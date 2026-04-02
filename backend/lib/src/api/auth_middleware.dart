import 'package:domain/domain.dart';
import 'package:shelf/shelf.dart';

import '../store/demo_contract_store.dart';
import 'json_response.dart';

const _authSessionContextKey = 'auth_session';

Middleware authMiddleware(DemoContractStore store) {
  return (Handler innerHandler) {
    return (Request request) async {
      final path = request.url.path;
      if (!path.startsWith('v1/') || path == 'v1/auth/login') {
        return innerHandler(request);
      }

      final authorization = request.headers['authorization'];
      if (authorization == null || !authorization.startsWith('Bearer ')) {
        return _unauthorizedResponse();
      }

      final token = authorization.substring('Bearer '.length).trim();
      try {
        final session = store.requireSession(token);
        final enrichedRequest = request.change(
          context: {...request.context, _authSessionContextKey: session},
        );
        return innerHandler(enrichedRequest);
      } on DemoStoreUnauthorized {
        return _unauthorizedResponse();
      }
    };
  };
}

AuthSession? authSessionFromRequest(Request request) {
  return request.context[_authSessionContextKey] as AuthSession?;
}

Response unauthorizedResponse() => _unauthorizedResponse();

Response forbiddenResponse({
  String code = 'forbidden',
  String message = 'You do not have access to this resource.',
  Map<String, Object?> details = const {},
}) {
  return jsonResponse({
    'error': {'code': code, 'message': message, 'details': details},
  }, statusCode: 403);
}

Response _unauthorizedResponse() {
  return jsonResponse({
    'error': {
      'code': 'unauthorized',
      'message': 'Authorization token is missing or invalid.',
      'details': const <String, Object?>{},
    },
  }, statusCode: 401);
}
