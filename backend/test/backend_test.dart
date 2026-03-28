import 'dart:convert';

import 'package:backend/backend.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  test('health endpoint returns ok', () async {
    final handler = buildHandler();
    final response = await handler(Request('GET', Uri.parse('http://localhost/health')));
    final body = jsonDecode(await response.readAsString()) as Map<String, dynamic>;

    expect(response.statusCode, 200);
    expect(body['status'], 'ok');
  });
}
