import 'dart:io';

import 'package:domain/domain.dart';

void main() {
  const machine = Machine(id: 'machine-1', code: 'M-100', name: 'Test machine');
  stdout.writeln('Loaded ${machine.name} (${machine.code})');
}
