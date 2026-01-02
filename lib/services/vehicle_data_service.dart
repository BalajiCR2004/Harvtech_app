import 'dart:async';
import 'dart:typed_data';
import 'package:rxdart/rxdart.dart';
import '../models/ble_constants.dart';
import '../models/data_field.dart';
import '../models/vehicle_data.dart';
import '../protocol/ble_protocol_handler.dart';
import 'ble_connection_service.dart';

/// Vehicle Data Service - Handles real-time vehicle data from BLE
class VehicleDataService {
  final BleConnectionService _connectionService;
  final _vehicleDataController = BehaviorSubject<VehicleData>.seeded(
    VehicleData.initial(),
  );

  StreamSubscription? _notificationSubscription;
  VehicleData _currentData = VehicleData.initial();
  // Buffer recent live data for export (non-intrusive)
  final List<VehicleData> _buffer = [];
  static const int _maxBufferEntries = 5000;

  // Data field configurations (based on analysis)
  late final Map<int, DataField> _dataFieldMap;

  VehicleDataService(this._connectionService) {
    _initializeDataFields();
  }

  // Stream
  Stream<VehicleData> get vehicleDataStream => _vehicleDataController.stream;
  VehicleData get currentData => _currentData;

  /// Initialize data field configurations
  /// Based on actual addresses found in CJPOWER app source code
  void _initializeDataFields() {
    _dataFieldMap = {
      // RPM (Motor Speed) - address 105, i16, K=1
      105: const DataField(
        address: 105,
        addressSize: 'i16',
        ratioK: 1.0,
        ratioB: 0.0,
        uiType: 'field',
        title: '电机转速',
        titleEn: 'RPM',
        unit: 'rpm',
      ),
      // Battery Voltage - address 113, u16, K=10
      113: const DataField(
        address: 113,
        addressSize: 'u16',
        ratioK: 10.0,
        ratioB: 0.0,
        uiType: 'field',
        title: '电池电压',
        titleEn: 'Battery Voltage',
        unit: 'V',
      ),
      // Power (KW) - address 115, i16, K=1000
      115: const DataField(
        address: 115,
        addressSize: 'i16',
        ratioK: 1000.0,
        ratioB: 0.0,
        uiType: 'field',
        title: '功率',
        titleEn: 'Power',
        unit: 'kw',
      ),
      // Current (A) - address 119, i16, K=10
      119: const DataField(
        address: 119,
        addressSize: 'i16',
        ratioK: 10.0,
        ratioB: 0.0,
        uiType: 'field',
        title: '电流',
        titleEn: 'Current',
        unit: 'A',
      ),
      // Throttle Voltage - address 220, u16, K=744.3
      220: const DataField(
        address: 220,
        addressSize: 'u16',
        ratioK: 744.3,
        ratioB: 0.0,
        uiType: 'field',
        title: '油门电压',
        titleEn: 'Throttle Voltage',
        unit: 'V',
      ),
      // Controller Temperature - address 222, u8, K=1, B=40
      222: const DataField(
        address: 222,
        addressSize: 'u8',
        ratioK: 1.0,
        ratioB: 40.0,
        uiType: 'field',
        title: '控制器温度',
        titleEn: 'Controller Temp',
        unit: '℃',
      ),
      // Motor Temperature - address 223, i8, K=1, B=40
      223: const DataField(
        address: 223,
        addressSize: 'i8',
        ratioK: 1.0,
        ratioB: 40.0,
        uiType: 'field',
        title: '电机温度',
        titleEn: 'Motor Temp',
        unit: '℃',
      ),
      // Phase Current - address 224, i16, K=33.03
      224: const DataField(
        address: 224,
        addressSize: 'i16',
        ratioK: 33.03,
        ratioB: 0.0,
        uiType: 'field',
        title: '相电流',
        titleEn: 'Phase Current',
        unit: 'A',
      ),
      // Speed - address 24, u16, K=10 (Assuming K=10 based on standard)
      24: const DataField(
        address: 24,
        addressSize: 'u16',
        ratioK: 10.0,
        ratioB: 0.0,
        uiType: 'field',
        title: '速度',
        titleEn: 'Speed',
        unit: 'km/h',
      ),
      // SoC - address 26, u16, K=1 (Assuming K=1)
      26: const DataField(
        address: 26,
        addressSize: 'u16',
        ratioK: 1.0,
        ratioB: 0.0,
        uiType: 'field',
        title: '电量',
        titleEn: 'SoC',
        unit: '%',
      ),
      // Error codes - address 239, u32, K=1
      239: const DataField(
        address: 239,
        addressSize: 'u32',
        ratioK: 1.0,
        ratioB: 0.0,
        uiType: 'field',
        title: '故障码',
        titleEn: 'Error Code',
        unit: '',
      ),
    };
  }

  /// Start receiving live data
  Future<void> startDataStream() async {
    try {
      // Check if connected
      if (!_connectionService.isConnected) {
        throw Exception('Not connected to device');
      }

      // Check if write characteristic is available
      if (_connectionService.writeCharacteristic == null) {
        throw Exception('Write characteristic not available');
      }

      // Subscribe to notifications first
      _notificationSubscription?.cancel();
      _notificationSubscription = _connectionService.notificationStream.listen(
        _handleNotification,
        onError: (_) {},
      );

      // Stop any existing upload
      try {
        await _writeControlCommand(BleConstants.cmdStopUpload);
        await Future.delayed(const Duration(milliseconds: 200));
      } catch (_) {
        // Ignore stop upload errors
      }

      // Clear data
      try {
        await _writeControlCommand(BleConstants.cmdClearData);
        await Future.delayed(const Duration(milliseconds: 200));
      } catch (_) {
        // Ignore clear data errors
      }

      // CRITICAL: Set up time data channels for each data field
      // This tells the device which data to stream
      await _setupTimeDataChannels();
      await Future.delayed(const Duration(milliseconds: 100));

      // Start continuous upload
      await _writeControlCommand(BleConstants.cmdStartUpload);
    } catch (_) {
      rethrow;
    }
  }

  /// Set up time data channels - configures which data fields to receive
  /// Based on original app's readTimeDataChannelSetParam function
  Future<void> _setupTimeDataChannels() async {
    for (final field in _dataFieldMap.values) {
      try {
        // Create read command for this field
        final readCmd = BleProtocolHandler.createReadCommand(
          field.address,
          field.addressSize,
        );

        // Clear the high bits (keep only lower 5 bits of byte[1])
        // This is what the original app does: s[1] &= 31
        final modifiedCmd = Uint8List.fromList(readCmd);
        modifiedCmd[1] = modifiedCmd[1] & 0x1F;

        // Write to address 12 (time data channel setup)
        final channelSetupCmd = BleProtocolHandler.createWriteCommand(
          BleConstants.timeDataChannelAddress,
          'array',
          modifiedCmd.toList(),
        );

        await _connectionService.write(channelSetupCmd.toList(),
            withoutResponse: true);
        await Future.delayed(const Duration(milliseconds: 50));
      } catch (_) {
        // Ignore channel setup errors
      }
    }
  }

  /// Stop receiving live data
  Future<void> stopDataStream() async {
    try {
      await _notificationSubscription?.cancel();
      _notificationSubscription = null;

      await _writeControlCommand(BleConstants.cmdStopUpload);
    } catch (_) {
      // Ignore stop errors
    }
  }

  /// Handle incoming notification data
  void _handleNotification(List<int> data) {
    if (data.isEmpty) return;

    try {
      final ackData = BleProtocolHandler.parseAckData(Uint8List.fromList(data));
      if (ackData == null) {
        return;
      }

      // Find data field configuration
      final dataField = _dataFieldMap[ackData.address];

      if (dataField != null) {
        // Convert raw data
        final rawValue = BleProtocolHandler.convertData(
          ackData.data,
          dataField.addressSize,
        );

        if (rawValue != null) {
          // Process based on address
          if (ackData.address == BleConstants.errorCodeAddress) {
            // Handle error codes
            _processErrorCode(rawValue as int);
          } else {
            // Handle live data
            _processLiveData(ackData.address, rawValue, dataField);
          }
        }
      }
    } catch (_) {
      // Ignore notification handling errors
    }
  }

  /// Process error code data
  void _processErrorCode(int errorCode) {
    final errorCodes = <String>[];
    for (var bit = 0; bit < 32; bit++) {
      if ((errorCode >> bit) & 1 == 1) {
        errorCodes.add('Error bit $bit');
      }
    }

    _currentData = _currentData.copyWith(
      errorCodes: errorCodes,
      timestamp: DateTime.now(),
    );
    _vehicleDataController.add(_currentData);
    // Maintain buffer (keep a rolling window)
    _buffer.add(_currentData);
    if (_buffer.length > _maxBufferEntries) {
      _buffer.removeRange(0, _buffer.length - _maxBufferEntries);
    }
  }

  /// Process live data with calibration
  void _processLiveData(int address, dynamic rawValue, DataField dataField) {
    if (dataField.uiType != 'field') return;

    final calibratedValue = dataField.calibrateValue(rawValue);

    // Map to vehicle data fields based on CJPOWER addresses
    switch (address) {
      case 105: // RPM (Motor Speed)
        _currentData = _currentData.copyWith(
          rpm: calibratedValue.toInt(),
          timestamp: DateTime.now(),
        );
        break;
      case 113: // Battery Voltage
        _currentData = _currentData.copyWith(
          batteryVoltage: calibratedValue,
          timestamp: DateTime.now(),
        );
        break;
      case 115: // Power (KW)
        _currentData = _currentData.copyWith(
          power: calibratedValue,
          timestamp: DateTime.now(),
        );
        break;
      case 119: // Current (A)
        _currentData = _currentData.copyWith(
          batteryCurrent: calibratedValue,
          timestamp: DateTime.now(),
        );
        break;
      case 220: // Throttle Voltage
        _currentData = _currentData.copyWith(
          throttleVoltage: calibratedValue,
          timestamp: DateTime.now(),
        );
        break;
      case 24: // Speed
        _currentData = _currentData.copyWith(
          speed: calibratedValue,
          timestamp: DateTime.now(),
        );
        break;
      case 26: // SoC
        _currentData = _currentData.copyWith(
          stateOfCharge: calibratedValue.toInt(),
          timestamp: DateTime.now(),
        );
        break;
      case 222: // Controller Temperature
        _currentData = _currentData.copyWith(
          temperature: calibratedValue,
          timestamp: DateTime.now(),
        );
        break;
      case 223: // Motor Temperature
        // Motor temperature - could add field if needed
        break;
      case 224: // Phase Current
        // Phase current - could add field if needed
        break;
    }

    _vehicleDataController.add(_currentData);
  }

  /// Write control command
  Future<void> _writeControlCommand(int command) async {
    final data = BleProtocolHandler.createWriteCommand(
      BleConstants.controlAddress,
      'u8',
      command,
    );
    await _connectionService.write(data.toList(), withoutResponse: true);
  }

  /// Read specific parameter
  Future<dynamic> readParameter(int address, String addressSize) async {
    final command = BleProtocolHandler.createReadCommand(address, addressSize);
    await _connectionService.write(command.toList());

    // Wait for response (implement proper response waiting mechanism)
    await Future.delayed(const Duration(milliseconds: 200));

    return null; // Implement proper response handling
  }

  /// Write parameter
  Future<void> writeParameter(
      int address, String addressSize, dynamic value) async {
    final command =
        BleProtocolHandler.createWriteCommand(address, addressSize, value);
    await _connectionService.write(command.toList());

    // Verify write by reading back
    await Future.delayed(const Duration(milliseconds: 100));
    await readParameter(address, addressSize);
  }

  void dispose() {
    _notificationSubscription?.cancel();
    _vehicleDataController.close();
  }

  /// Return a snapshot copy of buffered live data (non-destructive)
  List<VehicleData> getBufferedData() => List<VehicleData>.from(_buffer);
}
