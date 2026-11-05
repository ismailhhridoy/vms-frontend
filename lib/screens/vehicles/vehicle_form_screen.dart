import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/network/api_client.dart';
import '../../data/vehicle_repository.dart';
import '../../models/vehicle.dart';
import '../../models/vehicle_status.dart';
import '../../models/vehicle_type.dart';
import '../../widgets/custom_text_field.dart';

class VehicleFormScreen extends StatefulWidget {
  final Vehicle? initialVehicle;

  const VehicleFormScreen({super.key, this.initialVehicle});

  @override
  State<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends State<VehicleFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _vehicleNumberController;
  late final TextEditingController _brandController;
  late final TextEditingController _modelController;

  late String _selectedCompany;
  late VehicleType _selectedType;
  late VehicleStatus _selectedStatus;

  bool _isSaving = false;
  String? _serverErrorMessage;

  bool get _isEditing => widget.initialVehicle != null;

  @override
  void initState() {
    super.initState();
    final v = widget.initialVehicle;

    _vehicleNumberController =
        TextEditingController(text: v?.vehicleNumber ?? '');
    _brandController = TextEditingController(text: v?.brand ?? '');
    _modelController = TextEditingController(text: v?.model ?? '');

    final availableCompanies = VehicleRepository.instance.companies;
    _selectedCompany =
        v?.company ?? availableCompanies.first;
    _selectedType = v?.type ?? VehicleType.sedan;
    _selectedStatus = v?.status ?? VehicleStatus.active;
  }

  @override
  void dispose() {
    _vehicleNumberController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _serverErrorMessage = null;
    });

    final vehicleNumber = _vehicleNumberController.text.trim().toUpperCase();
    final brand = _brandController.text.trim();
    final model = _modelController.text.trim();

    try {
      final repo = VehicleRepository.instance;

      if (_isEditing) {
        final id = widget.initialVehicle!.id;
        if (id == null) {
          throw const ApiException('Invalid vehicle record ID');
        }

        final updated = widget.initialVehicle!.copyWith(
          vehicleNumber: vehicleNumber,
          company: _selectedCompany,
          type: _selectedType,
          brand: brand,
          model: model,
          status: _selectedStatus,
        );

        await repo.updateVehicle(id, updated);
        if (!mounted) return;
        _showSuccessSnackBar('Vehicle $vehicleNumber updated successfully.');
      } else {
        final newVehicle = Vehicle(
          vehicleNumber: vehicleNumber,
          company: _selectedCompany,
          type: _selectedType,
          brand: brand,
          model: model,
          status: _selectedStatus,
        );

        await repo.createVehicle(newVehicle);
        if (!mounted) return;
        _showSuccessSnackBar('Vehicle $vehicleNumber registered successfully.');
      }

      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _serverErrorMessage = e.userFriendlyMessage;
      });
      _showErrorSnackBar(e.userFriendlyMessage);
    } catch (e) {
      if (!mounted) return;
      final msg = 'Failed to save vehicle: $e';
      setState(() {
        _serverErrorMessage = msg;
      });
      _showErrorSnackBar(msg);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title =
        _isEditing ? AppStrings.editVehicle : AppStrings.registerVehicle;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBreadcrumb(title),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFormHeader(title),
                          const Divider(height: 36, thickness: 1),

                          if (_serverErrorMessage != null) ...[
                            _buildErrorBanner(),
                            const SizedBox(height: 12),
                          ],

                          // GROUP 1: Identity & Corporate Organization
                          _buildSectionTitle(
                            icon: Icons.badge_outlined,
                            title: '1. Asset & Corporate Identity',
                            subtitle:
                                'Assign a unique vehicle number and select the operating Stark Group subsidiary.',
                          ),
                          const SizedBox(height: 18),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isTwoColumn = constraints.maxWidth >= 600;
                              if (isTwoColumn) {
                                return Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                        child: _buildVehicleNumberField()),
                                    const SizedBox(width: 20),
                                    Expanded(
                                        child: _buildCompanyDropdown()),
                                  ],
                                );
                              }
                              return Column(
                                children: [
                                  _buildVehicleNumberField(),
                                  const SizedBox(height: 16),
                                  _buildCompanyDropdown(),
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 32),
                          const Divider(height: 1, thickness: 1),
                          const SizedBox(height: 24),

                          // GROUP 2: Vehicle Specifications & Status
                          _buildSectionTitle(
                            icon: Icons.directions_car_outlined,
                            title: '2. Specifications & Operational Status',
                            subtitle:
                                'Define vehicle manufacturer, model name, classification type, and operational status.',
                          ),
                          const SizedBox(height: 18),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isTwoColumn = constraints.maxWidth >= 600;
                              if (isTwoColumn) {
                                return Column(
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(child: _buildBrandField()),
                                        const SizedBox(width: 20),
                                        Expanded(child: _buildModelField()),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(child: _buildTypeDropdown()),
                                        const SizedBox(width: 20),
                                        Expanded(
                                            child: _buildStatusDropdown()),
                                      ],
                                    ),
                                  ],
                                );
                              }
                              return Column(
                                children: [
                                  _buildBrandField(),
                                  const SizedBox(height: 16),
                                  _buildModelField(),
                                  const SizedBox(height: 16),
                                  _buildTypeDropdown(),
                                  const SizedBox(height: 16),
                                  _buildStatusDropdown(),
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 36),
                          const Divider(height: 1, thickness: 1),
                          const SizedBox(height: 24),
                          _buildFormActions(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Unable to save vehicle',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _serverErrorMessage ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.textSecondary),
            onPressed: () => setState(() => _serverErrorMessage = null),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumb(String currentTitle) {
    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => Navigator.of(context).pop(),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 4, horizontal: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back_rounded,
                    size: 16, color: AppColors.primary),
                SizedBox(width: 6),
                Text(
                  'Fleet Vehicles',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 4),
        const Text(
          '/',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(width: 8),
        Text(
          currentTitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFormHeader(String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.16),
            ),
          ),
          child: const Icon(
            Icons.directions_car_filled_rounded,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _isEditing
                    ? 'Update specifications and tracking parameters for ${widget.initialVehicle?.vehicleNumber ?? "this asset"}.'
                    : 'Enter vehicle attributes to register a new asset into Stark Group fleet management.',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleNumberField() {
    return CustomTextField(
      label: '${AppStrings.fieldVehicleNumber} *',
      hint: 'e.g. SG-TRK-1042',
      helperText: 'Corporate asset code or registration identifier',
      controller: _vehicleNumberController,
      prefixIcon: const Icon(Icons.tag_rounded, size: 20),
      validator: (val) {
        if (val == null || val.trim().isEmpty) {
          return 'Vehicle number is required';
        }
        if (val.trim().length < 3) {
          return 'Vehicle number must be at least 3 characters';
        }
        return null;
      },
    );
  }

  Widget _buildCompanyDropdown() {
    final companies = VehicleRepository.instance.companies;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '${AppStrings.fieldCompany} *',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: companies.contains(_selectedCompany)
              ? _selectedCompany
              : companies.first,
          borderRadius: BorderRadius.circular(10),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.business_rounded, size: 20),
            helperText: 'Stark Group legal operating subsidiary',
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: companies.map((comp) {
            return DropdownMenuItem<String>(
              value: comp,
              child: Text(comp),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedCompany = val);
          },
        ),
      ],
    );
  }

  Widget _buildBrandField() {
    return CustomTextField(
      label: '${AppStrings.fieldBrand} *',
      hint: 'e.g. Ford, Toyota, Tesla, Volvo',
      helperText: 'Vehicle manufacturing company',
      controller: _brandController,
      prefixIcon: const Icon(Icons.stars_rounded, size: 20),
      validator: (val) {
        if (val == null || val.trim().isEmpty) {
          return 'Manufacturer / Brand is required';
        }
        return null;
      },
    );
  }

  Widget _buildModelField() {
    return CustomTextField(
      label: '${AppStrings.fieldModel} *',
      hint: 'e.g. F-150 Lightning, Model Y, Camry',
      helperText: 'Commercial or production model name',
      controller: _modelController,
      prefixIcon: const Icon(Icons.commute_rounded, size: 20),
      validator: (val) {
        if (val == null || val.trim().isEmpty) {
          return 'Model name is required';
        }
        return null;
      },
    );
  }

  Widget _buildTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '${AppStrings.fieldType} *',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<VehicleType>(
          initialValue: _selectedType,
          borderRadius: BorderRadius.circular(10),
          decoration: const InputDecoration(
            helperText: 'Body style classification',
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: VehicleType.values.map((type) {
            return DropdownMenuItem<VehicleType>(
              value: type,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(type.icon, size: 18, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Text(type.label),
                ],
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedType = val);
          },
        ),
      ],
    );
  }

  Widget _buildStatusDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '${AppStrings.fieldStatus} *',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<VehicleStatus>(
          initialValue: _selectedStatus,
          borderRadius: BorderRadius.circular(10),
          decoration: const InputDecoration(
            helperText: 'Operational deployment status',
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: VehicleStatus.values.map((status) {
            return DropdownMenuItem<VehicleStatus>(
              value: status,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: status.foregroundColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(status.label),
                ],
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedStatus = val);
          },
        ),
      ],
    );
  }

  Widget _buildFormActions() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 450;

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _handleSave,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_rounded, size: 18),
                label: Text(
                  _isSaving
                      ? 'Saving...'
                      : (_isEditing ? AppStrings.save : AppStrings.registerVehicle),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, size: 18),
                label: const Text(AppStrings.cancel),
              ),
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton.icon(
              onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded, size: 18),
              label: const Text(AppStrings.cancel),
            ),
            const SizedBox(width: 14),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _handleSave,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_rounded, size: 18),
              label: Text(
                _isSaving
                    ? 'Saving...'
                    : (_isEditing ? AppStrings.save : AppStrings.registerVehicle),
              ),
            ),
          ],
        );
      },
    );
  }
}
