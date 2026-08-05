import 'package:coder_app/src/attachment_io.dart';

/// Creates the save/share adapter used on desktop and mobile.
AttachmentExportPort createAttachmentExport() => const NativeAttachmentExport();
