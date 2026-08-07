import 'dart:async';

import 'package:coder_app/l10n/gen/app_localizations.dart';
import 'package:coder_app/src/features/conversation/application/conversation_controller.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

/// Sentinel radio value standing for the always-present free-form option.
///
/// The agent never authors this choice, so it cannot collide with a label it
/// wrote: option values are prefixed with their index.
const String _otherValue = 'other';

/// Renders the questions one agent turn is blocked on.
///
/// Every question offers the agent's fixed choices plus a free-form answer, so
/// the user is never forced into an option that does not fit.
class ChatQuestionCard extends ConsumerStatefulWidget {
  /// Creates a [ChatQuestionCard].
  const ChatQuestionCard({
    required this.hostId,
    required this.request,
    super.key,
  });

  /// Stable host profile containing the question's session.
  final String hostId;

  /// The pending question rendered by this card.
  final UserQuestionRequestDto request;

  @override
  ConsumerState<ChatQuestionCard> createState() => _ChatQuestionCardState();
}

class _ChatQuestionCardState extends ConsumerState<ChatQuestionCard> {
  /// Chosen radio value per question id.
  final Map<String, String> _selected = <String, String>{};

  /// Free-form text per question id, used when [_otherValue] is selected.
  final Map<String, TextEditingController> _freeForm =
      <String, TextEditingController>{};

  bool _submitting = false;

  @override
  void dispose() {
    for (final controller in _freeForm.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(String questionId) =>
      _freeForm.putIfAbsent(questionId, TextEditingController.new);

  /// The answers, or null while any question is still unanswered.
  List<UserQuestionAnswerDto>? get _answers {
    final answers = <UserQuestionAnswerDto>[];
    for (final question in widget.request.questions) {
      final choice = _selected[question.id];
      if (choice == null) return null;
      if (choice == _otherValue) {
        final text = _controllerFor(question.id).text.trim();
        if (text.isEmpty) return null;
        answers.add(
          UserQuestionAnswerDto(
            questionId: question.id,
            answer: text,
            isFreeForm: true,
          ),
        );
        continue;
      }
      answers.add(
        UserQuestionAnswerDto(
          questionId: question.id,
          answer: question.options[int.parse(choice)].label,
          isFreeForm: false,
        ),
      );
    }
    return answers;
  }

  Future<void> _submit(List<UserQuestionAnswerDto> answers) async {
    setState(() => _submitting = true);
    try {
      await ref
          .read(
            conversationControllerProvider(
              widget.hostId,
              widget.request.sessionId,
            ).notifier,
          )
          .answerUserQuestion(widget.request.id, answers);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final answers = _answers;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TRSpacing.large,
        TRSpacing.small,
        TRSpacing.large,
        0,
      ),
      child: TRCard(
        key: ValueKey<String>('chat-question-${widget.request.id}'),
        padding: TRCardPadding.none,
        variant: TRCardVariant.elevated,
        child: Padding(
          padding: const EdgeInsets.all(TRSpacing.medium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (final question in widget.request.questions)
                _QuestionSection(
                  key: ValueKey<String>(question.id),
                  question: question,
                  selected: _selected[question.id],
                  freeFormController: _controllerFor(question.id),
                  onChanged: (value) =>
                      setState(() => _selected[question.id] = value),
                  onFreeFormChanged: (_) => setState(() {}),
                ),
              const SizedBox(height: TRSpacing.small),
              Align(
                alignment: Alignment.centerRight,
                child: TRButton(
                  key: const ValueKey<String>('chat-question-submit'),
                  intent: TRIntent.primary,
                  onPressed: answers == null || _submitting
                      ? null
                      : () => unawaited(_submit(answers)),
                  child: Text(l10n.chatQuestionSubmit),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestionSection extends StatelessWidget {
  const _QuestionSection({
    required this.question,
    required this.selected,
    required this.freeFormController,
    required this.onChanged,
    required this.onFreeFormChanged,
    super.key,
  });

  final UserQuestionItemDto question;
  final String? selected;
  final TextEditingController freeFormController;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onFreeFormChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: TRSpacing.small),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TRText(question.header, variant: TRTextVariant.label),
          const SizedBox(height: TRSpacing.threeExtraSmall),
          TRText(question.question),
          const SizedBox(height: TRSpacing.small),
          TRRadioGroup(
            value: selected,
            onValueChange: onChanged,
            children: <TRRadio>[
              for (var index = 0; index < question.options.length; index += 1)
                TRRadio(
                  value: '$index',
                  label: _OptionLabel(option: question.options[index]),
                ),
              TRRadio(
                value: _otherValue,
                label: TRText(l10n.chatQuestionOther),
              ),
            ],
          ),
          if (selected == _otherValue) ...<Widget>[
            const SizedBox(height: TRSpacing.small),
            TRTextField(
              key: ValueKey<String>('chat-question-other-${question.id}'),
              controller: freeFormController,
              placeholder: l10n.chatQuestionOtherPlaceholder,
              onChanged: onFreeFormChanged,
            ),
          ],
        ],
      ),
    );
  }
}

class _OptionLabel extends StatelessWidget {
  const _OptionLabel({required this.option});

  final UserQuestionOptionDto option;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      TRText(option.label),
      if (option.description.isNotEmpty)
        TRText(
          option.description,
          variant: TRTextVariant.caption,
          color: TRTextColor.muted,
        ),
    ],
  );
}
