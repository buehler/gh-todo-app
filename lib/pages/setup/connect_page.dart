import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gh_todos/components/editorial_card.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/compositions/setup/connect_brand_block.dart';
import 'package:gh_todos/compositions/setup/connect_decorative_panel.dart';
import 'package:gh_todos/compositions/setup/connect_footer.dart';
import 'package:gh_todos/compositions/setup/connect_security_notice.dart';
import 'package:gh_todos/compositions/setup/connect_token_form.dart';
import 'package:gh_todos/compositions/shared/pat_scope_help_card.dart';
import 'package:gh_todos/providers/session_provider.dart';
import 'package:gh_todos/router/app_routes.dart';
import 'package:gh_todos/services/github_auth_service.dart';
import 'package:gh_todos/style/breakpoints.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mix/mix.dart';
import 'package:url_launcher/url_launcher.dart';

final _logger = Logger('ConnectPage');

class ConnectPage extends ConsumerStatefulWidget {
  static const pageKey = ValueKey('connect-page');
  static const backgroundKey = ValueKey('connect-page-background');
  static const safeAreaKey = ValueKey('connect-page-safe-area');
  static const githubDocsUrl =
      'https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens';
  static const tosUrl = 'https://gh-todos.cbue.ch/tos';
  static const privacyUrl = 'https://gh-todos.cbue.ch/privacy';

  const ConnectPage({super.key});

  @override
  ConsumerState<ConnectPage> createState() => _ConnectPageState();
}

class _ConnectPageState extends ConsumerState<ConnectPage> {
  final TextEditingController _tokenController = TextEditingController();

  String? _errorText;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final trimmedToken = _tokenController.text.trim();
    if (trimmedToken.isEmpty || _isSubmitting) {
      return;
    }

    setState(() {
      _errorText = null;
      _isSubmitting = true;
    });

    try {
      _logger.info('Setup flow submitted a PAT for validation.');
      await ref.read(sessionProvider.notifier).connectToken(trimmedToken);
      if (!mounted) {
        return;
      }
      context.goNamed(AppRoutes.rootName);
    } catch (error, stackTrace) {
      _logger.warning('Setup PAT validation failed.', error, stackTrace);
      if (!mounted) {
        return;
      }
      setState(() {
        _errorText = _submitErrorText(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _handleTokenChanged(String _) {
    setState(() {
      _errorText = null;
    });
  }

  Future<void> Function() _urlOpener(String url) {
    final uri = Uri.parse(url);
    return () => launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _submitErrorText(Object error) {
    if (error is MissingGithubScopesException) {
      return error.userMessage;
    }
    if (error is InvalidGithubTokenException) {
      return error.message;
    }
    return 'The token could not be saved securely. Try again and/or check the logs.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: resolveColor(context, ColorTokens.background.$default),
      body: StackBox(
        style: setupPageStackStyle(),
        children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: _ConnectBackgroundLayer(key: ConnectPage.backgroundKey),
            ),
          ),
          SafeArea(
            key: ConnectPage.safeAreaKey,
            child: _ConnectForegroundLayer(
              tokenController: _tokenController,
              errorText: _errorText,
              isSubmitting: _isSubmitting,
              onChanged: _handleTokenChanged,
              onSubmitted: _submit,
              onConnectPressed: _submit,
              onHelpPressed: _urlOpener(ConnectPage.githubDocsUrl),
              onPrivacyPressed: _urlOpener(ConnectPage.privacyUrl),
              onTosPressed: _urlOpener(ConnectPage.tosUrl),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectForegroundLayer extends StatelessWidget {
  final TextEditingController tokenController;
  final String? errorText;
  final bool isSubmitting;
  final ValueChanged<String> onChanged;
  final Future<void> Function() onSubmitted;
  final VoidCallback onConnectPressed;
  final VoidCallback onHelpPressed;
  final VoidCallback onPrivacyPressed;
  final VoidCallback onTosPressed;

  const _ConnectForegroundLayer({
    required this.tokenController,
    required this.errorText,
    required this.isSubmitting,
    required this.onChanged,
    required this.onSubmitted,
    required this.onConnectPressed,
    required this.onHelpPressed,
    required this.onPrivacyPressed,
    required this.onTosPressed,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = resolveColor(context, ColorTokens.surface.on);
    final onSurfaceVariant = resolveColor(
      context,
      ColorTokens.surface.onVariant,
    );
    final surfaceHighest = resolveColor(
      context,
      ColorTokens.surface.containerHighest,
    );
    final outline = resolveColor(context, ColorTokens.outline.$default);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Align(
              alignment: Alignment.topCenter,
              child: Box(
                style: setupPageContentFrameStyle(),
                child: ColumnBox(
                  key: ConnectPage.pageKey,
                  style: setupPageContentColumnStyle(),
                  children: [
                    const ConnectBrandBlock(),
                    ConnectTokenForm(
                      controller: tokenController,
                      onChanged: onChanged,
                      onSubmitted: (_) => onSubmitted(),
                      onConnectPressed: onConnectPressed,
                      onHelpPressed: onHelpPressed,
                      isSubmitting: isSubmitting,
                      errorText: errorText,
                    ),
                    const PatScopeHelpCard(),
                    EditorialCard(
                      variation: CardVariation.elevated,
                      padding: EdgeInsets.zero,
                      child: PressableBox(
                        onPress: () async {
                          _logger.info('Navigating to application logs.');
                          if (!context.mounted) return;
                          await context.pushNamed<void>(
                            AppRoutes.applicationLogsName,
                          );
                        },
                        style: BoxStyler()
                            .color(Colors.transparent)
                            .paddingOnly(horizontal: 20, vertical: 16)
                            .animate(editorialAnimation)
                            .onHovered(BoxStyler().color(surfaceHighest)),
                        child: RowBox(
                          style: editorialRowStyle(
                            spacing: 16,
                            mainAxisSize: MainAxisSize.max,
                          ),
                          children: [
                            Expanded(
                              child: ColumnBox(
                                style: editorialColumnStyle(
                                  spacing: 2,
                                  crossAxis: CrossAxisAlignment.start,
                                ),
                                children: [
                                  StyledText(
                                    'View Logs',
                                    style: editorialTextStyle(
                                      TextTokens.body.$medium,
                                      color: onSurface,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  StyledText(
                                    'Open local application logs.',
                                    style: editorialTextStyle(
                                      TextTokens.body.$small,
                                      color: onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            StyledIcon(
                              icon: LucideIcons.chevronRight,
                              style: editorialIconStyle(
                                color: outline,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const ConnectSecurityNotice(),
                    ConnectFooter(
                      onPrivacyPressed: onPrivacyPressed,
                      onTermsPressed: onTosPressed,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ConnectBackgroundLayer extends StatelessWidget {
  const _ConnectBackgroundLayer({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryFixed = resolveColor(context, ColorTokens.primary.fixed);
    final tertiaryFixed = resolveColor(context, ColorTokens.tertiary.fixedDim);

    // Promote the decorative panel only on `large` (≥1280). Below that the
    // connect form already reads as a deliberate hero; the extra rotated
    // card would just crowd tablet-landscape and smaller desktop windows.
    final showDecorativePanel = isLarge(context);

    return StackBox(
      style: setupPageStackStyle(),
      children: [
        Positioned.fill(child: Box(style: setupPageBackgroundStyle(context))),
        Positioned(
          top: -120,
          left: -120,
          child: _AmbientOrb(color: withOpacity(primaryFixed, 0.28), size: 320),
        ),
        Positioned(
          right: -80,
          bottom: -80,
          child: _AmbientOrb(color: withOpacity(tertiaryFixed, 0.2), size: 240),
        ),
        if (showDecorativePanel)
          const Positioned(
            right: 84,
            top: 180,
            child: ConnectDecorativePanel(),
          ),
      ],
    );
  }
}

class _AmbientOrb extends StatelessWidget {
  final Color color;
  final double size;

  const _AmbientOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
      child: Box(
        style: BoxStyler()
            .width(size)
            .height(size)
            .color(color)
            .borderRounded(size),
      ),
    );
  }
}
