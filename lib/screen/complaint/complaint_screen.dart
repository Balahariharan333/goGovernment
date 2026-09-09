import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../utils/responsive_helper.dart';
import '../../widget/custom_text.dart';
import '../../constants/route_constants.dart';
import '../../widget/motion/tilt_3d_card.dart';
import '../../widget/motion/fade_slide_transition.dart';

class ComplaintCategoryData {
  final String title;
  final String description;
  final Color iconBgColor;
  final Widget icon;
  final String categoryKey;

  const ComplaintCategoryData({
    required this.title,
    required this.description,
    required this.iconBgColor,
    required this.icon,
    required this.categoryKey,
  });
}

class ComplaintScreen extends StatelessWidget {
  const ComplaintScreen({super.key});

  static final List<ComplaintCategoryData> _categories = [
    ComplaintCategoryData(
      title: 'Roads &\nTransportation',
      description: 'Report potholes, road\ndamage, traffic issues',
      iconBgColor: const Color(0xFFFFDDD2),
      icon: CustomPaint(
        size: const Size(26, 26),
        painter: RoadIconPainter(color: const Color(0xFF1E293B)),
      ),
      categoryKey: 'Roads & Transportation',
    ),
    ComplaintCategoryData(
      title: 'Garbage & Waste\nManagement',
      description: 'Report garbage, overflow,\nsegregation issues',
      iconBgColor: const Color(0xFFDCFCE7),
      icon: const Icon(
        Icons.delete_outline_rounded,
        color: Color(0xFF15803D),
        size: 26,
      ),
      categoryKey: 'Garbage & Waste Management',
    ),
    ComplaintCategoryData(
      title: 'Streetlights &\nElectricity',
      description: 'Report faulty streetlights,\npower issues',
      iconBgColor: const Color(0xFFFEF3C7),
      icon: const Icon(
        Icons.lightbulb_rounded,
        color: Color(0xFFD97706),
        size: 26,
      ),
      categoryKey: 'Streetlights & Electricity',
    ),
    ComplaintCategoryData(
      title: 'Water\nSupply',
      description: 'Report water shortage,\nleakage, low pressure',
      iconBgColor: const Color(0xFFDBEAFE),
      icon: const Icon(
        Icons.water_drop_rounded,
        color: Color(0xFF2563EB),
        size: 26,
      ),
      categoryKey: 'Water Supply',
    ),
    ComplaintCategoryData(
      title: 'Drainage &\nSewage',
      description: 'Report blockages,\noverflow, sewer issues',
      iconBgColor: const Color(0xFFEDE9FE),
      icon: CustomPaint(
        size: const Size(26, 26),
        painter: DrainageIconPainter(color: const Color(0xFF7C3AED)),
      ),
      categoryKey: 'Drainage & Sewage',
    ),
    ComplaintCategoryData(
      title: 'Cleanliness &\nSanitation',
      description: 'Report unclean areas,\npublic hygiene issues',
      iconBgColor: const Color(0xFFFFE4E6),
      icon: const Icon(
        Icons.cleaning_services_rounded,
        color: Color(0xFFBE123C),
        size: 26,
      ),
      categoryKey: 'Cleanliness & Sanitation',
    ),
    ComplaintCategoryData(
      title: 'Parks &\nPublic Spaces',
      description: 'Report park issues,\nplaygrounds, amenities',
      iconBgColor: const Color(0xFFDCFCE7),
      icon: const Icon(
        Icons.park_rounded,
        color: Color(0xFF166534),
        size: 26,
      ),
      categoryKey: 'Parks & Public Spaces',
    ),
    ComplaintCategoryData(
      title: 'Environmental\nIssues',
      description: 'Report air pollution,\nnoise, greenery concerns',
      iconBgColor: const Color(0xFFF3E8FF),
      icon: const Icon(
        Icons.eco_rounded,
        color: Color(0xFF9333EA),
        size: 26,
      ),
      categoryKey: 'Environmental Issues',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Header Row with Title, Subtitle, and 3D Clipboard Badge
        FadeSlideTransitionWidget(
          index: 0,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText.header(
                      'Complaints',
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F172A),
                    ),
                    SizedBox(height: Responsive.h(6)),
                    CustomText.body(
                      'Report civic issues and help us build a better community',
                      fontSize: 13,
                      color: const Color(0xFF64748B),
                      height: 1.35,
                    ),
                  ],
                ),
              ),
              SizedBox(width: Responsive.w(8)),
              const _HeaderClipboardIllustration(),
            ],
          ),
        ),
        SizedBox(height: Responsive.h(22)),

        // 1. Grid of Category Cards (Staggered Entrance Animation)
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: Responsive.w(14),
          mainAxisSpacing: Responsive.w(14),
          childAspectRatio: 0.76,
          children: _categories.asMap().entries.map((entry) {
            final int index = entry.key;
            final item = entry.value;
            return FadeSlideTransitionWidget(
              index: index + 1,
              child: _buildCategoryCard(context, item),
            );
          }).toList(),
        ),
        SizedBox(height: Responsive.h(20)),
      ],
    );
  }

  Widget _buildCategoryCard(BuildContext context, ComplaintCategoryData item) {
    final radius = BorderRadius.circular(Responsive.w(24));

    return Tilt3DCard(
      borderRadius: radius,
      onTap: () {
        Navigator.of(context).pushNamed(
          RouteConstants.addComplaint,
          arguments: item.categoryKey,
        );
      },
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF97316).withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            children: [
              // Subtle curved accent circle in bottom-right corner
              Positioned(
                bottom: -Responsive.w(18),
                right: -Responsive.w(18),
                child: Container(
                  width: Responsive.w(82),
                  height: Responsive.w(82),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF5F0),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              // Circular peach arrow button
              Positioned(
                bottom: Responsive.h(12),
                right: Responsive.w(12),
                child: Container(
                  width: Responsive.w(28),
                  height: Responsive.w(28),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFECE5),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: Responsive.w(15),
                      color: const Color(0xFFEA580C),
                    ),
                  ),
                ),
              ),

              // Card content column
              Padding(
                padding: EdgeInsets.all(Responsive.w(14)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Circular Pastel Icon Badge
                    Container(
                      width: Responsive.w(48),
                      height: Responsive.w(48),
                      decoration: BoxDecoration(
                        color: item.iconBgColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(child: item.icon),
                    ),
                    SizedBox(height: Responsive.h(12)),

                    // Title
                    CustomText.header(
                      item.title,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                      height: 1.22,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: Responsive.h(5)),

                    // Subtitle description
                    CustomText.body(
                      item.description,
                      fontSize: 11,
                      color: const Color(0xFF64748B),
                      height: 1.3,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 3D Clipboard Illustration shown in the Header
class _HeaderClipboardIllustration extends StatelessWidget {
  const _HeaderClipboardIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: Responsive.w(86),
      height: Responsive.h(90),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Sparkle accent ray 1 (top-right)
          Positioned(
            top: Responsive.h(6),
            right: Responsive.w(2),
            child: Transform.rotate(
              angle: math.pi / 4,
              child: Container(
                width: Responsive.w(8),
                height: Responsive.h(2.4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8A65),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          // Sparkle accent ray 2 (left)
          Positioned(
            top: Responsive.h(20),
            left: -Responsive.w(4),
            child: Transform.rotate(
              angle: -math.pi / 5,
              child: Container(
                width: Responsive.w(7),
                height: Responsive.h(2.2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8A65),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          // Sparkle accent ray 3 (bottom-right)
          Positioned(
            bottom: Responsive.h(12),
            right: -Responsive.w(2),
            child: Transform.rotate(
              angle: -math.pi / 3,
              child: Container(
                width: Responsive.w(6),
                height: Responsive.h(2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8A65),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),

          // Main Clipboard rotated ~6 degrees
          Transform.rotate(
            angle: 0.10,
            child: Container(
              width: Responsive.w(66),
              height: Responsive.h(78),
              decoration: BoxDecoration(
                color: const Color(0xFFFFECE5),
                borderRadius: BorderRadius.circular(Responsive.w(16)),
                border: Border.all(
                  color: const Color(0xFFFFCCBD),
                  width: Responsive.w(1.5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF97316).withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  // Clip on top
                  Positioned(
                    top: -Responsive.h(5),
                    child: Container(
                      width: Responsive.w(24),
                      height: Responsive.h(11),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF8A65),
                        borderRadius: BorderRadius.circular(Responsive.w(6)),
                      ),
                    ),
                  ),

                  // Inner Paper
                  Positioned(
                    top: Responsive.h(10),
                    left: Responsive.w(6),
                    right: Responsive.w(6),
                    bottom: Responsive.h(6),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.w(6),
                        vertical: Responsive.h(8),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(Responsive.w(10)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: Responsive.w(30),
                            height: Responsive.h(3.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD4C7),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          SizedBox(height: Responsive.h(5)),
                          Container(
                            width: Responsive.w(38),
                            height: Responsive.h(3.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE0D6),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          SizedBox(height: Responsive.h(5)),
                          Container(
                            width: Responsive.w(26),
                            height: Responsive.h(3.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE0D6),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          SizedBox(height: Responsive.h(5)),
                          Container(
                            width: Responsive.w(18),
                            height: Responsive.h(3.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE0D6),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Exclamation Alert Badge on bottom right
          Positioned(
            bottom: Responsive.h(2),
            right: Responsive.w(0),
            child: Container(
              width: Responsive.w(26),
              height: Responsive.w(26),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5722),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: Responsive.w(2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF5722).withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: CustomText.title(
                  '!',
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
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
