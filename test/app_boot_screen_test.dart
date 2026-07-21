import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gh_todos/app.dart';
import 'package:gh_todos/compositions/setup/app_boot_screen.dart';
import 'package:gh_todos/pages/application_logs_page.dart';
import 'package:gh_todos/providers/app_logger_provider.dart';
import 'package:gh_todos/providers/hive_bootstrap_provider.dart';
import 'package:gh_todos/providers/storage_providers.dart';
import 'package:gh_todos/services/app_logger_service.dart';
import 'package:gh_todos/services/github_token_storage_service.dart';

void main() {
  testWidgets('shows the branded boot screen while Hive is loading', (
    tester,
  ) async {
    final hiveReady = Completer<void>();

    await tester.pumpWidget(_testApp(hiveBootstrap: (_) => hiveReady.future));
    await tester.pump();

    expect(find.byKey(AppBootScreen.loadingKey), findsOneWidget);
    expect(find.text('Preparing your workspace'), findsOneWidget);

    hiveReady.complete();
    await tester.pumpAndSettle();
  });

  testWidgets(
    'shows the boot screen while Keychain session loading is pending',
    (tester) async {
      final tokenReady = Completer<String?>();

      await tester.pumpWidget(
        _testApp(storage: _ControlledStorage(readResult: tokenReady.future)),
      );
      await tester.pump();

      expect(find.byKey(AppBootScreen.loadingKey), findsOneWidget);

      tokenReady.complete(null);
      await tester.pumpAndSettle();
    },
  );

  testWidgets('leaves the boot screen after initialization completes', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    expect(find.byKey(AppBootScreen.loadingKey), findsNothing);
    expect(find.text('Connect to GitHub'), findsOneWidget);
  });

  testWidgets('shows retry and logs actions when initialization fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(hiveBootstrap: (_) async => throw StateError('Hive failed')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(AppBootScreen.errorKey), findsOneWidget);
    expect(find.byKey(AppBootScreen.retryKey), findsOneWidget);
    expect(find.byKey(AppBootScreen.logsKey), findsOneWidget);
  });

  testWidgets('retry reruns failed initialization', (tester) async {
    var attempts = 0;

    await tester.pumpWidget(
      _testApp(
        hiveBootstrap: (_) async {
          attempts++;
          if (attempts == 1) throw StateError('Hive failed');
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(AppBootScreen.retryKey));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.text('Connect to GitHub'), findsOneWidget);
  });

  testWidgets('opens and closes application logs from the boot failure state', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(hiveBootstrap: (_) async => throw StateError('Hive failed')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(AppBootScreen.logsKey));
    await tester.pumpAndSettle();
    expect(find.byType(ApplicationLogsPage), findsOneWidget);

    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(find.byKey(AppBootScreen.errorKey), findsOneWidget);
  });
}

Widget _testApp({
  Future<void> Function(Ref ref)? hiveBootstrap,
  FlutterSecureStorage? storage,
}) {
  return ProviderScope(
    overrides: [
      hiveBootstrapProvider.overrideWith(hiveBootstrap ?? (_) async {}),
      appLogStoreProvider.overrideWithValue(
        AppLogStore(sinkFactory: () => MemoryAppLogSink()),
      ),
      tokenStorageProvider.overrideWithValue(
        GithubTokenStorageService(storage: storage ?? _ControlledStorage()),
      ),
    ],
    child: const GhTodosApp(),
  );
}

class _ControlledStorage extends FlutterSecureStorage {
  final Future<String?>? readResult;

  _ControlledStorage({this.readResult});

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return readResult ?? Future<String?>.value(null);
  }
}
