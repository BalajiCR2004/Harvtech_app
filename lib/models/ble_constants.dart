/// BLE UUIDs and constants for CJPOWER device
class BleConstants {
  // Service UUIDs
  static const String mainServiceUuid = '0000FFE0-0000-1000-8000-00805F9B34FB';
  static const String deviceInfoServiceUuid =
      '0000180A-0000-1000-8000-00805F9B34FB';

  // Characteristic UUIDs
  static const String writeCharacteristicUuid =
      '0000FFE1-0000-1000-8000-00805F9B34FB';
  static const String readNotifyCharacteristicUuid =
      '0000FFE2-0000-1000-8000-00805F9B34FB';
  static const String bootSwCharacteristicUuid =
      '0000FFE3-0000-1000-8000-00805F9B34FB';
  static const String bootNotiCharacteristicUuid =
      '0000FFE4-0000-1000-8000-00805F9B34FB';

  // Device Info Characteristics
  static const String firmwareVersionCharacteristicUuid =
      '00002A26-0000-1000-8000-00805F9B34FB';
  static const String hardwareVersionCharacteristicUuid =
      '00002A27-0000-1000-8000-00805F9B34FB';

  // Device name filters
  static const List<String> deviceNameFilters = [
    'M-SPEED',
    'MSPEED',
    'QS*POWER',
    'cj-power',
    'cjpower',
  ];

  // Memory Addresses
  static const int controlAddress = 11; // Upload control
  static const int timeDataChannelAddress = 12; // Time data channel setup
  static const int errorCodeAddress = 239; // Error codes
  static const int liveDataStartAddress = 20; // Live data starts at address 20

  // Control Commands
  static const int cmdStopUpload = 0;
  static const int cmdClearData = 255;
  static const int cmdStartUpload = 1;

  // Data Type Sizes
  static const Map<String, int> dataTypeSizes = {
    'u8': 1,
    'i8': 1,
    'u16': 2,
    'i16': 2,
    'u32': 4,
    'i32': 4,
  };
}
