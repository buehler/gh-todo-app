import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gh_todos/components/components.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/models/project.dart';
import 'package:gh_todos/providers/connectivity_provider.dart';
import 'package:gh_todos/providers/issue_mutations.dart';
import 'package:gh_todos/providers/project_list_provider.dart';
import 'package:gh_todos/providers/selected_project_provider.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mix/mix.dart';

/// Inline quick-add composer that lives directly beneath the project selector
/// on the root feed.
///
/// Input + gradient "+" button, wrapped in a `surface_container_lowest` card
/// to honour the "no borders, layered surfaces" design rule. Submitting adds
/// an Issue to the selected project's first linked repository.
class TodosIssueComposer extends ConsumerStatefulWidget {
  static const pageKey = ValueKey('todos-issue-composer');
  static const submitKey = ValueKey('todos-issue-composer-submit');
  static const inputKey = ValueKey('todos-issue-composer-input');

  const TodosIssueComposer({super.key});

  @override
  ConsumerState<TodosIssueComposer> createState() => _TodosIssueComposerState();
}

class _TodosIssueComposerState extends ConsumerState<TodosIssueComposer> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _submitting = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleTextChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleTextChanged)
      ..dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  Future<void> _submit(String projectId) async {
    final title = _controller.text.trim();
    if (title.isEmpty || _submitting) return;

    setState(() => _submitting = true);
    try {
      await ref
          .read(issueMutationsProvider)
          .createIssueInProject(projectId: projectId, title: title);
      if (!mounted) return;
      _controller.clear();
    } on NoLinkedRepositoryException {
      if (!mounted) return;
      _showError(
        'This project has no linked repository. Link one in GitHub to add issues.',
      );
    } catch (_) {
      if (!mounted) return;
      _showError('Failed to create issue.');
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
        _refocusInput();
      }
    }
  }

  void _refocusInput() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNode.requestFocus();
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final selectedId = ref.watch(selectedProjectProvider).asData?.value;
    if (selectedId == null) return const SizedBox.shrink();
    final isOffline = ref.watch(offlineStatusProvider).asData?.value ?? false;

    final projects = ref.watch(projectListProvider);
    final Project? project = projects
        .where((p) => p.id == selectedId)
        .cast<Project?>()
        .firstOrNull;
    final hintText = project != null
        ? 'Quick todo in ${project.name}…'
        : 'Quick todo…';

    final surfaceLowest = resolveColor(
      context,
      ColorTokens.surface.containerLowest,
    );
    final enabled = !isOffline && !_submitting;

    return Padding(
      key: TodosIssueComposer.pageKey,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Box(
        style: BoxStyler()
            .color(surfaceLowest)
            .borderRounded(editorialRadiusMedium)
            .paddingOnly(left: 16, right: 12, top: 12, bottom: 12),
        child: ColumnBox(
          style: editorialColumnStyle(spacing: 10),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: EditorialTextField(
                    key: TodosIssueComposer.inputKey,
                    controller: _controller,
                    focusNode: _focusNode,
                    hintText: hintText,
                    enabled: enabled,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => enabled ? _submit(selectedId) : null,
                    submitOnModifierEnter: true,
                  ),
                ),
                const SizedBox(width: 12),
                _GradientPlusButton(
                  key: TodosIssueComposer.submitKey,
                  enabled: _hasText && enabled,
                  onPressed: () => _submit(selectedId),
                ),
              ],
            ),
            if (isOffline)
              Align(
                alignment: Alignment.centerLeft,
                child: StyledText(
                  'Reconnect to add new todos.',
                  style: editorialTextStyle(
                    TextTokens.label.$medium,
                    color: resolveColor(context, ColorTokens.surface.onVariant),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Gradient "+" button that inherits the FAB's visual DNA — same gradient
/// recipe and diffused glow, scaled down to sit inside the composer card.
///
/// Dropped to a tonal surface fill when disabled so the primary CTA only
/// lights up once there's a title to submit.
class _GradientPlusButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool enabled;

  const _GradientPlusButton({
    required this.onPressed,
    required this.enabled,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final primary = resolveColor(context, ColorTokens.primary.$default);
    final primaryContainer = resolveColor(
      context,
      ColorTokens.primary.container,
    );
    final onPrimary = resolveColor(context, ColorTokens.primary.on);
    final surfaceHigh = resolveColor(
      context,
      ColorTokens.surface.containerHigh,
    );
    final onSurfaceVariant = resolveColor(
      context,
      ColorTokens.surface.onVariant,
    );

    final style = enabled
        ? (BoxStyler()
              .width(44)
              .height(44)
              .linearGradient(
                colors: [primary, primaryContainer],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
              .borderRounded(14)
              .alignment(Alignment.center)
              .animate(editorialAnimation)
              .shadow(
                editorialShadow(
                  color: withOpacity(primary, 0.15),
                  blurRadius: 16,
                  yOffset: 6,
                ),
              )
              .onHovered(BoxStyler().scale(1.04))
              .onPressed(BoxStyler().scale(0.95)))
        : (BoxStyler()
              .width(44)
              .height(44)
              .color(surfaceHigh)
              .borderRounded(14)
              .alignment(Alignment.center)
              .animate(editorialAnimation));

    return PressableBox(
      enabled: enabled,
      onPress: enabled ? onPressed : null,
      style: style,
      child: Opacity(
        opacity: enabled ? 1 : 0.56,
        child: StyledIcon(
          icon: LucideIcons.plus,
          style: editorialIconStyle(
            color: enabled ? onPrimary : onSurfaceVariant,
            size: 20,
          ),
        ),
      ),
    );
  }
}
