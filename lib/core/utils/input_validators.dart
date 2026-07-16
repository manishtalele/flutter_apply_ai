/// Reusable input validation helpers returning a `TextFormField`-compatible
/// error string (`null` == valid). Deliberately avoids regex — simple,
/// explicit rules are easier to reason about and audit.
abstract final class InputValidators {
  const InputValidators._();

  /// OpenAI API keys are long opaque strings; require a sane minimum length.
  static String? openAiApiKey(String? value) {
    final String trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) {
      return 'API key is required.';
    }
    if (trimmed.length < 20) {
      return 'That does not look like a valid API key.';
    }
    return null;
  }

  /// Basic structural email check (local@domain.tld) without regex.
  static bool isValidEmail(String value) {
    final String trimmed = value.trim();
    final List<String> parts = trimmed.split('@');
    if (parts.length != 2) {
      return false;
    }
    final String local = parts.first;
    final String domain = parts.last;
    return local.isNotEmpty &&
        domain.contains('.') &&
        !domain.startsWith('.') &&
        !domain.endsWith('.');
  }

  static String? requiredText(String? value, {String field = 'This field'}) {
    if ((value ?? '').trim().isEmpty) {
      return '$field is required.';
    }
    return null;
  }
}
