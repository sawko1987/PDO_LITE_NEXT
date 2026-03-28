import 'package:flutter_test/flutter_test.dart';
import 'package:master_mobile/main.dart';

void main() {
  testWidgets('master dashboard renders offline queue card', (tester) async {
    await tester.pumpWidget(const MasterMobileApp());

    expect(find.text('Offline Queue'), findsOneWidget);
  });
}
