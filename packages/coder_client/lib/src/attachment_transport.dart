import 'package:coder_client/src/api.dart';
import 'package:coder_protocol/coder_protocol.dart';

/// Attachment transport selected alongside the active RPC connection.
abstract interface class AttachmentTransport {
  /// Streams one immutable upload.
  Future<AttachmentDto> upload({
    required String fileName,
    required String mimeType,
    required int byteSize,
    required Stream<List<int>> bytes,
  });

  /// Opens one immutable download stream.
  Future<AttachmentDownload> download(String id);
}
