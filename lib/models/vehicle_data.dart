import 'package:equatable/equatable.dart';

/// Live vehicle data from BLE device
class VehicleData extends Equatable {
  final double batteryVoltage; // V
  final double batteryCurrent; // A
  final int rpm; // Revolutions per minute
  final double power; // KW
  final double speed; // km/h or mph
  final double temperature; // °C
  final int stateOfCharge; // % (0-100)
  final double throttleVoltage; // V
  final List<String> errorCodes;
  final DateTime timestamp;

  const VehicleData({
    this.batteryVoltage = 0.0,
    this.batteryCurrent = 0.0,
    this.rpm = 0,
    this.power = 0.0,
    this.speed = 0.0,
    this.temperature = 0.0,
    this.stateOfCharge = 0,
    this.throttleVoltage = 0.0,
    this.errorCodes = const [],
    required this.timestamp,
  });

  VehicleData copyWith({
    double? batteryVoltage,
    double? batteryCurrent,
    int? rpm,
    double? power,
    double? speed,
    double? temperature,
    int? stateOfCharge,
    double? throttleVoltage,
    List<String>? errorCodes,
    DateTime? timestamp,
  }) {
    return VehicleData(
      batteryVoltage: batteryVoltage ?? this.batteryVoltage,
      batteryCurrent: batteryCurrent ?? this.batteryCurrent,
      rpm: rpm ?? this.rpm,
      power: power ?? this.power,
      speed: speed ?? this.speed,
      temperature: temperature ?? this.temperature,
      stateOfCharge: stateOfCharge ?? this.stateOfCharge,
      throttleVoltage: throttleVoltage ?? this.throttleVoltage,
      errorCodes: errorCodes ?? this.errorCodes,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  factory VehicleData.initial() {
    return VehicleData(
      timestamp: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        batteryVoltage,
        batteryCurrent,
        rpm,
        power,
        speed,
        temperature,
        stateOfCharge,
        throttleVoltage,
        errorCodes,
        timestamp,
      ];
}
