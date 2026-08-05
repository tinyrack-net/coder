import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:coder_client/coder_client.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

/// Maximum bytes accepted for a pending attachment.
const int maxPendingAttachmentBytes = 50 * 1024 * 1024;

/// Maximum pending files accepted by one submission.
const int maxPendingAttachmentCount = 10;

/// A repeatably readable local file waiting to be uploaded.
final class PendingAttachment {
  /// Creates a pending attachment.
  factory PendingAttachment({
    required String fileName,
    required String mimeType,
    required int byteSize,
    required Stream<List<int>> Function() openRead,
  }) => PendingAttachment._(fileName, mimeType, byteSize, openRead);

  const PendingAttachment._(
    this.fileName,
    this.mimeType,
    this.byteSize,
    this._openRead,
  );

  /// Creates a repeatable in-memory pending attachment.
  factory PendingAttachment.fromBytes({
    required String fileName,
    required String mimeType,
    required Uint8List bytes,
  }) => PendingAttachment(
    fileName: fileName,
    mimeType: mimeType,
    byteSize: bytes.length,
    openRead: () => Stream<List<int>>.value(bytes),
  );

  /// Display-only base name.
  final String fileName;

  /// Picker- or clipboard-provided media type.
  final String mimeType;

  /// Exact payload length.
  final int byteSize;

  final Stream<List<int>> Function() _openRead;

  /// Opens a fresh stream for an upload or preview.
  Stream<List<int>> openRead() => _openRead();

  /// Whether the composer can render an image preview.
  bool get isImage => <String>{
    'image/png',
    'image/jpeg',
    'image/webp',
    'image/gif',
  }.contains(mimeType);
}

/// Text and ordered files submitted by the composer.
final class ComposerSubmission {
  /// Creates one immutable composer submission.
  const ComposerSubmission({
    required this.text,
    required this.attachments,
  });

  /// Trimmed prompt, which may be empty for attachment-only turns.
  final String text;

  /// Pending files in selection, drop, or paste order.
  final List<PendingAttachment> attachments;
}

/// File-selection, clipboard, and drag/drop boundary for the composer.
abstract interface class AttachmentInputPort {
  /// Whether this adapter can receive operating-system drag events.
  bool get supportsDrop;

  /// Opens the platform multi-file selector.
  Future<List<PendingAttachment>> pickFiles();

  /// Reads file and image items from the platform clipboard.
  Future<List<PendingAttachment>> pasteFiles();

  /// Reads file items from a native drag event.
  Future<List<PendingAttachment>> droppedFiles(PerformDropEvent event);
}

/// Saves desktop downloads or opens the mobile system share sheet.
abstract interface class AttachmentExportPort {
  /// Exports fully downloaded bytes.
  Future<void> export({
    required String fileName,
    required String mimeType,
    required Uint8List bytes,
  });
}

/// Production native attachment input adapter.
final class NativeAttachmentInput implements AttachmentInputPort {
  /// Creates the native adapter.
  const NativeAttachmentInput();

  @override
  bool get supportsDrop =>
      Platform.isLinux || Platform.isMacOS || Platform.isWindows;

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
                _defaultName(format);
            completer.complete(
              _validated(
                PendingAttachment.fromBytes(
                  fileName: name,
                  mimeType: _mimeFromName(name, format: format),
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
    final length = await file.length();
    return _validated(
      PendingAttachment(
        fileName: file.name,
        mimeType: file.mimeType ?? _mimeFromName(file.name),
        byteSize: length,
        openRead: file.openRead,
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

/// Production save/share adapter.
final class NativeAttachmentExport implements AttachmentExportPort {
  /// Creates the native export adapter.
  const NativeAttachmentExport();

  @override
  Future<void> export({
    required String fileName,
    required String mimeType,
    required Uint8List bytes,
  }) async {
    final file = XFile.fromData(bytes, mimeType: mimeType, name: fileName);
    if (Platform.isAndroid || Platform.isIOS) {
      await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[file],
          fileNameOverrides: <String>[fileName],
        ),
      );
      return;
    }
    final location = await getSaveLocation(suggestedName: fileName);
    if (location != null) await file.saveTo(location.path);
  }
}

/// Production composer input adapter provider; tests override this port.
final attachmentInputProvider = Provider<AttachmentInputPort?>((ref) => null);

/// Production download export adapter provider; tests override this port.
final attachmentExportProvider = Provider<AttachmentExportPort>(
  (ref) => const NativeAttachmentExport(),
);

String _defaultName(FileFormat format) => switch (format) {
  final value when identical(value, Formats.png) => 'pasted-image.png',
  final value when identical(value, Formats.jpeg) => 'pasted-image.jpg',
  final value when identical(value, Formats.webp) => 'pasted-image.webp',
  final value when identical(value, Formats.gif) => 'pasted-image.gif',
  _ => 'pasted-file',
};

String _mimeFromName(String name, {FileFormat? format}) {
  if (identical(format, Formats.png)) return 'image/png';
  if (identical(format, Formats.jpeg)) return 'image/jpeg';
  if (identical(format, Formats.webp)) return 'image/webp';
  if (identical(format, Formats.gif)) return 'image/gif';
  final extension = name.toLowerCase().split('.').last;
  return switch (extension) {
    'png' => 'image/png',
    'jpg' || 'jpeg' => 'image/jpeg',
    'webp' => 'image/webp',
    'gif' => 'image/gif',
    'txt' || 'md' || 'log' => 'text/plain',
    'json' => 'application/json',
    'pdf' => 'application/pdf',
    'csv' => 'text/csv',
    _ => 'application/octet-stream',
  };
}

/// Fully buffers a streaming API download for preview or export.
Future<Uint8List> readAttachmentDownload(AttachmentDownload download) async {
  final builder = BytesBuilder(copy: false);
  await download.bytes.forEach(builder.add);
  return builder.takeBytes();
}
