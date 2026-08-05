/// Private cross-platform pseudo-terminal processes for Tinyrack Coder.
library;

import 'package:tinyrack_pty/src/native_bindings.dart';

export 'src/pty_exception.dart';
export 'src/pty_process.dart';

/// Internal package API version used to verify native binding linkage.
String get tinyrackPtyVersion => nativePtyBindingsVersion();
