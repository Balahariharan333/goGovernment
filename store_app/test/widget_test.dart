import 'package:flutter_test/flutter_test.dart';
import 'package:store_app/main.dart';

void main() {
  testWidgets('StoreApp initial smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const StoreApp());
    expect(find.text('GoGovernment'), findsWidgets);
  });
}
