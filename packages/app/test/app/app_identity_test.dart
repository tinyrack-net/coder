import 'dart:convert';
import 'dart:io';

import 'package:app/l10n/gen/app_localizations.dart';
import 'package:app/src/app/app_identity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final packageRoot = Directory.current;
  final workspaceRoot = packageRoot.parent.parent;

  String packageFile(String path) => File(
    '${packageRoot.path}/$path',
  ).readAsStringSync();
  String workspaceFile(String path) => File(
    '${workspaceRoot.path}/$path',
  ).readAsStringSync();

  test('app identity keeps every derived product name coherent', () {
    expect(
      AppIdentity.displayName,
      '${AppIdentity.vendorName} ${AppIdentity.name}',
    );
    expect(AppIdentity.applicationId, 'net.tinyrack.${AppIdentity.slug}');
    expect(AppIdentity.executableName, AppIdentity.slug);
    expect(AppIdentity.cliDisplayName, '${AppIdentity.name} CLI');
    expect(AppIdentity.cliExecutableName, '${AppIdentity.slug}-cli');
    expect(AppIdentity.protocolNamespace, 'tinyrack.${AppIdentity.slug}');
    expect(
      AppIdentity.environmentPrefix,
      'TINYRACK_${AppIdentity.slug.toUpperCase()}',
    );
    expect(AppIdentity.configDirectoryName, 'tinyrack-${AppIdentity.slug}');
    expect(
      AppIdentity.storagePrefix,
      'tinyrack_${AppIdentity.slug.replaceAll('-', '_')}',
    );
    expect(AppIdentity.projectConfigDirectoryName, '.${AppIdentity.slug}');
  });

  test('localized product messages preserve every locale result', () {
    final english = lookupAppLocalizations(const Locale('en'));
    final korean = lookupAppLocalizations(const Locale('ko'));
    final japanese = lookupAppLocalizations(const Locale('ja'));

    expect(english.trayTooltip(AppIdentity.displayName), 'Tinyrack Coder');
    expect(
      english.desktopMenuAbout(AppIdentity.displayName),
      'About Tinyrack Coder',
    );
    expect(korean.trayTooltip(AppIdentity.displayName), 'Tinyrack Coder');
    expect(
      korean.desktopMenuAbout(AppIdentity.displayName),
      'Tinyrack Coder 정보',
    );
    expect(japanese.trayTooltip(AppIdentity.displayName), 'Tinyrack Coder');
    expect(
      japanese.desktopMenuAbout(AppIdentity.displayName),
      'About Tinyrack Coder',
    );
  });

  test('localized messages receive product names through placeholders', () {
    for (final locale in <String>['en', 'ko', 'ja']) {
      final source = packageFile('lib/l10n/app_$locale.arb');
      final messages = jsonDecode(source) as Map<String, dynamic>;
      for (final entry in messages.entries) {
        if (entry.key.startsWith('@') || entry.value is! String) continue;
        expect(
          entry.value,
          isNot(anyOf(contains('Coder'), contains('Tinyrack Coder'))),
          reason:
              '${entry.key} in app_$locale.arb must use an app-name '
              'placeholder',
        );
      }
    }
  });

  test('user-facing Dart strings use app identity constants', () {
    String normalizedPath(String path) => path.replaceAll(r'\', '/');
    final identityPath = normalizedPath(
      '${packageRoot.path}/lib/src/app/app_identity.dart',
    );
    final brandedLiteral = RegExp(
      r'''(['"])(?:Tinyrack Coder|Coder)\1''',
    );
    final offenders = <String>[];
    for (final entity in Directory(
      '${packageRoot.path}/lib/src',
    ).listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final entityPath = normalizedPath(entity.path);
      if (entityPath == identityPath) continue;
      if (brandedLiteral.hasMatch(entity.readAsStringSync())) {
        offenders.add(
          entityPath.substring(normalizedPath(packageRoot.path).length + 1),
        );
      }
    }
    expect(offenders, isEmpty);
  });

  test('Flutter tooling can read the Android application identifiers', () {
    // `flutter test -d <android device>` resolves the launch activity through
    // `AndroidProject.namespace` and `AndroidProject.applicationId`, which scan
    // this file with these regexes rather than evaluating Gradle. A Kotlin
    // `val` therefore reads as absent and the tool refuses to install the app,
    // so both declarations have to stay quoted literals.
    final gradle = packageFile('android/app/build.gradle.kts');
    final namespace = RegExp(
      'android {[\\S\\s]+namespace\\s*=?\\s*[\'"](.+)[\'"]',
    ).firstMatch(gradle)?.group(1);
    final applicationId = RegExp(
      '^\\s*applicationId\\s*=?\\s*[\'"](.*)[\'"]\\s*\$',
      multiLine: true,
    ).firstMatch(gradle)?.group(1);

    expect(namespace, AppIdentity.applicationId);
    expect(applicationId, AppIdentity.applicationId);
  });

  test('platform and distribution metadata agree with app identity', () {
    final expectations = <String, List<String>>{
      'android/app/src/main/res/values/strings.xml': <String>[
        '<string name="app_name">${AppIdentity.name}</string>',
      ],
      'android/app/build.gradle.kts': <String>[
        'namespace = "${AppIdentity.applicationId}"',
        'applicationId = "${AppIdentity.applicationId}"',
      ],
      'ios/Runner/Info.plist': <String>[
        r'<string>$(PRODUCT_NAME)</string>',
        r'<string>$(APP_DISPLAY_NAME) connects to a daemon on your trusted local network.</string>',
      ],
      'ios/Flutter/AppIdentity.xcconfig': <String>[
        'APP_DISPLAY_NAME = ${AppIdentity.displayName}',
        'PRODUCT_NAME = ${AppIdentity.name}',
        'PRODUCT_BUNDLE_IDENTIFIER = ${AppIdentity.applicationId}',
      ],
      'macos/Runner/Configs/AppInfo.xcconfig': <String>[
        'APP_DISPLAY_NAME = ${AppIdentity.displayName}',
        'PRODUCT_NAME = ${AppIdentity.name}',
        'PRODUCT_BUNDLE_IDENTIFIER = ${AppIdentity.applicationId}',
      ],
      'linux/CMakeLists.txt': <String>[
        'set(APP_DISPLAY_NAME "${AppIdentity.name}")',
        'set(BINARY_NAME "${AppIdentity.executableName}")',
        'set(APPLICATION_ID "${AppIdentity.applicationId}")',
      ],
      'windows/CMakeLists.txt': <String>[
        'set(APP_DISPLAY_NAME "${AppIdentity.name}")',
        'set(BINARY_NAME "${AppIdentity.executableName}")',
      ],
      'web/manifest.json': <String>[
        '"name": "${AppIdentity.name}"',
        '"short_name": "${AppIdentity.name}"',
      ],
      'web/index.html': <String>[
        'content="${AppIdentity.name}"',
        '<title>${AppIdentity.name}</title>',
      ],
      'windows/installer/coder.iss': <String>[
        '#define AppName "${AppIdentity.name}"',
        '#define AppExeName "${AppIdentity.executableName}.exe"',
      ],
    };
    for (final entry in expectations.entries) {
      final contents = packageFile(entry.key);
      for (final expected in entry.value) {
        expect(contents, contains(expected), reason: entry.key);
      }
    }

    final shipworld = workspaceFile('shipworld.yaml');
    expect(shipworld, contains('display-name: ${AppIdentity.name}'));
    expect(shipworld, contains('bundle-id: ${AppIdentity.applicationId}'));
    expect(shipworld, contains('launcher: ${AppIdentity.executableName}'));
    expect(shipworld, contains('display-name: ${AppIdentity.cliDisplayName}'));
    expect(
      shipworld,
      contains('launcher: ${AppIdentity.cliExecutableName}'),
    );

    final protocol = workspaceFile('packages/protocol/lib/src/protocol.dart');
    expect(
      protocol,
      contains("'${AppIdentity.protocolNamespace}.v4'"),
    );
    expect(
      protocol,
      contains("'${AppIdentity.protocolNamespace}.token.'"),
    );
    final localHost = workspaceFile('packages/protocol/lib/local_host.dart');
    expect(localHost, contains("'${AppIdentity.configDirectoryName}'"));
    expect(
      localHost,
      contains("'${AppIdentity.environmentPrefix}_HOME'"),
    );
    final daemonConfig = workspaceFile(
      'packages/daemon/lib/src/bootstrap/config.dart',
    );
    expect(
      daemonConfig,
      contains("'${AppIdentity.environmentPrefix}_LISTEN'"),
    );
    expect(
      daemonConfig,
      contains("'${AppIdentity.environmentPrefix}_TOKEN'"),
    );
    final mcpConfig = workspaceFile(
      'packages/daemon/lib/src/features/mcp/infrastructure/mcp_config.dart',
    );
    expect(
      mcpConfig,
      contains("'${AppIdentity.projectConfigDirectoryName}/config.json'"),
    );
    final cliApplication = workspaceFile(
      'packages/cli/lib/src/cli/application.dart',
    );
    expect(
      cliApplication,
      contains("name: '${AppIdentity.cliExecutableName}'"),
    );
    final singleInstance = packageFile(
      'windows/runner/single_instance.cpp',
    );
    expect(
      singleInstance,
      contains('${AppIdentity.configDirectoryName}-single-instance'),
    );
    expect(singleInstance, contains(AppIdentity.environmentPrefix));
    final pipeline = workspaceFile('.github/workflows/pipeline.yml');
    expect(pipeline, contains(AppIdentity.cliExecutableName));
    expect(pipeline, contains(AppIdentity.environmentPrefix));
  });
}
