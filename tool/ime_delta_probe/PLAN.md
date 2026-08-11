# 우분투 Wayland 한글 IME 재정렬 버그 — 트레이스 캡처 계획서

> 이 문서는 자기완결형입니다. 이 폴더(`ime_delta_probe/`)만 있으면
> Tinest 레포 없이 수행할 수 있습니다. 실행 주체가 에이전트라면
> 아래 단계를 순서대로 수행하고 "회수 산출물"을 전부 수집해 보고하세요.

## 1. 배경 (왜 하는가)

- **버그**: Ubuntu GNOME Wayland + ibus-hangul에서 Tinest 터미널에
  `안녕하세요.`를 입력하면 `안세녕하요.`로 재정렬됨. 커서가 "녕"에서 멈추는
  증상 동반. 업스트림(termworld) 패치 수차례에도 미해결.
- **지금까지 확정된 사실**:
  - 기존 테스트/CI는 전부 X11 경로만 커버 → Wayland에서만 재현되는 이유.
  - Docker(headless sway + ibus-hangul 직결, `GTK_IM_MODULE=ibus`)에서는
    빠른 입력에도 **재정렬이 발생하지 않음** — 직결 경로는 깨끗함.
  - 따라서 유력 용의자는 **GNOME text-input-v3 경로**(GTK imwayland →
    mutter → ibus). GTK에는 알려진 serial 버그(GNOME/gtk#1365)가 있고,
    그 이슈가 ibus-hangul(preedit을 숨긴 뒤 커밋하는 패턴)을 명시적으로
    지목함: commit이 done 이벤트 뒤로 밀려 **다음 preedit 이후에 늦게
    적용**됨 → 음절 재정렬과 정확히 일치.
- **이번 작업의 목표**: 실제 버그 머신에서 Flutter `flutter/textinput`
  채널의 원시 이벤트 스트림(JSONL)을 녹화한다. 이 트레이스는 이후
  termworld의 결정적 재생 테스트(fixture)가 되어, 어떤 OS에서든 ibus 없이
  `안세녕하요.` 실패를 재현하게 만든다. **버그를 고치는 작업이 아니라
  녹화가 목표다.**

## 2. 프로브 앱이 하는 일

`lib/main.dart`: termworld(버그 앱과 동일 커밋 `e7d3b14f…`에 핀)의
`TerminalView` 하나를 띄우고,

- `flutter/textinput` 채널 **양방향**을 μs 타임스탬프 JSONL로 기록
  (`ime-trace.jsonl`): 수신 델타(rx), 송신 setEditingState 등(tx),
  PTY로 나가는 문자열(pty).
- PTY 바이트를 `pty-input.bin`에 그대로 기록 (재정렬 판정의 근거).

## 3. 준비 (1회)

```bash
cd ime_delta_probe
flutter create --platforms=linux --project-name ime_delta_probe .
flutter pub get
```

Flutter SDK가 없으면 3.44.x stable 설치. `docker/` 하위 폴더는 이 머신에서는
무시해도 된다(윈도우 쪽 컨테이너 실험용).

## 4. 환경 사실 수집 (모든 분기가 여기 걸림)

**Tinest 앱(또는 프로브 앱)을 먼저 띄운 상태에서**:

```bash
bash capture_env.sh > env.txt 2>&1
```

핵심 확인 포인트:

- `XDG_SESSION_TYPE=wayland` 인지.
- `GTK_IM_MODULE` 값: **비어 있으면 text-input-v3 경로**(유력 용의 경로),
  `ibus`면 직결 경로.
- **XWayland 체크**: `xlsclients` 출력에 Tinest/프로브 앱이 보이면 앱이
  XWayland로 떠 있다는 뜻 → text-input-v3 가설 폐기, 결과에 반드시 명기.
- `gsettings`의 `preedit-mode`, `word-commit` 값 (CI 하네스와 다르면
  하네스를 이 값으로 맞춰야 함).

## 5. 실행 매트릭스 (3회)

각 실행마다 동일한 절차:

1. 터미널(검은 화면) 클릭해 포커스 → 한글 전환.
2. `안녕하세요.` 를 **천천히**(1키/초) 입력 + Enter.
3. 같은 문장을 **빠르게** 입력 + Enter.
4. 창 닫기. (창 크기 조절/마우스 드래그 등 다른 조작 금지 — 트레이스 오염)

```bash
bash run_probe.sh wayland-default   # ① 실제 사용자 경로 (GNOME 기본 IM)
bash run_probe.sh wayland-ibus      # ② GTK_IM_MODULE=ibus 직결 경로
bash run_probe.sh x11-control       # ③ 대조군 (GDK_BACKEND=x11)
```

각 실행이 끝나면 스크립트가 PTY 바이트를 hex/텍스트로 출력한다.

## 6. 판정 기준

| 실행 | 기대 결과 | 의미 |
|---|---|---|
| ① wayland-default | `안세녕하요.` (재정렬) | **재현 성공** — 이 트레이스가 핵심 fixture |
| ② wayland-ibus | `안녕하세요.` (정상) | Docker 결과와 일치 → 경로 특정 완성 |
| ③ x11-control | `안녕하세요.` (정상) | Wayland-only 확정 |

- ①에서 재정렬이 안 나오면: 더 빠르게 여러 번 반복 입력해 볼 것(레이스성).
  그래도 안 나오면 실제 Tinest 앱에서는 재현되는지 함께 확인하고 보고
  (프로브 앱 미재현 + 실제 앱 재현이면 앱 구성 요인 → 다음 단계에서
  앱 내부 계측으로 전환).
- ①이 재현됐는데 ②도 재정렬되면: 예상과 다른 신호 — 그대로 보고
  (직결 경로도 오염된 환경이라는 뜻이므로 중요 정보).

## 7. 회수 산출물 (전부)

```
env.txt
traces/wayland-default/ime-trace.jsonl   ← 가장 중요
traces/wayland-default/pty-input.bin
traces/wayland-ibus/ime-trace.jsonl
traces/wayland-ibus/pty-input.bin
traces/x11-control/ime-trace.jsonl
traces/x11-control/pty-input.bin
```

가능하면 ①의 재정렬이 화면에 보이는 스크린샷 1장도.

## 8. 트러블슈팅

- **한글 전환이 안 됨**: `ibus engine hangul` 실행 후 다시 시도. 설정된
  전환 키는 `gsettings get org.freedesktop.ibus.engine.hangul switch-keys`로
  확인.
- **프로브 창에 한글이 □로 보임**: 폰트 문제일 뿐, 판정은 `pty-input.bin`
  바이트로 하므로 무시.
- **`flutter run`이 GPU 오류로 죽음**: `flutter run -d linux --release`
  대신 `flutter build linux --release` 후
  `IME_TRACE_DIR=$(pwd)/traces/<이름> ./build/linux/x64/release/bundle/ime_delta_probe`
  로 직접 실행 (run_probe.sh의 env 설정을 그대로 따라할 것).
- **trace 파일이 안 생김**: 실행 디렉터리 권한 확인. 파일은 실행 시작 시
  삭제 후 append로 다시 생성됨.

## 9. 이후 계획 (참고 — 이 머신에서 할 일 아님)

회수된 ①번 트레이스를 termworld
(`tinyrack-net/flutter-packages`)의 결정적 재생 테스트
`terminal_view_wayland_ime_test.dart`의 fixture로 체크인하고, rx 델타를
`updateEditingValueWithDeltas`로 재생 + tx setEditingState를 지연 왕복으로
모델링해 **어떤 OS에서든 `안세녕하요.`를 뱉으며 실패하는 테스트**를 만든다.
그것이 "재현 확정"이며, 이후 수정 작업의 기준선이 된다.
