import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class GithubTokenStorageService {
  static const tokenStorageKey = 'github.personal_access_token';
  static const iosKeychainAccessGroup = 'A7JX5S6CZ6.ch.cbue.GH-Todos';

  final FlutterSecureStorage _storage;

  GithubTokenStorageService({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.unlocked,
              groupId: iosKeychainAccessGroup,
            ),
            mOptions: MacOsOptions(
              accessibility: KeychainAccessibility.unlocked,
            ),
          );

  Future<String?> readToken() async {
    final token = await _storage.read(key: tokenStorageKey);
    final trimmedToken = token?.trim();

    if (trimmedToken == null || trimmedToken.isEmpty) {
      return null;
    }

    return trimmedToken;
  }

  Future<bool> hasToken() async {
    return (await readToken()) != null;
  }

  Future<void> saveToken(String token) async {
    final trimmedToken = token.trim();
    if (trimmedToken.isEmpty) {
      throw ArgumentError.value(
        token,
        'token',
        'GitHub token must not be empty.',
      );
    }

    await _storage.write(key: tokenStorageKey, value: trimmedToken);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: tokenStorageKey);
  }
}
