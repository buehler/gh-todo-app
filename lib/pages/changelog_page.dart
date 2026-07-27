import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gh_todos/components/editorial_card.dart';
import 'package:gh_todos/components/github_html_body.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:mix/mix.dart';

class ChangelogPage extends StatefulWidget {
  static const pageKey = ValueKey('changelog-page');

  final VoidCallback? onBack;

  const ChangelogPage({this.onBack, super.key});

  @override
  State<ChangelogPage> createState() => _ChangelogPageState();
}

class _ChangelogPageState extends State<ChangelogPage> {
  late final Future<String> _htmlFuture = _loadChangelog();
  final ScrollController _scrollController = ScrollController();

  Future<String> _loadChangelog() async {
    final source = await rootBundle.loadString('CHANGELOG.md');
    return md.markdownToHtml(source);
  }

  @override
  void dispose() {
    _scrollController.dispose();
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

    return Scaffold(
      key: ChangelogPage.pageKey,
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
                'Changelog',
                style: editorialTextStyle(
                  TextTokens.headline.$medium,
                  color: onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              StyledText(
                'Updates and changes in GitHub Todos.',
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
                  child: FutureBuilder<String>(
                    future: _htmlFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(
                          child: CircularProgressIndicator.adaptive(),
                        );
                      }
                      if (snapshot.hasError) {
                        return StyledText(
                          'The changelog could not be loaded.',
                          style: editorialTextStyle(
                            TextTokens.body.$medium,
                            color: onSurfaceVariant,
                          ),
                        );
                      }
                      return Scrollbar(
                        controller: _scrollController,
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          child: GithubHtmlBody(html: snapshot.data),
                        ),
                      );
                    },
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
