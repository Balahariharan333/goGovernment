import 'package:flutter/material.dart';
import 'dart:ui';
import '../utils/app_colors.dart';

enum MapState { list, directions, navigation }

class CommonMap extends StatelessWidget {
  final MapState mapState;
  final bool isWalkMode;
  final double? width;
  final double? height;

  const CommonMap({
    super.key,
    required this.mapState,
    required this.isWalkMode,
    this.width,
    this.height,
    
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? double.infinity,
      child: ClipRect(
        child: CustomPaint(
          painter: _MapPainter(
            mapState: mapState,
            isWalkMode: isWalkMode,
          ),
        ),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  final MapState mapState;
  final bool isWalkMode;

  _MapPainter({required this.mapState, required this.isWalkMode});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint bgPaint = Paint()..color = const Color(0xFFF9F6F0);
    canvas.drawRect(Offset.zero & size, bgPaint);

    final Paint roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 24.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final Paint roadBorderPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 26.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Draw Map grid streets
    final List<Path> roads = [
      // Street 1 (Horizontal)
      Path()
        ..moveTo(0, size.height * 0.45)
        ..lineTo(size.width, size.height * 0.45),
      // Street 2 (Vertical Left)
      Path()
        ..moveTo(size.width * 0.35, 0)
        ..lineTo(size.width * 0.35, size.height),
      // Street 3 (Vertical Right)
      Path()
        ..moveTo(size.width * 0.75, 0)
        ..lineTo(size.width * 0.75, size.height),
      // Street 4 (Diagonal shortcut)
      Path()
        ..moveTo(size.width * 0.35, size.height * 0.7)
        ..lineTo(size.width * 0.75, size.height * 0.2),
    ];

    for (final path in roads) {
      canvas.drawPath(path, roadBorderPaint);
      canvas.drawPath(path, roadPaint);
    }

    // Draw park block (Green)
    final Paint greenBlock = Paint()..color = const Color(0xFFE8F5E9);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.45, size.height * 0.15, size.width * 0.22, size.height * 0.22),
        const Radius.circular(8),
      ),
      greenBlock,
    );

    // Coordinate configurations
    final Offset userLoc = Offset(size.width * 0.35, size.height * 0.7);
    final Offset destination = Offset(size.width * 0.35, size.height * 0.25);

    // Draw active path route if in Directions or Active Navigation mode
    if (mapState == MapState.directions || mapState == MapState.navigation) {
      final Paint routePaint = Paint()
        ..color = AppColors.black
        ..strokeWidth = 5.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      // Solid line for driving, Dotted line for walking
      if (isWalkMode) {
        // Dotted path implementation
        final Path routePath = Path()
          ..moveTo(userLoc.dx, userLoc.dy)
          ..lineTo(destination.dx, destination.dy);

        final double dashWidth = 6.0;
        final double dashSpace = 6.0;
        double distance = 0.0;
        final PathMetrics metrics = routePath.computeMetrics();

        for (final PathMetric metric in metrics) {
          while (distance < metric.length) {
            canvas.drawPath(
              metric.extractPath(distance, distance + dashWidth),
              routePaint,
            );
            distance += dashWidth + dashSpace;
          }
        }
      } else {
        // Solid driving path
        canvas.drawLine(userLoc, destination, routePaint);
      }
    }

    // Draw markers
    final Paint pinPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    if (mapState == MapState.list) {
      // Draw multiple pins
      final List<Offset> mockPins = [
        destination,
        Offset(size.width * 0.15, size.height * 0.35),
        Offset(size.width * 0.75, size.height * 0.55),
        Offset(size.width * 0.25, size.height * 0.6),
        Offset(size.width * 0.55, size.height * 0.8),
      ];

      // Draw normal pins
      for (final pin in mockPins) {
        canvas.drawCircle(pin, 8.0, pinPaint);
        canvas.drawCircle(pin, 14.0, Paint()..color = AppColors.primary.withValues(alpha: 0.2));
      }

      // Draw center active user locator indicator
      final Offset userPin = Offset(size.width * 0.5, size.height * 0.45);
      canvas.drawCircle(userPin, 6.0, Paint()..color = Colors.blue);
      canvas.drawCircle(userPin, 12.0, Paint()..color = Colors.blue.withValues(alpha: 0.25));
    } else {
      // Directions & Navigation Mode: Draw Start (orange dot) & Destination (locator pin)
      // 1. Start point (User location)
      canvas.drawCircle(userLoc, 10.0, Paint()..color = const Color(0xFFFF9800));
      canvas.drawCircle(userLoc, 18.0, Paint()..color = const Color(0xFFFF9800).withValues(alpha: 0.25));

      // 2. Destination locator pin
      canvas.drawCircle(destination, 8.0, pinPaint);
      canvas.drawCircle(destination, 15.0, Paint()..color = AppColors.primary.withValues(alpha: 0.2));

      // 3. User navigation cursor pointer (arrowhead chevron) in active navigation mode
      if (mapState == MapState.navigation) {
        final Paint cursorPaint = Paint()
          ..color = AppColors.primary
          ..style = PaintingStyle.fill;

        final Path arrowPath = Path();
        final double cursorX = userLoc.dx;
        final double cursorY = userLoc.dy;

        // Draw arrow pointing straight along vertical road
        arrowPath.moveTo(cursorX, cursorY - 14);
        arrowPath.lineTo(cursorX - 8, cursorY + 6);
        arrowPath.lineTo(cursorX, cursorY);
        arrowPath.lineTo(cursorX + 8, cursorY + 6);
        arrowPath.close();

        canvas.drawPath(arrowPath, cursorPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MapPainter oldDelegate) {
    return oldDelegate.mapState != mapState || oldDelegate.isWalkMode != isWalkMode;
  }
}
