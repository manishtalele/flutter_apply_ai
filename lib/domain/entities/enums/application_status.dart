/// Lifecycle status of a submitted job application.
///
/// [value] is the stable identifier persisted to SQLite (never localize or
/// rename it — migrations depend on it). [label] is the human-readable text
/// shown in the UI.
enum ApplicationStatus {
  applied('applied', 'Applied'),
  interview('interview', 'Interview'),
  selected('selected', 'Selected'),
  rejected('rejected', 'Rejected'),
  noReply('no_reply', 'No Reply');

  const ApplicationStatus(this.value, this.label);

  final String value;
  final String label;

  /// Resolves a persisted [value] back to an enum, defaulting to [applied]
  /// for forward-compatibility with unknown values.
  static ApplicationStatus fromValue(String value) {
    return ApplicationStatus.values.firstWhere(
      (ApplicationStatus status) => status.value == value,
      orElse: () => ApplicationStatus.applied,
    );
  }

  /// Whether this status represents a reply having been received from the
  /// employer (used by the dashboard "Replies" aggregate).
  bool get isReply =>
      this == ApplicationStatus.interview ||
      this == ApplicationStatus.selected ||
      this == ApplicationStatus.rejected;
}
