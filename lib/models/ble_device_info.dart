import 'package:equatable/equatable.dart';

/// BLE Device Information
class BleDeviceInfo extends Equatable {
  final String deviceId;
  final String name;
  final String firmwareVersion;
  final String hardwareVersion;
  final int rssi;

  const BleDeviceInfo({
    required this.deviceId,
    required this.name,
    this.firmwareVersion = '',
    this.hardwareVersion = '',
    this.rssi = 0,
  });

  BleDeviceInfo copyWith({
    String? deviceId,
    String? name,
    String? firmwareVersion,
    String? hardwareVersion,
    int? rssi,
  }) {
    return BleDeviceInfo(
      deviceId: deviceId ?? this.deviceId,
      name: name ?? this.name,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      hardwareVersion: hardwareVersion ?? this.hardwareVersion,
      rssi: rssi ?? this.rssi,
    );
  }

  @override
  List<Object?> get props => [deviceId, name, firmwareVersion, hardwareVersion, rssi];
}
