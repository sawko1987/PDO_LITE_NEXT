import 'dart:convert';

import 'package:shelf/shelf.dart';

Response jsonResponse(
  Object? body, {
  int statusCode = 200,
}) {
  return Response(
    statusCode,
    body: jsonEncode(body),
    headers: const {'content-type': 'application/json'},
  );
}
