#ifndef TINYRACK_PTY_H
#define TINYRACK_PTY_H

#include <stddef.h>
#include <stdint.h>

#ifdef _WIN32
#define TR_EXPORT __declspec(dllexport)
#else
#define TR_EXPORT __attribute__((visibility("default")))
#endif

typedef struct tr_pty tr_pty;

TR_EXPORT tr_pty *tr_pty_spawn(const char *executable,
                               const char *const *arguments,
                               const char *working_directory,
                               const char *const *environment,
                               int columns,
                               int rows,
                               int *error_code);
TR_EXPORT int tr_pty_pid(const tr_pty *pty);
TR_EXPORT int tr_pty_read(tr_pty *pty, uint8_t *buffer, int capacity);
TR_EXPORT int tr_pty_write(tr_pty *pty, const uint8_t *buffer, int length);
TR_EXPORT int tr_pty_resize(tr_pty *pty, int columns, int rows);
TR_EXPORT int tr_pty_try_wait(tr_pty *pty, int *exit_code);
TR_EXPORT int tr_pty_signal(tr_pty *pty, int force);
TR_EXPORT int tr_pty_last_error(const tr_pty *pty);
TR_EXPORT void tr_pty_error_message(int error_code, char *buffer, int capacity);
TR_EXPORT void tr_pty_free(tr_pty *pty);

#endif
