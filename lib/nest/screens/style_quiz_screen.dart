import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/nest_theme.dart';
import '../data/catalog.dart';
import '../state/room_board_controller.dart';
import '../widgets/confetti_burst.dart';
import '../widgets/motion_widgets.dart';
import '../widgets/nest_button.dart';
import '../widgets/pressable.dart';
import '../widgets/product_card.dart';
import '../widgets/room_sheets.dart';
import '../widgets/staggered_in.dart';
import 'room_board_screen.dart';

// --------------------------------------------------------------------- data

class _Opt {
  const _Opt(this.label, this.icon, this.main, this.second);

  final String label;
  final IconData icon;

  /// Index of the style this answer points to most (2 points)...
  final int main;

  /// ...and the one it points to a little (1 point).
  final int second;
}

class _Question {
  const _Question(this.lead, this.emphasis, this.options);

  final String lead;
  final String emphasis;
  final List<_Opt> options;
}

class _Style {
  const _Style({
    required this.title,
    required this.short,
    required this.tagline,
    required this.color,
    required this.fg,
    required this.picks,
  });

  /// Shown as "The <title>".
  final String title;
  final String short;
  final String tagline;
  final Color color;
  final Color fg;
  final List<String> picks;
}

const List<_Style> _styles = [
  _Style(
    title: 'Soft Nester',
    short: 'Soft',
    tagline: 'You build rooms that feel like a hug: rounded edges, warm textures and a sofa you never want to leave.',
    color: NestColors.butter,
    fg: NestColors.charcoal,
    picks: ['oslo-sofa', 'bloom-rug', 'miro-chair'],
  ),
  _Style(
    title: 'Bold Curator',
    short: 'Bold',
    tagline: 'Your home is a gallery you can sit in. Statement shapes, sharp light and one loud piece in every room.',
    color: NestColors.coral,
    fg: NestColors.charcoal,
    picks: ['arc-lamp', 'miro-chair', 'terra-vase'],
  ),
  _Style(
    title: 'Calm Minimalist',
    short: 'Calm',
    tagline: 'Clear surfaces, natural wood and room to breathe. Every piece has to earn its place.',
    color: NestColors.softGreen,
    fg: NestColors.charcoal,
    picks: ['pilar-table', 'haven-sideboard', 'dune-table'],
  ),
  _Style(
    title: 'Social Host',
    short: 'Host',
    tagline: 'Your door is always open. Big tables, deep sofas and the kind of light that makes everyone look good.',
    color: NestColors.cobalt,
    fg: NestColors.cream,
    picks: ['dune-table', 'oslo-sofa', 'arc-lamp'],
  ),
];

const List<_Question> _questions = [
  _Question('Your perfect', 'Saturday morning?', [
    _Opt('Slow coffee, a blanket, nowhere to be', Icons.coffee_outlined, 0, 2),
    _Opt('A gallery, then the flea market', Icons.museum_outlined, 1, 3),
    _Opt('Fresh air and a clear head', Icons.park_outlined, 2, 0),
    _Opt('Brunch with the whole crew', Icons.groups_outlined, 3, 1),
  ]),
  _Question('Pick a', 'shape.', [
    _Opt('Round and soft', Icons.circle_outlined, 0, 3),
    _Opt('Sharp and graphic', Icons.change_history_rounded, 1, 2),
    _Opt('Clean and simple', Icons.crop_square_rounded, 2, 1),
    _Opt('Big and generous', Icons.open_in_full_rounded, 3, 0),
  ]),
  _Question('Which colors make', 'you happy?', [
    _Opt('Butter and cream', Icons.wb_sunny_outlined, 0, 2),
    _Opt('Coral and cobalt', Icons.local_fire_department_outlined, 1, 3),
    _Opt('Sage and oak', Icons.spa_outlined, 2, 0),
    _Opt('A bit of everything', Icons.celebration_outlined, 3, 1),
  ]),
  _Question('This room is mostly', 'for…', [
    _Opt('Resting', Icons.bed_outlined, 0, 2),
    _Opt('Showing off', Icons.auto_awesome_outlined, 1, 3),
    _Opt('Thinking', Icons.lightbulb_outline, 2, 1),
    _Opt('Hosting', Icons.restaurant_outlined, 3, 0),
  ]),
];

const List<Color> _optionColors = [
  NestColors.butter,
  NestColors.coral,
  NestColors.softGreen,
  NestColors.creamDeep,
];

const List<BorderRadius> _optionRadii = [
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
  BorderRadius.only(
    topLeft: Radius.circular(14),
    topRight: Radius.circular(44),
    bottomLeft: Radius.circular(44),
    bottomRight: Radius.circular(14),
  ),
];

// ------------------------------------------------------------------- screen

class StyleQuizScreen extends StatefulWidget {
  const StyleQuizScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 450),
        reverseTransitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const StyleQuizScreen(),
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
  State<StyleQuizScreen> createState() => _StyleQuizScreenState();
}

class _StyleQuizScreenState extends State<StyleQuizScreen> {
  /// 0 = intro, 1..4 = questions, 5 = result.
  int _step = 0;
  final List<int> _scores = [0, 0, 0, 0];
  final List<_Opt> _chosen = [];
  int? _picked;
  bool _locked = false;
  bool _forward = true;

  int get _winner {
    var best = 0;
    for (var i = 1; i < _scores.length; i++) {
      if (_scores[i] > _scores[best]) best = i;
    }
    // On a tie, the style of the last answer wins.
    if (_chosen.isNotEmpty && _scores[_chosen.last.main] == _scores[best]) {
      return _chosen.last.main;
    }
    return best;
  }

  void _start() {
    HapticFeedback.selectionClick();
    setState(() {
      _forward = true;
      _step = 1;
    });
  }

  Future<void> _pick(int index) async {
    if (_locked) return;
    _locked = true;
    HapticFeedback.mediumImpact();
    final option = _questions[_step - 1].options[index];
    setState(() => _picked = index);

    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;

    _scores[option.main] += 2;
    _scores[option.second] += 1;
    _chosen.add(option);
    setState(() {
      _picked = null;
      _forward = true;
      _step += 1;
      _locked = false;
    });
    if (_step == 5) HapticFeedback.heavyImpact();
  }

  void _back() {
    if (_locked) return;
    if (_step == 0 || _step == 5) {
      Navigator.of(context).pop();
    } else if (_step == 1) {
      setState(() {
        _forward = false;
        _step = 0;
      });
    } else {
      final last = _chosen.removeLast();
      _scores[last.main] -= 2;
      _scores[last.second] -= 1;
      setState(() {
        _forward = false;
        _step -= 1;
      });
    }
  }

  void _retake() {
    HapticFeedback.selectionClick();
    setState(() {
      for (var i = 0; i < _scores.length; i++) {
        _scores[i] = 0;
      }
      _chosen.clear();
      _picked = null;
      _locked = false;
      _forward = false;
      _step = 1;
    });
  }

  Future<void> _planRoom(_Style style) async {
    final room = await showRoomFormSheet(context);
    if (room == null || !mounted) return;
    for (final id in style.picks) {
      roomBoardController.addItem(room.id, id);
    }
    RoomBoardScreen.open(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == 0 || _step == 5,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _back();
      },
      child: Scaffold(
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
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: Offset(_forward ? 0.08 : -0.08, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey<int>(_step),
                    child: switch (_step) {
                      0 => _intro(),
                      5 => _result(),
                      _ => _question(),
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------ top

  Widget _top() {
    final inQuiz = _step >= 1 && _step <= 4;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 20, 0),
      child: Column(
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
                inQuiz ? 'QUESTION $_step OF 4' : 'STYLE QUIZ',
                style: NestText.label.copyWith(color: NestColors.muted),
              ),
            ],
          ),
          if (inQuiz) ...[
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Row(
                children: [
                  for (var i = 0; i < 4; i++)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: i < 3 ? 6 : 0),
                        child: AnimatedContainer(
                          duration: NestMotion.base,
                          curve: NestMotion.enter,
                          height: 6,
                          decoration: BoxDecoration(
                            color: i < _step
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
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- intro

  Widget _intro() {
    const dotColors = [
      NestColors.butter,
      NestColors.coral,
      NestColors.softGreen,
      NestColors.cobalt,
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 220,
            height: 130,
            child: Stack(
              children: [
                for (var i = 0; i < dotColors.length; i++)
                  Positioned(
                    left: i * 38.0,
                    top: i.isEven ? 0 : 30,
                    child: Entrance(
                      kind: EntranceKind.pop,
                      delay: Duration(milliseconds: 150 + i * 130),
                      duration: const Duration(milliseconds: 1000),
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: dotColors[i],
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          StaggeredIn(
            index: 3,
            child: Column(
              children: [
                Text(
                  'STYLE QUIZ',
                  style: NestText.label.copyWith(color: NestColors.cobalt),
                ),
                const SizedBox(height: 10),
                Text.rich(
                  const TextSpan(
                    text: 'Which home\n',
                    children: [
                      TextSpan(
                        text: 'are you?',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: NestColors.cobalt,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  style: NestText.display(52),
                ),
                const SizedBox(height: 14),
                Text(
                  '4 quick questions. We’ll match you with pieces and a room to start planning.',
                  textAlign: TextAlign.center,
                  style: NestText.body,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          StaggeredIn(
            index: 5,
            child: NestButton(
              label: 'Start',
              background: NestColors.cobalt,
              icon: Icons.arrow_forward_rounded,
              onTap: _start,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- question

  Widget _question() {
    final q = _questions[_step - 1];
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
      children: [
        StaggeredIn(
          key: ValueKey<String>('title-$_step'),
          offset: 20,
          child: Text.rich(
            TextSpan(
              text: '${q.lead} ',
              children: [
                TextSpan(
                  text: q.emphasis,
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    color: NestColors.cobalt,
                  ),
                ),
              ],
            ),
            style: NestText.display(40),
          ),
        ),
        const SizedBox(height: 22),
        for (var i = 0; i < q.options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: StaggeredIn(
              key: ValueKey<String>('opt-$_step-$i'),
              index: i + 1,
              offset: 30,
              child: _OptionCard(
                option: q.options[i],
                color: _optionColors[i],
                radius: _optionRadii[i],
                selected: _picked == i,
                dimmed: _picked != null && _picked != i,
                onTap: () => _pick(i),
              ),
            ),
          ),
      ],
    );
  }

  // --------------------------------------------------------------- result

  Widget _result() {
    final winner = _winner;
    final style = _styles[winner];
    final total = _scores.fold(0, (sum, s) => sum + s);

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(26, 34, 26, 30),
              decoration: BoxDecoration(
                color: style.color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(96),
                  topRight: Radius.circular(24),
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Entrance(
                    delay: const Duration(milliseconds: 250),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 18),
                      child: Text(
                        'YOUR HOME PERSONALITY',
                        style: NestText.label.copyWith(color: style.fg),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Entrance(
                    delay: const Duration(milliseconds: 400),
                    child: Text.rich(
                      TextSpan(
                        text: 'The ',
                        children: [
                          TextSpan(
                            text: style.title,
                            style: const TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                      style: NestText.display(52).copyWith(color: style.fg),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Entrance(
                    delay: const Duration(milliseconds: 600),
                    child: Text(
                      style.tagline,
                      style: NestText.body.copyWith(
                        fontSize: 15,
                        color: style.fg,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            StaggeredIn(
              index: 2,
              child: _MatchCard(scores: _scores, total: total, winner: winner),
            ),
            const SizedBox(height: 32),
            StaggeredIn(
              index: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PICKED FOR YOU',
                      style: NestText.label.copyWith(color: NestColors.cobalt),
                    ),
                    const SizedBox(height: 8),
                    Text('Start with these', style: NestText.display(34)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 290,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: style.picks.length,
                separatorBuilder: (context, index) => const SizedBox(width: 14),
                itemBuilder: (context, i) => StaggeredIn(
                  index: i + 3,
                  child: SizedBox(
                    width: 150,
                    child: ProductCard(
                      product: Catalog.byId(style.picks[i]),
                      shape: CardShape.values[i % CardShape.values.length],
                      imageAspect: 0.8,
                      heroScope: 'quiz',
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            StaggeredIn(
              index: 6,
              child: NestButton(
                label: 'Plan a room with these',
                background: NestColors.cobalt,
                icon: Icons.add_home_outlined,
                onTap: () => _planRoom(style),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Pressable(
                onTap: _retake,
                semanticLabel: 'Retake the quiz',
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    'RETAKE THE QUIZ',
                    style: NestText.label.copyWith(color: NestColors.muted),
                  ),
                ),
              ),
            ),
          ],
        ),
        const Positioned.fill(child: ConfettiBurst()),
      ],
    );
  }
}

// ------------------------------------------------------------------ widgets

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.option,
    required this.color,
    required this.radius,
    required this.selected,
    required this.dimmed,
    required this.onTap,
  });

  final _Opt option;
  final Color color;
  final BorderRadius radius;
  final bool selected;
  final bool dimmed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? NestColors.cream : NestColors.charcoal;

    return AnimatedOpacity(
      opacity: dimmed ? 0.45 : 1,
      duration: NestMotion.base,
      child: Pressable(
        onTap: onTap,
        semanticLabel: option.label,
        child: AnimatedContainer(
          duration: NestMotion.base,
          curve: NestMotion.enter,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            color: selected ? NestColors.cobalt : color,
            borderRadius: radius,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: fg.withValues(alpha: 0.12),
                ),
                child: Icon(option.icon, size: 24, color: fg),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  option.label,
                  style: NestText.display(24).copyWith(color: fg),
                ),
              ),
              AnimatedScale(
                scale: selected ? 1 : 0,
                duration: NestMotion.base,
                curve: Curves.easeOutBack,
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 26,
                  color: NestColors.cream,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({
    required this.scores,
    required this.total,
    required this.winner,
  });

  final List<int> scores;
  final int total;
  final int winner;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      decoration: BoxDecoration(
        color: NestColors.creamDeep,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HOW YOU MATCH',
            style: NestText.label.copyWith(color: NestColors.muted),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < _styles.length; i++) _row(i),
        ],
      ),
    );
  }

  Widget _row(int i) {
    final percent = total == 0 ? 0 : (scores[i] * 100 / total).round();
    final isWinner = i == winner;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(
              _styles[i].short,
              style: isWinner
                  ? NestText.bodyStrong.copyWith(fontSize: 13)
                  : NestText.body.copyWith(fontSize: 13),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(
                children: [
                  Container(height: 12, color: NestColors.cream),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: percent / 100),
                    duration: Duration(milliseconds: 700 + i * 120),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: value,
                      child: Container(height: 12, color: _styles[i].color),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 46,
            child: Text(
              '$percent%',
              textAlign: TextAlign.right,
              style: isWinner
                  ? NestText.bodyStrong.copyWith(fontSize: 13)
                  : NestText.body.copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card for the Home screen that opens the quiz.
class StyleQuizPromo extends StatelessWidget {
  const StyleQuizPromo({super.key, required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    const dotColors = [
      NestColors.butter,
      NestColors.coral,
      NestColors.cobalt,
      NestColors.cream,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Pressable(
        scale: 0.98,
        onTap: onOpen,
        semanticLabel: 'Take the style quiz',
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: NestColors.softGreen,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(110),
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('FIND YOUR STYLE', style: NestText.label),
                  ),
                  for (var i = 0; i < dotColors.length; i++)
                    Padding(
                      padding: EdgeInsets.only(left: 6, right: i == 3 ? 22 : 0),
                      child: Entrance(
                        kind: EntranceKind.pop,
                        delay: Duration(milliseconds: 200 + i * 130),
                        duration: const Duration(milliseconds: 1000),
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: dotColors[i],
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text.rich(
                const TextSpan(
                  text: 'Which home\n',
                  children: [
                    TextSpan(
                      text: 'are you?',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
                style: NestText.display(38),
              ),
              const SizedBox(height: 10),
              Text(
                '4 quick questions and we’ll match you with pieces and a room to start planning.',
                style: NestText.body.copyWith(color: NestColors.charcoal),
              ),
              const SizedBox(height: 20),
              NestButton(
                label: 'Take the quiz',
                background: NestColors.cobalt,
                icon: Icons.arrow_forward_rounded,
                onTap: onOpen,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
