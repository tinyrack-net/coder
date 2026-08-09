import 'package:protocol/src/common/rpc_values.dart';
import 'package:protocol/src/rpc_catalog.dart';
import 'package:protocol/src/rpc_models.dart';

/// Typed v4 transport descriptor.
final promptsListCommandsProcedure =
    RpcProcedure<CommandListParamsDto, CommandListResultDto>(
      name: 'prompts.listCommands',
      decodeParams: CommandListParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: CommandListResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v4 transport descriptor.
final promptsListSkillsProcedure =
    RpcProcedure<SkillScopeParamsDto, SkillListResultDto>(
      name: 'prompts.listSkills',
      decodeParams: SkillScopeParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: SkillListResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v4 transport descriptor.
final promptsGetSkillProcedure = RpcProcedure<SkillIdParamsDto, SkillResultDto>(
  name: 'prompts.getSkill',
  decodeParams: SkillIdParamsDto.fromJson,
  encodeParams: (value) => value.toJson(),
  decodeResult: SkillResultDto.fromJson,
  encodeResult: (value) => value.toJson(),
);

/// Typed v4 transport descriptor.
final promptsCreateSkillProcedure =
    RpcProcedure<SkillCreateParamsDto, SkillResultDto>(
      name: 'prompts.createSkill',
      decodeParams: SkillCreateParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: SkillResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v4 transport descriptor.
final promptsUpdateSkillProcedure =
    RpcProcedure<SkillUpdateParamsDto, SkillResultDto>(
      name: 'prompts.updateSkill',
      decodeParams: SkillUpdateParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: SkillResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v4 transport descriptor.
final promptsDeleteSkillProcedure =
    RpcProcedure<SkillIdParamsDto, EmptyResultDto>(
      name: 'prompts.deleteSkill',
      decodeParams: SkillIdParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: EmptyResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v4 transport descriptor.
final promptsSetSkillEnabledProcedure =
    RpcProcedure<SkillSetEnabledParamsDto, SkillResultDto>(
      name: 'prompts.setSkillEnabled',
      decodeParams: SkillSetEnabledParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: SkillResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v4 transport descriptor.
final promptsSkillsChangedNotification = RpcNotification<EmptyResultDto>(
  name: 'prompts.skillsChanged',
  decode: EmptyResultDto.fromJson,
  encode: (value) => value.toJson(),
);

/// Typed v4 transport descriptor.
final promptsCommandsChangedNotification = RpcNotification<EmptyResultDto>(
  name: 'prompts.commandsChanged',
  decode: EmptyResultDto.fromJson,
  encode: (value) => value.toJson(),
);

/// Feature-owned descriptor catalog.
final promptsProcedures = <RpcProcedureDescriptor>[
  promptsListCommandsProcedure,
  promptsListSkillsProcedure,
  promptsGetSkillProcedure,
  promptsCreateSkillProcedure,
  promptsUpdateSkillProcedure,
  promptsDeleteSkillProcedure,
  promptsSetSkillEnabledProcedure,
];

/// Feature-owned descriptor catalog.
final promptsNotifications = <RpcNotificationDescriptor>[
  promptsSkillsChangedNotification,
  promptsCommandsChangedNotification,
];
