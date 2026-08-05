import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('production UI uses Tinyrack components and Lucide icons', () {
    final sourceDirectory = Directory('lib/src');
    final forbidden = <RegExp, String>{
      RegExp(r'\bIcons\.'): 'Material icon; use CoderIcons',
      RegExp(r'\bCupertinoIcons\.'): 'Cupertino icon; use CoderIcons',
      // Every glyph goes through the semantic map, so a screen never names a
      // Lucide constant and the app has one place to retheme.
      RegExp(r'\bLucideIcons\.'): 'raw Lucide glyph; use CoderIcons',
      RegExp(r'\bIconData\('): 'icon code point literal; use CoderIcons',
      RegExp(r'\bImageIcon\b'): 'bitmap icon; use CoderIcons',
      // The theme sizes icons from a token. A literal here is either redundant
      // or an off-scale glyph.
      RegExp(r'size: \d'): 'icon size literal; use a Tinyrack measurement',
      RegExp(
        r'\b(?:Scaffold|AppBar|ListTile|TextField|TextFormField|IconButton|'
        'TextButton|FilledButton|OutlinedButton|ElevatedButton|Card|Dialog|'
        'AlertDialog|SimpleDialog|Divider|CircularProgressIndicator|'
        'DropdownButton|DropdownButtonFormField|PopupMenuButton|PopupMenuItem|'
        'Checkbox|Switch|Radio|SegmentedButton|Tooltip|ActionChip|ChoiceChip|'
        'FilterChip|InputChip|ExpansionTile|LinearProgressIndicator|'
        'FloatingActionButton|BottomNavigationBar|NavigationRail|Drawer|'
        'TabBar|Material|InkWell|InkResponse|VerticalDivider|Scrollbar|'
        r'SelectableText)(?:\.|\s*\()',
      ): 'direct Material component',
      RegExp(
        r'\b(?:showAboutDialog|showDialog|showModalBottomSheet|showMenu)\s*<?',
      ): 'direct Material overlay',
      RegExp(r'\b(?:ScaffoldMessenger|SnackBar)(?:\.|\s*\()'):
          'direct Material transient feedback',
    };
    // The semantic icon map is where raw Lucide glyphs are allowed to appear;
    // naming them anywhere else is what the rule above forbids.
    final exempt = <String, Set<String>>{
      'lib/src/coder_icons.dart': {'raw Lucide glyph; use CoderIcons'},
    };
    final violations = <String>[];

    for (final entity in sourceDirectory.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = entity.readAsStringSync();
      final allowed = exempt[entity.path] ?? const <String>{};
      for (final entry in forbidden.entries) {
        if (allowed.contains(entry.value)) continue;
        for (final match in entry.key.allMatches(source)) {
          final line =
              '\n'.allMatches(source.substring(0, match.start)).length + 1;
          violations.add('${entity.path}:$line: ${entry.value}');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Use tinyrack_ui components and LucideIcons instead:\n'
          '${violations.join('\n')}',
    );
  });
}
