import 'dart:typed_data';
import '../models/ble_constants.dart';

/// BLE Protocol Handler for CJPOWER device
class BleProtocolHandler {
  /// Parse acknowledgment data from device
  static AckData? parseAckData(Uint8List data) {
    if (data.length < 2) {
      return null;
    }

    final isRead = (data[1] & 0x80) == 0x80;
    final isMulti = (data[1] & 0x40) == 0x40;
    final isResp = (data[1] & 0x20) == 0x20;
    final address = ((data[1] & 0x1F) << 8) | data[0];
    final payload = data.length > 2 ? data.sublist(2) : Uint8List(0);

    return AckData(
      isRead: isRead,
      isMulti: isMulti,
      isResp: isResp,
      address: address,
      data: payload,
    );
  }

  /// Create write command
  static Uint8List createWriteCommand(
      int address, String addressSize, dynamic value) {
    switch (addressSize) {
      case 'u8':
      case 'i8':
        return _createWriteCommandU8(address, value as int);
      case 'u16':
      case 'i16':
        return _createWriteCommandU16(address, value as int);
      case 'u32':
      case 'i32':
        return _createWriteCommandU32(address, value as int);
      case 'array':
        return _createWriteCommandArray(address, value as List<int>);
      default:
        throw ArgumentError('Unsupported address size: $addressSize');
    }
  }

  /// Create read command
  static Uint8List createReadCommand(int address, String addressSize) {
    final buffer = Uint8List(3);
    buffer[0] = address & 0xFF;
    buffer[1] = ((address & 0x1F00) >> 8) | 0x80; // Set read bit
    buffer[2] = _getDataTypeSize(addressSize);
    return buffer;
  }

  static int _getDataTypeSize(String addressSize) {
    return BleConstants.dataTypeSizes[addressSize] ?? 1;
  }

  static Uint8List _createWriteCommandU8(int address, int value) {
    final buffer = Uint8List(3);
    buffer[0] = address & 0xFF;
    buffer[1] = (address & 0x1F00) >> 8;
    buffer[2] = value & 0xFF;
    return buffer;
  }

  static Uint8List _createWriteCommandU16(int address, int value) {
    final buffer = Uint8List(4);
    buffer[0] = address & 0xFF;
    buffer[1] = (address & 0x1F00) >> 8;
    buffer[2] = value & 0xFF;
    buffer[3] = (value >> 8) & 0xFF;
    return buffer;
  }

  static Uint8List _createWriteCommandU32(int address, int value) {
    final buffer = Uint8List(6);
    buffer[0] = address & 0xFF;
    buffer[1] = (address & 0x1F00) >> 8;
    buffer[2] = value & 0xFF;
    buffer[3] = (value >> 8) & 0xFF;
    buffer[4] = (value >> 16) & 0xFF;
    buffer[5] = (value >> 24) & 0xFF;
    return buffer;
  }

  static Uint8List _createWriteCommandArray(int address, List<int> value) {
    final buffer = Uint8List(2 + value.length);
    buffer[0] = address & 0xFF;
    buffer[1] = (address & 0x1F00) >> 8;
    for (var i = 0; i < value.length; i++) {
      buffer[2 + i] = value[i] & 0xFF;
    }
    return buffer;
  }

  /// Convert raw data bytes to value based on address size
  static dynamic convertData(Uint8List data, String addressSize) {
    if (data.isEmpty) {
      return null;
    }

    try {
      // Ensure we have enough bytes
      final requiredSize = BleConstants.dataTypeSizes[addressSize] ?? 1;
      if (data.length < requiredSize) {
        // Pad with zeros if needed
        final paddedData = Uint8List(requiredSize);
        for (var i = 0; i < data.length; i++) {
          paddedData[i] = data[i];
        }
        data = paddedData;
      }

      final byteData = ByteData.sublistView(data);

      switch (addressSize) {
        case 'u8':
          return byteData.getUint8(0);
        case 'i8':
          return byteData.getInt8(0);
        case 'u16':
          return byteData.getUint16(0, Endian.little);
        case 'i16':
          return byteData.getInt16(0, Endian.little);
        case 'u32':
          return byteData.getUint32(0, Endian.little);
        case 'i32':
          return byteData.getInt32(0, Endian.little);
        case 'str':
          return String.fromCharCodes(data);
        case 'array':
          return data.toList();
        default:
          return null;
      }
    } catch (_) {
      return null;
    }
  }
}

/// Acknowledgment data structure
class AckData {
  final bool isRead;
  final bool isMulti;
  final bool isResp;
  final int address;
  final Uint8List data;

  const AckData({
    required this.isRead,
    required this.isMulti,
    required this.isResp,
    required this.address,
    required this.data,
  });
}
