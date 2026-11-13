import 'package:flutter_test/flutter_test.dart';
import 'package:shopsphere/domain/entities/payment_method.dart';
import 'package:shopsphere/services/payment_service.dart';

void main() {
  test('wallet number, PIN and OTP validators', () {
    expect(PaymentService.validateWalletNumber('01712345678'), isNull);
    expect(PaymentService.validateWalletNumber('0171234'), isNotNull);
    expect(PaymentService.validatePin('1234'), isNull);
    expect(PaymentService.validatePin('12'), isNotNull);
    expect(PaymentService.validateOtp('123456'), isNull);
    expect(PaymentService.validateOtp('12345'), isNotNull);
  });

  test('card number uses the Luhn check', () {
    expect(PaymentService.validateCardNumber('4242 4242 4242 4242'), isNull);
    expect(PaymentService.validateCardNumber('4242424242424241'), isNotNull);
  });

  test('card expiry', () {
    final now = DateTime(2026, 6, 15);
    expect(PaymentService.validateExpiry('12/30', now: now), isNull);
    expect(PaymentService.validateExpiry('01/20', now: now), isNotNull);
    expect(PaymentService.validateExpiry('13/30', now: now), isNotNull);
    expect(PaymentService.validateExpiry('1230', now: now), isNotNull);
  });

  test('wrong OTP is rejected and charge returns a transaction id', () async {
    final s = PaymentService();
    expect(() => s.verifyOtp('000000'), throwsA(isA<PaymentException>()));
    await s.verifyOtp(PaymentService.demoOtp);
    final id = await s.charge(method: PaymentMethod.bkash, amount: 500);
    expect(id.startsWith('BK'), isTrue);
  });
}
