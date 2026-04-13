class Address {
  Address({
    required this.id,
    required this.label,
    required this.street,
    required this.city,
    required this.postalCode,
    required this.isDefault,
  });

  final String id;
  final String label;
  final String street;
  final String city;
  final String postalCode;
  final bool isDefault;

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      street: json['street']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      postalCode: json['postalCode']?.toString() ?? '',
      isDefault: json['isDefault'] == true,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'label': label,
      'street': street,
      'city': city,
      'postalCode': postalCode,
      'isDefault': isDefault,
    };
  }
}
