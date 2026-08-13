import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Keys declared more than once in [source], in file order.
///
/// `jsonDecode` keeps the last of a repeated key and reports nothing, so a
/// duplicate silently replaces a string that is still in use. Counting the
/// declarations in the text is the only way to see it.
List<String> _duplicateKeys(String source) {
  final declaration = RegExp(r'^\s{2}"(@?[A-Za-z0-9_]+)"\s*:', multiLine: true);
  final seen = <String>{};
  final duplicates = <String>[];
  for (final match in declaration.allMatches(source)) {
    final key = match.group(1)!;
    if (!seen.add(key)) duplicates.add(key);
  }
  return duplicates;
}

/// The message keys in [source], without the `@`-prefixed metadata entries.
///
/// Only the template carries `@key` descriptions, so comparing raw maps would
/// report every description as an extra key in the translations.
Set<String> _messageKeys(String source) {
  final decoded = jsonDecode(source) as Map<String, dynamic>;
  return decoded.keys.where((key) => !key.startsWith('@')).toSet();
}

const _settingsTermsByLocale = <String, Map<String, String>>{
  'app_ja.arb': {
    'settingsSectionApp': 'アプリ',
    'settingsSectionDaemon': 'デーモン',
    'settingsDaemonSelectLabel': 'デーモン',
    'settingsCategoryGeneral': '一般',
    'settingsCategoryProjects': 'プロジェクト',
    'settingsCategoryAgent': 'エージェント',
    'settingsCategoryProvider': 'プロバイダー',
    'settingsCategoryDaemon': 'デーモン',
    'projectSettingsHeading': 'プロジェクト',
    'agentSettingsHeading': 'エージェント',
    'appSettingsRemoteDetails': 'デーモン',
    'relayConfirmDaemon': 'デーモン ID',
    'relayPathRelay': 'リレー',
  },
  'app_ko.arb': {
    'settingsSectionApp': '앱',
    'settingsSectionDaemon': '데몬',
    'settingsDaemonSelectLabel': '데몬',
    'settingsCategoryGeneral': '일반',
    'settingsCategoryProjects': '프로젝트',
    'settingsCategoryAgent': '에이전트',
    'settingsCategoryProvider': '프로바이더',
    'settingsCategoryDaemon': '데몬',
    'projectSettingsHeading': '프로젝트',
    'projectSettingsCount': '프로젝트 {count}개',
    'agentSettingsHeading': '에이전트',
    'agentSettingsCount': '정의 {count}개',
    'agentSettingsModelId': '모델 ID',
    'agentSettingsOverwrite': '덮어쓰기',
    'agentSettingsReload': '다시 불러오기',
    'appSettingsBearerToken': 'Bearer 토큰',
    'appSettingsRemoteDetails': '데몬',
    'providerSettingsBaseUrl': '기본 URL',
    'relayConfirmDaemon': '데몬 ID',
    'relayPathRelay': '릴레이',
  },
};

void main() {
  final arbFiles = Directory('lib/l10n')
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.arb'))
      .toList();

  // The template names every string the app can show. A translation that is
  // merely missing a key does not fail the build: `gen_l10n` falls back to
  // English, so the gap only ever shows up in front of a user who does not
  // read English. Comparing key sets is what turns that into a build failure.
  const templateName = 'app_en.arb';
  final templateKeys = _messageKeys(
    File('lib/l10n/$templateName').readAsStringSync(),
  );

  test('$templateName is the template and declares messages', () {
    expect(templateKeys, isNotEmpty);
  });

  test('there are localization files to check', () {
    expect(arbFiles, isNotEmpty);
  });

  for (final file in arbFiles) {
    final name = file.path.split(RegExp(r'[/\\]')).last;

    test('$name declares every key once', () {
      expect(
        _duplicateKeys(file.readAsStringSync()),
        isEmpty,
        reason:
            'a repeated key overwrites the earlier one, so whichever surface '
            'used it silently starts showing the other string',
      );
    });

    test('$name parses as a flat map of strings', () {
      final decoded = jsonDecode(file.readAsStringSync());
      expect(decoded, isA<Map<String, dynamic>>());
    });

    final expectedSettingsTerms = _settingsTermsByLocale[name];
    if (expectedSettingsTerms != null) {
      test('$name localizes core Settings terms consistently', () {
        final table =
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        expect(
          <String, String>{
            for (final key in expectedSettingsTerms.keys)
              key: table[key]! as String,
          },
          expectedSettingsTerms,
          reason:
              'Settings navigation and pane chrome must not switch back to '
              'English within a localized flow.',
        );
      });
    }

    if (name == templateName) continue;

    test('$name translates every message the template declares', () {
      final keys = _messageKeys(file.readAsStringSync());
      final missing = templateKeys.difference(keys).toList()..sort();
      final unknown = keys.difference(templateKeys).toList()..sort();

      expect(
        missing,
        isEmpty,
        reason:
            'these keys fall back to English, so a reader of this locale sees '
            'untranslated text with nothing to signal it: '
            '${missing.join(', ')}',
      );
      expect(
        unknown,
        isEmpty,
        reason:
            'these keys are not in $templateName, so nothing reads them and '
            'the translation effort is wasted: ${unknown.join(', ')}',
      );
    });

    test('$name carries prose in its own script', () {
      // Key parity alone would pass if someone pasted the English value in to
      // fill the slot. Prose in a CJK locale has to contain CJK characters, so
      // requiring that on the long messages catches an untranslated paste
      // while leaving short labels that are genuinely shared alone -- 'OK',
      // 'MCP', 'URL', and the slash-command names the user types.
      final cjk = RegExp('[぀-ヿ㐀-鿿가-힯]');
      final table = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final template = jsonDecode(
        File('lib/l10n/$templateName').readAsStringSync(),
      ) as Map<String, dynamic>;
      final untranslated = <String>[
        for (final key in templateKeys)
          if (table[key] == template[key] &&
              (template[key]! as String).length > 24 &&
              !cjk.hasMatch(table[key]! as String))
            key,
      ]..sort();

      expect(
        untranslated,
        isEmpty,
        reason:
            'these long messages are byte-identical to the English template '
            'and contain no ${name.contains('ja') ? 'Japanese' : 'Korean'} '
            'characters, so they read as untranslated: '
            '${untranslated.join(', ')}',
      );
    });
  }
}
