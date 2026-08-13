// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skills_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Loads and edits the skills one daemon offers, optionally for one project.
///
/// A null [SkillsController.workspaceId] shows only the built-in, user-home,
/// and daemon-config sources; naming a workspace layers its
/// `.agents/skills` on top.

@ProviderFor(SkillsController)
final skillsControllerProvider = SkillsControllerFamily._();

/// Loads and edits the skills one daemon offers, optionally for one project.
///
/// A null [SkillsController.workspaceId] shows only the built-in, user-home,
/// and daemon-config sources; naming a workspace layers its
/// `.agents/skills` on top.
final class SkillsControllerProvider
    extends $AsyncNotifierProvider<SkillsController, List<SkillDto>> {
  /// Loads and edits the skills one daemon offers, optionally for one project.
  ///
  /// A null [SkillsController.workspaceId] shows only the built-in, user-home,
  /// and daemon-config sources; naming a workspace layers its
  /// `.agents/skills` on top.
  SkillsControllerProvider._({
    required SkillsControllerFamily super.from,
    required (String, String?) super.argument,
  }) : super(
         retry: noAutomaticRetry,
         name: r'skillsControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$skillsControllerHash();

  @override
  String toString() {
    return r'skillsControllerProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  SkillsController create() => SkillsController();

  @override
  bool operator ==(Object other) {
    return other is SkillsControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$skillsControllerHash() => r'1e8232c9e4f432a8b4fbb02320819a0de37b5a00';

/// Loads and edits the skills one daemon offers, optionally for one project.
///
/// A null [SkillsController.workspaceId] shows only the built-in, user-home,
/// and daemon-config sources; naming a workspace layers its
/// `.agents/skills` on top.

final class SkillsControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          SkillsController,
          AsyncValue<List<SkillDto>>,
          List<SkillDto>,
          FutureOr<List<SkillDto>>,
          (String, String?)
        > {
  SkillsControllerFamily._()
    : super(
        retry: noAutomaticRetry,
        name: r'skillsControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Loads and edits the skills one daemon offers, optionally for one project.
  ///
  /// A null [SkillsController.workspaceId] shows only the built-in, user-home,
  /// and daemon-config sources; naming a workspace layers its
  /// `.agents/skills` on top.

  SkillsControllerProvider call(String hostId, String? workspaceId) =>
      SkillsControllerProvider._(argument: (hostId, workspaceId), from: this);

  @override
  String toString() => r'skillsControllerProvider';
}

/// Loads and edits the skills one daemon offers, optionally for one project.
///
/// A null [SkillsController.workspaceId] shows only the built-in, user-home,
/// and daemon-config sources; naming a workspace layers its
/// `.agents/skills` on top.

abstract class _$SkillsController extends $AsyncNotifier<List<SkillDto>> {
  late final _$args = ref.$arg as (String, String?);
  String get hostId => _$args.$1;
  String? get workspaceId => _$args.$2;

  FutureOr<List<SkillDto>> build(String hostId, String? workspaceId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<SkillDto>>, List<SkillDto>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<SkillDto>>, List<SkillDto>>,
              AsyncValue<List<SkillDto>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}
