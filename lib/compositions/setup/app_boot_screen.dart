import 'package:flutter/material.dart';
import 'package:gh_todos/components/components.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mix/mix.dart';

class AppBootScreen extends StatelessWidget {
  static const loadingKey = ValueKey('app-boot-loading');
  static const errorKey = ValueKey('app-boot-error');
  static const retryKey = ValueKey('app-boot-retry');
  static const logsKey = ValueKey('app-boot-logs');

  final bool hasError;
  final VoidCallback? onRetry;
  final VoidCallback? onOpenLogs;

  const AppBootScreen({
    super.key,
    this.hasError = false,
    this.onRetry,
    this.onOpenLogs,
  });

  @override
  Widget build(BuildContext context) {
    final background = resolveColor(context, ColorTokens.background.$default);
    final onBackground = resolveColor(context, ColorTokens.background.on);
    final onSurfaceVariant = resolveColor(
      context,
      ColorTokens.surface.onVariant,
    );
    final primary = resolveColor(context, ColorTokens.primary.$default);
    final primaryOn = resolveColor(context, ColorTokens.primary.on);

    return Scaffold(
      key: hasError ? errorKey : loadingKey,
      backgroundColor: background,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              resolveColor(context, ColorTokens.surface.bright),
              background,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _BootMark(background: onBackground, foreground: primaryOn),
                    const SizedBox(height: 28),
                    Center(
                      child: StyledText(
                        hasError
                            ? 'Workspace unavailable'
                            : 'Preparing your workspace',
                        style: editorialTextStyle(
                          TextTokens.headline.$medium,
                          color: onBackground,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: StyledText(
                        hasError
                            ? 'GH Todos could not finish its local startup checks.'
                            : 'Connecting the local workspace layers securely.',
                        style: editorialTextStyle(
                          TextTokens.body.$medium,
                          color: onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    if (hasError)
                      _BootErrorActions(
                        onRetry: onRetry,
                        onOpenLogs: onOpenLogs,
                      )
                    else
                      _BootProgressIndicator(color: primary),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BootMark extends StatelessWidget {
  final Color background;
  final Color foreground;

  const _BootMark({required this.background, required this.foreground});

  @override
  Widget build(BuildContext context) {
    return Box(
      style: BoxStyler()
          .width(64)
          .height(64)
          .color(background)
          .borderRounded(editorialRadiusMedium)
          .alignment(Alignment.center)
          .shadow(
            editorialShadow(
              color: withOpacity(background, 0.1),
              blurRadius: 22,
              yOffset: 12,
            ),
          ),
      child: StyledIcon(
        icon: LucideIcons.squareTerminal,
        style: editorialIconStyle(color: foreground, size: 30),
      ),
    );
  }
}

class _BootProgressIndicator extends StatefulWidget {
  final Color color;

  const _BootProgressIndicator({required this.color});

  @override
  State<_BootProgressIndicator> createState() => _BootProgressIndicatorState();
}

class _BootProgressIndicatorState extends State<_BootProgressIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: SizedBox.square(
        dimension: 28,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          value: 0.72,
          color: widget.color,
          backgroundColor: withOpacity(widget.color, 0.14),
        ),
      ),
    );
  }
}

class _BootErrorActions extends StatelessWidget {
  final VoidCallback? onRetry;
  final VoidCallback? onOpenLogs;

  const _BootErrorActions({required this.onRetry, required this.onOpenLogs});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        EditorialButton(
          key: AppBootScreen.retryKey,
          label: 'Try again',
          leadingIcon: LucideIcons.rotateCw,
          onPressed: onRetry,
        ),
        const SizedBox(height: 8),
        EditorialButton(
          key: AppBootScreen.logsKey,
          label: 'View application logs',
          leadingIcon: LucideIcons.fileText,
          variation: ButtonVariation.tertiary,
          onPressed: onOpenLogs,
        ),
      ],
    );
  }
}
