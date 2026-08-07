/// Public lifecycle surface for hosting the Coder daemon.
library;

export 'package:coder_agent/coder_agent.dart'
    show
        Clock,
        GitignoreEnvironment,
        ModelProvider,
        ProviderOAuthGateway,
        SystemClock;
export 'src/bootstrap/application.dart'
    show DaemonAlreadyRunningException, DaemonApplication, DaemonHandle;
export 'src/bootstrap/config.dart'
    show
        DaemonConfig,
        DaemonEnvironment,
        IoDaemonEnvironment,
        defaultAllowedOrigins,
        generateBearerToken;
export 'src/bootstrap/data_reset.dart'
    show
        DaemonDataFiles,
        DaemonDataReset,
        DaemonDataResetException,
        DaemonDataResetFailureReason,
        NativeDaemonDataFiles;
export 'src/bootstrap/embedded.dart'
    show
        EmbeddedDaemonHandle,
        EmbeddedDaemonStartupException,
        EmbeddedDaemonStartupFailureReason;
export 'src/features/providers/infrastructure/provider_adapters.dart'
    show ProviderModelDiscovery;
export 'src/features/providers/infrastructure/provider_catalog.dart'
    show ProviderCatalogMetadata, ProviderCatalogMetadataSource;
export 'src/features/workspaces/infrastructure/git_workspace.dart'
    show ProcessGitWorkspaceGateway;
export 'src/features/workspaces/infrastructure/project_settings.dart'
    show FileProjectSettingsStore, ProjectSettingsStore;
export 'src/shared/ports/daemon_ports.dart'
    show
        GitWorkspaceGateway,
        IdGenerator,
        IoWorkspacePathGateway,
        ShellWorktreeHookRunner,
        UuidIdGenerator,
        WorkspacePathGateway,
        WorktreeHookRunner;
