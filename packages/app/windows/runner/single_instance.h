#ifndef RUNNER_SINGLE_INSTANCE_H_
#define RUNNER_SINGLE_INSTANCE_H_

#include <windows.h>

// Coder is single-instance per logon session.
//
// The embedded daemon takes an exclusive lock on `daemon.lock` in the user's
// %LOCALAPPDATA%, and on Windows that lock is owned per handle, so a second
// copy of the app fails to start its daemon and can do nothing useful. Closing
// the window only hides it to the tray, so a second launch — from the Start
// menu, from a login item, or from the installer's "run now" — is easy to
// trigger and used to leave the user staring at a lock error.
//
// The mutex lives in the `Local\` namespace, which is scoped to the logon
// session. That matches the scope of %LOCALAPPDATA%: two users signed in at
// once own separate daemon homes and must not block each other.
class SingleInstance {
 public:
  SingleInstance();
  ~SingleInstance();

  SingleInstance(const SingleInstance&) = delete;
  SingleInstance& operator=(const SingleInstance&) = delete;

  // Whether this process is the first instance in the logon session.
  bool IsPrimary() const { return is_primary_; }

  // Asks the running instance to reveal its window.
  //
  // Broadcasting a registered message avoids depending on the window title or
  // the Flutter window class name, either of which can change without anyone
  // noticing this code exists.
  static void RevealRunningInstance();

  // The registered message the running instance answers, or 0 if the message
  // could not be registered.
  static UINT RevealMessage();

 private:
  HANDLE mutex_ = nullptr;
  bool is_primary_ = false;
};

#endif  // RUNNER_SINGLE_INSTANCE_H_
