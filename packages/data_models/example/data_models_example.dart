import 'dart:io';

import 'package:data_models/data_models.dart';

void main() {
  final health = ServiceHealthDto(
    status: 'ok',
    service: 'example',
    timestamp: DateTime.utc(2026, 3, 28),
  );
  stdout.writeln(health.toJson());
}
