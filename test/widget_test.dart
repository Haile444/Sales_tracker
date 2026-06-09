import 'package:flutter_test/flutter_test.dart';
import 'package:sales_tracker/main.dart';

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    await tester.pumpWidget(const SalesTrackerApp());
  });
}
