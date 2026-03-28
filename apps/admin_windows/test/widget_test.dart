import 'package:admin_windows/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('admin dashboard renders shell title', (tester) async {
    await tester.pumpWidget(const AdminWindowsApp());

    expect(find.text('PDO Lite Next'), findsOneWidget);
    expect(find.textContaining('Windows panel'), findsOneWidget);
  });
}
