import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Custom painted icons for vehicle metrics
class CustomIcons {
  CustomIcons._();

  /// HarvTech logo - uses the actual app icon image
  static Widget harvTechLogoImage({double size = 24}) {
    return Image.asset(
      'assets/icon/app_icon.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }

  /// HarvTech logo - stylized painted version (coral arc + track shape)
  static Widget harvTechLogo({double size = 24, Color color = Colors.orange}) {
    return CustomPaint(
      size: Size(size, size),
      painter: _HarvTechLogoPainter(color),
    );
  }

  /// Bluetooth scan icon - Bluetooth with radar waves
  static Widget bluetoothScan({double size = 24, Color color = Colors.white}) {
    return CustomPaint(
      size: Size(size, size),
      painter: _BluetoothScanPainter(color),
    );
  }

  /// Simulation/test icon - flask with gear
  static Widget simulation({double size = 24, Color color = Colors.cyan}) {
    return CustomPaint(
      size: Size(size, size),
      painter: _SimulationIconPainter(color),
    );
  }

  /// Battery icon with voltage indicator
  static Widget battery({double size = 24, Color color = Colors.amber}) {
    return CustomPaint(
      size: Size(size, size),
      painter: _BatteryIconPainter(color),
    );
  }

  /// RPM tachometer icon
  static Widget rpm({double size = 24, Color color = Colors.blue}) {
    return CustomPaint(
      size: Size(size, size),
      painter: _RpmIconPainter(color),
    );
  }

  /// Power/KW lightning bolt icon
  static Widget power({double size = 24, Color color = Colors.orange}) {
    return CustomPaint(
      size: Size(size, size),
      painter: _PowerIconPainter(color),
    );
  }

  /// Current/Amperage icon
  static Widget current({double size = 24, Color color = Colors.purple}) {
    return CustomPaint(
      size: Size(size, size),
      painter: _CurrentIconPainter(color),
    );
  }

  /// Temperature icon
  static Widget temperature({double size = 24, Color color = Colors.red}) {
    return CustomPaint(
      size: Size(size, size),
      painter: _TemperatureIconPainter(color),
    );
  }

  /// Speed icon
  static Widget speed({double size = 24, Color color = Colors.teal}) {
    return CustomPaint(
      size: Size(size, size),
      painter: _SpeedIconPainter(color),
    );
  }
}

class _BatteryIconPainter extends CustomPainter {
  final Color color;
  _BatteryIconPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Battery body
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.1,
        size.height * 0.2,
        size.width * 0.7,
        size.height * 0.6,
      ),
      Radius.circular(size.width * 0.08),
    );
    canvas.drawRRect(bodyRect, paint);

    // Battery terminal
    final terminalRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.8,
        size.height * 0.35,
        size.width * 0.12,
        size.height * 0.3,
      ),
      Radius.circular(size.width * 0.04),
    );
    canvas.drawRRect(terminalRect, fillPaint);

    // Lightning bolt inside
    final path = Path();
    path.moveTo(size.width * 0.5, size.height * 0.28);
    path.lineTo(size.width * 0.35, size.height * 0.5);
    path.lineTo(size.width * 0.45, size.height * 0.5);
    path.lineTo(size.width * 0.4, size.height * 0.72);
    path.lineTo(size.width * 0.6, size.height * 0.45);
    path.lineTo(size.width * 0.5, size.height * 0.45);
    path.lineTo(size.width * 0.55, size.height * 0.28);
    path.close();
    canvas.drawPath(path, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RpmIconPainter extends CustomPainter {
  final Color color;
  _RpmIconPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;

    // Outer arc (tachometer gauge)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      2.4, // Start angle
      2.0, // Sweep angle
      false,
      paint,
    );

    // Tick marks
    for (int i = 0; i <= 5; i++) {
      final angle = 2.4 + (i * 0.4);
      final outerPoint = Offset(
        center.dx + radius * 1.0 * math.cos(angle),
        center.dy + radius * 1.0 * math.sin(angle),
      );
      final innerPoint = Offset(
        center.dx + radius * 0.75 * math.cos(angle),
        center.dy + radius * 0.75 * math.sin(angle),
      );
      canvas.drawLine(
          innerPoint, outerPoint, paint..strokeWidth = size.width * 0.05);
    }

    // Needle
    const needleAngle = 3.2; // Points to middle-high
    final needleEnd = Offset(
      center.dx + radius * 0.65 * math.cos(needleAngle),
      center.dy + radius * 0.65 * math.sin(needleAngle),
    );
    canvas.drawLine(center, needleEnd, paint..strokeWidth = size.width * 0.08);

    // Center dot
    canvas.drawCircle(center, size.width * 0.08, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PowerIconPainter extends CustomPainter {
  final Color color;
  _PowerIconPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Lightning bolt shape
    final path = Path();
    path.moveTo(size.width * 0.55, size.height * 0.05);
    path.lineTo(size.width * 0.2, size.height * 0.45);
    path.lineTo(size.width * 0.42, size.height * 0.45);
    path.lineTo(size.width * 0.35, size.height * 0.95);
    path.lineTo(size.width * 0.8, size.height * 0.42);
    path.lineTo(size.width * 0.55, size.height * 0.42);
    path.lineTo(size.width * 0.65, size.height * 0.05);
    path.close();

    canvas.drawPath(path, paint);

    // Add "kW" text effect with small dots
    final dotPaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width * 0.75, size.height * 0.85),
      size.width * 0.04,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CurrentIconPainter extends CustomPainter {
  final Color color;
  _CurrentIconPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.1
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Draw "A" shape representing Amperage
    // Circle with wave inside (AC current symbol)
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.38;

    // Outer circle
    canvas.drawCircle(center, radius, paint);

    // Sine wave inside
    final wavePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round;

    final wavePath = Path();
    wavePath.moveTo(size.width * 0.25, size.height * 0.5);
    wavePath.quadraticBezierTo(
      size.width * 0.38,
      size.height * 0.25,
      size.width * 0.5,
      size.height * 0.5,
    );
    wavePath.quadraticBezierTo(
      size.width * 0.62,
      size.height * 0.75,
      size.width * 0.75,
      size.height * 0.5,
    );
    canvas.drawPath(wavePath, wavePaint);

    // Arrow indicators
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.15),
      size.width * 0.06,
      fillPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.85),
      size.width * 0.06,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TemperatureIconPainter extends CustomPainter {
  final Color color;
  _TemperatureIconPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Thermometer body
    final bodyPath = Path();
    bodyPath.moveTo(size.width * 0.4, size.height * 0.15);
    bodyPath.lineTo(size.width * 0.4, size.height * 0.6);
    bodyPath.arcToPoint(
      Offset(size.width * 0.6, size.height * 0.6),
      radius: Radius.circular(size.width * 0.2),
      clockwise: false,
    );
    bodyPath.lineTo(size.width * 0.6, size.height * 0.15);
    bodyPath.arcToPoint(
      Offset(size.width * 0.4, size.height * 0.15),
      radius: Radius.circular(size.width * 0.1),
      clockwise: true,
    );
    canvas.drawPath(bodyPath, paint);

    // Bulb
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.75),
      size.width * 0.18,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.75),
      size.width * 0.12,
      fillPaint,
    );

    // Mercury level
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.35),
      Offset(size.width * 0.5, size.height * 0.65),
      Paint()
        ..color = color
        ..strokeWidth = size.width * 0.08
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SpeedIconPainter extends CustomPainter {
  final Color color;
  _SpeedIconPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Speedometer arc
    final center = Offset(size.width / 2, size.height * 0.55);
    final radius = size.width * 0.4;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.14159, // PI - start from left
      3.14159, // PI - half circle
      false,
      paint,
    );

    // Speed lines (motion effect)
    for (int i = 0; i < 3; i++) {
      final yOffset = size.height * (0.7 + i * 0.08);
      canvas.drawLine(
        Offset(size.width * 0.15, yOffset),
        Offset(size.width * (0.3 - i * 0.05), yOffset),
        paint..strokeWidth = size.width * 0.05,
      );
    }

    // Needle
    canvas.drawLine(
      center,
      Offset(size.width * 0.7, size.height * 0.3),
      paint..strokeWidth = size.width * 0.06,
    );

    // Center dot
    canvas.drawCircle(center, size.width * 0.08, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// HarvTech Logo - Coral arc on top, dark rounded track shape below
class _HarvTechLogoPainter extends CustomPainter {
  final Color color;
  _HarvTechLogoPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    // Coral/red color for the top arc
    final arcPaint = Paint()
      ..color = const Color(0xFFE25D4E) // Coral red
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.10
      ..strokeCap = StrokeCap.round;

    // Dark color for the track shape (use provided color or default to dark)
    final trackPaint = Paint()
      ..color = color == Colors.orange ? const Color(0xFF2D2D2D) : color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.10
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Top arc - curved like a smile upside down with extended ends
    final arcPath = Path();
    arcPath.moveTo(size.width * 0.15, size.height * 0.28);
    arcPath.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.08,
      size.width * 0.85,
      size.height * 0.28,
    );
    canvas.drawPath(arcPath, arcPaint);

    // Bottom rounded track/rectangle shape with chamfered corners
    final trackPath = Path();
    // Start from top-left, going clockwise
    trackPath.moveTo(size.width * 0.30, size.height * 0.40);
    // Top edge to top-right chamfer
    trackPath.lineTo(size.width * 0.70, size.height * 0.40);
    // Top-right chamfer
    trackPath.lineTo(size.width * 0.85, size.height * 0.50);
    // Right edge
    trackPath.lineTo(size.width * 0.85, size.height * 0.75);
    // Bottom-right chamfer
    trackPath.lineTo(size.width * 0.70, size.height * 0.90);
    // Bottom edge
    trackPath.lineTo(size.width * 0.30, size.height * 0.90);
    // Bottom-left chamfer
    trackPath.lineTo(size.width * 0.15, size.height * 0.75);
    // Left edge
    trackPath.lineTo(size.width * 0.15, size.height * 0.50);
    // Top-left chamfer back to start
    trackPath.close();
    canvas.drawPath(trackPath, trackPaint);

    // Inner rounded rectangle (the hole in the track)
    final innerPaint = Paint()
      ..color = color == Colors.orange ? const Color(0xFF2D2D2D) : color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.06
      ..strokeCap = StrokeCap.round;

    final innerPath = Path();
    innerPath.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.32,
        size.height * 0.52,
        size.width * 0.36,
        size.height * 0.26,
      ),
      Radius.circular(size.width * 0.08),
    ));
    canvas.drawPath(innerPath, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Bluetooth Scan Icon
class _BluetoothScanPainter extends CustomPainter {
  final Color color;
  _BluetoothScanPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Bluetooth symbol
    final btPath = Path();
    // Top arrow
    btPath.moveTo(size.width * 0.35, size.height * 0.25);
    btPath.lineTo(size.width * 0.6, size.height * 0.45);
    btPath.lineTo(size.width * 0.45, size.height * 0.15);
    btPath.lineTo(size.width * 0.45, size.height * 0.85);
    btPath.lineTo(size.width * 0.6, size.height * 0.55);
    btPath.lineTo(size.width * 0.35, size.height * 0.75);
    canvas.drawPath(btPath, paint);

    // Radar waves on right
    final wavePaint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.05
      ..strokeCap = StrokeCap.round;

    // Wave 1
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.5),
        width: size.width * 0.5,
        height: size.height * 0.5,
      ),
      -math.pi / 4,
      math.pi / 2,
      false,
      wavePaint,
    );

    // Wave 2
    wavePaint.color = color.withValues(alpha: 0.4);
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.5),
        width: size.width * 0.75,
        height: size.height * 0.75,
      ),
      -math.pi / 4,
      math.pi / 2,
      false,
      wavePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Simulation Icon - Flask with bubbles
class _SimulationIconPainter extends CustomPainter {
  final Color color;
  _SimulationIconPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.07
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Flask neck
    canvas.drawLine(
      Offset(size.width * 0.4, size.height * 0.1),
      Offset(size.width * 0.4, size.height * 0.35),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.6, size.height * 0.1),
      Offset(size.width * 0.6, size.height * 0.35),
      paint,
    );

    // Flask top
    canvas.drawLine(
      Offset(size.width * 0.35, size.height * 0.1),
      Offset(size.width * 0.65, size.height * 0.1),
      paint,
    );

    // Flask body
    final flaskPath = Path();
    flaskPath.moveTo(size.width * 0.4, size.height * 0.35);
    flaskPath.lineTo(size.width * 0.2, size.height * 0.75);
    flaskPath.quadraticBezierTo(
      size.width * 0.15,
      size.height * 0.9,
      size.width * 0.3,
      size.height * 0.9,
    );
    flaskPath.lineTo(size.width * 0.7, size.height * 0.9);
    flaskPath.quadraticBezierTo(
      size.width * 0.85,
      size.height * 0.9,
      size.width * 0.8,
      size.height * 0.75,
    );
    flaskPath.lineTo(size.width * 0.6, size.height * 0.35);
    canvas.drawPath(flaskPath, paint);

    // Bubbles inside flask
    canvas.drawCircle(
      Offset(size.width * 0.4, size.height * 0.7),
      size.width * 0.06,
      fillPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.55, size.height * 0.75),
      size.width * 0.04,
      fillPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.6, size.height * 0.6),
      size.width * 0.05,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
