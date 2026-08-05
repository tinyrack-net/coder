import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:coder_app/src/app.dart';
import 'package:coder_app/src/host_models.dart';
import 'package:coder_app/src/host_ports.dart';
import 'package:coder_app/src/model_picker.dart';
import 'package:coder_app/src/session_composer.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinyrack_ui/tinyrack_ui.dart';

import '../support/fake_coder_api.dart';
import '../support/fake_desktop_ports.dart';
import '../support/localization.dart';

void main() {
  unawaited(
    goldenTest(
      'desktop title bar file menu is open',
      fileName: 'desktop_file_menu_open',
      constraints: const BoxConstraints.tightFor(width: 1000, height: 620),
      pumpBeforeTest: (tester) async {
        await tester.pumpAndSettle();
        await tester.tap(find.text('파일'));
        await tester.pumpAndSettle();
      },
      builder: _desktopApp,
    ),
  );

  unawaited(
    goldenTest(
      'desktop about dialog uses the Tinyrack layer',
      fileName: 'desktop_about_dialog',
      constraints: const BoxConstraints.tightFor(width: 1000, height: 620),
      pumpBeforeTest: (tester) async {
        await tester.pumpAndSettle();
        await tester.tap(find.text('도움말'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Tinyrack Coder 정보'));
        await tester.pumpAndSettle();
      },
      builder: _desktopApp,
    ),
  );

  unawaited(
    goldenTest(
      'composer chip menu is open without a tooltip',
      fileName: 'composer_chip_menu_without_tooltip',
      constraints: const BoxConstraints.tightFor(width: 720, height: 480),
      whilePerforming: (tester) async {
        final chip = find.byKey(const ValueKey('golden-project-chip'));
        await tester.tap(chip);
        await tester.pumpAndSettle();
        expect(find.text('프로젝트 선택'), findsNothing);
        expect(find.text('추가'), findsOneWidget);
        return null;
      },
      builder: _composerChipApp,
    ),
  );

  for (final variant in <({String name, Size size, ThemeMode mode})>[
    (
      name: 'desktop_light',
      size: const Size(800, 700),
      mode: ThemeMode.light,
    ),
    (
      name: 'mobile_dark',
      size: const Size(390, 760),
      mode: ThemeMode.dark,
    ),
  ]) {
    unawaited(
      goldenTest(
        'model picker ${variant.name} layer',
        fileName: 'model_picker_${variant.name}',
        constraints: BoxConstraints.tight(variant.size),
        builder: () => _ModelPickerGoldenHost(
          mode: variant.mode,
          size: variant.size,
        ),
      ),
    );
  }
}

Widget _desktopApp() => CoderApp(
  services: fakeAppServices(
    FakeCoderApi(),
    connected: false,
    store: MemoryAppStore(
      settings: const AppSettings(
        embeddedDaemonEnabled: false,
        localeTag: 'ko',
      ),
    ),
  ),
  desktopWindow: FakeDesktopWindow(supportsCustomTitleBar: true),
  trayIcon: FakeTrayIcon(),
  autostart: FakeAutostartRegistration(),
);

Widget _composerChipApp() => MaterialApp(
  debugShowCheckedModeBanner: false,
  locale: testLocale,
  localizationsDelegates: testLocalizationsDelegates,
  supportedLocales: testSupportedLocales,
  theme: testLightTheme,
  darkTheme: testDarkTheme,
  themeMode: ThemeMode.dark,
  home: Scaffold(
    body: Center(
      child: TRTooltipProvider(
        child: ComposerChip(
          valueKey: const ValueKey('golden-project-chip'),
          icon: Icons.folder_outlined,
          label: 'Coder',
          tooltip: '프로젝트 선택',
          menuChildren: <Widget>[
            TRMenuItem(onPressed: () {}, child: const Text('Coder · test')),
            TRMenuItem(onPressed: () {}, child: const Text('추가')),
          ],
        ),
      ),
    ),
  ),
);

class _ModelPickerGoldenHost extends StatelessWidget {
  const _ModelPickerGoldenHost({required this.mode, required this.size});

  final ThemeMode mode;
  final Size size;

  @override
  Widget build(BuildContext context) => SizedBox.fromSize(
    size: size,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: testLocale,
      localizationsDelegates: testLocalizationsDelegates,
      supportedLocales: testSupportedLocales,
      theme: testLightTheme,
      darkTheme: testDarkTheme,
      themeMode: mode,
      home: const TRTooltipProvider(child: _OpenModelPicker()),
    ),
  );
}

class _OpenModelPicker extends StatelessWidget {
  const _OpenModelPicker();

  @override
  Widget build(BuildContext context) {
    const picker = ModelPicker(
      currentSelection: SessionModelSelectionDto(
        providerConnectionId: 'openai',
        modelId: 'gpt-5.6',
      ),
      title: '모델 선택',
      inheritLabel: '프로젝트 설정 사용',
      options: <ModelPickerOption>[
        ModelPickerOption(
          providerName: 'OpenAI',
          model: ProviderModelDto(
            connectionId: 'openai',
            id: 'gpt-5.6',
            label: 'GPT-5.6',
            source: ProviderModelSource.bundled,
            capabilities: ModelCapabilitiesDto(),
          ),
        ),
        ModelPickerOption(
          providerName: 'DeepSeek',
          model: ProviderModelDto(
            connectionId: 'deepseek',
            id: 'gpt-5.6-mini',
            label: 'GPT-5.6 mini',
            source: ProviderModelSource.bundled,
            capabilities: ModelCapabilitiesDto(),
          ),
        ),
      ],
    );
    final isMobile = MediaQuery.sizeOf(context).width < 760;
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: isMobile
          ? Align(
              alignment: Alignment.bottomCenter,
              child: TRDrawer(
                semanticLabel: '모델 선택',
                snapPoints: const <double>[0.8, 1],
                content: const SizedBox(height: 520, child: picker),
              ),
            )
          : const Center(
              child: TRDialog(
                semanticLabel: '모델 선택',
                content: SizedBox(width: 560, height: 600, child: picker),
              ),
            ),
    );
  }
}
