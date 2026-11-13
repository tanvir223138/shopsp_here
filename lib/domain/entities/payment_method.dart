enum PaymentMethod {
  bkash('bKash', 'Pay with your bKash account'),
  nagad('Nagad', 'Pay with your Nagad account'),
  rocket('Rocket', 'Pay with your Rocket account'),
  card('Credit / Debit Card', 'Visa, Mastercard, Amex'),
  bank('Internet Banking', 'Dutch-Bangla, BRAC, City and more'),
  cod('Cash on Delivery', 'Pay when you receive the parcel');

  const PaymentMethod(this.label, this.subtitle);
  final String label;
  final String subtitle;

  bool get isWallet => this == bkash || this == nagad || this == rocket;
  bool get isOnline => this != cod;
}
