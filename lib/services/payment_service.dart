import 'dart:math';

import '../domain/entities/payment_method.dart';

class PaymentException implements Exception {
  const PaymentException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Simulated payment gateway (bKash / Nagad / Rocket / card / bank).
/// No real money moves: it only validates input and fakes the network delay.
class PaymentService {
  static const String demoOtp = '123456';
  final Random _random = Random();

  // ----- validators (pure, easy to unit test) -----

  static String? validateWalletNumber(String? v) {
    final s = (v ?? '').trim();
    return RegExp(r'^01[3-9]\d{8}$').hasMatch(s) ? null : 'Enter a valid number (01XXXXXXXXX)';
  }

  static String? validatePin(String? v) {
    final s = (v ?? '').trim();
    return RegExp(r'^\d{4,5}$').hasMatch(s) ? null : 'Enter your 4-5 digit PIN';
  }

  static String? validateOtp(String? v) {
    final s = (v ?? '').trim();
    return RegExp(r'^\d{6}$').hasMatch(s) ? null : 'Enter the 6 digit code';
  }

  /// Luhn check, e.g. 4242424242424242 is valid.
  static String? validateCardNumber(String? v) {
    final s = (v ?? '').replaceAll(' ', '');
    if (!RegExp(r'^\d{13,19}$').hasMatch(s)) return 'Enter a valid card number';
    var sum = 0;
    var alt = false;
    for (var i = s.length - 1; i >= 0; i--) {
      var d = int.parse(s[i]);
      if (alt) {
        d *= 2;
        if (d > 9) d -= 9;
      }
      sum += d;
      alt = !alt;
    }
    return sum % 10 == 0 ? null : 'Card number is not valid';
  }

  static String? validateExpiry(String? v, {DateTime? now}) {
    final m = RegExp(r'^(\d{2})/(\d{2})$').firstMatch((v ?? '').trim());
    if (m == null) return 'Use MM/YY';
    final month = int.parse(m.group(1)!);
    final year = 2000 + int.parse(m.group(2)!);
    if (month < 1 || month > 12) return 'Invalid month';
    final current = now ?? DateTime.now();
    final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);
    return endOfMonth.isBefore(current) ? 'Card has expired' : null;
  }

  static String? validateCvv(String? v) =>
      RegExp(r'^\d{3,4}$').hasMatch((v ?? '').trim()) ? null : 'Invalid CVV';

  // ----- gateway calls -----

  Future<void> verifyOtp(String otp) async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (otp.trim() != demoOtp) {
      throw const PaymentException('Wrong verification code. Please try again.');
    }
  }

  Future<void> verifyPin() => Future.delayed(const Duration(milliseconds: 700));

  /// Returns a fake transaction id.
  Future<String> charge({required PaymentMethod method, required double amount}) async {
    await Future.delayed(const Duration(milliseconds: 1800));
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final id = List.generate(8, (_) => chars[_random.nextInt(chars.length)]).join();
    final prefix = switch (method) {
      PaymentMethod.bkash => 'BK',
      PaymentMethod.nagad => 'NG',
      PaymentMethod.rocket => 'RK',
      PaymentMethod.card => 'CD',
      PaymentMethod.bank => 'BN',
      PaymentMethod.cod => 'CO',
    };
    return '$prefix$id';
  }
}
