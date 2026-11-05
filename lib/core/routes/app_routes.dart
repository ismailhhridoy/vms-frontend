import 'package:flutter/material.dart';
import '../../models/vehicle.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/vehicles/vehicle_form_screen.dart';
import '../../screens/vehicles/vehicle_list_screen.dart';
import '../../widgets/app_shell.dart';

class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String vehicles = '/vehicles';
  static const String vehicleNew = '/vehicles/new';
  static const String vehicleEdit = '/vehicles/edit';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute<void>(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );

      case vehicles:
        return MaterialPageRoute<void>(
          builder: (_) => const AppShell(
            currentRoute: vehicles,
            child: VehicleListScreen(),
          ),
          settings: settings,
        );

      case vehicleNew:
        return MaterialPageRoute<void>(
          builder: (_) => const AppShell(
            currentRoute: vehicles,
            child: VehicleFormScreen(),
          ),
          settings: settings,
        );

      case vehicleEdit:
        final vehicle = settings.arguments as Vehicle?;
        return MaterialPageRoute<void>(
          builder: (_) => AppShell(
            currentRoute: vehicles,
            child: VehicleFormScreen(initialVehicle: vehicle),
          ),
          settings: settings,
        );

      default:
        return MaterialPageRoute<void>(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );
    }
  }
}

