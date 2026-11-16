import 'package:flutter_test/flutter_test.dart';

import 'package:smart_community_service_system/main.dart';

void main() {
  testWidgets('shows the login screen when no session is loaded', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text("Don't have an account? Register"), findsOneWidget);
  });
}
