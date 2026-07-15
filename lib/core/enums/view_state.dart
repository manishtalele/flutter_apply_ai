/// Generic, cross-cutting UI state used by every GetX controller to drive the
/// initial / loading / success / error rendering of a screen. Kept in Core
/// (not Presentation) because it is framework-agnostic and shared everywhere.
enum ViewState {
  initial,
  loading,
  success,
  error;

  bool get isInitial => this == ViewState.initial;
  bool get isLoading => this == ViewState.loading;
  bool get isSuccess => this == ViewState.success;
  bool get isError => this == ViewState.error;
}
