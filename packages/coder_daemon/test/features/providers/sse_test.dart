import 'dart:convert';
import 'dart:typed_data';

import 'package:coder_daemon/src/features/providers/infrastructure/openai/openai.dart';
import 'package:test/test.dart';

void main() {
  test('SSE decoder handles split chunks and multiline data', () async {
    const source =
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

  test('SSE decoder ignores comments and flushes trailing data', () async {
    final stream = Stream<Uint8List>.value(
      Uint8List.fromList(
        utf8.encode(': keepalive\nevent\ndata: value without final blank'),
      ),
    );

    final events = await decodeServerSentEvents(stream).toList();

    expect(events.single.event, isEmpty);
    expect(events.single.data, 'value without final blank');
  });
}
