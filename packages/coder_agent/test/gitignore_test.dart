@Tags(<String>['feature_test__tool_search__unit'])
library;

import 'package:coder_agent/coder_agent.dart';
import 'package:file/file.dart' as file_api;
import 'package:file/memory.dart';
import 'package:test/test.dart';

void main() {
  bool ignores(String patterns, String path, {bool isDirectory = false}) =>
      GitignoreMatcher(<GitignoreSource>[
        GitignoreSource.parse('', patterns),
      ]).isIgnored(path, isDirectory: isDirectory);

  group('parsing', () {
    test('blank lines and comments carry no pattern', () {
      expect(GitignorePattern.parse(''), isNull);
      expect(GitignorePattern.parse('   '), isNull);
      expect(GitignorePattern.parse('# a comment'), isNull);
      // Only a leading backslash rescues a literal hash.
      expect(ignores(r'\#notes', '#notes'), isTrue);
    });

    test('trailing whitespace is dropped unless escaped', () {
      expect(ignores('notes.txt   ', 'notes.txt'), isTrue);
      expect(ignores(r'notes\ ', 'notes '), isTrue);
      expect(ignores(r'notes\ ', 'notes'), isFalse);
    });

    test('a leading bang negates, and can itself be escaped', () {
      expect(ignores('*.log\n!keep.log', 'keep.log'), isFalse);
      expect(ignores('*.log\n!keep.log', 'drop.log'), isTrue);
      expect(ignores(r'\!literal', '!literal'), isTrue);
    });

    test('a trailing slash matches only directories', () {
      expect(ignores('build/', 'build', isDirectory: true), isTrue);
      // A file that happens to share the name is not ignored.
      expect(ignores('build/', 'build'), isFalse);
    });

    test('a slash anchors the pattern to the gitignore directory', () {
      expect(ignores('/lib', 'lib'), isTrue);
      expect(ignores('/lib', 'packages/lib'), isFalse);
      // Without a slash the pattern floats to any depth.
      expect(ignores('lib', 'packages/lib'), isTrue);
      // An interior slash anchors just as a leading one does.
      expect(ignores('doc/api', 'doc/api'), isTrue);
      expect(ignores('doc/api', 'packages/doc/api'), isFalse);
    });

    test('a star stops at a separator and a question mark takes one', () {
      expect(ignores('*.dart', 'main.dart'), isTrue);
      expect(ignores('a/*.dart', 'a/b/main.dart'), isFalse);
      expect(ignores('?.dart', 'a.dart'), isTrue);
      expect(ignores('?.dart', 'ab.dart'), isFalse);
    });

    test('a double star crosses separators', () {
      expect(ignores('**/gen', 'a/b/gen'), isTrue);
      expect(ignores('a/**/b', 'a/b'), isTrue);
      expect(ignores('a/**/b', 'a/x/y/b'), isTrue);
      expect(ignores('a/**', 'a/x/y'), isTrue);
      expect(ignores('a/**', 'a'), isFalse);
    });

    test('character classes match, and never cross a separator', () {
      expect(ignores('[a-c].dart', 'b.dart'), isTrue);
      expect(ignores('[a-c].dart', 'd.dart'), isFalse);
      expect(ignores('[!a-c].dart', 'd.dart'), isTrue);
      expect(ignores('[!a-c].dart', 'b.dart'), isFalse);
      // A negated class must not swallow the separator and match across it.
      expect(ignores('a[!x]c', 'a/c'), isFalse);
    });

    test('a backslash makes the next character literal', () {
      expect(ignores(r'a\*b', 'a*b'), isTrue);
      expect(ignores(r'a\*b', 'axb'), isFalse);
    });
  });

  group('precedence', () {
    test('within one file the last matching pattern wins', () {
      expect(ignores('*.log\n!keep.log\nkeep.log', 'keep.log'), isTrue);
      expect(ignores('keep.log\n*.log\n!keep.log', 'keep.log'), isFalse);
    });

    test('a deeper source overrides a shallower one', () {
      final matcher = GitignoreMatcher(<GitignoreSource>[
        GitignoreSource.parse('', '*.log'),
        GitignoreSource.parse('packages/app', '!debug.log'),
      ]);

      expect(matcher.isIgnored('a.log', isDirectory: false), isTrue);
      expect(
        matcher.isIgnored('packages/app/debug.log', isDirectory: false),
        isFalse,
      );
    });

    test('a source says nothing about paths outside its directory', () {
      final matcher = GitignoreMatcher(<GitignoreSource>[
        GitignoreSource.parse('packages/app', '*.log'),
      ]);

      expect(
        matcher.isIgnored('packages/app/a.log', isDirectory: false),
        isTrue,
      );
      expect(
        matcher.isIgnored('packages/other/a.log', isDirectory: false),
        isFalse,
      );
    });
  });

  group('loader', () {
    late file_api.FileSystem fileSystem;

    setUp(() {
      fileSystem = MemoryFileSystem.test();
      fileSystem.directory('/workspace/.git/info').createSync(recursive: true);
      fileSystem.directory('/home/dev/.config/git').createSync(recursive: true);
    });

    GitignoreLoader loader({Map<String, String>? environment}) =>
        GitignoreLoader(
          fileSystem: fileSystem,
          environment: GitignoreEnvironment.fromEnvironment(
            environment ?? <String, String>{'HOME': '/home/dev'},
          ),
        );

    test('info/exclude applies to the whole workspace', () {
      fileSystem
          .file('/workspace/.git/info/exclude')
          .writeAsStringSync('scratch/\n');

      final matcher = loader().baseMatcher('/workspace');

      expect(matcher.isIgnored('scratch', isDirectory: true), isTrue);
    });

    test('the default global ignore file is found under the home config', () {
      fileSystem
          .file('/home/dev/.config/git/ignore')
          .writeAsStringSync('*.swp\n');

      final matcher = loader().baseMatcher('/workspace');

      expect(matcher.isIgnored('a.swp', isDirectory: false), isTrue);
    });

    test('XDG_CONFIG_HOME wins over the home config default', () {
      fileSystem.directory('/xdg/git').createSync(recursive: true);
      fileSystem.file('/xdg/git/ignore').writeAsStringSync('*.tmp\n');
      fileSystem
          .file('/home/dev/.config/git/ignore')
          .writeAsStringSync('*.swp\n');

      final matcher = loader(
        environment: <String, String>{
          'HOME': '/home/dev',
          'XDG_CONFIG_HOME': '/xdg',
        },
      ).baseMatcher('/workspace');

      expect(matcher.isIgnored('a.tmp', isDirectory: false), isTrue);
      expect(matcher.isIgnored('a.swp', isDirectory: false), isFalse);
    });

    test('core.excludesFile overrides the default, and expands ~', () {
      fileSystem
          .file('/home/dev/.gitconfig')
          .writeAsStringSync('[core]\n\texcludesfile = ~/mine\n');
      fileSystem.file('/home/dev/mine').writeAsStringSync('*.bak\n');
      fileSystem
          .file('/home/dev/.config/git/ignore')
          .writeAsStringSync('*.swp\n');

      final matcher = loader().baseMatcher('/workspace');

      expect(matcher.isIgnored('a.bak', isDirectory: false), isTrue);
      expect(matcher.isIgnored('a.swp', isDirectory: false), isFalse);
    });

    test('the repository config outranks the user config', () {
      fileSystem
          .file('/home/dev/.gitconfig')
          .writeAsStringSync('[core]\n\texcludesfile = /home/dev/user\n');
      fileSystem
          .file('/workspace/.git/config')
          .writeAsStringSync('[core]\n\texcludesfile = /home/dev/repo\n');
      fileSystem.file('/home/dev/user').writeAsStringSync('*.user\n');
      fileSystem.file('/home/dev/repo').writeAsStringSync('*.repo\n');

      final matcher = loader().baseMatcher('/workspace');

      expect(matcher.isIgnored('a.repo', isDirectory: false), isTrue);
      expect(matcher.isIgnored('a.user', isDirectory: false), isFalse);
    });

    test('keys outside the core section are not read as excludesFile', () {
      fileSystem
          .file('/home/dev/.gitconfig')
          .writeAsStringSync('[user]\n\texcludesfile = /home/dev/wrong\n');
      fileSystem.file('/home/dev/wrong').writeAsStringSync('*.bak\n');

      final matcher = loader().baseMatcher('/workspace');

      expect(matcher.isIgnored('a.bak', isDirectory: false), isFalse);
    });

    test('a missing global file and a missing exclude ignore nothing', () {
      final matcher = loader(
        environment: const <String, String>{},
      ).baseMatcher('/workspace');

      expect(matcher.isIgnored('anything', isDirectory: false), isFalse);
    });

    test('a directory gitignore is scoped to that directory', () {
      fileSystem.directory('/workspace/app').createSync(recursive: true);
      fileSystem.file('/workspace/app/.gitignore').writeAsStringSync('*.log\n');

      final source = loader().sourceForDirectory('/workspace/app', 'app');

      expect(source, isNotNull);
      expect(source!.basePath, 'app');
      expect(
        GitignoreMatcher(<GitignoreSource>[source]).isIgnored(
          'app/a.log',
          isDirectory: false,
        ),
        isTrue,
      );
      expect(
        GitignoreMatcher(<GitignoreSource>[source]).isIgnored(
          'other/a.log',
          isDirectory: false,
        ),
        isFalse,
      );
    });

    test('a directory without a gitignore yields no source', () {
      expect(loader().sourceForDirectory('/workspace', ''), isNull);
    });
  });
}
