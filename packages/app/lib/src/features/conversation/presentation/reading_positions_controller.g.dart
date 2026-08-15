// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reading_positions_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(ConversationReadingPositions)
final conversationReadingPositionsProvider =
    ConversationReadingPositionsProvider._();

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
final class ConversationReadingPositionsProvider
    extends
        $NotifierProvider<
          ConversationReadingPositions,
          Map<String, TRVirtualListSnapshot<String>>
        > {
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
  ConversationReadingPositionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'conversationReadingPositionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$conversationReadingPositionsHash();

  @$internal
  @override
  ConversationReadingPositions create() => ConversationReadingPositions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, TRVirtualListSnapshot<String>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<Map<String, TRVirtualListSnapshot<String>>>(value),
    );
  }
}

String _$conversationReadingPositionsHash() =>
    r'3315e951bb2390191775f25a57ff13145db4a6a5';

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

abstract class _$ConversationReadingPositions
    extends $Notifier<Map<String, TRVirtualListSnapshot<String>>> {
  Map<String, TRVirtualListSnapshot<String>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              Map<String, TRVirtualListSnapshot<String>>,
              Map<String, TRVirtualListSnapshot<String>>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                Map<String, TRVirtualListSnapshot<String>>,
                Map<String, TRVirtualListSnapshot<String>>
              >,
              Map<String, TRVirtualListSnapshot<String>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
