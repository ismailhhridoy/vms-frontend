import 'package:flutter/foundation.dart';
import '../models/vehicle.dart';
import '../models/vehicle_status.dart';
import '../models/vehicle_type.dart';

class MockVehicleRepository extends ChangeNotifier {
  MockVehicleRepository._();

  static final MockVehicleRepository instance = MockVehicleRepository._();

  final List<Vehicle> _vehicles = [
    const Vehicle(
      id: 'vms-01',
      vehicleNumber: 'SG-TRK-1042',
      company: 'Stark Logistics',
      type: VehicleType.truck,
      brand: 'Ford',
      model: 'F-150 Lightning',
      status: VehicleStatus.active,
    ),
    const Vehicle(
      id: 'vms-02',
      vehicleNumber: 'SG-SED-2018',
      company: 'Stark Industries',
      type: VehicleType.sedan,
      brand: 'Toyota',
      model: 'Camry Hybrid',
      status: VehicleStatus.active,
    ),
    const Vehicle(
      id: 'vms-03',
      vehicleNumber: 'SG-EV-3091',
      company: 'Stark Clean Energy',
      type: VehicleType.electric,
      brand: 'Tesla',
      model: 'Model Y',
      status: VehicleStatus.active,
    ),
    const Vehicle(
      id: 'vms-04',
      vehicleNumber: 'SG-VAN-4005',
      company: 'Stark Logistics',
      type: VehicleType.van,
      brand: 'Mercedes-Benz',
      model: 'Sprinter 2500',
      status: VehicleStatus.maintenance,
    ),
    const Vehicle(
      id: 'vms-05',
      vehicleNumber: 'SG-SUV-5120',
      company: 'Stark Security',
      type: VehicleType.suv,
      brand: 'Chevrolet',
      model: 'Tahoe Premier',
      status: VehicleStatus.active,
    ),
    const Vehicle(
      id: 'vms-06',
      vehicleNumber: 'SG-TRK-1089',
      company: 'Stark Aerospace',
      type: VehicleType.truck,
      brand: 'Volvo',
      model: 'VNL 860',
      status: VehicleStatus.inactive,
    ),
    const Vehicle(
      id: 'vms-07',
      vehicleNumber: 'SG-SED-2044',
      company: 'Stark Industries',
      type: VehicleType.sedan,
      brand: 'Honda',
      model: 'Accord Touring',
      status: VehicleStatus.active,
    ),
    const Vehicle(
      id: 'vms-08',
      vehicleNumber: 'SG-EV-3012',
      company: 'Stark Clean Energy',
      type: VehicleType.electric,
      brand: 'Rivian',
      model: 'R1T Adventure',
      status: VehicleStatus.maintenance,
    ),
  ];

  static const List<String> defaultCompanies = [
    'Stark Industries',
    'Stark Logistics',
    'Stark Security',
    'Stark Aerospace',
    'Stark Clean Energy',
  ];

  List<Vehicle> get vehicles => List.unmodifiable(_vehicles);

  List<String> get companies {
    final set = <String>{...defaultCompanies};
    for (final v in _vehicles) {
      if (v.company.isNotEmpty) set.add(v.company);
    }
    return set.toList()..sort();
  }

  int get totalCount => _vehicles.length;
  int get activeCount =>
      _vehicles.where((v) => v.status == VehicleStatus.active).length;
  int get maintenanceCount =>
      _vehicles.where((v) => v.status == VehicleStatus.maintenance).length;
  int get inactiveCount =>
      _vehicles.where((v) => v.status == VehicleStatus.inactive).length;

  List<Vehicle> filter({
    String? searchQuery,
    VehicleStatus? statusFilter,
    String? companyFilter,
  }) {
    return _vehicles.where((vehicle) {
      final matchesStatus =
          statusFilter == null || vehicle.status == statusFilter;

      final matchesCompany = companyFilter == null ||
          companyFilter.isEmpty ||
          vehicle.company == companyFilter;

      final query = (searchQuery ?? '').trim().toLowerCase();
      if (query.isEmpty) {
        return matchesStatus && matchesCompany;
      }

      final matchesQuery = vehicle.vehicleNumber.toLowerCase().contains(query) ||
          vehicle.company.toLowerCase().contains(query) ||
          vehicle.brand.toLowerCase().contains(query) ||
          vehicle.model.toLowerCase().contains(query) ||
          vehicle.type.label.toLowerCase().contains(query) ||
          vehicle.status.label.toLowerCase().contains(query);

      return matchesStatus && matchesCompany && matchesQuery;
    }).toList();
  }

  void addVehicle(Vehicle vehicle) {
    _vehicles.insert(0, vehicle);
    notifyListeners();
  }

  void updateVehicle(Vehicle vehicle) {
    final index = _vehicles.indexWhere((v) => v.id == vehicle.id);
    if (index != -1) {
      _vehicles[index] = vehicle;
      notifyListeners();
    }
  }

  void deleteVehicle(String id) {
    _vehicles.removeWhere((v) => v.id == id);
    notifyListeners();
  }
}
