import 'vehicle_status.dart';
import 'vehicle_type.dart';

class Vehicle {
  final int? id;
  final String vehicleNumber;
  final String company;
  final VehicleType type;
  final String brand;
  final String model;
  final VehicleStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Vehicle({
    this.id,
    required this.vehicleNumber,
    required this.company,
    required this.type,
    required this.brand,
    required this.model,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  String get displayName => '$brand $model';

  bool get isNew => id == null;

  /// Parse from backend JSON (inside ApiResponse.data)
  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] as int?,
      vehicleNumber: json['vehicleNumber'] as String,
      company: json['company'] as String,
      type: VehicleType.fromApi(json['type'] as String),
      brand: json['brand'] as String,
      model: json['model'] as String,
      status: VehicleStatus.fromApi(json['status'] as String),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// Serialize for create/update request body
  Map<String, dynamic> toJson() {
    return {
      'vehicleNumber': vehicleNumber,
      'company': company,
      'type': type.apiValue,
      'brand': brand,
      'model': model,
      'status': status.apiValue,
    };
  }

  Vehicle copyWith({
    int? id,
    String? vehicleNumber,
    String? company,
    VehicleType? type,
    String? brand,
    String? model,
    VehicleStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Vehicle(
      id: id ?? this.id,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      company: company ?? this.company,
      type: type ?? this.type,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
