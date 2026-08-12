import 'dart:io';

import 'package:tinest_quality/src/desktop_version_sync.dart';

void main() {
  DesktopVersionSync(Directory.current.path).synchronize();
}
