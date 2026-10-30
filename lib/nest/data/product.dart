import 'package:flutter/painting.dart';

enum ProductCategory {
  bedroom('Bedroom'),
  nightstands('Nightstands'),
  vanity('Vanity & Dressing'),
  seating('Seating'),
  tables('Tables'),
  storage('Storage'),
  lighting('Lighting'),
  decor('Decor');

  const ProductCategory(this.label);
  final String label;
}

/// 1290 -> "$1,290"
String formatPrice(int value) {
  final digits = value.toString();
  final buffer = StringBuffer('\$');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.imageAsset,
    required this.tone,
    this.isNew = false,
    this.isCustom = false,
  });

  final String id;
  final String name;
  final String description;
  final ProductCategory category;

  /// Whole dollars.
  final int price;

  /// Bundled photo path (assets/...), or for the user's own pieces the
  /// path of a transparent PNG saved on the phone (starts with "/").
  final String imageAsset;

  /// Background color shown behind (and instead of) the photo.
  final Color tone;
  final bool isNew;

  /// True for pieces the user created from their own photo.
  final bool isCustom;

  String get priceLabel => formatPrice(price);
}
