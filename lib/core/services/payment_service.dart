import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/payment_model.dart';
import 'api_service.dart';

final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService(ref.watch(apiServiceProvider));
});

class EPassResult {
  const EPassResult({required this.epass, required this.teksEpass});

  final EPassModel epass;

  final String teksEpass;
}

class PaymentService {
  PaymentService(this._apiService);

  final ApiService _apiService;

  Future<PaymentModel> payBooking({
    required String token,
    required String bookingId,
    required String metode,
  }) async {
    final body = await _apiService.post('/payments/$bookingId', {
      'metode': metode,
    }, token: token);

    final data = body['data'] as Map<String, dynamic>?;
    final payment = data?['payment'] as Map<String, dynamic>?;

    if (payment == null) {
      throw const FormatException('Respons pembayaran tidak valid');
    }

    return PaymentModel.fromJson(payment);
  }

  Future<PaymentModel?> getPayment({
    required String token,
    required String bookingId,
  }) async {
    final body = await _apiService.get('/payments/$bookingId', token: token);

    final data = body['data'] as Map<String, dynamic>?;
    final payment = data?['payment'] as Map<String, dynamic>?;

    if (payment == null) {
      return null;
    }

    return PaymentModel.fromJson(payment);
  }

  Future<EPassResult> getEPass({
    required String token,
    required String bookingId,
  }) async {
    final body = await _apiService.get('/epass/$bookingId', token: token);

    final data = body['data'] as Map<String, dynamic>?;
    final epass = data?['epass'] as Map<String, dynamic>?;

    if (epass == null) {
      throw const FormatException('Respons E-Pass tidak valid');
    }

    return EPassResult(
      epass: EPassModel.fromJson(epass),
      teksEpass: data?['teks_epass'] as String? ?? '',
    );
  }
}
