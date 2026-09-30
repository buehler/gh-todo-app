import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gh_todos/compositions/setup/app_boot_screen.dart';
import 'package:gh_todos/providers/hive_bootstrap_provider.dart';
import 'package:gh_todos/providers/session_provider.dart';
import 'package:gh_todos/router/app_router.dart';
import 'package:gh_todos/services/app_logging.dart';
import 'package:gh_todos/style/themes.dart';
import 'package:talker_flutter/talker_flutter.dart';

class GhTodosApp extends ConsumerWidget {
  final String? initialLocation;

  const GhTodosApp({this.initialLocation, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hiveAsync = ref.watch(hiveBootstrapProvider);
    final sessionAsync = ref.watch(sessionProvider);
    final router = ref.watch(appRouterProvider(initialLocation));

    return octanePrime(
      MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        theme: ThemeData(useMaterial3: true),
        builder: (context, child) => _AppBootGate(
          hiveAsync: hiveAsync,
          sessionAsync: sessionAsync,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class _AppBootGate extends ConsumerStatefulWidget {
  final AsyncValue<void> hiveAsync;
  final AsyncValue<({bool hasToken})> sessionAsync;
  final Widget child;

  const _AppBootGate({
    required this.hiveAsync,
    required this.sessionAsync,
    required this.child,
  });

  @override
  ConsumerState<_AppBootGate> createState() => _AppBootGateState();
}

class _AppBootGateState extends ConsumerState<_AppBootGate> {
  bool _showLogs = false;

  @override
  Widget build(BuildContext context) {
    if (_showLogs) {
      return TalkerScreen(
        talker: talkerInstance,
        appBarTitle: 'Application Logs',
        appBarLeading: BackButton(
          onPressed: () => setState(() => _showLogs = false),
        ),
      );
    }

    final error = widget.hiveAsync.hasError || widget.sessionAsync.hasError;
    if (error) {
      return AppBootScreen(
        hasError: true,
        onRetry: () {
          setState(() => _showLogs = false);
          ref.invalidate(hiveBootstrapProvider);
          ref.invalidate(sessionProvider);
        },
        onOpenLogs: () => setState(() => _showLogs = true),
      );
    }

    if (widget.hiveAsync.isLoading || widget.sessionAsync.isLoading) {
      return const AppBootScreen();
    }

    return widget.child;
  }
}
