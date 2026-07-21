import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gh_todos/components/editorial_card.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/providers/app_logger_provider.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mix/mix.dart';

class ApplicationLogsPage extends ConsumerStatefulWidget {
  static const pageKey = ValueKey('application-logs-page');

  final VoidCallback? onBack;

  const ApplicationLogsPage({this.onBack, super.key});

  @override
  ConsumerState<ApplicationLogsPage> createState() =>
      _ApplicationLogsPageState();
}

class _ApplicationLogsPageState extends ConsumerState<ApplicationLogsPage> {
  final ScrollController _verticalController = ScrollController();

  @override
  void dispose() {
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final background = resolveColor(context, ColorTokens.background.$default);
    final onSurface = resolveColor(context, ColorTokens.surface.on);
    final onSurfaceVariant = resolveColor(
      context,
      ColorTokens.surface.onVariant,
    );
    final logsAsync = ref.watch(applicationLogsProvider);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PressableBox(
                onPress:
                    widget.onBack ?? () => Navigator.of(context).maybePop(),
                child: RowBox(
                  style: editorialRowStyle(spacing: 10),
                  children: [
                    StyledIcon(
                      icon: LucideIcons.arrowLeft,
                      style: editorialIconStyle(color: onSurface, size: 18),
                    ),
                    StyledText(
                      'Back',
                      style: editorialTextStyle(
                        TextTokens.body.$medium,
                        color: onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              StyledText(
                'Application Logs',
                style: editorialTextStyle(
                  TextTokens.headline.$medium,
                  color: onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              StyledText(
                'Local diagnostic output stored on this device.',
                style: editorialTextStyle(
                  TextTokens.body.$medium,
                  color: onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: EditorialCard(
                  variation: CardVariation.elevated,
                  padding: const EdgeInsets.all(16),
                  child: logsAsync.when(
                    data: (lines) {
                      if (lines.isEmpty) {
                        return StyledText(
                          'No application logs are currently available.',
                          style: editorialTextStyle(
                            TextTokens.body.$medium,
                            color: onSurfaceVariant,
                          ),
                        );
                      }

                      return Scrollbar(
                        controller: _verticalController,
                        child: SingleChildScrollView(
                          primary: false,
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            controller: _verticalController,
                            primary: false,
                            child: SelectableText(
                              lines.join('\n'),
                              key: ApplicationLogsPage.pageKey,
                              style: TextStyle(
                                color: onSurface,
                                fontSize: 12,
                                height: 1.45,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator.adaptive(),
                    ),
                    error: (_, _) => StyledText(
                      'Application logs could not be loaded.',
                      style: editorialTextStyle(
                        TextTokens.body.$medium,
                        color: onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
