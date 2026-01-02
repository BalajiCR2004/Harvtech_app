// ignore_for_file: avoid_print
import 'dart:io';
import 'package:image/image.dart' as img;

/// Generates HarvTech logo as app icon
void main() {
  const size = 1024;
  final image = img.Image(width: size, height: size);

  // Background color - HarvTech orange
  final bgColor = img.ColorRgba8(245, 166, 35, 255); // #F5A623
  final fgColor = img.ColorRgba8(255, 255, 255, 255); // White

  // Fill background
  img.fill(image, color: bgColor);

  // Draw the "H" with lightning bolt
  final strokeWidth = (size * 0.10).round();

  // Left vertical of H
  _drawThickLine(
    image,
    (size * 0.25).round(),
    (size * 0.18).round(),
    (size * 0.25).round(),
    (size * 0.82).round(),
    strokeWidth,
    fgColor,
  );

  // Right vertical of H
  _drawThickLine(
    image,
    (size * 0.75).round(),
    (size * 0.18).round(),
    (size * 0.75).round(),
    (size * 0.82).round(),
    strokeWidth,
    fgColor,
  );

  // Lightning bolt in center
  final boltPoints = [
    [0.58, 0.32], // top
    [0.32, 0.50], // left point
    [0.48, 0.50], // inner left
    [0.42, 0.68], // bottom
    [0.68, 0.50], // right point
    [0.52, 0.50], // inner right
  ];

  _fillPolygon(image, boltPoints, size, fgColor);

  // Save the image
  final pngBytes = img.encodePng(image);
  final outputFile = File('assets/icon/app_icon.png');
  outputFile.writeAsBytesSync(pngBytes);
  print('✓ Generated app_icon.png (${size}x$size)');

  // Also create a foreground version for adaptive icons (with transparency)
  final fgImage = img.Image(width: size, height: size);
  // Transparent background
  img.fill(fgImage, color: img.ColorRgba8(0, 0, 0, 0));

  // Draw H in orange on transparent
  final orangeColor = img.ColorRgba8(245, 166, 35, 255);

  // Left vertical
  _drawThickLine(
    fgImage,
    (size * 0.25).round(),
    (size * 0.18).round(),
    (size * 0.25).round(),
    (size * 0.82).round(),
    strokeWidth,
    orangeColor,
  );

  // Right vertical
  _drawThickLine(
    fgImage,
    (size * 0.75).round(),
    (size * 0.18).round(),
    (size * 0.75).round(),
    (size * 0.82).round(),
    strokeWidth,
    orangeColor,
  );

  // Lightning bolt
  _fillPolygon(fgImage, boltPoints, size, orangeColor);

  final fgBytes = img.encodePng(fgImage);
  final fgFile = File('assets/icon/app_icon_foreground.png');
  fgFile.writeAsBytesSync(fgBytes);
  print('✓ Generated app_icon_foreground.png (${size}x$size)');
}

void _drawThickLine(
  img.Image image,
  int x1,
  int y1,
  int x2,
  int y2,
  int thickness,
  img.Color color,
) {
  final halfThickness = thickness ~/ 2;

  // For vertical lines
  if (x1 == x2) {
    for (int x = x1 - halfThickness; x <= x1 + halfThickness; x++) {
      for (int y = y1; y <= y2; y++) {
        if (x >= 0 && x < image.width && y >= 0 && y < image.height) {
          image.setPixel(x, y, color);
        }
      }
    }
    // Round caps
    _fillCircle(image, x1, y1, halfThickness, color);
    _fillCircle(image, x2, y2, halfThickness, color);
  }
}

void _fillCircle(img.Image image, int cx, int cy, int radius, img.Color color) {
  for (int y = -radius; y <= radius; y++) {
    for (int x = -radius; x <= radius; x++) {
      if (x * x + y * y <= radius * radius) {
        final px = cx + x;
        final py = cy + y;
        if (px >= 0 && px < image.width && py >= 0 && py < image.height) {
          image.setPixel(px, py, color);
        }
      }
    }
  }
}

void _fillPolygon(
  img.Image image,
  List<List<double>> points,
  int size,
  img.Color color,
) {
  // Convert normalized points to pixel coordinates
  final pixelPoints = points
      .map((p) => [(p[0] * size).round(), (p[1] * size).round()])
      .toList();

  // Find bounding box
  int minX = size, maxX = 0, minY = size, maxY = 0;
  for (final p in pixelPoints) {
    if (p[0] < minX) minX = p[0];
    if (p[0] > maxX) maxX = p[0];
    if (p[1] < minY) minY = p[1];
    if (p[1] > maxY) maxY = p[1];
  }

  // Fill using scanline
  for (int y = minY; y <= maxY; y++) {
    for (int x = minX; x <= maxX; x++) {
      if (_pointInPolygon(x, y, pixelPoints)) {
        if (x >= 0 && x < image.width && y >= 0 && y < image.height) {
          image.setPixel(x, y, color);
        }
      }
    }
  }
}

bool _pointInPolygon(int x, int y, List<List<int>> polygon) {
  bool inside = false;
  int j = polygon.length - 1;

  for (int i = 0; i < polygon.length; i++) {
    final xi = polygon[i][0], yi = polygon[i][1];
    final xj = polygon[j][0], yj = polygon[j][1];

    if (((yi > y) != (yj > y)) && (x < (xj - xi) * (y - yi) / (yj - yi) + xi)) {
      inside = !inside;
    }
    j = i;
  }

  return inside;
}
