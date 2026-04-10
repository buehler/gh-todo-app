import 'package:flutter_test/flutter_test.dart';
import 'package:gh_todos/services/github_token_storage_service.dart';

import '../support/fakes.dart';

void main() {
  test('cold start has no token', () async {
    final storage = FakeFlutterSecureStorage();
    final service = GithubTokenStorageService(storage: storage);

    expect(await service.readToken(), isNull);
    expect(await service.hasToken(), isFalse);
  });

  test('save trims and reads token', () async {
    final storage = FakeFlutterSecureStorage();
    final service = GithubTokenStorageService(storage: storage);

    await service.saveToken('  ghp_12345  ');

    expect(await service.readToken(), 'ghp_12345');
    expect(
      storage.values[GithubTokenStorageService.tokenStorageKey],
      'ghp_12345',
    );
    expect(await service.hasToken(), isTrue);
  });

  test('clear removes stored token', () async {
    final storage = FakeFlutterSecureStorage(
      seed: {GithubTokenStorageService.tokenStorageKey: 'ghp_seed'},
    );
    final service = GithubTokenStorageService(storage: storage);

    await service.clearToken();

    expect(await service.readToken(), isNull);
    expect(await service.hasToken(), isFalse);
  });

  test('empty-after-trim save is rejected', () async {
    final service = GithubTokenStorageService(
      storage: FakeFlutterSecureStorage(),
    );

    expect(() => service.saveToken('   '), throwsArgumentError);
  });
}
