import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dijab/utils/safe_firestore_parse.dart';

class Product {
  final String id;
  final String name;
  final int price;
  final String description;
  final List<String> imageUrls;
  final String category;
  final Map<String, Variant> variants;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.imageUrls,
    required this.category,
    required this.variants,
  });

  // Convert Firestore Map to Hoodie Object
  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final variantsMap = data['variants'] as Map<String, dynamic>? ?? {};
    
    final variants = variantsMap.map(
      (key, value) => MapEntry(
        key,
        Variant.fromMap(value as Map<String, dynamic>),
      ),
    );

    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      price: safeInt(data['price']),
      description: data['description'] ?? '',
      imageUrls: List<String>.from(data['images'] ?? []),
      category: data['category'] ?? '',
      variants: variants,
    );
  }

  // Convert Hoodie Object to Firestore Map
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'price': price,
      'description': description,
      'images': imageUrls,
      'category': category,
      'variants': variants.map(
        (key, value) => MapEntry(key, value.toMap()),
      ),
    };
  }

  // Get price in EGP format
  String get priceFormatted => '$price EGP';

  // Check if a specific variant is in stock
  bool isVariantInStock(String color, String size) {
    final variantKey = '${color}_$size';
    final variant = variants[variantKey];
    return variant != null && variant.stock > 0;
  }

  // Get available sizes for a color
  List<String> getAvailableSizes(String color) {
    return variants.entries
        .where((entry) => entry.key.startsWith('${color}_') && entry.value.stock > 0)
        .map((entry) => entry.key.split('_').last)
        .toList();
  }

  // Get available colors
  List<String> getAvailableColors(String size) {
    return variants.keys
        .map((key) => key.split('_').first)
        .toSet()
        .toList();
  }
}

class Variant {
  final int stock;
  final int priceAdjustment; // Additional price for this variant

  Variant({
    required this.stock,
    this.priceAdjustment = 0,
  });

  factory Variant.fromMap(Map<String, dynamic> map) {
    return Variant(
      stock: safeInt(map['stock']),
      priceAdjustment: safeInt(map['price_adjustment']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'stock': stock,
      'price_adjustment': priceAdjustment,
    };
  }
}
