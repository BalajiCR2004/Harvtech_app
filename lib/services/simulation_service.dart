import 'dart:async';
import 'dart:math';
import '../models/vehicle_data.dart';

/// Simulation service that generates realistic fake vehicle data
/// for testing the UI without a real BLE device
class SimulationService {
  final _random = Random();
  final _dataController = StreamController<VehicleData>.broadcast();
  // In-memory buffer of recent simulated data for export
  final List<VehicleData> _buffer = [];
  static const int _maxBufferEntries = 5000;

  Timer? _simulationTimer;
  bool _isRunning = false;

  // Simulation state
  double _batteryVoltage = 72.0; // Start with full 72V battery
  double _batteryCapacity = 100.0; // Start at 100% SoC
  double _targetRpm = 0;
  double _currentRpm = 0;
  double _throttleDirection = 1; // 1 = accelerating, -1 = decelerating
  double _throttleCyclePosition = 0;
  double _temperature = 25.0;

  // Constants
  static const double maxVoltage = 72.0;
  static const double minVoltage = 54.0; // Depleted battery
  static const double maxRpm = 5000;
  static const double rpmAccelRate = 50; // RPM change per tick

  Stream<VehicleData> get dataStream => _dataController.stream;
  bool get isRunning => _isRunning;

  void startSimulation() {
    if (_isRunning) return;

    _isRunning = true;
    _resetState();

    // Run simulation at 10Hz (100ms intervals)
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _updateSimulation();
    });
  }

  void stopSimulation() {
    _isRunning = false;
    _simulationTimer?.cancel();
    _simulationTimer = null;
  }

  void _resetState() {
    _batteryVoltage = maxVoltage;
    _batteryCapacity = 100.0;
    _currentRpm = 0;
    _targetRpm = 0;
    _throttleDirection = 1;
    _throttleCyclePosition = 0;
    _temperature = 25.0;
  }

  void _updateSimulation() {
    // === THROTTLE CYCLE (back and forth 0 to 5000 RPM) ===
    _throttleCyclePosition += 0.02 * _throttleDirection;

    // Add some randomness to make it feel more natural
    final randomFactor = 0.8 + _random.nextDouble() * 0.4; // 0.8 to 1.2

    // When reaching extremes, reverse direction with some randomness
    if (_throttleCyclePosition >= 1.0) {
      _throttleDirection = -1;
      _throttleCyclePosition = 1.0;
    } else if (_throttleCyclePosition <= 0.0) {
      _throttleDirection = 1;
      _throttleCyclePosition = 0.0;
    }

    // Smooth sine-wave like throttle pattern
    final throttlePercent = (sin(_throttleCyclePosition * pi - pi / 2) + 1) / 2;

    // === BATTERY DRAIN ===
    // Battery drains based on power consumption (faster at high RPM)
    final drainRate =
        0.002 + (throttlePercent * 0.008); // 0.2% to 1% per second at 10Hz
    _batteryCapacity -= drainRate * randomFactor;

    // Clamp battery capacity
    if (_batteryCapacity < 5) {
      _batteryCapacity = 5; // Never fully deplete for demo
    }

    // Battery voltage drops as capacity drops
    final capacityFactor = _batteryCapacity / 100.0;
    _batteryVoltage = minVoltage + (maxVoltage - minVoltage) * capacityFactor;
    _batteryVoltage += (_random.nextDouble() - 0.5) * 0.5; // Small fluctuation

    // === PERFORMANCE DEGRADATION ===
    // As battery drops, max performance drops too
    final performanceFactor = 0.3 + (capacityFactor * 0.7); // 30% to 100%

    // === RPM CALCULATION ===
    _targetRpm = maxRpm * throttlePercent * performanceFactor;

    // Smooth RPM changes (motor doesn't instantly change speed)
    if (_currentRpm < _targetRpm) {
      _currentRpm += rpmAccelRate * randomFactor;
      if (_currentRpm > _targetRpm) _currentRpm = _targetRpm;
    } else if (_currentRpm > _targetRpm) {
      _currentRpm -= rpmAccelRate * 1.5 * randomFactor; // Decel faster
      if (_currentRpm < _targetRpm) _currentRpm = _targetRpm;
    }
    _currentRpm = _currentRpm.clamp(0, maxRpm);

    // === CURRENT (AMPS) CALCULATION ===
    // Current draw based on throttle position and RPM
    // Higher current at low RPM with high throttle (starting torque)
    final baseAmps = throttlePercent * 80 * performanceFactor; // 0-80A
    final startingTorqueBonus = throttlePercent > 0.3 && _currentRpm < 1000
        ? 20 * (1 - _currentRpm / 1000)
        : 0;
    final current =
        (baseAmps + startingTorqueBonus + (_random.nextDouble() - 0.5) * 5)
            .clamp(0.0, 100.0);

    // === POWER (KW) CALCULATION ===
    // P = V * I / 1000
    final power = (_batteryVoltage * current / 1000);

    // === SPEED CALCULATION ===
    // Assume speed is proportional to RPM (simple gear ratio)
    final speed = (_currentRpm / maxRpm) * 60 * performanceFactor; // 0-60 km/h

    // === TEMPERATURE ===
    // Temperature rises with power consumption
    final heatGeneration = power * 0.1; // Heat from power
    final cooling = (_temperature - 25) * 0.02; // Natural cooling
    _temperature += heatGeneration - cooling;
    _temperature = _temperature.clamp(20.0, 85.0);

    // === STATE OF CHARGE ===
    final soc = _batteryCapacity.round().clamp(0, 100);

    // === THROTTLE VOLTAGE ===
    // Simulate throttle voltage (typically 1.1V to 4.2V)
    final throttleVoltage = 1.1 + (throttlePercent * (4.2 - 1.1));

    // === BUILD VEHICLE DATA ===
    final data = VehicleData(
      rpm: _currentRpm.round(),
      speed: speed,
      batteryVoltage: _batteryVoltage,
      batteryCurrent: current,
      stateOfCharge: soc,
      power: power,
      temperature: _temperature,
      throttleVoltage: throttleVoltage,
      errorCodes: soc < 20 ? ['Low Battery Warning'] : [],
      timestamp: DateTime.now(),
    );

    _dataController.add(data);
    // Buffer data (non-intrusive append)
    _buffer.add(data);
    if (_buffer.length > _maxBufferEntries) {
      _buffer.removeRange(0, _buffer.length - _maxBufferEntries);
    }
  }

  void dispose() {
    stopSimulation();
    _dataController.close();
  }

  /// Return a snapshot copy of buffered simulation data (non-destructive)
  List<VehicleData> getBufferedData() => List<VehicleData>.from(_buffer);
}
