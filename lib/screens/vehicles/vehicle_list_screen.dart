import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/network/api_client.dart';
import '../../core/routes/app_routes.dart';
import '../../data/vehicle_repository.dart';
import '../../models/vehicle.dart';
import '../../models/vehicle_status.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/status_badge.dart';

class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({super.key});

  @override
  State<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
  final _searchController = TextEditingController();
  VehicleStatus? _selectedStatusFilter;
  String? _selectedCompanyFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    await VehicleRepository.instance.fetchVehicles(
      searchQuery: _searchController.text,
      statusFilter: _selectedStatusFilter,
      companyFilter: _selectedCompanyFilter,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearAllFilters() {
    setState(() {
      _searchController.clear();
      _selectedStatusFilter = null;
      _selectedCompanyFilter = null;
    });
    _loadData();
  }

  bool get _hasActiveFilters =>
      _searchController.text.trim().isNotEmpty ||
      _selectedStatusFilter != null ||
      _selectedCompanyFilter != null;

  void _onDeleteVehicle(Vehicle vehicle) {
    if (vehicle.id == null) return;

    ConfirmationDialog.show(
      context,
      title: AppStrings.deleteConfirmTitle,
      message:
          'Are you sure you want to remove ${vehicle.vehicleNumber} (${vehicle.brand} ${vehicle.model} - ${vehicle.company}) from Stark Group fleet records?',
      onConfirm: () async {
        try {
          await VehicleRepository.instance.deleteVehicle(vehicle.id!);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${vehicle.vehicleNumber} successfully removed.'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF16A34A),
            ),
          );
        } on ApiException catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Delete failed: ${e.userFriendlyMessage}'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.error,
            ),
          );
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete vehicle: $e'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = VehicleRepository.instance;

    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        final filteredVehicles = repo.filter(
          searchQuery: _searchController.text,
          statusFilter: _selectedStatusFilter,
          companyFilter: _selectedCompanyFilter,
        );

        return Scaffold(
          backgroundColor: AppColors.background,
          body: RefreshIndicator(
            onRefresh: _loadData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(repo, filteredVehicles.length),
                  const SizedBox(height: 20),
                  _buildStatCards(repo),
                  const SizedBox(height: 24),
                  _buildFilterBar(repo),
                  const SizedBox(height: 16),
                  _buildTableCard(repo, filteredVehicles),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(VehicleRepository repo, int filteredCount) {
    final totalFleetCount = repo.totalCount;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    AppStrings.vehicleListTitle,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      _hasActiveFilters
                          ? '$filteredCount of $totalFleetCount'
                          : '$totalFleetCount Total',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (repo.isLoading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      tooltip: 'Refresh fleet data from server',
                      onPressed: _loadData,
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                AppStrings.vehicleListSubtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCards(VehicleRepository repo) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 1000
            ? 4
            : (constraints.maxWidth >= 600 ? 2 : 1);

        final cards = [
          StatCard(
            title: 'Total Fleet',
            value: '${repo.totalCount}',
            icon: Icons.directions_car_rounded,
            iconColor: AppColors.primary,
            iconBackgroundColor: AppColors.primary.withValues(alpha: 0.1),
          ),
          StatCard(
            title: 'Active Vehicles',
            value: '${repo.activeCount}',
            icon: Icons.check_circle_outline_rounded,
            iconColor: const Color(0xFF16A34A),
            iconBackgroundColor: const Color(0xFFDCFCE7),
          ),
          StatCard(
            title: 'In Maintenance',
            value: '${repo.maintenanceCount}',
            icon: Icons.build_circle_outlined,
            iconColor: const Color(0xFFD97706),
            iconBackgroundColor: const Color(0xFFFEF3C7),
          ),
          StatCard(
            title: 'Inactive Fleet',
            value: '${repo.inactiveCount}',
            icon: Icons.pause_circle_outline_rounded,
            iconColor: const Color(0xFF64748B),
            iconBackgroundColor: const Color(0xFFF1F5F9),
          ),
        ];

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 104,
          ),
          itemBuilder: (context, index) => cards[index],
        );
      },
    );
  }

  Widget _buildFilterBar(VehicleRepository repo) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxWidth: 360, minWidth: 260),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _loadData(),
                    decoration: InputDecoration(
                      hintText: AppStrings.searchPlaceholder,
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                                _loadData();
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Company:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        DropdownButton<String?>(
                          value: _selectedCompanyFilter,
                          underline: const SizedBox(),
                          borderRadius: BorderRadius.circular(8),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text(AppStrings.filterAllCompany),
                            ),
                            ...repo.companies.map(
                              (c) => DropdownMenuItem<String?>(
                                value: c,
                                child: Text(c),
                              ),
                            ),
                          ],
                          onChanged: (comp) {
                            setState(() => _selectedCompanyFilter = comp);
                            _loadData();
                          },
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Status:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        DropdownButton<VehicleStatus?>(
                          value: _selectedStatusFilter,
                          underline: const SizedBox(),
                          borderRadius: BorderRadius.circular(8),
                          items: [
                            const DropdownMenuItem<VehicleStatus?>(
                              value: null,
                              child: Text(AppStrings.filterAllStatus),
                            ),
                            ...VehicleStatus.values.map(
                              (status) => DropdownMenuItem<VehicleStatus?>(
                                value: status,
                                child: Text(status.label),
                              ),
                            ),
                          ],
                          onChanged: (status) {
                            setState(() => _selectedStatusFilter = status);
                            _loadData();
                          },
                        ),
                      ],
                    ),
                    if (_hasActiveFilters)
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.error,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        onPressed: _clearAllFilters,
                        icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                        label: const Text(
                          'Reset Filters',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableCard(VehicleRepository repo, List<Vehicle> vehicles) {
    if (repo.isLoading && repo.vehicles.isEmpty) {
      return Card(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 80),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text(
                'Connecting to backend and loading fleet data...',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    if (repo.hasError && repo.vehicles.isEmpty) {
      return Card(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cloud_off_rounded,
                  size: 36,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Unable to Load Fleet Data',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Text(
                  repo.errorMessage ?? 'An error occurred while connecting to the backend server.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry Connection'),
              ),
            ],
          ),
        ),
      );
    }

    if (vehicles.isEmpty) {
      return _buildEmptyState(repo.totalCount);
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          if (repo.hasError)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColors.error.withValues(alpha: 0.1),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Failed to sync with server: ${repo.errorMessage}',
                      style: const TextStyle(color: AppColors.error, fontSize: 12),
                    ),
                  ),
                  TextButton(
                    onPressed: _loadData,
                    child: const Text('Retry', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    headingRowHeight: 48,
                    dataRowMinHeight: 62,
                    dataRowMaxHeight: 68,
                    columnSpacing: 28,
                    horizontalMargin: 20,
                    columns: const [
                      DataColumn(
                        label: Text(
                          AppStrings.fieldVehicleNumber,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          AppStrings.fieldStatus,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          AppStrings.fieldCompany,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          AppStrings.fieldBrand,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          AppStrings.fieldModel,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          AppStrings.fieldType,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Actions',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    rows: vehicles.map((vehicle) {
                      return DataRow(
                        cells: [
                          // Highlighted Vehicle Number
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.primaryLight
                                      .withValues(alpha: 0.28),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.tag_rounded,
                                    size: 13,
                                    color: AppColors.primary.withValues(alpha: 0.7),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    vehicle.vehicleNumber,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'monospace',
                                      fontSize: 13,
                                      color: AppColors.primary,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Highlighted Status Badge
                          DataCell(StatusBadge(status: vehicle.status)),

                          // Company
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.business_rounded,
                                  size: 16,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  vehicle.company,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Brand
                          DataCell(
                            Text(
                              vehicle.brand,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),

                          // Model
                          DataCell(
                            Text(
                              vehicle.model,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),

                          // Type
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 13,
                                  backgroundColor:
                                      AppColors.primary.withValues(alpha: 0.08),
                                  child: Icon(
                                    vehicle.type.icon,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  vehicle.type.label,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Clear, Distinct Actions
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Clear Edit Action
                                Tooltip(
                                  message: 'Edit vehicle specifications',
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () async {
                                      await Navigator.of(context).pushNamed(
                                        AppRoutes.vehicleEdit,
                                        arguments: vehicle,
                                      );
                                      await _loadData();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.2),
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.edit_outlined,
                                            size: 14,
                                            color: AppColors.primary,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Edit',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Clear Delete Action
                                Tooltip(
                                  message: 'Delete vehicle record',
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () => _onDeleteVehicle(vehicle),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.error
                                            .withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColors.error
                                              .withValues(alpha: 0.2),
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.delete_outline_rounded,
                                            size: 14,
                                            color: AppColors.error,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Delete',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.error,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(int totalFleetCount) {
    final isFiltered = _hasActiveFilters && totalFleetCount > 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Layered circular icon badge
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isFiltered
                        ? const Color(0xFFF1F5F9)
                        : AppColors.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isFiltered
                          ? const Color(0xFFE2E8F0)
                          : AppColors.primary.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isFiltered
                          ? Icons.filter_alt_off_rounded
                          : Icons.directions_car_filled_outlined,
                      size: 38,
                      color: isFiltered
                          ? AppColors.textSecondary
                          : AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  isFiltered
                      ? 'No Vehicles Match Your Filter'
                      : 'No Vehicles Registered Yet',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isFiltered
                      ? 'We could not find any vehicle records matching your search query or filter selection. Try adjusting or clearing your filters.'
                      : 'Get started by registering the first vehicle asset into Stark Group fleet operations.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                if (isFiltered)
                  OutlinedButton.icon(
                    onPressed: _clearAllFilters,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Reset All Filters'),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.of(context).pushNamed(AppRoutes.vehicleNew);
                      await _loadData();
                    },
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text(AppStrings.registerVehicle),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
