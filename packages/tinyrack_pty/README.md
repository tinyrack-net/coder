# tinyrack_pty

Private cross-platform pseudo-terminal support for Tinyrack Coder. The package
builds a small C Native Asset on Linux, macOS, and Windows. Android and iOS
consumers receive no local PTY asset and remain remote-terminal-only clients.

The API deliberately exposes raw terminal bytes. Consumers are responsible for
stateful text decoding and terminal emulation.
