import 'package:flutter/material.dart';

/// Placeholder settings page.
///
/// Intentionally blank for now — only the app shell (top bar + bottom nav)
/// is visible. Content will be added once the todos feed ships.
class SettingsPage extends StatelessWidget {
  static const pageKey = ValueKey('settings-page');

  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.expand(key: pageKey);
  }
}
