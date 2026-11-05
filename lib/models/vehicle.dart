import 'vehicle_status.dart';
import 'vehicle_type.dart';

class Vehicle {
  final String id;
  final String vehicleNumber;
  final String company;
  final VehicleType type;
  final String brand;
  final String model;
  final VehicleStatus status;

  const Vehicle({
    required this.id,
    required this.vehicleNumber,
    required this.company,
    required this.type,
    required this.brand,
    required this.model,
    required this.status,
  });

  String get displayName => '$brand $model';

  Vehicle copyWith({
    String? id,
    String? vehicleNumber,
    String? company,
    VehicleType? type,
    String? brand,
    String? model,
    VehicleStatus? status,
  }) {
    return Vehicle(
      id: id ?? this.id,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      company: company ?? this.company,
      type: type ?? this.type,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      status: status ?? this.status,
    );
  }
}
