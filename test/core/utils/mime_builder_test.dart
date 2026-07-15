import 'dart:convert';
import 'dart:io';

import 'package:flutter_apply_ai/core/utils/mime_builder.dart';
import 'package:flutter_test/flutter_test.dart';

String _decode(String rawBase64Url) {
  return utf8.decode(base64Url.decode(rawBase64Url));
}

void main() {
  test('builds a single text/html message when there are no attachments',
      () async {
    final String raw = await MimeBuilder.buildRawMessage(
      fromEmail: 'me@gmail.com',
      fromName: 'Jane Doe',
      to: 'jobs@acme.com',
      subject: 'Application for Flutter Developer',
      htmlBody: '<p>Hello</p>',
    );

    final String message = _decode(raw);
    expect(message, contains('From: Jane Doe <me@gmail.com>'));
    expect(message, contains('To: jobs@acme.com'));
    expect(message, contains('Subject: Application for Flutter Developer'));
    expect(message, contains('Content-Type: text/html; charset="UTF-8"'));
    expect(message, contains('<p>Hello</p>'));
    expect(message, isNot(contains('multipart/mixed')));
  });

  test('builds a multipart/mixed message with an attachment', () async {
    final Directory tempDir = Directory.systemTemp.createTempSync('mime_test');
    final File resume = File('${tempDir.path}/resume.txt')
      ..writeAsStringSync('RESUME CONTENT');

    try {
      final String raw = await MimeBuilder.buildRawMessage(
        fromEmail: 'me@gmail.com',
        fromName: '',
        to: 'jobs@acme.com',
        subject: 'Hi',
        htmlBody: '<p>Body</p>',
        attachmentPaths: <String>[resume.path],
      );

      final String message = _decode(raw);
      expect(message, contains('Content-Type: multipart/mixed; boundary='));
      expect(message, contains('Content-Disposition: attachment; filename="resume.txt"'));
      expect(message, contains('Content-Transfer-Encoding: base64'));
      expect(message, contains(base64.encode(utf8.encode('RESUME CONTENT'))));
      // No display name → bare address.
      expect(message, contains('From: me@gmail.com'));
    } finally {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('RFC 2047-encodes a non-ASCII subject', () async {
    final String raw = await MimeBuilder.buildRawMessage(
      fromEmail: 'me@gmail.com',
      fromName: '',
      to: 'jobs@acme.com',
      subject: 'Applicación 🚀',
      htmlBody: '<p>Body</p>',
    );

    expect(_decode(raw), contains('Subject: =?UTF-8?B?'));
  });
}
