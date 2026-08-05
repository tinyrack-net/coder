import 'package:coder_app/src/attachment_web.dart';

/// Creates the save adapter used in a browser.
AttachmentExportPort createAttachmentExport() => const WebAttachmentExport();
