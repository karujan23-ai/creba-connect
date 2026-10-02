import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../utils/formatters.dart';

/// A profile photo or brand logo. When there is no image (or it fails to
/// load) the name's initials are shown instead, so nothing ever looks broken.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 48,
    this.square = false,
  });

  final String name;
  final String? imageUrl;
  final double size;

  /// Rounded square (used for brand logos) instead of a circle.
  final bool square;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final initials = Center(
      child: Text(
        initialsOf(name),
        style: TextStyle(
          fontSize: size * 0.34,
          fontWeight: FontWeight.w600,
          color: palette.textMuted,
          letterSpacing: 0.3,
        ),
      ),
    );

    return Semantics(
      label: name,
      image: true,
      child: Container(
        width: size,
        height: size,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: palette.surfaceAlt,
          border: Border.all(color: palette.border),
          shape: square ? BoxShape.rectangle : BoxShape.circle,
          borderRadius: square ? BorderRadius.circular(size * 0.26) : null,
        ),
        child: imageUrl == null
            ? initials
            : Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                excludeFromSemantics: true,
                errorBuilder: (_, _, _) => initials,
              ),
      ),
    );
  }
}
