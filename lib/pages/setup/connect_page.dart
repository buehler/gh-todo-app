import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/compositions/setup/connect_brand_block.dart';
import 'package:gh_todos/compositions/setup/connect_decorative_panel.dart';
import 'package:gh_todos/compositions/setup/connect_footer.dart';
import 'package:gh_todos/compositions/setup/connect_security_notice.dart';
import 'package:gh_todos/compositions/setup/connect_token_form.dart';
import 'package:gh_todos/router/app_routes.dart';
import 'package:gh_todos/services/app_session_controller.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class ConnectPage extends StatefulWidget {
  static const pageKey = ValueKey('connect-page');
  static const githubDocsUrl =
      'https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens';

  final AppSessionController sessionController;

  const ConnectPage({required this.sessionController, super.key});

  @override
  State<ConnectPage> createState() => _ConnectPageState();
}

class _ConnectPageState extends State<ConnectPage> {
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
      await widget.sessionController.setToken(trimmedToken);
      if (!mounted) {
        return;
      }
      context.goNamed(AppRoutes.rootName);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorText = 'The token could not be saved securely. Try again.';
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

  Future<void> _openGithubDocs() async {
    final uri = Uri.parse(ConnectPage.githubDocsUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final background = resolveColor(context, ColorTokens.background.$default);
    final primaryFixed = resolveColor(context, ColorTokens.primary.fixed);
    final tertiaryFixed = resolveColor(context, ColorTokens.tertiary.fixedDim);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: _ConnectBackground()),
            Positioned(
              top: -120,
              left: -120,
              child: _AmbientOrb(
                color: withOpacity(primaryFixed, 0.28),
                size: 320,
              ),
            ),
            Positioned(
              right: -80,
              bottom: -80,
              child: _AmbientOrb(
                color: withOpacity(tertiaryFixed, 0.2),
                size: 240,
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 1100;
                final horizontalPadding = constraints.maxWidth >= 720
                    ? 48.0
                    : 24.0;
                final verticalPadding = constraints.maxWidth >= 720
                    ? 36.0
                    : 24.0;

                final content = ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    key: ConnectPage.pageKey,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const ConnectBrandBlock(),
                      const SizedBox(height: 40),
                      ConnectTokenForm(
                        controller: _tokenController,
                        onChanged: _handleTokenChanged,
                        onSubmitted: (_) => _submit(),
                        onConnectPressed: _submit,
                        onHelpPressed: _openGithubDocs,
                        isSubmitting: _isSubmitting,
                        errorText: _errorText,
                      ),
                      const SizedBox(height: 20),
                      const ConnectSecurityNotice(),
                      const SizedBox(height: 32),
                      ConnectFooter(
                        onPrivacyPressed: () =>
                            context.goNamed(AppRoutes.privacyName),
                        onTermsPressed: () =>
                            context.goNamed(AppRoutes.termsName),
                      ),
                    ],
                  ),
                );

                final centeredChild = isDesktop
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(child: content),
                          const SizedBox(width: 72),
                          const ConnectDecorativePanel(),
                        ],
                      )
                    : SingleChildScrollView(child: content);

                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  ),
                  child: Center(child: centeredChild),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectBackground extends StatelessWidget {
  const _ConnectBackground();

  @override
  Widget build(BuildContext context) {
    final surface = resolveColor(context, ColorTokens.surface.$default);
    final bright = resolveColor(context, ColorTokens.surface.bright);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bright, surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}

class _AmbientOrb extends StatelessWidget {
  final Color color;
  final double size;

  const _AmbientOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}
