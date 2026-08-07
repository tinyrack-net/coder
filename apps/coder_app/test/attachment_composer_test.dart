import 'package:coder_app/l10n/gen/app_localizations.dart';
import 'package:coder_app/src/attachment_io.dart';
import 'package:coder_app/src/controller.dart';
import 'package:coder_app/src/session_composer.dart';
import 'package:coder_protocol/coder_protocol.dart';
import 'package:dropwell/dropwell.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_coder_api.dart';
import 'support/localization.dart';

void main() {
  testWidgets(
    'composer keeps ordered attachment-only draft on failure '
    'and clears on success',
    tags: const <String>['feature_test__conversation_attachments__widget'],
    (tester) async {
      for (final size in <Size>[const Size(1000, 700), const Size(390, 844)]) {
        await tester.pumpWidget(const SizedBox());
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final input = _FakeAttachmentInput();
        var fail = true;
        ComposerSubmission? submitted;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appServicesProvider.overrideWithValue(
                fakeAppServices(FakeCoderApi()),
              ),
            ],
            child: MaterialApp(
              theme: testLightTheme,
              locale: testLocale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: Align(
                  alignment: Alignment.bottomCenter,
                  child: SessionComposer(
                    enabled: true,
                    attachmentInput: input,
                    onSubmit: (submission) async {
                      submitted = submission;
                      if (fail) throw Exception('upload failed');
                    },
                    bar: _bar(),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.byKey(const ValueKey('session-composer-attach')));
        await tester.pumpAndSettle();
        expect(find.textContaining('fixture.png'), findsOneWidget);
        expect(find.textContaining('notes.txt'), findsOneWidget);
        expect(find.textContaining('2.0 KB'), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('session-composer-send')));
        await tester.pumpAndSettle();
        expect(find.textContaining('fixture.png'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('session-composer-attachment-error')),
          findsOneWidget,
        );

        fail = false;
        await tester.tap(find.byKey(const ValueKey('session-composer-send')));
        await tester.pumpAndSettle();
        expect(submitted!.text, isEmpty);
        expect(
          submitted!.attachments.map((item) => item.fileName),
          <String>['fixture.png', 'notes.txt'],
        );
        expect(find.textContaining('fixture.png'), findsNothing);

        final region = tester.widget<DropwellRegion>(
          find.byType(DropwellRegion),
        );
        await region.onDrop(const <DropwellFile>[
          DropwellFile.path(fileName: 'dropped.txt', path: '/tmp/dropped.txt'),
        ]);
        await tester.pumpAndSettle();
        expect(find.textContaining('dropped.txt'), findsOneWidget);
      }
    },
  );

  testWidgets(
    'composer omits the native drop target when the adapter cannot drop',
    tags: const <String>['feature_test__conversation_attachments__widget'],
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appServicesProvider.overrideWithValue(
              fakeAppServices(FakeCoderApi()),
            ),
          ],
          child: MaterialApp(
            theme: testLightTheme,
            locale: testLocale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SessionComposer(
                enabled: true,
                attachmentInput: _FakeAttachmentInput(supportsDrop: false),
                onSubmit: (_) async {},
                bar: _bar(),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(DropwellRegion), findsNothing);
      expect(
        find.byKey(const ValueKey('session-composer-attach')),
        findsOneWidget,
      );
    },
  );
}

SessionComposerBar _bar() => SessionComposerBar(
  hostId: 'server',
  definitions: const <AgentDefinitionDto>[],
  agentDefinitionId: null,
  selection: null,
  onAgentChanged: (_) {},
  onModelChanged: (_) {},
  mode: SessionMode.normal,
  onModeChanged: (_) {},
);

final class _FakeAttachmentInput implements AttachmentInputPort {
  _FakeAttachmentInput({this.supportsDrop = true});

  @override
  final bool supportsDrop;

  @override
  Future<List<PendingAttachment>> pickFiles() async => <PendingAttachment>[
    PendingAttachment.fromBytes(
      fileName: 'fixture.png',
      mimeType: 'image/png',
      bytes: Uint8List.fromList(<int>[1, 2, 3]),
    ),
    PendingAttachment.fromBytes(
      fileName: 'notes.txt',
      mimeType: 'text/plain',
      bytes: Uint8List(2048),
    ),
  ];

  @override
  Future<List<PendingAttachment>> pasteFiles() async =>
      const <PendingAttachment>[];

  @override
  Future<List<PendingAttachment>> droppedFiles(
    List<DropwellFile> files,
  ) async => <PendingAttachment>[
    PendingAttachment.fromBytes(
      fileName: 'dropped.txt',
      mimeType: 'text/plain',
      bytes: Uint8List.fromList(<int>[6]),
    ),
  ];
}
