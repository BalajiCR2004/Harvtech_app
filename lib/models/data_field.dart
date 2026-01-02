import 'package:equatable/equatable.dart';

/// Data field configuration for live data
class DataField extends Equatable {
  final int address;
  final String addressSize; // u8, i8, u16, i16, u32, i32, str, array
  final double ratioK; // Calibration multiplier
  final double ratioB; // Calibration offset
  final String uiType; // field, picker, switch
  final String title;
  final String titleEn;
  final String unit;
  final String? iconPath;
  final List<dynamic>? pickerData;

  const DataField({
    required this.address,
    required this.addressSize,
    this.ratioK = 1.0,
    this.ratioB = 0.0,
    required this.uiType,
    required this.title,
    required this.titleEn,
    this.unit = '',
    this.iconPath,
    this.pickerData,
  });

  /// Apply calibration: Display Value = (MCU Value - ratioB) / ratioK
  double calibrateValue(num mcuValue) {
    if (ratioK == 0 && ratioB == 0) {
      return mcuValue.toDouble();
    }
    return (mcuValue - ratioB) / ratioK;
  }

  @override
  List<Object?> get props => [
        address,
        addressSize,
        ratioK,
        ratioB,
        uiType,
        title,
        titleEn,
        unit,
        iconPath,
        pickerData,
      ];
}
