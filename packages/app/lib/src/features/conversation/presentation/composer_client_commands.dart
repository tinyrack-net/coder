import 'package:app/src/app/router/app_router.dart';
import 'package:app/src/features/conversation/domain/composer_commands.dart';
import 'package:flutter/widgets.dart';

/// App commands a composer without a session cannot carry out.
///
/// The home and draft composers create their session from the first prompt, so
/// there is no current session for `/new` to be new relative to, and no
/// conversation for `/compact` to summarize.
const Set<ClientCommandAction> sessionlessClientActions = <ClientCommandAction>{
  ClientCommandAction.newSession,
  ClientCommandAction.compact,
  ClientCommandAction.goal,
};

/// Runs an app-owned command for a composer that has no session yet.
///
/// Shared by the home and draft composers so `/` behaves the same before and
/// after a session exists. Always reports the submission as consumed: a client
/// command never becomes a turn.
Future<bool> runSessionlessClientCommand(
  BuildContext context,
  ComposerCommandInvocation invocation, {
  required String hostId,
  required VoidCallback onToggleMode,
}) async {
  switch (invocation.command.action!) {
    // The composer clears its own draft before dispatching, and typing `/`
    // already lists every command, so help only reopens that list. A new
    // session is what the next prompt makes, so `/new` has nothing to add;
    // [sessionlessClientActions] keeps it out of the catalog.
    case ClientCommandAction.clear:
    case ClientCommandAction.help:
    case ClientCommandAction.newSession:
    case ClientCommandAction.compact:
    case ClientCommandAction.goal:
      break;
    case ClientCommandAction.toggleMode:
      onToggleMode();
    case ClientCommandAction.openAgentSettings:
      AgentSettingsRoute(hostId: hostId).go(context);
    case ClientCommandAction.openSkillSettings:
      SkillSettingsRoute(hostId: hostId).go(context);
  }
  return true;
}
