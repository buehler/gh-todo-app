import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:mix/mix.dart';

enum TextFieldVariation { editorial }

class EditorialTextField extends StatefulWidget {
  static const shellKey = ValueKey('editorial-text-field-shell');

  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final IconData? prefixIcon;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final bool autofocus;
  final bool obscureText;
  final bool enabled;
  final TextFieldVariation variation;
  final bool submitOnShiftEnter;

  /// Minimum visible rows. Mirrors `TextField.minLines`.
  final int? minLines;

  /// Maximum visible rows before scrolling. Mirrors `TextField.maxLines`.
  /// Pass `null` for unbounded growth; keep default `1` for single-line inputs.
  final int? maxLines;

  const EditorialTextField({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.keyboardType,
    this.autofocus = false,
    this.obscureText = false,
    this.enabled = true,
    this.variation = TextFieldVariation.editorial,
    this.submitOnShiftEnter = false,
    this.minLines,
    this.maxLines = 1,
  });

  @override
  State<EditorialTextField> createState() => _EditorialTextFieldState();
}

class _EditorialTextFieldState extends State<EditorialTextField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {});
  }

  bool get _hasError =>
      widget.errorText != null && widget.errorText!.isNotEmpty;
  bool get _isFocused => _focusNode.hasFocus;

  @override
  Widget build(BuildContext context) {
    final onSurface = resolveColor(context, ColorTokens.surface.on);
    final onSurfaceVariant = resolveColor(
      context,
      ColorTokens.surface.onVariant,
    );
    final error = resolveColor(context, ColorTokens.error.$default);

    final fieldTextStyle = resolveTextStyle(
      context,
      TextTokens.body.$medium,
    ).copyWith(color: onSurface, fontWeight: FontWeight.w500);
    final hintStyle = resolveTextStyle(
      context,
      TextTokens.body.$medium,
    ).copyWith(color: withOpacity(onSurfaceVariant, 0.8));

    return Opacity(
      opacity: widget.enabled ? 1 : 0.56,
      child: ColumnBox(
        style: editorialColumnStyle(spacing: 8),
        children: [
          if (widget.label != null)
            StyledText(
              widget.label!,
              style: editorialTextStyle(
                TextTokens.label.$small,
                color: resolveColor(context, ColorTokens.outline.$default),
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
              ).uppercase(),
            ),
          Box(
            key: EditorialTextField.shellKey,
            style: editorialTextFieldShellStyle(
              context,
              isFocused: _isFocused,
              hasError: _hasError,
            ),
            child: RowBox(
              style: editorialRowStyle(spacing: 12),
              children: [
                if (widget.prefixIcon != null)
                  StyledIcon(
                    icon: widget.prefixIcon,
                    style: editorialIconStyle(
                      color: _isFocused
                          ? resolveColor(context, ColorTokens.primary.$default)
                          : onSurfaceVariant,
                      size: 18,
                    ),
                  ),
                Expanded(
                  child: CallbackShortcuts(
                    bindings: widget.submitOnShiftEnter
                        ? {
                            SingleActivator(
                              LogicalKeyboardKey.enter,
                              shift: true,
                            ): _submitCurrentText,
                          }
                        : const {},
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      enabled: widget.enabled,
                      obscureText: widget.obscureText,
                      onChanged: widget.onChanged,
                      onSubmitted: widget.onSubmitted,
                      textInputAction: widget.textInputAction,
                      keyboardType: widget.keyboardType,
                      autofocus: widget.autofocus,
                      minLines: widget.minLines,
                      maxLines: widget.maxLines,
                      style: fieldTextStyle,
                      cursorColor: resolveColor(
                        context,
                        ColorTokens.primary.$default,
                      ),
                      decoration: InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        hintText: widget.hintText,
                        hintStyle: hintStyle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_hasError || widget.helperText != null)
            StyledText(
              widget.errorText ?? widget.helperText!,
              style: editorialTextStyle(
                TextTokens.body.$small,
                color: _hasError ? error : onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }

  void _submitCurrentText() {
    if (!widget.enabled) return;
    final handler = widget.onSubmitted;
    if (handler == null) return;
    handler(widget.controller?.text ?? '');
  }
}
