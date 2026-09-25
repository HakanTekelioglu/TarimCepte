import 'package:flutter/material.dart';

/// Renders Material glyphs from the application's bundled, complete icon font.
///
/// Flutter may subset its built-in Material icon font in release builds. On
/// some web and Android deployments that subset can be served from a stale
/// cache, which leaves every [Icon] as a missing-glyph box. Keeping the app's
/// icon font under a separate family makes icons deterministic on every screen.
class AppIcon extends StatelessWidget {
  final IconData? icon;
  final double? size;
  final Color? color;
  final List<Shadow>? shadows;
  final String? semanticLabel;
  final TextDirection? textDirection;
  final bool? applyTextScaling;

  const AppIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.shadows,
    this.semanticLabel,
    this.textDirection,
    this.applyTextScaling,
  });

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final shouldScale = applyTextScaling ?? iconTheme.applyTextScaling ?? false;
    final baseSize = size ?? iconTheme.size ?? 24;
    final resolvedSize =
        shouldScale
            ? MediaQuery.textScalerOf(context).scale(baseSize)
            : baseSize;
    final iconData = icon;

    if (iconData == null) {
      return Semantics(
        label: semanticLabel,
        child: SizedBox.square(dimension: resolvedSize),
      );
    }

    final direction = textDirection ?? Directionality.of(context);
    final opacity = iconTheme.opacity ?? 1;
    final baseColor = color ?? iconTheme.color ?? Colors.black;
    final resolvedColor = baseColor.withValues(alpha: baseColor.a * opacity);

    Widget glyph = RichText(
      overflow: TextOverflow.visible,
      textDirection: direction,
      text: TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: TextStyle(
          inherit: false,
          color: resolvedColor,
          fontSize: resolvedSize,
          fontFamily: 'AppMaterialIcons',
          shadows: shadows ?? iconTheme.shadows,
          height: 1,
          leadingDistribution: TextLeadingDistribution.even,
        ),
      ),
    );

    if (iconData.matchTextDirection && direction == TextDirection.rtl) {
      glyph = Transform.flip(flipX: true, child: glyph);
    }

    return Semantics(
      label: semanticLabel,
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: resolvedSize,
          child: Center(child: glyph),
        ),
      ),
    );
  }
}

/// Back affordance that also avoids the framework's built-in icon renderer.
class AppBackButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const AppBackButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: onPressed ?? () => Navigator.maybePop(context),
      icon: const AppIcon(Icons.arrow_back_rounded),
    );
  }
}
