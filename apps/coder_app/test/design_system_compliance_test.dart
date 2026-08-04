import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('production UI uses Tinyrack components and Lucide icons', () {
    final sourceDirectory = Directory('lib/src');
    final forbidden = <RegExp, String>{
      RegExp(r'\bIcons\.'): 'Material icon',
      RegExp(
        r'\b(?:Scaffold|AppBar|ListTile|TextField|TextFormField|IconButton|'
        'TextButton|FilledButton|OutlinedButton|ElevatedButton|Card|Dialog|'
        'AlertDialog|SimpleDialog|Divider|CircularProgressIndicator|'
        'DropdownButton|DropdownButtonFormField|PopupMenuButton|PopupMenuItem|'
        'Checkbox|Switch|Radio|SegmentedButton|Tooltip|ActionChip|ChoiceChip|'
        'FilterChip|InputChip|ExpansionTile|LinearProgressIndicator|'
        'FloatingActionButton|BottomNavigationBar|NavigationRail|Drawer|'
        r'TabBar|Material|InkWell|InkResponse)(?:\.|\s*\()',
      ): 'direct Material component',
      RegExp(
        r'\b(?:showAboutDialog|showDialog|showModalBottomSheet|showMenu)\s*<?',
      ): 'direct Material overlay',
      RegExp(r'\b(?:ScaffoldMessenger|SnackBar)(?:\.|\s*\()'):
          'direct Material transient feedback',
    };
    final violations = <String>[];

    for (final entity in sourceDirectory.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = entity.readAsStringSync();
      for (final entry in forbidden.entries) {
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
