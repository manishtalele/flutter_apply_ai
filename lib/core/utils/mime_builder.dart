import 'dart:convert';
import 'dart:io';

import 'package:flutter_apply_ai/core/errors/exceptions.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

/// Builds an RFC 2822 MIME message and encodes it as base64url for the Gmail
/// API `messages.send` `raw` field.
///
/// Produces a `multipart/mixed` message when attachments are present (HTML body
/// part + one part per attachment), or a single `text/html` message otherwise.
/// Non-ASCII subjects are RFC 2047 encoded.
abstract final class MimeBuilder {
  const MimeBuilder._();

  static const String _crlf = '\r\n';

  static Future<String> buildRawMessage({
    required String fromEmail,
    required String fromName,
    required String to,
    required String subject,
    required String htmlBody,
    List<String> attachmentPaths = const <String>[],
  }) async {
    final String from =
        fromName.trim().isEmpty ? fromEmail : '${_encodeHeader(fromName)} <$fromEmail>';
    final String encodedSubject = _encodeHeader(subject);

    final StringBuffer buffer = StringBuffer();
    final bool hasAttachments = attachmentPaths.isNotEmpty;

    if (!hasAttachments) {
      buffer
        ..write('From: $from$_crlf')
        ..write('To: $to$_crlf')
        ..write('Subject: $encodedSubject$_crlf')
        ..write('MIME-Version: 1.0$_crlf')
        ..write('Content-Type: text/html; charset="UTF-8"$_crlf')
        ..write('Content-Transfer-Encoding: 7bit$_crlf')
        ..write(_crlf)
        ..write(htmlBody);
      return _encodeBase64Url(buffer.toString());
    }

    final String boundary =
        'boundary_${DateTime.now().microsecondsSinceEpoch}';

    buffer
      ..write('From: $from$_crlf')
      ..write('To: $to$_crlf')
      ..write('Subject: $encodedSubject$_crlf')
      ..write('MIME-Version: 1.0$_crlf')
      ..write('Content-Type: multipart/mixed; boundary="$boundary"$_crlf')
      ..write(_crlf)
      // HTML body part.
      ..write('--$boundary$_crlf')
      ..write('Content-Type: text/html; charset="UTF-8"$_crlf')
      ..write('Content-Transfer-Encoding: 7bit$_crlf')
      ..write(_crlf)
      ..write(htmlBody)
      ..write(_crlf);

    for (final String path in attachmentPaths) {
      await _appendAttachment(buffer, boundary, path);
    }

    buffer.write('--$boundary--$_crlf');
    return _encodeBase64Url(buffer.toString());
  }

  static Future<void> _appendAttachment(
    StringBuffer buffer,
    String boundary,
    String path,
  ) async {
    final File file = File(path);
    if (!file.existsSync()) {
      throw ValidationException('Attachment not found: $path');
    }
    final List<int> bytes = await file.readAsBytes();
    final String fileName = p.basename(path);
    final String contentType =
        lookupMimeType(path) ?? 'application/octet-stream';
    final String encoded = _wrap(base64.encode(bytes));

    buffer
      ..write('--$boundary$_crlf')
      ..write('Content-Type: $contentType; name="$fileName"$_crlf')
      ..write('Content-Transfer-Encoding: base64$_crlf')
      ..write('Content-Disposition: attachment; filename="$fileName"$_crlf')
      ..write(_crlf)
      ..write(encoded)
      ..write(_crlf);
  }

  /// Wraps base64 content at 76 characters per line (RFC 2045).
  static String _wrap(String input) {
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < input.length; i += 76) {
      final int end = (i + 76 < input.length) ? i + 76 : input.length;
      buffer.write(input.substring(i, end));
      buffer.write(_crlf);
    }
    return buffer.toString().trimRight();
  }

  /// RFC 2047 "encoded-word" for headers containing non-ASCII characters.
  static String _encodeHeader(String value) {
    final bool isAscii = value.codeUnits.every((int c) => c < 128);
    if (isAscii) {
      return value;
    }
    final String encoded = base64.encode(utf8.encode(value));
    return '=?UTF-8?B?$encoded?=';
  }

  static String _encodeBase64Url(String message) {
    return base64Url.encode(utf8.encode(message));
  }
}
