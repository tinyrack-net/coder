#include "single_instance.h"

namespace {

constexpr const wchar_t kMutexName[] = L"Local\\tinyrack-coder-single-instance";
constexpr const wchar_t kRevealMessageName[] = L"TinyrackCoderRevealWindow";

}  // namespace

SingleInstance::SingleInstance() {
  // Mirrors the Linux runner's escape hatch: an E2E shard owns an isolated
  // daemon home, so a developer's running Coder must not take its launch over
  // and exit it before the Flutter engine starts.
  if (::GetEnvironmentVariableW(L"TINYRACK_CODER_ALLOW_MULTIPLE_INSTANCES",
                                nullptr, 0) != 0) {
    is_primary_ = true;
    return;
  }
  mutex_ = ::CreateMutexW(nullptr, TRUE, kMutexName);
  // A mutex this process could not create at all is treated as "primary": a
  // failure here must never keep the app from launching.
  is_primary_ = mutex_ == nullptr || ::GetLastError() != ERROR_ALREADY_EXISTS;
}

SingleInstance::~SingleInstance() {
  if (mutex_ == nullptr) {
    return;
  }
  if (is_primary_) {
    ::ReleaseMutex(mutex_);
  }
  ::CloseHandle(mutex_);
}

UINT SingleInstance::RevealMessage() {
  static const UINT message = ::RegisterWindowMessageW(kRevealMessageName);
  return message;
}

void SingleInstance::RevealRunningInstance() {
  const UINT message = RevealMessage();
  if (message == 0) {
    return;
  }
  // This process holds the foreground privilege it just received from the
  // user's launch gesture, so it can hand that privilege to the instance that
  // is about to raise its window.
  ::AllowSetForegroundWindow(ASFW_ANY);
  ::PostMessageW(HWND_BROADCAST, message, 0, 0);
}
