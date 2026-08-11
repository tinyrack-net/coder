// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model_picker_options.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Loads every provider-qualified model the user may currently pick.
///
/// Exposed as a loader rather than as the option list itself because opening
/// the picker must fetch what is missing right then; a plain `FutureProvider`
/// would answer the second open from cache. The `Ref` handed to [_load] is this
/// provider's, so the fetch below is bound to the provider's lifetime rather
/// than to whichever widget happened to open the picker.
///
/// `keepAlive` for that same reason: callers read the loader and invoke it
/// later, so an auto-disposed provider would hand out a closure over a `Ref`
/// that is already gone. It holds no state and is keyed only by host.

@ProviderFor(modelPickerOptionsLoader)
final modelPickerOptionsLoaderProvider = ModelPickerOptionsLoaderFamily._();

/// Loads every provider-qualified model the user may currently pick.
///
/// Exposed as a loader rather than as the option list itself because opening
/// the picker must fetch what is missing right then; a plain `FutureProvider`
/// would answer the second open from cache. The `Ref` handed to [_load] is this
/// provider's, so the fetch below is bound to the provider's lifetime rather
/// than to whichever widget happened to open the picker.
///
/// `keepAlive` for that same reason: callers read the loader and invoke it
/// later, so an auto-disposed provider would hand out a closure over a `Ref`
/// that is already gone. It holds no state and is keyed only by host.

final class ModelPickerOptionsLoaderProvider
    extends
        $FunctionalProvider<
          ModelPickerOptionsLoader,
          ModelPickerOptionsLoader,
          ModelPickerOptionsLoader
        >
    with $Provider<ModelPickerOptionsLoader> {
  /// Loads every provider-qualified model the user may currently pick.
  ///
  /// Exposed as a loader rather than as the option list itself because opening
  /// the picker must fetch what is missing right then; a plain `FutureProvider`
  /// would answer the second open from cache. The `Ref` handed to [_load] is this
  /// provider's, so the fetch below is bound to the provider's lifetime rather
  /// than to whichever widget happened to open the picker.
  ///
  /// `keepAlive` for that same reason: callers read the loader and invoke it
  /// later, so an auto-disposed provider would hand out a closure over a `Ref`
  /// that is already gone. It holds no state and is keyed only by host.
  ModelPickerOptionsLoaderProvider._({
    required ModelPickerOptionsLoaderFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'modelPickerOptionsLoaderProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$modelPickerOptionsLoaderHash();

  @override
  String toString() {
    return r'modelPickerOptionsLoaderProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<ModelPickerOptionsLoader> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ModelPickerOptionsLoader create(Ref ref) {
    final argument = this.argument as String;
    return modelPickerOptionsLoader(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ModelPickerOptionsLoader value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ModelPickerOptionsLoader>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ModelPickerOptionsLoaderProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$modelPickerOptionsLoaderHash() =>
    r'cbef84c1e2c35acd9ed76f840564cec7b232bf1a';

/// Loads every provider-qualified model the user may currently pick.
///
/// Exposed as a loader rather than as the option list itself because opening
/// the picker must fetch what is missing right then; a plain `FutureProvider`
/// would answer the second open from cache. The `Ref` handed to [_load] is this
/// provider's, so the fetch below is bound to the provider's lifetime rather
/// than to whichever widget happened to open the picker.
///
/// `keepAlive` for that same reason: callers read the loader and invoke it
/// later, so an auto-disposed provider would hand out a closure over a `Ref`
/// that is already gone. It holds no state and is keyed only by host.

final class ModelPickerOptionsLoaderFamily extends $Family
    with $FunctionalFamilyOverride<ModelPickerOptionsLoader, String> {
  ModelPickerOptionsLoaderFamily._()
    : super(
        retry: null,
        name: r'modelPickerOptionsLoaderProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Loads every provider-qualified model the user may currently pick.
  ///
  /// Exposed as a loader rather than as the option list itself because opening
  /// the picker must fetch what is missing right then; a plain `FutureProvider`
  /// would answer the second open from cache. The `Ref` handed to [_load] is this
  /// provider's, so the fetch below is bound to the provider's lifetime rather
  /// than to whichever widget happened to open the picker.
  ///
  /// `keepAlive` for that same reason: callers read the loader and invoke it
  /// later, so an auto-disposed provider would hand out a closure over a `Ref`
  /// that is already gone. It holds no state and is keyed only by host.

  ModelPickerOptionsLoaderProvider call(String hostId) =>
      ModelPickerOptionsLoaderProvider._(argument: hostId, from: this);

  @override
  String toString() => r'modelPickerOptionsLoaderProvider';
}
