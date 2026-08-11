import 'package:agent/src/contracts.dart';
import 'package:agent/src/prompts/prompt_assets.g.dart';

/// The two axes upstream describes separately, resolved for one mode.
///
/// Tinest collapses them into a single [AgentPermissionMode], so the mapping
/// lives here rather than in the templates: the model still reads a sandbox
/// sentence and an approval-policy section, as it does upstream.
typedef _Permissions = ({String sandbox, String approval, bool writableRoot});

/// Describes what this turn may do on its own and what the host escalates.
///
/// The order matches upstream: the filesystem sentence first, then the
/// approval policy, then the roots the turn may write to.
String permissionsInstructions({
  required AgentPermissionMode mode,
  required String workspaceRoot,
}) {
  final permissions = _permissionsFor(mode);
  final sections = <String>[
    permissions.sandbox.trim(),
    permissions.approval.trim(),
    if (permissions.writableRoot) 'The writable root is `$workspaceRoot`.',
  ];
  return sections.join('\n\n');
}

_Permissions _permissionsFor(AgentPermissionMode mode) => switch (mode) {
  // Reads are allowed and everything else is denied outright, so there is no
  // approval path to describe.
  AgentPermissionMode.readOnly => (
    sandbox: PromptAssets.permissionsSandboxModeReadOnly,
    approval: PromptAssets.permissionsApprovalPolicyNever,
    writableRoot: false,
  ),
  AgentPermissionMode.ask => (
    sandbox: PromptAssets.permissionsSandboxModeWorkspaceWrite,
    approval: PromptAssets.permissionsApprovalPolicyOnRequest,
    writableRoot: true,
  ),
  AgentPermissionMode.workspaceWrite => (
    sandbox: PromptAssets.permissionsSandboxModeWorkspaceWrite,
    approval: PromptAssets.permissionsApprovalPolicyUnlessTrusted,
    writableRoot: true,
  ),
  AgentPermissionMode.fullAccess => (
    sandbox: PromptAssets.permissionsSandboxModeFullAccess,
    approval: PromptAssets.permissionsApprovalPolicyNever,
    writableRoot: false,
  ),
};
