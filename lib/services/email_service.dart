import 'package:dio/dio.dart';

import '../core/email_config.dart';

class EmailException implements Exception {
  const EmailException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Sends real emails through the EmailJS REST API (no own server needed).
class EmailService {
  EmailService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
            ),
          );

  final Dio _dio;

  static const _endpoint = 'https://api.emailjs.com/api/v1.0/email/send';

  bool get isConfigured => EmailConfig.isConfigured;

  Future<void> send({
    required String toEmail,
    required String toName,
    required String subject,
    required String message,
  }) async {
    if (!isConfigured) throw const EmailException('Email service is not configured.');
    try {
      await _dio.post(
        _endpoint,
        options: Options(headers: {'Content-Type': 'application/json'}),
        data: {
          'service_id': EmailConfig.serviceId,
          'template_id': EmailConfig.templateId,
          'user_id': EmailConfig.publicKey,
          'template_params': {
            'to_email': toEmail,
            'to_name': toName,
            'subject': subject,
            'message': message,
            'app_name': EmailConfig.appName,
          },
        },
      );
    } on DioException catch (e) {
      final noNet =
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout;
      if (noNet) {
        throw const EmailException('No internet connection. Please check it and try again.');
      }
      throw EmailException('Could not send the email (${e.response?.statusCode ?? 'error'}).');
    } catch (_) {
      throw const EmailException('Could not send the email. Please try again.');
    }
  }

  Future<void> sendVerificationCode({
    required String toEmail,
    required String toName,
    required String code,
  }) => send(
    toEmail: toEmail,
    toName: toName,
    subject: 'Your ${EmailConfig.appName} verification code',
    message:
        'Hi $toName,\n\nWelcome to ${EmailConfig.appName}! Your verification code is:\n\n'
        '$code\n\nThe code is valid for 10 minutes. If you did not create this account, '
        'you can ignore this email.',
  );

  Future<void> sendLoginAlert({required String toEmail, required String toName}) {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    final when =
        '${now.year}-${two(now.month)}-${two(now.day)} ${two(now.hour)}:${two(now.minute)}';
    return send(
      toEmail: toEmail,
      toName: toName,
      subject: 'New login to your ${EmailConfig.appName} account',
      message:
          'Hi $toName,\n\nYou just logged in to your ${EmailConfig.appName} account ($when). '
          'If this was not you, please change your password.',
    );
  }
}
