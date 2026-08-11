import 'package:app/l10n/gen/app_localizations.dart';
import 'package:app/src/features/conversation/presentation/tools/presenter.dart';

/// How the MCP resource tools appear in the chat timeline.
final Map<String, ChatToolPresenter>
mcpResourcesPresenters = <String, ChatToolPresenter>{
  'list_mcp_resources': ChatToolPresenter(
    glyph: ChatToolGlyph.resource,
    title: (l10n, activity) => l10n.toolTitleMcpResources(
      stringToolArg(activity, 'server') ?? l10n.toolArgumentAllServers,
    ),
    result: (l10n, activity, output) => _mcpListResult(
      l10n,
      output,
      'resources',
      l10n.toolMcpResources,
    ),
    isFailure: toolHasErrorKey,
  ),
  'list_mcp_resource_templates': ChatToolPresenter(
    glyph: ChatToolGlyph.resource,
    title: (l10n, activity) => l10n.toolTitleMcpResourceTemplates(
      stringToolArg(activity, 'server') ?? l10n.toolArgumentAllServers,
    ),
    result: (l10n, activity, output) => _mcpListResult(
      l10n,
      output,
      'resourceTemplates',
      l10n.toolMcpResourceTemplates,
    ),
    isFailure: toolHasErrorKey,
  ),
  'read_mcp_resource': ChatToolPresenter(
    glyph: ChatToolGlyph.resource,
    title: (l10n, activity) {
      final server = stringToolArg(activity, 'server') ?? '?';
      final uri = truncateToolText(stringToolArg(activity, 'uri') ?? '?', 48);
      return l10n.toolTitleMcpResource(server, uri);
    },
    result: (l10n, activity, output) {
      if (output is! ChatToolJsonObject) return genericToolResult(l10n, output);
      final error = output.value['error'];
      if (error is String) return error;
      final contents = output.value['contents'];
      final blocks = contents is List ? contents.length : 0;
      return l10n.toolMcpResourceRead(blocks);
    },
    body: (activity, output) {
      // Text contents are what the user actually wants to inspect.
      if (output is! ChatToolJsonObject) return plainToolBody(activity, output);
      final contents = output.value['contents'];
      if (contents is! List) return plainToolBody(activity, output);
      final text = contents
          .whereType<Map<dynamic, dynamic>>()
          .map((block) => block['text'])
          .whereType<String>()
          .join('\n');
      return text.isEmpty
          ? plainToolBody(activity, output)
          : ChatToolTextBody(text);
    },
    isFailure: toolHasErrorKey,
  ),
};

/// Summarizes an MCP listing, noting when a page was truncated.
String _mcpListResult(
  AppLocalizations l10n,
  ChatToolOutput output,
  String key,
  String Function(int count) label,
) {
  if (output is! ChatToolJsonObject) return genericToolResult(l10n, output);
  final error = output.value['error'];
  if (error is String) return error;
  final entries = output.value[key];
  final count = entries is List ? entries.length : 0;
  final summary = label(count);
  return output.value['truncated'] == true ? '$summary…' : summary;
}
