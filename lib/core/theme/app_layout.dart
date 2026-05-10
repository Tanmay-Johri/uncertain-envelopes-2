/// Layout tokens (Phase 3 POL1 — web / wide viewport).
abstract final class AppLayout {
  /// When [MediaQuery.sizeOf] width exceeds this, the main navigator body is
  /// centered with this max width so ultra-wide monitors do not stretch
  /// mobile-first UIs edge-to-edge.
  static const double maxContentWidth = 960;
}
