import 'dart:async';
import 'dart:typed_data';

import 'package:coder_app/src/attachment_ports.dart';
import 'package:file_selector/file_selector.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

export 'package:coder_app/src/attachment_ports.dart';

/// Composer input adapter for a browser.
///
/// The file picker, clipboard, and drop plugins all ship web implementations,
/// so this differs from the native adapter only in lacking `dart:io`.
final class WebAttachmentInput implements AttachmentInputPort {
  /// Creates the web adapter.
  const WebAttachmentInput();

  @override
  bool get supportsDrop => true;

  @override
  Future<List<PendingAttachment>> pickFiles() async {
    final files = await openFiles();
    return Future.wait(files.map(_fromXFile));
  }

  @override
  Future<List<PendingAttachment>> pasteFiles() async {
    final clipboard = SystemClipboard.instance;
    if (clipboard == null) return const <PendingAttachment>[];
    final reader = await clipboard.read();
    return _readItems(reader.items);
  }

  @override
  Future<List<PendingAttachment>> droppedFiles(PerformDropEvent event) =>
      _readItems(
        event.session.items
            .map((item) => item.dataReader)
            .whereType<DataReader>(),
      );

  Future<List<PendingAttachment>> _readItems(
    Iterable<DataReader> readers,
  ) async {
    final result = <PendingAttachment>[];
    for (final reader in readers) {
      final formats = reader
          .getFormats(Formats.standardFormats)
          .whereType<FileFormat>();
      final format = formats.firstOrNull;
      if (format == null) continue;
      final completer = Completer<PendingAttachment?>();
      final progress = reader.getFile(
        format,
        (file) async {
          try {
            final bytes = await file.readAll();
            final name =
                file.fileName ??
                await reader.getSuggestedName() ??
                defaultAttachmentName(format);
            completer.complete(
              _validated(
                PendingAttachment.fromBytes(
                  fileName: name,
                  mimeType: mimeFromAttachmentName(name, format: format),
                  bytes: bytes,
                ),
              ),
            );
          } on Object catch (error, stackTrace) {
            completer.completeError(error, stackTrace);
          }
        },
        onError: completer.completeError,
      );
      if (progress == null) continue;
      final attachment = await completer.future;
      if (attachment != null) result.add(attachment);
    }
    return result;
  }

  Future<PendingAttachment> _fromXFile(XFile file) async {
    // A browser has already buffered the selection, so the length is known
    // without touching a filesystem.
    final bytes = await file.readAsBytes();
    return _validated(
      PendingAttachment.fromBytes(
        fileName: file.name,
        mimeType: file.mimeType ?? mimeFromAttachmentName(file.name),
        bytes: bytes,
      ),
    );
  }

  PendingAttachment _validated(PendingAttachment attachment) {
    if (attachment.byteSize > maxPendingAttachmentBytes) {
      throw const FormatException('Attachment exceeds the 50 MB limit.');
    }
    return attachment;
  }
}

/// Download adapter for a browser.
final class WebAttachmentExport implements AttachmentExportPort {
  /// Creates the web export adapter.
  const WebAttachmentExport();

  @override
  Future<void> export({
    required String fileName,
    required String mimeType,
    required Uint8List bytes,
  }) async {
    // `saveTo` is a no-op on the web; `getSaveLocation` returning a name is
    // what triggers the browser download.
    final file = XFile.fromData(bytes, mimeType: mimeType, name: fileName);
    await file.saveTo(fileName);
  }
}
