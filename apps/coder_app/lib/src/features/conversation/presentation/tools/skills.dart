import 'package:coder_app/src/features/conversation/presentation/tools/presenter.dart';

/// How the skill tools appear in the chat timeline.
final Map<String, ChatToolPresenter>
skillsPresenters = <String, ChatToolPresenter>{
  'list_skills': ChatToolPresenter(
    glyph: ChatToolGlyph.list,
    title: (l10n, activity) => 'Skills()',
    result: (l10n, activity, output) {
      if (output is! ChatToolJsonObject) return genericToolResult(l10n, output);
      final skills = output.value['skills'];
      if (skills is! List || skills.isEmpty) return l10n.toolNoMatches;
      return output.value['nextCursor'] != null
          ? l10n.toolSkillsTruncated(skills.length)
          : l10n.toolSkills(skills.length);
    },
    isFailure: toolHasErrorKey,
  ),
  'skill': ChatToolPresenter(
    glyph: ChatToolGlyph.read,
    title: (l10n, activity) {
      final name = stringToolArg(activity, 'name') ?? '?';
      final resource = stringToolArg(activity, 'resource');
      // The bundled file matters as much as the skill when one is named.
      return resource == null || resource.isEmpty
          ? 'Skill($name)'
          : 'Skill($name:${truncateToolText(resource, 40)})';
    },
    result: (l10n, activity, output) {
      if (output is! ChatToolJsonObject) return genericToolResult(l10n, output);
      final error = output.value['error'];
      if (error is String) return error;
      final name = output.value['name'];
      return name is String
          ? l10n.toolSkillLoaded(name)
          : genericToolResult(l10n, output);
    },
    body: (activity, output) {
      if (output is! ChatToolJsonObject) return plainToolBody(activity, output);
      final text = output.value['instructions'] ?? output.value['content'];
      return text is String && text.isNotEmpty
          ? ChatToolTextBody(text)
          : const ChatToolEmptyBody();
    },
    isFailure: toolHasErrorKey,
  ),
};
