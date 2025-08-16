import 'package:flutter/material.dart';

class MoMoLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final Color? primaryColor;
  final Color? secondaryColor;

  const MoMoLogo({
    super.key,
    this.size = 120,
    this.showText = true,
    this.primaryColor,
    this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final primary = primaryColor ?? Colors.green;
    final secondary = secondaryColor ?? Colors.blue;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo Container
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primary, secondary],
            ),
            boxShadow: [
              BoxShadow(
                color: primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: CustomPaint(
            painter: MoMoLogoPainter(
              primaryColor: primary,
              secondaryColor: secondary,
            ),
          ),
        ),
        
        if (showText) ...[
          const SizedBox(height: 16),
          // Mo-Mo Text
          const Text(
            "Mo-Mo",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          // Money Monitor Tagline
          Text(
            "MONEY MONITOR",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
              letterSpacing: 2.0,
            ),
          ),
        ],
      ],
    );
  }
}

class MoMoLogoPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;

  MoMoLogoPainter({
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..style = PaintingStyle.fill;

    final path = Path();
    final width = size.width;
    final height = size.height;
    final padding = width * 0.15;

    // Draw the main "M" shape
    final mPath = Path();
    
    // Left leg of M
    mPath.moveTo(padding, height - padding);
    mPath.lineTo(padding + width * 0.2, padding + height * 0.2);
    mPath.lineTo(padding + width * 0.3, padding + height * 0.4);
    mPath.lineTo(padding + width * 0.4, padding + height * 0.2);
    
    // Right leg of M (with upward arrow)
    mPath.lineTo(padding + width * 0.5, padding + height * 0.4);
    mPath.lineTo(padding + width * 0.6, padding + height * 0.2);
    mPath.lineTo(padding + width * 0.8, padding + height * 0.2);
    mPath.lineTo(padding + width * 0.85, padding); // Upward arrow tip

    // Draw the M with gradient
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [primaryColor, secondaryColor],
    );

    paint.shader = gradient.createShader(Rect.fromLTWH(0, 0, width, height));
    paint.strokeWidth = size.width * 0.08;
    canvas.drawPath(mPath, paint);

    // Draw internal circuit board lines
    final circuitPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.02
      ..color = primaryColor.withOpacity(0.7);

    // Horizontal circuit lines
    for (int i = 0; i < 3; i++) {
      final y = padding + height * 0.3 + i * height * 0.15;
      canvas.drawLine(
        Offset(padding + width * 0.1, y),
        Offset(padding + width * 0.7, y),
        circuitPaint,
      );
    }

    // Vertical circuit lines
    for (int i = 0; i < 2; i++) {
      final x = padding + width * 0.25 + i * width * 0.2;
      canvas.drawLine(
        Offset(x, padding + height * 0.2),
        Offset(x, padding + height * 0.6),
        circuitPaint,
      );
    }

    // Draw circuit nodes
    final nodePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = primaryColor;

    final nodePositions = [
      Offset(padding + width * 0.25, padding + height * 0.3),
      Offset(padding + width * 0.45, padding + height * 0.3),
      Offset(padding + width * 0.25, padding + height * 0.45),
      Offset(padding + width * 0.45, padding + height * 0.45),
    ];

    for (final position in nodePositions) {
      canvas.drawCircle(position, size.width * 0.015, nodePaint);
    }

    // Draw stock chart line on upper left
    final chartPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.015
      ..color = primaryColor;

    final chartPath = Path();
    chartPath.moveTo(padding - width * 0.05, padding + height * 0.15);
    chartPath.lineTo(padding - width * 0.02, padding + height * 0.12);
    chartPath.lineTo(padding, padding + height * 0.18);
    chartPath.lineTo(padding + width * 0.02, padding + height * 0.14);
    chartPath.lineTo(padding + width * 0.05, padding + height * 0.16);
    chartPath.lineTo(padding + width * 0.08, padding + height * 0.13);

    canvas.drawPath(chartPath, chartPaint);

    // Draw chart nodes
    final chartNodePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = primaryColor;

    final chartNodePositions = [
      Offset(padding - width * 0.05, padding + height * 0.15),
      Offset(padding - width * 0.02, padding + height * 0.12),
      Offset(padding, padding + height * 0.18),
      Offset(padding + width * 0.02, padding + height * 0.14),
      Offset(padding + width * 0.05, padding + height * 0.16),
      Offset(padding + width * 0.08, padding + height * 0.13),
    ];

    for (final position in chartNodePositions) {
      canvas.drawCircle(position, size.width * 0.008, chartNodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Alternative: Simple Logo with Icon
class MoMoSimpleLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final Color? primaryColor;
  final Color? secondaryColor;

  const MoMoSimpleLogo({
    super.key,
    this.size = 120,
    this.showText = true,
    this.primaryColor,
    this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final primary = primaryColor ?? Colors.green;
    final secondary = secondaryColor ?? Colors.blue;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Simple Logo Container
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primary, secondary],
            ),
            boxShadow: [
              BoxShadow(
                color: primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.trending_up,
              size: size * 0.5,
              color: Colors.white,
            ),
          ),
        ),
        
        if (showText) ...[
          const SizedBox(height: 16),
          // Mo-Mo Text
          const Text(
            "Mo-Mo",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          // Money Monitor Tagline
          Text(
            "MONEY MONITOR",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
              letterSpacing: 2.0,
            ),
          ),
        ],
      ],
    );
  }
}

// Enhanced Logo with Better M Shape
class MoMoEnhancedLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final Color? primaryColor;
  final Color? secondaryColor;

  const MoMoEnhancedLogo({
    super.key,
    this.size = 120,
    this.showText = true,
    this.primaryColor,
    this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final primary = primaryColor ?? Colors.green;
    final secondary = secondaryColor ?? Colors.blue;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Enhanced Logo Container
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primary, secondary],
            ),
            boxShadow: [
              BoxShadow(
                color: primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: CustomPaint(
            painter: MoMoEnhancedLogoPainter(
              primaryColor: primary,
              secondaryColor: secondary,
            ),
          ),
        ),
        
        if (showText) ...[
          const SizedBox(height: 16),
          // Mo-Mo Text
          const Text(
            "Mo-Mo",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          // Money Monitor Tagline
          Text(
            "MONEY MONITOR",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
              letterSpacing: 2.0,
            ),
          ),
        ],
      ],
    );
  }
}

class MoMoEnhancedLogoPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;

  MoMoEnhancedLogoPainter({
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final padding = width * 0.15;

    // Create gradient for the M
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [primaryColor, secondaryColor],
    );

    // Draw the main "M" shape with better proportions
    final mPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width * 0.06
      ..strokeCap = StrokeCap.round
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, width, height));

    final mPath = Path();
    
    // Start from bottom left
    mPath.moveTo(padding, height - padding);
    
    // Left leg up
    mPath.lineTo(padding + width * 0.15, padding + height * 0.25);
    
    // First dip
    mPath.lineTo(padding + width * 0.25, padding + height * 0.35);
    
    // Middle peak
    mPath.lineTo(padding + width * 0.35, padding + height * 0.25);
    
    // Second dip
    mPath.lineTo(padding + width * 0.45, padding + height * 0.35);
    
    // Right leg up with arrow
    mPath.lineTo(padding + width * 0.55, padding + height * 0.25);
    mPath.lineTo(padding + width * 0.65, padding + height * 0.25);
    mPath.lineTo(padding + width * 0.75, padding + height * 0.25);
    
    // Arrow tip pointing up and right
    mPath.lineTo(padding + width * 0.8, padding + height * 0.15);
    mPath.lineTo(padding + width * 0.75, padding + height * 0.25);
    mPath.lineTo(padding + width * 0.8, padding + height * 0.35);

    canvas.drawPath(mPath, mPaint);

    // Draw circuit board elements
    final circuitPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width * 0.015
      ..color = primaryColor.withOpacity(0.8);

    // Horizontal lines
    for (int i = 0; i < 2; i++) {
      final y = padding + height * 0.45 + i * height * 0.15;
      canvas.drawLine(
        Offset(padding + width * 0.1, y),
        Offset(padding + width * 0.7, y),
        circuitPaint,
      );
    }

    // Vertical lines
    for (int i = 0; i < 2; i++) {
      final x = padding + width * 0.3 + i * width * 0.2;
      canvas.drawLine(
        Offset(x, padding + height * 0.25),
        Offset(x, padding + height * 0.65),
        circuitPaint,
      );
    }

    // Circuit nodes
    final nodePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = primaryColor;

    final nodePositions = [
      Offset(padding + width * 0.3, padding + height * 0.45),
      Offset(padding + width * 0.5, padding + height * 0.45),
      Offset(padding + width * 0.3, padding + height * 0.6),
      Offset(padding + width * 0.5, padding + height * 0.6),
    ];

    for (final position in nodePositions) {
      canvas.drawCircle(position, width * 0.012, nodePaint);
    }

    // Stock chart line (simplified)
    final chartPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width * 0.012
      ..color = primaryColor;

    final chartPath = Path();
    chartPath.moveTo(padding - width * 0.08, padding + height * 0.2);
    chartPath.lineTo(padding - width * 0.04, padding + height * 0.15);
    chartPath.lineTo(padding, padding + height * 0.25);
    chartPath.lineTo(padding + width * 0.04, padding + height * 0.2);
    chartPath.lineTo(padding + width * 0.08, padding + height * 0.22);

    canvas.drawPath(chartPath, chartPaint);

    // Chart nodes
    final chartNodePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = primaryColor;

    final chartNodePositions = [
      Offset(padding - width * 0.08, padding + height * 0.2),
      Offset(padding - width * 0.04, padding + height * 0.15),
      Offset(padding, padding + height * 0.25),
      Offset(padding + width * 0.04, padding + height * 0.2),
      Offset(padding + width * 0.08, padding + height * 0.22),
    ];

    for (final position in chartNodePositions) {
      canvas.drawCircle(position, width * 0.006, chartNodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
