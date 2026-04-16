import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_provider.g.dart';

@Riverpod(keepAlive: true)
Connectivity connectivity(Ref ref) => Connectivity();

@Riverpod(keepAlive: true)
class OfflineStatus extends _$OfflineStatus {
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  @override
  Future<bool> build() async {
    final connectivity = ref.watch(connectivityProvider);
    final initial = await connectivity.checkConnectivity();

    _subscription = connectivity.onConnectivityChanged.listen((results) {
      state = AsyncData(_isOffline(results));
    });
    ref.onDispose(() => _subscription?.cancel());

    return _isOffline(initial);
  }

  bool _isOffline(List<ConnectivityResult> results) {
    return results.isEmpty || results.every((result) => result == ConnectivityResult.none);
  }
}
