class VehicleStats {
  final int totalCount;
  final int activeCount;
  final int maintenanceCount;
  final int inactiveCount;

  const VehicleStats({
    required this.totalCount,
    required this.activeCount,
    required this.maintenanceCount,
    required this.inactiveCount,
  });

  const VehicleStats.empty()
      : totalCount = 0,
        activeCount = 0,
        maintenanceCount = 0,
        inactiveCount = 0;

  factory VehicleStats.fromJson(Map<String, dynamic> json) {
    return VehicleStats(
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      activeCount: (json['activeCount'] as num?)?.toInt() ?? 0,
      maintenanceCount: (json['maintenanceCount'] as num?)?.toInt() ?? 0,
      inactiveCount: (json['inactiveCount'] as num?)?.toInt() ?? 0,
    );
  }
}

