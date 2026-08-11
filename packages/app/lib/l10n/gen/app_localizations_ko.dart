// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get commonCancel => '취소';

  @override
  String get commonSave => '저장';

  @override
  String get commonSaving => '저장 중…';

  @override
  String get commonCreate => '생성';

  @override
  String get commonCreating => '생성 중…';

  @override
  String get commonConfirm => '확인';

  @override
  String get commonDelete => '삭제';

  @override
  String get commonRetry => '다시 시도';

  @override
  String get commonClose => '닫기';

  @override
  String get commonCopy => '복사';

  @override
  String get commonStop => '중지';

  @override
  String get commonName => '이름';

  @override
  String get commonKind => '유형';

  @override
  String get commonDescription => '설명';

  @override
  String get commonRunning => '실행 중';

  @override
  String get commonDone => '완료';

  @override
  String get commonDetails => '자세히';

  @override
  String get commonSaved => '저장했습니다.';

  @override
  String get commonDeleted => '삭제했습니다.';

  @override
  String get commonCopied => '클립보드에 복사했습니다.';

  @override
  String get commonActionFailed => '문제가 발생했습니다.';

  @override
  String get toastRegionLabel => '알림';

  @override
  String get settingsTitle => '설정';

  @override
  String get settingsLoading => '설정 불러오는 중';

  @override
  String settingsRefreshFailed(String error) {
    return '설정을 새로 불러오지 못했습니다: $error';
  }

  @override
  String get settingsSectionApp => 'App';

  @override
  String get settingsSectionDaemon => 'Daemon';

  @override
  String get settingsDaemonSelectLabel => 'Daemon';

  @override
  String get settingsDaemonSelectEmpty => 'Daemon 없음';

  @override
  String settingsDaemonOffline(String label) {
    return '$label이(가) 연결되어 있지 않습니다.';
  }

  @override
  String get settingsCategoryGeneral => 'General';

  @override
  String get settingsCategoryProjects => 'Projects';

  @override
  String get settingsCategoryAgent => 'Agent';

  @override
  String get settingsCategoryProvider => 'Provider';

  @override
  String get settingsCategoryPermission => '권한';

  @override
  String get settingsCategoryDaemon => 'Daemons';

  @override
  String get settingsCategoryAdvanced => '고급';

  @override
  String get advancedResetSection => '초기화';

  @override
  String get advancedResetTitle => '전체 초기화';

  @override
  String get advancedResetDescription =>
      '임베디드 daemon의 데이터베이스, 자격 증명, MCP 및 에이전트 설정, 스킬, 첨부 파일을 삭제하고 모든 앱 설정과 저장된 원격 daemon 토큰을 지웁니다. worktrees 폴더의 Git 체크아웃은 디스크에 남습니다.';

  @override
  String get advancedResetDescriptionAppOnly =>
      '이 기기의 모든 앱 설정과 저장된 원격 daemon 토큰을 지웁니다. 원격 daemon의 데이터는 그대로 유지됩니다.';

  @override
  String get advancedResetAction => '전체 초기화';

  @override
  String get advancedResetRunning => '초기화 중…';

  @override
  String get advancedResetConfirmTitle => '전체 초기화할까요?';

  @override
  String get advancedResetConfirmBody =>
      '임베디드 daemon의 모든 세션, 워크스페이스 등록, 프로바이더 연결, 에이전트, 스킬, MCP 서버가 삭제되고 모든 앱 설정과 원격 daemon 프로필 및 토큰도 함께 삭제됩니다. daemon은 기본 포트로 돌아갑니다. Git 체크아웃은 디스크에 남지만 다시 추가해야 합니다. 되돌릴 수 없습니다.';

  @override
  String get advancedResetConfirmAccept => '초기화';

  @override
  String get advancedResetDone => '초기 설정으로 되돌렸습니다.';

  @override
  String get advancedResetFailedTitle => '초기화 실패';

  @override
  String advancedResetFailedDaemonRunning(String appDisplayName) {
    return '다른 $appDisplayName daemon이 데이터 디렉터리를 사용 중입니다. 종료한 뒤 다시 시도하세요. 삭제된 항목은 없습니다.';
  }

  @override
  String advancedResetFailedFilesystem(String error) {
    return '일부 daemon 파일을 삭제하지 못했습니다: $error';
  }

  @override
  String advancedResetFailedIncomplete(String appDisplayName) {
    return 'daemon 데이터는 삭제했지만 앱 설정을 지우지 못했습니다. $appDisplayName를 다시 시작하세요.';
  }

  @override
  String get settingsRequiresOnlineDaemon => '온라인 daemon 연결이 필요합니다.';

  @override
  String get generalAppearanceSection => '외관';

  @override
  String get generalAppearanceLabel => '테마';

  @override
  String get generalAppearanceDescription => '앱 전체에 적용되며 다음 실행에도 유지됩니다.';

  @override
  String get generalAppearanceSystem => '시스템 테마 따름';

  @override
  String get generalAppearanceLight => '라이트';

  @override
  String get generalAppearanceDark => '다크';

  @override
  String get generalLanguageSection => '언어';

  @override
  String get generalLanguageLabel => '표시 언어';

  @override
  String get generalLanguageDescription => '앱 전체에 적용되며 즉시 반영됩니다.';

  @override
  String get generalLanguageSystem => '시스템 설정 따름';

  @override
  String get generalStartupSection => '시작';

  @override
  String get generalStartupAtBootLabel => '로그인 시 시작';

  @override
  String generalStartupAtBootDescription(String appDisplayName) {
    return '로그인하면 운영체제가 $appDisplayName를 실행해 내장 daemon이 계속 동작합니다.';
  }

  @override
  String get generalStartupMinimizedLabel => '최소화된 상태로 시작';

  @override
  String get generalStartupMinimizedDescription =>
      '로그인 시 실행되면 창을 열지 않고 바로 트레이로 들어갑니다.';

  @override
  String get generalAppearanceFailed => '테마를 바꾸지 못했습니다.';

  @override
  String get generalLanguageFailed => '언어를 바꾸지 못했습니다.';

  @override
  String get generalStartupFailed => '시작 설정을 바꾸지 못했습니다.';

  @override
  String generalStartupCloseNotice(String appDisplayName) {
    return '창을 닫아도 $appDisplayName는 트레이에서 계속 실행됩니다.';
  }

  @override
  String trayTooltip(String appDisplayName) {
    return '$appDisplayName';
  }

  @override
  String get trayShowWindow => '창 열기';

  @override
  String get trayHideWindow => '창 숨기기';

  @override
  String get trayOpenSettings => '설정';

  @override
  String get trayQuit => '종료';

  @override
  String get desktopMenuFile => '파일';

  @override
  String get desktopMenuView => '보기';

  @override
  String get desktopMenuHelp => '도움말';

  @override
  String desktopMenuAbout(String appDisplayName) {
    return '$appDisplayName 정보';
  }

  @override
  String get desktopWindowMinimize => '최소화';

  @override
  String get desktopWindowMaximize => '최대화';

  @override
  String get desktopWindowRestore => '복원';

  @override
  String get desktopWindowClose => '트레이로 닫기';

  @override
  String get workspacesTitle => 'Workspaces';

  @override
  String get workspaceSidebarExpand => '사이드바 열기';

  @override
  String get workspaceSidebarCollapse => '사이드바 접기';

  @override
  String get workspaceNewSession => '새 session';

  @override
  String get sessionDefaultTitle => '코딩 세션';

  @override
  String get workspaceNewTab => '새 탭';

  @override
  String get workspaceNewTerminal => '새 터미널';

  @override
  String terminalTabTitle(int number) {
    return '터미널 $number';
  }

  @override
  String get workspaceLoading => '워크스페이스 불러오는 중';

  @override
  String get workspaceCatalogLoading => '워크스페이스 목록 불러오는 중';

  @override
  String get workspaceCreatingWorktree => '워크트리 생성 중…';

  @override
  String get workspaceStartingSession => '세션 시작 중…';

  @override
  String get workspaceTerminalStarting => '터미널 시작 중';

  @override
  String workspaceTerminalStartFailed(String error) {
    return '터미널을 시작하지 못했습니다: $error';
  }

  @override
  String get terminalCloseTitle => '터미널을 종료할까요?';

  @override
  String get terminalCloseConfirm => '이 탭을 닫으면 셸과 하위 프로세스가 종료돼요.';

  @override
  String get terminalTerminate => '종료';

  @override
  String get terminalConnectionFailed => '터미널 연결에 실패했어요';

  @override
  String get terminalConnecting => '터미널 연결 중';

  @override
  String get conversationLoading => '대화 불러오는 중';

  @override
  String get directoryBrowserLoading => '디렉터리 불러오는 중';

  @override
  String get terminalCreationFailed => '터미널을 만들 수 없어요';

  @override
  String get terminalWorktreeUnavailable =>
      '이 worktree는 더 이상 사용할 수 없습니다. 다른 worktree를 선택하세요.';

  @override
  String get terminalShellStartFailed =>
      '설정된 터미널 셸을 시작할 수 없습니다. 터미널 설정을 확인하고 다시 시도하세요.';

  @override
  String get terminalMenuCopy => '복사';

  @override
  String get terminalMenuPaste => '붙여넣기';

  @override
  String get terminalMenuSelectAll => '전체 선택';

  @override
  String get terminalMenuClearSelection => '선택 해제';

  @override
  String get terminalMenuClearScreen => '화면 지우기';

  @override
  String get projectSettingsHookHeading => 'Worktree 수명주기 훅';

  @override
  String get projectSettingsShellHeading => '프로젝트 터미널 셸';

  @override
  String get projectSettingsShellHelp =>
      '이 프로젝트에서 여는 터미널의 데몬 호스트 셸을 덮어써요. 실행 파일을 비워 두면 호스트 기본값을 사용해요.';

  @override
  String get projectSettingsShellExecutable => '셸 실행 파일';

  @override
  String get projectSettingsShellArguments => '셸 인자 (한 줄에 하나)';

  @override
  String get projectSettingsHostShellHeading => '데몬 호스트 기본 셸';

  @override
  String get projectSettingsHostShellHelp =>
      '프로젝트에서 별도로 지정하지 않으면 이 데몬 호스트의 모든 프로젝트에 사용해요. 실행 파일을 비워 두면 운영체제 기본값을 사용해요.';

  @override
  String get workspaceAllSessions => '모든 session';

  @override
  String get workspaceSplitRight => '오른쪽으로 분할';

  @override
  String get workspaceSplitDown => '아래로 분할';

  @override
  String get workspaceResizePanes => 'Pane 크기 조절';

  @override
  String get workspaceSwitchTab => '탭 전환';

  @override
  String get workspaceMoveTabToPane => '활성 탭을 다른 pane으로 이동';

  @override
  String get workspaceCloseTab => '탭 닫기';

  @override
  String get workspaceNewWorkspace => 'New workspace';

  @override
  String get workspaceWorktreeMenu => 'Worktree 메뉴';

  @override
  String get workspaceProjectMenu => 'Project 메뉴';

  @override
  String get workspaceUnregister => 'Project 제거';

  @override
  String workspaceUnregisterTitle(String name) {
    return '$name을 제거할까요?';
  }

  @override
  String workspaceUnregisterBody(String appName) {
    return '$appName 목록에서만 제거하며 repository와 파일은 디스크에 그대로 둡니다.';
  }

  @override
  String get workspaceArchive => 'Archive';

  @override
  String get workspaceArchiveBlockedTitle => 'Archive할 수 없습니다';

  @override
  String workspaceArchiveBlockedBody(int count) {
    return '실행 중인 session $count개를 먼저 중지하세요.';
  }

  @override
  String workspaceArchiveTitle(String name) {
    return '$name을 Archive할까요?';
  }

  @override
  String get workspaceArchiveDirty => '커밋하지 않은 변경이 있습니다.\n';

  @override
  String workspaceArchiveUnpushed(int count) {
    return '$count개의 push하지 않은 commit이 있습니다.\n';
  }

  @override
  String workspaceArchiveRemovesDirectory(String appName) {
    return '$appName가 만든 checkout 디렉터리가 제거됩니다.';
  }

  @override
  String get workspaceArchiveKeepsDirectory => '등록만 숨기고 디스크의 checkout은 유지합니다.';

  @override
  String get workspaceArchiveRisky => '위험을 확인하고 Archive';

  @override
  String get workspaceNoDaemons => '설정된 daemon이 없습니다.';

  @override
  String get workspaceNoConnectedDaemons => '연결된 daemon이 없습니다.';

  @override
  String get workspaceNoWorkspaces => '아직 workspace가 없습니다.';

  @override
  String get workspaceNoProjectSessions => '프로젝트 없음';

  @override
  String get workspaceNoProjectOption => '프로젝트 없음 (홈 폴더)';

  @override
  String get workspaceProjectChip => '프로젝트';

  @override
  String get workspaceProjectChipTooltip => '프로젝트 선택';

  @override
  String get workspaceProjectAdd => '추가';

  @override
  String get workspaceWorktreeNew => '새 worktree';

  @override
  String get workspaceWorktreeChipTooltip => 'Worktree 선택';

  @override
  String get workspaceBaseBranchChip => '기반 branch';

  @override
  String get workspaceBaseBranchChipTooltip => '기반 branch 선택';

  @override
  String get workspaceAddProjectFirst => '먼저 프로젝트를 추가하세요.';

  @override
  String get workspaceSelectProject => '프로젝트를 선택하세요.';

  @override
  String get workspaceCheckoutMissing => '프로젝트 checkout을 찾을 수 없습니다.';

  @override
  String get workspaceDaemonRequired => 'Daemon 연결이 필요합니다.';

  @override
  String get workspaceOpenDaemonSettings => 'Daemon 설정';

  @override
  String get workspaceStartFailedTitle => '세션을 시작하지 못했습니다';

  @override
  String get composerSelectProviderModel => '사용할 Provider와 모델을 먼저 선택하세요.';

  @override
  String get errorBranchAlreadyExists => '같은 이름의 브랜치가 이미 있습니다. 다른 이름을 사용하세요.';

  @override
  String get errorWorktreePathInUse => '다른 체크아웃이 이미 그 폴더를 사용하고 있습니다.';

  @override
  String get errorInvalidBranchName => '그 이름은 Git 브랜치로 사용할 수 없습니다.';

  @override
  String get errorGitCommandFailed => 'Git 명령이 실패했습니다. 아래 내용은 Git이 출력한 그대로입니다.';

  @override
  String get errorWorkspaceNotFound => '그 프로젝트는 Daemon에 더 이상 등록되어 있지 않습니다.';

  @override
  String get errorWorkspaceNotGit => '그 프로젝트는 Git 저장소가 아니라 워크트리를 만들 수 없습니다.';

  @override
  String get errorWorkspaceProtected => 'Daemon이 직접 관리하는 폴더입니다.';

  @override
  String get errorWorktreeNotFound => '그 체크아웃은 Daemon에 더 이상 등록되어 있지 않습니다.';

  @override
  String get errorWorktreeArchiveBlocked => '지금은 이 체크아웃을 보관할 수 없습니다.';

  @override
  String get errorAgentDefinitionNotFound =>
      '그 Agent는 더 이상 존재하지 않습니다. 다른 Agent를 선택하세요.';

  @override
  String get errorAgentDefinitionUnusable =>
      '그 Agent로는 세션을 시작할 수 없습니다. 다른 Agent를 선택하세요.';

  @override
  String get errorProtocolMismatch =>
      '앱과 Daemon의 프로토콜 버전이 다릅니다. 두 쪽을 같은 릴리스로 업데이트하세요.';

  @override
  String get errorInvalidProjectSettings =>
      '프로젝트의 coder.json을 읽을 수 없습니다. 파일을 고친 뒤 다시 시도하세요.';

  @override
  String get errorRequestTimeout => 'Daemon이 제때 응답하지 않았습니다. 다시 시도하세요.';

  @override
  String get errorInternalDaemon =>
      'Daemon에서 예기치 못한 문제가 발생했습니다. 문제를 알릴 때 아래 내용을 복사해 주세요.';

  @override
  String get errorSessionTurnActive =>
      '이 session은 turn을 실행 중입니다. 끝나기를 기다리거나 중지한 뒤 설정을 바꿔 주세요.';

  @override
  String get errorSessionSettingFailed => 'Session 설정을 바꾸지 못했습니다.';

  @override
  String get hostStatusOnline => '온라인';

  @override
  String get hostStatusConnecting => '연결 중';

  @override
  String get hostStatusReconnecting => '재연결 중';

  @override
  String get hostStatusOffline => '오프라인';

  @override
  String get hostStatusError => '오류';

  @override
  String get hostStatusConflict => '중복 daemon';

  @override
  String get hostStatusIdle => '자동 연결 꺼짐';

  @override
  String get hostStatusPending => '대기 중';

  @override
  String get embeddedDaemonName => '내장 daemon';

  @override
  String get hostErrorMissingToken => 'Bearer token을 입력하세요.';

  @override
  String get hostErrorNoToken => 'Bearer token이 없습니다.';

  @override
  String get hostErrorDuplicate => '같은 daemon이 이미 등록되어 있습니다.';

  @override
  String get hostErrorUnauthorized => 'Daemon이 bearer token을 거부했습니다.';

  @override
  String get hostErrorEmbeddedPortInUse => '선택한 포트를 이미 사용 중입니다.';

  @override
  String hostErrorEmbeddedAlreadyRunning(String appName) {
    return '이 컴퓨터에서 $appName가 이미 실행 중이며 로컬 daemon을 점유하고 있습니다. 트레이에서 실행 중인 창을 열거나, 종료한 뒤 다시 시도하세요.';
  }

  @override
  String get hostErrorLocalNetworkUnreachable =>
      'Daemon에 연결하지 못했습니다. Daemon이 실행 중인지, 그리고 이 사이트의 로컬 네트워크 접근을 허용했는지 확인하세요.';

  @override
  String get hostErrorRelayPairingUnavailable =>
      '이 플랫폼에서는 relay 페어링을 사용할 수 없습니다.';

  @override
  String get hostErrorServerIdentityMismatch =>
      '이 주소는 저장된 daemon이 아닌 다른 daemon으로 연결됩니다.';

  @override
  String get hostErrorCredentialMismatch => '저장된 자격 증명이 이 연결 경로와 맞지 않습니다.';

  @override
  String get appSettingsTitle => '앱 설정';

  @override
  String get appSettingsLocalSection => '로컬 실행';

  @override
  String get appSettingsEmbeddedSubtitle =>
      '앱과 함께 시작하고 앱 종료 시 중지합니다. 시작 실패는 앱 사용을 막지 않습니다.';

  @override
  String get appSettingsExposure => '네트워크 접근 허용';

  @override
  String get appSettingsExposureSubtitle =>
      '끄면 이 기기에서만, 켜면 모든 IPv4 네트워크 인터페이스에서 연결할 수 있습니다.';

  @override
  String get appSettingsEmbeddedPort => '포트';

  @override
  String get appSettingsEmbeddedPortHelp =>
      '1~65535 사이의 포트를 선택하세요. 적용하면 실행 중인 내장 daemon이 재시작됩니다.';

  @override
  String get appSettingsEmbeddedPortInvalid => '1~65535 사이의 정수를 입력하세요.';

  @override
  String get appSettingsEmbeddedPortApply => '적용';

  @override
  String get appSettingsEmbeddedFailureTitle => '내장 daemon을 시작할 수 없습니다';

  @override
  String appSettingsEmbeddedPortConflict(int port) {
    return '포트 $port을(를) 다른 프로세스에서 사용 중입니다. 다른 포트를 입력해 적용하거나 포트가 비워진 후 다시 시도하세요.';
  }

  @override
  String get appSettingsRemoteSection => '원격 daemons';

  @override
  String get appSettingsAddRemote => '원격 daemon 추가';

  @override
  String get relayPairTitle => '기기 연결';

  @override
  String get relayConnectDaemonTitle => 'Daemon 연결';

  @override
  String get relayConnectDaemonDescription =>
      'Daemon에 연결할 방법을 선택하세요. 릴레이 링크에서도 daemon 트래픽은 종단 간 암호화됩니다.';

  @override
  String get relayConnectScanDescription => 'Daemon에 표시된 일회용 QR 코드를 스캔합니다.';

  @override
  String get relayConnectPasteTitle => '연결 링크 붙여넣기';

  @override
  String get relayConnectPasteDescription => 'Daemon에 표시된 일회용 링크를 붙여넣습니다.';

  @override
  String get relayConnectDirectDescription =>
      'WebSocket 주소와 bearer token으로 연결합니다.';

  @override
  String get relayConfirmTitle => 'Daemon 연결 확인';

  @override
  String get relayConfirmDescription => '이 기기를 등록하기 전에 daemon과 릴레이를 확인하세요.';

  @override
  String get relayConfirmDaemon => 'Daemon ID';

  @override
  String get relayConfirmRelay => '릴레이 서버';

  @override
  String get relayConfirmExpires => '링크 만료';

  @override
  String get relayShare => '공유';

  @override
  String get relayRefreshLink => '새 링크 만들기';

  @override
  String get relayEnableTitle => '이 daemon을 릴레이로 연결';

  @override
  String get relayEnableDescription =>
      '다른 기기에서 접근할 수 있도록 daemon이 별도의 Tinyrack 릴레이 서버에 outbound 암호화 연결을 엽니다.';

  @override
  String get relayEnableAction => '릴레이 연결 활성화';

  @override
  String get settingsCategoryConnection => '연결';

  @override
  String get relayPairDescription =>
      'daemon에 표시된 일회용 링크를 붙여 넣으세요. 코드와 파일은 relay를 통과할 때도 종단 간 암호화됩니다.';

  @override
  String get relayPairLink => '연결 링크';

  @override
  String get relayPairDeviceName => '이 기기 이름';

  @override
  String get relayPairAction => '연결';

  @override
  String get relayPairScan => 'QR 코드 스캔';

  @override
  String get relayPairCameraUnavailable =>
      'QR 스캔은 Android와 iOS에서 사용할 수 있습니다. 이 기기에서는 연결 링크를 붙여 넣으세요.';

  @override
  String relayPairCameraError(String appDisplayName) {
    return '$appDisplayName에서 카메라를 열 수 없습니다. 시스템 설정에서 카메라 권한을 허용한 뒤 다시 시도하세요.';
  }

  @override
  String get relayPairCameraRetry => '카메라 다시 시도';

  @override
  String get relayPairQrSemantics => '일회용 기기 연결 링크 QR 코드';

  @override
  String relayPairInvalid(String appDisplayName) {
    return '올바른 $appDisplayName 연결 링크를 입력하세요.';
  }

  @override
  String get relayPairExpired =>
      '이 연결 링크가 만료되었거나 이미 사용되었습니다. daemon에서 새 링크를 만드세요.';

  @override
  String get relayPairFailed =>
      '이 daemon을 연결하지 못했습니다. daemon에서 새 링크를 만든 뒤 다시 시도하세요.';

  @override
  String get relayAdvancedDirect => '고급 직접 연결';

  @override
  String get relayDevicesTitle => '연결된 기기';

  @override
  String get relayDevicesDescription =>
      '새 기기를 위한 10분짜리 링크를 만들거나 더 이상 연결하면 안 되는 기기를 해제하세요.';

  @override
  String get relayCreateLink => '연결 링크 만들기';

  @override
  String relayLinkExpires(String expiresAt) {
    return '$expiresAt에 만료';
  }

  @override
  String get relayNoDevices => '승인된 기기가 없습니다.';

  @override
  String get relayRevoke => '해제';

  @override
  String relayRevokeTitle(String name) {
    return '$name 기기를 해제할까요?';
  }

  @override
  String get relayRevokeBody =>
      '기기의 현재 relay 연결이 즉시 종료됩니다. 다시 연결하려면 새 연결 링크가 필요합니다.';

  @override
  String get relayPathDirect => '직접 연결';

  @override
  String get relayPathRelay => 'Relay';

  @override
  String get relayConnectionDetails => '연결 세부 정보';

  @override
  String get relayApprovedDevices => '기기';

  @override
  String get appSettingsNoRemotes => '저장된 원격 daemon이 없습니다.';

  @override
  String get appSettingsStopEmbeddedTitle => '내장 daemon을 중지할까요?';

  @override
  String get appSettingsStopEmbeddedBody =>
      '이 앱이 소유한 daemon과 연결만 중지합니다. 원격 및 standalone daemon은 영향을 받지 않습니다.';

  @override
  String get appSettingsEditConnection => '연결 편집';

  @override
  String get appSettingsAutoConnect => '앱 시작 시 자동 연결';

  @override
  String get appSettingsReconnect => '다시 연결';

  @override
  String get appSettingsProviderSettings => 'Provider 설정';

  @override
  String get appSettingsAddRemoteTitle => '원격 daemon 추가';

  @override
  String get appSettingsEditRemoteTitle => '원격 daemon 편집';

  @override
  String get appSettingsAddress => 'WebSocket 주소';

  @override
  String get appSettingsLabelPlaceholder => '운영 daemon';

  @override
  String get appSettingsNewToken => '새 Bearer token (변경할 때만 입력)';

  @override
  String get appSettingsBearerToken => 'Bearer token';

  @override
  String get appSettingsRemoteDetails => 'Daemon';

  @override
  String get appSettingsConnectionBehaviour => '연결';

  @override
  String get appSettingsConnectionFailed => '연결을 저장하지 못했어요';

  @override
  String appSettingsDeleteTitle(String label) {
    return '$label을 삭제할까요?';
  }

  @override
  String get appSettingsDeleteBody => '연결과 저장된 bearer token도 이 기기에서 제거됩니다.';

  @override
  String get projectSettingsHeading => 'Projects';

  @override
  String get projectSettingsNoProjects => '등록된 project가 없습니다.';

  @override
  String get projectSettingsSelectProject => 'Project를 선택하세요.';

  @override
  String get projectSettingsProjectList => 'Project 목록';

  @override
  String projectSettingsCount(int count) {
    return '$count projects';
  }

  @override
  String get projectSettingsCopyPath => '파일 위치 복사';

  @override
  String get projectSettingsHookHelp =>
      '한 줄에 명령 하나를 적으면 daemon 호스트의 shell에서 순서대로 실행됩니다. CODER_WORKTREE_PATH, CODER_PROJECT_PATH, CODER_BRANCH 환경변수를 사용할 수 있습니다.';

  @override
  String get projectSettingsSetup => 'Setup (worktree 생성 후)';

  @override
  String get projectSettingsTeardown => 'Teardown (worktree 제거 전)';

  @override
  String get agentSettingsHeading => 'Agents';

  @override
  String get agentSettingsSelectAgent => 'Agent를 선택하세요.';

  @override
  String agentSettingsCount(int count) {
    return '$count definitions';
  }

  @override
  String agentSettingsModeStale(String mode) {
    return '$mode · 해석 실패';
  }

  @override
  String get agentSettingsAdd => 'Agent 추가';

  @override
  String get agentSettingsAddTitle => 'Agent 추가';

  @override
  String get agentSettingsList => 'Agent 목록';

  @override
  String get agentSettingsCopyPath => '파일 위치 복사';

  @override
  String get agentSettingsReset => '기본값으로 초기화';

  @override
  String get agentSettingsCustomPrompt => 'Custom system prompt 사용';

  @override
  String get agentSettingsSessionModel => '세션마다 선택';

  @override
  String get agentSettingsPinnedModel => '고정 provider/model';

  @override
  String get agentSettingsDefinitionHeading => '정의';

  @override
  String get agentSettingsPromptHeading => '시스템 프롬프트';

  @override
  String get agentSettingsSystemPrompt => '시스템 프롬프트 (Markdown)';

  @override
  String get agentSettingsModelHeading => '모델';

  @override
  String get agentSettingsProviderConnectionId => 'Provider 연결 ID';

  @override
  String get agentSettingsModelId => 'Model ID';

  @override
  String get agentSettingsBehaviourHeading => '동작';

  @override
  String get agentSettingsReasoning => '추론 강도';

  @override
  String get agentSettingsPermission => '권한 모드';

  @override
  String get agentSettingsBuiltinTools => '내장 도구';

  @override
  String get agentSettingsToolGroupFilesystem => '파일';

  @override
  String get agentSettingsToolGroupEditing => '편집';

  @override
  String get agentSettingsToolGroupExecution => '명령 실행';

  @override
  String get agentSettingsToolGroupAttachments => '첨부';

  @override
  String get agentSettingsToolGroupMcp => 'MCP';

  @override
  String get agentSettingsToolGroupCollaboration => '협업';

  @override
  String get agentSettingsToolGroupSession => '세션';

  @override
  String agentSettingsToolGroupSummary(int enabled, int total) {
    return '$total개 중 $enabled개 사용';
  }

  @override
  String get agentSettingsToolGroupAlwaysOn => '항상 사용 가능';

  @override
  String get agentSettingsSubagents => '호출 가능한 Subagent';

  @override
  String get agentSettingsNoSubagents => '등록된 Subagent가 없습니다.';

  @override
  String agentSettingsArchiveTitle(String name) {
    return '$name 을(를) 보관할까요?';
  }

  @override
  String get agentSettingsArchiveBody =>
      '이미 이 agent를 쓰고 있는 세션은 그대로 실행됩니다. 새 세션에서만 더 이상 제공되지 않습니다.';

  @override
  String agentSettingsResetTitle(String name) {
    return '$name 을(를) 기본값으로 되돌릴까요?';
  }

  @override
  String get agentSettingsResetBody =>
      '이 기본 agent에 적용한 수정 사항이 모두 사라지며 되돌릴 수 없습니다.';

  @override
  String get agentSettingsArchiveFailed => 'Agent를 보관하지 못했습니다.';

  @override
  String get agentSettingsResetFailed => '기본 Agent를 되돌리지 못했습니다.';

  @override
  String get agentSettingsArchived => '보관했습니다.';

  @override
  String get agentSettingsResetDone => '기본 Agent로 되돌렸습니다.';

  @override
  String get agentSettingsSaveFailedTitle => 'Agent 저장 실패';

  @override
  String get agentSettingsReload => 'Reload';

  @override
  String get agentSettingsOverwrite => 'Overwrite';

  @override
  String get agentSettingsIdInvalid => '영문 소문자, 숫자, -, _만 사용할 수 있습니다.';

  @override
  String get agentSettingsIdTaken => '이미 존재하는 Agent ID입니다.';

  @override
  String get agentSettingsIdLabel => 'ID (파일명)';

  @override
  String get agentSettingsNameRequired => '이름을 입력하세요.';

  @override
  String get providerSettingsTitle => 'Provider 설정';

  @override
  String get providerSettingsRequiresDaemon => 'Daemon 연결이 필요합니다.';

  @override
  String get providerSettingsRefreshCatalog => 'Catalog 갱신';

  @override
  String get providerSettingsCatalogStatus => 'Catalog 메타데이터';

  @override
  String get providerSettingsCatalogBundled => '번들된 스냅샷';

  @override
  String get providerSettingsCatalogCached => '마지막 정상 캐시';

  @override
  String get providerSettingsCatalogFresh => '최근 갱신됨';

  @override
  String get providerSettingsCatalogStale => '갱신 필요 · 로컬 메타데이터 사용 가능';

  @override
  String get providerSettingsDefaultModelTitle => '기본 모델';

  @override
  String get providerSettingsDefaultModelDescription =>
      '세션과 Agent 모두 모델을 지정하지 않았을 때 사용합니다.';

  @override
  String get providerSettingsDefaultModelAutomatic => '자동';

  @override
  String get providerSettingsDefaultModelNone =>
      '연동된 프로바이더에 사용할 수 있는 모델이 없습니다.';

  @override
  String get providerSettingsDefaultModelUnavailable =>
      '이 모델을 사용할 수 없어 세션은 첫 번째 사용 가능한 모델을 사용합니다.';

  @override
  String get providerSettingsDefaultModelChoose => '변경';

  @override
  String providerSettingsAuthTitle(String name) {
    return '$name 연결';
  }

  @override
  String get providerSettingsExperimental => '실험적';

  @override
  String get providerSettingsDisconnectTitle => 'Provider 연결 해제';

  @override
  String providerSettingsDisconnectBody(String name) {
    return '$name 연결을 해제할까요? 기존 agent 이력은 유지됩니다.';
  }

  @override
  String get providerSettingsDisconnect => '연결 해제';

  @override
  String get providerSettingsDeleteCustomTitle => 'Custom Provider 삭제';

  @override
  String providerSettingsDeleteCustomBody(String name) {
    return '$name 및 저장된 credential을 삭제할까요? 기존 session 이력은 유지됩니다.';
  }

  @override
  String get providerSettingsConnected => '연결됨';

  @override
  String get providerSettingsNoConnections => '연결된 Provider가 없습니다.';

  @override
  String get providerSettingsSelectConnection => '관리할 Provider를 선택하세요.';

  @override
  String get providerSettingsRequiredFields => '이름과 Base URL을 입력하세요.';

  @override
  String get providerSettingsApiKeyRequired => 'API key를 입력하세요.';

  @override
  String get providerSettingsEditAdvanced => '고급 설정 편집';

  @override
  String get providerSettingsActions => '연결 작업';

  @override
  String get providerSettingsAdd => 'Provider 추가';

  @override
  String get providerSettingsNoPresets => '추가 가능한 preset이 없습니다.';

  @override
  String get providerSettingsCustomSubtitle => '고급 설정: 자체 endpoint 연결';

  @override
  String get providerSettingsCustomName => '커스텀 프로바이더';

  @override
  String get providerSettingsRefreshFailed => 'Catalog를 갱신하지 못했어요';

  @override
  String get providerSettingsOAuthPending => '로그인 대기 중';

  @override
  String get providerSettingsOpenBrowser => '브라우저 열기';

  @override
  String get providerSettingsReconnect => '다시 연결';

  @override
  String get providerSettingsModelPrefix => '모델 Prefix';

  @override
  String get providerSettingsModelPrefixHelp =>
      'openai/gpt-5.6-col 같은 모델 ID에 사용됩니다.';

  @override
  String get providerSettingsModelPrefixInvalid =>
      '소문자, 숫자, 하이픈, 밑줄을 사용해 1~64자로 입력하세요.';

  @override
  String get providerSettingsModelPrefixConflict =>
      '이미 사용 중인 모델 Prefix입니다. 갱신된 제안을 사용해 보세요.';

  @override
  String providerSettingsConnectTitle(String name) {
    return '$name 연결';
  }

  @override
  String get providerSettingsConnect => '연결';

  @override
  String get providerSettingsApiKey => 'API 키';

  @override
  String get providerSettingsBaseUrl => 'Base URL';

  @override
  String get providerSettingsConnectionFailed => '프로바이더 연결에 실패했습니다.';

  @override
  String get providerSettingsAuthUrlFailed => '인증 페이지를 열 수 없습니다.';

  @override
  String get providerSettingsCustomTitle => 'Custom Provider 고급 설정';

  @override
  String get providerSettingsApiFormat => 'API 형식';

  @override
  String get providerSettingsRequiresApiKey => 'API key 필요';

  @override
  String get providerSettingsManualModels => '수동 model ID';

  @override
  String get providerSettingsModelLookupFailedTitle => 'Model 자동 조회 실패';

  @override
  String get providerSettingsModelLookupFailedBody =>
      'Provider가 model 목록을 제공하지 않았습니다. 사용할 model ID를 입력하세요.';

  @override
  String get providerSettingsLater => '나중에';

  @override
  String get providerStatusConnecting => '연결 중';

  @override
  String get providerStatusConnected => '연결됨';

  @override
  String get providerStatusDegraded => '제한된 연결';

  @override
  String get providerStatusError => '오류';

  @override
  String get providerStatusReauthRequired => '재로그인 필요';

  @override
  String get providerStatusDisconnected => '연결 해제됨';

  @override
  String get providerAuthStored => '저장된 credential';

  @override
  String get providerAuthOAuth => 'OAuth';

  @override
  String get providerAuthNone => '인증 없음';

  @override
  String get modelPickerTitle => '모델 선택';

  @override
  String get modelPickerSearch => '모델 검색';

  @override
  String get modelPickerNoResults => '검색 결과가 없습니다.';

  @override
  String get composerPlan => 'Plan';

  @override
  String get composerRun => '실행';

  @override
  String get composerMode => '모드';

  @override
  String get composerPlanTooltip => '계획만 세웁니다. Shift+Tab으로 전환';

  @override
  String get composerRunTooltip => '요청을 바로 수행합니다. Shift+Tab으로 전환';

  @override
  String get composerSelectAgent => 'Agent 선택';

  @override
  String get composerAgent => 'Agent';

  @override
  String get composerAgentLocked => '세션 생성 후에는 Agent를 바꿀 수 없습니다.';

  @override
  String get composerModel => '모델';

  @override
  String get composerSelectModel => '모델 선택';

  @override
  String get composerInheritModel => 'Agent 기본값 사용';

  @override
  String get composerInheritDefaultModel => '기본 모델 사용';

  @override
  String get composerStartHint => '코딩 요청으로 새 session을 시작하세요.';

  @override
  String get composerNoPrimaryAgent => '사용 가능한 primary Agent가 없습니다.';

  @override
  String get composerConnectProviderFirst => '프로바이더를 먼저 연동하세요.';

  @override
  String get composerInputHint => '코딩 요청을 입력하세요…';

  @override
  String get composerReasoningEffort => '추론';

  @override
  String get composerSelectReasoningEffort => '추론 강도 선택';

  @override
  String get composerInheritReasoningEffort => '에이전트 기본값';

  @override
  String get composerPermissionMode => '권한';

  @override
  String get composerSelectPermissionMode => '권한 선택';

  @override
  String get composerInheritPermissionMode => '에이전트 기본값';

  @override
  String get composerPermissionReadOnly => '읽기 전용';

  @override
  String get composerPermissionAsk => '변경 전 확인';

  @override
  String get composerPermissionWorkspaceWrite => '작업 공간 접근';

  @override
  String get composerPermissionFullAccess => '전체 접근';

  @override
  String get permissionPickerDescription => '에이전트가 확인 없이 할 수 있는 작업을 선택하세요.';

  @override
  String get permissionDescriptionReadOnly =>
      '파일을 읽을 수 있습니다. 파일 변경, 명령 실행, 변경 가능한 외부 도구는 차단합니다.';

  @override
  String get permissionDescriptionAsk =>
      '파일 읽기는 바로 허용하고, 파일 변경·명령 실행·변경 가능한 외부 도구는 먼저 확인합니다.';

  @override
  String get permissionDescriptionWorkspaceWrite =>
      '작업 공간 파일은 읽고 수정할 수 있습니다. 명령 실행과 변경 가능한 외부 도구는 먼저 확인합니다.';

  @override
  String get permissionDescriptionFullAccess =>
      '파일 변경, 명령 실행, 외부 도구를 확인 없이 허용합니다. 신뢰할 수 있는 작업에서만 사용하세요.';

  @override
  String get permissionSettingsTitle => '권한';

  @override
  String get permissionSettingsSection => '기본 권한';

  @override
  String get permissionSettingsSectionDescription =>
      '별도 권한을 선택하지 않은 에이전트는 이 데몬 기본값을 상속합니다.';

  @override
  String get permissionSettingsChange => '기본 권한 변경';

  @override
  String get permissionSettingsSaveFailed => '기본 권한을 변경하지 못했습니다';

  @override
  String get permissionChangeFailed => '권한을 변경하지 못했습니다';

  @override
  String get permissionSettingsDaemonDefault => '데몬 기본값';

  @override
  String get composerFastMode => '빠르게';

  @override
  String get composerFastModeTooltip => '크레딧을 더 쓰고 응답을 빠르게 받아요';

  @override
  String get composerFastModeOnTooltip => '빠른 모드가 켜져 있어요. 누르면 표준 등급을 사용해요';

  @override
  String get composerSettingLocked => '설정은 턴 사이에만 바꿀 수 있어요';

  @override
  String get composerSendLabel => '메시지 보내기';

  @override
  String get composerQueueLabel => '메시지 대기열에 넣기';

  @override
  String get composerQueueTooltip => '현재 턴이 끝나면 보내요';

  @override
  String get composerQueuedEdit => '대기 중인 메시지 편집';

  @override
  String get composerQueuedSendNow => '대기 중인 메시지 지금 보내기';

  @override
  String composerQueuedAttachments(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '파일 $countString개',
    );
    return '$_temp0';
  }

  @override
  String composerQueuedFailed(String reason) {
    return '전송되지 않음 · $reason';
  }

  @override
  String get composerAttachLabel => '파일 첨부';

  @override
  String composerRemoveAttachment(String name) {
    return '$name 제거';
  }

  @override
  String composerAttachmentTooLarge(int limit) {
    return '첨부 파일은 하나당 $limit MB 미만이어야 합니다.';
  }

  @override
  String composerAttachmentTooMany(int limit) {
    return '한 턴에 첨부할 수 있는 파일은 최대 $limit개입니다.';
  }

  @override
  String get composerMoreSettings => '설정 더 보기';

  @override
  String get composerUseDefault => '기본값 사용';

  @override
  String get composerEnabled => '사용';

  @override
  String get chatEmptyTitle => '코딩 요청을 입력하세요.';

  @override
  String get chatEmptyExample => '예) 테스트를 실행하고 실패 원인을 고쳐줘';

  @override
  String get chatNoticeCancelled => '중지됨';

  @override
  String chatNoticeFailed(String message) {
    return '실패 · $message';
  }

  @override
  String get chatCopyResponse => '응답 복사';

  @override
  String chatMoreLines(int count) {
    return '… $count줄 더';
  }

  @override
  String chatApprovalRequired(String tool) {
    return '승인 필요 · $tool';
  }

  @override
  String get chatApprovalDeny => '거부';

  @override
  String get chatApprovalAllow => '승인';

  @override
  String get chatPlanTitle => '계획';

  @override
  String usageInput(int tokens) {
    return '입력 $tokens';
  }

  @override
  String usageInputCached(int tokens, int cached) {
    return '입력 $tokens(캐시 $cached)';
  }

  @override
  String usageOutput(int tokens) {
    return '출력 $tokens';
  }

  @override
  String usageOutputReasoning(int tokens, int reasoning) {
    return '출력 $tokens(추론 $reasoning)';
  }

  @override
  String usageTotal(int tokens) {
    return '합계 $tokens';
  }

  @override
  String usageThroughput(double rate) {
    final intl.NumberFormat rateNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String rateString = rateNumberFormat.format(rate);

    return '$rateString tok/s';
  }

  @override
  String toolExecRunning(int lines) {
    return '실행 중 · $lines줄';
  }

  @override
  String chatAnswerTyped(String answer) {
    return '$answer (직접 입력)';
  }

  @override
  String get chatSleepWaiting => '대기 중';

  @override
  String chatSleepRemaining(int seconds) {
    return '$seconds초 남음';
  }

  @override
  String chatSleepDone(int seconds) {
    return '$seconds초 대기함';
  }

  @override
  String toolSearchFound(int found, int remaining) {
    return '$found개 로드 · $remaining개 남음';
  }

  @override
  String subagentTrackHeader(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '서브 에이전트 $count개',
    );
    return '$_temp0';
  }

  @override
  String subagentTrackRunning(int count) {
    return '$count개 실행 중';
  }

  @override
  String get subagentStatusRunning => '실행 중';

  @override
  String get subagentStatusCompleted => '완료';

  @override
  String get subagentStatusInterrupted => '중단됨';

  @override
  String get subagentStatusErrored => '실패';

  @override
  String get subagentStatusWaitingForApproval => '승인 대기 중';

  @override
  String get subagentReadOnlyNotice => '서브 에이전트 대화 · 읽기 전용';

  @override
  String get chatToolSubagentQueued => '대기열에 추가됨';

  @override
  String chatToolSubagentCount(int count) {
    return '에이전트 $count개';
  }

  @override
  String chatDeferredTools(int count) {
    return '검색으로 사용할 수 있는 도구 $count개';
  }

  @override
  String toolMcpResources(int count) {
    return '리소스 $count개';
  }

  @override
  String toolMcpResourceTemplates(int count) {
    return '템플릿 $count개';
  }

  @override
  String toolMcpResourceRead(int count) {
    return '블록 $count개';
  }

  @override
  String toolImageLoaded(int bytes) {
    return '$bytes바이트 확인';
  }

  @override
  String get chatQuestionSubmit => '답변';

  @override
  String get chatQuestionNext => '다음';

  @override
  String get chatQuestionNavigation => '질문';

  @override
  String get chatQuestionSubmitting => '답변 제출 중';

  @override
  String get chatQuestionOther => '직접 입력';

  @override
  String get chatQuestionOtherPlaceholder => '답변을 입력하세요';

  @override
  String get chatPlanStepPending => '시작 전';

  @override
  String get chatPlanStepInProgress => '진행 중';

  @override
  String get chatPlanStepCompleted => '완료';

  @override
  String get chatPlanPrompt => '이 계획대로 진행할까요?';

  @override
  String get chatPlanKeepPlanning => '계속 계획';

  @override
  String get chatPlanRunInNewSession => '새 세션에서 실행';

  @override
  String get chatPlanRun => '계획대로 실행';

  @override
  String get planImplementPrompt => '계획을 실행해줘.';

  @override
  String get planFreshSessionPreamble =>
      '이전 에이전트가 사용자의 요청을 위해 아래 계획을 세웠습니다. 이 계획을 새로운 컨텍스트에서 구현하세요. 계획을 사용자 의도의 근거로 삼되, 필요한 파일은 다시 읽고 구현과 검증까지 진행하세요.';

  @override
  String get toolRejected => '거부됨';

  @override
  String get toolFailed => '실패';

  @override
  String get toolEmptyFile => '빈 파일';

  @override
  String toolReadLines(int count) {
    return '$count줄 읽음';
  }

  @override
  String toolListItems(int count) {
    return '항목 $count개';
  }

  @override
  String toolListEntries(int directories, int files) {
    return '디렉터리 $directories · 파일 $files';
  }

  @override
  String get toolNoMatches => '일치 없음';

  @override
  String toolMatches(int matches, int files) {
    return '$files개 파일에서 $matches건';
  }

  @override
  String toolMatchesTruncated(int matches, int files) {
    return '$files개 파일에서 $matches건 이상';
  }

  @override
  String get toolNoPaths => '파일 없음';

  @override
  String toolPaths(int count) {
    return '파일 $count개';
  }

  @override
  String toolPathsTruncated(int count) {
    return '파일 $count개 이상';
  }

  @override
  String toolAttached(String name) {
    return '$name 첨부';
  }

  @override
  String toolSkillLoaded(String name) {
    return '$name 불러옴';
  }

  @override
  String toolSkills(int count) {
    return '스킬 $count개';
  }

  @override
  String toolSkillsTruncated(int count) {
    return '스킬 $count개 이상';
  }

  @override
  String toolEditFiles(int count) {
    return '편집($count개 파일)';
  }

  @override
  String toolPatchSummary(int added, int removed, int files) {
    return '+$added -$removed · $files개 파일';
  }

  @override
  String toolCommandResult(int exitCode, int lines) {
    return '종료 코드 $exitCode · $lines줄';
  }

  @override
  String get toolTitleEdit => '편집';

  @override
  String toolTitleEditPath(String path) {
    return '편집($path)';
  }

  @override
  String toolTitleAttach(String path) {
    return '첨부($path)';
  }

  @override
  String toolTitleAttachment(String id) {
    return '첨부 파일($id)';
  }

  @override
  String get toolTitleNow => '현재 시각()';

  @override
  String toolTitleSleep(int milliseconds) {
    return '슬립(${milliseconds}ms)';
  }

  @override
  String get toolTitleSleepUnknown => '슬립()';

  @override
  String toolTitleSpawn(String task) {
    return '생성($task)';
  }

  @override
  String toolTitleSend(String target) {
    return '전송($target)';
  }

  @override
  String toolTitleFollowup(String target) {
    return '후속 작업($target)';
  }

  @override
  String get toolTitleWait => '대기()';

  @override
  String toolTitleInterrupt(String target) {
    return '중단($target)';
  }

  @override
  String get toolTitleAgents => '에이전트()';

  @override
  String get toolTitleContext => '컨텍스트()';

  @override
  String get toolTitleNewContext => '새 컨텍스트()';

  @override
  String toolTitleBash(String command) {
    return '실행($command)';
  }

  @override
  String toolTitleStdin(String session) {
    return '입력($session)';
  }

  @override
  String toolTitleStdinChars(String session, String chars) {
    return '입력($session ← $chars)';
  }

  @override
  String toolTitleGlob(String pattern) {
    return '파일 찾기($pattern)';
  }

  @override
  String toolTitleGlobIn(String pattern, String path) {
    return '파일 찾기($path에서 $pattern)';
  }

  @override
  String toolTitleList(String path) {
    return '목록($path)';
  }

  @override
  String toolTitleMcpResources(String server) {
    return '리소스($server)';
  }

  @override
  String toolTitleMcpResourceTemplates(String server) {
    return '리소스 템플릿($server)';
  }

  @override
  String toolTitleMcpResource(String server, String uri) {
    return '리소스($server: $uri)';
  }

  @override
  String toolTitleRead(String path) {
    return '읽기($path)';
  }

  @override
  String toolTitleReadRange(String path, String offset, String limit) {
    return '읽기($path @$offset+$limit)';
  }

  @override
  String toolTitleAsk(String headers) {
    return '질문($headers)';
  }

  @override
  String toolTitleSearch(String query) {
    return '검색($query)';
  }

  @override
  String toolTitleSearchIn(String query, String path) {
    return '검색($path에서 $query)';
  }

  @override
  String get toolTitleSkills => '스킬()';

  @override
  String toolTitleSkill(String name) {
    return '스킬($name)';
  }

  @override
  String toolTitleSkillResource(String name, String resource) {
    return '스킬($name:$resource)';
  }

  @override
  String toolTitleToolSearch(String query) {
    return '도구($query)';
  }

  @override
  String toolTitlePlan(int count) {
    return '계획($count)';
  }

  @override
  String toolTitleView(String path) {
    return '이미지 보기($path)';
  }

  @override
  String get toolArgumentAllServers => '전체';

  @override
  String get directoryBrowserTitle => 'Daemon의 폴더 선택';

  @override
  String get directoryBrowserPath => 'Daemon 경로';

  @override
  String get directoryBrowserEmpty => '하위 폴더가 없습니다.';

  @override
  String get directoryBrowserSelect => '이 폴더 선택';

  @override
  String get directoryBrowserHostTitle => '폴더를 추가할 daemon';

  @override
  String hookFailureMessage(String phase, int exitCode, String command) {
    return '$phase 실패 (exit $exitCode): $command';
  }

  @override
  String hookFailureTitle(String phase) {
    return '$phase hook 실패';
  }

  @override
  String get hookFailureNoOutput => '(출력 없음)';

  @override
  String get settingsCategorySkill => '스킬';

  @override
  String get skillSettingsHeading => '스킬';

  @override
  String skillSettingsCount(int count) {
    return '스킬 $count개';
  }

  @override
  String get skillSettingsSelectSkill => '스킬을 선택하세요.';

  @override
  String get skillSettingsList => '스킬 목록';

  @override
  String get skillSettingsAdd => '스킬 추가';

  @override
  String get skillSettingsAddTitle => '스킬 추가';

  @override
  String get skillSettingsIdLabel => 'ID (디렉터리 이름)';

  @override
  String get skillSettingsIdInvalid => '영문 소문자, 숫자, -, _ 만 쓸 수 있습니다.';

  @override
  String get skillSettingsIdTaken => '이미 있는 스킬 ID입니다.';

  @override
  String get skillSettingsNameRequired => '이름을 입력하세요.';

  @override
  String get skillSettingsCopyPath => '파일 위치 복사';

  @override
  String get skillSettingsDelete => '스킬 삭제';

  @override
  String get skillSettingsDeleteFailed => '스킬을 삭제하지 못했습니다.';

  @override
  String get skillSettingsToggleFailed => '스킬 사용 여부를 바꾸지 못했습니다.';

  @override
  String skillSettingsDeleteTitle(String name) {
    return '$name 을(를) 삭제할까요?';
  }

  @override
  String get skillSettingsDeleteMessage => '스킬 디렉터리는 옆의 .archive 로 이동합니다.';

  @override
  String get skillSettingsEnabled => '사용';

  @override
  String get skillSettingsMandatory => '이 내장 스킬은 항상 켜져 있습니다.';

  @override
  String get skillSettingsReadOnly => '내장 스킬은 앱에 포함되어 있어 편집할 수 없습니다.';

  @override
  String get skillSettingsInstructions => '지시문 (Markdown)';

  @override
  String get skillSettingsStateHeading => '사용 여부';

  @override
  String get skillSettingsDefinitionHeading => '정의';

  @override
  String get skillSettingsResources => '포함된 파일';

  @override
  String get skillSettingsNoResources => '이 스킬에 포함된 파일이 없습니다.';

  @override
  String get skillSettingsSaveFailedTitle => '스킬을 저장하지 못했습니다';

  @override
  String get skillSettingsReload => '다시 불러오기';

  @override
  String get skillSettingsOverwrite => '덮어쓰기';

  @override
  String get skillSettingsShadowed => '다른 소스가 이 스킬을 덮어씁니다.';

  @override
  String get skillSettingsStale => '파일을 해석할 수 없어 마지막 정상 버전을 표시합니다.';

  @override
  String get skillSettingsSource => '소속';

  @override
  String get skillSettingsSourceBuiltIn => '내장';

  @override
  String get skillSettingsSourceUserHome => '글로벌';

  @override
  String get skillSettingsSourceConfig => '설정';

  @override
  String get skillSettingsSourceProject => '프로젝트';

  @override
  String get skillSettingsProject => '프로젝트';

  @override
  String get skillSettingsProjectNone => '전역 스킬만';

  @override
  String get skillSettingsProjectHint => '프로젝트를 고르면 그 프로젝트에 커밋된 스킬이 함께 보입니다.';

  @override
  String get skillSettingsProjectSearch => '프로젝트 검색';

  @override
  String get skillSettingsProjectNoMatch => '일치하는 프로젝트가 없습니다';

  @override
  String get settingsCategoryMcp => 'MCP';

  @override
  String get mcpSettingsHeading => 'MCP 서버';

  @override
  String get mcpSettingsAdd => 'MCP 서버 추가';

  @override
  String get mcpSettingsEmpty => '설정된 MCP 서버가 없습니다.';

  @override
  String get mcpSettingsSelectServer => '편집할 서버를 선택하세요.';

  @override
  String get mcpSettingsScopeUser => '내 설정';

  @override
  String get mcpSettingsScopeProject => '이 프로젝트';

  @override
  String mcpSettingsProjectReadOnly(String appName) {
    return '이 저장소가 정의한 서버라 $appName가 수정하지 않습니다.';
  }

  @override
  String get mcpSettingsShadowed => '같은 이름의 내 서버에 가려짐';

  @override
  String mcpSettingsSource(String path) {
    return '$path에 정의됨';
  }

  @override
  String get mcpSettingsServerId => 'ID';

  @override
  String get mcpSettingsServerIdInvalid => '소문자, 숫자, - 및 _만 사용하세요.';

  @override
  String get mcpSettingsTransport => '연결 방식';

  @override
  String get mcpSettingsTransportStdio => '명령';

  @override
  String get mcpSettingsTransportHttp => 'HTTP';

  @override
  String get mcpSettingsCommand => '명령';

  @override
  String get mcpSettingsArgs => '인자 (한 줄에 하나)';

  @override
  String get mcpSettingsWorkingDirectory => '작업 디렉터리 (선택)';

  @override
  String get mcpSettingsUrl => 'URL';

  @override
  String get mcpSettingsEnvironment => '환경 변수 (KEY=value, 한 줄에 하나)';

  @override
  String get mcpSettingsHeaders => '헤더 (Name: value, 한 줄에 하나)';

  @override
  String get mcpSettingsConnectionHeading => '연결';

  @override
  String get mcpSettingsStateHeading => '사용 여부';

  @override
  String get mcpSettingsEnabled => '사용';

  @override
  String get mcpSettingsSecretHint =>
      '비밀값을 직접 입력하지 마세요. 저장된 비밀값이나 환경 변수를 참조하세요:';

  @override
  String get mcpSettingsTest => '연결 테스트';

  @override
  String mcpSettingsTestSucceeded(int count) {
    return '연결됨. 도구 $count개를 찾았습니다.';
  }

  @override
  String mcpSettingsTestFailed(String error) {
    return '연결할 수 없습니다: $error';
  }

  @override
  String get terminalTerminateFailed => '터미널을 종료하지 못했습니다.';

  @override
  String get relayRevokeFailed => '기기를 폐기하지 못했습니다.';

  @override
  String get appSettingsDaemonChangeFailed => 'daemon 설정을 바꾸지 못했습니다.';

  @override
  String get appSettingsDeleteFailed => 'daemon을 제거하지 못했습니다.';

  @override
  String get appSettingsReconnectFailed => '다시 연결하지 못했습니다.';

  @override
  String get providerSettingsDisconnectFailed => '프로바이더 연결을 해제하지 못했습니다.';

  @override
  String get providerSettingsDeleteFailed => '프로바이더를 삭제하지 못했습니다.';

  @override
  String get providerSettingsDefaultModelFailed => '기본 모델을 바꾸지 못했습니다.';

  @override
  String get providerSettingsDisconnected => '연결을 해제했습니다.';

  @override
  String get workspaceArchiveFailed => '워크트리를 보관하지 못했습니다.';

  @override
  String get workspaceUnregisterFailed => '프로젝트를 제거하지 못했습니다.';

  @override
  String get projectSettingsSaveFailed => '프로젝트 설정을 저장하지 못했습니다.';

  @override
  String get mcpSettingsSaveFailed => '서버를 저장하지 못했습니다.';

  @override
  String get mcpSettingsDeleteFailed => '서버를 삭제하지 못했습니다.';

  @override
  String get mcpSettingsSecretFailed => '시크릿을 저장하지 못했습니다.';

  @override
  String get mcpSettingsDelete => '서버 삭제';

  @override
  String mcpSettingsDeleteConfirm(String name) {
    return '$name을(를) 삭제할까요? 이 도구를 쓰던 에이전트는 사용할 수 없게 됩니다.';
  }

  @override
  String get mcpSettingsStatusDisabled => '사용 안 함';

  @override
  String get mcpSettingsStatusConnecting => '연결 중';

  @override
  String get mcpSettingsConnecting => 'MCP 서버 연결 중';

  @override
  String get mcpSettingsStatusReady => '준비됨';

  @override
  String get mcpSettingsStatusFailed => '실패';

  @override
  String get mcpSettingsDiscoveredResources => '리소스';

  @override
  String get mcpSettingsResources => '게시된 리소스';

  @override
  String get mcpSettingsNoResources => '게시된 리소스가 없습니다.';

  @override
  String get mcpSettingsResourceTemplates => '리소스 템플릿';

  @override
  String get mcpSettingsNoResourceTemplates => '게시된 리소스 템플릿이 없습니다.';

  @override
  String get mcpSettingsDiscoveredTools => '도구';

  @override
  String get mcpSettingsNoTools => '이 서버는 도구를 제공하지 않습니다.';

  @override
  String get mcpSettingsDiagnostics => '서버 출력';

  @override
  String get mcpSettingsSecretSet => '비밀값 저장';

  @override
  String get mcpSettingsSecretKey => '참조 이름';

  @override
  String get mcpSettingsSecretValue => '값';

  @override
  String get agentSettingsToolAlwaysOn => '항상 사용 가능';

  @override
  String toolContextRemaining(int remaining, int window) {
    return '토큰 $remaining/$window 남음';
  }

  @override
  String toolContextRemainingUnknown(int used) {
    return '토큰 $used개 사용';
  }

  @override
  String get chatContextReset => '새 컨텍스트 창';

  @override
  String get chatContextCompacted => '대화 요약됨';

  @override
  String get composerCommandCompactLabel => 'compact';

  @override
  String get composerCommandCompactDescription => '대화를 요약해 컨텍스트 창을 비웁니다.';

  @override
  String get sessionContextMeter => '컨텍스트';

  @override
  String sessionContextMeterValue(int percent) {
    return '컨텍스트 창의 $percent% 사용';
  }

  @override
  String get sessionContextDetailsTitle => '컨텍스트 사용량';

  @override
  String sessionContextPercent(int percent) {
    return '$percent% 사용';
  }

  @override
  String sessionContextTokens(String used, String max) {
    return '$used / $max 토큰';
  }

  @override
  String sessionContextCost(String cost) {
    return '세션 비용 $cost';
  }

  @override
  String get sessionQuotaLoading => 'Provider 사용량 불러오는 중';

  @override
  String get sessionQuotaError => 'Provider 사용량을 일시적으로 불러올 수 없습니다.';

  @override
  String sessionQuotaProviderPlan(String provider, String plan) {
    return '$provider · $plan';
  }

  @override
  String sessionQuotaPercent(int percent) {
    return '$percent% 사용';
  }

  @override
  String sessionQuotaResets(String time) {
    return '$time 재설정';
  }

  @override
  String sessionQuotaCredits(String amount) {
    return '크레딧 $amount';
  }

  @override
  String get sessionQuotaWindowSession => '세션 한도';

  @override
  String get sessionQuotaWindowWeekly => '주간 한도';

  @override
  String get sessionQuotaWindowCodeReview => '코드 리뷰 한도';

  @override
  String get composerCommandNoAttachments => '명령을 실행하려면 첨부를 제거하세요.';

  @override
  String get composerCommandsEmpty => '명령 없음';

  @override
  String get composerFilesEmpty => '파일 없음';

  @override
  String get composerFilesSearching => '워크스페이스 검색 중';

  @override
  String get composerCommandsError => '명령을 불러오지 못했습니다';

  @override
  String get composerFilesError => '파일을 검색하지 못했습니다';

  @override
  String get composerCommandSourceClient => '앱';

  @override
  String get composerCommandSourceAgent => '명령';

  @override
  String get composerCommandSourceSkill => '스킬';

  @override
  String get composerCommandClearLabel => 'clear';

  @override
  String get composerCommandClearDescription => '컴포저를 비웁니다.';

  @override
  String get composerCommandNewLabel => 'new';

  @override
  String get composerCommandNewDescription => '새 세션을 시작합니다.';

  @override
  String get composerCommandModeLabel => 'mode';

  @override
  String get composerCommandModeDescription => '계획과 작업 모드를 전환합니다.';

  @override
  String get composerCommandAgentsLabel => 'agents';

  @override
  String get composerCommandAgentsDescription => '에이전트 설정을 엽니다.';

  @override
  String get composerCommandSkillsLabel => 'skills';

  @override
  String get composerCommandSkillsDescription => '스킬 설정을 엽니다.';

  @override
  String get composerCommandHelpLabel => 'help';

  @override
  String get composerCommandHelpDescription => '사용할 수 있는 명령을 보여줍니다.';

  @override
  String get composerCommandGoalLabel => 'goal';

  @override
  String get composerCommandGoalDescription => '세션의 영속 작업 목표를 만들거나 관리합니다.';

  @override
  String get goalStatusActive => '실행 중';

  @override
  String get goalStatusPaused => '일시 정지';

  @override
  String get goalStatusBlocked => '막힘';

  @override
  String get goalStatusUsageLimited => '사용량 제한';

  @override
  String get goalStatusBudgetLimited => '예산 도달';

  @override
  String get goalStatusComplete => '완료';

  @override
  String get goalPlanHold => 'Run 모드에서 재개';

  @override
  String goalElapsed(int seconds) {
    return '$seconds초 경과';
  }

  @override
  String goalTokenUsage(int used, int budget) {
    return '$used / $budget 토큰';
  }

  @override
  String get goalPause => 'Goal 일시 정지';

  @override
  String get goalResume => 'Goal 재개';

  @override
  String get goalEdit => 'Goal 편집';

  @override
  String get goalClear => 'Goal 지우기';

  @override
  String get goalDialogTitle => '세션 Goal';

  @override
  String get goalObjectiveLabel => '목표';

  @override
  String get goalObjectiveRequired => '1–4,000자로 입력하세요.';

  @override
  String get goalBudgetLabel => '토큰 예산(선택)';

  @override
  String get goalBudgetInvalid => '양수 토큰 예산을 입력하세요.';

  @override
  String get goalStart => 'Goal 시작';

  @override
  String get goalReplaceTitle => '현재 Goal을 교체할까요?';

  @override
  String get goalReplaceDescription => '새 Goal을 시작하고 기록된 사용량을 초기화합니다.';

  @override
  String get goalReplaceAction => 'Goal 교체';

  @override
  String get composerSuggestionsLabel => '제안';

  @override
  String get composerDropFilesHere => '여기에 파일을 놓으세요';

  @override
  String get chatToolActionRead => '파일 읽기';

  @override
  String get chatToolActionList => '파일 목록 보기';

  @override
  String get chatToolActionSearch => '검색';

  @override
  String get chatToolActionEdit => '파일 편집';

  @override
  String get chatToolActionRun => '명령 실행';

  @override
  String get chatToolActionDelegate => '에이전트 조율';

  @override
  String get chatToolActionPlan => '계획 업데이트';

  @override
  String get chatToolActionAsk => '질문하기';

  @override
  String get chatToolActionResource => '리소스 사용';

  @override
  String get chatToolActionTools => '도구 찾기';

  @override
  String get chatToolActionClock => '대기';

  @override
  String get chatToolActionContext => '컨텍스트 관리';

  @override
  String get chatToolActionImage => '이미지 보기';

  @override
  String get chatToolActionGeneric => '도구 사용';

  @override
  String get chatReasoningThinking => '사고 중';

  @override
  String get chatReasoningThought => '생각함';

  @override
  String get chatReasoningWaiting => '사고 내용을 기다리는 중…';

  @override
  String get chatToolStatusFailed => '실패';

  @override
  String get chatToolStatusDenied => '거부됨';

  @override
  String get chatToolDetailsTool => '도구';

  @override
  String get chatToolDetailsRequest => '요청';

  @override
  String get chatToolDetailsResult => '결과';
}
