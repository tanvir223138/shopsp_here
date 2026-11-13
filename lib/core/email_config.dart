
class EmailConfig {
  static const String serviceId = 'service_5e8kt6f';
  static const String templateId = 'template_vsjge2t';
  static const String publicKey = 'Eu_dH96OW3wgFmshM';
  static const bool sendLoginAlert = true;

  static const String appName = 'ShopSphere';

  static bool get isConfigured =>
      !serviceId.startsWith('YOUR_') &&
      !templateId.startsWith('YOUR_') &&
      !publicKey.startsWith('YOUR_');
}
