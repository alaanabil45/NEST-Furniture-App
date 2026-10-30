import 'dart:math' as math;
import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/nest_theme.dart';
import '../data/catalog.dart';
import '../data/product.dart';
import '../state/room_board_controller.dart';
import '../state/custom_pieces_controller.dart';
import 'category_style.dart';
import 'nest_button.dart';
import 'nest_image.dart';
import 'pressable.dart';
import 'quantity_stepper.dart';
import 'room_sheets.dart';

// ------------------------------------------------------------------ options

/// Wall colors the user can choose from (Room.wall is an index into this).
const List<Color> kRoomWalls = [
  Color(0xFFEFE6D2),
  Color(0xFFF7E3AE),
  Color(0xFFC9D8C3),
  Color(0xFFF6B9A5),
  Color(0xFFB9C7F2),
  Color(0xFFF8F3E8),
];

class FloorStyle {
  const FloorStyle(this.name, this.color, {this.wood = false});

  final String name;
  final Color color;
  final bool wood;
}

/// Floor styles (Room.floor is an index into this).
const List<FloorStyle> kRoomFloors = [
  FloorStyle('Oak', Color(0xFFC9A073), wood: true),
  FloorStyle('Walnut', Color(0xFF8B5E3C), wood: true),
  FloorStyle('Ash', Color(0xFFE3D0A8), wood: true),
  FloorStyle('Cream', Color(0xFFECE2CB)),
  FloorStyle('Sage', Color(0xFFB7CBB0)),
  FloorStyle('Sky', Color(0xFFB3C3EF)),
];

// ------------------------------------------------------------------- world

const double _roomHeight = 1.0;
const double _slab = 0.1;
const double _floorLimit = 0.9;
const double _cameraDistance = 4.6;
const double _targetY = 0.25;

/// Transparent PNG of a product, named after its id.
String cutoutAssetFor(Product p) => 'assets/images/nest/cutouts/${p.id}.png';

class _Spec {
  const _Spec(this.height, {this.foot = 0.2, this.rug = 0.0});

  /// Height in room units (the room floor is 2 units wide).
  final double height;

  /// Half-width of the footprint (for the shadow and selection ring).
  final double foot;

  /// If > 0 the piece lies flat on the floor (a rug) with this half-size.
  final double rug;

  bool get flat => rug > 0;
}

const Map<String, _Spec> _specs = {
  'oslo-sofa': _Spec(0.46, foot: 0.45),
  'miro-chair': _Spec(0.40, foot: 0.22),
  'pilar-table': _Spec(0.22, foot: 0.24),
  'dune-table': _Spec(0.34, foot: 0.36),
  'arc-lamp': _Spec(0.82, foot: 0.13),
  'haven-sideboard': _Spec(0.34, foot: 0.36),
  'terra-vase': _Spec(0.16, foot: 0.08),
  'bloom-rug': _Spec(0.0, rug: 0.5),
};

_Spec _specFor(String id) {
  final known = _specs[id];
  if (known != null) return known;

  // A piece the user made from their own photo.
  final custom = customPieces.pieceFor(id);
  if (custom != null) {
    return _Spec(
      custom.height,
      foot: (custom.height * custom.aspect / 2).clamp(0.08, 0.6).toDouble(),
    );
  }

  final name = Catalog.byId(id).name.toLowerCase();
  if (id.contains('rug') || name.contains('rug') || name.contains('carpet')) {
    return const _Spec(0.0, rug: 0.5);
  }
  return const _Spec(0.4);
}

// Wall i runs from corner i to corner i+1 (x, z).
const List<List<double>> _corners = [
  [-1.0, -1.0],
  [1.0, -1.0],
  [1.0, 1.0],
  [-1.0, 1.0],
];

// Inner normal of each wall (x, z).
const List<List<double>> _normals = [
  [0.0, 1.0],
  [-1.0, 0.0],
  [0.0, -1.0],
  [1.0, 0.0],
];

// ------------------------------------------------------------------- camera

class _V3 {
  const _V3(this.x, this.y, this.z);

  final double x;
  final double y;
  final double z;

  _V3 operator +(_V3 o) => _V3(x + o.x, y + o.y, z + o.z);
  _V3 operator -(_V3 o) => _V3(x - o.x, y - o.y, z - o.z);
  _V3 times(double k) => _V3(x * k, y * k, z * k);
  double dot(_V3 o) => x * o.x + y * o.y + z * o.z;
  _V3 cross(_V3 o) =>
      _V3(y * o.z - z * o.y, z * o.x - x * o.z, x * o.y - y * o.x);
  _V3 normalized() {
    final l = math.sqrt(dot(this));
    return l == 0 ? this : times(1 / l);
  }
}

class _Proj {
  const _Proj(this.offset, this.depth);

  final Offset offset;
  final double depth;
}

/// A simple orbiting pinhole camera that looks at the middle of the room.
class _Cam {
  _Cam({
    required this.yaw,
    required this.elevation,
    required this.size,
    required this.f,
    required this.center,
  });

  final double yaw;
  final double elevation;
  final Size size;
  final double f;
  final Offset center;

  late final _V3 pos = _V3(
    math.sin(yaw) * math.cos(elevation) * _cameraDistance,
    _targetY + math.sin(elevation) * _cameraDistance,
    math.cos(yaw) * math.cos(elevation) * _cameraDistance,
  );
  late final _V3 fwd = (const _V3(0, _targetY, 0) - pos).normalized();
  late final _V3 right = fwd.cross(const _V3(0, 1, 0)).normalized();
  late final _V3 up = right.cross(fwd);

  _Proj project(_V3 p) {
    final v = p - pos;
    final d = v.dot(fwd);
    return _Proj(
      Offset(
        size.width / 2 + center.dx + f * v.dot(right) / d,
        size.height / 2 + center.dy - f * v.dot(up) / d,
      ),
      d,
    );
  }

  /// Screen point -> point on the floor (x, z), or null if it misses.
  Offset? floorPoint(Offset s) {
    final a = (s.dx - size.width / 2 - center.dx) / f;
    final b = (size.height / 2 + center.dy - s.dy) / f;
    final dir = fwd + right.times(a) + up.times(b);
    if (dir.y > -1e-6) return null;
    final t = -pos.y / dir.y;
    return Offset(pos.x + t * dir.x, pos.z + t * dir.z);
  }

  bool wallVisible(int w) {
    final a = _corners[w];
    final b = _corners[(w + 1) % 4];
    final cx = (a[0] + b[0]) / 2;
    final cz = (a[1] + b[1]) / 2;
    final n = _normals[w];
    return (pos.x - cx) * n[0] + (pos.z - cz) * n[1] > 0;
  }
}

class _Fit {
  const _Fit(this.f, this.center);

  final double f;
  final Offset center;
}

/// Picks a zoom that keeps the whole room inside the canvas for any rotation.
_Fit _fitCamera(Size size, double elevation) {
  var minX = double.infinity;
  var maxX = -double.infinity;
  var minY = double.infinity;
  var maxY = -double.infinity;

  for (final yaw in [0.0, math.pi / 4, -math.pi / 4]) {
    final cam = _Cam(
      yaw: yaw,
      elevation: elevation,
      size: Size.zero,
      f: 1,
      center: Offset.zero,
    );
    for (final y in [-_slab, _roomHeight]) {
      for (final sx in [-1.0, 1.0]) {
        for (final sz in [-1.0, 1.0]) {
          final p = cam.project(_V3(sx, y, sz)).offset;
          minX = math.min(minX, p.dx);
          maxX = math.max(maxX, p.dx);
          minY = math.min(minY, p.dy);
          maxY = math.max(maxY, p.dy);
        }
      }
    }
  }

  final spanX = maxX - minX;
  final spanY = maxY - minY;
  final f = math.min(size.width * 0.94 / spanX, size.height * 0.92 / spanY);
  return _Fit(f, Offset(-(minX + maxX) / 2 * f, -(minY + maxY) / 2 * f));
}

// ------------------------------------------------------------ draw helpers

class _RugDraw {
  const _RugDraw(this.points, this.color);

  final List<Offset> points;
  final Color color;
}

class _ShadowDraw {
  const _ShadowDraw(this.center, this.rx);

  final Offset center;
  final double rx;
}

class _Ring {
  const _Ring(this.center, this.rx);

  final Offset center;
  final double rx;
}

Color _darker(Color c, double amount) => Color.lerp(c, Colors.black, amount)!;
Color _lighter(Color c, double amount) => Color.lerp(c, Colors.white, amount)!;

class _RoomPainter extends CustomPainter {
  _RoomPainter({
    required this.cam,
    required this.wall,
    required this.floor,
    required this.rugs,
    required this.shadows,
    required this.ring,
  });

  final _Cam cam;
  final Color wall;
  final FloorStyle floor;
  final List<_RugDraw> rugs;
  final List<_ShadowDraw> shadows;
  final _Ring? ring;

  Offset _p(double x, double y, double z) => cam.project(_V3(x, y, z)).offset;

  /// Point on wall [w]: u along the wall (0..1), v up the wall (0..1).
  Offset _w(int w, double u, double v) {
    final a = _corners[w];
    final b = _corners[(w + 1) % 4];
    return _p(
      a[0] + (b[0] - a[0]) * u,
      v * _roomHeight,
      a[1] + (b[1] - a[1]) * u,
    );
  }

  Path _quad(List<Offset> pts) {
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (var i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }
    return path..close();
  }

  Path _wallQuad(int w, double u0, double u1, double v0, double v1) =>
      _quad([_w(w, u0, v0), _w(w, u1, v0), _w(w, u1, v1), _w(w, u0, v1)]);

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint();
    final stroke = Paint()..style = PaintingStyle.stroke;

    // ---- floor slab (the thickness seen from the front)
    for (var w = 0; w < 4; w++) {
      if (cam.wallVisible(w)) continue;
      final a = _corners[w];
      final b = _corners[(w + 1) % 4];
      fill.color = _darker(floor.color, 0.3);
      canvas.drawPath(
        _quad([
          _p(a[0], 0, a[1]),
          _p(b[0], 0, b[1]),
          _p(b[0], -_slab, b[1]),
          _p(a[0], -_slab, a[1]),
        ]),
        fill,
      );
    }

    // ---- floor
    fill.color = floor.color;
    canvas.drawPath(
      _quad([_p(-1, 0, -1), _p(1, 0, -1), _p(1, 0, 1), _p(-1, 0, 1)]),
      fill,
    );

    if (floor.wood) {
      const planks = 10;
      stroke
        ..strokeWidth = 1
        ..color = const Color(0x30000000);
      for (var i = 0; i < planks; i++) {
        final x0 = -1 + 2 * i / planks;
        final x1 = -1 + 2 * (i + 1) / planks;
        final k = ((i * 53 + 17) % 7) / 7.0;
        final shade = (k - 0.5) * 0.14;
        fill.color = shade >= 0
            ? _lighter(floor.color, shade)
            : _darker(floor.color, -shade);
        final plank = _quad([
          _p(x0, 0, -1),
          _p(x1, 0, -1),
          _p(x1, 0, 1),
          _p(x0, 0, 1),
        ]);
        canvas.drawPath(plank, fill);
        canvas.drawPath(plank, stroke);
        final seam = -1 + 2 * (((i * 37 + 11) % 9) + 0.5) / 9;
        canvas.drawLine(_p(x0, 0, seam), _p(x1, 0, seam), stroke);
      }
    } else {
      stroke
        ..strokeWidth = 1
        ..color = const Color(0x14000000);
      const cells = 8;
      for (var i = 0; i <= cells; i++) {
        final t = -1 + 2 * i / cells;
        canvas.drawLine(_p(t, 0, -1), _p(t, 0, 1), stroke);
        canvas.drawLine(_p(-1, 0, t), _p(1, 0, t), stroke);
      }
    }

    // ---- walls
    const shades = [0.0, 0.07, 0.0, 0.07];
    for (var w = 0; w < 4; w++) {
      if (!cam.wallVisible(w)) continue;
      final color = _darker(wall, shades[w]);
      fill.color = color;
      canvas.drawPath(_wallQuad(w, 0, 1, 0, 1), fill);

      // baseboard
      fill.color = _darker(color, 0.12);
      canvas.drawPath(_wallQuad(w, 0, 1, 0, 0.06), fill);

      // top edge
      stroke
        ..strokeWidth = 2
        ..color = _darker(color, 0.2);
      canvas.drawLine(_w(w, 0, 1), _w(w, 1, 1), stroke);

      if (w == 0 || w == 2) {
        _window(canvas, w);
      } else {
        _picture(canvas, w, w == 1 ? NestColors.coral : NestColors.butter);
      }
    }

    // ---- rugs
    for (final rug in rugs) {
      fill.color = rug.color;
      canvas.drawPath(_quad(rug.points), fill);
      final c = Offset(
        rug.points.fold(0.0, (s, o) => s + o.dx) / 4,
        rug.points.fold(0.0, (s, o) => s + o.dy) / 4,
      );
      stroke
        ..strokeWidth = 2
        ..color = NestColors.cream.withValues(alpha: 0.7);
      for (final inset in [0.16, 0.34]) {
        canvas.drawPath(
          _quad([for (final p in rug.points) Offset.lerp(p, c, inset)!]),
          stroke,
        );
      }
    }

    // ---- shadows
    for (final s in shadows) {
      fill.color = const Color(0x14000000);
      canvas.drawOval(
        Rect.fromCenter(
          center: s.center,
          width: s.rx * 2.5,
          height: s.rx * 2.5 * 0.34,
        ),
        fill,
      );
      fill.color = const Color(0x26000000);
      canvas.drawOval(
        Rect.fromCenter(
          center: s.center,
          width: s.rx * 1.7,
          height: s.rx * 1.7 * 0.34,
        ),
        fill,
      );
    }

    // ---- selection ring
    final r = ring;
    if (r != null) {
      stroke
        ..strokeWidth = 3
        ..color = NestColors.cobalt;
      canvas.drawOval(
        Rect.fromCenter(
          center: r.center,
          width: r.rx * 2,
          height: r.rx * 2 * 0.34,
        ),
        stroke,
      );
    }
  }

  void _window(Canvas canvas, int w) {
    final fill = Paint()..color = NestColors.cream;
    canvas.drawPath(_wallQuad(w, 0.28, 0.62, 0.40, 0.88), fill);
    fill.color = const Color(0xFFDDE7FA);
    canvas.drawPath(_wallQuad(w, 0.30, 0.60, 0.43, 0.85), fill);
    final bar = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = NestColors.cream;
    canvas.drawLine(_w(w, 0.45, 0.43), _w(w, 0.45, 0.85), bar);
    canvas.drawLine(_w(w, 0.30, 0.64), _w(w, 0.60, 0.64), bar);
  }

  void _picture(Canvas canvas, int w, Color color) {
    final fill = Paint()..color = NestColors.cream;
    canvas.drawPath(_wallQuad(w, 0.38, 0.66, 0.48, 0.80), fill);
    fill.color = color;
    canvas.drawPath(_wallQuad(w, 0.41, 0.63, 0.52, 0.76), fill);
    fill.color = NestColors.cream.withValues(alpha: 0.85);
    final c = _w(w, 0.52, 0.64);
    final e = _w(w, 0.56, 0.64);
    canvas.drawCircle(c, (e - c).distance, fill);
  }

  @override
  bool shouldRepaint(covariant _RoomPainter oldDelegate) => true;
}

// ------------------------------------------------------------------- widget

class _Placed {
  const _Placed({
    required this.id,
    required this.product,
    required this.layout,
    required this.spec,
    required this.x,
    required this.z,
    required this.scale,
    required this.foot,
    required this.quad,
  });

  final String id;
  final Product product;
  final PieceLayout layout;
  final _Spec spec;
  final double x;
  final double z;
  final double scale;
  final _Proj foot;
  final List<Offset> quad;
}

/// A 3D-looking room. Drag the room to look around, drag pieces on the floor.
/// Place it inside a bounded-height parent (e.g. Expanded).
class RoomCanvasView extends StatefulWidget {
  const RoomCanvasView({super.key, required this.room});

  final Room room;

  @override
  State<RoomCanvasView> createState() => _RoomCanvasViewState();
}

class _RoomCanvasViewState extends State<RoomCanvasView>
    with SingleTickerProviderStateMixin {
  final GlobalKey _canvasKey = GlobalKey();

  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  double _yaw = -0.9;
  double _elev = 0.85;
  double _fromYaw = 0;
  double _toYaw = 0;
  double _fromElev = 0;
  double _toElev = 0;
  bool _started = false;
  bool _touched = false;

  String? _selectedId;
  String? _dragId;
  PieceLayout? _live;
  Offset _grab = Offset.zero;
  double? _liveScale;

  @override
  void initState() {
    super.initState();
    _spin.addListener(() {
      final t = Curves.easeOutCubic.transform(_spin.value);
      setState(() {
        _yaw = _fromYaw + (_toYaw - _fromYaw) * t;
        _elev = _fromElev + (_toElev - _fromElev) * t;
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _yaw = 0.35;
      _elev = 0.42;
    } else {
      _animateTo(0.35, 0.42);
    }
  }

  @override
  void didUpdateWidget(RoomCanvasView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.room.id != widget.room.id) {
      _selectedId = null;
      _dragId = null;
      _live = null;
      _liveScale = null;
    } else if (_selectedId != null &&
        !widget.room.items.containsKey(_selectedId)) {
      _selectedId = null;
      _liveScale = null;
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  void _animateTo(double yaw, double elev) {
    _fromYaw = _yaw;
    _toYaw = yaw;
    _fromElev = _elev;
    _toElev = elev;
    _spin.forward(from: 0);
  }

  Offset? _floorAt(_Cam cam, Offset global) {
    final box = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    return cam.floorPoint(box.globalToLocal(global));
  }

  void _dragStart(_Placed p, _Cam cam, Offset global) {
    _spin.stop();
    HapticFeedback.selectionClick();
    final hit = _floorAt(cam, global);
    setState(() {
      _selectedId = p.id;
      _dragId = p.id;
      _live = p.layout;
      _grab = hit == null ? Offset.zero : Offset(p.x - hit.dx, p.z - hit.dy);
      _touched = true;
    });
  }

  void _dragUpdate(_Cam cam, Offset global) {
    final hit = _floorAt(cam, global);
    final live = _live;
    if (hit == null || live == null) return;
    final x = (hit.dx + _grab.dx).clamp(-_floorLimit, _floorLimit).toDouble();
    final z = (hit.dy + _grab.dy).clamp(-_floorLimit, _floorLimit).toDouble();
    setState(() {
      _live = live.copyWith(
        dx: x / (2 * _floorLimit) + 0.5,
        dy: z / (2 * _floorLimit) + 0.5,
      );
    });
  }

  void _dragEnd() {
    final id = _dragId;
    final live = _live;
    if (id != null && live != null && live != widget.room.layoutOf(id)) {
      roomBoardController.setLayout(widget.room.id, id, live);
    }
    setState(() {
      _dragId = null;
      _live = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    final selected =
        (_selectedId != null && room.items.containsKey(_selectedId))
        ? _selectedId
        : null;

    final Widget panel;
    if (selected == null) {
      panel = _StylePanel(key: const ValueKey<String>('style'), room: room);
    } else {
      final layout = room.layoutOf(selected);
      panel = _PiecePanel(
        key: ValueKey<String>('piece-$selected'),
        room: room,
        productId: selected,
        scale: (_liveScale ?? layout.scale).clamp(0.6, 1.6).toDouble(),
        onScale: (v) => setState(() => _liveScale = v),
        onScaleEnd: (v) {
          roomBoardController.setLayout(
            room.id,
            selected,
            room.layoutOf(selected).copyWith(scale: v),
          );
          setState(() => _liveScale = null);
        },
      );
    }

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, c) =>
                _buildScene(room, selected, Size(c.maxWidth, c.maxHeight)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 104,
          child: AnimatedSwitcher(duration: NestMotion.base, child: panel),
        ),
      ],
    );
  }

  Widget _buildScene(Room room, String? selected, Size size) {
    final fit = _fitCamera(size, _elev);
    final cam = _Cam(
      yaw: _yaw,
      elevation: _elev,
      size: size,
      f: fit.f,
      center: fit.center,
    );
    final wallColor = kRoomWalls[room.wall % kRoomWalls.length];
    final floor = kRoomFloors[room.floor % kRoomFloors.length];

    // Work out where every piece is on screen.
    final placed = <_Placed>[];
    for (final entry in room.items.entries) {
      final product = Catalog.byId(entry.key);
      final layout = (entry.key == _dragId && _live != null)
          ? _live!
          : room.layoutOf(entry.key);
      final rawScale = (entry.key == selected && _liveScale != null)
          ? _liveScale!
          : layout.scale;
      final scale = rawScale.clamp(0.6, 1.6).toDouble();
      final spec = _specFor(entry.key);
      final x = (layout.dx - 0.5) * 2 * _floorLimit;
      final z = (layout.dy - 0.5) * 2 * _floorLimit;

      var quad = const <Offset>[];
      if (spec.flat) {
        final w = spec.rug * scale * 1.1;
        final d = spec.rug * scale * 0.8;
        quad = [
          cam.project(_V3(x - w, 0, z - d)).offset,
          cam.project(_V3(x + w, 0, z - d)).offset,
          cam.project(_V3(x + w, 0, z + d)).offset,
          cam.project(_V3(x - w, 0, z + d)).offset,
        ];
      }

      placed.add(
        _Placed(
          id: entry.key,
          product: product,
          layout: layout,
          spec: spec,
          x: x,
          z: z,
          scale: scale,
          foot: cam.project(_V3(x, 0, z)),
          quad: quad,
        ),
      );
    }

    // Rugs first, then far pieces, then near pieces.
    placed.sort((a, b) {
      if (a.spec.flat != b.spec.flat) return a.spec.flat ? -1 : 1;
      return b.foot.depth.compareTo(a.foot.depth);
    });

    final rugs = <_RugDraw>[];
    final shadows = <_ShadowDraw>[];
    _Ring? ring;
    for (final p in placed) {
      if (p.spec.flat) {
        rugs.add(
          _RugDraw(
            p.quad,
            Color.lerp(p.product.tone, NestColors.charcoal, 0.12)!,
          ),
        );
      } else {
        shadows.add(
          _ShadowDraw(
            p.foot.offset,
            p.spec.foot * p.scale * fit.f / p.foot.depth,
          ),
        );
      }
      if (p.id == selected) {
        final world = p.spec.flat
            ? p.spec.rug * 1.1 * p.scale
            : p.spec.foot * p.scale;
        ring = _Ring(p.foot.offset, world * fit.f / p.foot.depth * 1.15);
      }
    }

    final over = room.isOver;
    final near = !over && room.usedFraction >= 0.8;
    final dotColor = over
        ? NestColors.coral
        : near
        ? NestColors.butter
        : NestColors.cobalt;

    return SizedBox(
      key: _canvasKey,
      width: size.width,
      height: size.height,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(56),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Color(0xFFF3EBDA)),
            // The room. Dragging the background looks around.
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() {
                _selectedId = null;
                _liveScale = null;
              }),
              onPanStart: (_) {
                _spin.stop();
                setState(() => _touched = true);
              },
              onPanUpdate: (d) => setState(() {
                _yaw -= d.delta.dx * 0.012;
                _elev = (_elev + d.delta.dy * 0.006)
                    .clamp(0.22, 0.95)
                    .toDouble();
              }),
              child: CustomPaint(
                size: Size.infinite,
                painter: _RoomPainter(
                  cam: cam,
                  wall: wallColor,
                  floor: floor,
                  rugs: rugs,
                  shadows: shadows,
                  ring: ring,
                ),
              ),
            ),
            // Pieces
            for (final p in placed)
              p.spec.flat ? _rugHit(p, cam) : _sprite(p, cam),
            // Rotate buttons
            Positioned(
              left: 12,
              top: 12,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _RoundButton(
                    icon: Icons.rotate_left_rounded,
                    label: 'Rotate left',
                    onTap: () => _animateTo(_yaw - math.pi / 4, _elev),
                  ),
                  const SizedBox(width: 8),
                  _RoundButton(
                    icon: Icons.rotate_right_rounded,
                    label: 'Rotate right',
                    onTap: () => _animateTo(_yaw + math.pi / 4, _elev),
                  ),
                ],
              ),
            ),
            // Budget pill
            Positioned(
              right: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: NestColors.cream.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: NestMotion.base,
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                        begin: 0,
                        end: room.spent.toDouble(),
                      ),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) => Text(
                        formatPrice(value.round()),
                        style: NestText.bodyStrong.copyWith(fontSize: 13),
                      ),
                    ),
                    Text(
                      ' / ${formatPrice(room.budget)}',
                      style: NestText.body.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            // Bottom: hint, or a call to action when the room is empty
            Positioned(
              left: 0,
              right: 0,
              bottom: 14,
              child: Center(
                child: room.items.isEmpty
                    ? NestButton(
                        label: 'Furnish this room',
                        background: NestColors.cobalt,
                        icon: Icons.add_rounded,
                        onTap: () => showPiecePickerSheet(context, room.id),
                      )
                    : IgnorePointer(
                        child: AnimatedOpacity(
                          opacity: _touched ? 0 : 1,
                          duration: NestMotion.base,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: NestColors.cream.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              'Drag the room to look around',
                              style: NestText.body.copyWith(fontSize: 12),
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gesture(_Placed p, _Cam cam, Widget child) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedId = p.id);
      },
      onPanStart: (d) => _dragStart(p, cam, d.globalPosition),
      onPanUpdate: (d) => _dragUpdate(cam, d.globalPosition),
      onPanEnd: (_) => _dragEnd(),
      onPanCancel: _dragEnd,
      child: child,
    );
  }

  Widget _sprite(_Placed p, _Cam cam) {
    final head = cam.project(_V3(p.x, p.spec.height * p.scale, p.z));
    final heightPx = (p.foot.offset.dy - head.offset.dy)
        .abs()
        .clamp(12.0, 800.0)
        .toDouble();

    return Positioned(
      key: ValueKey<String>('sprite-${p.id}'),
      left: p.foot.offset.dx,
      top: p.foot.offset.dy,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -1.0),
        child: _gesture(
          p,
          cam,
          _Drop(
            child: _SpriteImage(
              product: p.product,
              height: heightPx,
              flip: p.layout.flip,
            ),
          ),
        ),
      ),
    );
  }

  Widget _rugHit(_Placed p, _Cam cam) {
    var minX = double.infinity;
    var maxX = -double.infinity;
    var minY = double.infinity;
    var maxY = -double.infinity;
    for (final o in p.quad) {
      minX = math.min(minX, o.dx);
      maxX = math.max(maxX, o.dx);
      minY = math.min(minY, o.dy);
      maxY = math.max(maxY, o.dy);
    }
    return Positioned(
      key: ValueKey<String>('sprite-${p.id}'),
      left: minX,
      top: minY,
      width: maxX - minX,
      height: maxY - minY,
      child: _gesture(p, cam, const SizedBox.expand()),
    );
  }
}

/// Pieces drop into the room the first time they appear.
class _Drop extends StatelessWidget {
  const _Drop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0).toDouble(),
        child: Transform.translate(
          offset: Offset(0, -(1 - t) * 60),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class _SpriteImage extends StatelessWidget {
  const _SpriteImage({
    required this.product,
    required this.height,
    required this.flip,
  });

  final Product product;
  final double height;
  final bool flip;

  @override
  Widget build(BuildContext context) {
    final Widget image;
    if (product.isCustom) {
      image = Image.file(
        File(product.imageAsset),
        height: height,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        cacheHeight: 700,
        gaplessPlayback: true,
        excludeFromSemantics: true,
        errorBuilder: (context, error, stack) =>
            _FramedPhoto(product: product, height: height),
      );
    } else {
      image = Image.asset(
        cutoutAssetFor(product),
        height: height,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        cacheHeight: 700,
        gaplessPlayback: true,
        excludeFromSemantics: true,
        errorBuilder: (context, error, stack) {
          debugPrint(
            'NEST cutout missing: ${cutoutAssetFor(product)} -> $error',
          );
          return _FramedPhoto(product: product, height: height);
        },
      );
    }

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.diagonal3Values(flip ? -1.0 : 1.0, 1.0, 1.0),
      child: image,
    );
  }
}

/// Used until the transparent PNG of a product exists.
class _FramedPhoto extends StatelessWidget {
  const _FramedPhoto({required this.product, required this.height});

  final Product product;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: height * 0.85,
      height: height,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: NestColors.cream, width: 3),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33252923),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: NestImage(
          asset: product.imageAsset,
          tone: product.tone,
          icon: product.category.icon,
          cacheWidth: 400,
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      scale: 0.88,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: NestColors.cream.withValues(alpha: 0.92),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 22, color: NestColors.charcoal),
      ),
    );
  }
}

// ------------------------------------------------------------------- panels

class _StylePanel extends StatelessWidget {
  const _StylePanel({super.key, required this.room});

  final Room room;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _swatchRow('WALL', [
            for (var i = 0; i < kRoomWalls.length; i++)
              _Swatch(
                label: 'Wall color ${i + 1}',
                selected: room.wall % kRoomWalls.length == i,
                onTap: () {
                  HapticFeedback.selectionClick();
                  roomBoardController.setWall(room.id, i);
                },
                child: ColoredBox(color: kRoomWalls[i]),
              ),
          ]),
          const SizedBox(height: 10),
          _swatchRow('FLOOR', [
            for (var i = 0; i < kRoomFloors.length; i++)
              _Swatch(
                label: '${kRoomFloors[i].name} floor',
                selected: room.floor % kRoomFloors.length == i,
                onTap: () {
                  HapticFeedback.selectionClick();
                  roomBoardController.setFloor(room.id, i);
                },
                child: kRoomFloors[i].wood
                    ? CustomPaint(
                        painter: _WoodSwatchPainter(kRoomFloors[i].color),
                      )
                    : ColoredBox(color: kRoomFloors[i].color),
              ),
          ]),
        ],
      ),
    );
  }

  Widget _swatchRow(String label, List<Widget> swatches) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(
              label,
              style: NestText.label.copyWith(color: NestColors.muted),
            ),
          ),
          for (final s in swatches)
            Padding(padding: const EdgeInsets.only(right: 8), child: s),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: selected ? '$label, selected' : label,
      scale: 0.88,
      child: AnimatedContainer(
        duration: NestMotion.base,
        width: 38,
        height: 38,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? NestColors.charcoal : Colors.transparent,
            width: 2,
          ),
        ),
        child: ClipOval(child: child),
      ),
    );
  }
}

class _WoodSwatchPainter extends CustomPainter {
  const _WoodSwatchPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (var i = 0; i < 4; i++) {
      paint.color = _darker(color, i.isEven ? 0.0 : 0.12);
      canvas.drawRect(
        Rect.fromLTWH(size.width * i / 4, 0, size.width / 4 + 1, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WoodSwatchPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _PiecePanel extends StatelessWidget {
  const _PiecePanel({
    super.key,
    required this.room,
    required this.productId,
    required this.scale,
    required this.onScale,
    required this.onScaleEnd,
  });

  final Room room;
  final String productId;
  final double scale;
  final ValueChanged<double> onScale;
  final ValueChanged<double> onScaleEnd;

  @override
  Widget build(BuildContext context) {
    final quantity = room.items[productId] ?? 0;
    if (quantity == 0) return const SizedBox.shrink();
    final product = Catalog.byId(productId);
    final layout = room.layoutOf(productId);
    final isRug = _specFor(productId).flat;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: NestText.display(24),
                    ),
                    Text(
                      '${formatPrice(product.price)} × $quantity',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: NestText.body,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              QuantityStepper(
                quantity: quantity,
                canIncrement: quantity < RoomBoardController.maxQuantity,
                onDecrement: () {
                  HapticFeedback.selectionClick();
                  roomBoardController.setQuantity(
                    room.id,
                    productId,
                    quantity - 1,
                  );
                },
                onIncrement: () {
                  HapticFeedback.selectionClick();
                  roomBoardController.addItem(room.id, productId);
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              if (!isRug)
                Pressable(
                  semanticLabel: 'Flip piece',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    roomBoardController.setLayout(
                      room.id,
                      productId,
                      layout.copyWith(flip: !layout.flip),
                    );
                  },
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: NestColors.creamDeep,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.flip_rounded,
                          size: 16,
                          color: NestColors.charcoal,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'FLIP',
                          style: NestText.label.copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
              if (!isRug) const SizedBox(width: 12),
              Text(
                'SIZE',
                style: NestText.label.copyWith(color: NestColors.muted),
              ),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: Slider(
                    value: scale,
                    min: 0.6,
                    max: 1.6,
                    onChanged: onScale,
                    onChangeEnd: onScaleEnd,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
