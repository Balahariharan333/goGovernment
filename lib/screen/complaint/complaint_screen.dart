import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../utils/app_colors.dart';
import '../../utils/responsive_helper.dart';
import '../../widget/custom_text.dart';
import 'add_complaint_screen.dart';

class ComplaintScreen extends StatelessWidget {
  const ComplaintScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomText.header(
          'Complaints',
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        SizedBox(height: Responsive.h(20)),
        // 1. Grid of Category Cards
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: Responsive.w(16),
          mainAxisSpacing: Responsive.w(16),
          childAspectRatio: 0.9,
          children: [
            _buildCategoryCard(
              context,
              label: 'Roads &\nTransportation',
              painter: RoadIconPainter(color: AppColors.black),
            ),
            _buildCategoryCard(
              context,
              label: 'Garbage & Waste\nManagement',
              painter: GarbageIconPainter(color: AppColors.black),
            ),
            _buildCategoryCard(
              context,
              label: 'Streetlights &\nElectricity',
              painter: LightbulbIconPainter(color: AppColors.black),
            ),
            _buildCategoryCard(
              context,
              label: 'Water\nSupply',
              painter: WaterIconPainter(color: AppColors.black),
            ),
            _buildCategoryCard(
              context,
              label: 'Drainage &\nSewage',
              painter: DrainageIconPainter(color: AppColors.black),
            ),
            _buildCategoryCard(
              context,
              label: 'Cleanliness &\nSanitation',
              painter: CleanlinessIconPainter(color: AppColors.black),
            ),
            _buildCategoryCard(
              context,
              label: 'Parks &\nPublic Spaces',
              painter: ParksIconPainter(color: AppColors.black),
            ),
            _buildCategoryCard(
              context,
              label: 'Environmental\nIssues',
              painter: EnvironmentalIconPainter(color: AppColors.black),
            ),
          ],
        ),
        SizedBox(height: Responsive.h(28)),

        // 2. Floating Pill Button "+ Complaint"
        Container(
          height: Responsive.h(52),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF6F3), // Light cream/peach fill matching the screenshot
            borderRadius: BorderRadius.circular(Responsive.w(26)),
            border: Border.all(
              color: AppColors.primary,
              width: Responsive.w(1.5),
            ),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddComplaintScreen(),
                ),
              );
            },
            borderRadius: BorderRadius.circular(Responsive.w(26)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add,
                  color: AppColors.primary,
                  size: Responsive.w(24),
                ),
                SizedBox(width: Responsive.w(6)),
                CustomText.title(
                  'Complaint',
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(BuildContext context, {required String label, required CustomPainter painter}) {
    final cleanCategory = label.replaceAll('\n', ' ');
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddComplaintScreen(category: cleanCategory),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(Responsive.w(28)),
          border: Border.all(
            color: AppColors.outliner,
            width: Responsive.w(1.5),
          ),
        ),
        padding: EdgeInsets.symmetric(horizontal: Responsive.w(12), vertical: Responsive.h(16)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon Container circle
            Container(
              width: Responsive.w(58),
              height: Responsive.h(58),
              decoration: const BoxDecoration(
                color: Color(0xFFFBF8F6), // Extremely soft gray/cream fill
                shape: BoxShape.circle,
              ),
              child: Center(
                child: CustomPaint(
                  size: Size(Responsive.w(28), Responsive.h(28)),
                  painter: painter,
                ),
              ),
            ),
            SizedBox(height: Responsive.h(14)),
            // Label text
            CustomText.title(
              label,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ================= CUSTOM PAINTERS FOR THE FIGMA ICONS =================

class RoadIconPainter extends CustomPainter {
  final Color color;
  RoadIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    final double w = size.width;
    final double h = size.height;

    // Road left edge line (perspective layout)
    canvas.drawLine(Offset(w * 0.36, h * 0.1), Offset(w * 0.16, h * 0.9), paint);
    // Road right edge line (perspective layout)
    canvas.drawLine(Offset(w * 0.64, h * 0.1), Offset(w * 0.84, h * 0.9), paint);

    // Dashed center lane line
    paint.strokeWidth = 2.0;
    canvas.drawLine(Offset(w * 0.5, h * 0.18), Offset(w * 0.5, h * 0.34), paint);
    canvas.drawLine(Offset(w * 0.5, h * 0.46), Offset(w * 0.5, h * 0.62), paint);
    canvas.drawLine(Offset(w * 0.5, h * 0.74), Offset(w * 0.5, h * 0.9), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GarbageIconPainter extends CustomPainter {
  final Color color;
  GarbageIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final double w = size.width;
    final double h = size.height;

    // Lid handle curve
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.38, h * 0.22)
        ..quadraticBezierTo(w * 0.5, h * 0.12, w * 0.62, h * 0.22),
      paint,
    );

    // Lid horizontal bar
    canvas.drawLine(Offset(w * 0.24, h * 0.24), Offset(w * 0.76, h * 0.24), paint);

    // Bin body
    final bodyPath = Path()
      ..moveTo(w * 0.29, h * 0.26)
      ..lineTo(w * 0.34, h * 0.84)
      ..quadraticBezierTo(w * 0.36, h * 0.9, w * 0.44, h * 0.9)
      ..lineTo(w * 0.56, h * 0.9)
      ..quadraticBezierTo(w * 0.64, h * 0.9, w * 0.66, h * 0.84)
      ..lineTo(w * 0.71, h * 0.26);
    canvas.drawPath(bodyPath, paint);

    // Vertical grooves in the can body
    canvas.drawLine(Offset(w * 0.43, h * 0.36), Offset(w * 0.45, h * 0.76), paint);
    canvas.drawLine(Offset(w * 0.57, h * 0.36), Offset(w * 0.55, h * 0.76), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LightbulbIconPainter extends CustomPainter {
  final Color color;
  LightbulbIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final double w = size.width;
    final double h = size.height;

    // Bulb outline shape
    final bulbPath = Path()
      ..moveTo(w * 0.34, h * 0.62)
      ..cubicTo(w * 0.2, h * 0.52, w * 0.22, h * 0.2, w * 0.5, h * 0.2)
      ..cubicTo(w * 0.78, h * 0.2, w * 0.8, h * 0.52, w * 0.66, h * 0.62)
      ..lineTo(w * 0.63, h * 0.76)
      ..lineTo(w * 0.37, h * 0.76)
      ..close();
    canvas.drawPath(bulbPath, paint);

    // Screw lines on the base
    canvas.drawLine(Offset(w * 0.39, h * 0.82), Offset(w * 0.61, h * 0.82), paint);
    canvas.drawLine(Offset(w * 0.42, h * 0.88), Offset(w * 0.58, h * 0.88), paint);

    // Lightning bolt in center
    final boltPath = Path()
      ..moveTo(w * 0.54, h * 0.33)
      ..lineTo(w * 0.43, h * 0.49)
      ..lineTo(w * 0.51, h * 0.49)
      ..lineTo(w * 0.46, h * 0.66);
    canvas.drawPath(boltPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class WaterIconPainter extends CustomPainter {
  final Color color;
  WaterIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final double w = size.width;
    final double h = size.height;

    void drawDrop(Canvas canvas, double cx, double cy, double scale) {
      final dropPath = Path()
        ..moveTo(cx, cy - 9 * scale)
        ..cubicTo(cx + 7 * scale, cy - 2 * scale, cx + 7 * scale, cy + 7 * scale, cx, cy + 7 * scale)
        ..cubicTo(cx - 7 * scale, cy + 7 * scale, cx - 7 * scale, cy - 2 * scale, cx, cy - 9 * scale)
        ..close();
      canvas.drawPath(dropPath, paint);
    }

    // Triangular layout of three drops
    drawDrop(canvas, w * 0.5, h * 0.32, 0.95);
    drawDrop(canvas, w * 0.35, h * 0.66, 0.95);
    drawDrop(canvas, w * 0.65, h * 0.66, 0.95);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DrainageIconPainter extends CustomPainter {
  final Color color;
  DrainageIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;
    final double cy = h / 2;
    final double r = w * 0.22;

    // Microbe main circle body
    canvas.drawCircle(Offset(cx, cy), r, paint);

    // Spikes around body (8 spikes)
    for (int i = 0; i < 8; i++) {
      double angle = i * math.pi / 4;
      double startX = cx + r * math.cos(angle);
      double startY = cy + r * math.sin(angle);
      double endX = cx + (r + 7) * math.cos(angle);
      double endY = cy + (r + 7) * math.sin(angle);

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);

      // Solid round cap on each spike
      paint.style = PaintingStyle.fill;
      canvas.drawCircle(Offset(endX, endY), 2.2, paint);
      paint.style = PaintingStyle.stroke;
    }

    // Microbe inner texture
    canvas.drawCircle(Offset(cx - 4, cy - 4), 1.8, paint);
    canvas.drawCircle(Offset(cx + 5, cy + 2), 1.4, paint);
    canvas.drawCircle(Offset(cx - 1, cy + 5), 1.0, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CleanlinessIconPainter extends CustomPainter {
  final Color color;
  CleanlinessIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final double w = size.width;
    final double h = size.height;

    // Stylized sanitation bag / loop
    final path = Path()
      ..moveTo(w * 0.44, h * 0.28)
      ..cubicTo(w * 0.24, h * 0.34, w * 0.18, h * 0.66, w * 0.34, h * 0.78)
      ..cubicTo(w * 0.5, h * 0.88, w * 0.74, h * 0.82, w * 0.78, h * 0.6)
      ..cubicTo(w * 0.8, h * 0.44, w * 0.64, h * 0.34, w * 0.58, h * 0.28)
      ..lineTo(w * 0.63, h * 0.2) // loop tip
      ..lineTo(w * 0.51, h * 0.22)
      ..close();
    canvas.drawPath(path, paint);

    // Cleanliness tie point detail
    canvas.drawCircle(Offset(w * 0.55, h * 0.26), 2.4, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ParksIconPainter extends CustomPainter {
  final Color color;
  ParksIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final double w = size.width;
    final double h = size.height;

    // Pine tree outline on the right
    canvas.drawLine(Offset(w * 0.75, h * 0.52), Offset(w * 0.75, h * 0.82), paint);
    final treePath = Path()
      ..moveTo(w * 0.75, h * 0.24)
      ..lineTo(w * 0.87, h * 0.52)
      ..lineTo(w * 0.63, h * 0.52)
      ..close();
    canvas.drawPath(treePath, paint);

    // Bench outline on the left
    canvas.drawLine(Offset(w * 0.18, h * 0.64), Offset(w * 0.52, h * 0.64), paint); // seat
    canvas.drawLine(Offset(w * 0.22, h * 0.5), Offset(w * 0.48, h * 0.5), paint); // backrest
    canvas.drawLine(Offset(w * 0.26, h * 0.5), Offset(w * 0.26, h * 0.64), paint); // support vertical
    canvas.drawLine(Offset(w * 0.44, h * 0.5), Offset(w * 0.44, h * 0.64), paint); // support vertical
    canvas.drawLine(Offset(w * 0.2, h * 0.64), Offset(w * 0.2, h * 0.82), paint); // leg
    canvas.drawLine(Offset(w * 0.5, h * 0.64), Offset(w * 0.5, h * 0.82), paint); // leg

    // Sun icon in the background
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.35, h * 0.3), 3.0, paint);
    paint.style = PaintingStyle.stroke;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class EnvironmentalIconPainter extends CustomPainter {
  final Color color;
  EnvironmentalIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;
    final double cy = h / 2;
    final double r = w * 0.26;

    // Recirculating arc segments
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      -math.pi * 0.1,
      math.pi * 0.8,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      math.pi * 0.9,
      math.pi * 0.8,
      false,
      paint,
    );

    // Arrow tips
    double angle1 = math.pi * 0.7;
    double tx1 = cx + r * math.cos(angle1);
    double ty1 = cy + r * math.sin(angle1);
    final arrow1 = Path()
      ..moveTo(tx1 - 5, ty1)
      ..lineTo(tx1, ty1)
      ..lineTo(tx1 - 1, ty1 - 6);
    canvas.drawPath(arrow1, paint);

    double angle2 = -math.pi * 0.3;
    double tx2 = cx + r * math.cos(angle2);
    double ty2 = cy + r * math.sin(angle2);
    final arrow2 = Path()
      ..moveTo(tx2 + 5, ty2)
      ..lineTo(tx2, ty2)
      ..lineTo(tx2 + 1, ty2 + 6);
    canvas.drawPath(arrow2, paint);

    // Sparkle lines in center
    canvas.drawLine(Offset(cx - 3, cy - 3), Offset(cx + 3, cy + 3), paint);
    canvas.drawLine(Offset(cx + 3, cy - 3), Offset(cx - 3, cy + 3), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
