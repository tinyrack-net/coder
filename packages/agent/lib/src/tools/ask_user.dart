import 'dart:async';
import 'dart:convert';

import 'package:agent/src/contracts.dart';
import 'package:agent/src/model.dart';
import 'package:agent/src/tools/tool_registry.dart';
import 'package:agent/src/tools/tool_support.dart';

/// Largest number of questions one `ask_user` call may raise.
const int maxUserQuestions = 3;

/// Bounds on the fixed choices one question may offer.
const int minUserQuestionOptions = 2;

/// Largest number of fixed choices one question may offer.
const int maxUserQuestionOptions = 3;

/// Largest number of characters a question header may use.
const int maxUserQuestionHeader = 12;

/// Asks the user structured multiple-choice questions and blocks for answers.
///
/// The schema cannot express the bounds — strict provider schemas reject
/// `minItems` and `maxItems` — so they are enforced here and a violation comes
/// back as a correctable tool error instead of a failed turn.
class AskUserTool extends AgentTool {
  /// Creates an [AskUserTool].
  factory AskUserTool({required UserQuestionCoordinator coordinator}) =>
      AskUserTool._(coordinator);

  AskUserTool._(this._coordinator);

  final UserQuestionCoordinator _coordinator;

  @override
  String get name => 'ask_user';

  @override
  String get description =>
      'Ask the user up to $maxUserQuestions multiple-choice questions and '
      "wait for the answers. Use it when a decision is genuinely the user's "
      'to make and proceeding on a guess would waste work. Each question '
      'needs $minUserQuestionOptions to $maxUserQuestionOptions options; the '
      'client always adds a free-form option, so never write one yourself.';

  @override
  AgentToolRisk get risk => AgentToolRisk.read;

  @override
  Map<String, dynamic> get strictJsonSchema =>
      strictToolObject(<String, Map<String, dynamic>>{
        'questions': <String, dynamic>{
          'type': 'array',
          'description':
              'Between 1 and $maxUserQuestions questions, most important '
              'first.',
          'items': strictToolObject(<String, Map<String, dynamic>>{
            'id': <String, dynamic>{
              'type': 'string',
              'description': 'Identifier unique within this call.',
            },
            'header': <String, dynamic>{
              'type': 'string',
              'description':
                  'A label of at most $maxUserQuestionHeader characters, for '
                  'example "Storage".',
            },
            'question': <String, dynamic>{
              'type': 'string',
              'description':
                  'The complete question, ending in a question '
                  'mark.',
            },
            'options': <String, dynamic>{
              'type': 'array',
              'description':
                  'Between $minUserQuestionOptions and $maxUserQuestionOptions '
                  'mutually exclusive choices.',
              'items': strictToolObject(<String, Map<String, dynamic>>{
                'label': <String, dynamic>{
                  'type': 'string',
                  'description': 'The choice, in one to five words.',
                },
                'description': <String, dynamic>{
                  'type': 'string',
                  'description': 'What choosing this option means.',
                },
              }),
            },
          }),
        },
      });

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async {
    final raw = arguments['questions'];
    if (raw is! List || raw.isEmpty || raw.length > maxUserQuestions) {
      return _reject(
        'Ask between 1 and $maxUserQuestions questions.',
      );
    }
    final questions = <UserQuestion>[];
    final ids = <String>{};
    for (final entry in raw) {
      if (entry is! Map) return _reject('Every question must be an object.');
      final id = entry['id'];
      if (id is! String || id.trim().isEmpty) {
        return _reject('Every question needs a non-empty "id".');
      }
      if (!ids.add(id)) return _reject('Duplicate question id "$id".');
      final header = entry['header'];
      if (header is! String ||
          header.trim().isEmpty ||
          header.length > maxUserQuestionHeader) {
        return _reject(
          'Question "$id" needs a header of 1 to $maxUserQuestionHeader '
          'characters.',
        );
      }
      final question = entry['question'];
      if (question is! String || question.trim().isEmpty) {
        return _reject('Question "$id" needs non-empty question text.');
      }
      final rawOptions = entry['options'];
      if (rawOptions is! List ||
          rawOptions.length < minUserQuestionOptions ||
          rawOptions.length > maxUserQuestionOptions) {
        return _reject(
          'Question "$id" needs $minUserQuestionOptions to '
          '$maxUserQuestionOptions options.',
        );
      }
      final options = <UserQuestionOption>[];
      for (final rawOption in rawOptions) {
        if (rawOption is! Map) {
          return _reject('Every option of "$id" must be an object.');
        }
        final label = rawOption['label'];
        final optionDescription = rawOption['description'];
        if (label is! String ||
            label.trim().isEmpty ||
            optionDescription is! String) {
          return _reject(
            'Every option of "$id" needs a non-empty label and a description.',
          );
        }
        options.add(
          UserQuestionOption(
            label: label.trim(),
            description: optionDescription,
          ),
        );
      }
      questions.add(
        UserQuestion(
          id: id,
          header: header.trim(),
          question: question.trim(),
          options: List<UserQuestionOption>.unmodifiable(options),
        ),
      );
    }
    context.cancellation.throwIfCancelled();
    final answers = await _coordinator.ask(
      context.callId,
      List<UserQuestion>.unmodifiable(questions),
      context.cancellation,
    );
    return ToolResult(
      output: truncateToolOutput(
        jsonEncode(<Map<String, dynamic>>[
          for (final answer in answers)
            <String, dynamic>{
              'questionId': answer.questionId,
              'answer': answer.answer,
              'isFreeForm': answer.isFreeForm,
            },
        ]),
      ),
    );
  }

  ToolResult _reject(String reason) => ToolResult(
    output: jsonEncode(<String, dynamic>{'error': reason}),
    isError: true,
  );
}

/// Registers raising multiple-choice questions to the user.
final class AskUserToolProvider extends SelectableToolProvider {
  /// Creates a [AskUserToolProvider].
  const AskUserToolProvider();

  @override
  String get id => 'ask_user';

  @override
  AgentToolDefinition get catalogEntry => AgentToolDefinition(
    id: id,
    name: id,
    description:
        'Ask the user multiple-choice questions and wait for the '
        'answers.',
    risk: AgentToolRisk.read,
    alwaysOn: true,
  );

  @override
  List<AgentTool> build(AgentToolScope scope) => <AgentTool>[
    AskUserTool(coordinator: scope.questions),
  ];
}
