// ignore_for_file: avoid_print
import 'dart:io';
import 'package:image/image.dart' as img;

/// Creates a properly padded adaptive icon foreground from the app icon
/// Android adaptive icons need ~25% safe zone padding on all sides
void main() {
  const outputSize = 1024;

  // Load the original icon
  final inputFile = File('assets/icon/app_icon.png');
  if (!inputFile.existsSync()) {
    print('Error: assets/icon/app_icon.png not found');
    return;
  }

  final originalBytes = inputFile.readAsBytesSync();
  final originalImage = img.decodeImage(originalBytes);

  if (originalImage == null) {
    print('Error: Could not decode image');
    return;
  }

  // Create the adaptive foreground with proper padding
  // The logo should occupy about 66% of the icon (leaving ~17% padding on each side)
  // This ensures it stays within the safe zone for all mask shapes
  final foregroundImage = img.Image(width: outputSize, height: outputSize);

  // Fill with transparent background
  img.fill(foregroundImage, color: img.ColorRgba8(0, 0, 0, 0));

  // Calculate the size and position for the centered, scaled logo
  // Using 60% of the total size to ensure good visibility with padding
  final logoSize = (outputSize * 0.60).round();
  final offset = ((outputSize - logoSize) / 2).round();

  // Resize the original image
  final resizedLogo = img.copyResize(
    originalImage,
    width: logoSize,
    height: logoSize,
    interpolation: img.Interpolation.cubic,
  );

  // Composite the resized logo onto the transparent background
  img.compositeImage(
    foregroundImage,
    resizedLogo,
    dstX: offset,
    dstY: offset,
  );

  // Save the foreground image
  final fgBytes = img.encodePng(foregroundImage);
  final fgFile = File('assets/icon/app_icon_foreground.png');
  fgFile.writeAsBytesSync(fgBytes);
  print(
      '✓ Generated app_icon_foreground.png (${outputSize}x$outputSize) with centered logo');

  // Also create a version of the main icon that's properly centered
  // This is for non-adaptive icon displays
  final centeredIcon = img.Image(width: outputSize, height: outputSize);

  // Fill with the orange background
  img.fill(centeredIcon, color: img.ColorRgba8(245, 166, 35, 255));

  // Composite the resized logo
  img.compositeImage(
    centeredIcon,
    resizedLogo,
    dstX: offset,
    dstY: offset,
  );

  final iconBytes = img.encodePng(centeredIcon);
  final iconFile = File('assets/icon/app_icon_centered.png');
  iconFile.writeAsBytesSync(iconBytes);
  print(
      '✓ Generated app_icon_centered.png (${outputSize}x$outputSize) with orange background');
}
