import 'package:coder_workspace/src/feature_verifier.dart';

/// Complete traceability manifest for user-visible Coder capabilities.
const List<FeatureContract> coderFeatureManifest = <FeatureContract>[
  FeatureContract(
    id: 'daemon.management',
    description: 'Starts, connects, edits, and removes daemon hosts.',
    apiMethods: <String>['close'],
    routes: <String>[
      'DaemonSettingsRoute',
      'NewHostRoute',
      'EditHostRoute',
    ],
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
    id: 'worktree.lifecycle',
    description: 'Creates and safely archives Git worktrees.',
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
        'provider, and model, and changes the session model afterwards.',
    apiMethods: <String>[
      'listSessions',
      'createSession',
      'updateSessionModel',
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
