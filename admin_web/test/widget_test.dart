import 'package:flutter_test/flutter_test.dart';
import 'package:admin_web/main.dart';

void main() {
  testWidgets('AdminWebApp initial smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AdminWebApp());
    expect(find.text('GoGovernment Administration Portal'), findsWidgets);
  });
}
