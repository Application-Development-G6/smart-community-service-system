// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:smart_community_service_system/services/api_config.dart';

void main() {
  test('API base URL resolves to a valid local backend address', () {
    final url = ApiConfig.baseUrl;

    expect(url, startsWith('http://'));
    expect(url, contains('3000'));
  });
}
