/// Builds RFC 4180-compliant CSV text from generic rows.
///
/// Kept generic (no domain dependency) so the Core layer stays low-level: the
/// mapping from domain entities to rows lives in the use case that calls this.
abstract final class CsvExporter {
  const CsvExporter._();

  static String build(List<String> headers, List<List<String>> rows) {
    final StringBuffer buffer = StringBuffer()..writeln(_row(headers));
    for (final List<String> row in rows) {
      buffer.writeln(_row(row));
    }
    return buffer.toString();
  }

  static String _row(List<String> fields) {
    return fields.map(_escape).join(',');
  }

  /// Quotes a field when it contains a comma, quote, or newline, doubling any
  /// embedded quotes (RFC 4180).
  static String _escape(String field) {
    final bool needsQuoting = field.contains(',') ||
        field.contains('"') ||
        field.contains('\n') ||
        field.contains('\r');
    if (!needsQuoting) {
      return field;
    }
    final String escaped = field.replaceAll('"', '""');
    return '"$escaped"';
  }
}
