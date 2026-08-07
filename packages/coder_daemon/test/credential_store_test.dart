import 'dart:convert';
import 'dart:io';

import 'package:coder_agent/coder_agent.dart';
import 'package:coder_daemon/src/features/providers/infrastructure/credential_store.dart';
import 'package:coder_daemon/src/shared/infrastructure/persistence/repositories.dart';
import 'package:test/test.dart';

void main() {
  test(
    'stores provider and daemon credentials atomically in one protected file',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'coder-credential-test-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final expiresAt = DateTime.utc(2026, 8, 2, 12);
      final store = CredentialStore(directory.path);

      await store.setCredential(
        'deepseek',
        const ApiKeyCredential('api-secret'),
      );
      await store.setCredential(
        'openai',
        OAuthCredential(
          accessToken: 'access-secret',
          refreshToken: 'refresh-secret',
          expiresAt: expiresAt,
          accountId: 'account-id',
        ),
      );
      await store.setDaemonToken('daemon-secret');

      final reloaded = CredentialStore(directory.path);
      await reloaded.load();
      expect(
        reloaded.credential('deepseek'),
        isA<ApiKeyCredential>().having(
          (credential) => credential.key,
          'key',
          'api-secret',
        ),
      );
      expect(
        reloaded.credential('openai'),
        isA<OAuthCredential>()
            .having(
              (credential) => credential.accessToken,
              'access token',
              'access-secret',
            )
            .having(
              (credential) => credential.refreshToken,
              'refresh token',
              'refresh-secret',
            )
            .having(
              (credential) => credential.expiresAt,
              'expiration',
              expiresAt,
            ),
      );
      expect(reloaded.bearerToken, 'daemon-secret');

      final credentialsJson = await File(
        '${directory.path}/secrets.json',
      ).readAsString();
      expect(jsonDecode(credentialsJson), <String, dynamic>{
        'schemaVersion': 1,
        'daemon': <String, dynamic>{'bearerToken': 'daemon-secret'},
        'providerCredentials': <String, dynamic>{
          'deepseek': <String, dynamic>{
            'type': 'apiKey',
            'key': 'api-secret',
          },
          'openai': <String, dynamic>{
            'type': 'oauth',
            'accessToken': 'access-secret',
            'refreshToken': 'refresh-secret',
            'expiresAt': expiresAt.toIso8601String(),
            'accountId': 'account-id',
          },
        },
      });
      expect(credentialsJson, contains('daemon-secret'));
      expect(credentialsJson, contains('api-secret'));
      expect(credentialsJson, contains('access-secret'));
      expect(File('${directory.path}/auth.json').existsSync(), isFalse);

      if (!Platform.isWindows) {
        expect(
          File('${directory.path}/secrets.json').statSync().mode & 0x1ff,
          0x180,
        );
      }
    },
  );

  test('rejects obsolete dual-token credential documents explicitly', () async {
    final directory = await Directory.systemTemp.createTemp(
      'coder-obsolete-credential-test-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/secrets.json');
    await file.writeAsString(
      jsonEncode(<String, dynamic>{
        'schemaVersion': 0,
        'daemon': <String, dynamic>{
          'bearerToken': 'bearer',
          'adminToken': 'obsolete',
        },
        'providerCredentials': <String, dynamic>{},
      }),
    );

    await expectLater(
      CredentialStore(directory.path).load(),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('incompatible_credentials'),
        ),
      ),
    );
  });

  test('MCP secrets live beside provider credentials', () async {
    final directory = await Directory.systemTemp.createTemp(
      'coder-credential-mcp-test-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final store = CredentialStore(directory.path);

    await store.setMcpSecret('github.token', 'mcp-secret');
    await store.setCredential('openai', const ApiKeyCredential('api-secret'));

    final reloaded = CredentialStore(directory.path);
    await reloaded.load();
    expect(reloaded.mcpSecrets, <String, String>{
      'github.token': 'mcp-secret',
    });
    expect(reloaded.credential('openai'), isA<ApiKeyCredential>());

    await reloaded.setMcpSecret('github.token', 'rotated');
    await reloaded.removeMcpSecret('absent');
    expect(reloaded.mcpSecrets['github.token'], 'rotated');

    await reloaded.removeMcpSecret('github.token');
    final rereloaded = CredentialStore(directory.path);
    await rereloaded.load();
    expect(rereloaded.mcpSecrets, isEmpty);
  });

  test('a file carrying a malformed MCP secret is rejected', () async {
    final directory = await Directory.systemTemp.createTemp(
      'coder-credential-mcp-invalid-',
    );
    addTearDown(() => directory.delete(recursive: true));
    await File('${directory.path}/secrets.json').writeAsString(
      jsonEncode(<String, dynamic>{
        'schemaVersion': 1,
        'providerCredentials': <String, dynamic>{},
        'mcpSecrets': <String, dynamic>{'github.token': 42},
      }),
    );

    await expectLater(
      CredentialStore(directory.path).load(),
      throwsA(isA<FormatException>()),
    );
  });

  test('removing one credential preserves the remaining credentials', () async {
    final directory = await Directory.systemTemp.createTemp(
      'coder-credential-remove-test-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final store = CredentialStore(directory.path);
    await store.setCredential('first', const ApiKeyCredential('first-secret'));
    await store.setCredential(
      'second',
      const ApiKeyCredential('second-secret'),
    );

    await store.removeCredential('first');

    final reloaded = CredentialStore(directory.path);
    await reloaded.load();
    expect(reloaded.credential('first'), isNull);
    expect(reloaded.credential('second'), isA<ApiKeyCredential>());
  });
}
