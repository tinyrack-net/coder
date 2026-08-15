import 'package:agent/agent.dart';
import 'package:test/test.dart';

void main() {
  test('usage snapshots normalize provider values and round-trip', () {
    final usage = ModelUsage.fromJson(<String, dynamic>{
      'inputTokens': 12,
      'cachedInputTokens': 3,
      'outputTokens': 7,
      'reasoningTokens': 2,
      'totalTokens': 19,
    });

    expect(usage.contextTokens, 19);
    expect(usage.isEmpty, isFalse);
    expect(usage.toJson(), <String, int>{
      'inputTokens': 12,
      'cachedInputTokens': 3,
      'outputTokens': 7,
      'reasoningTokens': 2,
      'totalTokens': 19,
    });
    expect(
      usage.toString(),
      'ModelUsage(input: 12, cached: 3, output: 7, reasoning: 2, total: 19)',
    );
  });

  test('usage defaults invalid counters and derives context tokens', () {
    final empty = ModelUsage.fromJson(<String, dynamic>{
      'inputTokens': 'unknown',
      'cachedInputTokens': null,
      'outputTokens': 1.5,
      'reasoningTokens': false,
      'totalTokens': <Object?>[],
    });
    expect(empty.isEmpty, isTrue);
    expect(empty.contextTokens, 0);

    final counters = <String>[
      'inputTokens',
      'cachedInputTokens',
      'outputTokens',
      'reasoningTokens',
      'totalTokens',
    ];
    for (final counter in counters) {
      final usage = ModelUsage.fromJson(<String, dynamic>{counter: 1});
      expect(usage.isEmpty, isFalse, reason: counter);
    }

    final derived = ModelUsage.fromJson(<String, dynamic>{
      'inputTokens': 8,
      'outputTokens': 5,
    });
    expect(derived.contextTokens, 13);
  });
}
