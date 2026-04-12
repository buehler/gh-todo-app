import 'package:flutter/foundation.dart';
import 'package:gh_todos/services/github_token_storage_service.dart';

class AppSessionController extends ChangeNotifier {
  final GithubTokenStorageService _storageService;

  bool _isHydrated = false;
  bool _hasToken = false;

  AppSessionController({required GithubTokenStorageService storageService})
    : _storageService = storageService;

  bool get isHydrated => _isHydrated;
  bool get hasToken => _hasToken;

  Future<void> hydrate() async {
    _hasToken = await _storageService.hasToken();
    _isHydrated = true;
    notifyListeners();
  }

  Future<void> setToken(String token) async {
    await _storageService.saveToken(token);
    _hasToken = true;
    notifyListeners();
  }

  Future<String?> readToken() async {
    return await _storageService.readToken();
  }

  Future<void> clearToken() async {
    await _storageService.clearToken();
    _hasToken = false;
    notifyListeners();
  }
}
