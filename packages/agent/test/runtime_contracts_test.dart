import 'package:agent/agent.dart';
import 'package:test/test.dart';

void main() {
  test(
    'AgentRunResult carries the provider items and driver tool-round count',
    tags: const <String>['feature_test__turn_execution__unit'],
    () {
      const item = AssistantConversationItem(text: 'done');

      const result = AgentRunResult(
        conversationItems: <ConversationItem>[item],
        toolRounds: 2,
      );

      expect(result.conversationItems, const <ConversationItem>[item]);
      expect(result.toolRounds, 2);
    },
  );

  test('model controls and capability copies preserve typed values', () {
    final suffix = DateTime.now().microsecondsSinceEpoch.toString();
    final choice = AgentModelControlChoice(
      id: 'high-$suffix',
      label: 'High',
      description: 'Use more reasoning.',
    );
    final descriptor = AgentModelControlDescriptor(
      id: AgentModelControlIds.reasoningEffort,
      label: 'Reasoning',
      kind: AgentModelControlKind.choice,
      presentation: AgentModelControlPresentation.selectableChip,
      choices: <AgentModelControlChoice>[choice],
      conflictsWith: <String>[AgentModelControlIds.thinkingBudget],
    );
    final original = AgentModelCapabilities(
      controls: <AgentModelControlDescriptor>[descriptor],
    );

    expect(original.copyWith().controls.single.choices.single, same(choice));
    final replaced = original.copyWith(
      streaming: AgentCapabilitySupport.supported,
      toolCalling: AgentCapabilitySupport.unsupported,
      functionTools: AgentCapabilitySupport.supported,
      deferredTools: AgentCapabilitySupport.supported,
      imageInput: AgentCapabilitySupport.supported,
      fileInput: AgentCapabilitySupport.unsupported,
      controls: const <AgentModelControlDescriptor>[],
      source: AgentCapabilitySource.refreshed,
    );
    expect(replaced.streaming, AgentCapabilitySupport.supported);
    expect(replaced.deferredTools, AgentCapabilitySupport.supported);
    expect(replaced.controls, isEmpty);
    expect(replaced.source, AgentCapabilitySource.refreshed);

    final values = <AgentModelControlValue>[
      AgentModelControlStringValue(value: suffix),
      AgentModelControlBoolValue(value: suffix.isNotEmpty),
      AgentModelControlIntValue(value: suffix.length),
    ];
    expect((values[0] as AgentModelControlStringValue).value, suffix);
    expect((values[1] as AgentModelControlBoolValue).value, isTrue);
    expect((values[2] as AgentModelControlIntValue).value, suffix.length);

    final pricing = AgentModelPricing(
      input: suffix.length.toDouble(),
      output: 2,
      cacheRead: 1,
      cacheWrite: 3,
    );
    final limits = AgentModelLimits(
      context: suffix.length,
      input: 4,
      output: 5,
    );
    expect(pricing.input, suffix.length.toDouble());
    expect(pricing.cacheWrite, 3);
    expect(limits.context, suffix.length);
    expect(limits.output, 5);
  });
}
