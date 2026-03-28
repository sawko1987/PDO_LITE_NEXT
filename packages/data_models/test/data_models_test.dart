import 'package:data_models/data_models.dart';
import 'package:test/test.dart';

void main() {
  test('health dto serializes to json', () {
    final dto = ServiceHealthDto(
      status: 'ok',
      service: 'backend',
      timestamp: DateTime.utc(2026, 3, 28, 10),
    );

    expect(dto.toJson()['status'], 'ok');
    expect(dto.toJson()['service'], 'backend');
  });
}
