import 'package:get_it/get_it.dart';
import 'ble_connection_service.dart';
import 'vehicle_data_service.dart';

final getIt = GetIt.instance;

/// Setup service locator
void setupServiceLocator() {
  // BLE Connection Service (Singleton)
  getIt.registerLazySingleton<BleConnectionService>(
    () => BleConnectionService(),
  );

  // Vehicle Data Service (Singleton)
  getIt.registerLazySingleton<VehicleDataService>(
    () => VehicleDataService(getIt<BleConnectionService>()),
  );
}

/// Clean up services
void disposeServices() {
  getIt<VehicleDataService>().dispose();
  getIt<BleConnectionService>().dispose();
}
