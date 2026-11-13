class ApiConstants {
  static const String baseUrl = 'https://dummyjson.com';
  static const int pageSize = 20;
}

class ShopConstants {
  static const double freeShippingFrom = 3000; // BDT
  static const double shippingInsideDhaka = 60;
  static const double shippingOutsideDhaka = 120;

  static const List<String> districts = [
    'Dhaka',
    'Gazipur',
    'Narayanganj',
    'Chattogram',
    'Cumilla',
    "Cox's Bazar",
    'Sylhet',
    'Rajshahi',
    'Bogura',
    'Khulna',
    'Jashore',
    'Barishal',
    'Rangpur',
    'Mymensingh',
  ];

  static const List<String> banks = [
    'Dutch-Bangla Bank',
    'BRAC Bank',
    'City Bank',
    'Islami Bank',
    'Eastern Bank',
    'Sonali Bank',
  ];

  // Demo account shown on the login screen.
  static const String demoEmail = 'demo@shopsphere.com';
  static const String demoPassword = 'demo1234';
}
