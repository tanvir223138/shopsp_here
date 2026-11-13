class AppUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String passwordHash;
  final String address;
  final String district;

  /// False until the user enters the code that was emailed to them.
  final bool emailVerified;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.passwordHash,
    this.address = '',
    this.district = 'Dhaka',
    this.emailVerified = true,
  });

  AppUser copyWith({
    String? name,
    String? phone,
    String? address,
    String? district,
    bool? emailVerified,
  }) => AppUser(
    id: id,
    name: name ?? this.name,
    email: email,
    phone: phone ?? this.phone,
    passwordHash: passwordHash,
    address: address ?? this.address,
    district: district ?? this.district,
    emailVerified: emailVerified ?? this.emailVerified,
  );
}
