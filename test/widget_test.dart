// Basic smoke test for Spendly.
import 'package:flutter_test/flutter_test.dart';
import 'package:spendly/main.dart';

void main() {
  testWidgets('SpendlyApp builds', (WidgetTester tester) async {
    await tester.pumpWidget(const SpendlyApp());
    expect(find.byType(SpendlyApp), findsOneWidget);
  });
}
