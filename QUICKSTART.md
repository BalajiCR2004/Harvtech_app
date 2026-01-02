# CJPOWER BLE Flutter App - Quick Start

## ✅ Setup Complete

Your Flutter BLE application is ready with the following features:

### 📱 Dashboard UI
- **2x2 Grid Display**: SoC, RPM, Power (KW), Current (A)
- **Additional Info Card**: Voltage, Speed, Temperature
- **Error Display**: Real-time error code monitoring
- **Connection Status**: Bluetooth icon with visual feedback
- **Device Scanner**: Modal bottom sheet with RSSI indicators

### 🔧 Technical Stack
- Flutter 3.35.7
- flutter_blue_plus: BLE communication
- RxDart: Reactive streams
- GetIt: Dependency injection
- Material Design 3

### 🚀 Running the App

#### On Android:
```bash
# Connect your Android device or start emulator
flutter run
```

#### On iOS:
```bash
# Connect your iPhone or start simulator
flutter run
```

### 📱 App Usage

1. **Launch App**: Opens to "Not Connected" screen
2. **Tap Bluetooth Icon**: Opens device scanner
3. **Select Device**: App scans for CJPOWER devices (M-SPEED, MSPEED, QS*POWER, cj-power, cjpower)
4. **Auto-Connect**: Connection dialog shows progress
5. **Start Streaming**: Tap green "Start Streaming" button
6. **View Data**: Real-time display of:
   - State of Charge (%)
   - RPM
   - Power (KW)
   - Current (A)
   - Plus: Voltage, Speed, Temperature
7. **Stop Streaming**: Tap red "Stop Streaming" button
8. **Disconnect**: Tap Bluetooth icon in app bar

### 🎨 UI Features

#### Color Coding
- **SoC**: Green (>60%), Orange (30-60%), Red (<30%)
- **Signal**: Green (>-60dBm), Orange (-60 to -80dBm), Red (<-80dBm)
- **Streaming**: Green (Start), Red (Stop)

#### Cards
- **Metric Cards**: Large value display with icons
- **Info Card**: Detailed additional parameters
- **Error Card**: Red background for active errors

### ⚙️ Permissions

**Android** (Already configured in AndroidManifest.xml):
- BLUETOOTH
- BLUETOOTH_ADMIN
- BLUETOOTH_SCAN
- BLUETOOTH_CONNECT
- ACCESS_FINE_LOCATION
- ACCESS_COARSE_LOCATION

**iOS** (Already configured in Info.plist):
- NSBluetoothAlwaysUsageDescription
- NSBluetoothPeripheralUsageDescription

### 🔌 BLE Protocol Details

**Service UUID**: 0000FFE0-0000-1000-8000-00805F9B34FB
**Write Characteristic**: 0000FFE1-0000-1000-8000-00805F9B34FB
**Notify Characteristic**: 0000FFE2-0000-1000-8000-00805F9B34FB

**Data Fields** (Memory Addresses):
- Address 20: Battery Voltage (u16, K=10.0)
- Address 21: Current (i16, K=10.0)
- Address 22: RPM (u16, K=1.0)
- Address 23: Power (u16, K=100.0)
- Address 24: Speed (u16, K=10.0)
- Address 25: Temperature (i16, K=10.0)
- Address 26: SoC (u8, K=1.0)
- Address 239: Error codes (u32)

### 🐛 Troubleshooting

**No Devices Found:**
- Ensure CJPOWER device is powered on
- Check Bluetooth is enabled on phone
- Device should be within range
- Device name should match filters

**Connection Failed:**
- Move closer to device
- Restart CJPOWER device
- Check device is not connected to another phone
- Try disabling/enabling Bluetooth

**No Data Streaming:**
- Ensure "Start Streaming" button is tapped
- Check connection is stable
- Verify memory addresses match your device

**Incorrect Values:**
- Adjust calibration ratios in `vehicle_data_service.dart`
- Modify `ratio_K` and `ratio_B` in `_initializeDataFields()`
- Formula: Y = (X - B) / K

### 📂 Project Structure
```
lib/
├── main.dart                          # Main app with dashboard UI
├── models/
│   ├── ble_device_info.dart          # Device information model
│   ├── vehicle_data.dart             # Vehicle data model
│   ├── ble_constants.dart            # UUIDs and addresses
│   └── data_field.dart               # Field configuration
├── protocol/
│   └── ble_protocol_handler.dart     # Protocol encoding/decoding
└── services/
    ├── ble_connection_service.dart   # Connection management
    ├── vehicle_data_service.dart     # Data streaming
    └── service_locator.dart          # Dependency injection
```

### ⚡ Next Steps

1. **Test with Device**: Connect to actual CJPOWER hardware
2. **Verify Addresses**: Confirm memory addresses (20-26) match your device
3. **Calibrate**: Adjust ratio_K and ratio_B for accurate readings
4. **Customize**: Modify UI colors, layout, or add features
5. **Deploy**: Build release APK/IPA for distribution

### 🔧 Customization

**Change Memory Addresses:**
Edit `lib/services/vehicle_data_service.dart` in `_initializeDataFields()` method.

**Adjust Calibration:**
Modify `ratio_K` and `ratio_B` values in DataField definitions.

**Update Device Filters:**
Edit `lib/models/ble_constants.dart` - `deviceNameFilters` list.

**Change UI Theme:**
Modify colors in `lib/main.dart` - `ThemeData` configuration.

### 📊 Analysis Results
- ✅ No critical errors
- ✅ 18 style warnings (safe to ignore)
- ✅ All dependencies resolved
- ✅ Android & iOS permissions configured
- ✅ Ready for deployment

---

**Built with**: Flutter • Dart • BLE
**For**: CJPOWER Motor Controller Monitoring
**Date**: December 23, 2025
