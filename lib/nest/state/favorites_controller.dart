import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/catalog.dart';

/// Favorites, saved on the device.
class FavoritesController extends ChangeNotifier {
  static const String _key = 'nest.favorites';

  final Set<String> _ids = <String>{};
  SharedPreferences? _prefs;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final saved = _prefs!.getStringList(_key) ?? const <String>[];
    _ids
      ..clear()
      ..addAll(saved.where((id) => Catalog.all.any((p) => p.id == id)));
  }

  int get count => _ids.length;

  bool isFavorite(String id) => _ids.contains(id);

  void toggle(String id) {
    if (!_ids.remove(id)) _ids.add(id);
    notifyListeners();
    _prefs?.setStringList(_key, _ids.toList());
  }
}

final FavoritesController favoritesController = FavoritesController();
