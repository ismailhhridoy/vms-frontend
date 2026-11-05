import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vms_frontend/core/constants/app_strings.dart';
import 'package:vms_frontend/core/network/api_client.dart';
import 'package:vms_frontend/data/vehicle_repository.dart';
import 'package:vms_frontend/main.dart';

void main() {
  setUp(() {
    final mockHttpClient = MockClient((request) async {
      if (request.url.path.endsWith('/vehicles')) {
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Success',
            'data': [
              {
                'id': 1,
                'vehicleNumber': 'SG-TRK-1042',
                'company': 'Stark Logistics',
                'type': 'TRUCK',
                'brand': 'Ford',
                'model': 'F-150 Lightning',
                'status': 'ACTIVE',
              }
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path.endsWith('/vehicles/stats')) {
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Success',
            'data': {
              'totalCount': 1,
              'activeCount': 1,
              'maintenanceCount': 0,
              'inactiveCount': 0,
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path.endsWith('/vehicles/companies')) {
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Success',
            'data': ['Stark Logistics'],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('Not Found', 404);
    });

    VehicleRepository.instance = VehicleRepository(
      apiClient: ApiClient(client: mockHttpClient),
    );
  });

  testWidgets('VMS login screen renders properly on startup', (WidgetTester tester) async {
    await tester.pumpWidget(const VmsApp());
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.loginTitle), findsOneWidget);
    expect(find.text(AppStrings.emailLabel), findsOneWidget);
    expect(find.text(AppStrings.passwordLabel), findsOneWidget);
    expect(find.text(AppStrings.signInButton), findsOneWidget);
  });

  testWidgets('VMS logs in and displays Vehicle List with domain columns', (WidgetTester tester) async {
    await tester.pumpWidget(const VmsApp());
    await tester.pumpAndSettle();

    // Tap sign in button
    await tester.tap(find.text(AppStrings.signInButton));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    // Verify Vehicle List elements
    expect(find.text(AppStrings.vehicleListTitle), findsOneWidget);
    expect(find.text(AppStrings.fieldVehicleNumber), findsOneWidget);
    expect(find.text(AppStrings.fieldCompany), findsOneWidget);
    expect(find.text(AppStrings.fieldBrand), findsOneWidget);
    expect(find.text(AppStrings.fieldModel), findsOneWidget);
    expect(find.text(AppStrings.fieldStatus), findsOneWidget);
  });
}
