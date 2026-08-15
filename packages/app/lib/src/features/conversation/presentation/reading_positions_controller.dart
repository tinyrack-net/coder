import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

part 'reading_positions_controller.g.dart';

/// How many conversations keep a reading position before the oldest is dropped.
///
/// A snapshot carries the measured extents of the rows it was taken over, so
/// an unbounded map would retain layout data for every session ever opened.
const int retainedReadingPositions = 32;

@Riverpod(keepAlive: true)
/// Where a reader left each conversation, keyed by `<hostId>:<sessionId>`.
///
/// Only a reader who left history *above* them is recorded. Someone who was at
/// the newest message wants the newest message again, and restoring the row
/// that happened to be under the cursor would hide everything that arrived
/// while they were away.
///
/// This cannot live in widget state: the conversation pane is keyed per tab and
/// remounts on every switch. It is deliberately not page storage either, whose
/// restore path outranks the "open at the newest message" contract even when
/// the stored anchor is the very first row.
class ConversationReadingPositions extends _$ConversationReadingPositions {
  @override
  Map<String, TRVirtualListSnapshot<String>> build() =>
      const <String, TRVirtualListSnapshot<String>>{};

  /// Records where the reader of [sessionKey] left, or forgets it when
  /// [position] is null because they were already at the newest message.
  void remember(String sessionKey, TRVirtualListSnapshot<String>? position) {
    // A pane reports its position while it is being torn down, so the write
    // is deferred past the build phase and can land after the app itself is
    // gone. There is nothing left to remember for.
    if (!ref.mounted) return;
    if (position == null) {
      forget(sessionKey);
      return;
    }
    // Re-inserting rather than overwriting keeps the map ordered by recency,
    // so the entry evicted below is the least recently read conversation.
    final next = <String, TRVirtualListSnapshot<String>>{...state}
      ..remove(sessionKey)
      ..[sessionKey] = position;
    while (next.length > retainedReadingPositions) {
      next.remove(next.keys.first);
    }
    state = next;
  }

  /// Forgets the reading position of [sessionKey].
  void forget(String sessionKey) {
    if (!ref.mounted || !state.containsKey(sessionKey)) return;
    state = <String, TRVirtualListSnapshot<String>>{...state}
      ..remove(sessionKey);
  }
}
