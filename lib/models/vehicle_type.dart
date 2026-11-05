import 'package:flutter/material.dart';

enum VehicleType {
  sedan('Sedan', Icons.directions_car_rounded),
  suv('SUV', Icons.directions_car_filled_rounded),
  truck('Truck', Icons.local_shipping_rounded),
  van('Van', Icons.airport_shuttle_rounded),
  electric('Electric Vehicle', Icons.electric_car_rounded);

  final String label;
  final IconData icon;

  const VehicleType(this.label, this.icon);

  /// The uppercase string sent to/from the backend API
  String get apiValue => name.toUpperCase();

  /// Parse from backend API string (e.g. "SEDAN", "TRUCK")
  static VehicleType fromApi(String value) {
    return VehicleType.values.firstWhere(
      (e) => e.name.toUpperCase() == value.toUpperCase(),
      orElse: () => VehicleType.sedan,
    );
  }
}
