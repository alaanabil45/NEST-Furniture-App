import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/catalog.dart';
import '../data/product.dart';

class CartLine {
  const CartLine(this.product, this.quantity);

  final Product product;
  final int quantity;

  int get total => product.price * quantity;
}

/// Cart contents, saved on the device as "productId|quantity".
class CartController extends ChangeNotifier {
  static const String _key = 'nest.cart';
  static const int maxQuantity = 9;

  final Map<String, int> _lines = <String, int>{};
  SharedPreferences? _prefs;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final saved = _prefs!.getStringList(_key) ?? const <String>[];
    _lines.clear();
    for (final entry in saved) {
      final parts = entry.split('|');
      if (parts.length != 2) continue;
      final quantity = int.tryParse(parts[1]);
      final known = Catalog.all.any((p) => p.id == parts[0]);
      if (quantity != null && quantity > 0 && known) {
        _lines[parts[0]] = quantity.clamp(1, maxQuantity).toInt();
      }
    }
  }

  int quantityOf(String id) => _lines[id] ?? 0;

  List<CartLine> get lines => [
    for (final e in _lines.entries) CartLine(Catalog.byId(e.key), e.value),
  ];

  int get itemCount => _lines.values.fold(0, (sum, q) => sum + q);

  int get subtotal => lines.fold(0, (sum, line) => sum + line.total);

  void add(String id) => setQuantity(id, quantityOf(id) + 1);

  void remove(String id) => setQuantity(id, 0);

  void setQuantity(String id, int quantity) {
    if (quantity <= 0) {
      _lines.remove(id);
    } else {
      _lines[id] = quantity > maxQuantity ? maxQuantity : quantity;
    }
    notifyListeners();
    _save();
  }

  void _save() {
    _prefs?.setStringList(_key, [
      for (final e in _lines.entries) '${e.key}|${e.value}',
    ]);
  }
}

final CartController cartController = CartController();
