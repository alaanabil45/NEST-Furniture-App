import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/nest_theme.dart';
import '../data/catalog.dart';
import '../data/product.dart';
import '../state/cart_controller.dart';
import '../state/room_board_controller.dart';
import '../widgets/category_style.dart';
import '../widgets/empty_state.dart';
import '../widgets/nest_button.dart';
import '../widgets/nest_chip.dart';
import '../widgets/nest_image.dart';
import '../widgets/pressable.dart';
import '../widgets/quantity_stepper.dart';
import '../widgets/room_canvas.dart';
import '../widgets/room_sheets.dart';
import '../widgets/screen_title.dart';
import '../widgets/staggered_in.dart';
import 'product_detail_screen.dart';

class RoomBoardScreen extends StatefulWidget {
  const RoomBoardScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 450),
        reverseTransitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const RoomBoardScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.06),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  State<RoomBoardScreen> createState() => _RoomBoardScreenState();
}

class _RoomBoardScreenState extends State<RoomBoardScreen> {
  bool _canvas = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NestColors.cream,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: roomBoardController,
          builder: (context, _) {
            final room = roomBoardController.selected;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TopBar(
                  canvas: _canvas,
                  showToggle: room != null,
                  onMode: (value) {
                    HapticFeedback.selectionClick();
                    setState(() => _canvas = value);
                  },
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    switchInCurve: Curves.easeOutCubic,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(
                          begin: 0.96,
                          end: 1,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: room == null
                        ? const _NoRooms(key: ValueKey<String>('none'))
                        : _canvas
                        ? _CanvasMode(
                            key: const ValueKey<String>('canvas'),
                            room: room,
                          )
                        : _RoomView(
                            key: const ValueKey<String>('list'),
                            room: room,
                          ),
                  ),
                ),
                if (room != null && room.items.isNotEmpty)
                  _ActionBar(room: room),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.canvas,
    required this.showToggle,
    required this.onMode,
  });

  final bool canvas;
  final bool showToggle;
  final ValueChanged<bool> onMode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Pressable(
            onTap: () => Navigator.of(context).pop(),
            semanticLabel: 'Back',
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: NestColors.charcoal,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                size: 22,
                color: NestColors.cream,
              ),
            ),
          ),
          const Spacer(),
          if (showToggle)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: NestColors.creamDeep,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ModeButton(
                    label: 'List',
                    icon: Icons.format_list_bulleted_rounded,
                    selected: !canvas,
                    onTap: () => onMode(false),
                  ),
                  _ModeButton(
                    label: '3D',
                    icon: Icons.view_in_ar_outlined,
                    selected: canvas,
                    onTap: () => onMode(true),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                'ROOM BOARD',
                style: NestText.label.copyWith(color: NestColors.muted),
              ),
            ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? NestColors.cream : NestColors.charcoal;
    return Pressable(
      onTap: onTap,
      semanticLabel: selected ? '$label view, selected' : '$label view',
      child: AnimatedContainer(
        duration: NestMotion.base,
        curve: NestMotion.enter,
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? NestColors.charcoal : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 6),
            AnimatedDefaultTextStyle(
              duration: NestMotion.base,
              style: NestText.button.copyWith(fontSize: 13, color: fg),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoRooms extends StatelessWidget {
  const _NoRooms({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: ScreenTitle(
            lead: 'Room',
            emphasis: 'board',
            subtitle: 'Plan it. Budget it. Buy it.',
          ),
        ),
        Expanded(
          child: EmptyState(
            icon: Icons.add_home_outlined,
            accent: NestColors.coral,
            accent2: NestColors.butter,
            lead: 'No rooms',
            emphasis: 'yet.',
            message: 'Start a room, set a budget, and collect pieces until it feels right.',
            actionLabel: 'Create a room',
            onAction: () => showRoomFormSheet(context),
          ),
        ),
      ],
    );
  }
}

/// Canvas mode: tabs + the room sketch. Not scrollable on purpose, so
/// dragging pieces never fights with page scrolling.
class _CanvasMode extends StatelessWidget {
  const _CanvasMode({super.key, required this.room});

  final Room room;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: _RoomTabs(selectedId: room.id),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: RoomCanvasView(room: room),
          ),
        ),
      ],
    );
  }
}

class _RoomView extends StatelessWidget {
  const _RoomView({super.key, required this.room});

  final Room room;

  @override
  Widget build(BuildContext context) {
    final entries = room.items.entries.toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      children: [
        const StaggeredIn(
          child: ScreenTitle(
            lead: 'Room',
            emphasis: 'board',
            subtitle: 'Plan it. Budget it. Buy it.',
          ),
        ),
        const SizedBox(height: 18),
        StaggeredIn(index: 1, child: _RoomTabs(selectedId: room.id)),
        const SizedBox(height: 18),
        StaggeredIn(index: 2, child: _BudgetCard(room: room)),
        const SizedBox(height: 24),
        if (entries.isEmpty)
          StaggeredIn(
            key: ValueKey<String>('empty-${room.id}'),
            index: 3,
            child: _EmptyRoom(room: room),
          )
        else ...[
          for (var i = 0; i < entries.length; i++)
            StaggeredIn(
              key: ValueKey<String>('${room.id}-${entries[i].key}'),
              index: i + 3,
              child: _RoomItemTile(
                roomId: room.id,
                product: Catalog.byId(entries[i].key),
                quantity: entries[i].value,
              ),
            ),
          _AddPieceTile(roomId: room.id),
        ],
        const SizedBox(height: 18),
        Center(
          child: Pressable(
            onTap: () => _confirmDelete(context, room),
            semanticLabel: 'Delete room',
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: NestColors.muted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'DELETE ROOM',
                    style: NestText.label.copyWith(color: NestColors.muted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

Future<void> _confirmDelete(BuildContext context, Room room) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: NestColors.cream,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Text('Delete ${room.name}?', style: NestText.display(28)),
      content: Text(
        'This removes the room and its list of pieces.',
        style: NestText.body,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text('Keep', style: NestText.button),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(
            'Delete',
            style: NestText.button.copyWith(color: NestColors.cobalt),
          ),
        ),
      ],
    ),
  );
  if (ok == true) roomBoardController.deleteRoom(room.id);
}

class _RoomTabs extends StatelessWidget {
  const _RoomTabs({required this.selectedId});

  final String selectedId;

  @override
  Widget build(BuildContext context) {
    final rooms = roomBoardController.rooms;
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: rooms.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          if (i == rooms.length) {
            return NestChip(
              label: '+ New room',
              selected: false,
              onTap: () => showRoomFormSheet(context),
            );
          }
          final r = rooms[i];
          return NestChip(
            label: r.name,
            selected: r.id == selectedId,
            onTap: () {
              HapticFeedback.selectionClick();
              roomBoardController.select(r.id);
            },
          );
        },
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.room});

  final Room room;

  @override
  Widget build(BuildContext context) {
    final fraction = room.usedFraction;
    final over = room.isOver;
    final near = !over && fraction >= 0.8;
    final bg = over
        ? NestColors.coral
        : near
        ? NestColors.butter
        : NestColors.cobalt;
    final fg = (over || near) ? NestColors.charcoal : NestColors.cream;
    final status = over
        ? 'Over by ${formatPrice(-room.remaining)}'
        : '${formatPrice(room.remaining)} left';

    return AnimatedContainer(
      duration: NestMotion.base,
      curve: NestMotion.enter,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 22),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(56),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  'BUDGET',
                  style: NestText.label.copyWith(color: fg),
                ),
              ),
              const Spacer(),
              Pressable(
                onTap: () => showRoomFormSheet(context, editing: room),
                semanticLabel: 'Edit room and budget',
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: fg.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_outlined, size: 14, color: fg),
                      const SizedBox(width: 6),
                      Text(
                        'EDIT',
                        style: NestText.label.copyWith(fontSize: 10, color: fg),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: room.spent.toDouble()),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => Text(
                  formatPrice(value.round()),
                  style: NestText.display(54).copyWith(color: fg),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'of ${formatPrice(room.budget)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: NestText.body.copyWith(fontSize: 15, color: fg),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                Container(height: 12, color: fg.withValues(alpha: 0.2)),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(
                    begin: 0,
                    end: fraction.clamp(0.0, 1.0).toDouble(),
                  ),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: value,
                    child: Container(height: 12, color: fg),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: NestMotion.fast,
                  child: Align(
                    key: ValueKey<String>(status),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      status,
                      style: NestText.button.copyWith(color: fg),
                    ),
                  ),
                ),
              ),
              Text(
                '${room.itemCount} ${room.itemCount == 1 ? 'piece' : 'pieces'}',
                style: NestText.body.copyWith(color: fg),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyRoom extends StatelessWidget {
  const _EmptyRoom({required this.room});

  final Room room;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: NestColors.creamDeep,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(80),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.chair_outlined,
            size: 34,
            color: NestColors.charcoal,
          ),
          const SizedBox(height: 12),
          Text('This room is empty', style: NestText.display(30)),
          const SizedBox(height: 8),
          Text(
            'Add a few pieces and watch the total climb toward your budget.',
            style: NestText.body,
          ),
          const SizedBox(height: 20),
          NestButton(
            label: 'Add pieces',
            background: NestColors.cobalt,
            icon: Icons.add_rounded,
            onTap: () => showPiecePickerSheet(context, room.id),
          ),
        ],
      ),
    );
  }
}

class _AddPieceTile extends StatelessWidget {
  const _AddPieceTile({required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () => showPiecePickerSheet(context, roomId),
      semanticLabel: 'Add another piece',
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: NestColors.line, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_rounded, size: 22, color: NestColors.charcoal),
            const SizedBox(width: 8),
            Text('Add another piece', style: NestText.button),
          ],
        ),
      ),
    );
  }
}

class _RoomItemTile extends StatefulWidget {
  const _RoomItemTile({
    required this.roomId,
    required this.product,
    required this.quantity,
  });

  final String roomId;
  final Product product;
  final int quantity;

  @override
  State<_RoomItemTile> createState() => _RoomItemTileState();
}

class _RoomItemTileState extends State<_RoomItemTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _exit = AnimationController(
    vsync: this,
    duration: NestMotion.base,
    value: 1,
  );
  late final Animation<double> _size = CurvedAnimation(
    parent: _exit,
    curve: Curves.easeInOut,
  );
  bool _removing = false;

  @override
  void dispose() {
    _exit.dispose();
    super.dispose();
  }

  Future<void> _remove() async {
    if (_removing) return;
    _removing = true;
    HapticFeedback.mediumImpact();
    await _exit.reverse();
    roomBoardController.setQuantity(widget.roomId, widget.product.id, 0);
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final quantity = widget.quantity;
    final heroTag = 'room-${product.id}';

    return SizeTransition(
      sizeFactor: _size,
      alignment: Alignment.topLeft,
      child: FadeTransition(
        opacity: _exit,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Pressable(
                scale: 0.97,
                onTap: () {
                  if (product.isCustom) return;
                  ProductDetailScreen.open(context, product, heroTag);
                },
                child: Hero(
                  tag: heroTag,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(36),
                      bottomRight: Radius.circular(36),
                      topRight: Radius.circular(10),
                      bottomLeft: Radius.circular(10),
                    ),
                    child: SizedBox(
                      width: 92,
                      height: 112,
                      child: NestImage(
                        asset: product.imageAsset,
                        tone: product.tone,
                        icon: product.category.icon,
                        cacheWidth: 300,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: NestText.display(23),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${product.category.label.toUpperCase()} · ${product.priceLabel}',
                      style: NestText.label.copyWith(
                        fontSize: 10,
                        color: NestColors.muted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        QuantityStepper(
                          quantity: quantity,
                          canIncrement:
                              quantity < RoomBoardController.maxQuantity,
                          onDecrement: () {
                            if (quantity <= 1) {
                              _remove();
                            } else {
                              HapticFeedback.selectionClick();
                              roomBoardController.setQuantity(
                                widget.roomId,
                                product.id,
                                quantity - 1,
                              );
                            }
                          },
                          onIncrement: () {
                            HapticFeedback.selectionClick();
                            roomBoardController.addItem(
                              widget.roomId,
                              product.id,
                            );
                          },
                        ),
                        Flexible(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Text(
                                formatPrice(product.price * quantity),
                                style: NestText.bodyStrong.copyWith(
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.room});

  final Room room;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(
        color: NestColors.cream,
        border: Border(top: BorderSide(color: NestColors.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: NestButton(
              label: 'Add all to cart · ${formatPrice(room.spent)}',
              background: NestColors.cobalt,
              icon: Icons.shopping_bag_outlined,
              onTap: () {
                HapticFeedback.mediumImpact();
                for (final entry in room.items.entries) {
                  // Your own furniture can't be bought, so skip it.
                  if (entry.key.startsWith('custom-')) continue;
                  cartController.setQuantity(
                    entry.key,
                    cartController.quantityOf(entry.key) + entry.value,
                  );
                }
                showNestToast(
                  context,
                  'Added ${room.itemCount} ${room.itemCount == 1 ? 'piece' : 'pieces'} to your cart',
                  bottom: 84,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
