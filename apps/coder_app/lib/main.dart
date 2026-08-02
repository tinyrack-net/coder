import 'dart:io';

import 'main_desktop.dart' as desktop;
import 'main_mobile.dart' as mobile;

Future<void> main() =>
    Platform.isAndroid || Platform.isIOS ? mobile.main() : desktop.main();
