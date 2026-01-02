import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:rxdart/rxdart.dart';
import 'models/vehicle_data.dart';
import 'services/ble_connection_service.dart';
import 'services/vehicle_data_service.dart';
import 'services/service_locator.dart';
import 'services/simulation_service.dart';
import 'services/export_service.dart';
import 'widgets/realtime_line_chart.dart';
import 'widgets/custom_icons.dart';

void main() {
  setupServiceLocator();
  runApp(const HarvTechApp());
}

class HarvTechApp extends StatelessWidget {
  const HarvTechApp({super.key});

  static const Color primaryOrange = Color(0xFFF5A623);
  static const Color darkGrey = Color(0xFF1A1A2E);
  static const Color cardBackground = Color(0xFF16213E);
  static const Color surfaceColor = Color(0xFF0F0F1A);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HarvTech Connector',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: surfaceColor,
        primaryColor: primaryOrange,
        colorScheme: const ColorScheme.dark(
          primary: primaryOrange,
          secondary: Color(0xFF00D4FF),
          surface: cardBackground,
          onSurface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        cardTheme: CardThemeData(
          color: cardBackground,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: const VehicleDataScreen(),
    );
  }
}

class VehicleDataScreen extends StatefulWidget {
  const VehicleDataScreen({super.key});

  @override
  State<VehicleDataScreen> createState() => _VehicleDataScreenState();
}

class _VehicleDataScreenState extends State<VehicleDataScreen> {
  late final BleConnectionService _connectionService;
  late final VehicleDataService _vehicleDataService;
  final SimulationService _simulationService = SimulationService();
  bool _isStreaming = false;
  bool _isSimulating = false;

  final _voltageStreamController = BehaviorSubject<double>.seeded(0);
  final _rpmStreamController = BehaviorSubject<double>.seeded(0);
  final _powerStreamController = BehaviorSubject<double>.seeded(0);
  final _currentStreamController = BehaviorSubject<double>.seeded(0);
  final _speedStreamController = BehaviorSubject<double>.seeded(0);
  final _throttleStreamController = BehaviorSubject<double>.seeded(0);

  // For simulation data display
  VehicleData? _simulatedData;

  @override
  void initState() {
    super.initState();
    _connectionService = getIt<BleConnectionService>();
    _vehicleDataService = getIt<VehicleDataService>();

    _vehicleDataService.vehicleDataStream.listen((data) {
      if (!_isSimulating) {
        _voltageStreamController.add(data.batteryVoltage);
        _rpmStreamController.add(data.rpm.toDouble());
        _powerStreamController.add(data.power);
        _currentStreamController.add(data.batteryCurrent);
        _speedStreamController.add(data.speed);
        _throttleStreamController.add(data.throttleVoltage);
      }
    });

    // Listen to simulation data
    _simulationService.dataStream.listen((data) {
      if (_isSimulating) {
        setState(() => _simulatedData = data);
        _voltageStreamController.add(data.batteryVoltage);
        _rpmStreamController.add(data.rpm.toDouble());
        _powerStreamController.add(data.power);
        _currentStreamController.add(data.batteryCurrent);
        _speedStreamController.add(data.speed);
        _throttleStreamController.add(data.throttleVoltage);
      }
    });
  }

  @override
  void dispose() {
    _voltageStreamController.close();
    _rpmStreamController.close();
    _powerStreamController.close();
    _currentStreamController.close();
    _speedStreamController.close();
    _throttleStreamController.close();
    _simulationService.dispose();
    if (_isStreaming) {
      _vehicleDataService.stopDataStream();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSimulating,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isSimulating) {
          _stopSimulation();
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _isSimulating
                      ? Colors.cyan.withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _isSimulating
                    ? CustomIcons.simulation(size: 20, color: Colors.cyan)
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: CustomIcons.harvTechLogoImage(size: 28),
                      ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  _isSimulating ? 'SIMULATION MODE' : 'HarvTech Connector',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            if (_isSimulating) ...[
              IconButton(
                tooltip: 'Download simulation data',
                onPressed: _exportSimulationData,
                icon: const Icon(Icons.download_rounded, color: Colors.cyan),
              ),
              _buildSimulationChip(),
            ] else ...[
              StreamBuilder<BluetoothConnectionState>(
                stream: _connectionService.connectionState,
                builder: (context, snapshot) {
                  final isConnected =
                      snapshot.data == BluetoothConnectionState.connected;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isConnected)
                        IconButton(
                          tooltip: 'Download live data',
                          onPressed: _exportStreamingData,
                          icon: const Icon(Icons.download_rounded,
                              color: HarvTechApp.primaryOrange),
                        ),
                      _buildStatusChip(isConnected),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
        body: _isSimulating
            ? _buildSimulationDashboard()
            : StreamBuilder<BluetoothConnectionState>(
                stream: _connectionService.connectionState,
                builder: (context, connectionSnapshot) {
                  final isConnected =
                      connectionSnapshot.data ==
                      BluetoothConnectionState.connected;

                  if (!isConnected) {
                    return _buildNotConnectedView();
                  }

                  return StreamBuilder<VehicleData>(
                    stream: _vehicleDataService.vehicleDataStream,
                    builder: (context, dataSnapshot) {
                      if (!dataSnapshot.hasData) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(
                                color: HarvTechApp.primaryOrange,
                                strokeWidth: 2,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Awaiting data...',
                                style: TextStyle(color: Colors.grey[400]),
                              ),
                            ],
                          ),
                        );
                      }

                      final data = dataSnapshot.data!;
                      return _buildDashboard(data);
                    },
                  );
                },
              ),
      ),
    );
  }

  Widget _buildSimulationChip() {
    return GestureDetector(
      onTap: _stopSimulation,
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.cyan.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.cyan.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.stop_rounded, size: 14, color: Colors.cyan),
            SizedBox(width: 6),
            Text(
              'Stop Sim',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.cyan,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimulationDashboard() {
    final data = _simulatedData;
    if (data == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.cyan, strokeWidth: 2),
            const SizedBox(height: 16),
            Text(
              'Starting simulation...',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }
    return _buildDashboard(data);
  }

  Widget _buildStatusChip(bool isConnected) {
    return GestureDetector(
      onTap: isConnected ? _disconnect : _showDeviceList,
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isConnected
              ? const Color(0xFF00E676).withValues(alpha: 0.15)
              : Colors.grey.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isConnected
                ? const Color(0xFF00E676).withValues(alpha: 0.5)
                : Colors.grey.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isConnected ? const Color(0xFF00E676) : Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              isConnected ? 'Connected' : 'Offline',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isConnected ? const Color(0xFF00E676) : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(VehicleData data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 360;
        final horizontalPadding = isSmallScreen ? 12.0 : 16.0;
        final cardSpacing = isSmallScreen ? 8.0 : 12.0;
        final topPadding = MediaQuery.of(context).padding.top + 60;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            topPadding,
            horizontalPadding,
            24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Main 2x2 Metrics Grid
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      label: 'Battery SoC',
                      value: data.stateOfCharge.toString(),
                      unit: '%',
                      icon: CustomIcons.battery(
                        size: 28,
                        color: const Color(0xFFFFD54F),
                      ),
                      color: const Color(0xFFFFD54F),
                      gradientColors: [
                        const Color(0xFFFFD54F),
                        const Color(0xFFFF8F00),
                      ],
                      isSmallScreen: isSmallScreen,
                    ),
                  ),
                  SizedBox(width: cardSpacing),
                  Expanded(
                    child: _buildMetricCard(
                      label: 'RPM',
                      value: '${data.rpm}',
                      unit: 'rpm',
                      icon: CustomIcons.rpm(
                        size: 28,
                        color: const Color(0xFF42A5F5),
                      ),
                      color: const Color(0xFF42A5F5),
                      gradientColors: [
                        const Color(0xFF42A5F5),
                        const Color(0xFF1565C0),
                      ],
                      isSmallScreen: isSmallScreen,
                    ),
                  ),
                ],
              ),
              SizedBox(height: cardSpacing),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      label: 'Power',
                      value: data.power.toStringAsFixed(2),
                      unit: 'KW',
                      icon: CustomIcons.power(
                        size: 28,
                        color: HarvTechApp.primaryOrange,
                      ),
                      color: HarvTechApp.primaryOrange,
                      gradientColors: [
                        HarvTechApp.primaryOrange,
                        const Color(0xFFE65100),
                      ],
                      isSmallScreen: isSmallScreen,
                    ),
                  ),
                  SizedBox(width: cardSpacing),
                  Expanded(
                    child: _buildMetricCard(
                      label: 'Current',
                      value: data.batteryCurrent.toStringAsFixed(1),
                      unit: 'A',
                      icon: CustomIcons.current(
                        size: 28,
                        color: const Color(0xFFAB47BC),
                      ),
                      color: const Color(0xFFAB47BC),
                      gradientColors: [
                        const Color(0xFFAB47BC),
                        const Color(0xFF6A1B9A),
                      ],
                      isSmallScreen: isSmallScreen,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Voltage Chart (Retained as requested, but maybe user meant just update layout?
              // User said "retain rpm,current,power in widgets" and "change battery to show SoC".
              // User also said "add motor speed graph and throttle graph".
              // Existing charts were Voltage and RPM. I will Replace Voltage with Speed as per "make a graph for speed".
              // Actually user said "make a graoh for speed also" implies ADDITION.
              // So I will keep Voltage, RPM and ADD Speed, Throttle.)

              // Speed Chart
              _buildChartCard(
                title: 'Vehicle Speed',
                unit: 'km/h',
                stream: _speedStreamController.stream,
                color: const Color(0xFF00E676),
                minY: 0,
                maxY: 100,
              ),

              const SizedBox(height: 16),

              // RPM Chart
              _buildChartCard(
                title: 'Motor RPM',
                unit: 'rpm',
                stream: _rpmStreamController.stream,
                color: const Color(0xFF42A5F5),
                minY: 0,
                maxY: 6000,
              ),

              const SizedBox(height: 16),

              // Throttle Voltage Chart
              _buildChartCard(
                title: 'Throttle Voltage',
                unit: 'V',
                stream: _throttleStreamController.stream,
                color: const Color(0xFFFF5252),
                minY: 0,
                maxY: 5,
              ),

              const SizedBox(height: 16),

              // Battery Voltage Chart
              _buildChartCard(
                title: 'Battery Voltage',
                unit: 'V',
                stream: _voltageStreamController.stream,
                color: const Color(0xFFFFD54F),
                minY: 0,
                maxY: 120,
              ),

              const SizedBox(height: 24),

              // Additional Info Section
              _buildInfoSection(data),

              // Error Codes
              if (data.errorCodes.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildErrorSection(data.errorCodes),
              ],

              const SizedBox(height: 24),

              // Control Button
              _buildControlButton(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required String unit,
    required Widget icon,
    required Color color,
    required List<Color> gradientColors,
    bool isSmallScreen = false,
  }) {
    final padding = isSmallScreen ? 12.0 : 16.0;
    final valueFontSize = isSmallScreen ? 28.0 : 36.0;
    final labelFontSize = isSmallScreen ? 11.0 : 13.0;
    final unitFontSize = isSmallScreen ? 12.0 : 14.0;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: HarvTechApp.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              icon,
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: labelFontSize,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 10 : 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: valueFontSize,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  unit,
                  style: TextStyle(
                    fontSize: unitFontSize,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard({
    required String title,
    required String unit,
    required Stream<double> stream,
    required Color color,
    required double minY,
    required double maxY,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: HarvTechApp.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: RealtimeLineChart(
          title: title,
          unit: unit,
          dataStream: stream,
          lineColor: color,
          gradientColor: color,
          minY: minY,
          maxY: maxY,
          maxDataPoints: 60,
        ),
      ),
    );
  }

  Widget _buildInfoSection(VehicleData data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HarvTechApp.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: HarvTechApp.primaryOrange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: HarvTechApp.primaryOrange,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Additional Information',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.05)),
          const SizedBox(height: 16),
          _buildInfoRow(
            'State of Charge',
            '${data.stateOfCharge}%',
            _getSoCColor(data.stateOfCharge),
          ),
          _buildInfoRow(
            'Speed',
            '${data.speed.toStringAsFixed(1)} km/h',
            Colors.teal,
          ),
          _buildInfoRow(
            'Temperature',
            '${data.temperature.toStringAsFixed(1)} °C',
            Colors.redAccent,
          ),
          const SizedBox(height: 12),
          Text(
            'Last Update: ${_formatTime(data.timestamp)}',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: valueColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorSection(List<String> errors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.redAccent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Active Errors',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...errors.map(
            (error) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      error,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton() {
    return GestureDetector(
      onTap: _toggleDataStream,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isStreaming
                ? [const Color(0xFFE53935), const Color(0xFFB71C1C)]
                : [const Color(0xFF43A047), const Color(0xFF1B5E20)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isStreaming ? Icons.stop_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                _isStreaming ? 'Stop Streaming' : 'Start Streaming',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotConnectedView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        final isSmallScreen = screenWidth < 360;
        final logoSize = isSmallScreen ? 100.0 : 140.0;
        final padding = isSmallScreen ? 20.0 : 32.0;

        return Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: padding,
              vertical: screenHeight * 0.05,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo container - properly centered and sized
                Container(
                  width: logoSize + (isSmallScreen ? 32 : 48),
                  height: logoSize + (isSmallScreen ? 32 : 48),
                  decoration: BoxDecoration(
                    color: HarvTechApp.cardBackground,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: HarvTechApp.primaryOrange.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: HarvTechApp.primaryOrange.withValues(alpha: 0.1),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: CustomIcons.harvTechLogoImage(size: logoSize),
                  ),
                ),
                SizedBox(height: isSmallScreen ? 28 : 36),
                Text(
                  'Not Connected',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 22 : 26,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 16 : 24,
                  ),
                  child: Text(
                    'Connect to your HarvTech device to view real-time data',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 13 : 15,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
                SizedBox(height: isSmallScreen ? 36 : 44),
                GestureDetector(
                  onTap: _showDeviceList,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 28 : 36,
                      vertical: isSmallScreen ? 14 : 18,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [HarvTechApp.primaryOrange, Color(0xFFE65100)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomIcons.bluetoothScan(
                          size: isSmallScreen ? 18 : 22,
                          color: Colors.white,
                        ),
                        SizedBox(width: isSmallScreen ? 8 : 10),
                        Text(
                          'Scan for Devices',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: isSmallScreen ? 40 : 60),

                // Simulation button
                GestureDetector(
                  onTap: _startSimulation,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 18 : 24,
                      vertical: isSmallScreen ? 10 : 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.cyan.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.cyan.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomIcons.simulation(
                          size: isSmallScreen ? 16 : 20,
                          color: Colors.cyan.withValues(alpha: 0.8),
                        ),
                        SizedBox(width: isSmallScreen ? 8 : 10),
                        Text(
                          'Simulation (not real)',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.cyan.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Test UI with simulated 72V battery & motor',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 10 : 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _startSimulation() {
    setState(() {
      _isSimulating = true;
    });
    _simulationService.startSimulation();
    _showSnackBar('Simulation started - 72V battery with motor', Colors.cyan);
  }

  void _stopSimulation() {
    _simulationService.stopSimulation();
    setState(() {
      _isSimulating = false;
      _simulatedData = null;
    });
    // Clear chart data
    _voltageStreamController.add(0);
    _rpmStreamController.add(0);
    _powerStreamController.add(0);
    _currentStreamController.add(0);
    _showSnackBar('Simulation stopped', Colors.grey);
  }

  Color _getSoCColor(int soc) {
    if (soc > 60) return const Color(0xFF66BB6A);
    if (soc > 30) return HarvTechApp.primaryOrange;
    return Colors.redAccent;
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}';
  }

  void _showDeviceList() async {
    try {
      await _connectionService.startScan();
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        e.toString().contains('not enabled')
            ? 'Please enable Bluetooth to scan for devices'
            : 'Scan error: $e',
        Colors.redAccent,
      );
      return;
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: HarvTechApp.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: HarvTechApp.primaryOrange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.bluetooth_searching_rounded,
                      color: HarvTechApp.primaryOrange,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Available Devices',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 20,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: Colors.white.withValues(alpha: 0.05)),
            Expanded(
              child: StreamBuilder<List<ScanResult>>(
                stream: _connectionService.scanResults,
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            color: HarvTechApp.primaryOrange,
                            strokeWidth: 2,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Scanning for devices...',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final result = snapshot.data![index];
                      return _buildDeviceTile(result);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    ).then((_) => _connectionService.stopScan());
  }

  Widget _buildDeviceTile(ScanResult result) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _connect(result.device);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: HarvTechApp.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF42A5F5).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.bluetooth,
                color: Color(0xFF42A5F5),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.device.platformName.isNotEmpty
                        ? result.device.platformName
                        : 'Unknown Device',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    result.device.remoteId.toString(),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _getSignalColor(result.rssi).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.signal_cellular_alt,
                    size: 14,
                    color: _getSignalColor(result.rssi),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${result.rssi} dBm',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _getSignalColor(result.rssi),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSignalColor(int rssi) {
    if (rssi > -60) return const Color(0xFF66BB6A);
    if (rssi > -80) return HarvTechApp.primaryOrange;
    return Colors.redAccent;
  }

  void _connect(BluetoothDevice device) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: HarvTechApp.cardBackground,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: HarvTechApp.primaryOrange,
                strokeWidth: 2,
              ),
              SizedBox(height: 20),
              Text('Connecting...', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    );

    try {
      await _connectionService.connect(device);
      if (mounted) {
        Navigator.pop(context);
        _showSnackBar('Connected successfully!', const Color(0xFF66BB6A));
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showSnackBar('Connection failed: $e', Colors.redAccent);
      }
    }
  }

  void _disconnect() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: HarvTechApp.cardBackground,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: HarvTechApp.primaryOrange,
                strokeWidth: 2,
              ),
              SizedBox(height: 20),
              Text('Disconnecting...', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    );

    if (_isStreaming) {
      await _vehicleDataService.stopDataStream();
      setState(() => _isStreaming = false);
    }

    await _connectionService.disconnect();

    if (mounted) {
      Navigator.pop(context);
      _showSnackBar('Disconnected', Colors.grey);
    }
  }

  void _toggleDataStream() async {
    if (_isStreaming) {
      try {
        await _vehicleDataService.stopDataStream();
        setState(() => _isStreaming = false);
        if (mounted) {
          _showSnackBar('Data stream stopped', HarvTechApp.primaryOrange);
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar('Failed to stop: $e', Colors.redAccent);
        }
      }
    } else {
      try {
        await _vehicleDataService.startDataStream();
        setState(() => _isStreaming = true);
        if (mounted) {
          _showSnackBar('Data stream started', const Color(0xFF66BB6A));
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar('Failed to start: $e', Colors.redAccent);
        }
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _exportSimulationData() async {
    final rows = _simulationService.getBufferedData();
    if (rows.isEmpty) {
      _showSnackBar('No simulation data to export', Colors.grey);
      return;
    }

    final bytes = ExportService.createExcelBytes(rows);
    if (bytes == null) {
      _showSnackBar('Failed to create Excel file', Colors.redAccent);
      return;
    }

    // Save directly to Downloads (fallback handled in service)
    final path = await ExportService.saveToDownloads('simulation-data', bytes);
    if (path != null) {
      _showSnackBar('Simulation data saved: $path', Colors.cyan);
    } else {
      _showSnackBar('Export failed (check storage permissions)', Colors.redAccent);
    }
  }

  Future<void> _exportStreamingData() async {
    final rows = _vehicleDataService.getBufferedData();
    if (rows.isEmpty) {
      _showSnackBar('No live data to export', Colors.grey);
      return;
    }

    final bytes = ExportService.createExcelBytes(rows);
    if (bytes == null) {
      _showSnackBar('Failed to create Excel file', Colors.redAccent);
      return;
    }

    // Save directly to Downloads (fallback handled in service)
    final path = await ExportService.saveToDownloads('live-data', bytes);
    if (path != null) {
      _showSnackBar('Live data saved: $path', HarvTechApp.primaryOrange);
    } else {
      _showSnackBar('Export failed (check storage permissions)', Colors.redAccent);
    }
  }
}
