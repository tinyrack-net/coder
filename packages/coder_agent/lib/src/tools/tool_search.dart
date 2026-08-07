import 'dart:convert';
import 'dart:math' as math;

import 'package:coder_agent/src/model.dart';
import 'package:coder_agent/src/tools.dart';
import 'package:coder_protocol/coder_protocol.dart';

/// Whether a tool is advertised to the model up front or found by searching.
enum ToolExposure {
  /// Sent in the model's tool list on every request.
  advertised,

  /// Withheld from the tool list until [ToolSearchTool] surfaces it.
  ///
  /// A deferred tool stays dispatchable the whole time: withholding changes
  /// only what the model is told about, never what it is allowed to call.
  deferred,
}

/// Name of the tool that searches withheld tools.
const String toolSearchToolName = 'tool_search';

/// How many tools one search returns when the model does not say.
const int defaultToolSearchLimit = 8;

/// Most tools one search may return.
const int maxToolSearchLimit = 25;

/// Deepest a schema is walked when building a search document.
const int maxToolSearchDepth = 8;

/// Most terms one tool contributes to the index.
///
/// A server with a pathological schema would otherwise dominate every query
/// and inflate the index without bound.
const int maxToolSearchTerms = 2000;

const Set<String> _stopwords = <String>{
  'a',
  'an',
  'and',
  'are',
  'as',
  'at',
  'be',
  'but',
  'by',
  'for',
  'from',
  'in',
  'into',
  'is',
  'it',
  'of',
  'on',
  'or',
  'that',
  'the',
  'this',
  'to',
  'with',
};

/// Splits [text] into the terms the index and queries share.
///
/// Separators and camelCase boundaries both split, so `create_pull_request`
/// and `createPullRequest` reduce to the same terms a prose query uses.
/// Deliberately unstemmed: tool names are not prose, and an English-only
/// stemmer would mangle identifiers for no gain.
List<String> tokenizeToolSearch(String text) {
  final terms = <String>[];
  final buffer = StringBuffer();

  void flush() {
    if (buffer.isEmpty) return;
    final term = buffer.toString().toLowerCase();
    buffer.clear();
    if (term.length < 2 || _stopwords.contains(term)) return;
    terms.add(term);
  }

  for (var index = 0; index < text.length; index += 1) {
    final rune = text.codeUnitAt(index);
    final isUpper = rune >= 0x41 && rune <= 0x5A;
    final isLower = rune >= 0x61 && rune <= 0x7A;
    final isDigit = rune >= 0x30 && rune <= 0x39;
    if (!isUpper && !isLower && !isDigit) {
      flush();
      continue;
    }
    // A capital after a lowercase starts a new word: `pullRequest`.
    if (isUpper && buffer.isNotEmpty) {
      final previous = buffer.toString().codeUnitAt(buffer.length - 1);
      if (previous >= 0x61 && previous <= 0x7A) flush();
    }
    buffer.writeCharCode(rune);
  }
  flush();
  return terms;
}

/// Builds the searchable terms for one tool.
///
/// Covers the name, its description, and every property name and description
/// in its schema, so a query can match on an argument the tool takes rather
/// than only on how it was named.
List<String> buildToolSearchDocument(AgentTool tool) {
  final terms = <String>[
    ...tokenizeToolSearch(tool.name),
    ...tokenizeToolSearch(tool.description),
  ];

  void walk(Object? node, int depth) {
    if (depth > maxToolSearchDepth || terms.length >= maxToolSearchTerms) {
      return;
    }
    if (node is List) {
      for (final item in node) {
        walk(item, depth + 1);
      }
      return;
    }
    if (node is! Map) return;
    final description = node['description'];
    if (description is String) terms.addAll(tokenizeToolSearch(description));
    final properties = node['properties'];
    if (properties is Map) {
      for (final entry in properties.entries) {
        if (terms.length >= maxToolSearchTerms) break;
        terms.addAll(tokenizeToolSearch('${entry.key}'));
        walk(entry.value, depth + 1);
      }
    }
    for (final key in const <String>['items', 'anyOf', 'oneOf']) {
      walk(node[key], depth + 1);
    }
  }

  walk(tool.strictJsonSchema, 0);
  return terms.length > maxToolSearchTerms
      ? terms.sublist(0, maxToolSearchTerms)
      : terms;
}

/// Ranks withheld tools against a query using BM25.
///
/// Written here rather than pulled in: the corpus is a handful of tool
/// descriptions, the scoring is thirty lines, and a dependency would add a
/// tokenizer whose behaviour we would then have to pin anyway.
final class ToolSearchIndex {
  /// Builds an index over [tools].
  ToolSearchIndex(List<AgentTool> tools)
    : _tools = List<AgentTool>.unmodifiable(tools) {
    var totalLength = 0;
    for (final tool in _tools) {
      final terms = buildToolSearchDocument(tool);
      final frequencies = <String, int>{};
      for (final term in terms) {
        frequencies[term] = (frequencies[term] ?? 0) + 1;
      }
      _frequencies.add(frequencies);
      _lengths.add(terms.length);
      totalLength += terms.length;
      for (final term in frequencies.keys) {
        _documentCounts[term] = (_documentCounts[term] ?? 0) + 1;
      }
    }
    _averageLength = _tools.isEmpty ? 0 : totalLength / _tools.length;
  }

  static const double _k1 = 1.2;
  static const double _b = 0.75;

  final List<AgentTool> _tools;
  final List<Map<String, int>> _frequencies = <Map<String, int>>[];
  final List<int> _lengths = <int>[];
  final Map<String, int> _documentCounts = <String, int>{};
  late final double _averageLength;

  /// The tools this index covers.
  List<AgentTool> get tools => _tools;

  /// Returns the best [limit] matches for [query], most relevant first.
  ///
  /// Ties break on tool name so the order is identical across runs; test
  /// ordering is randomized and a wobbling rank would fail the gate.
  List<AgentTool> search(String query, {required int limit}) {
    final terms = tokenizeToolSearch(query);
    if (terms.isEmpty || _tools.isEmpty || limit <= 0) {
      return const <AgentTool>[];
    }

    final scored = <({AgentTool tool, double score})>[];
    for (var index = 0; index < _tools.length; index += 1) {
      var score = 0.0;
      for (final term in terms) {
        final frequency = _frequencies[index][term];
        if (frequency == null) continue;
        final documents = _documentCounts[term] ?? 0;
        final idf = math.log(
          1 + (_tools.length - documents + 0.5) / (documents + 0.5),
        );
        final normalized = _averageLength == 0
            ? 0.0
            : _lengths[index] / _averageLength;
        score +=
            idf *
            (frequency * (_k1 + 1)) /
            (frequency + _k1 * (1 - _b + _b * normalized));
      }
      if (score > 0) scored.add((tool: _tools[index], score: score));
    }
    scored.sort((left, right) {
      final byScore = right.score.compareTo(left.score);
      return byScore != 0 ? byScore : left.tool.name.compareTo(right.tool.name);
    });
    return <AgentTool>[
      for (final entry in scored.take(limit)) entry.tool,
    ];
  }
}

/// Finds tools that were withheld from the model's tool list.
///
/// The runner owns this tool: it holds both the registry and the advertised
/// list, so nothing outside has to know the tool exists — and when nothing is
/// deferred, it is never built and never advertised.
class ToolSearchTool extends AgentTool {
  /// Creates a [ToolSearchTool] over [deferred].
  factory ToolSearchTool({
    required List<AgentTool> deferred,
    required void Function(Iterable<String> names) onSurfaced,
  }) => ToolSearchTool._(ToolSearchIndex(deferred), onSurfaced);

  ToolSearchTool._(this._index, this._onSurfaced);

  final ToolSearchIndex _index;
  final void Function(Iterable<String> names) _onSurfaced;

  @override
  String get name => toolSearchToolName;

  @override
  String get description =>
      'Search the tools that were not loaded up front and make the matches '
      'callable. ${_index.tools.length} tools are available this way — search '
      'before assuming a capability is missing.';

  @override
  ToolRisk get risk => ToolRisk.read;

  @override
  Map<String, dynamic> get strictJsonSchema =>
      strictToolObject(<String, Map<String, dynamic>>{
        'query': <String, dynamic>{
          'type': 'string',
          'description':
              'What you want to do, in prose or keywords, for example '
              '"open a pull request".',
        },
        'limit': <String, dynamic>{
          'type': <String>['integer', 'null'],
          'description':
              'How many tools to return. Null uses $defaultToolSearchLimit; '
              'values are clamped to 1…$maxToolSearchLimit.',
        },
      });

  @override
  Future<ToolResult> execute(
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async {
    final query = arguments['query'];
    if (query is! String || query.trim().isEmpty) {
      return ToolResult(
        output: jsonEncode(<String, dynamic>{
          'error': 'query must be a non-empty string.',
        }),
        isError: true,
      );
    }
    final rawLimit = arguments['limit'];
    final limit = rawLimit is int
        ? rawLimit.clamp(1, maxToolSearchLimit)
        : defaultToolSearchLimit;
    final found = _index.search(query, limit: limit);
    _onSurfaced(found.map((tool) => tool.name));
    return ToolResult(
      output: truncateToolOutput(
        jsonEncode(<String, dynamic>{
          'tools': <Map<String, dynamic>>[
            for (final tool in found)
              <String, dynamic>{
                'name': tool.name,
                'description': tool.description,
                'parameters': tool.strictJsonSchema,
              },
          ],
          'remaining': _index.tools.length - found.length,
        }),
      ),
    );
  }
}
