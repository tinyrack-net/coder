import 'package:coder_workspace/src/feature_verifier.dart';

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
  ),
  FeatureContract(
    id: 'daemon.exposure',
    description:
        'Restarts the embedded daemon on loopback or all IPv4 interfaces.',
    requiredLayers: <FeatureVerificationLayer>{
      FeatureVerificationLayer.unit,
      FeatureVerificationLayer.contract,
      FeatureVerificationLayer.verticalSlice,
      FeatureVerificationLayer.widget,
      FeatureVerificationLayer.e2e,
      FeatureVerificationLayer.platformSmoke,
    },
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
    },
  ),
  FeatureContract(
    id: 'desktop.residency',
    description:
        'Keeps the desktop app and its embedded daemon resident in the tray '
        'when the window is closed, and quits only from the tray menu.',
    requiredLayers: <FeatureVerificationLayer>{
      FeatureVerificationLayer.unit,
      FeatureVerificationLayer.widget,
      FeatureVerificationLayer.platformSmoke,
    },
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
    },
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
  ),
  FeatureContract(
    id: 'session.lifecycle',
    description:
        'Starts sessions from the chat composer with a selected Agent, '
        'provider, model, and collaboration mode, and changes the session '
        'model or mode afterwards.',
    apiMethods: <String>[
      'listSessions',
      'createSession',
      'updateSessionModel',
      'updateSessionMode',
    ],
    routes: <String>['SessionRoute'],
    requiredLayers: <FeatureVerificationLayer>{
      FeatureVerificationLayer.unit,
      FeatureVerificationLayer.contract,
      FeatureVerificationLayer.verticalSlice,
      FeatureVerificationLayer.widget,
      FeatureVerificationLayer.e2e,
    },
  ),
  FeatureContract(
    id: 'session.tabs',
    description: 'Opens, closes, restores, and switches session tabs.',
    requiredLayers: <FeatureVerificationLayer>{
      FeatureVerificationLayer.unit,
      FeatureVerificationLayer.widget,
      FeatureVerificationLayer.e2e,
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
    },
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
  ),
  FeatureContract(
    id: 'provider.connection.management',
    description: 'Connects presets and manages defaults and disconnection.',
    apiMethods: <String>[
      'connectProviderApiKey',
      'connectProviderNone',
      'disconnectProvider',
      'setDefaultProvider',
      'setDefaultProviderModel',
    ],
    requiredLayers: <FeatureVerificationLayer>{
      FeatureVerificationLayer.unit,
      FeatureVerificationLayer.contract,
      FeatureVerificationLayer.verticalSlice,
      FeatureVerificationLayer.widget,
      FeatureVerificationLayer.e2e,
    },
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
    },
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
  ),
];
