import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smart_community_service_system/main.dart';
import 'package:smart_community_service_system/screens/admin_dashboard_screen.dart';
import 'package:smart_community_service_system/screens/complaint_form_screen.dart';

void main() {
  testWidgets('shows the login screen when no session is loaded', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(
      find.text('New to the community? Create an account'),
      findsOneWidget,
    );
  });

  testWidgets('renders compact navigation on a narrow complaint form', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(899, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: ComplaintFormScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Report a community problem'), findsOneWidget);
    expect(find.text('What happens next?'), findsOneWidget);
    expect(find.byTooltip('Navigation'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the navigation visible on a wide complaint form', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1366, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: ComplaintFormScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Report a Problem'), findsOneWidget);
    expect(find.text('Track Reports'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('blocks a resident from the admin dashboard', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AdminDashboardScreen(user: {'role': 'user'}),
      ),
    );

    expect(find.textContaining('Access denied'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
