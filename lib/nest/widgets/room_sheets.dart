import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/nest_theme.dart';
import '../data/catalog.dart';
import '../data/product.dart';
import '../state/room_board_controller.dart';
import 'category_style.dart';
import 'nest_button.dart';
import 'nest_chip.dart';
import 'nest_image.dart';
import 'pressable.dart';
import '../screens/add_piece_screen.dart';
import '../state/custom_pieces_controller.dart';

/// Small floating message at the bottom of the screen.
void showNestToast(BuildContext context, String message, {double bottom = 16}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: NestColors.charcoal,
      margin: EdgeInsets.fromLTRB(16, 0, 16, bottom),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      duration: const Duration(milliseconds: 2200),
      content: Text(
        message,
        style: NestText.button.copyWith(color: NestColors.cream),
      ),
    ),
  );
}

// ------------------------------------------------------- create / edit room

/// Opens the room form. Returns the created or updated room (or null).
Future<Room?> showRoomFormSheet(BuildContext context, {Room? editing}) {
  return showModalBottomSheet<Room>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _RoomFormSheet(editing: editing),
  );
}

InputDecoration _fieldDecoration(String hint, {String? prefix}) {
  OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(26),
    borderSide: BorderSide(color: color, width: width),
  );

  return InputDecoration(
    hintText: hint,
    hintStyle: NestText.body,
    prefixText: prefix,
    prefixStyle: NestText.bodyStrong,
    filled: true,
    fillColor: NestColors.creamDeep,
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    border: border(Colors.transparent, 0),
    enabledBorder: border(Colors.transparent, 0),
    focusedBorder: border(NestColors.cobalt, 2),
  );
}

class _RoomFormSheet extends StatefulWidget {
  const _RoomFormSheet({this.editing});

  final Room? editing;

  @override
  State<_RoomFormSheet> createState() => _RoomFormSheetState();
}

class _RoomFormSheetState extends State<_RoomFormSheet> {
  static const List<String> _nameIdeas = [
    'Living room',
    'Bedroom',
    'Dining room',
    'Home office',
  ];
  static const List<int> _budgetIdeas = [1000, 2500, 5000];

  late final TextEditingController _name = TextEditingController(
    text: widget.editing?.name ?? '',
  );
  late final TextEditingController _budget = TextEditingController(
    text: widget.editing == null ? '' : '${widget.editing!.budget}',
  );

  int? get _budgetValue => int.tryParse(_budget.text);

  bool get _valid => _name.text.trim().isNotEmpty && (_budgetValue ?? 0) > 0;

  @override
  void dispose() {
    _name.dispose();
    _budget.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    final budget = _budgetValue!;
    final editing = widget.editing;
    final room = editing == null
        ? roomBoardController.addRoom(name, budget)
        : roomBoardController.updateRoom(
            editing.id,
            name: name,
            budget: budget,
          );
    Navigator.of(context).pop(room);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.editing != null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              editing ? 'Edit room' : 'New room',
              style: NestText.display(34),
            ),
            const SizedBox(height: 20),
            Text(
              'ROOM NAME',
              style: NestText.label.copyWith(color: NestColors.muted),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              inputFormatters: [LengthLimitingTextInputFormatter(24)],
              onChanged: (_) => setState(() {}),
              decoration: _fieldDecoration('e.g. Living room'),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final idea in _nameIdeas)
                  NestChip(
                    label: idea,
                    selected: _name.text.trim() == idea,
                    onTap: () => setState(() => _name.text = idea),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              'BUDGET',
              style: NestText.label.copyWith(color: NestColors.muted),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _budget,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(7),
              ],
              onChanged: (_) => setState(() {}),
              decoration: _fieldDecoration('0', prefix: '\$ '),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final idea in _budgetIdeas)
                  NestChip(
                    label: formatPrice(idea),
                    selected: _budgetValue == idea,
                    onTap: () => setState(() => _budget.text = '$idea'),
                  ),
              ],
            ),
            const SizedBox(height: 26),
            IgnorePointer(
              ignoring: !_valid,
              child: AnimatedOpacity(
                opacity: _valid ? 1 : 0.4,
                duration: NestMotion.base,
                child: Row(
                  children: [
                    Expanded(
                      child: NestButton(
                        label: editing ? 'Save changes' : 'Create room',
                        background: NestColors.cobalt,
                        onTap: _submit,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------- "add this product to a room"

/// Lets the user choose which room a product goes into
/// (or creates the first room if there are none).
Future<void> showRoomPickerSheet(
  BuildContext context,
  Product product, {
  double toastBottom = 16,
}) async {
  if (roomBoardController.rooms.isEmpty) {
    final room = await showRoomFormSheet(context);
    if (room != null && context.mounted) {
      roomBoardController.addItem(room.id, product.id);
      showNestToast(context, 'Added to ${room.name}', bottom: toastBottom);
    }
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _RoomPicker(product: product, toastBottom: toastBottom),
  );
}

class _RoomPicker extends StatelessWidget {
  const _RoomPicker({required this.product, required this.toastBottom});

  final Product product;
  final double toastBottom;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: roomBoardController,
      builder: (context, _) {
        final rooms = roomBoardController.rooms;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add to a room', style: NestText.display(34)),
              const SizedBox(height: 6),
              Text(
                '${product.name} · ${product.priceLabel}',
                style: NestText.body,
              ),
              const SizedBox(height: 20),
              for (final room in rooms)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _RoomPickRow(
                    room: room,
                    product: product,
                    toastBottom: toastBottom,
                  ),
                ),
              const SizedBox(height: 4),
              NestButton(
                label: 'New room',
                background: NestColors.creamDeep,
                foreground: NestColors.charcoal,
                icon: Icons.add_rounded,
                onTap: () async {
                  final room = await showRoomFormSheet(context);
                  if (room != null && context.mounted) {
                    roomBoardController.addItem(room.id, product.id);
                    showNestToast(
                      context,
                      'Added to ${room.name}',
                      bottom: toastBottom,
                    );
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RoomPickRow extends StatelessWidget {
  const _RoomPickRow({
    required this.room,
    required this.product,
    required this.toastBottom,
  });

  final Room room;
  final Product product;
  final double toastBottom;

  @override
  Widget build(BuildContext context) {
    final inRoom = roomBoardController.quantityIn(room.id, product.id);
    final status = room.isOver
        ? 'Over by ${formatPrice(-room.remaining)}'
        : '${formatPrice(room.remaining)} left of ${formatPrice(room.budget)}';

    return Pressable(
      semanticLabel: 'Add to ${room.name}',
      onTap: () {
        HapticFeedback.selectionClick();
        roomBoardController.addItem(room.id, product.id);
        showNestToast(context, 'Added to ${room.name}', bottom: toastBottom);
        Navigator.of(context).pop();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: NestColors.creamDeep,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(room.name, style: NestText.display(24)),
                  const SizedBox(height: 2),
                  Text(status, style: NestText.body),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: inRoom > 0 ? NestColors.cobalt : NestColors.butter,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: inRoom > 0
                    ? Text(
                        '×$inRoom',
                        style: NestText.button.copyWith(
                          color: NestColors.cream,
                        ),
                      )
                    : const Icon(
                        Icons.add_rounded,
                        size: 22,
                        color: NestColors.charcoal,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------- "add pieces" to a given room

Future<void> showPiecePickerSheet(BuildContext context, String roomId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _PiecePicker(roomId: roomId),
  );
}

class _PiecePicker extends StatelessWidget {
  const _PiecePicker({required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.78,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text('Add pieces', style: NestText.display(34)),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Tap + to add. Tap again for more.',
              style: NestText.body,
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Pressable(
              semanticLabel: 'Add your own piece',
              onTap: () => AddPieceScreen.open(context, roomId: roomId),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: NestColors.creamDeep,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: NestColors.coral,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_awesome_outlined,
                        size: 22,
                        color: NestColors.charcoal,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add your own piece',
                            style: NestText.bodyStrong.copyWith(fontSize: 15),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Photo in, background out',
                            style: NestText.body,
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 20,
                      color: NestColors.charcoal,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListenableBuilder(
              listenable: Listenable.merge([roomBoardController, customPieces]),
              builder: (context, _) {
                final items = [...customPieces.products, ...Catalog.all];
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: items.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 14),
                  itemBuilder: (context, i) {
                    final p = items[i];
                    final qty = roomBoardController.quantityIn(roomId, p.id);
                    return Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: SizedBox(
                            width: 64,
                            height: 72,
                            child: NestImage(
                              asset: p.imageAsset,
                              tone: p.tone,
                              icon: p.category.icon,
                              cacheWidth: 200,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: NestText.display(21),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                p.isCustom
                                    ? 'YOURS · ${p.priceLabel}'
                                    : '${p.category.label.toUpperCase()} · ${p.priceLabel}',
                                style: NestText.label.copyWith(
                                  fontSize: 10,
                                  color: p.isCustom
                                      ? NestColors.cobalt
                                      : NestColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Pressable(
                          semanticLabel: 'Add ${p.name}',
                          scale: 0.88,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            roomBoardController.addItem(roomId, p.id);
                          },
                          child: AnimatedContainer(
                            duration: NestMotion.base,
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: qty > 0
                                  ? NestColors.cobalt
                                  : NestColors.butter,
                            ),
                            child: Center(
                              child: qty > 0
                                  ? Text(
                                      '$qty',
                                      style: NestText.button.copyWith(
                                        color: NestColors.cream,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.add_rounded,
                                      size: 22,
                                      color: NestColors.charcoal,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
            child: Row(
              children: [
                Expanded(
                  child: NestButton(
                    label: 'Done',
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
