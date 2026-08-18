import 'package:protocol/src/common/rpc_values.dart';
import 'package:protocol/src/rpc_catalog.dart';
import 'package:protocol/src/rpc_models.dart';

/// Typed v5 transport descriptor.
final promptsListCommandsProcedure =
    RpcProcedure<CommandListParamsDto, CommandListResultDto>(
      name: 'prompts.listCommands',
      decodeParams: CommandListParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: CommandListResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v5 transport descriptor.
final promptsListSkillsProcedure =
    RpcProcedure<SkillListParamsDto, SkillListResultDto>(
      name: 'prompts.listSkills',
      decodeParams: SkillListParamsDto.fromJson,
      encodeParams: (value) => value.toJson(),
      decodeResult: SkillListResultDto.fromJson,
      encodeResult: (value) => value.toJson(),
    );

/// Typed v5 transport descriptor.
final promptsSkillsChangedNotification = RpcNotification<EmptyResultDto>(
  name: 'prompts.skillsChanged',
  decode: EmptyResultDto.fromJson,
  encode: (value) => value.toJson(),
);

/// Typed v5 transport descriptor.
final promptsCommandsChangedNotification = RpcNotification<EmptyResultDto>(
  name: 'prompts.commandsChanged',
  decode: EmptyResultDto.fromJson,
  encode: (value) => value.toJson(),
);

/// Feature-owned descriptor catalog.
final promptsProcedures = <RpcProcedureDescriptor>[
  promptsListCommandsProcedure,
  promptsListSkillsProcedure,
];

/// Feature-owned descriptor catalog.
final promptsNotifications = <RpcNotificationDescriptor>[
  promptsSkillsChangedNotification,
  promptsCommandsChangedNotification,
];
