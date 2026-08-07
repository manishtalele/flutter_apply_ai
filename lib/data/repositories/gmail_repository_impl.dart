import 'dart:convert';

import 'package:flutter_apply_ai/core/errors/exceptions.dart';
import 'package:flutter_apply_ai/core/utils/app_logger.dart';
import 'package:flutter_apply_ai/core/utils/mime_builder.dart';
import 'package:flutter_apply_ai/core/utils/typedefs.dart';
import 'package:flutter_apply_ai/data/datasources/remote/gmail_auth_service.dart';
import 'package:flutter_apply_ai/data/datasources/remote/gmail_remote_datasource.dart';
import 'package:flutter_apply_ai/data/datasources/remote/gmail_token_store.dart';
import 'package:flutter_apply_ai/data/repositories/repository_error_mapper.dart';
import 'package:flutter_apply_ai/domain/entities/app_settings.dart';
import 'package:flutter_apply_ai/domain/entities/email_draft.dart';
import 'package:flutter_apply_ai/domain/entities/sent_email.dart';
import 'package:flutter_apply_ai/domain/repositories/gmail_repository.dart';
import 'package:flutter_apply_ai/domain/repositories/settings_repository.dart';

/// [GmailRepository] combining the OAuth service, token store, Gmail REST
/// datasource, MIME builder, and settings persistence.
class GmailRepositoryImpl
    with RepositoryErrorMapper
    implements GmailRepository {
  GmailRepositoryImpl({
    required GmailAuthService authService,
    required GmailRemoteDataSource remoteDataSource,
    required GmailTokenStore tokenStore,
    required SettingsRepository settingsRepository,
    required AppLogger logger,
  })  : _auth = authService,
        _remote = remoteDataSource,
        _tokenStore = tokenStore,
        _settings = settingsRepository,
        _logger = logger;

  final GmailAuthService _auth;
  final GmailRemoteDataSource _remote;
  final GmailTokenStore _tokenStore;
  final SettingsRepository _settings;
  final AppLogger _logger;

  @override
  AppLogger get logger => _logger;

  @override
  ResultFuture<String> connect() {
    return guard<String>(() async {
      final GmailTokens tokens = await _auth.authorize();
      await _tokenStore.save(tokens);

      final String email = await _remote.getProfileEmail();
      final AppSettings current = await _currentSettings();
      final Result<void> saved =
          await _settings.saveSettings(current.copyWith(gmailAccountEmail: email));
      saved.fold(
        (failure) => throw GmailException(failure.message),
        (_) {},
      );
      _logger.i('Gmail connected as $email');
      return email;
    });
  }

  @override
  ResultVoid disconnect() {
    return guard<void>(() async {
      await _auth.revoke();
      await _tokenStore.clear();
      final AppSettings current = await _currentSettings();
      await _settings.saveSettings(current.withGmailDisconnected());
    });
  }

  @override
  ResultFuture<bool> isConnected() {
    return guard<bool>(_tokenStore.hasTokens);
  }

  @override
  ResultFuture<String?> connectedAccount() {
    return guard<String?>(_connectedEmail);
  }

  @override
  ResultFuture<SentEmail> sendEmail(EmailDraft draft) {
    return guard<SentEmail>(() async {
      final AppSettings settings = await _requireConnectedSettings();
      final String senderName =
          draft.senderName.trim().isEmpty ? settings.senderName : draft.senderName;

      final String raw = await MimeBuilder.buildRawMessage(
        fromEmail: settings.gmailAccountEmail!,
        fromName: senderName,
        to: draft.recipient,
        subject: draft.subject,
        htmlBody: draft.htmlBody,
        attachmentPaths: draft.attachmentPaths,
      );

      final GmailSendResult result = await _sendWithAuthContext(raw);
      return SentEmail(
        messageId: result.messageId,
        threadId: result.threadId,
      );
    });
  }

  @override
  ResultFuture<String?> fetchLatestIncomingReply(String threadId) {
    return guard<String?>(() async {
      final DataMap thread = await _remote.getThread(threadId);
      final String? connectedEmail = await _connectedEmail();

      final Object? messages = thread['messages'];
      if (messages is! List) {
        return null;
      }

      String? latestIncomingBody;
      for (final Object? message in messages) {
        if (message is! Map) {
          continue;
        }
        final Object? payload = message['payload'];
        if (payload is! Map) {
          continue;
        }
        final String? from = _headerValue(payload['headers'], 'From');
        final bool sentByUs = connectedEmail != null &&
            from != null &&
            from.toLowerCase().contains(connectedEmail.toLowerCase());
        if (sentByUs) {
          continue;
        }
        final String? body = _extractBody(payload);
        if (body != null && body.trim().isNotEmpty) {
          latestIncomingBody = body;
        }
      }
      return latestIncomingBody;
    });
  }

  /// Sends the message, translating a 401 into actionable guidance.
  ///
  /// A 401 here means the access token was rejected AND the interceptor's
  /// refresh attempt could not produce a working one — i.e. the Gmail session
  /// is genuinely gone. Google's own wording ("Request had invalid
  /// authentication credentials…") tells the user nothing they can act on.
  Future<GmailSendResult> _sendWithAuthContext(String raw) async {
    try {
      return await _remote.sendRawMessage(raw);
    } on ServerException catch (error) {
      if (error.statusCode == 401) {
        throw const AuthException(
          'Your Gmail session has expired. Open Settings, disconnect Gmail, '
          'and connect it again — then retry sending.',
        );
      }
      rethrow;
    }
  }

  Future<AppSettings> _currentSettings() async {
    final Result<AppSettings> result = await _settings.getSettings();
    return result.fold((_) => AppSettings.empty, (AppSettings s) => s);
  }

  Future<AppSettings> _requireConnectedSettings() async {
    final AppSettings settings = await _currentSettings();
    if (!settings.isGmailConnected) {
      throw const AuthException('Gmail is not connected. Connect it in Settings.');
    }
    return settings;
  }

  Future<String?> _connectedEmail() async {
    final Result<AppSettings> result = await _settings.getSettings();
    return result.fold((_) => null, (AppSettings s) => s.gmailAccountEmail);
  }

  String? _headerValue(Object? headers, String name) {
    if (headers is! List) {
      return null;
    }
    for (final Object? header in headers) {
      if (header is Map) {
        final Object? headerName = header['name'];
        final Object? headerValue = header['value'];
        if (headerName is String &&
            headerValue is String &&
            headerName.toLowerCase() == name.toLowerCase()) {
          return headerValue;
        }
      }
    }
    return null;
  }

  String? _extractBody(Map<dynamic, dynamic> payload) {
    final Object? parts = payload['parts'];
    if (parts is List) {
      final String? plain = _findPart(parts, 'text/plain');
      if (plain != null) {
        return plain;
      }
      final String? html = _findPart(parts, 'text/html');
      if (html != null) {
        return _stripHtml(html);
      }
    }
    final String? direct = _decodePartBody(payload);
    if (direct != null) {
      return payload['mimeType'] == 'text/html' ? _stripHtml(direct) : direct;
    }
    return null;
  }

  String? _findPart(List<dynamic> parts, String mimeType) {
    for (final Object? part in parts) {
      if (part is! Map) {
        continue;
      }
      final Object? partMime = part['mimeType'];
      if (partMime == mimeType) {
        final String? decoded = _decodePartBody(part);
        if (decoded != null) {
          return decoded;
        }
      }
      final Object? nested = part['parts'];
      if (nested is List) {
        final String? result = _findPart(nested, mimeType);
        if (result != null) {
          return result;
        }
      }
    }
    return null;
  }

  String? _decodePartBody(Map<dynamic, dynamic> part) {
    final Object? body = part['body'];
    if (body is Map) {
      final Object? data = body['data'];
      if (data is String && data.isNotEmpty) {
        try {
          return utf8.decode(base64Url.decode(base64Url.normalize(data)));
        } catch (_) {
          return null;
        }
      }
    }
    return null;
  }

  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp('<[^>]+>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
