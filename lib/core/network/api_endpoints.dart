class ApiEndpoints {
  ApiEndpoints._();

  static const String vehicles = '/vehicles';
  static const String vehicleStats = '/vehicles/stats';
  static const String vehicleCompanies = '/vehicles/companies';
  static const String health = '/actuator/health';

  static String vehicleById(int id) => '$vehicles/$id';
}
