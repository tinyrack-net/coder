// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_turns_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// First prompts of freshly created sessions, keyed by session id.
///
/// A new session navigates before its timeline subscription and first turn
/// complete, so the conversation pane renders the prompt from here as an
/// optimistic user bubble until the real timeline echoes it. A turn that
/// failed to start is marked rather than dropped: the auto-disposed
/// conversation state cannot yet hold it, so the mounted conversation pane
/// converts the entry into a queued turn once its conversation is live.

@ProviderFor(PendingFirstTurns)
final pendingFirstTurnsProvider = PendingFirstTurnsProvider._();

/// First prompts of freshly created sessions, keyed by session id.
///
/// A new session navigates before its timeline subscription and first turn
/// complete, so the conversation pane renders the prompt from here as an
/// optimistic user bubble until the real timeline echoes it. A turn that
/// failed to start is marked rather than dropped: the auto-disposed
/// conversation state cannot yet hold it, so the mounted conversation pane
/// converts the entry into a queued turn once its conversation is live.
final class PendingFirstTurnsProvider
    extends
        $NotifierProvider<PendingFirstTurns, Map<String, PendingFirstTurn>> {
  /// First prompts of freshly created sessions, keyed by session id.
  ///
  /// A new session navigates before its timeline subscription and first turn
  /// complete, so the conversation pane renders the prompt from here as an
  /// optimistic user bubble until the real timeline echoes it. A turn that
  /// failed to start is marked rather than dropped: the auto-disposed
  /// conversation state cannot yet hold it, so the mounted conversation pane
  /// converts the entry into a queued turn once its conversation is live.
  PendingFirstTurnsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingFirstTurnsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingFirstTurnsHash();

  @$internal
  @override
  PendingFirstTurns create() => PendingFirstTurns();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, PendingFirstTurn> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, PendingFirstTurn>>(
        value,
      ),
    );
  }
}

String _$pendingFirstTurnsHash() => r'aa440a78121721b3d1687e3018f3030202d578aa';

/// First prompts of freshly created sessions, keyed by session id.
///
/// A new session navigates before its timeline subscription and first turn
/// complete, so the conversation pane renders the prompt from here as an
/// optimistic user bubble until the real timeline echoes it. A turn that
/// failed to start is marked rather than dropped: the auto-disposed
/// conversation state cannot yet hold it, so the mounted conversation pane
/// converts the entry into a queued turn once its conversation is live.

abstract class _$PendingFirstTurns
    extends $Notifier<Map<String, PendingFirstTurn>> {
  Map<String, PendingFirstTurn> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              Map<String, PendingFirstTurn>,
              Map<String, PendingFirstTurn>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                Map<String, PendingFirstTurn>,
                Map<String, PendingFirstTurn>
              >,
              Map<String, PendingFirstTurn>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
