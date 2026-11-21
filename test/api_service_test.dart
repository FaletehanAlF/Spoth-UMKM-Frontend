import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:spoth_umkm/core/services/api_service.dart';

void main() {
  test('ApiService decodes successful response', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response(
              requestOptions: options,
              data: {
                'success': true,
                'message': 'ok',
                'data': {'value': 42},
              },
              statusCode: 200,
            ),
          );
        },
      ),
    );
    final service = ApiService(dio: dio);
    final body = await service.get('/health');
    expect(body['success'], isTrue);
    expect(body['data']['value'], 42);
  });

  test('ApiService throws ApiException on HTTP 401', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.badResponse,
              message: 'Unauthorized',
              response: Response(
                requestOptions: options,
                data: {
                  'success': false,
                  'message': 'Token tidak valid',
                },
                statusCode: 401,
              ),
            ),
          );
        },
      ),
    );
    final service = ApiService(dio: dio);

    await expectLater(
      service.get('/health'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 401)
            .having((e) => e.message, 'message', 'Token tidak valid'),
      ),
    );
  });

  test('ApiService sends POST body as JSON', () async {
    final dio = Dio();
    RequestOptions? seenOptions;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          seenOptions = options;
          handler.resolve(
            Response(
              requestOptions: options,
              data: {'success': true, 'message': 'ok'},
              statusCode: 201,
            ),
          );
        },
      ),
    );
    final service = ApiService(dio: dio);

    final body = await service.post('/places', {'nama': 'Tempat'});

    expect(seenOptions!.method, 'POST');
    expect(seenOptions!.headers['Content-Type'], contains('application/json'));
    expect(jsonDecode(seenOptions!.data as String), {'nama': 'Tempat'});
    expect(body['success'], isTrue);
  });

  test('ApiService maps connection failure to friendly ApiException', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.unknown,
              message: 'connection failed',
            ),
          );
        },
      ),
    );
    final service = ApiService(dio: dio);

    await expectLater(
      service.get('/health'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 0)
            .having(
              (e) => e.message,
              'message',
              contains('Tidak dapat terhubung ke server'),
            ),
      ),
    );
  });
}
