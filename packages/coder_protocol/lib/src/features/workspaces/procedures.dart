import 'package:coder_protocol/src/common/rpc_values.dart';
import 'package:coder_protocol/src/rpc_catalog.dart';
import 'package:coder_protocol/src/rpc_models.dart';

/// Typed v4 transport descriptor.
final workspacesCatalogProcedure =
    RpcProcedure<EmptyParamsDto, WorkspaceCatalogResultDto>(
      name: 'workspaces.catalog',
      decodeParams: EmptyParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: WorkspaceCatalogResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v4 transport descriptor.
final workspacesRegisterProcedure =
    RpcProcedure<WorkspaceRegisterParamsDto, WorkspaceRegisterResultDto>(
      name: 'workspaces.register',
      decodeParams: WorkspaceRegisterParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: WorkspaceRegisterResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v4 transport descriptor.
final workspacesRefreshProcedure =
    RpcProcedure<WorkspaceIdParamsDto, WorkspaceCatalogResultDto>(
      name: 'workspaces.refresh',
      decodeParams: WorkspaceIdParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: WorkspaceCatalogResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v4 transport descriptor.
final workspacesUnregisterProcedure =
    RpcProcedure<WorkspaceIdParamsDto, WorkspaceUnregisterResultDto>(
      name: 'workspaces.unregister',
      decodeParams: WorkspaceIdParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: WorkspaceUnregisterResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v4 transport descriptor.
final workspacesSuggestDirectoriesProcedure =
    RpcProcedure<DirectorySuggestParamsDto, DirectorySuggestResultDto>(
      name: 'workspaces.suggestDirectories',
      decodeParams: DirectorySuggestParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: DirectorySuggestResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v4 transport descriptor.
final workspacesSearchFilesProcedure =
    RpcProcedure<FileSearchParamsDto, FileSearchResultDto>(
      name: 'workspaces.searchFiles',
      decodeParams: FileSearchParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: FileSearchResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v4 transport descriptor.
final workspacesListBranchesProcedure =
    RpcProcedure<GitBranchesListParamsDto, GitBranchesListResultDto>(
      name: 'workspaces.listBranches',
      decodeParams: GitBranchesListParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: GitBranchesListResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v4 transport descriptor.
final workspacesCreateWorktreeProcedure =
    RpcProcedure<WorktreeCreateParamsDto, WorktreeResultDto>(
      name: 'workspaces.createWorktree',
      decodeParams: WorktreeCreateParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: WorktreeResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v4 transport descriptor.
final workspacesPreviewArchiveProcedure =
    RpcProcedure<WorktreeIdParamsDto, WorktreeArchivePreviewResultDto>(
      name: 'workspaces.previewArchive',
      decodeParams: WorktreeIdParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: WorktreeArchivePreviewResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v4 transport descriptor.
final workspacesArchiveWorktreeProcedure =
    RpcProcedure<WorktreeArchiveParamsDto, WorktreeResultDto>(
      name: 'workspaces.archiveWorktree',
      decodeParams: WorktreeArchiveParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: WorktreeResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v4 transport descriptor.
final workspacesGetProjectSettingsProcedure =
    RpcProcedure<ProjectSettingsGetParamsDto, ProjectSettingsResultDto>(
      name: 'workspaces.getProjectSettings',
      decodeParams: ProjectSettingsGetParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: ProjectSettingsResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v4 transport descriptor.
final workspacesSaveProjectSettingsProcedure =
    RpcProcedure<ProjectSettingsSaveParamsDto, ProjectSettingsResultDto>(
      name: 'workspaces.saveProjectSettings',
      decodeParams: ProjectSettingsSaveParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: ProjectSettingsResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Feature-owned descriptor catalog.
final workspacesProcedures = <RpcProcedureDescriptor>[
  workspacesCatalogProcedure,
  workspacesRegisterProcedure,
  workspacesRefreshProcedure,
  workspacesUnregisterProcedure,
  workspacesSuggestDirectoriesProcedure,
  workspacesSearchFilesProcedure,
  workspacesListBranchesProcedure,
  workspacesCreateWorktreeProcedure,
  workspacesPreviewArchiveProcedure,
  workspacesArchiveWorktreeProcedure,
  workspacesGetProjectSettingsProcedure,
  workspacesSaveProjectSettingsProcedure,
];
