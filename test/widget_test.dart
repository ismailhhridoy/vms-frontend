import 'package:flutter_test/flutter_test.dart';
import 'package:vms_frontend/core/constants/app_strings.dart';
import 'package:vms_frontend/main.dart';

void main() {
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
