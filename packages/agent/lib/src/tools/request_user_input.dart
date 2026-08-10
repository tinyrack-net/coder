import 'dart:async';
import 'package:agent/src/contracts.dart';
import 'package:agent/src/model.dart';
import 'package:agent/src/tools/tool_registry.dart';
import 'package:agent/src/tools/tool_support.dart';

/// Largest number of questions one `request_user_input` call may raise.
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
class RequestUserInputTool extends AgentTool {
  /// Creates a [RequestUserInputTool].
  factory RequestUserInputTool({
    required UserQuestionCoordinator coordinator,
  }) => RequestUserInputTool._(coordinator);

  RequestUserInputTool._(this._coordinator);

  final UserQuestionCoordinator _coordinator;

  @override
  String get name => 'request_user_input';

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
      value: <String, dynamic>{
        'answers': <String, dynamic>{
          for (final answer in answers)
            answer.questionId: <String, dynamic>{
              'answers': <String>[answer.answer],
            },
        },
      },
    );
  }

  ToolResult _reject(String reason) => ToolResult(
    value: <String, dynamic>{'error': reason},
    isError: true,
  );
}

/// Registers raising multiple-choice questions to the user.
final class RequestUserInputToolProvider extends SelectableToolProvider {
  /// Creates a [RequestUserInputToolProvider].
  const RequestUserInputToolProvider();

  @override
  String get id => 'request_user_input';

  @override
  AgentToolDefinition get catalogEntry => AgentToolDefinition(
    id: id,
    name: id,
    description:
        'Ask the user multiple-choice questions and wait for the '
        'answers.',
    risk: AgentToolRisk.read,
    group: AgentToolGroup.session,
    alwaysOn: true,
  );

  @override
  List<AgentTool> build(AgentToolScope scope) => scope.isRootAgent
      ? <AgentTool>[RequestUserInputTool(coordinator: scope.questions)]
      : const <AgentTool>[];
}
