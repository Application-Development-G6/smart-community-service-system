import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_community_service_system/screens/home_screen.dart';

void main() {
  for (final size in [const Size(390, 844), const Size(1280, 900)]) {
    testWidgets('home screen fits ${size.width}px layout', (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(home: HomeScreen(fullName: 'Cherryl Caspe')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Smart Community'), findsOneWidget);
      expect(find.text('Community services, made simpler'), findsOneWidget);
      expect(find.text('Submit a Report'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
