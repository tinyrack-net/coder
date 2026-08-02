import 'dart:io';

import 'package:coder_daemon/src/credential_store.dart';
import 'package:coder_daemon/src/repositories.dart';
import 'package:test/test.dart';

void main() {
  test(
    'stores typed provider credentials separately from daemon auth',
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
      await store.setBearerToken('daemon-secret');

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
        '${directory.path}/credentials.json',
      ).readAsString();
      final authJson = await File('${directory.path}/auth.json').readAsString();
      expect(credentialsJson, isNot(contains('daemon-secret')));
      expect(authJson, isNot(contains('api-secret')));
      expect(authJson, isNot(contains('access-secret')));

      if (!Platform.isWindows) {
        expect(
          File('${directory.path}/credentials.json').statSync().mode & 0x1ff,
          0x180,
        );
        expect(
          File('${directory.path}/auth.json').statSync().mode & 0x1ff,
          0x180,
        );
      }
    },
  );

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
