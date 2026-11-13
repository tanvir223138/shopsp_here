import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../providers/auth_provider.dart';
import 'auth_widgets.dart';
import 'login_screen.dart';

/// Asks for the 6-digit code that was emailed to the user.
/// The code is sent automatically when the screen opens (first sign-up, or a
/// login with an account whose email was never verified).
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key, required this.email});
  final String email;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  static const _cooldownSeconds = 30;

  final _code = TextEditingController();
  Timer? _timer;
  int _cooldown = 0;
  bool _sending = false;
  bool _verifying = false;
  String? _devCode;
  String? _info;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _send());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = _cooldownSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _cooldown--);
      if (_cooldown <= 0) t.cancel();
    });
  }

  Future<void> _send() async {
    setState(() {
      _sending = true;
      _error = null;
      _info = null;
    });
    final result = await context.read<AuthProvider>().sendVerificationCode(widget.email);
    if (!mounted) return;
    setState(() {
      _sending = false;
      _devCode = result.devCode;
      _error = result.error;
      if (result.emailed) {
        _info = 'We sent a 6-digit code to ${widget.email}. Check your inbox and spam folder.';
      }
    });
    if (result.error == null) _startCooldown();
  }

  Future<void> _verify() async {
    final code = _code.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Enter the 6-digit code.');
      return;
    }
    setState(() {
      _verifying = true;
      _error = null;
    });
    final error = await context.read<AuthProvider>().verifyEmail(widget.email, code);
    if (!mounted) return;
    setState(() => _verifying = false);
    if (error != null) {
      setState(() => _error = error);
    } else {
      goToShell(context);
    }
  }

  Widget _notice(IconData icon, Color color, String text) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withAlpha(24),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withAlpha(90)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13, height: 1.35))),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;
    return AuthScaffold(
      title: 'Verify your email',
      subtitle: 'Enter the code we sent you',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_sending)
            const Padding(
              padding: EdgeInsets.only(bottom: 14),
              child: LinearProgressIndicator(minHeight: 3),
            ),
          if (_info != null) _notice(Icons.mark_email_read_outlined, AppColors.success, _info!),
          if (_devCode != null)
            _notice(
              Icons.info_outline_rounded,
              AppColors.primary,
              'Demo mode: the email service is not configured, so no email was sent. '
              'Your code is $_devCode',
            ),
          if (_error != null) _notice(Icons.error_outline_rounded, errorColor, _error!),
          TextField(
            controller: _code,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 10),
            onSubmitted: (_) => _verify(),
            decoration: const InputDecoration(counterText: '', hintText: '------'),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _verifying ? null : _verify,
            child: _verifying
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('VERIFY & CONTINUE'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: (_cooldown > 0 || _sending) ? null : _send,
            child: Text(_cooldown > 0 ? 'Resend code in ${_cooldown}s' : 'Resend code'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Use a different email'),
          ),
        ],
      ),
    );
  }
}
