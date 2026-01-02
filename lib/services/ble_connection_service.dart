import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:rxdart/rxdart.dart';
import '../models/ble_constants.dart';
import '../models/ble_device_info.dart';

/// BLE Connection Service
class BleConnectionService {
  final _connectionStateController =
      BehaviorSubject<BluetoothConnectionState>.seeded(
    BluetoothConnectionState.disconnected,
  );
  final _deviceInfoController = BehaviorSubject<BleDeviceInfo?>.seeded(null);
  final _scanResultsController = BehaviorSubject<List<ScanResult>>.seeded([]);

  List<BluetoothService>? _discoveredServices;

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? _notifyCharacteristic;

  // Streams
  Stream<BluetoothConnectionState> get connectionState =>
      _connectionStateController.stream;
  Stream<BleDeviceInfo?> get deviceInfo => _deviceInfoController.stream;
  Stream<List<ScanResult>> get scanResults => _scanResultsController.stream;

  // Getters
  BluetoothDevice? get connectedDevice => _connectedDevice;
  BluetoothCharacteristic? get writeCharacteristic => _writeCharacteristic;
  BluetoothCharacteristic? get notifyCharacteristic => _notifyCharacteristic;
  bool get isConnected =>
      _connectionStateController.value == BluetoothConnectionState.connected;

  /// Start scanning for devices
  Future<void> startScan(
      {Duration timeout = const Duration(seconds: 15)}) async {
    try {
      // Check if Bluetooth is supported
      if (!await FlutterBluePlus.isSupported) {
        throw Exception('Bluetooth is not supported on this device');
      }

      // Check adapter state
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        throw Exception('Bluetooth is not enabled');
      }

      // Clear previous results
      _scanResultsController.add([]);

      // Start scanning - don't filter by service to find all devices
      await FlutterBluePlus.startScan(
        timeout: timeout,
        androidUsesFineLocation: true,
      );

      // Listen to scan results
      FlutterBluePlus.scanResults.listen((results) {
        // Filter for CJPOWER devices by name
        final filteredResults = results.where((result) {
          final deviceName = result.device.platformName.toUpperCase();
          if (deviceName.isEmpty) return false;

          return BleConstants.deviceNameFilters.any(
            (filter) => deviceName.contains(filter.toUpperCase()),
          );
        }).toList();

        _scanResultsController.add(filteredResults);
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Stop scanning
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  /// Connect to a device
  Future<void> connect(BluetoothDevice device) async {
    try {
      // Disconnect any existing connection
      if (_connectedDevice != null) {
        await disconnect();
      }

      _connectedDevice = device;

      // Connect to device
      await device.connect(
        timeout: const Duration(seconds: 30),
        autoConnect: false,
      );

      // Listen to connection state
      device.connectionState.listen((state) {
        _connectionStateController.add(state);

        if (state == BluetoothConnectionState.disconnected) {
          _cleanup();
        }
      });

      // Discover services
      await _discoverServices();

      // Read device info
      await _readDeviceInfo();

      // Setup notifications
      await _setupNotifications();
    } catch (e) {
      _cleanup();
      rethrow;
    }
  }

  /// Disconnect from device
  Future<void> disconnect() async {
    try {
      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
      }
    } catch (_) {
      // Ignore disconnect errors
    } finally {
      _cleanup();
    }
  }

  /// Discover services and characteristics
  Future<void> _discoverServices() async {
    if (_connectedDevice == null) return;

    _discoveredServices = await _connectedDevice!.discoverServices();

    // Find main service (FFE0) - compare lowercase
    final mainServiceUuidLower = BleConstants.mainServiceUuid.toLowerCase();
    BluetoothService? mainService;

    for (final service in _discoveredServices!) {
      if (service.uuid.toString().toLowerCase() == mainServiceUuidLower) {
        mainService = service;
        break;
      }
    }

    if (mainService == null) {
      // Try short UUID match
      for (final service in _discoveredServices!) {
        final uuid = service.uuid.toString().toLowerCase();
        if (uuid.contains('ffe0')) {
          mainService = service;
          break;
        }
      }
    }

    if (mainService == null) {
      throw Exception(
          'Main service FFE0 not found. Available services: ${_discoveredServices!.map((s) => s.uuid.toString()).join(", ")}');
    }

    // Find write characteristic (FFE1)
    final writeUuidLower = BleConstants.writeCharacteristicUuid.toLowerCase();
    for (final c in mainService.characteristics) {
      final charUuid = c.uuid.toString().toLowerCase();
      if (charUuid == writeUuidLower || charUuid.contains('ffe1')) {
        _writeCharacteristic = c;
        break;
      }
    }

    // Find notify characteristic (FFE2)
    final notifyUuidLower =
        BleConstants.readNotifyCharacteristicUuid.toLowerCase();
    for (final c in mainService.characteristics) {
      final charUuid = c.uuid.toString().toLowerCase();
      if (charUuid == notifyUuidLower || charUuid.contains('ffe2')) {
        _notifyCharacteristic = c;
        break;
      }
    }

    // If not found in FFE0, check if there's a single service with these characteristics
    if (_writeCharacteristic == null || _notifyCharacteristic == null) {
      for (final service in _discoveredServices!) {
        for (final c in service.characteristics) {
          final charUuid = c.uuid.toString().toLowerCase();
          if (_writeCharacteristic == null && charUuid.contains('ffe1')) {
            _writeCharacteristic = c;
          }
          if (_notifyCharacteristic == null && charUuid.contains('ffe2')) {
            _notifyCharacteristic = c;
          }
        }
      }
    }

    if (_writeCharacteristic == null) {
      throw Exception('Write characteristic FFE1 not found');
    }
    if (_notifyCharacteristic == null) {
      throw Exception('Notify characteristic FFE2 not found');
    }
  }

  /// Read device information
  Future<void> _readDeviceInfo() async {
    if (_connectedDevice == null || _discoveredServices == null) return;

    try {
      // Find device info service - use cached services
      BluetoothService? deviceInfoService;
      final deviceInfoUuidLower =
          BleConstants.deviceInfoServiceUuid.toLowerCase();

      for (final service in _discoveredServices!) {
        final uuid = service.uuid.toString().toLowerCase();
        if (uuid == deviceInfoUuidLower || uuid.contains('180a')) {
          deviceInfoService = service;
          break;
        }
      }

      if (deviceInfoService == null) {
        // Create basic device info without firmware/hardware versions
        final deviceInfo = BleDeviceInfo(
          deviceId: _connectedDevice!.remoteId.toString(),
          name: _connectedDevice!.platformName,
          firmwareVersion: 'Unknown',
          hardwareVersion: 'Unknown',
        );
        _deviceInfoController.add(deviceInfo);
        return;
      }

      String firmwareVersion = 'Unknown';
      String hardwareVersion = 'Unknown';

      // Read firmware version
      try {
        final fwUuidLower =
            BleConstants.firmwareVersionCharacteristicUuid.toLowerCase();
        for (final c in deviceInfoService.characteristics) {
          final charUuid = c.uuid.toString().toLowerCase();
          if (charUuid == fwUuidLower || charUuid.contains('2a26')) {
            final fwValue = await c.read();
            firmwareVersion = String.fromCharCodes(fwValue);
            break;
          }
        }
      } catch (_) {
        // Ignore firmware read errors
      }

      // Read hardware version
      try {
        final hwUuidLower =
            BleConstants.hardwareVersionCharacteristicUuid.toLowerCase();
        for (final c in deviceInfoService.characteristics) {
          final charUuid = c.uuid.toString().toLowerCase();
          if (charUuid == hwUuidLower || charUuid.contains('2a27')) {
            final hwValue = await c.read();
            hardwareVersion = String.fromCharCodes(hwValue);
            break;
          }
        }
      } catch (_) {
        // Ignore hardware read errors
      }

      final deviceInfo = BleDeviceInfo(
        deviceId: _connectedDevice!.remoteId.toString(),
        name: _connectedDevice!.platformName,
        firmwareVersion: firmwareVersion,
        hardwareVersion: hardwareVersion,
      );

      _deviceInfoController.add(deviceInfo);
    } catch (_) {
      // Ignore device info read errors
    }
  }

  /// Setup notifications for the notify characteristic
  Future<void> _setupNotifications() async {
    if (_notifyCharacteristic == null) return;

    try {
      await _notifyCharacteristic!.setNotifyValue(true);
    } catch (_) {
      rethrow;
    }
  }

  /// Get notification stream
  Stream<List<int>> get notificationStream {
    if (_notifyCharacteristic == null) {
      return const Stream.empty();
    }
    return _notifyCharacteristic!.lastValueStream;
  }

  /// Write data to device
  /// Automatically detects if characteristic supports writeWithoutResponse
  Future<void> write(List<int> data, {bool withoutResponse = false}) async {
    if (_writeCharacteristic == null) {
      throw Exception('Write characteristic not available');
    }

    try {
      // Check if characteristic supports the requested write type
      final supportsWriteNoResp =
          _writeCharacteristic!.properties.writeWithoutResponse;
      final supportsWrite = _writeCharacteristic!.properties.write;

      // Use writeWithoutResponse only if requested AND supported
      // Otherwise fall back to regular write
      bool useNoResponse = withoutResponse && supportsWriteNoResp;

      // If neither is supported, this is an error
      if (!supportsWrite && !supportsWriteNoResp) {
        throw Exception('Characteristic does not support any write operation');
      }

      // If we wanted no response but it's not supported, use regular write
      if (withoutResponse && !supportsWriteNoResp && supportsWrite) {
        useNoResponse = false;
      }

      await _writeCharacteristic!.write(
        data,
        withoutResponse: useNoResponse,
      );
    } catch (_) {
      rethrow;
    }
  }

  void _cleanup() {
    _connectedDevice = null;
    _writeCharacteristic = null;
    _notifyCharacteristic = null;
    _discoveredServices = null;
    _deviceInfoController.add(null);
    _connectionStateController.add(BluetoothConnectionState.disconnected);
  }

  void dispose() {
    _connectionStateController.close();
    _deviceInfoController.close();
    _scanResultsController.close();
  }
}
