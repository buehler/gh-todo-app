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

  /// Called for a GitHub task-list checkbox with its source-order index and
  /// requested checked state. Omit it to render task lists as read-only.
  final Future<void> Function(int taskIndex, bool checked)? onTaskToggle;

  /// Disables every task checkbox in this rendered document while its source
  /// Markdown is being persisted.
  final bool taskToggleBusy;

  const GithubHtmlBody({
    required this.html,
    this.emptyText,
    this.onTaskToggle,
    this.taskToggleBusy = false,
    super.key,
  });

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
      data: _normalizeTaskCheckboxWhitespace(trimmed),
      extensions: [
        TableHtmlExtension(),
        SvgHtmlExtension(),
        MatcherExtension(
          matcher: _isTaskListCheckbox,
          builder: (context) {
            final checkedValue = context.attributes['checked'];
            final checked =
                checkedValue != null &&
                (checkedValue.isEmpty ||
                    checkedValue.toLowerCase() == 'checked');
            return _GithubTaskCheckbox(
              taskIndex: _taskCheckboxIndex(context),
              checked: checked,
              busy: taskToggleBusy,
              onTaskToggle: onTaskToggle,
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

  static final RegExp _taskCheckboxLabelWhitespace = RegExp(
    r'''(<li\b(?=[^>]*\bclass\s*=\s*["'][^"']*\btask-list-item\b[^"']*["'])[^>]*>\s*<input\b(?=[^>]*\btype\s*=\s*["']?checkbox\b)[^>]*>)\s+''',
    caseSensitive: false,
  );

  /// The checkbox widget supplies the task-label gap. Remove whitespace from
  /// the HTML source at this boundary so the first task item cannot receive a
  /// second, source-dependent gap.
  static String _normalizeTaskCheckboxWhitespace(String html) {
    return html.replaceAllMapped(
      _taskCheckboxLabelWhitespace,
      (match) => match.group(1)!,
    );
  }

  static bool _isTaskListCheckbox(ExtensionContext context) {
    final attributes = context.attributes;
    return context.elementName == 'input' &&
        attributes['type']?.toLowerCase() == 'checkbox' &&
        context.element?.parent?.classes.contains('task-list-item') == true;
  }

  static int _taskCheckboxIndex(ExtensionContext context) {
    final checkbox = context.element;
    if (checkbox == null) return -1;

    final checkboxes = context.parser.htmlData
        .getElementsByTagName('input')
        .where(
          (input) =>
              input.attributes['type']?.toLowerCase() == 'checkbox' &&
              input.parent?.classes.contains('task-list-item') == true,
        )
        .toList(growable: false);
    return checkboxes.indexOf(checkbox);
  }
}

class _GithubTaskCheckbox extends StatefulWidget {
  final int taskIndex;
  final bool checked;
  final bool busy;
  final Future<void> Function(int taskIndex, bool checked)? onTaskToggle;

  const _GithubTaskCheckbox({
    required this.taskIndex,
    required this.checked,
    required this.busy,
    required this.onTaskToggle,
  });

  @override
  State<_GithubTaskCheckbox> createState() => _GithubTaskCheckboxState();
}

class _GithubTaskCheckboxState extends State<_GithubTaskCheckbox> {
  var _submitting = false;

  bool get _enabled =>
      widget.taskIndex >= 0 &&
      widget.onTaskToggle != null &&
      !widget.busy &&
      !_submitting;

  Future<void> _toggle() async {
    if (!_enabled) return;
    setState(() => _submitting = true);
    try {
      await widget.onTaskToggle!(widget.taskIndex, !widget.checked);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = _enabled;
    final checkbox = mix.Box(
      style: mix.BoxStyler()
          .size(16, 16)
          .borderAll(color: ColorTokens.primary.$default(), width: 1.2)
          .borderRadiusAll(Radius.circular(4))
          .marginRight(8)
          .alignment(AlignmentGeometry.center),
      child: widget.checked
          ? mix.StyledIcon(
              icon: LucideIcons.check,
              style: mix.IconStyler()
                  .size(12)
                  .color(ColorTokens.primary.$default()),
            )
          : null,
    );

    return Semantics(
      key: ValueKey('github-task-checkbox-${widget.taskIndex}'),
      label: 'Task ${widget.taskIndex + 1}',
      checked: widget.checked,
      button: enabled,
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? _toggle : null,
        child: ExcludeSemantics(child: checkbox),
      ),
    );
  }
}
