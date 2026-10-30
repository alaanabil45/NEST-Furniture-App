import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/product.dart';

/// A piece the user made from their own photo.
class CustomPiece {
  const CustomPiece({
    required this.id,
    required this.name,
    required this.price,
    required this.height,
    required this.aspect,
    required this.file,
  });

  final String id;
  final String name;
  final int price;

  /// Height in room units (a sofa is about 0.46, a floor lamp 0.82).
  final double height;

  /// width / height of the cutout.
  final double aspect;

  /// File name inside the custom_pieces folder.
  final String file;
}

/// The user's own pieces, saved on the device (metadata in preferences,
/// transparent PNGs in the app's documents folder).
class CustomPiecesController extends ChangeNotifier {
  static const String _key = 'nest.custom_pieces';

  List<CustomPiece> _pieces = <CustomPiece>[];
  final Map<String, Product> _products = <String, Product>{};
  String _dir = '';
  SharedPreferences? _prefs;

  List<CustomPiece> get pieces => List<CustomPiece>.unmodifiable(_pieces);

  /// Newest first.
  List<Product> get products => [for (final p in _pieces) _productOf(p)];

  CustomPiece? pieceFor(String id) {
    for (final p in _pieces) {
      if (p.id == id) return p;
    }
    return null;
  }

  Product? productFor(String id) {
    final piece = pieceFor(id);
    return piece == null ? null : _productOf(piece);
  }

  Product _productOf(CustomPiece p) => _products.putIfAbsent(
    p.id,
    () => Product(
      id: p.id,
      name: p.name,
      description: 'Your own piece.',
      category: ProductCategory.decor,
      price: p.price,
      imageAsset: '$_dir/${p.file}',
      tone: const Color(0xFFF7E3AE),
      isCustom: true,
    ),
  );

  Future<void> _ensureReady() async {
    _prefs ??= await SharedPreferences.getInstance();
    if (_dir.isEmpty) {
      final docs = await getApplicationDocumentsDirectory();
      _dir = '${docs.path}/custom_pieces';
    }
    final folder = Directory(_dir);
    if (!await folder.exists()) await folder.create(recursive: true);
  }

  Future<void> load() async {
    await _ensureReady();
    final raw = _prefs!.getString(_key);
    if (raw == null) return;

    try {
      final data = jsonDecode(raw) as List<dynamic>;
      final loaded = <CustomPiece>[];
      for (final entry in data) {
        final m = entry as Map<String, dynamic>;
        final piece = CustomPiece(
          id: m['id'] as String,
          name: m['name'] as String,
          price: (m['price'] as num).toInt(),
          height: (m['height'] as num).toDouble(),
          aspect: (m['aspect'] as num).toDouble(),
          file: m['file'] as String,
        );
        if (await File('$_dir/${piece.file}').exists()) loaded.add(piece);
      }
      _pieces = loaded;
    } catch (_) {
      _pieces = <CustomPiece>[];
    }
  }

  Future<CustomPiece> add({
    required String name,
    required int price,
    required double height,
    required double aspect,
    required Uint8List png,
  }) async {
    await _ensureReady();
    final id = 'custom-${DateTime.now().microsecondsSinceEpoch}';
    final fileName = '$id.png';
    await File('$_dir/$fileName').writeAsBytes(png, flush: true);

    final piece = CustomPiece(
      id: id,
      name: name,
      price: price,
      height: height,
      aspect: aspect,
      file: fileName,
    );
    _pieces = [piece, ..._pieces];
    notifyListeners();
    _save();
    return piece;
  }

  void _save() {
    _prefs?.setString(
      _key,
      jsonEncode([
        for (final p in _pieces)
          {
            'id': p.id,
            'name': p.name,
            'price': p.price,
            'height': p.height,
            'aspect': p.aspect,
            'file': p.file,
          },
      ]),
    );
  }
}

final CustomPiecesController customPieces = CustomPiecesController();
