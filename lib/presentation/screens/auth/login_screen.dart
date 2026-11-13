import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../core/validators.dart';
import '../../../providers/auth_provider.dart';
import '../main_shell.dart';
import 'auth_widgets.dart';
import 'register_screen.dart';
import 'verify_email_screen.dart';

void goToShell(BuildContext context) {
  shellTab.value = 0;
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => const MainShell()),
    (route) => false,
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _id = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _id.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<String?> Function(AuthProvider) action) async {
    setState(() => _busy = true);
    final error = await action(context.read<AuthProvider>());
    if (!mounted) return;
    setState(() => _busy = false);
    if (error == AuthProvider.needsVerification) {
      final mail = context.read<AuthProvider>().unverifiedEmail ?? '';
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => VerifyEmailScreen(email: mail)),
      );
      return;
    }
    if (error != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error)));
    } else {
      goToShell(context);
    }
  }

  void _login() {
    if (!_formKey.currentState!.validate()) return;
    _run((auth) => auth.login(_id.text, _password.text));
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Welcome back',
      subtitle: 'Please login to your account',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _id,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (v) => Validators.required(v, 'Email or phone'),
              decoration: const InputDecoration(
                labelText: 'Email or phone number',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 14),
            PasswordField(
              controller: _password,
              label: 'Password',
              validator: (v) => Validators.required(v, 'Password'),
              onSubmitted: _login,
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: _busy ? null : _login,
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('LOGIN'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _run((auth) => auth.loginDemo()),
              icon: const Icon(Icons.flash_on_rounded),
              label: const Text('Use demo account'),
            ),
            const SizedBox(height: 8),
            Text(
              'Demo: ${ShopConstants.demoEmail} / ${ShopConstants.demoPassword}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('New to ShopSphere?'),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
                        ),
                  child: const Text('Sign up'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
