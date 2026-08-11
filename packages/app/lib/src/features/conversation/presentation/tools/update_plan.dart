import 'package:app/src/features/conversation/presentation/tools/presenter.dart';

/// How `update_plan` appears in the chat timeline.
final Map<String, ChatToolPresenter> updatePlanPresenters =
    <String, ChatToolPresenter>{
      'update_plan': ChatToolPresenter(
        timeline: ChatToolTimeline.card,
        glyph: ChatToolGlyph.plan,
        title: (l10n, activity) {
          final plan = activity.arguments['plan'];
          return l10n.toolTitlePlan(plan is List ? plan.length : 0);
        },
        result: (l10n, activity, output) {
          final error = output is ChatToolJsonObject
              ? output.value['error']
              : null;
          return error is String ? error : genericToolResult(l10n, output);
        },
        isFailure: (output) =>
            output is ChatToolJsonObject && output.value['error'] != null,
      ),
    };
