import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../core/constants.dart';
import '../core/email_config.dart';
import '../data/datasource/shop_local_datasource.dart';
import '../domain/entities/app_user.dart';
import '../services/email_service.dart';

/// Result of sending a verification code.
class CodeResult {
  const CodeResult({this.error, this.devCode, this.emailed = false});

  /// Why the email could not be sent (null on success).
  final String? error;

  /// Only set in demo mode (email service not configured): the code to show on screen.
  final String? devCode;
  final bool emailed;
}

/// Local accounts (stored in Hive). Passwords are stored as SHA-256 hashes.
/// New accounts must verify their email with a 6-digit code before they can log in.
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._ds, [EmailService? email]) : _email = email ?? EmailService() {
    final id = _ds.readSession();
    if (id != null) {
      for (final u in _ds.readUsers()) {
        if (u.id == id) _user = u;
      }
    }
  }

  final ShopLocalDataSource _ds;
  final EmailService _email;
  AppUser? _user;

  /// Returned by [login] when the account exists but its email is not verified yet.
  static const String needsVerification = 'needs_verification';
  static const Duration _codeLifetime = Duration(minutes: 10);
  static const int _maxAttempts = 5;

  /// Set when [login] returns [needsVerification].
  String? unverifiedEmail;

  AppUser? get user => _user;
  bool get isLoggedIn => _user != null;

  static String hash(String password) =>
      sha256.convert(utf8.encode('shopsphere::$password')).toString();

  /// Creates the account (not verified yet). The caller then opens the verify
  /// screen, which sends the code. Returns an error message, or null on success.
  Future<String?> register({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final mail = email.trim().toLowerCase();
    final ph = phone.trim();
    // An unverified account with the same email is replaced, so a typo can be retried.
    final users = _ds.readUsers().where((u) => !(u.email == mail && !u.emailVerified)).toList();
    if (users.any((u) => u.email == mail)) return 'An account with this email already exists.';
    if (users.any((u) => u.phone == ph)) return 'An account with this phone number already exists.';

    final user = AppUser(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim(),
      email: mail,
      phone: ph,
      passwordHash: hash(password),
      emailVerified: false,
    );
    await _ds.saveUsers([...users, user]);
    return null;
  }

  AppUser? _byEmail(String email) {
    final mail = email.trim().toLowerCase();
    for (final u in _ds.readUsers()) {
      if (u.email == mail) return u;
    }
    return null;
  }

  String _newCode() => (100000 + Random.secure().nextInt(900000)).toString();

  /// Creates a fresh 6-digit code and emails it. In demo mode (no email service
  /// configured) the code is returned in [CodeResult.devCode] instead.
  Future<CodeResult> sendVerificationCode(String email) async {
    final user = _byEmail(email);
    if (user == null) return const CodeResult(error: 'Account not found. Please sign up again.');

    final code = _newCode();
    await _ds.saveVerification(user.id, {
      'hash': hash(code),
      'expires': DateTime.now().add(_codeLifetime).millisecondsSinceEpoch,
      'attempts': 0,
    });

    if (!_email.isConfigured) return CodeResult(devCode: code);
    try {
      await _email.sendVerificationCode(toEmail: user.email, toName: user.name, code: code);
      return const CodeResult(emailed: true);
    } on EmailException catch (e) {
      return CodeResult(error: e.message);
    }
  }

  /// Checks the code. On success the account is verified and logged in.
  /// Returns an error message, or null on success.
  Future<String?> verifyEmail(String email, String code) async {
    final user = _byEmail(email);
    if (user == null) return 'Account not found. Please sign up again.';
    final data = _ds.readVerification(user.id);
    if (data == null) return 'No code found. Tap "Resend code".';

    final expires = (data['expires'] as num?)?.toInt() ?? 0;
    if (DateTime.now().millisecondsSinceEpoch > expires) {
      return 'This code has expired. Tap "Resend code".';
    }
    final attempts = (data['attempts'] as num?)?.toInt() ?? 0;
    if (attempts >= _maxAttempts) return 'Too many wrong attempts. Tap "Resend code".';

    if (data['hash'] != hash(code.trim())) {
      await _ds.saveVerification(user.id, {...data, 'attempts': attempts + 1});
      return 'Wrong code. Please try again.';
    }

    final verified = user.copyWith(emailVerified: true);
    final users = _ds.readUsers().map((u) => u.id == verified.id ? verified : u).toList();
    await _ds.saveUsers(users);
    await _ds.saveVerification(user.id, null);
    await _ds.saveSession(verified.id);
    _user = verified;
    notifyListeners();
    return null;
  }

  /// [identifier] is an email or a phone number.
  Future<String?> login(String identifier, String password) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final id = identifier.trim().toLowerCase();
    for (final u in _ds.readUsers()) {
      if ((u.email == id || u.phone == id) && u.passwordHash == hash(password)) {
        if (!u.emailVerified) {
          unverifiedEmail = u.email;
          return needsVerification;
        }
        await _ds.saveSession(u.id);
        _user = u;
        notifyListeners();
        _sendLoginAlert(u);
        return null;
      }
    }
    return 'Wrong email/phone or password.';
  }

  /// Fire and forget: a failed alert must never block the login.
  void _sendLoginAlert(AppUser u) {
    if (!EmailConfig.sendLoginAlert || !_email.isConfigured) return;
    if (u.email == ShopConstants.demoEmail) return;
    unawaited(_email.sendLoginAlert(toEmail: u.email, toName: u.name).catchError((_) {}));
  }

  Future<String?> loginDemo() async {
    final users = _ds.readUsers();
    if (!users.any((u) => u.email == ShopConstants.demoEmail)) {
      await _ds.saveUsers([
        ...users,
        AppUser(
          id: 'demo-user',
          name: 'Demo User',
          email: ShopConstants.demoEmail,
          phone: '01700000000',
          passwordHash: hash(ShopConstants.demoPassword),
          address: 'House 12, Road 5, Dhanmondi',
          district: 'Dhaka',
        ),
      ]);
    }
    return login(ShopConstants.demoEmail, ShopConstants.demoPassword);
  }

  Future<void> logout() async {
    await _ds.saveSession(null);
    _user = null;
    notifyListeners();
  }

  Future<void> updateProfile({
    required String name,
    required String phone,
    required String address,
    required String district,
  }) async {
    final current = _user;
    if (current == null) return;
    final updated = current.copyWith(
      name: name,
      phone: phone,
      address: address,
      district: district,
    );
    final users = _ds.readUsers().map((u) => u.id == updated.id ? updated : u).toList();
    _user = updated;
    notifyListeners();
    await _ds.saveUsers(users);
  }
}
