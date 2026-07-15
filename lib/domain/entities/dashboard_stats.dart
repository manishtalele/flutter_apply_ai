import 'package:equatable/equatable.dart';

/// Aggregated counters powering the Dashboard screen. Computed from the
/// `applications` table by the dashboard use case (Module 19).
class DashboardStats extends Equatable {
  const DashboardStats({
    required this.appliedToday,
    required this.appliedThisWeek,
    required this.appliedThisMonth,
    required this.totalApplied,
    required this.replies,
    required this.interviews,
    required this.selected,
    required this.rejected,
    required this.noReply,
  });

  /// All-zero stats (empty state / initial value).
  static const DashboardStats empty = DashboardStats(
    appliedToday: 0,
    appliedThisWeek: 0,
    appliedThisMonth: 0,
    totalApplied: 0,
    replies: 0,
    interviews: 0,
    selected: 0,
    rejected: 0,
    noReply: 0,
  );

  final int appliedToday;
  final int appliedThisWeek;
  final int appliedThisMonth;
  final int totalApplied;
  final int replies;
  final int interviews;
  final int selected;
  final int rejected;
  final int noReply;

  /// Reply rate as a fraction 0.0–1.0 (0 when nothing applied).
  double get replyRate => totalApplied == 0 ? 0 : replies / totalApplied;

  @override
  List<Object?> get props => <Object?>[
        appliedToday,
        appliedThisWeek,
        appliedThisMonth,
        totalApplied,
        replies,
        interviews,
        selected,
        rejected,
        noReply,
      ];
}
