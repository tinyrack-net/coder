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
  String get settingsTitle => '설정';

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
  String get advancedResetFailedTitle => '초기화 실패';

  @override
  String get advancedResetFailedDaemonRunning =>
      '다른 Tinyrack Coder daemon이 데이터 디렉터리를 사용 중입니다. 종료한 뒤 다시 시도하세요. 삭제된 항목은 없습니다.';

  @override
  String advancedResetFailedFilesystem(String error) {
    return '일부 daemon 파일을 삭제하지 못했습니다: $error';
  }

  @override
  String get advancedResetFailedIncomplete =>
      'daemon 데이터는 삭제했지만 앱 설정을 지우지 못했습니다. Tinyrack Coder를 다시 시작하세요.';

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
  String get generalStartupAtBootDescription =>
      '로그인하면 운영체제가 Tinyrack Coder를 실행해 내장 daemon이 계속 동작합니다.';

  @override
  String get generalStartupMinimizedLabel => '최소화된 상태로 시작';

  @override
  String get generalStartupMinimizedDescription =>
      '로그인 시 실행되면 창을 열지 않고 바로 트레이로 들어갑니다.';

  @override
  String get generalStartupCloseNotice =>
      '창을 닫아도 Tinyrack Coder는 트레이에서 계속 실행됩니다.';

  @override
  String get trayTooltip => 'Tinyrack Coder';

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
  String get desktopMenuAbout => 'Tinyrack Coder 정보';

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
  String get workspaceNewTab => '새 탭';

  @override
  String get workspaceNewTerminal => '새 터미널';

  @override
  String get terminalCloseTitle => '터미널을 종료할까요?';

  @override
  String get terminalCloseConfirm => '이 탭을 닫으면 셸과 하위 프로세스가 종료돼요.';

  @override
  String get terminalTerminate => '종료';

  @override
  String get terminalConnectionFailed => '터미널 연결에 실패했어요';

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
  String get workspaceUnregisterBody =>
      'Coder 목록에서만 제거하며 repository와 파일은 디스크에 그대로 둡니다.';

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
  String get workspaceArchiveRemovesDirectory =>
      'Coder가 만든 checkout 디렉터리가 제거됩니다.';

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
  String get hostErrorEmbeddedAlreadyRunning =>
      '이 컴퓨터에서 Coder가 이미 실행 중이며 로컬 daemon을 점유하고 있습니다. 트레이에서 실행 중인 창을 열거나, 종료한 뒤 다시 시도하세요.';

  @override
  String get hostErrorLocalNetworkUnreachable =>
      'Daemon에 연결하지 못했습니다. Daemon이 실행 중인지, 그리고 이 사이트의 로컬 네트워크 접근을 허용했는지 확인하세요.';

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
  String get agentSettingsSubagents => '호출 가능한 Subagent';

  @override
  String get agentSettingsNoSubagents => '등록된 Subagent가 없습니다.';

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
  String providerSettingsConnectTitle(String name) {
    return '$name 연결';
  }

  @override
  String get providerSettingsConnect => '연결';

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
  String get composerPlanTooltip => '계획만 세웁니다. Shift+Tab으로 전환';

  @override
  String get composerRunTooltip => '요청을 바로 수행합니다. Shift+Tab으로 전환';

  @override
  String get composerSelectAgent => 'Agent 선택';

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
  String get composerMoreSettings => '설정 더 보기';

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
    return 'Edit($count개 파일)';
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
  String get mcpSettingsProjectReadOnly => '이 저장소가 정의한 서버라 Coder가 수정하지 않습니다.';

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
  String get composerSuggestionsLabel => '제안';
}
