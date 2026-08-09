import 'dart:async';
import 'dart:typed_data';

import 'package:app/src/features/conversation/infrastructure/attachment_export_io.dart'
    if (dart.library.js_interop) 'package:app/src/features/conversation/infrastructure/attachment_export_web.dart'
    as export_platform;
import 'package:client/client.dart';
import 'package:dropwell/dropwell.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  /// Reads file items delivered by a native drop.
  Future<List<PendingAttachment>> droppedFiles(List<DropwellFile> files);
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

/// Production composer input adapter provider; tests override this port.
final attachmentInputProvider = Provider<AttachmentInputPort?>((ref) => null);

/// Production download export adapter provider; tests override this port.
final attachmentExportProvider = Provider<AttachmentExportPort>(
  (ref) => export_platform.createAttachmentExport(),
);

/// Names a clipboard item that arrives without a filename.
String defaultAttachmentName(String? mimeHint) => switch (mimeHint) {
  'image/png' => 'pasted-image.png',
  'image/jpeg' => 'pasted-image.jpg',
  'image/webp' => 'pasted-image.webp',
  'image/gif' => 'pasted-image.gif',
  _ => 'pasted-file',
};

/// Derives a media type from a platform hint or a filename extension.
///
/// The hint wins when the platform gave one: it looked at the file, and an
/// extension can be missing, wrong, or belong to a name the platform invented.
String mimeFromAttachmentName(String name, {String? mimeHint}) {
  if (mimeHint != null && mimeHint.isNotEmpty) return mimeHint;
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
