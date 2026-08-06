import 'package:coder_workspace/src/feature_verifier.dart';

const Set<FeatureSurface> _desktop = <FeatureSurface>{
  FeatureSurface.desktop,
};
// Web reaches a daemon exactly the way mobile does, through the shared
// remote-only bootstrap, so every scenario mobile supports it supports too.
const Set<FeatureSurface> _allSurfaces = <FeatureSurface>{
  FeatureSurface.desktop,
  FeatureSurface.mobile,
  FeatureSurface.web,
};

/// Complete traceability manifest for user-visible Coder capabilities.
const List<FeatureContract> coderFeatureManifest = <FeatureContract>[
  FeatureContract(
    id: 'daemon.management',
    description: 'Starts, connects, edits, and removes daemon hosts.',
    apiMethods: <String>['close'],
    routes: <String>['DaemonSettingsRoute', 'NewHostRoute', 'EditHostRoute'],
    requiredLayers: <FeatureVerificationLayer>{
      FeatureVerificationLayer.unit,
      FeatureVerificationLayer.contract,
      FeatureVerificationLayer.widget,
      FeatureVerificationLayer.e2e,
      FeatureVerificationLayer.platformSmoke,
    },
    e2eScenarios: <FeatureScenario>[
      FeatureScenario(
        id: 'remote_host_lifecycle',
        description: 'Adds, connects, edits, and removes a remote daemon.',
        surfaces: _allSurfaces,
      ),
      FeatureScenario(
        id: 'embedded_host_lifecycle',
        description: 'Starts and stops the app-owned embedded daemon.',
        surfaces: _desktop,
      ),
      FeatureScenario(
        id: 'connection_failure_recovery',
        description: 'Shows a failed host and reconnects after recovery.',
        surfaces: _allSurfaces,
      ),
    ],
  ),
  FeatureContract(
    id: 'daemon.authentication',
    description:
        'Uses one bearer token for complete local and remote daemon access.',
    requiredLayers: <FeatureVerificationLayer>{
      FeatureVerificationLayer.unit,
      FeatureVerificationLayer.contract,
      FeatureVerificationLayer.verticalSlice,
      FeatureVerificationLayer.widget,
      FeatureVerificationLayer.e2e,
    },
    e2eScenarios: <FeatureScenario>[
      FeatureScenario(
        id: 'valid_token_reconnect',
        description: 'Authenticates and reconnects with the persisted token.',
        surfaces: _allSurfaces,
      ),
      FeatureScenario(
        id: 'invalid_token_rejected',
        description: 'Rejects an invalid token without exposing daemon data.',
        surfaces: _allSurfaces,
      ),
    ],
  ),
  FeatureContract(
    id: 'daemon.exposure',
    description:
        'Configures and restarts the embedded daemon listener address and '
        'port.',
    requiredLayers: <FeatureVerificationLayer>{
      FeatureVerificationLayer.unit,
      FeatureVerificationLayer.contract,
      FeatureVerificationLayer.verticalSlice,
      FeatureVerificationLayer.widget,
      FeatureVerificationLayer.e2e,
      FeatureVerificationLayer.platformSmoke,
    },
    e2eScenarios: <FeatureScenario>[
      FeatureScenario(
        id: 'loopback_lan_restart',
        description: 'Restarts the embedded daemon across exposure modes.',
        surfaces: _desktop,
      ),
      FeatureScenario(
        id: 'restart_failure_recovery',
        description: 'Reports a restart failure and keeps a recoverable host.',
        surfaces: _desktop,
      ),
      FeatureScenario(
        id: 'port_change_restart',
        description: 'Applies a new listener port and reconnects the daemon.',
        surfaces: _desktop,
      ),
    ],
  ),
  FeatureContract(
    id: 'settings.reset',
    description:
        'Erases embedded daemon data and every device-local app setting '
        'while preserving managed Git checkouts, then restarts the '
        'app-owned daemon.',
    routes: <String>['AdvancedSettingsRoute'],
    requiredLayers: <FeatureVerificationLayer>{
      FeatureVerificationLayer.unit,
      FeatureVerificationLayer.verticalSlice,
      FeatureVerificationLayer.widget,
      FeatureVerificationLayer.e2e,
    },
    e2eScenarios: <FeatureScenario>[
      FeatureScenario(
        id: 'full_reset_restart',
        description:
            'Erases daemon data and app settings, then reconnects a daemon '
            'with a new server identity.',
        surfaces: _desktop,
      ),
      FeatureScenario(
        id: 'preserves_checkouts',
        description: 'Keeps managed Git checkouts after a full reset.',
        surfaces: _desktop,
      ),
    ],
  ),
  FeatureContract(
    id: 'workspace.catalog',
    description: 'Merges repositories and worktrees from every online host.',
    apiMethods: <String>['getWorkspaceCatalog', 'refreshWorkspace'],
    routes: <String>['WorkspaceHomeRoute'],
    requiredLayers: <FeatureVerificationLayer>{
      FeatureVerificationLayer.unit,
      FeatureVerificationLayer.contract,
      FeatureVerificationLayer.verticalSlice,
      FeatureVerificationLayer.widget,
      FeatureVerificationLayer.e2e,
    },
    e2eScenarios: <FeatureScenario>[
      FeatureScenario(
        id: 'multi_host_merge_refresh',
        description: 'Merges and refreshes workspaces from online hosts.',
        surfaces: _allSurfaces,
      ),
      FeatureScenario(
        id: 'empty_offline_recovery',
        description: 'Presents empty and offline states and recovers.',
        surfaces: _allSurfaces,
      ),
    ],
  ),
  FeatureContract(
    id: 'workspace.registration',
    description: 'Selects a daemon path and registers or removes a repository.',
    apiMethods: <String>[
      'registerWorkspace',
      'unregisterWorkspace',
      'suggestDirectories',
    ],
    requiredLayers: <FeatureVerificationLayer>{
      FeatureVerificationLayer.unit,
      FeatureVerificationLayer.contract,
      FeatureVerificationLayer.verticalSlice,
      FeatureVerificationLayer.widget,
      FeatureVerificationLayer.e2e,
    },
    e2eScenarios: <FeatureScenario>[
      FeatureScenario(
        id: 'browse_register_unregister',
        description: 'Browses a daemon path and registers then removes it.',
        surfaces: _allSurfaces,
      ),
      FeatureScenario(
        id: 'invalid_path_cancel',
        description: 'Rejects invalid paths and preserves state on cancel.',
        surfaces: _allSurfaces,
      ),
    ],
  ),
  FeatureContract(
    id: 'settings.language',
    description:
        'Selects the app UI language or follows the system locale, and keeps '
        'the choice across restarts.',
    routes: <String>['GeneralSettingsRoute'],
    requiredLayers: <FeatureVerificationLayer>{
      FeatureVerificationLayer.unit,
      FeatureVerificationLayer.widget,
      FeatureVerificationLayer.e2e,
    },
    e2eScenarios: <FeatureScenario>[
      FeatureScenario(
        id: 'selection_restart_persistence',
        description: 'Changes locale and preserves it across app restart.',
        surfaces: _allSurfaces,
      ),
      FeatureScenario(
        id: 'system_locale_fallback',
        description: 'Follows supported and unsupported system locales.',
        surfaces: _allSurfaces,
      ),
    ],
  ),
  FeatureContract(
    id: 'settings.appearance',
    description:
        'Selects the light or dark app theme or follows the system '
        'brightness, and keeps the choice across restarts.',
    requiredLayers: <FeatureVerificationLayer>{
      FeatureVerificationLayer.unit,
      FeatureVerificationLayer.widget,
      FeatureVerificationLayer.e2e,
    },
    e2eScenarios: <FeatureScenario>[
      FeatureScenario(
        id: 'restart_persistence',
        description: 'Changes the theme and preserves it across app restart.',
        surfaces: _allSurfaces,
      ),
      FeatureScenario(
        id: 'system_brightness_follow',
        description:
            'Tracks the platform brightness while following the system.',
        surfaces: _allSurfaces,
      ),
    ],
  ),
  FeatureContract(
    id: 'app.navigation',
    description:
        'Opens settings and daemon editing as pushed tasks that close back to '
        'the screen they were opened from, moves laterally between settings '
        'categories and workspace selections without changing the stack, and '
        'still closes to a sensible destination when entered by deep link.',
    requiredLayers: <FeatureVerificationLayer>{
      FeatureVerificationLayer.widget,
    },
  ),
  FeatureContract(
    id: 'settings.startup',
    description:
        'Registers the app with the operating system login items and chooses '
        'whether a login-time launch starts hidden in the tray.',
    requiredLayers: <FeatureVerificationLayer>{
      FeatureVerificationLayer.unit,
      FeatureVerificationLayer.widget,
      FeatureVerificationLayer.e2e,
    },
    e2eScenarios: <FeatureScenario>[
      FeatureScenario(
        id: 'registration_toggle',
        description: 'Enables and disables operating-system login startup.',
        surfaces: _desktop,
      ),
      FeatureScenario(
        id: 'hidden_login_launch',
        description: 'Starts a login-time launch hidden without window flash.',
        surfaces: _desktop,
      ),
    ],
  ),
  FeatureContract(
    id: 'desktop.residency',
    description:
        'Keeps the desktop app and its embedded daemon resident in the tray '
        'when the window is closed, reports daemon health without unbounded '
        'failure details, and quits only from the tray menu.',
    requiredLayers: <FeatureVerificationLayer>{
      FeatureVerificationLayer.unit,
      FeatureVerificationLayer.widget,
      FeatureVerificationLayer.e2e,
      FeatureVerificationLayer.platformSmoke,
    },
    e2eScenarios: <FeatureScenario>[
      FeatureScenario(
        id: 'close_hide_restore',
        description: 'Hides on close and restores from the resident process.',
        surfaces: _desktop,
      ),
      FeatureScenario(
        id: 'tray_quit',
        description: 'Quits only through the tray quit action.',
        surfaces: _desktop,
      ),
    ],
  ),
  FeatureContract(
    id: 'desktop.window.chrome',
    description:
        'Replaces Windows and Linux native title bars with localized menus, '
        'window controls, and a draggable application frame.',
    requiredLayers: <FeatureVerificationLayer>{
      FeatureVerificationLayer.unit,
      FeatureVerificationLayer.widget,
      FeatureVerificationLayer.e2e,
      FeatureVerificationLayer.platformSmoke,
    },
    e2eScenarios: <FeatureScenario>[
      FeatureScenario(
        id: 'localized_menu_navigation',
        description: 'Navigates through the localized desktop menu.',
        surfaces: _desktop,
      ),
      FeatureScenario(
        id: 'native_window_controls',
        description: 'Uses minimize, maximize, restore, and close controls.',
        surfaces: _desktop,
      ),
    ],
  ),
  FeatureContract(
    id: 'project.settings',
    description:
        'Edits per-project worktree lifecycle hooks stored in the repository '
        "root's coder.json.",
    apiMethods: <String>['getProjectSettings', 'saveProjectSettings'],
    routes: <String>['ProjectSettingsRoute'],
    requiredLayers: <FeatureVerificationLayer>{
      FeatureVerificationLayer.unit,
      FeatureVerificationLayer.contract,
      FeatureVerificationLayer.verticalSlice,
      FeatureVerificationLayer.widget,
      FeatureVerificationLayer.e2e,
    },
    e2eScenarios: <FeatureScenario>[
      FeatureScenario(
        id: 'load_save_persist_hooks',
        description: 'Loads, saves, and reloads project lifecycle hooks.',
        surfaces: _allSurfaces,
      ),
      FeatureScenario(
        id: 'hook_failure_feedback',
        description: 'Reports invalid hook settings and recovers after repair.',
        surfaces: _allSurfaces,
      ),
    ],
  ),
  FeatureContract(
    id: 'worktree.lifecycle',
    description:
        'Creates and safely archives Git worktrees, running the project '
        'setup and teardown hooks around each checkout.',
    apiMethods: <String>[
      'listGitBranches',
      'createWorktree',
      'previewWorktreeArchive',
      'archiveWorktree',
    ],
    routes: <String>['WorktreeRoute'],
    requiredLayers: <FeatureVerificationLayer>{
      FeatureVerificationLayer.unit,
      FeatureVerificationLayer.contract,
      FeatureVerificationLayer.verticalSlice,
      FeatureVerificationLayer.widget,
      FeatureVerificationLayer.e2e,
    },
    e2eScenarios: <FeatureScenario>[
      FeatureScenario(
        id: 'create_and_archive',
        description: 'Creates and safely archives a managed worktree.',
        surfaces: _allSurfaces,
      ),
      FeatureScenario(
        id: 'setup_failure_cleanup',
        description: 'Cleans up a checkout after setup hook failure.',
        surfaces: _allSurfaces,
      ),
      FeatureScenario(
        id: 'archive_preview_cancel',
        description: 'Previews archive effects and preserves on cancel.',
        surfaces: _allSurfaces,
      ),
    ],
  ),
  FeatureContract(
    id: 'session.lifecycle',
    description:
        'Starts sessions from the chat composer with a selected Agent, model, '
        'and collaboration mode, resolves the model provider automatically, '
        'and changes the session model, mode, reasoning effort, permission '
        'mode, or provider service tier afterwards.',
    apiMethods: <String>[
      'listSessions',
      'createSession',
      'updateSessionModel',
      'updateSessionMode',
      'updateSessionReasoningEffort',
      'updateSessionPermissionMode',
      'updateSessionServiceTier',
    ],
    routes: <String>['SessionRoute'],
    requiredLayers: <FeatureVerificationLayer>{
      FeatureVerificationLayer.unit,
      FeatureVerificationLayer.contract,
      FeatureVerificationLayer.verticalSlice,
      FeatureVerificationLayer.widget,
      FeatureVerificationLayer.e2e,
    },
    e2eScenarios: <FeatureScenario>[
      FeatureScenario(
        id: 'create_with_configuration',
        description: 'Creates a session with chosen agent, model, and mode.',
        surfaces: _allSurfaces,
      ),
      FeatureScenario(
        id: 'update_model_and_mode',
        description: 'Changes model and collaboration mode after creation.',
        surfaces: _allSurfaces,
      ),
      FeatureScenario(
        id: 'reconnect_persistence',
        description: 'Restores session configuration after reconnect.',
        surfaces: _allSurfaces,
      ),
    ],
  ),
  FeatureContract(
    id: 'session.home',
    description:
        'Starts a session without picking a project. The daemon provisions the '
        'user home directory as an implicit home workspace that no project '
        'list offers and that clients cannot unregister or archive, and the '
        'sidebar lists these sessions outside every project.',
    requiredLayers: <FeatureVerificationLayer>{
      FeatureVerificationLayer.unit,
      FeatureVerificationLayer.contract,
      FeatureVerificationLayer.verticalSlice,
      FeatureVerificationLayer.widget,
      FeatureVerificationLayer.e2e,
    },
    e2eScenarios: <FeatureScenario>[
      FeatureScenario(
        id: 'create_without_project',
        description:
            'Creates a session with no project and runs it in the home folder.',
        surfaces: _allSurfaces,
      ),
    ],
  ),
  FeatureContract(
    id: 'session.tabs',
    description: 'Opens, closes, restores, and switches session tabs.',
    requiredLayers: <FeatureVerificationLayer>{
      FeatureVerificationLayer.unit,
      FeatureVerificationLayer.widget,
      FeatureVerificationLayer.e2e,
    },
    e2eScenarios: <FeatureScenario>[
      FeatureScenario(
        id: 'open_switch_close_restore',
        description: 'Opens, switches, closes, and restores session tabs.',
        surfaces: _allSurfaces,
      ),
    ],
  ),
  FeatureContract(
    id: 'terminal.lifecycle',
    description:
        'Creates, attaches, resizes, restores, and terminates daemon-owned '
        'interactive terminal tabs.',
    apiMethods: <String>[
      'listTerminals',
      'createTerminal',
      'attachTerminal',
      'writeTerminal',
      'resizeTerminal',
      'terminateTerminal',
    ],
    routes: <String>['TerminalRoute'],
    requiredLayers: <FeatureVerificationLayer>{
      FeatureVerificationLayer.unit,
      FeatureVerificationLayer.contract,
      FeatureVerificationLayer.verticalSlice,
      FeatureVerificationLayer.widget,
      FeatureVerificationLayer.e2e,
      FeatureVerificationLayer.platformSmoke,
    },
    e2eScenarios: <FeatureScenario>[
      FeatureScenario(
        id: 'create_write_terminate',
        description:
            'Creates a real PTY, writes and observes output, then terminates '
            'it.',
        surfaces: _desktop,
      ),
    ],
  ),
  FeatureContract(
    id: 'terminal.settings',
    description:
        'Resolves and edits project and daemon-host shell configuration.',
    apiMethods: <String>['getTerminalShell', 'setTerminalShell'],
    requiredLayers: <FeatureVerificationLayer>{
      FeatureVerificationLayer.unit,
      FeatureVerificationLayer.contract,
      FeatureVerificationLayer.verticalSlice,
      FeatureVerificationLayer.widget,
    },
  ),
  FeatureContract(
    id: 'turn.execution',
    description: 'Streams, cancels, approves, rejects, and restores turns.',
    apiMethods: <String>[
      'startTurn',
      'cancelTurn',
      'resolveApproval',
      'subscribeTimeline',
    ],
    requiredLayers: <FeatureVerificationLayer>{
      FeatureVerificationLayer.unit,
      FeatureVerificationLayer.contract,
      FeatureVerificationLayer.verticalSlice,
      FeatureVerificationLayer.widget,
      FeatureVerificationLayer.e2e,
    },
    e2eScenarios: <FeatureScenario>[
      FeatureScenario(
        id: 'stream_and_restore',
        description: 'Streams a completed turn and restores its timeline.',
        surfaces: _allSurfaces,
      ),
      FeatureScenario(
        id: 'cancel_stream',
        description: 'Cancels an active stream and records cancellation.',
        surfaces: _allSurfaces,
      ),
      FeatureScenario(
        id: 'approve_and_reject',
        description: 'Approves and rejects tool requests with durable results.',
        surfaces: _allSurfaces,
      ),
      FeatureScenario(
        id: 'provider_failure_recovery',
        description: 'Shows provider failure and accepts a later retry.',
        surfaces: _allSurfaces,
      ),
    ],
  ),
  FeatureContract(
    id: 'conversation.turn.queue',
    description:
        'Queues prompts typed during a turn, starts them as it finishes, and '
        'tells the daemon so a sleeping agent wakes early.',
    apiMethods: <String>['notePendingInput'],
    requiredLayers: <FeatureVerificationLayer>{
      FeatureVerificationLayer.unit,
      FeatureVerificationLayer.contract,
      FeatureVerificationLayer.verticalSlice,
      FeatureVerificationLayer.widget,
    },
  ),
  FeatureContract(
    id: 'turn.question',
    description:
        'Blocks a turn on a structured agent question and records the user '
        'answer, including free-form input.',
    apiMethods: <String>['answerUserQuestion'],
    requiredLayers: <FeatureVerificationLayer>{
      FeatureVerificationLayer.unit,
      FeatureVerificationLayer.contract,
      FeatureVerificationLayer.verticalSlice,
      FeatureVerificationLayer.widget,
      FeatureVerificationLayer.e2e,
    },
    e2eScenarios: <FeatureScenario>[
      FeatureScenario(
        id: 'ask_and_answer',
        description: 'Answers a blocking agent question and resumes the turn.',
        surfaces: _allSurfaces,
      ),
    ],
  ),
  FeatureContract(
    id: 'tool.exec.session',
    description:
        'Runs and drives command sessions inside a turn, on plain pipes or a '
        'pseudo-terminal, in a chosen workspace directory, with scoped session '
        'lifetime and per-session approval.',
    requiredLayers: <FeatureVerificationLayer>{
      FeatureVerificationLayer.unit,
      FeatureVerificationLayer.verticalSlice,
      FeatureVerificationLayer.widget,
    },
  ),
  FeatureContract(
    id: 'tool.clock',
    description:
        'Reports the current UTC time and pauses a turn, ending the pause '
        'early when the user queues new input.',
    requiredLayers: <FeatureVerificationLayer>{
      FeatureVerificationLayer.unit,
      FeatureVerificationLayer.verticalSlice,
      FeatureVerificationLayer.widget,
    },
  ),
  FeatureContract(
    id: 'tool.search.deferred',
    description:
        'Withholds bulk tools from the model tool list and makes them '
        'callable through a search that persists across a session.',
    requiredLayers: <FeatureVerificationLayer>{
      FeatureVerificationLayer.unit,
      FeatureVerificationLayer.widget,
    },
  ),
  FeatureContract(
    id: 'mcp.resource.access',
    description:
        'Discovers MCP resources and templates, shows them per server, and '
        'reads one resource inside a turn.',
    requiredLayers: <FeatureVerificationLayer>{
      FeatureVerificationLayer.unit,
      FeatureVerificationLayer.contract,
      FeatureVerificationLayer.verticalSlice,
      FeatureVerificationLayer.widget,
    },
  ),
  FeatureContract(
    id: 'tool.context.budget',
    description:
        'Normalizes provider token counters, reports the tokens left in the '
        'model context window, and starts a fresh window on request.',
    requiredLayers: <FeatureVerificationLayer>{
      FeatureVerificationLayer.unit,
      FeatureVerificationLayer.contract,
      FeatureVerificationLayer.verticalSlice,
      FeatureVerificationLayer.widget,
    },
  ),
  FeatureContract(
    id: 'tool.image.context',
    description:
        'Loads a workspace image into the model conversation context and '
        'encodes it for the Responses and Chat Completions APIs.',
    requiredLayers: <FeatureVerificationLayer>{
      FeatureVerificationLayer.unit,
      FeatureVerificationLayer.verticalSlice,
      FeatureVerificationLayer.widget,
    },
  ),
  FeatureContract(
    id: 'conversation.attachments',
    description:
        'Uploads, sends, previews, exports, and restores user and agent files.',
    apiMethods: <String>['uploadAttachment', 'downloadAttachment'],
    requiredLayers: <FeatureVerificationLayer>{
      FeatureVerificationLayer.unit,
      FeatureVerificationLayer.contract,
      FeatureVerificationLayer.verticalSlice,
      FeatureVerificationLayer.widget,
      FeatureVerificationLayer.e2e,
      FeatureVerificationLayer.platformSmoke,
    },
    e2eScenarios: <FeatureScenario>[
      FeatureScenario(
        id: 'picker_cancel_retry',
        description: 'Cancels file selection and retries without losing input.',
        surfaces: _allSurfaces,
      ),
      FeatureScenario(
        id: 'upload_preview_restore',
        description: 'Uploads ordered files, previews them, and restores them.',
        surfaces: _allSurfaces,
      ),
      FeatureScenario(
        id: 'agent_publish_download',
        description: 'Publishes and downloads an agent-created attachment.',
        surfaces: _allSurfaces,
      ),
    ],
  ),
  FeatureContract(
    id: 'agent.definition.management',
    description:
        'Creates, validates, edits, archives, and resets Markdown Agents.',
    apiMethods: <String>[
      'listAgentDefinitions',
      'getAgentDefinition',
      'createAgentDefinition',
      'updateAgentDefinition',
      'archiveAgentDefinition',
      'resetAgentDefinition',
      'validateAgentDefinition',
      'listAgentTools',
    ],
    routes: <String>['AgentSettingsRoute'],
    requiredLayers: <FeatureVerificationLayer>{
      FeatureVerificationLayer.unit,
      FeatureVerificationLayer.contract,
      FeatureVerificationLayer.verticalSlice,
      FeatureVerificationLayer.widget,
      FeatureVerificationLayer.e2e,
    },
    e2eScenarios: <FeatureScenario>[
      FeatureScenario(
        id: 'create_validate_edit_reload',
        description: 'Creates, validates, edits, and reloads an Agent file.',
        surfaces: _allSurfaces,
      ),
      FeatureScenario(
        id: 'invalid_definition_rejected',
        description: 'Rejects invalid Markdown without overwriting the Agent.',
        surfaces: _allSurfaces,
      ),
      FeatureScenario(
        id: 'archive_and_reset',
        description: 'Archives a custom Agent and resets a built-in Agent.',
        surfaces: _allSurfaces,
      ),
    ],
  ),
  FeatureContract(
    id: 'mcp.server.management',
    description:
        'Adds, edits, tests, and removes external MCP servers and shows '
        'their connection status and discovered tools.',
    apiMethods: <String>[
      'listMcpServers',
      'addMcpServer',
      'updateMcpServer',
      'removeMcpServer',
      'testMcpServer',
      'setMcpSecret',
    ],
    routes: <String>['McpSettingsRoute'],
    requiredLayers: <FeatureVerificationLayer>{
      FeatureVerificationLayer.unit,
      FeatureVerificationLayer.contract,
      FeatureVerificationLayer.verticalSlice,
      FeatureVerificationLayer.widget,
      FeatureVerificationLayer.e2e,
    },
    e2eScenarios: <FeatureScenario>[
      FeatureScenario(
        id: 'add_edit_test_remove',
        description: 'Adds, edits, tests, and removes an MCP server.',
        surfaces: _allSurfaces,
      ),
      FeatureScenario(
        id: 'offline_and_secret_recovery',
        description: 'Shows offline state and reconnects with a stored secret.',
        surfaces: _allSurfaces,
      ),
    ],
  ),
  FeatureContract(
    id: 'mcp.tool.execution',
    description:
        'Executes namespaced MCP tools inside a turn with approval, and '
        'degrades safely when a server is offline.',
    requiredLayers: <FeatureVerificationLayer>{
      FeatureVerificationLayer.unit,
      FeatureVerificationLayer.verticalSlice,
      FeatureVerificationLayer.e2e,
    },
    e2eScenarios: <FeatureScenario>[
      FeatureScenario(
        id: 'approve_execute_result',
        description: 'Approves a namespaced tool and renders its result.',
        surfaces: _allSurfaces,
      ),
      FeatureScenario(
        id: 'reject_and_offline',
        description: 'Rejects execution and degrades safely when offline.',
        surfaces: _allSurfaces,
      ),
    ],
  ),
  FeatureContract(
    id: 'skill.management',
    description:
        'Lists, creates, edits, toggles, and deletes skills from built-in, '
        'user-home, config, and project sources.',
    apiMethods: <String>[
      'listSkills',
      'getSkill',
      'createSkill',
      'updateSkill',
      'deleteSkill',
      'setSkillEnabled',
    ],
    routes: <String>['SkillSettingsRoute'],
    requiredLayers: <FeatureVerificationLayer>{
      FeatureVerificationLayer.unit,
      FeatureVerificationLayer.contract,
      FeatureVerificationLayer.verticalSlice,
      FeatureVerificationLayer.widget,
      FeatureVerificationLayer.e2e,
    },
    e2eScenarios: <FeatureScenario>[
      FeatureScenario(
        id: 'source_crud_toggle',
        description: 'Manages and toggles skills from every supported source.',
        surfaces: _allSurfaces,
      ),
      FeatureScenario(
        id: 'invalid_edit_preserves_file',
        description: 'Rejects invalid edits without corrupting the skill.',
        surfaces: _allSurfaces,
      ),
    ],
  ),
  FeatureContract(
    id: 'skill.invocation',
    description:
        'Injects the enabled skill catalog into a turn and loads skill '
        'instructions through the skill tool.',
    requiredLayers: <FeatureVerificationLayer>{
      FeatureVerificationLayer.unit,
      FeatureVerificationLayer.verticalSlice,
      FeatureVerificationLayer.widget,
      FeatureVerificationLayer.e2e,
    },
    e2eScenarios: <FeatureScenario>[
      FeatureScenario(
        id: 'enabled_injection_and_load',
        description: 'Injects enabled skills and loads their instructions.',
        surfaces: _allSurfaces,
      ),
      FeatureScenario(
        id: 'disabled_skill_excluded',
        description: 'Excludes a disabled skill from a subsequent turn.',
        surfaces: _allSurfaces,
      ),
    ],
  ),
  FeatureContract(
    id: 'composer.file.mention',
    description:
        'Completes gitignore-aware worktree file paths from an @ token in the '
        'composer and inserts them into the prompt.',
    apiMethods: <String>['searchFiles'],
    requiredLayers: <FeatureVerificationLayer>{
      FeatureVerificationLayer.unit,
      FeatureVerificationLayer.contract,
      FeatureVerificationLayer.verticalSlice,
      FeatureVerificationLayer.widget,
      FeatureVerificationLayer.e2e,
    },
    e2eScenarios: <FeatureScenario>[
      FeatureScenario(
        id: 'mention_insert_path',
        description: 'Completes an @ token into a worktree-relative path.',
        surfaces: _allSurfaces,
      ),
      FeatureScenario(
        id: 'no_match_dismiss',
        description: 'Dismisses the mention list and sends the typed text.',
        surfaces: _allSurfaces,
      ),
    ],
  ),
  FeatureContract(
    id: 'composer.slash.command',
    description:
        'Completes client, skill, and agent commands from a / token and either '
        'runs the app action or expands the prompt.',
    apiMethods: <String>['listCommands'],
    requiredLayers: <FeatureVerificationLayer>{
      FeatureVerificationLayer.unit,
      FeatureVerificationLayer.contract,
      FeatureVerificationLayer.verticalSlice,
      FeatureVerificationLayer.widget,
      FeatureVerificationLayer.e2e,
    },
    e2eScenarios: <FeatureScenario>[
      FeatureScenario(
        id: 'client_command_dispatch',
        description: 'Runs an app-owned command without starting a turn.',
        surfaces: _allSurfaces,
      ),
      FeatureScenario(
        id: 'agent_command_prompt',
        description: 'Expands an agent command template into the prompt.',
        surfaces: _allSurfaces,
      ),
    ],
  ),
  FeatureContract(
    id: 'agent.delegation',
    description:
        'Delegates to an allowlisted subagent and exposes its session.',
    requiredLayers: <FeatureVerificationLayer>{
      FeatureVerificationLayer.unit,
      FeatureVerificationLayer.verticalSlice,
      FeatureVerificationLayer.widget,
      FeatureVerificationLayer.e2e,
    },
    e2eScenarios: <FeatureScenario>[
      FeatureScenario(
        id: 'allowlisted_child_navigation',
        description: 'Delegates to an allowlisted Agent and opens its child.',
        surfaces: _allSurfaces,
      ),
      FeatureScenario(
        id: 'disallowed_delegation_rejected',
        description: 'Rejects delegation outside the Agent allowlist.',
        surfaces: _allSurfaces,
      ),
    ],
  ),
  FeatureContract(
    id: 'provider.catalog',
    description: 'Lists provider presets, connections, and available models.',
    apiMethods: <String>[
      'listProviderCatalog',
      'listProviderConnections',
      'refreshProviderCatalog',
      'listProviderModels',
    ],
    routes: <String>['ProviderSettingsRoute'],
    requiredLayers: <FeatureVerificationLayer>{
      FeatureVerificationLayer.unit,
      FeatureVerificationLayer.contract,
      FeatureVerificationLayer.verticalSlice,
      FeatureVerificationLayer.widget,
      FeatureVerificationLayer.e2e,
    },
    e2eScenarios: <FeatureScenario>[
      FeatureScenario(
        id: 'presets_models_refresh',
        description: 'Lists presets and refreshes available model catalogs.',
        surfaces: _allSurfaces,
      ),
      FeatureScenario(
        id: 'catalog_failure_retry',
        description: 'Shows catalog failure and succeeds on retry.',
        surfaces: _allSurfaces,
      ),
    ],
  ),
  FeatureContract(
    id: 'provider.default.model',
    description:
        'Resolves the chat model from the session override, the agent '
        'definition, the daemon default, then the first usable provider '
        'model, and edits the daemon default.',
    // ProviderSettingsRoute already belongs to provider.catalog; a route maps
    // to exactly one feature, and the card is only part of that page.
    apiMethods: <String>['getDefaultModel', 'setDefaultModel'],
    requiredLayers: <FeatureVerificationLayer>{
      FeatureVerificationLayer.unit,
      FeatureVerificationLayer.contract,
      FeatureVerificationLayer.verticalSlice,
      FeatureVerificationLayer.widget,
    },
  ),
  FeatureContract(
    id: 'provider.connection.management',
    description: 'Connects and disconnects provider presets.',
    apiMethods: <String>[
      'connectProviderApiKey',
      'connectProviderNone',
      'disconnectProvider',
    ],
    requiredLayers: <FeatureVerificationLayer>{
      FeatureVerificationLayer.unit,
      FeatureVerificationLayer.contract,
      FeatureVerificationLayer.verticalSlice,
      FeatureVerificationLayer.widget,
      FeatureVerificationLayer.e2e,
    },
    e2eScenarios: <FeatureScenario>[
      FeatureScenario(
        id: 'api_key_none_disconnect',
        description: 'Connects supported credential modes and disconnects.',
        surfaces: _allSurfaces,
      ),
      FeatureScenario(
        id: 'invalid_credential_recovery',
        description: 'Reports invalid credentials and accepts a correction.',
        surfaces: _allSurfaces,
      ),
    ],
  ),
  FeatureContract(
    id: 'provider.oauth',
    description: 'Starts, observes, cancels, and refreshes provider OAuth.',
    apiMethods: <String>[
      'startProviderAuth',
      'providerAuthStatus',
      'cancelProviderAuth',
    ],
    requiredLayers: <FeatureVerificationLayer>{
      FeatureVerificationLayer.unit,
      FeatureVerificationLayer.contract,
      FeatureVerificationLayer.verticalSlice,
      FeatureVerificationLayer.widget,
      FeatureVerificationLayer.e2e,
    },
    e2eScenarios: <FeatureScenario>[
      FeatureScenario(
        id: 'authorize_and_refresh',
        description: 'Completes OAuth and refreshes the connected catalog.',
        surfaces: _allSurfaces,
      ),
      FeatureScenario(
        id: 'cancel_and_error_recovery',
        description: 'Cancels OAuth and recovers from authorization failure.',
        surfaces: _allSurfaces,
      ),
    ],
  ),
  FeatureContract(
    id: 'provider.custom',
    description: 'Creates, edits, and removes advanced compatible providers.',
    apiMethods: <String>[
      'createCustomProvider',
      'updateCustomProvider',
      'deleteCustomProvider',
    ],
    requiredLayers: <FeatureVerificationLayer>{
      FeatureVerificationLayer.unit,
      FeatureVerificationLayer.contract,
      FeatureVerificationLayer.verticalSlice,
      FeatureVerificationLayer.widget,
      FeatureVerificationLayer.e2e,
    },
    e2eScenarios: <FeatureScenario>[
      FeatureScenario(
        id: 'create_edit_delete',
        description: 'Creates, edits, reloads, and deletes a custom provider.',
        surfaces: _allSurfaces,
      ),
      FeatureScenario(
        id: 'validation_and_model_failure',
        description: 'Rejects invalid configuration and reports model failure.',
        surfaces: _allSurfaces,
      ),
    ],
  ),
];
