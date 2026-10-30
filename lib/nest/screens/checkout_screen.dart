import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/nest_theme.dart';
import '../data/product.dart';
import '../state/cart_controller.dart';
import '../widgets/category_style.dart';
import '../widgets/confetti_burst.dart';
import '../widgets/nest_button.dart';
import '../widgets/nest_image.dart';
import '../widgets/pressable.dart';
import '../widgets/staggered_in.dart';

/// Standard delivery is free from this subtotal (whole dollars).
const int kFreeShippingFrom = 500;

class _Ship {
  const _Ship(this.id, this.name, this.note, this.fee, this.days);

  final String id;
  final String name;
  final String note;
  final int fee;
  final int days;
}

class _Order {
  const _Order({
    required this.number,
    required this.name,
    required this.lines,
    required this.subtotal,
    required this.fee,
    required this.pickup,
    required this.arrival,
  });

  final String number;
  final String name;
  final List<CartLine> lines;
  final int subtotal;
  final int fee;
  final bool pickup;
  final String arrival;

  int get total => subtotal + fee;
  int get pieces => lines.fold(0, (sum, l) => sum + l.quantity);
}

String _dateLabel(DateTime d) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${days[d.weekday - 1]} ${d.day} ${months[d.month - 1]}';
}

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key, required this.onFinished});

  /// Called after the success screen, once the checkout is closed.
  final VoidCallback onFinished;

  static Future<void> open(
    BuildContext context, {
    required VoidCallback onFinished,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 450),
        reverseTransitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (context, animation, secondaryAnimation) =>
            CheckoutScreen(onFinished: onFinished),
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
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  static const List<_Ship> _options = [
    _Ship('standard', 'Standard', '4–6 days', 29, 5),
    _Ship('express', 'Express', '1–2 days', 49, 2),
    _Ship('pickup', 'Store pickup', 'In 2 days', 0, 2),
  ];

  static const List<BorderRadius> _radii = [
    BorderRadius.only(
      topLeft: Radius.circular(44),
      topRight: Radius.circular(14),
      bottomLeft: Radius.circular(14),
      bottomRight: Radius.circular(14),
    ),
    BorderRadius.all(Radius.circular(24)),
    BorderRadius.only(
      topLeft: Radius.circular(14),
      topRight: Radius.circular(14),
      bottomLeft: Radius.circular(14),
      bottomRight: Radius.circular(44),
    ),
  ];

  static const List<List<String>> _titles = [
    ['Where should we', 'deliver?'],
    ['How soon do you', 'need it?'],
    ['Everything', 'look right?'],
  ];

  final TextEditingController _name = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _city = TextEditingController();
  final TextEditingController _address = TextEditingController();

  int _step = 0;
  String _shipId = 'standard';
  bool _placing = false;
  _Order? _order;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _city.dispose();
    _address.dispose();
    super.dispose();
  }

  int get _subtotal => cartController.subtotal;

  _Ship get _ship => _options.firstWhere((o) => o.id == _shipId);

  int _fee(_Ship o) =>
      (o.id == 'standard' && _subtotal >= kFreeShippingFrom) ? 0 : o.fee;

  bool get _detailsValid =>
      _name.text.trim().length >= 2 &&
      _phone.text.replaceAll(RegExp(r'[^0-9]'), '').length >= 7 &&
      _city.text.trim().length >= 2 &&
      _address.text.trim().length >= 5;

  void _back() {
    if (_step == 0) {
      Navigator.of(context).pop();
    } else {
      setState(() => _step -= 1);
    }
  }

  void _next() {
    HapticFeedback.selectionClick();
    FocusScope.of(context).unfocus();
    setState(() => _step += 1);
  }

  Future<void> _place() async {
    if (_placing) return;
    HapticFeedback.mediumImpact();
    setState(() => _placing = true);
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    final lines = cartController.lines;
    final ship = _ship;
    final order = _Order(
      number: 'NEST-${10000 + DateTime.now().millisecondsSinceEpoch % 90000}',
      name: _name.text.trim(),
      lines: lines,
      subtotal: _subtotal,
      fee: _fee(ship),
      pickup: ship.id == 'pickup',
      arrival: _dateLabel(DateTime.now().add(Duration(days: ship.days))),
    );

    for (final line in lines) {
      cartController.remove(line.product.id);
    }
    HapticFeedback.heavyImpact();
    setState(() {
      _order = order;
      _placing = false;
    });
  }

  void _finish() {
    Navigator.of(context).popUntil((route) => route.isFirst);
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    final done = _order != null;

    return PopScope(
      canPop: _step == 0 || done,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) setState(() => _step -= 1);
      },
      child: Scaffold(
        backgroundColor: NestColors.cream,
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 450),
            child: done
                ? _Success(
                    key: const ValueKey<String>('success'),
                    order: _order!,
                    onFinish: _finish,
                  )
                : _flow(),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- flow

  Widget _flow() {
    return Column(
      key: const ValueKey<String>('flow'),
      children: [
        _header(),
        Expanded(
          child: AnimatedSwitcher(
            duration: NestMotion.base,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: KeyedSubtree(
              key: ValueKey<int>(_step),
              child: switch (_step) {
                0 => _detailsStep(),
                1 => _shippingStep(),
                _ => _reviewStep(),
              },
            ),
          ),
        ),
        _bottomBar(),
      ],
    );
  }

  Widget _header() {
    final title = _titles[_step];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Pressable(
                onTap: _back,
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
                'STEP ${_step + 1} OF 3',
                style: NestText.label.copyWith(color: NestColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Row(
              children: [
                for (var i = 0; i < 3; i++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: i < 2 ? 6 : 0),
                      child: AnimatedContainer(
                        duration: NestMotion.base,
                        curve: NestMotion.enter,
                        height: 6,
                        decoration: BoxDecoration(
                          color: i <= _step
                              ? NestColors.cobalt
                              : NestColors.line,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: AnimatedSwitcher(
              duration: NestMotion.base,
              child: Align(
                key: ValueKey<int>(_step),
                alignment: Alignment.centerLeft,
                child: Text.rich(
                  TextSpan(
                    text: '${title[0]} ',
                    children: [
                      TextSpan(
                        text: title[1],
                        style: const TextStyle(
                          fontStyle: FontStyle.italic,
                          color: NestColors.cobalt,
                        ),
                      ),
                    ],
                  ),
                  style: NestText.display(38),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar() {
    final Widget action;
    if (_step == 2) {
      final total = _subtotal + _fee(_ship);
      action = _placing
          ? const SizedBox(
              height: 52,
              child: Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: NestColors.cobalt,
                  ),
                ),
              ),
            )
          : NestButton(
              label: 'Place order · ${formatPrice(total)}',
              background: NestColors.cobalt,
              icon: Icons.check_rounded,
              onTap: _place,
            );
    } else {
      final enabled = _step == 1 || _detailsValid;
      action = IgnorePointer(
        ignoring: !enabled,
        child: AnimatedOpacity(
          opacity: enabled ? 1 : 0.4,
          duration: NestMotion.base,
          child: NestButton(
            label: 'Continue',
            background: NestColors.cobalt,
            icon: Icons.arrow_forward_rounded,
            onTap: _next,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(
        color: NestColors.cream,
        border: Border(top: BorderSide(color: NestColors.line)),
      ),
      child: Row(children: [Expanded(child: action)]),
    );
  }

  // ------------------------------------------------------------ step 1

  Widget _field({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
    TextCapitalization capitalization = TextCapitalization.none,
    TextInputAction action = TextInputAction.next,
  }) {
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(24),
      borderSide: BorderSide(color: color, width: width),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: NestText.label.copyWith(color: NestColors.muted),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: formatters,
            textCapitalization: capitalization,
            textInputAction: action,
            onChanged: (_) => setState(() {}),
            style: NestText.bodyStrong.copyWith(fontWeight: FontWeight.w400),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: NestText.body,
              filled: true,
              fillColor: NestColors.creamDeep,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              border: border(Colors.transparent, 0),
              enabledBorder: border(Colors.transparent, 0),
              focusedBorder: border(NestColors.cobalt, 2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailsStep() {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
      child: Column(
        children: [
          StaggeredIn(
            offset: 24,
            child: _field(
              label: 'Full name',
              controller: _name,
              hint: 'e.g. Alaa Mohamed',
              capitalization: TextCapitalization.words,
              formatters: [LengthLimitingTextInputFormatter(40)],
            ),
          ),
          StaggeredIn(
            index: 1,
            offset: 24,
            child: _field(
              label: 'Phone',
              controller: _phone,
              hint: '+20 100 000 0000',
              keyboardType: TextInputType.phone,
              formatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
                LengthLimitingTextInputFormatter(16),
              ],
            ),
          ),
          StaggeredIn(
            index: 2,
            offset: 24,
            child: _field(
              label: 'City',
              controller: _city,
              hint: 'e.g. Alexandria',
              capitalization: TextCapitalization.words,
              formatters: [LengthLimitingTextInputFormatter(30)],
            ),
          ),
          StaggeredIn(
            index: 3,
            offset: 24,
            child: _field(
              label: 'Address',
              controller: _address,
              hint: 'Street, building, floor',
              capitalization: TextCapitalization.sentences,
              action: TextInputAction.done,
              formatters: [LengthLimitingTextInputFormatter(80)],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------ step 2

  Widget _shippingStep() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
      children: [
        for (var i = 0; i < _options.length; i++) _shipCard(_options[i], i),
        const SizedBox(height: 4),
        StaggeredIn(
          index: 3,
          child: Row(
            children: [
              const Icon(
                Icons.local_shipping_outlined,
                size: 18,
                color: NestColors.muted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Standard delivery is free on orders over ${formatPrice(kFreeShippingFrom)}.',
                  style: NestText.body.copyWith(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _shipCard(_Ship o, int index) {
    final selected = o.id == _shipId;
    final fee = _fee(o);
    final fg = selected ? NestColors.cream : NestColors.charcoal;
    final date = _dateLabel(DateTime.now().add(Duration(days: o.days)));

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: StaggeredIn(
        index: index,
        child: Pressable(
          semanticLabel: selected ? '${o.name}, selected' : o.name,
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _shipId = o.id);
          },
          child: AnimatedContainer(
            duration: NestMotion.base,
            curve: NestMotion.enter,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: selected ? NestColors.cobalt : NestColors.creamDeep,
              borderRadius: _radii[index % _radii.length],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        o.name,
                        style: NestText.display(30).copyWith(color: fg),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${o.note} · ${o.id == 'pickup' ? 'ready' : 'arrives'} $date',
                        style: NestText.body.copyWith(fontSize: 13, color: fg),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  fee == 0 ? 'Free' : formatPrice(fee),
                  style: NestText.display(30).copyWith(color: fg),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------ step 3

  Widget _reviewStep() {
    final lines = cartController.lines;
    final ship = _ship;
    final fee = _fee(ship);
    final total = _subtotal + fee;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
      children: [
        StaggeredIn(
          offset: 24,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: NestColors.creamDeep,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                for (final line in lines)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: SizedBox(
                            width: 52,
                            height: 60,
                            child: NestImage(
                              asset: line.product.imageAsset,
                              tone: line.product.tone,
                              icon: line.product.category.icon,
                              cacheWidth: 200,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                line.product.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: NestText.display(21),
                              ),
                              Text('× ${line.quantity}', style: NestText.body),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          formatPrice(line.total),
                          style: NestText.bodyStrong,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        StaggeredIn(
          index: 1,
          offset: 24,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
            decoration: const BoxDecoration(
              color: NestColors.cobalt,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(44),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    'SUMMARY',
                    style: NestText.label.copyWith(color: NestColors.butter),
                  ),
                ),
                const SizedBox(height: 10),
                _lightRow('Subtotal', formatPrice(_subtotal)),
                _lightRow(ship.name, fee == 0 ? 'Free' : formatPrice(fee)),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: total.toDouble()),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => Text(
                      formatPrice(value.round()),
                      style: NestText.display(48)
                          .copyWith(color: NestColors.cream),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        StaggeredIn(
          index: 2,
          offset: 24,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: NestColors.line, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 22,
                      color: NestColors.charcoal,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_name.text.trim(), style: NestText.bodyStrong),
                          const SizedBox(height: 2),
                          Text(
                            '${_address.text.trim()}, ${_city.text.trim()}\n${_phone.text.trim()}',
                            style: NestText.body,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(
                      Icons.payments_outlined,
                      size: 22,
                      color: NestColors.charcoal,
                    ),
                    const SizedBox(width: 10),
                    Text('Pay on delivery', style: NestText.bodyStrong),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No card needed',
                        style: NestText.body.copyWith(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _lightRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: Row(
        children: [
          Text(label, style: NestText.body.copyWith(color: NestColors.cream)),
          const Spacer(),
          Text(
            value,
            style: NestText.bodyStrong.copyWith(color: NestColors.cream),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ success

double _iv(double v, double a, double b, Curve curve) {
  final t = ((v - a) / (b - a)).clamp(0.0, 1.0).toDouble();
  return curve.transform(t);
}

class _Success extends StatefulWidget {
  const _Success({super.key, required this.order, required this.onFinish});

  final _Order order;
  final VoidCallback onFinish;

  @override
  State<_Success> createState() => _SuccessState();
}

class _SuccessState extends State<_Success>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final firstName = order.name.split(' ').first;
    final message = order.pickup
        ? 'Order ${order.number} will be ready for pickup on ${order.arrival}.'
        : 'Order ${order.number} is on its way. It arrives by ${order.arrival}.';

    return Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 180,
                  child: AnimatedBuilder(
                    animation: _c,
                    builder: (context, _) {
                      final pop = _iv(_c.value, 0, 0.5, Curves.elasticOut);
                      final dots = _iv(_c.value, 0.1, 0.6, Curves.elasticOut);
                      final check = _iv(_c.value, 0.4, 0.8, Curves.easeOut);
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            right: 6,
                            top: 8,
                            child: Transform.scale(
                              scale: dots,
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: const BoxDecoration(
                                  color: NestColors.coral,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 10,
                            bottom: 6,
                            child: Transform.scale(
                              scale: dots,
                              child: Container(
                                width: 64,
                                height: 64,
                                decoration: const BoxDecoration(
                                  color: NestColors.butter,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                          Transform.scale(
                            scale: pop,
                            child: Container(
                              width: 128,
                              height: 128,
                              decoration: const BoxDecoration(
                                color: NestColors.cobalt,
                                shape: BoxShape.circle,
                              ),
                              child: CustomPaint(painter: _CheckPainter(check)),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                StaggeredIn(
                  index: 4,
                  child: Column(
                    children: [
                      Text(
                        'ORDER CONFIRMED',
                        style: NestText.label.copyWith(
                          color: NestColors.cobalt,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text.rich(
                        TextSpan(
                          text: 'Thank you, ',
                          children: [
                            TextSpan(
                              text: '$firstName.',
                              style: const TextStyle(
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
                        message,
                        textAlign: TextAlign.center,
                        style: NestText.body,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: NestColors.creamDeep,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${order.pieces} ${order.pieces == 1 ? 'piece' : 'pieces'} · ${formatPrice(order.total)} · Pay on delivery',
                          style: NestText.bodyStrong.copyWith(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                StaggeredIn(
                  index: 6,
                  child: NestButton(
                    label: 'Keep shopping',
                    background: NestColors.cobalt,
                    icon: Icons.arrow_forward_rounded,
                    onTap: widget.onFinish,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Positioned.fill(child: ConfettiBurst()),
      ],
    );
  }
}

class _CheckPainter extends CustomPainter {
  const _CheckPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.28, h * 0.52)
      ..lineTo(w * 0.44, h * 0.68)
      ..lineTo(w * 0.74, h * 0.36);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.085
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = NestColors.cream;
    for (final metric in path.computeMetrics()) {
      canvas.drawPath(metric.extractPath(0, metric.length * progress), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CheckPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
