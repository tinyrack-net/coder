/// In-memory screen model mirroring one pseudo-terminal's parsed state.
///
/// A byte log cannot restore a session. It is bounded, and trimming its front
/// cuts the alternate-screen entry and a full-screen program's initial paint
/// off a long-lived terminal, leaving cursor-relative deltas with no anchor.
/// A parsed screen can be handed to any client as a screen.
abstract interface class TerminalScreen {
  /// Parses one output chunk.
  ///
  /// The returned future completes once the chunk has been applied, which is
  /// what lets a caller say which byte offset the grid corresponds to.
  Future<void> feed(String data);

  /// Reflows the grid to a new cell geometry.
  void resize(int columns, int rows);

  /// Serializes the screen, its modes, and up to [scrollbackLines] retained
  /// rows as ANSI that reproduces this state in a reset terminal.
  ///
  /// Synchronous by contract: a caller that has awaited [feed] must be able to
  /// read the grid without another chunk landing in between.
  String snapshot({required int scrollbackLines});

  /// Releases the grid.
  void dispose();
}

/// Creates one screen model per terminal.
abstract interface class TerminalScreenFactory {
  /// Creates a screen sized to a pseudo-terminal.
  TerminalScreen create({
    required int columns,
    required int rows,
    required int scrollbackLines,
  });
}
