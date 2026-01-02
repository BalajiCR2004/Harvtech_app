import 'dart:io';

void main() async {
  final files = [
    'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png',
  ];

  final buffer = StringBuffer();
  buffer.writeln('#pragma once');
  buffer.writeln('#include <Arduino.h>');
  buffer.writeln();

  for (final filePath in files) {
    final file = File(filePath);
    if (!file.existsSync()) {
      print('Warning: File not found: $filePath');
      continue;
    }

    final bytes = await file.readAsBytes();
    const name = 'img_app_icon'; // Simplified name

    buffer.writeln('// File: $filePath, Size: ${bytes.length} bytes');
    buffer.writeln('const uint8_t $name[] PROGMEM = {');

    for (int i = 0; i < bytes.length; i++) {
      buffer.write('0x${bytes[i].toRadixString(16).padLeft(2, '0')}');
      if (i < bytes.length - 1) {
        buffer.write(', ');
      }
      if ((i + 1) % 16 == 0) {
        buffer.writeln();
      }
    }
    buffer.writeln('};');
    buffer.writeln('const int ${name}_len = ${bytes.length};');
    buffer.writeln();
  }

  final outFile = File('display_firmware/src/Images.h');
  await outFile.writeAsString(buffer.toString());
  print('Generated ${outFile.path}');
}
