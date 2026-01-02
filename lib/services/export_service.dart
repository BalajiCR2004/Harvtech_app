import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';

import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';

import '../models/vehicle_data.dart';

/// Utility service to export lists of `VehicleData` to an Excel file
/// and share/save it via platform share dialog.
class ExportService {
  /// Create an Excel file from vehicle data and return the bytes.
  static Uint8List? createExcelBytes(List<VehicleData> rows) {
    final excel = Excel.createExcel();
    final sheet = excel[excel.getDefaultSheet() ?? 'Sheet1'];

    // Header
    sheet.appendRow([
      'timestamp',
      'rpm',
      'speed',
      'batteryVoltage',
      'batteryCurrent',
      'power',
      'temperature',
      'throttleVoltage',
      'stateOfCharge',
      'errorCodes',
    ]);

    for (final r in rows) {
      sheet.appendRow([
        r.timestamp.toIso8601String(),
        r.rpm,
        r.speed,
        r.batteryVoltage,
        r.batteryCurrent,
        r.power,
        r.temperature,
        r.throttleVoltage,
        r.stateOfCharge,
        r.errorCodes.join(';'),
      ]);
    }

    final encoded = excel.encode();
    if (encoded == null) return null;
    return Uint8List.fromList(encoded);
  }

  /// Save bytes to a temporary file and return its path.
  /// Returns the path of the saved file on success, or null.
  static Future<String?> saveToTempFile(String filenamePrefix, Uint8List bytes) async {
    try {
      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final safePrefix = filenamePrefix.replaceAll(RegExp(r'[^A-Za-z0-9-_]'), '_');
      final filename = '$safePrefix-$timestamp.xlsx';
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  /// Try to save the bytes to the device Downloads folder.
  /// Falls back to `/sdcard/Download` if `getExternalStorageDirectories` is unavailable.
  /// Returns the absolute path on success, or null on failure.
  static Future<String?> saveToDownloads(String filenamePrefix, Uint8List bytes) async {
    // Try platform MediaStore save first via MethodChannel
    const channel = MethodChannel('cjpower_ble/export');
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final safePrefix = filenamePrefix.replaceAll(RegExp(r'[^A-Za-z0-9-_]'), '_');
    final filename = '$safePrefix-$timestamp.xlsx';

    try {
      final res = await channel.invokeMethod<String>("saveToDownloads", {
        'filename': filename,
        'bytes': bytes,
      });
      if (res != null && res.isNotEmpty) return res;
    } catch (_) {
      // platform call failed, fall back to legacy approach
    }

    try {
      String? dirPath;
      try {
        final dirs = await getExternalStorageDirectories(type: StorageDirectory.downloads);
        if (dirs != null && dirs.isNotEmpty) {
          dirPath = dirs.first.path;
        }
      } catch (_) {
        // ignore and fallback
      }

      dirPath ??= '/sdcard/Download';

      final file = File('$dirPath/$filename');

      // Ensure directory exists
      try {
        await file.parent.create(recursive: true);
      } catch (_) {}

      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (_) {
      return null;
    }
  }
}
