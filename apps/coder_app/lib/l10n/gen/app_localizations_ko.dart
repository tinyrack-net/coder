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
  String get settingsCategoryGeneral => 'General';

  @override
  String get settingsCategoryProjects => 'Projects';

  @override
  String get settingsCategoryAgent => 'Agent';

  @override
  String get settingsCategoryProvider => 'Provider';

  @override
  String get settingsCategoryDaemon => 'Daemon';

  @override
  String get settingsRequiresOnlineDaemon => '온라인 daemon 연결이 필요합니다.';

  @override
  String get generalLanguageSection => '언어';

  @override
  String get generalLanguageLabel => '표시 언어';

  @override
  String get generalLanguageDescription => '앱 전체에 적용되며 즉시 반영됩니다.';

  @override
  String get generalLanguageSystem => '시스템 설정 따름';

  @override
  String get workspacesTitle => 'Workspaces';

  @override
  String get workspaceSidebarExpand => '사이드바 열기';

  @override
  String get workspaceSidebarCollapse => '사이드바 접기';

  @override
  String get workspaceNewSession => '새 session';

  @override
  String get workspaceAllSessions => '모든 session';

  @override
  String get workspaceCloseTab => '탭 닫기';

  @override
  String get workspaceNewWorkspace => 'New workspace';

  @override
  String get workspaceWorktreeMenu => 'Worktree 메뉴';

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
  String get agentSettingsDaemonDefaultModel => 'Daemon 기본 provider/model';

  @override
  String get agentSettingsPinnedModel => '고정 provider/model';

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
  String get providerSettingsOpenAiTitle => 'OpenAI 연결';

  @override
  String get providerSettingsOpenAiSubtitle =>
      'ChatGPT 로그인은 공개 Codex 인증 흐름에 의존하는 실험적 기능입니다.';

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
  String get providerSettingsConnected => '연결됨';

  @override
  String get providerSettingsNoConnections => '연결된 Provider가 없습니다.';

  @override
  String get providerSettingsDefaultChip => '기본';

  @override
  String get providerSettingsMakeDefault => '기본 Provider로 설정';

  @override
  String get providerSettingsEditAdvanced => '고급 설정 편집';

  @override
  String get providerSettingsModelsLoading => '모델을 불러오는 중…';

  @override
  String get providerSettingsNoModels => '사용 가능한 모델이 없습니다.';

  @override
  String get providerSettingsSelectModel => '모델 선택';

  @override
  String get providerSettingsDefaultModel => '기본 모델';

  @override
  String get providerSettingsModelMissing => '카탈로그에 없음';

  @override
  String get providerSettingsAdd => 'Provider 추가';

  @override
  String get providerSettingsNoPresets => '추가 가능한 preset이 없습니다.';

  @override
  String get providerSettingsCustomSubtitle => '고급 설정: 자체 endpoint 연결';

  @override
  String get providerSettingsOAuthPending => 'ChatGPT 로그인 대기 중';

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
  String get providerAuthNone => '인증 없음';

  @override
  String get modelPickerTitle => '기본 모델 선택';

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
  String get composerSelectProvider => 'Provider 선택';

  @override
  String get composerModel => '모델';

  @override
  String get composerSelectModel => '모델 선택';

  @override
  String get composerInheritModel => 'Agent 기본값 사용';

  @override
  String get composerStartHint => '코딩 요청으로 새 session을 시작하세요.';

  @override
  String get composerNoPrimaryAgent => '사용 가능한 primary Agent가 없습니다.';

  @override
  String get composerSelectProviderFirst => '사용할 Provider와 모델을 먼저 선택하세요.';

  @override
  String get composerPlanBanner => 'Plan 모드 · 계획만 세우고 실행하지 않습니다';

  @override
  String get composerInputHint => '코딩 요청을 입력하세요…';

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
  String get chatPlanTitle => '제안된 계획';

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
}
