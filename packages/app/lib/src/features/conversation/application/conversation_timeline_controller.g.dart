// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_timeline_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Projects only when timeline interaction data changes.
///
/// Queue edits and other conversation state updates retain the same collection
/// identities, so they do not reparse every Markdown and tool row.

@ProviderFor(conversationTimeline)
final conversationTimelineProvider = ConversationTimelineFamily._();

/// Projects only when timeline interaction data changes.
///
/// Queue edits and other conversation state updates retain the same collection
/// identities, so they do not reparse every Markdown and tool row.

final class ConversationTimelineProvider
    extends $FunctionalProvider<List<ChatItem>, List<ChatItem>, List<ChatItem>>
    with $Provider<List<ChatItem>> {
  /// Projects only when timeline interaction data changes.
  ///
  /// Queue edits and other conversation state updates retain the same collection
  /// identities, so they do not reparse every Markdown and tool row.
  ConversationTimelineProvider._({
    required ConversationTimelineFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'conversationTimelineProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$conversationTimelineHash();

  @override
  String toString() {
    return r'conversationTimelineProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<List<ChatItem>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<ChatItem> create(Ref ref) {
    final argument = this.argument as (String, String);
    return conversationTimeline(ref, argument.$1, argument.$2);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<ChatItem> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<ChatItem>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ConversationTimelineProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$conversationTimelineHash() =>
    r'9b3bb8647d6a82141beb827703e9fdacf49b88bf';

/// Projects only when timeline interaction data changes.
///
/// Queue edits and other conversation state updates retain the same collection
/// identities, so they do not reparse every Markdown and tool row.

final class ConversationTimelineFamily extends $Family
    with $FunctionalFamilyOverride<List<ChatItem>, (String, String)> {
  ConversationTimelineFamily._()
    : super(
        retry: null,
        name: r'conversationTimelineProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Projects only when timeline interaction data changes.
  ///
  /// Queue edits and other conversation state updates retain the same collection
  /// identities, so they do not reparse every Markdown and tool row.

  ConversationTimelineProvider call(String hostId, String sessionId) =>
      ConversationTimelineProvider._(argument: (hostId, sessionId), from: this);

  @override
  String toString() => r'conversationTimelineProvider';
}
