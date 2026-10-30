import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/nest_theme.dart';
import '../data/catalog.dart';
import '../data/product.dart';
import '../widgets/empty_state.dart';
import '../widgets/nest_button.dart';
import '../widgets/nest_chip.dart';
import '../widgets/pressable.dart';
import '../widgets/product_sliver_grid.dart';
import '../widgets/screen_title.dart';

enum SortMode {
  featured('Featured'),
  priceLow('Price: low to high'),
  priceHigh('Price: high to low');

  const SortMode(this.label);
  final String label;
}

class _ActiveFilter {
  const _ActiveFilter(this.label, this.onRemove);
  final String label;
  final VoidCallback onRemove;
}

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => ShopScreenState();
}

class ShopScreenState extends State<ShopScreen> {
  final TextEditingController _search = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  ProductCategory? _category;
  int? _maxPrice;
  bool _onlyNew = false;
  SortMode _sort = SortMode.featured;

  /// Bumped when filters change so the grid replays its entrance animation.
  int _epoch = 0;

  // Called by the navigation shell.
  void showCategory(ProductCategory? category) {
    setState(() {
      _category = category;
      _epoch++;
    });
  }

  void focusSearch() => _searchFocus.requestFocus();

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<Product> get _results {
    final query = _search.text.trim().toLowerCase();
    final list = Catalog.all.where((p) {
      if (_category != null && p.category != _category) return false;
      if (_maxPrice != null && p.price > _maxPrice!) return false;
      if (_onlyNew && !p.isNew) return false;
      if (query.isNotEmpty && !p.name.toLowerCase().contains(query)) {
        return false;
      }
      return true;
    }).toList();

    switch (_sort) {
      case SortMode.featured:
        break;
      case SortMode.priceLow:
        list.sort((a, b) => a.price.compareTo(b.price));
      case SortMode.priceHigh:
        list.sort((a, b) => b.price.compareTo(a.price));
    }
    return list;
  }

  void _update(VoidCallback change) {
    HapticFeedback.selectionClick();
    setState(() {
      change();
      _epoch++;
    });
  }

  void _clearSheetFilters() {
    _maxPrice = null;
    _onlyNew = false;
    _sort = SortMode.featured;
  }

  void _clearEverything() {
    _search.clear();
    _category = null;
    _clearSheetFilters();
  }

  List<_ActiveFilter> _activeFilters() => [
    if (_category != null)
      _ActiveFilter(_category!.label, () => _update(() => _category = null)),
    if (_maxPrice != null)
      _ActiveFilter(
        'Up to ${formatPrice(_maxPrice!)}',
        () => _update(() => _maxPrice = null),
      ),
    if (_onlyNew)
      _ActiveFilter('New in', () => _update(() => _onlyNew = false)),
    if (_sort != SortMode.featured)
      _ActiveFilter(
        _sort.label,
        () => _update(() => _sort = SortMode.featured),
      ),
  ];

  void _openFilters() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheet) {
            void change(VoidCallback fn, {bool replay = true}) {
              setState(() {
                fn();
                if (replay) _epoch++;
              });
              setSheet(() {});
            }

            const sliderMin = 50.0;
            final sliderMax = Catalog.priceCeiling.toDouble();
            final sliderValue = (_maxPrice ?? Catalog.priceCeiling)
                .toDouble()
                .clamp(sliderMin, sliderMax)
                .toDouble();
            final count = _results.length;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sort & filter', style: NestText.display(34)),
                  const SizedBox(height: 22),
                  Text(
                    'SORT BY',
                    style: NestText.label.copyWith(color: NestColors.muted),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final mode in SortMode.values)
                        NestChip(
                          label: mode.label,
                          selected: _sort == mode,
                          onTap: () => change(() => _sort = mode),
                        ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  Row(
                    children: [
                      Text(
                        'MAX PRICE',
                        style: NestText.label.copyWith(color: NestColors.muted),
                      ),
                      const Spacer(),
                      Text(
                        _maxPrice == null
                            ? 'Any price'
                            : 'Up to ${formatPrice(_maxPrice!)}',
                        style: NestText.bodyStrong,
                      ),
                    ],
                  ),
                  Slider(
                    value: sliderValue,
                    min: sliderMin,
                    max: sliderMax,
                    divisions: ((sliderMax - sliderMin) / 50).round(),
                    onChanged: (v) => change(
                      () => _maxPrice = v >= sliderMax ? null : v.round(),
                      replay: false,
                    ),
                    onChangeEnd: (_) => setState(() => _epoch++),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'New arrivals only',
                          style: NestText.bodyStrong,
                        ),
                      ),
                      Switch(
                        value: _onlyNew,
                        onChanged: (v) => change(() => _onlyNew = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: NestButton(
                          label: 'Reset',
                          background: NestColors.creamDeep,
                          foreground: NestColors.charcoal,
                          onTap: () => change(_clearSheetFilters),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: NestButton(
                          label:
                              'Show $count ${count == 1 ? 'piece' : 'pieces'}',
                          onTap: () => Navigator.of(sheetContext).pop(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    final active = _activeFilters();
    final sheetFilterCount =
        (_maxPrice != null ? 1 : 0) +
        (_onlyNew ? 1 : 0) +
        (_sort != SortMode.featured ? 1 : 0);

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ScreenTitle(
                    lead: 'The',
                    emphasis: 'shop',
                    subtitle:
                        '${results.length} ${results.length == 1 ? 'piece' : 'pieces'}',
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _SearchField(
                          controller: _search,
                          focusNode: _searchFocus,
                          onChanged: (_) => setState(() {}),
                          onClear: () => setState(_search.clear),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _FilterButton(
                        activeCount: sheetFilterCount,
                        onTap: _openFilters,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: ProductCategory.values.length + 1,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return NestChip(
                        label: 'All',
                        selected: _category == null,
                        onTap: () => _update(() => _category = null),
                      );
                    }
                    final c = ProductCategory.values[i - 1];
                    return NestChip(
                      label: c.label,
                      selected: _category == c,
                      onTap: () => _update(() => _category = c),
                    );
                  },
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: AnimatedSize(
              duration: NestMotion.base,
              curve: NestMotion.enter,
              alignment: Alignment.topCenter,
              child: active.isEmpty
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          for (final f in active)
                            _ActiveChip(label: f.label, onRemove: f.onRemove),
                          Pressable(
                            onTap: () => setState(() {
                              _clearEverything();
                              _epoch++;
                            }),
                            semanticLabel: 'Clear all filters',
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 8,
                              ),
                              child: Text(
                                'CLEAR ALL',
                                style: NestText.label.copyWith(
                                  color: NestColors.cobalt,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          if (results.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.search_off_rounded,
                accent: NestColors.coral,
                accent2: NestColors.butter,
                lead: 'Nothing',
                emphasis: 'found yet.',
                message: 'Try a different name, or loosen a filter.',
                actionLabel: 'Clear everything',
                onAction: () => setState(() {
                  _clearEverything();
                  _epoch++;
                }),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              sliver: ProductSliverGrid(products: results, epoch: _epoch),
            ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(26),
      borderSide: BorderSide(color: color, width: width),
    );

    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: NestText.bodyStrong.copyWith(fontWeight: FontWeight.w400),
      decoration: InputDecoration(
        hintText: 'Search by product name',
        hintStyle: NestText.body,
        filled: true,
        fillColor: NestColors.creamDeep,
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
        prefixIcon: const Icon(
          Icons.search_rounded,
          size: 22,
          color: NestColors.charcoal,
        ),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                icon: const Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: NestColors.charcoal,
                ),
                onPressed: onClear,
              ),
        border: border(Colors.transparent, 0),
        enabledBorder: border(Colors.transparent, 0),
        focusedBorder: border(NestColors.cobalt, 2),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.activeCount, required this.onTap});

  final int activeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: activeCount == 0
          ? 'Sort and filter'
          : 'Sort and filter, $activeCount active',
      child: SizedBox(
        width: 52,
        height: 52,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: const BoxDecoration(
                color: NestColors.charcoal,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.tune_rounded,
                  size: 22,
                  color: NestColors.cream,
                ),
              ),
            ),
            Positioned(
              right: 2,
              top: 2,
              child: AnimatedScale(
                scale: activeCount > 0 ? 1 : 0,
                duration: NestMotion.base,
                curve: Curves.easeOutBack,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: NestColors.coral,
                    shape: BoxShape.circle,
                    border: Border.all(color: NestColors.cream, width: 2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveChip extends StatelessWidget {
  const _ActiveChip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onRemove,
      semanticLabel: 'Remove filter $label',
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
        decoration: BoxDecoration(
          color: NestColors.butter,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: NestText.button.copyWith(fontSize: 13)),
            const SizedBox(width: 6),
            const Icon(
              Icons.close_rounded,
              size: 16,
              color: NestColors.charcoal,
            ),
          ],
        ),
      ),
    );
  }
}
