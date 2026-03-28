import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  test('theme can be created', () {
    final theme = buildPdoTheme();
    expect(theme.useMaterial3, isTrue);
  });
}
