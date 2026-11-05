import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/vehicle.dart';
import '../models/vehicle_stats.dart';
import '../models/vehicle_status.dart';

class VehicleRepository extends ChangeNotifier {
  final ApiClient _apiClient;

  VehicleRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  static VehicleRepository instance = VehicleRepository();

  List<Vehicle> _vehicles = [];
  VehicleStats _stats = const VehicleStats.empty();
  List<String> _companies = [];
  bool _isLoading = false;
  String? _errorMessage;

  static const List<String> defaultCompanies = [
    'Stark Industries',
    'Stark Logistics',
    'Stark Security',
    'Stark Aerospace',
    'Stark Clean Energy',
  ];

  List<Vehicle> get vehicles => List.unmodifiable(_vehicles);
  VehicleStats get stats => _stats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  List<String> get companies {
    final set = <String>{...defaultCompanies, ..._companies};
    for (final v in _vehicles) {
      if (v.company.isNotEmpty) set.add(v.company);
    }
    return set.toList()..sort();
  }

  int get totalCount => _stats.totalCount > 0 ? _stats.totalCount : _vehicles.length;
  int get activeCount => _stats.activeCount;
  int get maintenanceCount => _stats.maintenanceCount;
  int get inactiveCount => _stats.inactiveCount;

  /// Loads vehicles, fleet stats, and company filters from the backend
  Future<void> fetchVehicles({
    String? searchQuery,
    VehicleStatus? statusFilter,
    String? companyFilter,
    bool showLoading = true,
  }) async {
    if (showLoading) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final queryParams = <String, dynamic>{};
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        queryParams['search'] = searchQuery.trim();
      }
      if (statusFilter != null) {
        queryParams['status'] = statusFilter.apiValue;
      }
      if (companyFilter != null && companyFilter.trim().isNotEmpty) {
        queryParams['company'] = companyFilter.trim();
      }

      // Concurrently fetch vehicles list, stats, and companies
      final vehiclesFuture = _apiClient.get<List<Vehicle>>(
        ApiEndpoints.vehicles,
        queryParameters: queryParams,
        fromJsonT: (json) {
          if (json is List) {
            return json
                .map((e) => Vehicle.fromJson(e as Map<String, dynamic>))
                .toList();
          }
          return <Vehicle>[];
        },
      );

      final statsFuture = _apiClient.get<VehicleStats>(
        ApiEndpoints.vehicleStats,
        fromJsonT: (json) =>
            VehicleStats.fromJson(json as Map<String, dynamic>),
      );

      final companiesFuture = _apiClient.get<List<String>>(
        ApiEndpoints.vehicleCompanies,
        fromJsonT: (json) {
          if (json is List) {
            return json.map((e) => e.toString()).toList();
          }
          return <String>[];
        },
      );

      final results = await Future.wait([
        vehiclesFuture,
        statsFuture,
        companiesFuture,
      ]);

      _vehicles = (results[0].data as List<Vehicle>?) ?? [];
      _stats = (results[1].data as VehicleStats?) ?? const VehicleStats.empty();
      _companies = (results[2].data as List<String>?) ?? [];
      _errorMessage = null;
    } on ApiException catch (e) {
      _errorMessage = e.userFriendlyMessage;
    } catch (e) {
      _errorMessage = 'Unable to connect to VMS backend server. Please verify it is running on port 8080.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Client-side instant filter fallback on loaded vehicles
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

  /// Creates a vehicle via POST /api/v1/vehicles
  Future<Vehicle> createVehicle(Vehicle vehicle) async {
    final response = await _apiClient.post<Vehicle>(
      ApiEndpoints.vehicles,
      body: vehicle.toJson(),
      fromJsonT: (json) => Vehicle.fromJson(json as Map<String, dynamic>),
    );

    if (response.data == null) {
      throw const ApiException('Failed to create vehicle: empty server response');
    }

    final created = response.data!;
    // Refresh vehicle list and fleet metrics
    await fetchVehicles(showLoading: false);
    return created;
  }

  /// Updates an existing vehicle via PUT /api/v1/vehicles/{id}
  Future<Vehicle> updateVehicle(int id, Vehicle vehicle) async {
    final response = await _apiClient.put<Vehicle>(
      ApiEndpoints.vehicleById(id),
      body: vehicle.toJson(),
      fromJsonT: (json) => Vehicle.fromJson(json as Map<String, dynamic>),
    );

    if (response.data == null) {
      throw const ApiException('Failed to update vehicle: empty server response');
    }

    final updated = response.data!;
    // Refresh vehicle list and fleet metrics
    await fetchVehicles(showLoading: false);
    return updated;
  }

  /// Deletes a vehicle via DELETE /api/v1/vehicles/{id}
  Future<void> deleteVehicle(int id) async {
    await _apiClient.delete<void>(
      ApiEndpoints.vehicleById(id),
    );

    // Refresh vehicle list and fleet metrics only after successful delete
    await fetchVehicles(showLoading: false);
  }
}
