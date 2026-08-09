import 'package:app/src/features/conversation/infrastructure/attachment_web.dart';

/// Creates the save adapter used in a browser.
AttachmentExportPort createAttachmentExport() => const WebAttachmentExport();
