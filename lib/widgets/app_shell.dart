import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../core/routes/app_routes.dart';

class AppShell extends StatelessWidget {
  final String currentRoute;
  final Widget child;

  const AppShell({
    super.key,
    required this.currentRoute,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 960;

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            _buildSidebar(context),
            const VerticalDivider(width: 1, thickness: 1, color: AppColors.border),
            Expanded(
              child: Column(
                children: [
                  _buildTopBar(context, isDesktop: true),
                  const Divider(height: 1, thickness: 1, color: AppColors.border),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: _buildTopBar(context, isDesktop: false),
      ),
      drawer: Drawer(
        child: _buildSidebar(context, isDrawer: true),
      ),
      body: child,
    );
  }

  Widget _buildTopBar(BuildContext context, {required bool isDesktop}) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: AppColors.surface,
      child: Row(
        children: [
          if (!isDesktop) ...[
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu_rounded, color: AppColors.textPrimary),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
            const SizedBox(width: 8),
          ],
          const Icon(Icons.directions_car_filled_rounded, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              AppStrings.appTitle,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          if (currentRoute == AppRoutes.vehicles)
            isDesktop
                ? ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pushNamed(AppRoutes.vehicleNew),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text(AppStrings.registerVehicle),
                  )
                : IconButton.filled(
                    tooltip: AppStrings.registerVehicle,
                    onPressed: () => Navigator.of(context).pushNamed(AppRoutes.vehicleNew),
                    icon: const Icon(Icons.add_rounded, size: 18),
                  ),
          const SizedBox(width: 12),
          _buildUserDropdown(context),
        ],
      ),
    );
  }

  Widget _buildUserDropdown(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Account Menu',
      offset: const Offset(0, 48),
      onSelected: (value) {
        if (value == 'logout') {
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.login,
            (route) => false,
          );
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fleet Administrator',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              Text(
                'admin@starkgroup.com',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout_rounded, size: 18, color: AppColors.error),
              SizedBox(width: 10),
              Text(AppStrings.logout, style: TextStyle(color: AppColors.error)),
            ],
          ),
        ),
      ],
      child: const Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary,
            child: Text(
              'A',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          SizedBox(width: 8),
          Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary, size: 18),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, {bool isDrawer = false}) {
    return Container(
      width: isDrawer ? null : 240,
      color: AppColors.surface,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.shield_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stark Group',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      'Fleet VMS Portal',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.border),
          const SizedBox(height: 12),
          _buildNavItem(
            context,
            icon: Icons.directions_car_rounded,
            label: AppStrings.navVehicles,
            route: AppRoutes.vehicles,
            isSelected: currentRoute == AppRoutes.vehicles,
            isDrawer: isDrawer,
          ),
          _buildDisabledNavItem(
            icon: Icons.business_rounded,
            label: AppStrings.navCompanies,
            badge: 'Soon',
          ),
          _buildDisabledNavItem(
            icon: Icons.badge_rounded,
            label: AppStrings.navDrivers,
            badge: 'Soon',
          ),
          _buildDisabledNavItem(
            icon: Icons.build_rounded,
            label: AppStrings.navMaintenance,
            badge: 'Soon',
          ),
          _buildDisabledNavItem(
            icon: Icons.settings_rounded,
            label: AppStrings.navSettings,
            badge: 'Soon',
          ),
          const Spacer(),
          const Divider(height: 1, thickness: 1, color: AppColors.border),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
            title: const Text(
              AppStrings.logout,
              style: TextStyle(color: AppColors.error, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            onTap: () {
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.login,
                (route) => false,
              );
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
    required bool isSelected,
    required bool isDrawer,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        selected: isSelected,
        selectedTileColor: AppColors.primary.withValues(alpha: 0.08),
        leading: Icon(
          icon,
          size: 20,
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
        onTap: () {
          if (isDrawer) {
            Navigator.of(context).pop();
          }
          if (!isSelected) {
            Navigator.of(context).pushNamed(route);
          }
        },
      ),
    );
  }

  Widget _buildDisabledNavItem({
    required IconData icon,
    required String label,
    required String badge,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        leading: Icon(icon, size: 20, color: AppColors.textSecondary.withValues(alpha: 0.5)),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary.withValues(alpha: 0.6),
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            badge,
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}
