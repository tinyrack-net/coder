import 'package:coder_agent/coder_agent.dart';
import 'package:coder_protocol/coder_protocol.dart';

/// Calculates the exact USD charge represented by one normalized usage event.
///
/// A null result means at least one token class that was actually used has no
/// trustworthy price. Callers must preserve that unknown state for the rest of
/// the session instead of presenting a partial estimate as an exact amount.
double? modelUsageCostUsd(ModelUsage usage, ModelPricingDto? pricing) {
  if (usage.isEmpty) return 0;
  if (pricing == null) return null;

  final cached = usage.cachedInputTokens.clamp(0, usage.inputTokens);
  final uncached = usage.inputTokens - cached;
  final inputPrice = pricing.input;
  final outputPrice = pricing.output;
  final cachedPrice = pricing.cacheRead ?? inputPrice;
  if ((uncached > 0 && inputPrice == null) ||
      (cached > 0 && cachedPrice == null) ||
      (usage.outputTokens > 0 && outputPrice == null)) {
    return null;
  }

  const perMillion = 1000000;
  return (uncached * (inputPrice ?? 0) +
          cached * (cachedPrice ?? 0) +
          usage.outputTokens * (outputPrice ?? 0)) /
      perMillion;
}
