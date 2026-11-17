import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Radius scale. Shape signals importance: bigger radius = more important.
abstract final class AppRadius {
  static const double hero = 28;
  static const double surface = 20;
  static const double inner = 14;
  static const double chip = 10;
}

enum _CardKind { surface, feature }

// =============================================================================
// APP CARD  (surface + feature)
// =============================================================================
/// Flat solid surface with a hairline edge that is lighter at the top
/// (light catching the rim). No gradients, no glow.
///
/// * `AppCard(...)`          quiet default surface.
/// * `AppCard.feature(...)`  solid accent fill with dark ink. One per screen.
/// * `rail:`                 3px status edge (present / absent / pending).
///
/// Backwards compatible with the previous constructor.
class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.radius = AppRadius.surface,
    this.color,
    this.borderColor,
    this.onTap,
    this.onLongPress,
    this.elevation = 0,
    this.clipBehavior = Clip.antiAlias,
    this.rail,
    this.pressScale = 0.985,
    this.haptic = true,
    this.semanticLabel,
  }) : _kind = _CardKind.surface;

  const AppCard.feature({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.margin,
    this.radius = AppRadius.hero,
    this.color,
    this.onTap,
    this.onLongPress,
    this.clipBehavior = Clip.antiAlias,
    this.pressScale = 0.985,
    this.haptic = true,
    this.semanticLabel,
  }) : _kind = _CardKind.feature,
       borderColor = null,
       elevation = 0,
       rail = null;

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double elevation;
  final Clip clipBehavior;
  final Color? rail;
  final double pressScale;
  final bool haptic;
  final String? semanticLabel;
  final _CardKind _kind;

  /// Dark ink colour for content placed on a feature (accent) card.
  static Color ink(BuildContext context) =>
      Theme.of(context).scaffoldBackgroundColor;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _down = false;

  bool get _tappable => widget.onTap != null || widget.onLongPress != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final feature = widget._kind == _CardKind.feature;
    final r = widget.radius;

    final base =
        widget.color ??
        (feature
            ? theme.colorScheme.primary
            : (theme.cardTheme.color ?? theme.colorScheme.surface));
    final fill = (_down && !feature)
        ? Color.alphaBlend(Colors.white.withValues(alpha: 0.05), base)
        : base;

    final Gradient? hairline = feature
        ? null
        : (widget.borderColor != null
              ? LinearGradient(
                  colors: [widget.borderColor!, widget.borderColor!],
                )
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.16),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                ));

    final ink = AppCard.ink(context);

    Widget content = Padding(
      padding: widget.padding.add(
        EdgeInsets.only(left: widget.rail != null ? 6 : 0),
      ),
      child: widget.child,
    );

    if (feature) {
      content = IconTheme.merge(
        data: IconThemeData(color: ink),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: ink),
          child: content,
        ),
      );
    }

    if (widget.rail != null) {
      content = Stack(
        children: [
          content,
          Positioned(
            left: 0,
            top: 16,
            bottom: 16,
            width: 3,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: widget.rail,
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(3),
                ),
              ),
            ),
          ),
        ],
      );
    }

    Widget card = Container(
      margin: widget.margin,
      padding: EdgeInsets.all(feature ? 0 : 1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r),
        gradient: hairline,
        boxShadow: [
          if (widget.elevation > 0)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.30),
              blurRadius: widget.elevation * 5,
              offset: Offset(0, widget.elevation * 1.5),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(feature ? r : r - 1),
        clipBehavior: widget.clipBehavior,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          color: fill,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: widget.onTap == null
                  ? null
                  : () {
                      if (widget.haptic) HapticFeedback.selectionClick();
                      widget.onTap!();
                    },
              onLongPress: widget.onLongPress,
              onHighlightChanged: _tappable
                  ? (v) {
                      if (mounted && _down != v) setState(() => _down = v);
                    }
                  : null,
              splashColor: (feature ? ink : Colors.white).withValues(
                alpha: 0.08,
              ),
              highlightColor: Colors.transparent,
              child: content,
            ),
          ),
        ),
      ),
    );

    if (_tappable) {
      card = AnimatedScale(
        scale: _down ? widget.pressScale : 1,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        child: card,
      );
    }

    return Semantics(
      container: true,
      button: widget.onTap != null,
      label: widget.semanticLabel,
      child: card,
    );
  }
}

// =============================================================================
// TICKET CARD  (signature: hall-ticket style with perforation notches)
// =============================================================================
/// Two stacked sections divided by a perforated tear line with side notches.
/// Use once per screen for the key status (e.g. attendance).
class AppTicketCard extends StatefulWidget {
  const AppTicketCard({
    super.key,
    required this.top,
    required this.bottom,
    this.topPadding = const EdgeInsets.all(20),
    this.bottomPadding = const EdgeInsets.fromLTRB(20, 16, 20, 18),
    this.radius = AppRadius.hero,
    this.notch = 11,
    this.color,
    this.onTap,
    this.semanticLabel,
  });

  final Widget top;
  final Widget bottom;
  final EdgeInsetsGeometry topPadding;
  final EdgeInsetsGeometry bottomPadding;
  final double radius;
  final double notch;
  final Color? color;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  State<AppTicketCard> createState() => _AppTicketCardState();
}

class _AppTicketCardState extends State<AppTicketCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fill =
        widget.color ?? theme.cardTheme.color ?? theme.colorScheme.surface;
    final edge = Colors.white.withValues(alpha: 0.12);

    final topShape = _TicketShape(
      radius: widget.radius,
      notch: widget.notch,
      bottomNotch: true,
      edge: edge,
    );
    final bottomShape = _TicketShape(
      radius: widget.radius,
      notch: widget.notch,
      topNotch: true,
      edge: edge,
    );

    Widget piece(_TicketShape shape, Widget child) => ClipPath(
      clipper: ShapeBorderClipper(shape: shape),
      child: DecoratedBox(
        decoration: ShapeDecoration(color: fill, shape: shape),
        child: child,
      ),
    );

    Widget card = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        piece(
          topShape,
          SizedBox(
            width: double.infinity,
            child: Padding(padding: widget.topPadding, child: widget.top),
          ),
        ),
        piece(
          bottomShape,
          Stack(
            children: [
              SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: widget.bottomPadding,
                  child: widget.bottom,
                ),
              ),
              Positioned(
                top: 0,
                left: widget.notch + 10,
                right: widget.notch + 10,
                height: 1,
                child: CustomPaint(
                  painter: _DashPainter(Colors.white.withValues(alpha: 0.16)),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (widget.onTap != null) {
      card = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTap!();
        },
        child: AnimatedScale(
          scale: _down ? 0.985 : 1,
          duration: const Duration(milliseconds: 130),
          curve: Curves.easeOut,
          child: card,
        ),
      );
    }

    return Semantics(
      container: true,
      button: widget.onTap != null,
      label: widget.semanticLabel,
      child: card,
    );
  }
}

class _TicketShape extends ShapeBorder {
  const _TicketShape({
    required this.radius,
    required this.notch,
    required this.edge,
    this.topNotch = false,
    this.bottomNotch = false,
  });

  final double radius;
  final double notch;
  final Color edge;
  final bool topNotch;
  final bool bottomNotch;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  ShapeBorder scale(double t) => this;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect, textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final round = Radius.circular(radius);
    final rr = RRect.fromRectAndCorners(
      rect,
      topLeft: topNotch ? Radius.zero : round,
      topRight: topNotch ? Radius.zero : round,
      bottomLeft: bottomNotch ? Radius.zero : round,
      bottomRight: bottomNotch ? Radius.zero : round,
    );
    final body = Path()..addRRect(rr);
    final holes = Path();
    if (topNotch) {
      holes
        ..addOval(Rect.fromCircle(center: rect.topLeft, radius: notch))
        ..addOval(Rect.fromCircle(center: rect.topRight, radius: notch));
    }
    if (bottomNotch) {
      holes
        ..addOval(Rect.fromCircle(center: rect.bottomLeft, radius: notch))
        ..addOval(Rect.fromCircle(center: rect.bottomRight, radius: notch));
    }
    return Path.combine(PathOperation.difference, body, holes);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    // Skip the flat seam edge so the perforation line is the only divider.
    canvas.save();
    canvas.clipRect(
      Rect.fromLTRB(
        rect.left - 2,
        rect.top + (topNotch ? 2 : -2),
        rect.right + 2,
        rect.bottom - (bottomNotch ? 2 : -2),
      ),
    );
    canvas.drawPath(
      getOuterPath(rect),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = edge,
    );
    canvas.restore();
  }
}

class _DashPainter extends CustomPainter {
  _DashPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    const dash = 5.0;
    const gap = 5.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0.5), Offset(x + dash, 0.5), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}

// =============================================================================
// GROUPED LIST  (many rows, one surface, hairline dividers)
// =============================================================================
class AppListGroup extends StatelessWidget {
  const AppListGroup({
    super.key,
    required this.children,
    this.margin,
    this.dividerIndent = 68,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry? margin;
  final double dividerIndent;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      margin: margin,
      haptic: false,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                indent: dividerIndent,
                color: Colors.white.withValues(alpha: 0.07),
              ),
          ],
        ],
      ),
    );
  }
}

/// Row for [AppListGroup]. Monochrome icon tile; colour is kept for status.
class AppListTile extends StatelessWidget {
  const AppListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.leading,
    this.value,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.showChevron = true,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? leading;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final lead =
        leading ??
        (icon == null
            ? null
            : Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(AppRadius.inner - 2),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: iconColor ?? colors.onSurfaceVariant,
                ),
              ));

    return InkWell(
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap!();
            },
      splashColor: colors.primary.withValues(alpha: 0.10),
      highlightColor: colors.primary.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            if (lead != null) ...[lead, const SizedBox(width: 14)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (value != null) ...[
              const SizedBox(width: 10),
              Text(
                value!,
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            if (showChevron && onTap != null) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.onSurfaceVariant.withValues(alpha: 0.65),
                size: 22,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
