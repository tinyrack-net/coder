import 'package:shelf/shelf.dart';

/// Type-safe boundary implemented by the attachment feature transport.
abstract interface class AttachmentHttpBinding {
  /// Whether [request] targets the attachment route.
  bool matches(Request request);

  /// Handles an authenticated attachment request.
  Future<Response> call(Request request, Map<String, String> cors);
}
