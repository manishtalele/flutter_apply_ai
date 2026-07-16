/// A single piece of a signature line: plain text, or a link when [href] is
/// non-null.
class SignatureToken {
  const SignatureToken(this.text, {this.href});

  final String text;
  final String? href;

  bool get isLink => href != null;
}

/// Formats a plain-text signature into HTML (for the outgoing email) and into
/// structured tokens (for the on-screen live preview). Both outputs share the
/// same link-detection rules so the preview matches what is actually sent.
abstract final class SignatureFormatter {
  const SignatureFormatter._();

  /// Renders the signature as safe HTML: escapes markup, turns newlines into
  /// `<br>`, and wraps URLs/emails in `<a>` tags. Returns '' when empty.
  static String toHtml(String signature) {
    final String trimmed = signature.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    return trimmed
        .split('\n')
        .map(
          (String line) =>
              tokenizeLine(line).map(_tokenToHtml).join(' '),
        )
        .join('<br>');
  }

  /// Splits the signature into lines of tokens for widget rendering.
  static List<List<SignatureToken>> toLines(String signature) {
    return signature
        .split('\n')
        .map(tokenizeLine)
        .toList(growable: false);
  }

  /// Classifies each whitespace-separated token on a line as plain text, a
  /// URL, or an email address.
  static List<SignatureToken> tokenizeLine(String line) {
    return line
        .split(' ')
        .map((String token) {
          final String lower = token.toLowerCase();
          if (lower.startsWith('http://') || lower.startsWith('https://')) {
            return SignatureToken(token, href: token);
          }
          if (lower.startsWith('www.') ||
              lower.contains('linkedin.com') ||
              lower.contains('github.com')) {
            return SignatureToken(token, href: 'https://$token');
          }
          if (token.contains('@') &&
              token.contains('.') &&
              !token.contains('/')) {
            return SignatureToken(token, href: 'mailto:$token');
          }
          return SignatureToken(token);
        })
        .toList(growable: false);
  }

  static String _tokenToHtml(SignatureToken token) {
    final String escaped = _escapeHtml(token.text);
    if (token.isLink) {
      return '<a href="${_escapeHtml(token.href!)}">$escaped</a>';
    }
    return escaped;
  }

  static String _escapeHtml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
  }
}
