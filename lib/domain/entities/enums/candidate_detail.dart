/// A candidate fact that a job post may ask the applicant to state in their
/// subject line or email body, and that the app can store on their behalf.
///
/// This is the single source of truth for these details: [value] is the token
/// the AI returns (constrained by the response schema's `enum`, so no fuzzy
/// string matching is ever needed), and [label] is the wording used both in the
/// prompt sent to the AI and in the UI warning shown to the user.
///
/// Deliberately limited to the details the app actually persists — a post may
/// also ask for a portfolio link or reason for change, but the app has nothing
/// stored to fill those with, so flagging them would not be actionable.
enum CandidateDetail {
  currentLocation('currentLocation', 'Current location'),
  totalExperience('totalExperience', 'Total experience'),
  currentCtc('currentCtc', 'Current CTC'),
  expectedCtc('expectedCtc', 'Expected CTC'),
  noticePeriod('noticePeriod', 'Notice period');

  const CandidateDetail(this.value, this.label);

  /// The token used on the wire, in both the prompt and the response schema.
  final String value;

  /// Human-readable name, used in the prompt and in the UI.
  final String label;

  /// The tokens the AI is allowed to return, for the response schema's `enum`.
  static List<String> get allValues =>
      CandidateDetail.values.map((CandidateDetail d) => d.value).toList();

  /// Resolves a token from the AI, or `null` if it is not one we recognize.
  static CandidateDetail? fromValue(String value) {
    for (final CandidateDetail detail in CandidateDetail.values) {
      if (detail.value == value) {
        return detail;
      }
    }
    return null;
  }
}
