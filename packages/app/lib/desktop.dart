/// Public composition surface used by the desktop application package.
library;

export 'package:client/client.dart' show DaemonCredentials, HostEndpoint;

export 'main_desktop.dart' show runDesktopApp;
export 'src/app/composition/app_services.dart'
    show AppServices, WebSocketHostClientFactory;
export 'src/features/desktop/infrastructure/desktop_bootstrap.dart'
    show createDesktopServices;
export 'src/features/hosts/domain/host_models.dart'
    show
        EmbeddedDaemonExposure,
        FactoryResetFailure,
        FactoryResetFailureReason,
        HostConnectionFailure,
        HostFailureReason;
export 'src/features/hosts/domain/host_ports.dart'
    show
        EmbeddedDaemonDataEraser,
        EmbeddedDaemonLauncher,
        EmbeddedDaemonSession,
        HostClientFactory;
