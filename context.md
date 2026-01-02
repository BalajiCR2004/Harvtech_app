# CJPOWER BLE Flutter Package - Context & Analysis

## 1. Project Overview
**Name:** `cjpower_ble`
**Type:** Flutter Package / Application (Hybrid structure)
**Purpose:** Provides a BLE interface for CJPOWER motor controllers, enabling real-time monitoring of vehicle data (RPM, Voltage, Power, Current, etc.) and parameter configuration.
**Core Tech:** Flutter, `flutter_blue_plus` (BLE), `rxdart` (Reactive Streams), `provider/get_it` (DI).

## 2. Architecture & Modules

The project follows a **Service-Oriented Architecture** with strict separation of concerns:

### 2.1 Core Services (`lib/services/`)
*   **`BleConnectionService`**: Manages the lifecycle of the BLE connection.
    *   **Responsibilities:** Scanning (filtered), Connecting, Service Discovery, Characteristic Discovery (Write/Notify).
    *   **Key Streams:** `connectionState`, `scanResults`, `notificationStream`.
*   **`VehicleDataService`**: High-level data orchestration.
    *   **Responsibilities:** Configuring data streams (Time Data Channels), decoding incoming packets, applying calibration (Ratio K/B), and emitting `VehicleData`.
    *   **Key Logic:** `startDataStream()` sets up the specific memory addresses to monitor.
*   **`SimulationService`**: Provides mock data for UI testing without a physical device.

### 2.2 Protocol Layer (`lib/protocol/`)
*   **`BleProtocolHandler`**: Low-level packet manipulation.
    *   **Responsibilities:** Constructing Read/Write command packets, parsing Acknowledgments (`AckData`), and handling Endianness/Data Types (`u8`, `i16`, `u32`, etc.).

### 2.3 Models (`lib/models/`)
*   **`VehicleData`**: Immutable data class holding sanitized vehicle metrics (RPM, Voltage, SoC, etc.).
*   **`BleConstants`**: Central repository for UUIDs, Memory Addresses, and Command Codes.
*   **`DataField`**: Metadata for a specific vehicle parameter (Address, Unit, Calibration factors K/B).

## 3. Configuration & Constants

### BLE UUIDs
*   **Main Service:** `0000FFE0-0000-1000-8000-00805F9B34FB` (and similar `FFE0` variants)
*   **Write Characteristic:** `0000FFE1...` (FFE1)
*   **Notify Characteristic:** `0000FFE2...` (FFE2)
*   **Device Info:** `0000180A...` (Firmware/Hardware revisions)

### Memory Addresses (CJPOWER Protocol)
| Parameter | Address | Type | Ratio K | Ratio B |
| :--- | :--- | :--- | :--- | :--- |
| **Control/Upload** | `11` | `u8` | - | - |
| **Time Data Setup** | `12` | `array`| - | - |
| **RPM** | `105` | `i16` | 1.0 | 0.0 |
| **Voltage** | `113` | `u16` | 10.0 | 0.0 |
| **Power** | `115` | `i16` | 1000.0 | 0.0 |
| **Current** | `119` | `i16` | 10.0 | 0.0 |
| **Throttle** | `220` | `u16` | 744.3 | 0.0 |
| **Control Temp** | `222` | `u8` | 1.0 | 40.0 |
| **Error Code** | `239` | `u32` | 1.0 | 0.0 |

**Calibration Formula:** `Display = (Raw - B) / K`

## 4. Workflows & embedded Protocols

### 4.1 Connection Flow
1.  **Scan**: Filter devices by names `['M-SPEED', 'MSPEED', 'QS*POWER', 'cj-power', 'cjpower']`.
2.  **Connect**: Establish GATT connection.
3.  **Discovery**:
    *   Look for Service `FFE0`.
    *   Locate Write (`FFE1`) and Notify (`FFE2`) characteristics.
4.  **Setup**: Enable notifications on `FFE2`.

### 4.2 Data Streaming Flow (The "Embedded Protocol")
The app doesn't just "read" data; it programs the controller to stream specific fields.

1.  **Stop & Clear**: Send `cmdStopUpload` (0) and `cmdClearData` (255) to Address `11`.
2.  **Configure Channels**:
    *   Iterate through desired fields (RPM, Voltage, etc.).
    *   Construct a **Read Command** for the field's address.
    *   **Masking**: Clear high bits of the command byte 1 (`cmd[1] &= 0x1F`).
    *   **Upload Config**: Write this modified read command to Address `12` (Time Data Channel).
    *   *This tells the MCU: "Add this address to your upload loop".*
3.  **Start Upload**: Send `cmdStartUpload` (1) to Address `11`.
4.  **Receive Loop**:
    *   Listen to `FFE2`.
    *   Parse packet header to identify Address.
    *   Decode payload based on type (`u16`, `i16` etc.).
    *   Apply calibration.
    *   Update Stream.

### 4.3 Protocol Packet Structure

**Write Command:**
```
[Addr Low] [Addr High & 0x1F] [Data Bytes...]
```

**Read Command:**
```
[Addr Low] [Addr High | 0x80] [Size]
```

**Response (Notification):**
```
[Addr Low] [Addr High | Flags] [Data Bytes...]
Flags: 0x80 (Read), 0x40 (Multi), 0x20 (Ack)
```

## 5. Critical Code Snippets

### Data Channel Setup (The Core "Trick")
This logic in `VehicleDataService` is what enables real-time high-freq data.
```dart
// lib/services/vehicle_data_service.dart

Future<void> _setupTimeDataChannels() async {
  for (final field in _dataFieldMap.values) {
    // 1. Create standard read command
    final readCmd = BleProtocolHandler.createReadCommand(
      field.address,
      field.addressSize,
    );

    // 2. Protocol Specific: Modify command for Channel Setup
    // Clear high bits to treat it as a configuration payload
    final modifiedCmd = Uint8List.fromList(readCmd);
    modifiedCmd[1] = modifiedCmd[1] & 0x1F;

    // 3. Write to the "Channel Setup" address (12)
    final channelSetupCmd = BleProtocolHandler.createWriteCommand(
      BleConstants.timeDataChannelAddress, // 12
      'array',
      modifiedCmd.toList(),
    );

    await _connectionService.write(channelSetupCmd.toList(), withoutResponse: true);
  }
}
```

## Analysis Snapshot (automated)

- **Date:** 2026-01-02
- **Total files scanned:** 80
- **Top-level languages / types:** Dart (Flutter app), C/C++ (firmware), platform manifests and resources (Android, Windows)
- **Notable directories:** `lib/`, `android/`, `windows/`, `display_firmware/`, `assets/`
- **Summary of findings so far:** Inventory recorded. No code changes applied in this step — only analysis appended.

Refer to this file for further change logs and analysis entries.

## Change Log - Export Feature (automated)

- **Date:** 2026-01-02
- **Change:** Added Excel export feature with two download options (simulation and live data).
- **Files added:** `lib/services/export_service.dart`
- **Files modified:** `pubspec.yaml`, `lib/services/simulation_service.dart`, `lib/services/vehicle_data_service.dart`, `lib/main.dart`
- **Behavior:** Each service maintains an in-memory rolling buffer of recent `VehicleData`. The UI exposes two download buttons in the app bar: one for simulation data (visible in Simulation Mode) and one for live data (visible when connected). Clicking a button generates an `.xlsx` file and opens the platform share/save dialog. Uses `excel`, `path_provider`, and `share_plus` packages.
- **Notes:** Implementation is non-intrusive: buffers are appended without changing existing streams or public APIs. Exporting writes a temporary file and invokes the platform share dialog; no persistent storage changes.


### Packet Parsing
```dart
// lib/protocol/ble_protocol_handler.dart

static AckData? parseAckData(Uint8List data) {
  if (data.length < 2) return null;

  // Header decoding
  final isRead = (data[1] & 0x80) == 0x80;
  final address = ((data[1] & 0x1F) << 8) | data[0]; 
  final payload = data.sublist(2);

  return AckData(address: address, data: payload, ...);
}
```

## 6. Directory Structure
```
lib/
├── cjpower_ble.dart          # Package export
├── main.dart                 # App Entry & UI Dashboard
├── models/
│   ├── ble_constants.dart    # UUIDs, Addresses, Cmds
│   ├── data_field.dart       # Metadata for parameters
│   └── vehicle_data.dart     # State Class
├── protocol/
│   └── ble_protocol_handler.dart # Byte manipulation
├── services/
│   ├── ble_connection_service.dart # GATT logic
│   └── vehicle_data_service.dart   # Logic for "Time Data Channel" setup
└── widgets/                  # UI Components
```

## 7. ESP32 Firmware Protocol Definition
For the C++ implementation, use the following translation of the Flutter logic:

### Memory Addresses & Calibration
| Field | Address | Size | K (Divisor) | B (Offset) | Type |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Speed** | 24 | u16 | 10.0 | 0 | `uint16_t` |
| **SoC** | 26 | u16 | 1.0 | 0 | `uint16_t` |
| **RPM** | 105 | i16 | 1.0 | 0 | `int16_t` |
| **Voltage** | 113 | u16 | 10.0 | 0 | `uint16_t` |
| **Current** | 119 | i16 | 10.0 | 0 | `int16_t` |
| **Throttle**| 220 | u16 | 744.3 | 0 | `uint16_t` |
| **Temp** | 222 | u8 | 1.0 | 40.0 | `uint8_t` |

### Command Structure (Byte Array)
**Read/Setup Command Example:**
```cpp
// Create Read Command
uint8_t cmd[] = {
    0x00, 
    (uint8_t)((address >> 8) & 0xFF), 
    (uint8_t)(address & 0xFF), 
    size_byte // 1=u8, 2=u16, 4=u32
};

// Setup Time Data Channel (Address 12)
// Logic: Mask the command byte[1] & 0x1F, then wrap in a Write Command to Addr 12.
```
