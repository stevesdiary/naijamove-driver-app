import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// A lightweight stylised Lagos map rendered with CustomPainter.
///
/// This stands in for Mapbox during UI development (no API key, no tiles,
/// works offline). Pins, route and driver markers are positioned in
/// normalised 0..1 coordinates so the widget scales to any size.
/// Swap for `mapbox_maps_flutter` behind the same props later.
class MapCanvas extends StatelessWidget {
  const MapCanvas({
    super.key,
    this.pickup,
    this.destination,
    this.stops = const [],
    this.drivers = const [],
    this.showRoute = false,
    this.routeProgress = 1.0,
    this.currentLocation,
    this.pulse = false,
    this.dimmed = false,
    this.heatmap = false,
    this.child,
  });

  final Offset? pickup;
  final Offset? destination;
  final List<Offset> stops;
  final List<MapDriver> drivers;
  final bool showRoute;

  /// 0..1 — how much of the route (pickup→destination) has been travelled.
  final double routeProgress;
  final Offset? currentLocation;
  final bool pulse;

  /// Grey-out (completed trip).
  final bool dimmed;
  final bool heatmap;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _MapPainter(
              dark: dark,
              pickup: pickup,
              destination: destination,
              stops: stops,
              showRoute: showRoute,
              routeProgress: routeProgress,
              dimmed: dimmed,
              heatmap: heatmap,
            ),
          ),
          if (currentLocation != null)
            _Positioned(
              at: currentLocation!,
              child: _CurrentLocationDot(pulse: pulse),
            ),
          for (final d in drivers)
            _Positioned(
              at: d.position,
              child: _DriverMarker(heading: d.heading, dimmed: dimmed),
            ),
          if (pickup != null)
            _Positioned(
              at: pickup!,
              child: _PickupPin(pulse: pulse),
            ),
          for (var i = 0; i < stops.length; i++)
            _Positioned(
              at: stops[i],
              child: _StopPin(index: i + 1),
            ),
          if (destination != null)
            _Positioned(
              at: destination!,
              anchorBottom: true,
              child: const _DestinationPin(),
            ),
          ?child,
        ],
      ),
    );
  }
}

class MapDriver {
  const MapDriver(this.position, {this.heading = 0});
  final Offset position;
  final double heading; // radians
}

class _Positioned extends StatelessWidget {
  const _Positioned({
    required this.at,
    required this.child,
    this.anchorBottom = false,
  });
  final Offset at;
  final Widget child;
  final bool anchorBottom;
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, c) => Stack(
        children: [
          Positioned(
            left: at.dx * c.maxWidth,
            top: at.dy * c.maxHeight,
            child: FractionalTranslation(
              translation: Offset(-0.5, anchorBottom ? -1 : -0.5),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter({
    required this.dark,
    required this.pickup,
    required this.destination,
    required this.stops,
    required this.showRoute,
    required this.routeProgress,
    required this.dimmed,
    required this.heatmap,
  });

  final bool dark;
  final Offset? pickup;
  final Offset? destination;
  final List<Offset> stops;
  final bool showRoute;
  final double routeProgress;
  final bool dimmed;
  final bool heatmap;

  @override
  void paint(Canvas canvas, Size size) {
    final land = dark ? AppColors.darkBackground : AppColors.background;
    final water = dark ? AppColors.darkSurface : AppColors.mapWater;
    final road = dark ? AppColors.darkBorder : AppColors.mapRoad;
    final roadMajor = dark
        ? AppColors.darkBorder.withValues(alpha: 0.9)
        : Colors.white;

    canvas.drawRect(Offset.zero & size, Paint()..color = land);

    // Lagoon (bottom-left) and creek (right) — abstract Lagos water shapes.
    final waterPaint = Paint()..color = water;
    final lagoon = Path()
      ..moveTo(0, size.height * 0.62)
      ..cubicTo(
        size.width * 0.18,
        size.height * 0.55,
        size.width * 0.28,
        size.height * 0.78,
        size.width * 0.45,
        size.height * 0.72,
      )
      ..cubicTo(
        size.width * 0.55,
        size.height * 0.69,
        size.width * 0.6,
        size.height * 0.9,
        size.width * 0.5,
        size.height,
      )
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(lagoon, waterPaint);
    final creek = Path()
      ..moveTo(size.width, size.height * 0.05)
      ..cubicTo(
        size.width * 0.86,
        size.height * 0.18,
        size.width * 0.95,
        size.height * 0.32,
        size.width * 0.82,
        size.height * 0.42,
      )
      ..cubicTo(
        size.width * 0.78,
        size.height * 0.46,
        size.width * 0.9,
        size.height * 0.5,
        size.width,
        size.height * 0.48,
      )
      ..close();
    canvas.drawPath(creek, waterPaint);

    // Grid of minor roads.
    final minor = Paint()
      ..color = road
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    const cols = 9;
    const rows = 14;
    for (var i = 1; i < cols; i++) {
      final x = size.width * i / cols + math.sin(i * 1.7) * 8;
      canvas.drawLine(Offset(x, 0), Offset(x + 14, size.height), minor);
    }
    for (var j = 1; j < rows; j++) {
      final y = size.height * j / rows + math.cos(j * 1.3) * 6;
      canvas.drawLine(Offset(0, y), Offset(size.width, y - 10), minor);
    }

    // Major roads (white, wider).
    final major = Paint()
      ..color = roadMajor
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final majorEdge = Paint()
      ..color = road
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final expressway = Path()
      ..moveTo(-10, size.height * 0.3)
      ..cubicTo(
        size.width * 0.3,
        size.height * 0.22,
        size.width * 0.6,
        size.height * 0.4,
        size.width + 10,
        size.height * 0.34,
      );
    final bridge = Path()
      ..moveTo(size.width * 0.15, size.height + 10)
      ..cubicTo(
        size.width * 0.3,
        size.height * 0.7,
        size.width * 0.5,
        size.height * 0.5,
        size.width * 0.72,
        -10,
      );
    for (final p in [expressway, bridge]) {
      canvas.drawPath(p, majorEdge);
      canvas.drawPath(p, major);
    }

    // Blocks (subtle filled rectangles) for texture.
    final block = Paint()
      ..color = (dark ? AppColors.darkSurface : Colors.white).withValues(
        alpha: dark ? 0.35 : 0.6,
      );
    final rnd = math.Random(7);
    for (var i = 0; i < 26; i++) {
      final w = 18 + rnd.nextDouble() * 34;
      final h = 14 + rnd.nextDouble() * 26;
      final x = rnd.nextDouble() * (size.width - w);
      final y = rnd.nextDouble() * (size.height - h);
      if (lagoon.contains(Offset(x, y)) || creek.contains(Offset(x, y))) {
        continue;
      }
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, w, h),
          const Radius.circular(3),
        ),
        block,
      );
    }

    // Demand heat-map zones.
    if (heatmap) {
      final heat = Paint()..color = AppColors.mapOverlay;
      canvas.drawCircle(
        Offset(size.width * 0.3, size.height * 0.35),
        size.width * 0.18,
        heat,
      );
      canvas.drawCircle(
        Offset(size.width * 0.7, size.height * 0.55),
        size.width * 0.14,
        heat,
      );
    }

    // Route polyline.
    if (showRoute && pickup != null && destination != null) {
      final pts = [
        pickup!,
        ...stops,
        destination!,
      ].map((o) => Offset(o.dx * size.width, o.dy * size.height)).toList();
      final route = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (var i = 1; i < pts.length; i++) {
        final a = pts[i - 1];
        final b = pts[i];
        final c1 = Offset(
          a.dx + (b.dx - a.dx) * 0.2,
          a.dy + (b.dy - a.dy) * 0.9,
        );
        final c2 = Offset(
          a.dx + (b.dx - a.dx) * 0.8,
          a.dy + (b.dy - a.dy) * 0.1,
        );
        route.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, b.dx, b.dy);
      }
      final base = Paint()
        ..color = dimmed ? road : AppColors.primaryBlue.withValues(alpha: 0.25)
        ..strokeWidth = 8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(route, base);
      final line = Paint()
        ..color = dimmed ? AppColors.textSecondary : AppColors.primaryBlue
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      if (routeProgress >= 1) {
        canvas.drawPath(route, line);
      } else {
        for (final metric in route.computeMetrics()) {
          canvas.drawPath(
            metric.extractPath(0, metric.length * routeProgress),
            line,
          );
          canvas.drawPath(
            metric.extractPath(metric.length * routeProgress, metric.length),
            Paint()
              ..color = AppColors.primaryBlue.withValues(alpha: 0.35)
              ..strokeWidth = 4
              ..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.round,
          );
        }
      }
    }

    if (dimmed) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = land.withValues(alpha: 0.45),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) =>
      old.dark != dark ||
      old.pickup != pickup ||
      old.destination != destination ||
      old.stops != stops ||
      old.showRoute != showRoute ||
      old.routeProgress != routeProgress ||
      old.dimmed != dimmed ||
      old.heatmap != heatmap;
}

class _PickupPin extends StatelessWidget {
  const _PickupPin({required this.pulse});
  final bool pulse;
  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: AppColors.primaryBlue,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.4),
            blurRadius: 8,
          ),
        ],
      ),
    );
    if (!pulse) return dot;
    return _PulseRing(color: AppColors.primaryBlue, size: 90, child: dot);
  }
}

class _DestinationPin extends StatelessWidget {
  const _DestinationPin();
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: AppColors.dangerRed,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.dangerRed.withValues(alpha: 0.35),
                blurRadius: 8,
              ),
            ],
          ),
          child: const Icon(Icons.circle, size: 6, color: Colors.white),
        ),
        CustomPaint(
          size: const Size(12, 8),
          painter: _TrianglePainter(AppColors.dangerRed),
        ),
      ],
    );
  }
}

class _TrianglePainter extends CustomPainter {
  _TrianglePainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(p, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter old) => old.color != color;
}

class _StopPin extends StatelessWidget {
  const _StopPin({required this.index});
  final int index;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: AppColors.textSecondary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        '$index',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DriverMarker extends StatelessWidget {
  const _DriverMarker({required this.heading, required this.dimmed});
  final double heading;
  final bool dimmed;
  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: heading,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: dimmed ? AppColors.textSecondary : AppColors.primaryBlue,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.9),
              blurRadius: 6,
            ),
          ],
        ),
        child: const Icon(
          Icons.navigation_rounded,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }
}

class _CurrentLocationDot extends StatelessWidget {
  const _CurrentLocationDot({required this.pulse});
  final bool pulse;
  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: AppColors.primaryBlue,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
      ),
    );
    return _PulseRing(
      color: AppColors.primaryBlue,
      size: pulse ? 70 : 44,
      child: dot,
    );
  }
}

class _PulseRing extends StatefulWidget {
  const _PulseRing({
    required this.color,
    required this.size,
    required this.child,
  });
  final Color color;
  final double size;
  final Widget child;
  @override
  State<_PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<_PulseRing>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _c,
            builder: (_, _) => Container(
              width: widget.size * (0.3 + 0.7 * _c.value),
              height: widget.size * (0.3 + 0.7 * _c.value),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(alpha: 0.25 * (1 - _c.value)),
              ),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}
