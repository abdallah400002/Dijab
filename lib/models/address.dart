class Address {
  final String city;
  final String street;
  final String? building;
  final String? apartment;

  Address({
    required this.city,
    required this.street,
    this.building,
    this.apartment,
  });

  factory Address.fromMap(Map<String, dynamic> map) {
    return Address(
      city: map['city'] ?? '',
      street: map['street'] ?? '',
      building: map['building'],
      apartment: map['apartment'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'city': city,
      'street': street,
      if (building != null) 'building': building,
      if (apartment != null) 'apartment': apartment,
    };
  }

  String get fullAddress => '$street, ${building != null ? 'Building $building, ' : ''}${apartment != null ? 'Apartment $apartment, ' : ''}$city';
}
