import 'package:flutter/material.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/style/colors.dart';

class RootPage extends StatelessWidget {
  static const pageKey = ValueKey('root-page');

  const RootPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: resolveColor(context, ColorTokens.background.$default),
      body: const SafeArea(child: SizedBox.expand(key: pageKey)),
    );
  }
}
