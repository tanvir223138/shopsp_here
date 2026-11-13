import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants.dart';
import '../../core/di.dart';
import '../../core/money.dart';
import '../../domain/entities/payment_method.dart';
import '../../services/payment_service.dart';
import '../widgets/payment_ui.dart';

class PaymentResult {
  const PaymentResult({required this.method, required this.transactionId});
  final PaymentMethod method;
  final String transactionId;
}

/// Simulated payment gateway page. Nothing is charged: it only walks the
/// user through the same steps as a real gateway would.
///   wallets (bKash / Nagad / Rocket): number -> verification code -> PIN
///   card:                             card details -> 3-D Secure code
///   bank:                             choose bank -> login -> OTP
/// Pops with a [PaymentResult] on success, or null if the user cancels.
class PaymentGatewayScreen extends StatefulWidget {
  const PaymentGatewayScreen({super.key, required this.method, required this.amount});
  final PaymentMethod method;
  final double amount;

  @override
  State<PaymentGatewayScreen> createState() => _PaymentGatewayScreenState();
}

class _PaymentGatewayScreenState extends State<PaymentGatewayScreen> {
  final _service = sl<PaymentService>();
  final _formKey = GlobalKey<FormState>();

  final _wallet = TextEditingController();
  final _otp = TextEditingController();
  final _pin = TextEditingController();
  final _cardNo = TextEditingController();
  final _expiry = TextEditingController();
  final _cvv = TextEditingController();
  final _cardName = TextEditingController();
  final _bankUser = TextEditingController();
  final _bankPass = TextEditingController();

  String? _bank;
  int _step = 0;
  bool _busy = false;
  String? _error;
  String? _transactionId;

  late final List<String> _steps = widget.method.isWallet
      ? ['number', 'otp', 'pin']
      : widget.method == PaymentMethod.card
      ? ['card', 'otp']
      : ['bank', 'login', 'otp'];

  @override
  void dispose() {
    for (final c in [
      _wallet,
      _otp,
      _pin,
      _cardNo,
      _expiry,
      _cvv,
      _cardName,
      _bankUser,
      _bankPass,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _next() async {
    final key = _steps[_step];
    if (key == 'bank' && _bank == null) {
      setState(() => _error = 'Please select your bank.');
      return;
    }
    if (!(_formKey.currentState?.validate() ?? true)) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (key == 'otp') await _service.verifyOtp(_otp.text);
      if (key == 'pin') await _service.verifyPin();

      if (_step == _steps.length - 1) {
        final id = await _service.charge(method: widget.method, amount: widget.amount);
        if (!mounted) return;
        setState(() => _transactionId = id);
      } else {
        setState(() {
          _step++;
          _otp.clear();
        });
      }
    } on PaymentException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ------------------------------------------------------------- fields

  Widget _digits(
    TextEditingController c,
    String label, {
    required String? Function(String?) validator,
    required int maxLength,
    bool obscure = false,
    String? hint,
    IconData? icon,
  }) {
    return TextFormField(
      controller: c,
      obscureText: obscure,
      keyboardType: TextInputType.number,
      validator: validator,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(maxLength),
      ],
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: '',
        prefixIcon: icon == null ? null : Icon(icon),
      ),
    );
  }

  Widget _stepBody(String key) {
    final m = widget.method;
    switch (key) {
      case 'number':
        return Column(
          children: [
            _label('Your ${m.label} Account number'),
            _digits(
              _wallet,
              'e.g. 01XXXXXXXXX',
              validator: PaymentService.validateWalletNumber,
              maxLength: 11,
              icon: Icons.phone_android,
            ),
            const SizedBox(height: 8),
            Text(
              'By confirming, you agree to the ${m.label} terms and conditions.',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        );
      case 'otp':
        return Column(
          children: [
            _label(
              m == PaymentMethod.card
                  ? 'Enter the 3-D Secure code sent by your bank'
                  : m == PaymentMethod.bank
                  ? 'Enter the OTP sent to your registered mobile'
                  : 'Enter the verification code sent to ${_wallet.text}',
            ),
            _digits(
              _otp,
              '6 digit code',
              validator: PaymentService.validateOtp,
              maxLength: 6,
              icon: Icons.sms_outlined,
            ),
            const SizedBox(height: 8),
            _hint('Demo code: ${PaymentService.demoOtp}'),
          ],
        );
      case 'pin':
        return Column(
          children: [
            _label('Enter your ${m.label} PIN'),
            _digits(
              _pin,
              'PIN',
              validator: PaymentService.validatePin,
              maxLength: 5,
              obscure: true,
              icon: Icons.lock_outline,
            ),
            const SizedBox(height: 8),
            _hint('Demo: any 4-5 digit PIN works'),
          ],
        );
      case 'card':
        return Column(
          children: [
            _label('Enter your card details'),
            _digits(
              _cardNo,
              'Card number',
              validator: PaymentService.validateCardNumber,
              maxLength: 19,
              icon: Icons.credit_card,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _expiry,
                    keyboardType: TextInputType.number,
                    validator: PaymentService.validateExpiry,
                    inputFormatters: [_ExpiryFormatter()],
                    decoration: const InputDecoration(labelText: 'Expiry (MM/YY)', counterText: ''),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _digits(
                    _cvv,
                    'CVV',
                    validator: PaymentService.validateCvv,
                    maxLength: 4,
                    obscure: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cardName,
              textCapitalization: TextCapitalization.characters,
              validator: (v) => (v ?? '').trim().isEmpty ? 'Enter the name on card' : null,
              decoration: const InputDecoration(labelText: 'Name on card'),
            ),
            const SizedBox(height: 8),
            _hint('Demo card: 4242 4242 4242 4242, any future expiry, any CVV'),
          ],
        );
      case 'bank':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('Select your bank'),
            for (final b in ShopConstants.banks)
              InkWell(
                onTap: () => setState(() {
                  _bank = b;
                  _error = null;
                }),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _bank == b ? m.color : Colors.grey.withAlpha(100),
                      width: _bank == b ? 1.8 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.account_balance, color: m.color),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(b, style: const TextStyle(color: Colors.black87)),
                      ),
                      if (_bank == b) Icon(Icons.check_circle, color: m.color),
                    ],
                  ),
                ),
              ),
          ],
        );
      case 'login':
        return Column(
          children: [
            _label('Log in to $_bank Internet Banking'),
            TextFormField(
              controller: _bankUser,
              validator: (v) => (v ?? '').trim().isEmpty ? 'Enter your user ID' : null,
              decoration: const InputDecoration(
                labelText: 'User ID',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bankPass,
              obscureText: true,
              validator: (v) => (v ?? '').isEmpty ? 'Enter your password' : null,
              decoration: const InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 8),
            _hint('Demo: any user ID and password'),
          ],
        );
    }
    return const SizedBox.shrink();
  }

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        t,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
      ),
    ),
  );

  Widget _hint(String t) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.amber.withAlpha(40),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        const Icon(Icons.info_outline, size: 16, color: Colors.black54),
        const SizedBox(width: 8),
        Expanded(
          child: Text(t, style: const TextStyle(fontSize: 12.5, color: Colors.black87)),
        ),
      ],
    ),
  );

  // ------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final m = widget.method;
    final done = _transactionId != null;

    // The gateway page is always white, like a real hosted payment page.
    return Theme(
      data: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: m.color,
          brightness: Brightness.light,
        ).copyWith(primary: m.color),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: m.color, width: 1.8),
          ),
          labelStyle: const TextStyle(color: Colors.black54),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // brand header
            Container(
              width: double.infinity,
              color: m.color,
              padding: EdgeInsets.fromLTRB(8, MediaQuery.of(context).padding.top + 8, 8, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: _busy ? null : () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      const Icon(Icons.lock, size: 14, color: Colors.white70),
                      const SizedBox(width: 4),
                      const Text(
                        'Secure payment (demo)',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(width: 12),
                    ],
                  ),
                  PaymentBadge(m, size: 52),
                  const SizedBox(height: 8),
                  Text(
                    m.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: m.color.withAlpha(18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.storefront, color: Colors.black54),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'ShopSphere',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Text(
                              formatBdt(widget.amount),
                              style: TextStyle(
                                color: m.color,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (done) _success(m) else _form(m),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _form(PaymentMethod m) {
    final last = _step == _steps.length - 1;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Step ${_step + 1} of ${_steps.length}',
            style: const TextStyle(color: Colors.black45, fontSize: 12),
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: (_step + 1) / _steps.length,
            color: m.color,
            backgroundColor: m.color.withAlpha(30),
          ),
          const SizedBox(height: 20),
          _stepBody(_steps[_step]),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 22),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: m.color),
            onPressed: _busy ? null : _next,
            child: _busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(last ? 'CONFIRM PAYMENT' : 'CONTINUE'),
          ),
          const SizedBox(height: 8),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.black54),
            onPressed: _busy ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _success(PaymentMethod m) {
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 600),
          curve: Curves.elasticOut,
          builder: (_, v, child) => Transform.scale(scale: v, child: child),
          child: const Icon(Icons.check_circle_rounded, size: 84, color: Color(0xFF2E9E5B)),
        ),
        const SizedBox(height: 12),
        const Text(
          'Payment successful',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87),
        ),
        const SizedBox(height: 6),
        Text(
          'Transaction ID: $_transactionId',
          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        const SizedBox(height: 4),
        Text(
          '${formatBdt(widget.amount)} paid via ${m.label}',
          style: const TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: m.color),
            onPressed: () =>
                Navigator.pop(context, PaymentResult(method: m, transactionId: _transactionId!)),
            child: const Text('RETURN TO SHOP'),
          ),
        ),
      ],
    );
  }
}

/// Turns "1228" into "12/28" while typing.
class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 4 ? digits.substring(0, 4) : digits;
    final text = limited.length > 2
        ? '${limited.substring(0, 2)}/${limited.substring(2)}'
        : limited;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
