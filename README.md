# CJPOWER BLE Flutter Package

Flutter BLE service package for CJPOWER motor controller, providing real-time vehicle data including State of Charge (SoC), RPM, Power (KW), and Amperage (A).

## Features

- ✅ BLE device scanning and connection management
- ✅ Real-time vehicle data streaming
- ✅ Protocol encoding/decoding for CJPOWER devices
- ✅ Data calibration and conversion
- ✅ Error code monitoring
- ✅ Device information reading (firmware/hardware versions)
- ✅ Type-safe data models
- ✅ Reactive streams (RxDart)

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  cjpower_ble:
    path: ./path/to/cjpower_ble
```

## Platform Setup

### Android

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

### iOS

Add to `ios/Runner/Info.plist`:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app needs Bluetooth to connect to CJPOWER device</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>This app needs Bluetooth to connect to CJPOWER device</string>
```

## Usage

### 1. Initialize Service Locator

```dart
import 'package:cjpower_ble/cjpower_ble.dart';

void main() {
  setupServiceLocator();
  runApp(MyApp());
}
```

### 2. Scan and Connect

```dart
final connectionService = getIt<BleConnectionService>();

// Start scanning
await connectionService.startScan();

// Listen to scan results
connectionService.scanResults.listen((results) {
  for (var result in results) {
    print('Found device: ${result.device.platformName}');
  }
});

// Connect to device
await connectionService.connect(device);

// Monitor connection state
connectionService.connectionState.listen((state) {
  print('Connection state: $state');
});
```

### 3. Start Receiving Vehicle Data

```dart
final vehicleDataService = getIt<VehicleDataService>();

// Start data streaming
await vehicleDataService.startDataStream();

// Listen to vehicle data
vehicleDataService.vehicleDataStream.listen((data) {
  print('Battery Voltage: ${data.batteryVoltage} V');
  print('Current: ${data.batteryCurrent} A');
  print('RPM: ${data.rpm}');
  print('Power: ${data.power} KW');
  print('SoC: ${data.stateOfCharge} %');
  print('Speed: ${data.speed} km/h');
  print('Temperature: ${data.temperature} °C');
});

// Stop data streaming
await vehicleDataService.stopDataStream();
```

### 4. Read/Write Parameters

```dart
// Read parameter
final value = await vehicleDataService.readParameter(
  20, // address
  'u16', // data type
);

// Write parameter
await vehicleDataService.writeParameter(
  20, // address
  'u16', // data type
  1500, // value
);
```

## Architecture

```
┌─────────────────────────────────────────┐
│           Flutter App UI                │
└───────────────┬─────────────────────────┘
                │
┌───────────────▼─────────────────────────┐
│      VehicleDataService                 │
│  - Start/Stop data stream               │
│  - Parse and calibrate data             │
│  - Read/Write parameters                │
└───────────────┬─────────────────────────┘
                │
┌───────────────▼─────────────────────────┐
│    BleConnectionService                 │
│  - Scan devices                         │
│  - Connect/Disconnect                   │
│  - Read device info                     │
│  - Write/Notify characteristics         │
└───────────────┬─────────────────────────┘
                │
┌───────────────▼─────────────────────────┐
│    BleProtocolHandler                   │
│  - Encode commands                      │
│  - Decode responses                     │
│  - Data type conversion                 │
└───────────────┬─────────────────────────┘
                │
┌───────────────▼─────────────────────────┐
│        BLE Device (MCU)                 │
│  Service: FFE0                          │
│  Write Char: FFE1                       │
│  Notify Char: FFE2                      │
└─────────────────────────────────────────┘
```

## Data Fields

The package monitors the following vehicle parameters:

| Parameter | Address | Unit | Description |
|-----------|---------|------|-------------|
| Battery Voltage | 20 | V | Battery voltage |
| Current | 21 | A | Battery current (Amperage) |
| RPM | 22 | RPM | Motor revolutions per minute |
| Power | 23 | KW | Motor power output |
| Speed | 24 | km/h | Vehicle speed |
| Temperature | 25 | °C | Motor temperature |
| SoC | 26 | % | State of Charge (0-100%) |
| Error Code | 239 | - | Bit-mapped error codes |

**Note:** Memory addresses may need adjustment based on your specific device configuration.

## Protocol Details

### Command Format

**Write Command:**
```
[Address Low Byte] [Address High Byte] [Data Bytes...]
```

**Read Command:**
```
[Address Low Byte] [Address High Byte | 0x80] [Data Size]
```

### Response Format

```
[Address Low Byte] [Address High Byte | Flags] [Data Bytes...]
```

**Flags:**
- Bit 7 (0x80): Read response
- Bit 6 (0x40): Multi-byte
- Bit 5 (0x20): Response acknowledgment

### Data Types

- `u8`: Unsigned 8-bit integer (0-255)
- `i8`: Signed 8-bit integer (-128 to 127)
- `u16`: Unsigned 16-bit integer (0-65535)
- `i16`: Signed 16-bit integer (-32768 to 32767)
- `u32`: Unsigned 32-bit integer
- `i32`: Signed 32-bit integer
- `str`: String
- `array`: Byte array

### Calibration

Display values are calibrated using the formula:

```
Display Value = (MCU Value - ratio_B) / ratio_K
MCU Value = Display Value * ratio_K + ratio_B
```

## BLE UUIDs

| Service/Characteristic | UUID |
|----------------------|------|
| Main Service | 0000FFE0-0000-1000-8000-00805F9B34FB |
| Write Characteristic | 0000FFE1-0000-1000-8000-00805F9B34FB |
| Notify Characteristic | 0000FFE2-0000-1000-8000-00805F9B34FB |
| Device Info Service | 0000180A-0000-1000-8000-00805F9B34FB |
| Firmware Version | 00002A26-0000-1000-8000-00805F9B34FB |
| Hardware Version | 00002A27-0000-1000-8000-00805F9B34FB |

## Example App

See `example/main.dart` for a complete Flutter application demonstrating:
- Device scanning and connection
- Real-time data display
- Connection state management
- Error handling

## Customization

### Adjusting Data Field Addresses

Edit `VehicleDataService._initializeDataFields()` to match your device's memory mapping:

```dart
_dataFieldMap = {
  20: const DataField(
    address: 20,
    addressSize: 'u16',
    ratioK: 10.0,  // Adjust calibration
    ratioB: 0.0,
    uiType: 'field',
    title: 'Battery Voltage',
    titleEn: 'Battery Voltage',
    unit: 'V',
  ),
  // Add more fields...
};
```

### Adding Custom Parameters

1. Add the field to `VehicleData` model
2. Update `_dataFieldMap` in `VehicleDataService`
3. Handle the address in `_processLiveData()`

## Troubleshooting

### Connection Issues
- Ensure Bluetooth is enabled
- Check location permissions (Android)
- Verify device is powered on and nearby
- Check device name matches filters in `BleConstants.deviceNameFilters`

### No Data Received
- Verify connection is established
- Check `startDataStream()` was called
- Monitor `notificationStream` for incoming data
- Verify characteristic notifications are enabled

### Incorrect Values
- Check `ratioK` and `ratioB` calibration parameters
- Verify `addressSize` matches device specification
- Check endianness (little-endian is used)

## License

MIT License

## Support

For issues and feature requests, please contact the development team.

## Based On

This package is based on the reverse-engineered BLE protocol from the CJPOWER Android application (辰吉CJPOWER v1.1.4).
