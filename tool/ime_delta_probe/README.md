# ime_delta_probe

우분투 Wayland + ibus-hangul에서 termworld 터미널의 한글 재정렬 버그
("안녕하세요." → "안세녕하요.")를 재현·계측하는 1회용 앱.
`flutter/textinput` 채널의 양방향 트래픽과 PTY로 나가는 바이트를
타임스탬프 JSONL로 기록한다.

## 우분투 머신에서 (이 폴더를 통째로 복사한 뒤)

```bash
cd ime_delta_probe
flutter create --platforms=linux --project-name ime_delta_probe .
flutter pub get

# 1) 환경 사실 수집 — 먼저 Coder 앱(또는 프로브)을 띄워둔 상태에서:
bash capture_env.sh > env.txt 2>&1

# 2) 세 가지 경로로 각각 실행, 매 실행마다:
#    터미널 포커스 → 한글 전환 → "안녕하세요." 천천히 입력 + Enter
#    → 같은 문장 빠르게 입력 + Enter → 창 닫기
bash run_probe.sh wayland-default   # 실제 사용자 경로 (GNOME 기본)
bash run_probe.sh wayland-ibus      # GTK_IM_MODULE=ibus 직결 경로
bash run_probe.sh x11-control       # 대조군 — 깨끗해야 Wayland-only 확정
```

## 회수할 산출물

- `env.txt`
- `traces/<run-name>/ime-trace.jsonl` ×3
- `traces/<run-name>/pty-input.bin` ×3

각 실행 종료 시 `run_probe.sh`가 PTY 바이트를 hex/텍스트로 출력하므로,
`wayland-default`(또는 `wayland-ibus`)에서 `안세녕하요.`가 보이고
`x11-control`은 `안녕하세요.`면 재현 성공. jsonl 트레이스가 결정적
재생 테스트(termworld `terminal_view_wayland_ime_test.dart`)의 fixture가 된다.

주의: 창 크기를 바꾸거나 마우스로 긁으면 트레이스에 잡음이 섞인다.
입력 외의 조작은 최소화.
