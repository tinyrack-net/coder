import 'dart:convert';
import 'dart:typed_data';

import 'package:coder_provider_openai/coder_provider_openai.dart';
import 'package:test/test.dart';

void main() {
  test('SSE decoder handles split chunks and multiline data', () async {
    final source =
        'event: update\ndata: {"one":1,\ndata: "two":2}\n\ndata: [DONE]\n\n';
    final bytes = utf8.encode(source);
    final stream = Stream<Uint8List>.fromIterable(<Uint8List>[
      Uint8List.fromList(bytes.sublist(0, 17)),
      Uint8List.fromList(bytes.sublist(17)),
    ]);

    final events = await decodeServerSentEvents(stream).toList();

    expect(events, hasLength(2));
    expect(events.first.event, 'update');
    expect(events.first.data, '{"one":1,\n"two":2}');
    expect(events.last.data, '[DONE]');
  });
}
