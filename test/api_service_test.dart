import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:spoth_umkm/core/services/api_service.dart';

class _NeverCompletingClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    final completer = Completer<http.StreamedResponse>();
    return completer.future;
  }
}

class _OkClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    const body = '{"success":true,"message":"ok","data":{"value":42}}';
    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      200,
      headers: {'content-type': 'application/json'},
    );
  }
}

class _UnauthorizedClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    const body = '{"success":false,"message":"Token tidak valid"}';
    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      401,
      headers: {'content-type': 'application/json'},
    );
  }
}

void main() {
  test('ApiService throws ApiException (408) when request times out', () async {
    final service = ApiService(
      client: _NeverCompletingClient(),
      timeout: const Duration(milliseconds: 10),
    );

    await expectLater(
      service.get('/health'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 408)
            .having(
              (e) => e.message,
              'message',
              contains('melebihi batas waktu'),
            ),
      ),
    );
  });

  test('ApiService decodes successful response', () async {
    final service = ApiService(client: _OkClient());
    final body = await service.get('/health');
    expect(body['success'], isTrue);
    expect(body['data']['value'], 42);
  });

  test('ApiService throws ApiException on HTTP 401', () async {
    final service = ApiService(client: _UnauthorizedClient());
    expect(
      () => service.get('/health'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 401)
            .having((e) => e.message, 'message', 'Token tidak valid'),
      ),
    );
  });
}
