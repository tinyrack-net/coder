import 'dart:io';

import 'conversation_adversity_e2e_test.dart' as conversation_adversity;
import 'conversation_history_e2e_test.dart' as conversation_history;
import 'daemon_workspace_e2e_test.dart' as daemon_workspace;
import 'debug_conversation_e2e_test.dart' as conversation;
import 'debug_desktop_shell_e2e_test.dart' as desktop_shell;
import 'plugin_harness_e2e_test.dart' as plugin_harness;
import 'project_worktree_e2e_test.dart' as project_worktree;
import 'provider_e2e_test.dart' as provider;
import 'relay_e2e_test.dart' as relay;
import 'settings_desktop_e2e_test.dart' as settings_desktop;

const _selectedScenarios = String.fromEnvironment('TINEST_E2E_SCENARIOS');

void main() {
  _markApplicationReady();
  final selected = _selectedScenarios.split(',').toSet();
  final registrations = <String, void Function()>{
    'daemon-workspace': daemon_workspace.main,
    'project-worktree': project_worktree.main,
    'plugin-harness': plugin_harness.main,
    'relay': relay.main,
    'conversation-adversity': conversation_adversity.main,
    'conversation-history': conversation_history.main,
    'conversation': conversation.main,
    'provider': provider.main,
    'settings-desktop': settings_desktop.main,
    'desktop-shell': desktop_shell.main,
  };
  for (final entry in registrations.entries) {
    if (selected.contains(entry.key)) entry.value();
  }
}

void _markApplicationReady() {
  final markerPath = Platform.environment['TINYRACK_TINEST_E2E_READY_FILE'];
  if (markerPath == null || markerPath.isEmpty) return;
  final marker = File(markerPath);
  marker.parent.createSync(recursive: true);
  File('$markerPath.tmp')
    ..writeAsStringSync('ready\n', flush: true)
    ..renameSync(markerPath);
}
