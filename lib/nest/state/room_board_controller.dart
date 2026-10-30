import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/catalog.dart';

/// Where a piece sits in the room.
/// dx / dy are fractions (0..1) across the floor: dx left to right,
/// dy back wall (0) to front (1).
class PieceLayout {
  const PieceLayout({
    required this.dx,
    required this.dy,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.flip = false,
  });

  final double dx;
  final double dy;
  final double scale;
  final double rotation;

  /// Mirrors the piece horizontally (changes the way it faces).
  final bool flip;

  PieceLayout copyWith({
    double? dx,
    double? dy,
    double? scale,
    double? rotation,
    bool? flip,
  }) => PieceLayout(
    dx: dx ?? this.dx,
    dy: dy ?? this.dy,
    scale: scale ?? this.scale,
    rotation: rotation ?? this.rotation,
    flip: flip ?? this.flip,
  );

  Map<String, double> toJson() => {
    'x': dx,
    'y': dy,
    's': scale,
    'r': rotation,
    'f': flip ? 1.0 : 0.0,
  };

  static PieceLayout? fromJson(Object? json) {
    if (json is! Map) return null;
    final x = json['x'];
    final y = json['y'];
    final s = json['s'];
    final r = json['r'];
    final f = json['f'];
    if (x is! num || y is! num) return null;
    return PieceLayout(
      dx: x.toDouble(),
      dy: y.toDouble(),
      scale: s is num ? s.toDouble() : 1.0,
      rotation: r is num ? r.toDouble() : 0.0,
      flip: f is num && f > 0.5,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PieceLayout &&
      other.dx == dx &&
      other.dy == dy &&
      other.scale == scale &&
      other.rotation == rotation &&
      other.flip == flip;

  @override
  int get hashCode => Object.hash(dx, dy, scale, rotation, flip);
}

class Room {
  const Room({
    required this.id,
    required this.name,
    required this.budget,
    this.items = const <String, int>{},
    this.layout = const <String, PieceLayout>{},
    this.wall = 0,
    this.floor = 0,
  });

  final String id;
  final String name;
  final int budget;

  /// productId -> quantity
  final Map<String, int> items;

  /// productId -> position in the room (missing = automatic position)
  final Map<String, PieceLayout> layout;

  /// Index of the chosen wall color.
  final int wall;

  /// Index of the chosen floor style (wood or color).
  final int floor;

  static const List<PieceLayout> _defaults = [
    PieceLayout(dx: 0.50, dy: 0.36),
    PieceLayout(dx: 0.24, dy: 0.54),
    PieceLayout(dx: 0.76, dy: 0.54),
    PieceLayout(dx: 0.38, dy: 0.76),
    PieceLayout(dx: 0.64, dy: 0.76),
    PieceLayout(dx: 0.50, dy: 0.58),
  ];

  PieceLayout layoutOf(String productId) {
    final saved = layout[productId];
    if (saved != null) return saved;
    final index = items.keys.toList().indexOf(productId);
    return _defaults[(index < 0 ? 0 : index) % _defaults.length];
  }

  Room copyWith({
    String? name,
    int? budget,
    Map<String, int>? items,
    Map<String, PieceLayout>? layout,
    int? wall,
    int? floor,
  }) => Room(
    id: id,
    name: name ?? this.name,
    budget: budget ?? this.budget,
    items: items ?? this.items,
    layout: layout ?? this.layout,
    wall: wall ?? this.wall,
    floor: floor ?? this.floor,
  );

  int get spent => items.entries.fold(
    0,
    (sum, e) => sum + Catalog.byId(e.key).price * e.value,
  );

  int get itemCount => items.values.fold(0, (sum, q) => sum + q);

  int get remaining => budget - spent;

  bool get isOver => spent > budget;

  /// 0 = empty, 1 = exactly on budget, above 1 = over budget.
  double get usedFraction {
    if (budget <= 0) return spent > 0 ? 1.0 : 0.0;
    return spent / budget;
  }
}

/// Rooms and the pieces collected for each, saved on the device.
class RoomBoardController extends ChangeNotifier {
  static const String _key = 'nest.rooms';
  static const String _selectedKey = 'nest.rooms.selected';
  static const int maxQuantity = 9;

  List<Room> _rooms = <Room>[];
  String? _selectedId;
  SharedPreferences? _prefs;

  List<Room> get rooms => List<Room>.unmodifiable(_rooms);

  Room? get selected {
    if (_rooms.isEmpty) return null;
    for (final room in _rooms) {
      if (room.id == _selectedId) return room;
    }
    return _rooms.first;
  }

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    _selectedId = _prefs!.getString(_selectedKey);
    final raw = _prefs!.getString(_key);
    if (raw == null) return;

    try {
      final data = jsonDecode(raw) as List<dynamic>;
      final loaded = <Room>[];
      for (final entry in data) {
        final map = entry as Map<String, dynamic>;

        final items = <String, int>{};
        final rawItems = (map['items'] as Map<String, dynamic>?) ?? {};
        rawItems.forEach((id, q) {
          final qty = (q as num).toInt();
          if (qty > 0 && Catalog.exists(id)) {
            items[id] = qty.clamp(1, maxQuantity).toInt();
          }
        });

        final layout = <String, PieceLayout>{};
        final rawLayout = (map['layout'] as Map<String, dynamic>?) ?? {};
        rawLayout.forEach((id, value) {
          final parsed = PieceLayout.fromJson(value);
          if (parsed != null && items.containsKey(id)) layout[id] = parsed;
        });

        loaded.add(
          Room(
            id: map['id'] as String,
            name: map['name'] as String,
            budget: (map['budget'] as num).toInt(),
            items: items,
            layout: layout,
            wall: (map['wall'] as num?)?.toInt() ?? 0,
            floor: (map['floor'] as num?)?.toInt() ?? 0,
          ),
        );
      }
      _rooms = loaded;
    } catch (_) {
      _rooms = <Room>[];
    }
  }

  int quantityIn(String roomId, String productId) {
    for (final room in _rooms) {
      if (room.id == roomId) return room.items[productId] ?? 0;
    }
    return 0;
  }

  Room addRoom(String name, int budget) {
    final room = Room(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      budget: budget,
    );
    _rooms = [..._rooms, room];
    _selectedId = room.id;
    _changed();
    return room;
  }

  Room updateRoom(String id, {required String name, required int budget}) {
    late Room updated;
    _replace(id, (room) => updated = room.copyWith(name: name, budget: budget));
    return updated;
  }

  void select(String id) {
    if (!_rooms.any((r) => r.id == id)) return;
    _selectedId = id;
    _changed();
  }

  void deleteRoom(String id) {
    _rooms = _rooms.where((r) => r.id != id).toList();
    if (_selectedId == id) {
      _selectedId = _rooms.isEmpty ? null : _rooms.first.id;
    }
    _changed();
  }

  void addItem(String roomId, String productId) =>
      setQuantity(roomId, productId, quantityIn(roomId, productId) + 1);

  void setQuantity(String roomId, String productId, int quantity) {
    _replace(roomId, (room) {
      final items = Map<String, int>.of(room.items);
      final layout = Map<String, PieceLayout>.of(room.layout);
      if (quantity <= 0) {
        items.remove(productId);
        layout.remove(productId);
      } else {
        items[productId] = quantity > maxQuantity ? maxQuantity : quantity;
      }
      return room.copyWith(items: items, layout: layout);
    });
  }

  /// Saves where a piece sits in the room (call when a gesture ends).
  void setLayout(String roomId, String productId, PieceLayout value) {
    _replace(roomId, (room) {
      if (!room.items.containsKey(productId)) return room;
      final layout = Map<String, PieceLayout>.of(room.layout);
      layout[productId] = value;
      return room.copyWith(layout: layout);
    });
  }

  void setWall(String roomId, int wall) {
    _replace(roomId, (room) => room.copyWith(wall: wall));
  }

  void setFloor(String roomId, int floor) {
    _replace(roomId, (room) => room.copyWith(floor: floor));
  }

  void _replace(String id, Room Function(Room) change) {
    _rooms = [for (final r in _rooms) r.id == id ? change(r) : r];
    _changed();
  }

  void _changed() {
    notifyListeners();
    _save();
  }

  void _save() {
    final prefs = _prefs;
    if (prefs == null) return;
    prefs.setString(
      _key,
      jsonEncode([
        for (final r in _rooms)
          {
            'id': r.id,
            'name': r.name,
            'budget': r.budget,
            'items': r.items,
            'layout': {
              for (final e in r.layout.entries) e.key: e.value.toJson(),
            },
            'wall': r.wall,
            'floor': r.floor,
          },
      ]),
    );
    final id = _selectedId;
    if (id != null) prefs.setString(_selectedKey, id);
  }
}

final RoomBoardController roomBoardController = RoomBoardController();
