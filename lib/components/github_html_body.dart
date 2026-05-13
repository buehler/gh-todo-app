import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html_svg/flutter_html_svg.dart';
import 'package:flutter_html_table/flutter_html_table.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mix/mix.dart' as mix;
import 'package:url_launcher/url_launcher.dart';

class GithubHtmlBody extends StatelessWidget {
  final String? html;
  final String? emptyText;

  const GithubHtmlBody({required this.html, this.emptyText, super.key});

  @override
  Widget build(BuildContext context) {
    final trimmed = html?.trim();
    final onSurface = resolveColor(context, ColorTokens.surface.on);
    final onSurfaceVariant = resolveColor(
      context,
      ColorTokens.surface.onVariant,
    );
    final primary = resolveColor(context, ColorTokens.primary.container);
    final surfaceLow = resolveColor(context, ColorTokens.surface.containerLow);
    final surfaceLowest = resolveColor(
      context,
      ColorTokens.surface.containerLowest,
    );
    final outlineVariant = resolveColor(context, ColorTokens.outline.variant);

    if (trimmed == null || trimmed.isEmpty) {
      final fallback = emptyText;
      if (fallback == null || fallback.isEmpty) return const SizedBox.shrink();
      return Text(
        fallback,
        style: resolveTextStyle(context, TextTokens.body.$medium).copyWith(
          color: withOpacity(onSurfaceVariant, 0.7),
          fontWeight: FontWeight.w500,
        ),
      );
    }

    final bodyStyle = resolveTextStyle(
      context,
      TextTokens.body.$medium,
    ).copyWith(color: onSurfaceVariant, height: 1.5);
    final titleLarge = resolveTextStyle(
      context,
      TextTokens.title.$large,
    ).copyWith(color: onSurface, fontWeight: FontWeight.w800, height: 1.25);
    final titleMedium = resolveTextStyle(
      context,
      TextTokens.title.$medium,
    ).copyWith(color: onSurface, fontWeight: FontWeight.w800, height: 1.25);
    final titleSmall = resolveTextStyle(
      context,
      TextTokens.title.$small,
    ).copyWith(color: onSurface, fontWeight: FontWeight.w700, height: 1.25);

    return Html(
      data: trimmed,
      extensions: [
        TableHtmlExtension(),
        SvgHtmlExtension(),
        MatcherExtension(
          matcher: (context) {
            final attributes = context.attributes;
            return context.elementName == 'input' &&
                attributes['type']?.toLowerCase() == 'checkbox';
          },
          builder: (context) {
            final checkedValue = context.attributes['checked'];
            final checked =
                checkedValue != null &&
                (checkedValue.isEmpty ||
                    checkedValue.toLowerCase() == 'checked');
            return mix.Box(
              style: mix.BoxStyler()
                  .size(16, 16)
                  .borderAll(color: ColorTokens.primary.$default(), width: 1.2)
                  .borderRadiusAll(Radius.circular(4))
                  .marginRight(8)
                  .alignment(AlignmentGeometry.center),
              child: checked
                  ? mix.StyledIcon(
                      icon: LucideIcons.check,
                      style: mix.IconStyler()
                          .size(12)
                          .color(ColorTokens.primary.$default()),
                    )
                  : null,
            );
          },
        ),
      ],
      onLinkTap: (url, _, _) {
        if (url == null || url.isEmpty) return;
        final uri = Uri.tryParse(url);
        if (uri == null) return;
        launchUrl(uri, mode: LaunchMode.externalApplication);
      },
      style: {
        '*': Style(
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
          color: onSurfaceVariant,
          fontSize: FontSize(bodyStyle.fontSize ?? 16),
          lineHeight: const LineHeight(1.5),
          fontFamily: bodyStyle.fontFamily,
          fontFamilyFallback: bodyStyle.fontFamilyFallback,
        ),
        'body': Style.fromTextStyle(bodyStyle).copyWith(
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
          color: onSurfaceVariant,
          lineHeight: const LineHeight(1.5),
        ),
        'p': Style(
          margin: Margins.only(bottom: 12),
          lineHeight: const LineHeight(1.5),
        ),
        'a': Style(
          color: primary,
          fontWeight: FontWeight.w700,
          textDecoration: TextDecoration.none,
        ),
        'h1': Style.fromTextStyle(
          titleLarge,
        ).copyWith(margin: Margins.only(top: 4, bottom: 12)),
        'h2': Style.fromTextStyle(
          titleMedium,
        ).copyWith(margin: Margins.only(top: 4, bottom: 10)),
        'h3': Style.fromTextStyle(
          titleSmall,
        ).copyWith(margin: Margins.only(top: 4, bottom: 8)),
        'h4': Style.fromTextStyle(
          titleSmall,
        ).copyWith(margin: Margins.only(top: 4, bottom: 8)),
        'h5': Style.fromTextStyle(
          titleSmall,
        ).copyWith(margin: Margins.only(top: 4, bottom: 8)),
        'h6': Style.fromTextStyle(
          titleSmall,
        ).copyWith(margin: Margins.only(top: 4, bottom: 8)),
        'ul': Style(margin: Margins.only(left: 18, bottom: 12)),
        'ol': Style(margin: Margins.only(left: 18, bottom: 12)),
        'li': Style(margin: Margins.only(bottom: 6)),
        'input': Style(margin: Margins.only(right: 4)),
        'blockquote': Style(
          backgroundColor: surfaceLow,
          margin: Margins.only(bottom: 12),
          padding: HtmlPaddings.symmetric(horizontal: 14, vertical: 12),
          border: Border(
            left: BorderSide(
              color: withOpacity(outlineVariant, 0.15),
              width: 3,
            ),
          ),
        ),
        'code': Style(
          backgroundColor: surfaceLow,
          color: onSurface,
          fontFamily: 'monospace',
          fontFamilyFallback: const [
            'SFMono-Regular',
            'Menlo',
            'Consolas',
            'monospace',
          ],
          fontSize: FontSize(14),
          padding: HtmlPaddings.symmetric(horizontal: 5, vertical: 2),
        ),
        'pre': Style(
          backgroundColor: surfaceLow,
          color: onSurface,
          margin: Margins.only(bottom: 12),
          padding: HtmlPaddings.all(14),
          whiteSpace: WhiteSpace.pre,
        ),
        'table': Style(
          backgroundColor: surfaceLowest,
          margin: Margins.only(bottom: 12),
          border: Border.all(color: withOpacity(outlineVariant, 0.15)),
        ),
        'th': Style(
          backgroundColor: surfaceLow,
          color: onSurface,
          fontWeight: FontWeight.w800,
          padding: HtmlPaddings.symmetric(horizontal: 10, vertical: 8),
          border: Border.all(color: withOpacity(outlineVariant, 0.15)),
        ),
        'td': Style(
          padding: HtmlPaddings.symmetric(horizontal: 10, vertical: 8),
          border: Border.all(color: withOpacity(outlineVariant, 0.15)),
        ),
        'img': Style(margin: Margins.only(bottom: 12)),
      },
    );
  }
}
