import 'package:flutter/material.dart';
import 'package:gh_todos/components/src/component_foundation.dart';
import 'package:gh_todos/style/colors.dart';
import 'package:gh_todos/style/typography.dart';
import 'package:mix/mix.dart';

class EditorialAvatar extends StatelessWidget {
  final String? imageUrl;
  final String fallbackLabel;
  final double radius;

  const EditorialAvatar({
    required this.fallbackLabel,
    this.imageUrl,
    this.radius = 16,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final surfaceContainerLow = resolveColor(
      context,
      ColorTokens.surface.containerLow,
    );
    final onSurfaceVariant = resolveColor(
      context,
      ColorTokens.surface.onVariant,
    );
    final trimmedUrl = imageUrl?.trim() ?? '';
    final initials = _initialsFor(fallbackLabel);
    final diameter = radius * 2;

    return CircleAvatar(
      radius: radius,
      backgroundColor: surfaceContainerLow,
      child: ClipOval(
        child: SizedBox(
          width: diameter,
          height: diameter,
          child: trimmedUrl.isEmpty
              ? _AvatarFallback(initials: initials, color: onSurfaceVariant)
              : Image.network(
                  trimmedUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _AvatarFallback(
                    initials: initials,
                    color: onSurfaceVariant,
                  ),
                ),
        ),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  final String initials;
  final Color color;

  const _AvatarFallback({required this.initials, required this.color});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.transparent,
      child: Center(
        child: StyledText(
          initials,
          style: editorialTextStyle(
            TextTokens.label.$large,
            color: color,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

String _initialsFor(String value) {
  final words = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();

  if (words.isEmpty) return '?';
  if (words.length == 1) {
    return words.first.characters.take(2).toString().toUpperCase();
  }

  return '${words.first.characters.first}${words.last.characters.first}'
      .toUpperCase();
}
