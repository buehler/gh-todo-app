import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gh_todos/providers/hive_bootstrap_provider.dart';
import 'package:gh_todos/providers/session_provider.dart';
import 'package:gh_todos/router/app_router.dart';
import 'package:gh_todos/style/themes.dart';

class GhTodosApp extends ConsumerWidget {
  final String? initialLocation;

  const GhTodosApp({this.initialLocation, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hiveAsync = ref.watch(hiveBootstrapProvider);
    final sessionAsync = ref.watch(sessionProvider);

    if (hiveAsync.isLoading || sessionAsync.isLoading) {
      return const SizedBox.shrink();
    }

    final router = ref.watch(appRouterProvider(initialLocation));

    return octanePrime(
      MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        theme: ThemeData(useMaterial3: true),
      ),
    );
  }
}
