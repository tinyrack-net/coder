#ifndef _WIN32
#define _DEFAULT_SOURCE
#define _POSIX_C_SOURCE 200809L
#else
#define _WIN32_WINNT 0x0A00
#endif

#include "tinyrack_pty.h"

#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include <wchar.h>

#ifdef _WIN32

#define WIN32_LEAN_AND_MEAN
#include <windows.h>

struct tr_pty {
  HPCON console;
  HANDLE input;
  HANDLE output;
  HANDLE process;
  HANDLE job;
  DWORD pid;
  int exited;
  int exit_code;
  int last_error;
  CRITICAL_SECTION write_lock;
  CONDITION_VARIABLE write_ready;
  struct tr_write_chunk *write_head;
  struct tr_write_chunk *write_tail;
  size_t queued_bytes;
  int writer_stopping;
  int writer_initialized;
  HANDLE writer_thread;
};

typedef struct tr_write_chunk {
  uint8_t *data;
  DWORD length;
  DWORD offset;
  struct tr_write_chunk *next;
} tr_write_chunk;

#define TR_WRITE_QUEUE_CAPACITY (2u * 1024u * 1024u)

static DWORD WINAPI tr_writer(void *context) {
  tr_pty *pty = (tr_pty *)context;
  for (;;) {
    EnterCriticalSection(&pty->write_lock);
    while (pty->write_head == NULL && !pty->writer_stopping) {
      SleepConditionVariableCS(&pty->write_ready, &pty->write_lock, INFINITE);
    }
    if (pty->writer_stopping) {
      LeaveCriticalSection(&pty->write_lock);
      return 0;
    }
    tr_write_chunk *chunk = pty->write_head;
    LeaveCriticalSection(&pty->write_lock);

    DWORD written = 0;
    BOOL succeeded = WriteFile(pty->input, chunk->data + chunk->offset,
        chunk->length - chunk->offset, &written, NULL);

    EnterCriticalSection(&pty->write_lock);
    if (!succeeded) {
      pty->last_error = (int)GetLastError();
      pty->writer_stopping = 1;
      LeaveCriticalSection(&pty->write_lock);
      return 0;
    }
    chunk->offset += written;
    pty->queued_bytes -= written;
    if (chunk->offset == chunk->length) {
      pty->write_head = chunk->next;
      if (pty->write_head == NULL) pty->write_tail = NULL;
      free(chunk->data);
      free(chunk);
    }
    LeaveCriticalSection(&pty->write_lock);
  }
}

static void tr_stop_writer(tr_pty *pty) {
  if (pty == NULL || !pty->writer_initialized) return;
  if (pty->writer_thread != NULL) {
    EnterCriticalSection(&pty->write_lock);
    pty->writer_stopping = 1;
    WakeAllConditionVariable(&pty->write_ready);
    LeaveCriticalSection(&pty->write_lock);
    (void)CancelSynchronousIo(pty->writer_thread);
    WaitForSingleObject(pty->writer_thread, INFINITE);
    CloseHandle(pty->writer_thread);
    pty->writer_thread = NULL;
  }
  while (pty->write_head != NULL) {
    tr_write_chunk *chunk = pty->write_head;
    pty->write_head = chunk->next;
    free(chunk->data);
    free(chunk);
  }
  DeleteCriticalSection(&pty->write_lock);
  pty->writer_initialized = 0;
}

static wchar_t *tr_wide(const char *value) {
  if (value == NULL) return NULL;
  int length = MultiByteToWideChar(CP_UTF8, 0, value, -1, NULL, 0);
  if (length == 0) return NULL;
  wchar_t *result = (wchar_t *)calloc((size_t)length, sizeof(wchar_t));
  if (result == NULL) return NULL;
  if (MultiByteToWideChar(CP_UTF8, 0, value, -1, result, length) == 0) {
    free(result);
    return NULL;
  }
  return result;
}

static size_t tr_quote_size(const wchar_t *value) {
  return 3 + (wcslen(value) * 2);
}

static wchar_t *tr_command_line(const char *const *arguments) {
  size_t total = 1;
  for (int i = 0; arguments[i] != NULL; i++) {
    wchar_t *wide = tr_wide(arguments[i]);
    if (wide == NULL) return NULL;
    total += tr_quote_size(wide) + 1;
    free(wide);
  }
  wchar_t *result = (wchar_t *)calloc(total, sizeof(wchar_t));
  if (result == NULL) return NULL;
  wchar_t *cursor = result;
  for (int i = 0; arguments[i] != NULL; i++) {
    wchar_t *wide = tr_wide(arguments[i]);
    if (wide == NULL) {
      free(result);
      return NULL;
    }
    if (i > 0) *cursor++ = L' ';
    *cursor++ = L'"';
    wchar_t *source = wide;
    while (*source != L'\0') {
      size_t slashes = 0;
      while (*source == L'\\') {
        slashes++;
        source++;
      }
      if (*source == L'"') {
        for (size_t slash = 0; slash < (slashes * 2) + 1; slash++) {
          *cursor++ = L'\\';
        }
        *cursor++ = *source++;
      } else if (*source == L'\0') {
        for (size_t slash = 0; slash < slashes * 2; slash++) {
          *cursor++ = L'\\';
        }
      } else {
        for (size_t slash = 0; slash < slashes; slash++) *cursor++ = L'\\';
        *cursor++ = *source++;
      }
    }
    *cursor++ = L'"';
    free(wide);
  }
  *cursor = L'\0';
  return result;
}

static wchar_t *tr_environment(const char *const *environment) {
  size_t total = 1;
  for (int i = 0; environment[i] != NULL; i++) {
    int length = MultiByteToWideChar(CP_UTF8, 0, environment[i], -1, NULL, 0);
    if (length == 0) return NULL;
    total += (size_t)length;
  }
  wchar_t *result = (wchar_t *)calloc(total, sizeof(wchar_t));
  if (result == NULL) return NULL;
  wchar_t *cursor = result;
  for (int i = 0; environment[i] != NULL; i++) {
    int remaining = (int)(total - (size_t)(cursor - result));
    int length = MultiByteToWideChar(
        CP_UTF8, 0, environment[i], -1, cursor, remaining);
    if (length == 0) {
      free(result);
      return NULL;
    }
    cursor += length;
  }
  *cursor = L'\0';
  return result;
}

static void tr_close(HANDLE handle) {
  if (handle != NULL && handle != INVALID_HANDLE_VALUE) CloseHandle(handle);
}

tr_pty *tr_pty_spawn(const char *executable,
                     const char *const *arguments,
                     const char *working_directory,
                     const char *const *environment,
                     int columns,
                     int rows,
                     int *error_code) {
  HANDLE input_read = NULL;
  HANDLE input_write = NULL;
  HANDLE output_read = NULL;
  HANDLE output_write = NULL;
  HPCON console = NULL;
  LPPROC_THREAD_ATTRIBUTE_LIST attributes = NULL;
  wchar_t *command = NULL;
  wchar_t *directory = NULL;
  wchar_t *environment_block = NULL;
  PROCESS_INFORMATION process = {0};
  HANDLE job = NULL;
  tr_pty *result = NULL;
  SIZE_T attribute_size = 0;
  COORD size = {(SHORT)columns, (SHORT)rows};

  if (!CreatePipe(&input_read, &input_write, NULL, 0) ||
      !CreatePipe(&output_read, &output_write, NULL, 0)) goto fail;
  HRESULT console_result =
      CreatePseudoConsole(size, input_read, output_write, 0, &console);
  if (FAILED(console_result)) {
    SetLastError((DWORD)console_result);
    goto fail;
  }
  InitializeProcThreadAttributeList(NULL, 1, 0, &attribute_size);
  attributes = (LPPROC_THREAD_ATTRIBUTE_LIST)malloc(attribute_size);
  if (attributes == NULL ||
      !InitializeProcThreadAttributeList(attributes, 1, 0, &attribute_size) ||
      !UpdateProcThreadAttribute(attributes, 0,
          PROC_THREAD_ATTRIBUTE_PSEUDOCONSOLE, console, sizeof(console),
          NULL, NULL)) goto fail;

  STARTUPINFOEXW startup = {0};
  startup.StartupInfo.cb = sizeof(startup);
  startup.lpAttributeList = attributes;
  command = tr_command_line(arguments);
  directory = tr_wide(working_directory);
  environment_block = tr_environment(environment);
  if (command == NULL || (working_directory != NULL && directory == NULL) ||
      environment_block == NULL) {
    SetLastError(ERROR_NOT_ENOUGH_MEMORY);
    goto fail;
  }
  if (!CreateProcessW(NULL, command, NULL, NULL, FALSE,
          EXTENDED_STARTUPINFO_PRESENT | CREATE_UNICODE_ENVIRONMENT |
              CREATE_NEW_PROCESS_GROUP | CREATE_SUSPENDED,
          environment_block, directory, &startup.StartupInfo, &process)) {
    goto fail;
  }

  job = CreateJobObjectW(NULL, NULL);
  JOBOBJECT_EXTENDED_LIMIT_INFORMATION limits = {0};
  limits.BasicLimitInformation.LimitFlags = JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE;
  if (job == NULL ||
      !SetInformationJobObject(job, JobObjectExtendedLimitInformation,
          &limits, sizeof(limits)) ||
      !AssignProcessToJobObject(job, process.hProcess)) goto fail;
  // The pseudoconsole owns the opposing ends after CreateProcess. Releasing
  // our copies before the client resumes matches the documented ConPTY handle
  // lifecycle and prevents its synchronous input channel from remaining idle.
  tr_close(input_read);
  input_read = NULL;
  tr_close(output_write);
  output_write = NULL;
  if (ResumeThread(process.hThread) == (DWORD)-1) goto fail;

  result = (tr_pty *)calloc(1, sizeof(tr_pty));
  if (result == NULL) {
    SetLastError(ERROR_NOT_ENOUGH_MEMORY);
    goto fail;
  }
  result->console = console;
  result->input = input_write;
  result->output = output_read;
  result->process = process.hProcess;
  result->job = job;
  result->pid = process.dwProcessId;
  InitializeCriticalSection(&result->write_lock);
  InitializeConditionVariable(&result->write_ready);
  result->writer_initialized = 1;
  result->writer_thread = CreateThread(NULL, 0, tr_writer, result, 0, NULL);
  if (result->writer_thread == NULL) goto fail;
  CloseHandle(process.hThread);
  DeleteProcThreadAttributeList(attributes);
  free(attributes);
  free(command);
  free(directory);
  free(environment_block);
  return result;

fail:
  if (error_code != NULL) *error_code = (int)GetLastError();
  if (result != NULL) tr_stop_writer(result);
  if (process.hProcess != NULL) TerminateProcess(process.hProcess, 1);
  tr_close(process.hThread);
  tr_close(process.hProcess);
  tr_close(job);
  if (attributes != NULL) DeleteProcThreadAttributeList(attributes);
  free(attributes);
  if (console != NULL) ClosePseudoConsole(console);
  tr_close(input_read);
  tr_close(input_write);
  tr_close(output_read);
  tr_close(output_write);
  free(command);
  free(directory);
  free(environment_block);
  free(result);
  return NULL;
}

int tr_pty_pid(const tr_pty *pty) { return pty == NULL ? -1 : (int)pty->pid; }

int tr_pty_read(tr_pty *pty, uint8_t *buffer, int capacity) {
  DWORD available = 0;
  DWORD read = 0;
  if (pty == NULL) return -1;
  if (!PeekNamedPipe(pty->output, NULL, 0, NULL, &available, NULL)) {
    DWORD error = GetLastError();
    if (error == ERROR_BROKEN_PIPE) return -2;
    pty->last_error = (int)error;
    return -1;
  }
  if (available == 0) return 0;
  DWORD requested = available < (DWORD)capacity ? available : (DWORD)capacity;
  if (ReadFile(pty->output, buffer, requested, &read, NULL)) return (int)read;
  pty->last_error = (int)GetLastError();
  return -1;
}

int tr_pty_write(tr_pty *pty, const uint8_t *buffer, int length) {
  if (pty == NULL || length <= 0) return pty == NULL ? -1 : 0;
  EnterCriticalSection(&pty->write_lock);
  if (pty->writer_stopping) {
    LeaveCriticalSection(&pty->write_lock);
    return -1;
  }
  size_t space = TR_WRITE_QUEUE_CAPACITY - pty->queued_bytes;
  DWORD accepted = (DWORD)((size_t)length < space ? (size_t)length : space);
  if (accepted == 0) {
    LeaveCriticalSection(&pty->write_lock);
    return 0;
  }
  tr_write_chunk *chunk = (tr_write_chunk *)calloc(1, sizeof(tr_write_chunk));
  if (chunk == NULL) {
    pty->last_error = ERROR_NOT_ENOUGH_MEMORY;
    LeaveCriticalSection(&pty->write_lock);
    return -1;
  }
  chunk->data = (uint8_t *)malloc(accepted);
  if (chunk->data == NULL) {
    free(chunk);
    pty->last_error = ERROR_NOT_ENOUGH_MEMORY;
    LeaveCriticalSection(&pty->write_lock);
    return -1;
  }
  memcpy(chunk->data, buffer, accepted);
  chunk->length = accepted;
  if (pty->write_tail == NULL) {
    pty->write_head = chunk;
  } else {
    pty->write_tail->next = chunk;
  }
  pty->write_tail = chunk;
  pty->queued_bytes += accepted;
  WakeConditionVariable(&pty->write_ready);
  LeaveCriticalSection(&pty->write_lock);
  return (int)accepted;
}

int tr_pty_resize(tr_pty *pty, int columns, int rows) {
  COORD size = {(SHORT)columns, (SHORT)rows};
  if (pty == NULL) return -1;
  HRESULT result = ResizePseudoConsole(pty->console, size);
  if (FAILED(result)) pty->last_error = (int)result;
  return SUCCEEDED(result) ? 0 : -1;
}

int tr_pty_try_wait(tr_pty *pty, int *exit_code) {
  if (pty == NULL) return -1;
  if (!pty->exited) {
    DWORD code = STILL_ACTIVE;
    if (!GetExitCodeProcess(pty->process, &code)) {
      pty->last_error = (int)GetLastError();
      return -1;
    }
    if (code == STILL_ACTIVE) return 0;
    pty->exited = 1;
    pty->exit_code = (int)code;
  }
  if (exit_code != NULL) *exit_code = pty->exit_code;
  return 1;
}

int tr_pty_signal(tr_pty *pty, int force) {
  if (pty == NULL) return -1;
  BOOL result = force ? TerminateJobObject(pty->job, 1)
                      : GenerateConsoleCtrlEvent(CTRL_BREAK_EVENT, pty->pid);
  if (!result) pty->last_error = (int)GetLastError();
  return result ? 0 : -1;
}

int tr_pty_last_error(const tr_pty *pty) {
  return pty == NULL ? ERROR_INVALID_HANDLE : pty->last_error;
}

void tr_pty_error_message(int error_code, char *buffer, int capacity) {
  if (buffer == NULL || capacity <= 0) return;
  wchar_t wide[512] = {0};
  DWORD message_code = (DWORD)error_code;
  if ((message_code & 0xFFFF0000u) == 0x80070000u) {
    message_code &= 0xFFFFu;
  }
  DWORD length = FormatMessageW(FORMAT_MESSAGE_FROM_SYSTEM |
          FORMAT_MESSAGE_IGNORE_INSERTS, NULL, message_code, 0, wide,
      (DWORD)(sizeof(wide) / sizeof(wide[0])), NULL);
  if (length == 0 || WideCharToMultiByte(CP_UTF8, 0, wide, -1, buffer,
                         capacity, NULL, NULL) == 0) {
    buffer[0] = '\0';
  }
}

void tr_pty_free(tr_pty *pty) {
  if (pty == NULL) return;
  if (!pty->exited) TerminateJobObject(pty->job, 1);
  tr_stop_writer(pty);
  if (pty->console != NULL) ClosePseudoConsole(pty->console);
  tr_close(pty->input);
  tr_close(pty->output);
  tr_close(pty->process);
  tr_close(pty->job);
  free(pty);
}

#else

#include <fcntl.h>
#include <signal.h>
#include <stdio.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <termios.h>
#include <unistd.h>
#ifdef __APPLE__
#include <util.h>
#else
#include <pty.h>
#endif

typedef struct {
  int pid;
  int code;
} tr_message;

struct tr_pty {
  int master;
  int status;
  pid_t pid;
  int exited;
  int exit_code;
  int last_error;
};

static int tr_nonblocking(int descriptor) {
  int flags = fcntl(descriptor, F_GETFL, 0);
  return flags < 0 ? -1 : fcntl(descriptor, F_SETFL, flags | O_NONBLOCK);
}

static int tr_exit_code(int status) {
  if (WIFEXITED(status)) return WEXITSTATUS(status);
  if (WIFSIGNALED(status)) return 128 + WTERMSIG(status);
  return -1;
}

tr_pty *tr_pty_spawn(const char *executable,
                     const char *const *arguments,
                     const char *working_directory,
                     const char *const *environment,
                     int columns,
                     int rows,
                     int *error_code) {
  int master = -1;
  int slave = -1;
  int messages[2] = {-1, -1};
  int exec_errors[2] = {-1, -1};
  pid_t spawned_pid = -1;
  struct winsize size = {0};
  size.ws_col = (unsigned short)columns;
  size.ws_row = (unsigned short)rows;
  if (openpty(&master, &slave, NULL, NULL, &size) != 0 || pipe(messages) != 0 ||
      pipe(exec_errors) != 0 ||
      fcntl(exec_errors[1], F_SETFD, FD_CLOEXEC) != 0) {
    goto fail;
  }

  pid_t supervisor = fork();
  if (supervisor < 0) goto fail;
  if (supervisor == 0) {
    close(messages[0]);
    close(exec_errors[0]);
    pid_t child = fork();
    if (child == 0) {
      close(messages[1]);
      close(master);
      if (setsid() < 0 || ioctl(slave, TIOCSCTTY, 0) < 0 ||
          dup2(slave, STDIN_FILENO) < 0 ||
          dup2(slave, STDOUT_FILENO) < 0 ||
          dup2(slave, STDERR_FILENO) < 0) {
        int child_error = errno;
        (void)write(exec_errors[1], &child_error, sizeof(child_error));
        _exit(126);
      }
      if (slave > STDERR_FILENO) close(slave);
      if (working_directory != NULL && chdir(working_directory) != 0) {
        int child_error = errno;
        (void)write(exec_errors[1], &child_error, sizeof(child_error));
        _exit(126);
      }
      execve(executable, (char *const *)arguments, (char *const *)environment);
      int child_error = errno;
      (void)write(exec_errors[1], &child_error, sizeof(child_error));
      _exit(127);
    }
    close(exec_errors[1]);
    close(master);
    close(slave);
    tr_message message = {(int)child, -1};
    if (child < 0 || write(messages[1], &message, sizeof(message)) !=
                         (ssize_t)sizeof(message)) _exit(125);
    int status = 0;
    while (waitpid(child, &status, 0) < 0 && errno == EINTR) {}
    message.code = tr_exit_code(status);
    (void)write(messages[1], &message, sizeof(message));
    close(messages[1]);
    _exit(0);
  }

  close(slave);
  slave = -1;
  close(messages[1]);
  messages[1] = -1;
  close(exec_errors[1]);
  exec_errors[1] = -1;
  tr_message message = {0};
  ssize_t received;
  do {
    received = read(messages[0], &message, sizeof(message));
  } while (received < 0 && errno == EINTR);
  if (received == (ssize_t)sizeof(message) && message.pid > 0) {
    spawned_pid = (pid_t)message.pid;
  }
  if (spawned_pid <= 0 || tr_nonblocking(master) != 0 ||
      tr_nonblocking(messages[0]) != 0) {
    goto fail;
  }
  int exec_error = 0;
  do {
    received = read(exec_errors[0], &exec_error, sizeof(exec_error));
  } while (received < 0 && errno == EINTR);
  close(exec_errors[0]);
  exec_errors[0] = -1;
  if (received != 0) {
    if (received == (ssize_t)sizeof(exec_error)) errno = exec_error;
    goto fail;
  }
  tr_pty *result = (tr_pty *)calloc(1, sizeof(tr_pty));
  if (result == NULL) goto fail;
  result->master = master;
  result->status = messages[0];
  result->pid = (pid_t)message.pid;
  return result;

fail:
  if (error_code != NULL) *error_code = errno == 0 ? EIO : errno;
  if (spawned_pid > 0) (void)kill(-spawned_pid, SIGKILL);
  if (master >= 0) close(master);
  if (slave >= 0) close(slave);
  if (messages[0] >= 0) close(messages[0]);
  if (messages[1] >= 0) close(messages[1]);
  if (exec_errors[0] >= 0) close(exec_errors[0]);
  if (exec_errors[1] >= 0) close(exec_errors[1]);
  return NULL;
}

int tr_pty_pid(const tr_pty *pty) { return pty == NULL ? -1 : (int)pty->pid; }

int tr_pty_read(tr_pty *pty, uint8_t *buffer, int capacity) {
  if (pty == NULL) return -1;
  ssize_t result = read(pty->master, buffer, (size_t)capacity);
  if (result > 0) return (int)result;
  if (result == 0) return -2;
  if (errno == EAGAIN || errno == EWOULDBLOCK) return 0;
  if (errno == EIO) return -2;
  pty->last_error = errno;
  return -1;
}

int tr_pty_write(tr_pty *pty, const uint8_t *buffer, int length) {
  if (pty == NULL) return -1;
  ssize_t result = write(pty->master, buffer, (size_t)length);
  if (result >= 0) return (int)result;
  if (errno == EAGAIN || errno == EWOULDBLOCK) return 0;
  pty->last_error = errno;
  return -1;
}

int tr_pty_resize(tr_pty *pty, int columns, int rows) {
  if (pty == NULL) return -1;
  struct winsize size = {0};
  size.ws_col = (unsigned short)columns;
  size.ws_row = (unsigned short)rows;
  int result = ioctl(pty->master, TIOCSWINSZ, &size);
  if (result != 0) pty->last_error = errno;
  return result;
}

int tr_pty_try_wait(tr_pty *pty, int *exit_code) {
  if (pty == NULL) return -1;
  if (!pty->exited) {
    tr_message message = {0};
    ssize_t result = read(pty->status, &message, sizeof(message));
    if (result < 0 && (errno == EAGAIN || errno == EWOULDBLOCK)) return 0;
    if (result != (ssize_t)sizeof(message)) {
      if (result < 0) pty->last_error = errno;
      return result == 0 ? 0 : -1;
    }
    pty->exited = 1;
    pty->exit_code = message.code;
  }
  if (exit_code != NULL) *exit_code = pty->exit_code;
  return 1;
}

int tr_pty_signal(tr_pty *pty, int force) {
  if (pty == NULL) return -1;
  int signal_number = force ? SIGKILL : SIGTERM;
  int result = kill(-pty->pid, signal_number);
  if (result != 0) pty->last_error = errno;
  return result;
}

int tr_pty_last_error(const tr_pty *pty) {
  return pty == NULL ? EINVAL : pty->last_error;
}

void tr_pty_error_message(int error_code, char *buffer, int capacity) {
  if (buffer == NULL || capacity <= 0) return;
  const char *message = strerror(error_code);
  if (message == NULL) message = "Unknown PTY error";
  snprintf(buffer, (size_t)capacity, "%s", message);
}

void tr_pty_free(tr_pty *pty) {
  if (pty == NULL) return;
  if (!pty->exited) (void)kill(-pty->pid, SIGKILL);
  close(pty->master);
  close(pty->status);
  free(pty);
}

#endif
