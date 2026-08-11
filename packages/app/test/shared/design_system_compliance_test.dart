import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The scanned path as a key the exemption table can be written in.
///
/// Windows reports a backslash separator, so an exemption spelled with forward
/// slashes would silently never match there.
String scannedPathKey(String path) => path.replaceAll(r'\', '/');

void main() {
  test('production UI uses Tinyrack components and Lucide icons', () {
    final sourceDirectory = Directory('lib/src');
    final forbidden = <RegExp, String>{
      RegExp(r'\bIcons\.'): 'Material icon; use TinestIcons',
      RegExp(r'\bCupertinoIcons\.'): 'Cupertino icon; use TinestIcons',
      // Every glyph goes through the semantic map, so a screen never names a
      // Lucide constant and the app has one place to retheme.
      RegExp(r'\bLucideIcons\.'): 'raw Lucide glyph; use TinestIcons',
      RegExp(r'\bIconData\('): 'icon code point literal; use TinestIcons',
      RegExp(r'\bImageIcon\b'): 'bitmap icon; use TinestIcons',
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
      // Design values, which must name a token rather than a measurement
      // someone picked by eye.
      RegExp(r'\bColor\(0x'): 'color literal; use a Tinyrack color token',
      RegExp(r'\bColors\.(?!transparent\b)\w'):
          'Material palette color; use a Tinyrack color token',
      RegExp(r'\bBorderRadius\.circular\(\s*[\d.]'):
          'radius literal; use TRRadii',
      RegExp(r'\bEdgeInsets\.\w+\(\s*[\d.]'): 'inset literal; use TRSpacing',
      // Only a gap, which is spacing. A `SizedBox` that also takes a child is
      // sizing that child, which is product layout rather than a design value,
      // as are `ConstrainedBox` and `LayoutBuilder` bounds.
      RegExp(r'\bSizedBox\((?:width|height): [\d.]+\s*\)'):
          'gap literal; use TRSpacing',
      RegExp(r'\bTheme\.of\(context\)\.(?:colorScheme|textTheme)\b'):
          'Material theme read; use context.tinyrackTheme or TRTypography',
      // A text trigger carries inline padding on both sides, so a glyph in one
      // renders as a wide pill beside the square TRIconButtons it sits with.
      RegExp(r'trigger: (?:const )?Icon\('):
          'icon in a text menu trigger; use TRMenu.icon',
    };
    // The semantic icon map is where raw Lucide glyphs are allowed to appear;
    // naming them anywhere else is what the rule above forbids.
    final exempt = <String, Set<String>>{
      'lib/src/shared/presentation/tinest_icons.dart': {
        'raw Lucide glyph; use TinestIcons',
      },
    };
    final violations = <String>[];

    for (final entity in sourceDirectory.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = entity.readAsStringSync();
      final allowed = exempt[scannedPathKey(entity.path)] ?? const <String>{};
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

  test('exemptions match on every platform separator', () {
    expect(
      scannedPathKey(r'lib\src\shared\presentation\tinest_icons.dart'),
      'lib/src/shared/presentation/tinest_icons.dart',
    );
    expect(
      scannedPathKey('lib/src/shared/presentation/tinest_icons.dart'),
      'lib/src/shared/presentation/tinest_icons.dart',
    );
  });
}
