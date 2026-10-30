import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../core/nest_theme.dart';
import '../services/background_remover.dart';
import '../state/custom_pieces_controller.dart';
import '../state/room_board_controller.dart';
import '../widgets/motion_widgets.dart';
import '../widgets/nest_button.dart';
import '../widgets/nest_chip.dart';
import '../widgets/pressable.dart';
import '../widgets/staggered_in.dart';

enum _Phase { pick, working, review }

/// Photo in, background out: the user adds a piece of their own.
class AddPieceScreen extends StatefulWidget {
  const AddPieceScreen({super.key, this.roomId});

  /// If given, the new piece is added to this room when saved.
  final String? roomId;

  static Future<CustomPiece?> open(BuildContext context, {String? roomId}) {
    return Navigator.of(context).push<CustomPiece>(
      PageRouteBuilder<CustomPiece>(
        transitionDuration: const Duration(milliseconds: 450),
        reverseTransitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (context, animation, secondaryAnimation) =>
            AddPieceScreen(roomId: roomId),
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
  State<AddPieceScreen> createState() => _AddPieceScreenState();
}

class _AddPieceScreenState extends State<AddPieceScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _name = TextEditingController(text: 'My piece');
  final TextEditingController _price = TextEditingController();
  late final AnimationController _scan = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  );

  _Phase _phase = _Phase.pick;
  String? _photoPath;
  String _status = '';
  String? _error;
  CutoutResult? _result;
  bool _showCutout = true;
  double _height = 0.4;
  bool _saving = false;

  @override
  void dispose() {
    _scan.dispose();
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _choose(ImageSource source) async {
    XFile? picked;
    try {
      picked = await _picker.pickImage(
        source: source,
        maxWidth: 2000,
        imageQuality: 90,
      );
    } catch (error) {
      debugPrint('NEST image picker error: $error');
      if (mounted) {
        setState(() => _error = 'Could not open the photo picker.');
      }
      return;
    }
    if (picked == null || !mounted) return;
    final path = picked.path;

    setState(() {
      _photoPath = path;
      _phase = _Phase.working;
      _error = null;
      _status = 'Preparing your photo…';
      _result = null;
    });
    _scan.repeat(reverse: true);

    try {
      final result = await BackgroundRemover.run(
        path,
        onStatus: (s) {
          if (mounted) setState(() => _status = s);
        },
      );
      if (!mounted) return;
      _scan.stop();
      HapticFeedback.mediumImpact();
      setState(() {
        _result = result;
        _showCutout = true;
        _phase = _Phase.review;
      });
    } on CutoutException catch (e) {
      if (!mounted) return;
      _scan.stop();
      setState(() {
        _error = e.message;
        _phase = _Phase.pick;
      });
    } catch (error) {
      debugPrint('NEST cutout error: $error');
      if (!mounted) return;
      _scan.stop();
      setState(() {
        _error = 'Something went wrong while removing the background. Try another photo.';
        _phase = _Phase.pick;
      });
    }
  }

  Future<void> _save() async {
    final result = _result;
    if (result == null || _saving) return;
    setState(() => _saving = true);

    final typed = _name.text.trim();
    final piece = await customPieces.add(
      name: typed.isEmpty ? 'My piece' : typed,
      price: int.tryParse(_price.text.trim()) ?? 0,
      height: _height,
      aspect: result.width / result.height,
      png: result.png,
    );
    final roomId = widget.roomId;
    if (roomId != null) roomBoardController.addItem(roomId, piece.id);

    HapticFeedback.heavyImpact();
    if (!mounted) return;
    Navigator.of(context).pop(piece);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NestColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            _top(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 420),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(
                      begin: 0.97,
                      end: 1,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(
                  key: ValueKey<_Phase>(_phase),
                  child: switch (_phase) {
                    _Phase.pick => _pick(),
                    _Phase.working => _working(),
                    _Phase.review => _review(),
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _top() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 20, 0),
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
          Text(
            'ADD YOUR OWN PIECE',
            style: NestText.label.copyWith(color: NestColors.muted),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------- pick

  Widget _pick() {
    const colors = [NestColors.butter, NestColors.coral, NestColors.softGreen];

    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
      children: [
        Center(
          child: SizedBox(
            width: 230,
            height: 150,
            child: Stack(
              children: [
                for (var i = 0; i < colors.length; i++)
                  Positioned(
                    left: i * 62.0,
                    top: i == 1 ? 24 : 0,
                    child: Entrance(
                      kind: EntranceKind.pop,
                      delay: Duration(milliseconds: 100 + i * 140),
                      duration: const Duration(milliseconds: 1000),
                      child: Container(
                        width: 106,
                        height: 126,
                        decoration: BoxDecoration(
                          color: colors[i],
                          borderRadius: i == 0
                              ? const BorderRadius.vertical(
                                  top: Radius.circular(53),
                                  bottom: Radius.circular(16),
                                )
                              : i == 1
                              ? const BorderRadius.all(Radius.circular(53))
                              : const BorderRadius.only(
                                  topLeft: Radius.circular(46),
                                  bottomRight: Radius.circular(46),
                                  topRight: Radius.circular(12),
                                  bottomLeft: Radius.circular(12),
                                ),
                        ),
                        child: i == 1
                            ? const Icon(
                                Icons.auto_awesome_outlined,
                                size: 36,
                                color: NestColors.charcoal,
                              )
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        StaggeredIn(
          index: 2,
          child: Column(
            children: [
              Text.rich(
                const TextSpan(
                  text: 'Bring your own\n',
                  children: [
                    TextSpan(
                      text: 'furniture.',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: NestColors.cobalt,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                style: NestText.display(46),
              ),
              const SizedBox(height: 12),
              Text(
                'Take a photo of a piece you own or love. We remove the background and place it in your room.',
                textAlign: TextAlign.center,
                style: NestText.body,
              ),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: NestColors.coral.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: NestColors.charcoal,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _error!,
                    style: NestText.body.copyWith(color: NestColors.charcoal),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        StaggeredIn(
          index: 3,
          child: NestButton(
            label: 'Take a photo',
            background: NestColors.cobalt,
            icon: Icons.photo_camera_outlined,
            onTap: () => _choose(ImageSource.camera),
          ),
        ),
        const SizedBox(height: 12),
        StaggeredIn(
          index: 4,
          child: NestButton(
            label: 'Choose from gallery',
            background: NestColors.creamDeep,
            foreground: NestColors.charcoal,
            icon: Icons.photo_library_outlined,
            onTap: () => _choose(ImageSource.gallery),
          ),
        ),
        const SizedBox(height: 22),
        StaggeredIn(
          index: 5,
          child: Text(
            'TIP · One piece, plain background, good light, the whole piece in the frame.',
            textAlign: TextAlign.center,
            style: NestText.label.copyWith(
              fontSize: 10,
              height: 1.6,
              color: NestColors.muted,
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------- working

  Widget _working() {
    final reduced = MediaQuery.disableAnimationsOf(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(110),
                topRight: Radius.circular(24),
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(110),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const ColoredBox(color: NestColors.creamDeep),
                  if (_photoPath != null)
                    Image.file(
                      File(_photoPath!),
                      fit: BoxFit.cover,
                      cacheWidth: 900,
                      errorBuilder: (context, error, stack) =>
                          const SizedBox.shrink(),
                    ),
                  ColoredBox(color: NestColors.cobalt.withValues(alpha: 0.18)),
                  if (reduced)
                    const Center(
                      child: CircularProgressIndicator(
                        color: NestColors.cream,
                        strokeWidth: 3,
                      ),
                    )
                  else
                    AnimatedBuilder(
                      animation: _scan,
                      builder: (context, _) => Align(
                        alignment: Alignment(
                          0,
                          -1 + 2 * Curves.easeInOut.transform(_scan.value),
                        ),
                        child: Container(
                          height: 5,
                          decoration: BoxDecoration(
                            color: NestColors.butter,
                            boxShadow: [
                              BoxShadow(
                                color: NestColors.butter.withValues(alpha: 0.8),
                                blurRadius: 18,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'WORKING ON IT',
            style: NestText.label.copyWith(color: NestColors.cobalt),
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: NestMotion.fast,
            child: Text(
              _status,
              key: ValueKey<String>(_status),
              textAlign: TextAlign.center,
              style: NestText.display(28),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------- review

  InputDecoration _decoration(String hint, {String? prefix}) {
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

  Widget _review() {
    final result = _result!;
    final hasRoom = widget.roomId != null;

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      children: [
        StaggeredIn(
          offset: 20,
          child: Container(
            height: 340,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
              color: Color(0xFFF7E3AE),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(110),
                topRight: Radius.circular(24),
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(110),
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimatedSwitcher(
                  duration: NestMotion.base,
                  child: _showCutout
                      ? Padding(
                          key: const ValueKey<String>('cutout'),
                          padding: const EdgeInsets.fromLTRB(36, 40, 36, 56),
                          child: Image.memory(
                            result.png,
                            fit: BoxFit.contain,
                            gaplessPlayback: true,
                          ),
                        )
                      : Image.memory(
                          result.original,
                          key: const ValueKey<String>('original'),
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                        ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 14,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: NestColors.cream.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          NestChip(
                            label: 'Cutout',
                            selected: _showCutout,
                            onTap: () => setState(() => _showCutout = true),
                          ),
                          const SizedBox(width: 6),
                          NestChip(
                            label: 'Original',
                            selected: !_showCutout,
                            onTap: () => setState(() => _showCutout = false),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        StaggeredIn(
          index: 1,
          offset: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NAME',
                style: NestText.label.copyWith(color: NestColors.muted),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                inputFormatters: [LengthLimitingTextInputFormatter(28)],
                decoration: _decoration('e.g. Grandma’s armchair'),
              ),
              const SizedBox(height: 18),
              Text(
                'PRICE (OPTIONAL)',
                style: NestText.label.copyWith(color: NestColors.muted),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _price,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: _decoration('0', prefix: '\$ '),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Text(
                    'SIZE IN THE ROOM',
                    style: NestText.label.copyWith(color: NestColors.muted),
                  ),
                  const Spacer(),
                  Text(
                    _height < 0.3
                        ? 'Small'
                        : _height < 0.55
                        ? 'Medium'
                        : _height < 0.75
                        ? 'Large'
                        : 'Tall',
                    style: NestText.bodyStrong,
                  ),
                ],
              ),
              Slider(
                value: _height,
                min: 0.15,
                max: 0.9,
                onChanged: (v) => setState(() => _height = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        StaggeredIn(
          index: 2,
          offset: 20,
          child: IgnorePointer(
            ignoring: _saving,
            child: AnimatedOpacity(
              opacity: _saving ? 0.5 : 1,
              duration: NestMotion.base,
              child: NestButton(
                label: hasRoom ? 'Add to my room' : 'Save piece',
                background: NestColors.cobalt,
                icon: Icons.check_rounded,
                onTap: _save,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Pressable(
            onTap: () => setState(() {
              _phase = _Phase.pick;
              _result = null;
            }),
            semanticLabel: 'Try another photo',
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                'TRY ANOTHER PHOTO',
                style: NestText.label.copyWith(color: NestColors.muted),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
