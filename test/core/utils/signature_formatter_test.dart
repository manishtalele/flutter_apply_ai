import 'package:flutter_apply_ai/core/utils/signature_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SignatureFormatter.toHtml', () {
    test('returns empty for a blank signature', () {
      expect(SignatureFormatter.toHtml('   '), '');
    });

    test('joins lines with <br> and linkifies urls/emails', () {
      const String signature = 'Best regards,\n'
          'Manish Talele\n'
          'manishtalele1410@gmail.com\n'
          'https://github.com/manishtalele';
      final String html = SignatureFormatter.toHtml(signature);

      expect(html, contains('Best regards,<br>'));
      expect(
        html,
        contains('<a href="mailto:manishtalele1410@gmail.com">'
            'manishtalele1410@gmail.com</a>'),
      );
      expect(
        html,
        contains('<a href="https://github.com/manishtalele">'
            'https://github.com/manishtalele</a>'),
      );
    });

    test('adds https:// to scheme-less linkedin/github links', () {
      final String html =
          SignatureFormatter.toHtml('linkedin.com/in/manish-talele');
      expect(
        html,
        contains('<a href="https://linkedin.com/in/manish-talele">'),
      );
    });

    test('escapes HTML-special characters in plain text', () {
      final String html = SignatureFormatter.toHtml('Manish <dev> & co');
      expect(html, contains('Manish &lt;dev&gt; &amp; co'));
    });
  });

  group('SignatureFormatter.tokenizeLine', () {
    test('classifies plain text, urls, and emails', () {
      final List<SignatureToken> tokens =
          SignatureFormatter.tokenizeLine('Reach me@x.com or www.site.com now');
      expect(tokens[0].isLink, isFalse); // "Reach"
      expect(tokens[1].href, 'mailto:me@x.com');
      expect(tokens[3].href, 'https://www.site.com');
      expect(tokens[4].isLink, isFalse); // "now"
    });
  });
}
