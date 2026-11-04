import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/nav.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../data/api.dart';
import '../../data/catalog.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';
import '../../widgets/fields.dart';
import '../../widgets/illustrations.dart';
import '../../widgets/product_widgets.dart';
import '../../widgets/u_scaffold.dart';

// ───────────────────────── 05 · Customer home ─────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _cat; // null = featured
  List<Product>? _items;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final app = context.appRead;
      if (!app.ready) {
        app.init();
      } else {
        app.refreshHome().catchError((_) {});
      }
      if (app.signedIn && app.myOrders.isEmpty) app.loadMyOrders().catchError((_) {});
    });
  }

  Future<void> _select(String? slug) async {
    setState(() {
      _cat = slug;
      _items = null;
      _error = null;
    });
    if (slug == null) return;
    setState(() => _loading = true);
    try {
      final list = await context.appRead.fetchProducts(category: slug);
      if (mounted && _cat == slug) setState(() => _items = list);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final cats = app.categories;
    final labels = ['Our picks', ...cats.map((c) => c.name)];
    final selectedLabel = _cat == null ? 'Our picks' : cats.firstWhere((c) => c.slug == _cat, orElse: () => const ShopCategory(id: 0, slug: '', name: 'Our picks')).name;
    final items = _cat == null ? app.featured : (_items ?? const <Product>[]);
    final active = _activeOrder(app);

    return UScaffold(
      nav: NavKind.customer,
      navIndex: 0,
      header: _HomeHeader(area: app.hasAddress ? '${app.area}, ${app.city.split(',').first}' : 'Add your address'),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      children: [
        USearchBox(hint: 'Search mithai, snacks & more', onTap: () => go(context, R.search)),
        const Gap(14),
        ColorBlock(
          color: AppColors.yellow,
          padding: EdgeInsets.zero,
          child: SizedBox(
            height: 200,
            child: Stack(children: [
              Positioned(
                right: -18,
                top: 22,
                bottom: -30,
                width: 170,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(80), topRight: Radius.circular(80)),
                  child: Image.asset(Img.sweets, fit: BoxFit.cover),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 150, 16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Eyebrow('Rooted in Devbhoomi'),
                  const Gap(8),
                  const FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Headline('Happiness,\nfreshly *made.*', size: 30)),
                  const Gap(8),
                  Text('27 years of traditions, packed with love.', style: T.tiny(AppColors.ink), maxLines: 2),
                  const Spacer(),
                  SmallButton('Explore mithai', icon: Icons.north_east_rounded, onTap: () => goTab(context, R.collection)),
                ]),
              ),
            ]),
          ),
        ),
        if (active != null) ...[
          const Gap(10),
          ColorBlock(
            color: AppColors.teal,
            onTap: () => go(context, R.tracking, args: active.number),
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('ORDER  #${active.number}', style: T.sans(9.5, color: AppColors.white, weight: FontWeight.w700, spacing: 1.2)),
                  const Gap(8),
                  Text(active.statusLabel, style: T.display(23, color: AppColors.white)),
                  const Gap(4),
                  Text('${money(active.total)} · ${active.deliveryLabel.split(' · ').first}', style: T.sans(11, color: AppColors.white)),
                ]),
              ),
              const IconTileButton(Icons.north_east_rounded),
            ]),
          ),
        ],
        const Gap(14),
        Row(children: [
          Expanded(child: ChipGroup(options: labels, selected: selectedLabel, scroll: true, onSelected: (v) {
            if (v == 'Our picks') {
              _select(null);
            } else {
              _select(cats.firstWhere((c) => c.name == v).slug);
            }
          })),
          GestureDetector(
            onTap: () => go(context, R.favourites),
            child: Pill('${app.favourites.length}', bg: AppColors.pink, fg: AppColors.berry, icon: Icons.favorite_rounded),
          ),
        ]),
        const Gap(18),
        SectionTitle(_cat == null ? 'Little boxes of joy' : selectedLabel, action: 'View all', onAction: () => goTab(context, R.collection)),
        const Gap(12),
        if (_loading || (!app.ready && app.featured.isEmpty))
          const LoadState(loading: true)
        else if (_error != null)
          LoadState(error: _error, onRetry: () => _select(_cat))
        else if (items.isEmpty)
          const LoadState(empty: 'Nothing here just yet — have a look in the shop.')
        else
          AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: ProductGrid(items.take(8).toList(), key: ValueKey(_cat ?? 'picks'))),
        const Gap(6),
        ActionRow(icon: Icons.card_giftcard_rounded, title: 'Festive gifting', subtitle: 'Build a gift box or ask for a custom quote', onTap: () => go(context, R.gifting)),
        ActionRow(
          icon: Icons.receipt_long_outlined,
          title: 'Your orders',
          subtitle: active != null ? 'Track #${active.number} · ${active.statusLabel}' : 'Orders from the app and the website',
          onTap: () => go(context, R.orderHistory),
        ),
        ActionRow(icon: Icons.local_drink_outlined, title: 'Fresh milk at your door', subtitle: 'Every day, alternate days or the days you choose', onTap: () => goTab(context, R.milkHub)),
        ActionRow(icon: Icons.landscape_outlined, title: 'Our story', subtitle: '27 years of sweet beginnings', onTap: () => go(context, R.story), divider: false),
      ],
    );
  }
}

/// The most recent order that is still on its way (from this phone or the account).
ShopOrder? _activeOrder(AppState app) {
  for (final o in [if (app.lastOrder != null) app.lastOrder!, ...app.myOrders]) {
    if (o.isActive) return o;
  }
  return null;
}

class _HomeHeader extends StatelessWidget {
  final String area;
  const _HomeHeader({required this.area});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.cream,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 16, 4),
          child: Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: () => go(context, R.location, args: 'edit'),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Eyebrow('Delivering to'),
                  const Gap(6),
                  Row(children: [
                    const Icon(Icons.location_on_outlined, size: 17, color: AppColors.berry),
                    const SizedBox(width: 4),
                    Flexible(child: Text(area, style: T.sans(14, weight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.ink),
                  ]),
                ]),
              ),
            ),
            const BagButton(),
            const SizedBox(width: 8),
            IconTileButton(Icons.notifications_none_rounded, onTap: () => go(context, R.notifications)),
          ]),
        ),
      ),
    );
  }
}

// ───────────────────────── 06 · Shop collection ─────────────────────────
class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  static const _sorts = {'Featured': 'featured', 'Price: low to high': 'low', 'Price: high to low': 'high'};
  String? _cat;
  String _q = '';
  String _sort = 'Featured';
  List<Product>? _items;
  String? _error;
  Timer? _debounce;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final id = ++_request;
    setState(() {
      _items = null;
      _error = null;
    });
    try {
      final list = await context.appRead.fetchProducts(category: _cat, query: _q.trim().isEmpty ? null : _q.trim(), sort: _sorts[_sort]!);
      if (mounted && id == _request) setState(() => _items = list);
    } on ApiException catch (e) {
      if (mounted && id == _request) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cats = context.app.categories;
    final labels = ['All', ...cats.map((c) => c.name)];
    final selected = _cat == null ? 'All' : cats.firstWhere((c) => c.slug == _cat, orElse: () => const ShopCategory(id: 0, slug: '', name: 'All')).name;
    return UScaffold(
      title: 'The collection',
      nav: NavKind.customer,
      navIndex: 1,
      children: [
        USearchBox(
          hint: 'Find your favourite',
          onChanged: (v) {
            _q = v;
            _debounce?.cancel();
            _debounce = Timer(const Duration(milliseconds: 350), _load);
          },
        ),
        const Gap(14),
        ChipGroup(
          options: labels,
          selected: selected,
          scroll: true,
          onSelected: (v) {
            _cat = v == 'All' ? null : cats.firstWhere((c) => c.name == v).slug;
            _load();
          },
        ),
        const Gap(14),
        Row(children: [
          Expanded(child: Text('Made for your sweet moments.', style: T.sans(12, color: AppColors.muted))),
          GestureDetector(
            onTap: () async {
              final v = await pickOption(context, title: 'Sort by', options: _sorts.keys.toList(), selected: _sort);
              if (v != null) {
                _sort = v;
                _load();
              }
            },
            child: Pill(_sort, icon: Icons.swap_vert_rounded),
          ),
        ]),
        const Gap(16),
        SectionTitle(selected == 'All' ? 'Everything we make' : selected),
        const Gap(12),
        if (_error != null)
          LoadState(error: _error, onRetry: _load)
        else if (_items == null)
          const LoadState(loading: true)
        else if (_items!.isEmpty)
          LoadState(empty: _q.isEmpty ? 'Nothing in this collection right now.' : 'No sweets match “$_q” here yet.')
        else
          ProductGrid(_items!),
        const Gap(4),
        ActionRow(icon: Icons.card_giftcard_rounded, title: 'Build your own gift box', subtitle: 'Choose up to ${context.app.config.giftMaxItems} favourites', onTap: () => go(context, R.giftBox), divider: false),
      ],
    );
  }
}

// ───────────────────────── 07 · Product details ─────────────────────────
class ProductScreen extends StatefulWidget {
  /// A [Product], a product id (int) or a slug (String, same as the website URL).
  final Object? product;
  const ProductScreen({super.key, this.product});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  Product? p;
  List<Product> _related = const [];
  int? _option;
  int _qty = 1;
  String? _error;

  @override
  void initState() {
    super.initState();
    final arg = widget.product;
    if (arg is Product) _use(arg);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _use(Product x) {
    p = x;
    _option ??= x.defaultOption?.id;
  }

  Future<void> _load() async {
    final arg = widget.product;
    final Object? key = arg is Product ? arg.id : (arg ?? (context.appRead.featured.isNotEmpty ? context.appRead.featured.first.id : null));
    if (key == null) {
      setState(() => _error = 'Product not found.');
      return;
    }
    try {
      final (fresh, related) = await context.appRead.fetchProduct(key);
      if (!mounted) return;
      setState(() {
        _use(fresh);
        if (fresh.optionById(_option) == null) _option = fresh.defaultOption?.id;
        _related = related;
        _error = null;
      });
    } on ApiException catch (e) {
      if (mounted && p == null) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final p = this.p;
    if (p == null) {
      return UScaffold(title: 'Crafted with care', nav: NavKind.customer, navIndex: 1, children: [
        LoadState(loading: _error == null, error: _error, onRetry: _load),
      ]);
    }
    final unit = p.priceFor(_option);
    final stock = p.stockFor(_option);
    final soldOut = p.soldOutFor(_option);
    final maxQty = (stock ?? app.config.maxLineQuantity).clamp(1, app.config.maxLineQuantity);
    if (_qty > maxQty) _qty = maxQty;
    final fav = app.favourites.contains(p.id);

    return UScaffold(
      title: 'Crafted with care',
      nav: NavKind.customer,
      navIndex: 1,
      bottom: PrimaryButton(
        soldOut ? 'Sold out' : 'Add to bag · ${money(unit * _qty)}',
        icon: soldOut ? null : Icons.add_rounded,
        onTap: soldOut
            ? null
            : () {
                final error = context.appRead.addProduct(p, optionId: _option, qty: _qty);
                if (error != null) {
                  toast(context, error);
                } else {
                  HapticFeedback.mediumImpact();
                  go(context, R.bag);
                }
              },
      ),
      children: [
        Hero(
          tag: 'product-${p.id}',
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(70), bottom: Radius.circular(18)),
            child: AspectRatio(aspectRatio: 1.65, child: NetImage(p.imageUrl, fallback: fallbackFor(p))),
          ),
        ),
        const Gap(16),
        Row(children: [
          if (p.category != null) Pill(p.category!.name, bg: AppColors.pink, fg: AppColors.berry),
          if (p.isPerishable) ...[const SizedBox(width: 6), const Pill('Fresh', bg: AppColors.mint, fg: AppColors.teal)],
          const Spacer(),
          IconTileButton(
            fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            onTap: () async {
              final saved = await context.appRead.toggleFavourite(p);
              if (context.mounted) toast(context, saved ? 'Saved to favourites' : 'Removed from favourites');
            },
          ),
        ]),
        Text(p.name, style: T.display(38)),
        if (p.nameHi != null && p.nameHi!.isNotEmpty) Text(p.nameHi!, style: T.deva(14, color: AppColors.muted)),
        if (p.tagline != null) ...[const Gap(6), Text(p.tagline!, style: T.sans(12.5, color: AppColors.teal, weight: FontWeight.w600))],
        const Gap(10),
        BodyText(p.description),
        const Gap(14),
        if (p.options.length > 1)
          ChipGroup(
            options: p.options.map((o) => o.soldOut ? '${o.label} · sold out' : o.label).toList(),
            selected: () {
              final o = p.optionById(_option);
              if (o == null) return '';
              return o.soldOut ? '${o.label} · sold out' : o.label;
            }(),
            scroll: true,
            onSelected: (v) => setState(() => _option = p.options.firstWhere((o) => v.startsWith(o.label)).id),
          )
        else
          Align(alignment: Alignment.centerLeft, child: Pill(p.labelFor(_option), bg: AppColors.peach, fg: AppColors.ink)),
        const Gap(16),
        Row(children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (c, a) => FadeTransition(opacity: a, child: SlideTransition(position: Tween(begin: const Offset(0, .3), end: Offset.zero).animate(a), child: c)),
            child: Text(money(unit), key: ValueKey(unit), style: T.display(30, color: AppColors.teal, weight: FontWeight.w700)),
          ),
          const Spacer(),
          if (!soldOut) QtyStepper(value: _qty, min: 1, max: maxQty, onChanged: (v) => setState(() => _qty = v)),
        ]),
        if (stock != null && !soldOut && stock <= 5) Padding(padding: const EdgeInsets.only(top: 6), child: Text('Only $stock left', style: T.sans(11.5, color: AppColors.berry, weight: FontWeight.w600))),
        const Gap(14),
        UCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Column(children: [
            KV('Pack', p.labelFor(_option)),
            if (p.category != null) KV('Collection', p.category!.name),
            KV('Delivery', p.isPerishable ? 'Pickup or local delivery (fresh item)' : 'Pickup, local delivery or courier'),
          ]),
        ),
        const FinePrint('Prices include GST. Delivery availability is confirmed at checkout.'),
        if (_related.isNotEmpty) ...[
          const Gap(18),
          const SectionTitle('You may also like'),
          const Gap(12),
          ProductGrid(_related.take(4).toList()),
        ],
      ],
    );
  }
}

// ───────────────────────── 08 · Search & discover ─────────────────────────
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _c = TextEditingController();
  List<Product>? _results;
  String? _error;
  Timer? _debounce;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _c.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final id = ++_request;
    try {
      final r = await context.appRead.search(_c.text.trim());
      if (mounted && id == _request) {
        setState(() {
          _results = r;
          _error = null;
        });
      }
    } on ApiException catch (e) {
      if (mounted && id == _request) setState(() => _error = e.message);
    }
  }

  void _set(String v) {
    _c.text = v;
    _c.selection = TextSelection.collapsed(offset: v.length);
    _run();
  }

  @override
  Widget build(BuildContext context) {
    final q = _c.text.trim();
    final cats = context.app.categories;
    return UScaffold(
      title: 'Find your favourites',
      nav: NavKind.customer,
      navIndex: 1,
      children: [
        USearchBox(
          hint: 'Search mithai, snacks & more',
          controller: _c,
          autofocus: true,
          onChanged: (_) {
            setState(() {});
            _debounce?.cancel();
            _debounce = Timer(const Duration(milliseconds: 300), _run);
          },
        ),
        const Gap(14),
        const Eyebrow('Try searching for'),
        const Gap(10),
        ChipGroup(options: ['Kaju', 'Laddoo', 'Bal Mithai', ...cats.take(3).map((c) => c.name)], selected: q, scroll: true, onSelected: _set),
        const Gap(18),
        SectionTitle(q.isEmpty ? 'Popular right now' : 'Results'),
        const Gap(12),
        if (_error != null)
          LoadState(error: _error, onRetry: _run)
        else if (_results == null)
          const LoadState(loading: true)
        else if (_results!.isEmpty)
          LoadState(empty: 'Nothing found for “$q”. Try “Kaju” or “Laddoo”.')
        else
          ProductGrid(_results!),
        ActionRow(icon: Icons.card_giftcard_rounded, title: 'Festive gifting', subtitle: 'Thoughtful boxes for every occasion', onTap: () => go(context, R.gifting), divider: false),
      ],
    );
  }
}

// ───────────────────────── 09 · Festive gifting ─────────────────────────
class GiftingScreen extends StatefulWidget {
  const GiftingScreen({super.key});

  @override
  State<GiftingScreen> createState() => _GiftingScreenState();
}

class _GiftingScreenState extends State<GiftingScreen> {
  String _occasion = 'Festive';

  static const _copy = {
    'Festive': ('The Uttaranchal selection', 'A box full of traditions.', 'Choose your sweets, packaging and a personal message.'),
    'Weddings': ('Shagun & celebrations', 'Sweetness for every guest.', 'Tell us about your big day and we’ll plan boxes for every guest.'),
    'Corporate': ('Teams & clients', 'Thank-yous that taste good.', 'Bulk pricing and delivery for your team and clients.'),
  };

  @override
  Widget build(BuildContext context) {
    final c = _copy[_occasion]!;
    return UScaffold(
      title: 'Gifts with heart',
      nav: NavKind.customer,
      navIndex: 1,
      bottom: _occasion == 'Festive' ? PrimaryButton('Create a gift box', onTap: () => go(context, R.giftBox)) : null,
      children: [
        const Eyebrow('For every sweet occasion'),
        const Gap(10),
        const Headline('Wrapped in love.\nShared with *joy.*', size: 34),
        const Gap(14),
        const GiftBanner(),
        const Gap(14),
        ChipGroup(options: _copy.keys.toList(), selected: _occasion, onSelected: (v) => setState(() => _occasion = v)),
        const Gap(14),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: ColorBlock(
            key: ValueKey(_occasion),
            color: AppColors.berry,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.$1.toUpperCase(), style: T.sans(9.5, color: AppColors.white, weight: FontWeight.w700, spacing: 1.3)),
              const Gap(8),
              Text(c.$2, style: T.display(25, color: AppColors.white)),
              const Gap(6),
              Text(c.$3, style: T.sans(11.5, color: AppColors.white)),
            ]),
          ),
        ),
        if (_occasion != 'Festive') ...[
          const Gap(16),
          SectionTitle(_occasion == 'Weddings' ? 'Wedding enquiry' : 'Corporate gifting enquiry', size: 24),
          BulkEnquiryForm(key: ValueKey(_occasion), occasion: _occasion == 'Weddings' ? 'Wedding' : 'Corporate gifting'),
          const Gap(16),
        ],
        const Gap(8),
        ActionRow(icon: Icons.inventory_2_outlined, title: 'Build your own gift box', subtitle: 'Choose up to ${context.app.config.giftMaxItems} favourites', onTap: () => go(context, R.giftBox)),
        ActionRow(icon: Icons.groups_outlined, title: 'Gift & bulk orders', subtitle: 'Weddings, festivals and corporate gifting', onTap: () => go(context, R.bulkEnquiry)),
        ActionRow(icon: Icons.public_rounded, title: 'Wholesale & export', subtitle: 'Request a tailored quotation', onTap: () => go(context, R.bulkEnquiry, args: 'export'), divider: false),
      ],
    );
  }
}

// ───────────────────────── 10 · Build a gift box ─────────────────────────
/// Same as the website's gift builder: add the box to the bag, or ask the shop for a custom quote.
class GiftBoxScreen extends StatefulWidget {
  const GiftBoxScreen({super.key});

  @override
  State<GiftBoxScreen> createState() => _GiftBoxScreenState();
}

class _GiftBoxScreenState extends State<GiftBoxScreen> {
  List<Product>? _products;
  String? _error;
  final Set<int> _picks = {};
  String? _packaging;
  final _message = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final list = await context.appRead.fetchProducts();
      if (!mounted) return;
      final pk = context.appRead.config.giftPackaging;
      setState(() {
        _products = list.where((p) => !p.soldOut).toList();
        _packaging ??= pk.isNotEmpty ? pk.first.key : null;
        _error = null;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  GiftPackaging? get _pack {
    for (final p in context.appRead.config.giftPackaging) {
      if (p.key == _packaging) return p;
    }
    return null;
  }

  double get _estimate {
    final chosen = (_products ?? const <Product>[]).where((p) => _picks.contains(p.id));
    return chosen.fold<double>(0, (s, p) => s + p.priceFor(null)) + (_pack?.price ?? 0);
  }

  void _addToBag() {
    final app = context.appRead;
    final chosen = (_products ?? const <Product>[]).where((p) => _picks.contains(p.id)).toList();
    for (final p in chosen) {
      final err = app.addProduct(p);
      if (err != null) {
        toast(context, err);
        return;
      }
    }
    final pack = _pack;
    if (pack != null && pack.productId != null) {
      // Packaging is an internal (unlisted) product on the website; add it as a simple line.
      app.addProduct(Product(id: pack.productId!, slug: pack.key, name: pack.label, price: pack.price, priceLabel: money(pack.price), unit: 'per box'));
    }
    if (_message.text.trim().isNotEmpty) app.setNote('Gift message: ${_message.text.trim()}');
    toast(context, 'Your gift box has been added to the bag');
    go(context, R.bag);
  }

  Future<void> _askQuote() async {
    final app = context.appRead;
    final name = TextEditingController(text: app.signedIn || app.guestName.isNotEmpty ? app.userName : '');
    final phone = TextEditingController(text: app.phone);
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 0, 24, MediaQuery.viewInsetsOf(ctx).bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Ask for a custom quote', style: T.display(28)),
          const Gap(6),
          Text('The shop will call you to confirm your gift box and price.', style: T.body()),
          UField(label: 'Your name', controller: name),
          UField(label: 'Mobile number', controller: phone, prefixText: '+91', keyboard: TextInputType.phone, formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)]),
          const Gap(18),
          PrimaryButton('Send to the shop', icon: null, onTap: () => Navigator.pop(ctx, true)),
        ]),
      ),
    );
    if (ok != true || !mounted) return;
    try {
      final msg = await app.sendEnquiry('gift', {
        'name': name.text.trim(),
        'phone': phone.text.trim(),
        if (app.email.isNotEmpty) 'email': app.email,
        'products': _picks.toList(),
        'packaging': _packaging,
        if (_message.text.trim().isNotEmpty) 'message': _message.text.trim(),
      });
      if (!mounted) return;
      await showSuccess(context, title: 'Gift selection saved', message: msg, cta: 'Back to gifting');
      if (mounted) Navigator.maybePop(context);
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cfg = context.app.config;
    final max = cfg.giftMaxItems;
    return UScaffold(
      title: 'Your box. Your story.',
      nav: NavKind.customer,
      navIndex: 1,
      bottom: Row(children: [
        Expanded(child: OutlineBtn('Custom quote', icon: null, onTap: _picks.isEmpty ? null : _askQuote)),
        const SizedBox(width: 10),
        Expanded(child: PrimaryButton('Add to bag', icon: null, onTap: _picks.isEmpty ? null : _addToBag)),
      ]),
      children: [
        const Eyebrow('Choose your sweets'),
        const Gap(10),
        const Headline('A little of\n*everything lovely.*', size: 34),
        const Gap(10),
        Row(children: [
          Pill('${_picks.length} of $max chosen', bg: AppColors.pink, fg: AppColors.berry),
          const Spacer(),
          Text('Estimated ${money(_estimate)}', style: T.sans(12, weight: FontWeight.w700)),
        ]),
        const Gap(12),
        GiftBanner(gifts: _picks.length.clamp(1, 4)),
        const Gap(8),
        if (_error != null)
          LoadState(error: _error, onRetry: _load)
        else if (_products == null)
          const LoadState(loading: true)
        else
          for (final p in _products!) _pickRow(p, max),
        if (cfg.giftPackaging.isNotEmpty)
          UPicker(
            label: 'Gift packaging',
            value: _pack == null ? 'Choose packaging' : '${_pack!.label} · ${money(_pack!.price)}',
            onTap: () async {
              final labels = {for (final g in cfg.giftPackaging) '${g.label} · ${money(g.price)}': g.key};
              final v = await pickOption(context, title: 'Gift packaging', options: labels.keys.toList());
              if (v != null) setState(() => _packaging = labels[v]);
            },
          ),
        UField(label: 'Your message (optional)', controller: _message, hint: 'A little sweetness, with all our love.', formatters: [LengthLimitingTextInputFormatter(200)]),
        const FinePrint('“Add to bag” buys the box now. “Custom quote” sends your selection to the shop, who will call you.'),
      ],
    );
  }

  Widget _pickRow(Product p, int max) {
    final picked = _picks.contains(p.id);
    return InkWell(
      onTap: () => setState(() {
        if (picked) {
          _picks.remove(p.id);
        } else if (_picks.length < max) {
          _picks.add(p.id);
        } else {
          toast(context, 'Choose up to $max sweets');
        }
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderSoft))),
        child: Row(children: [
          ClipRRect(borderRadius: BorderRadius.circular(12), child: NetImage(p.imageUrl, width: 60, height: 60, fallback: fallbackFor(p))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name, style: T.display(21)),
              Text('${p.labelFor(null)} · ${money(p.priceFor(null))}', style: T.tiny()),
            ]),
          ),
          Icon(picked ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded, color: picked ? AppColors.teal : AppColors.berry),
        ]),
      ),
    );
  }
}

// ───────────────────────── 11 · Bulk & wholesale enquiry ─────────────────────────
/// The website's "Bulk orders" and "Export" forms. [initialType] 'export' opens the export form.
class BulkEnquiryScreen extends StatelessWidget {
  final String? initialType;
  const BulkEnquiryScreen({super.key, this.initialType});

  @override
  Widget build(BuildContext context) {
    final t = (initialType ?? '').toLowerCase();
    return UScaffold(
      title: 'Celebrations, together',
      nav: NavKind.customer,
      navIndex: 1,
      children: [
        const Eyebrow('Gifting · Wholesale · Export'),
        const Gap(10),
        const Headline('Big occasions.\n*Thoughtful details.*', size: 34),
        const Gap(14),
        BulkEnquiryForm(export: t.contains('export') || t.contains('wholesale'), showToggle: true),
      ],
    );
  }
}

/// Same fields and rules as the website's bulk-orders form (and the export form).
/// Used on its own screen and inline on the Weddings / Corporate gifting tabs.
class BulkEnquiryForm extends StatefulWidget {
  final bool export;
  final bool showToggle;

  /// Pre-selected occasion, e.g. 'Wedding' or 'Corporate gifting'.
  final String? occasion;
  const BulkEnquiryForm({super.key, this.export = false, this.showToggle = false, this.occasion});

  @override
  State<BulkEnquiryForm> createState() => _BulkEnquiryFormState();
}

class _BulkEnquiryFormState extends State<BulkEnquiryForm> {
  late bool _export = widget.export;
  late final _name = TextEditingController(text: context.appRead.signedIn ? context.appRead.userName : context.appRead.guestName);
  late final _email = TextEditingController(text: context.appRead.email);
  late final _phone = TextEditingController(text: context.appRead.phone);
  final _qty = TextEditingController();
  final _company = TextEditingController();
  final _country = TextEditingController(text: 'India');
  final _message = TextEditingController();
  late String? _occasion = widget.occasion;
  String? _exportType;
  DateTime? _date;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _qty, _company, _country, _message]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _check() {
    if (_name.text.trim().isEmpty) return 'Please enter your name';
    if (!_email.text.contains('@')) return 'Please enter a valid email';
    if (_export) {
      if (_company.text.trim().isEmpty) return 'Please enter your company';
      if (_country.text.trim().isEmpty) return 'Please enter your country';
    } else {
      if (!RegExp(r'^[6-9]\d{9}$').hasMatch(_phone.text.replaceAll(RegExp(r'\D'), ''))) return 'Enter a valid 10-digit mobile number';
      if ((int.tryParse(_qty.text.trim()) ?? 0) < 1) return 'Please enter the estimated quantity';
      if (_date == null) return 'Please choose the event date';
    }
    if (_message.text.trim().isEmpty) return _export ? 'Please tell us about your requirement' : 'Please describe the products, packaging & delivery you need';
    return null;
  }

  Future<void> _send() async {
    final problem = _check();
    if (problem != null) {
      toast(context, problem);
      return;
    }
    final app = context.appRead;
    final cfg = app.config;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      final msg = _export
          ? await app.sendEnquiry('export', {
              'name': _name.text.trim(),
              'company': _company.text.trim(),
              'email': _email.text.trim(),
              'country': _country.text.trim(),
              'enquiry_type': _exportType ?? cfg.exportTypes.first,
              'message': _message.text.trim(),
            })
          : await app.sendEnquiry('bulk', {
              'name': _name.text.trim(),
              'email': _email.text.trim(),
              'phone': _phone.text.replaceAll(RegExp(r'\D'), ''),
              'occasion': _occasion ?? cfg.bulkOccasions.first,
              'quantity': int.parse(_qty.text.trim()),
              'event_date': isoDate(_date!),
              'message': _message.text.trim(),
            });
      if (!mounted) return;
      _message.clear();
      _qty.clear();
      await showSuccess(context, title: 'Enquiry sent', message: msg, cta: 'Done');
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cfg = context.app.config;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (widget.showToggle)
        ChipGroup(options: const ['Bulk / event order', 'Wholesale & export'], selected: _export ? 'Wholesale & export' : 'Bulk / event order', onSelected: (v) => setState(() => _export = v == 'Wholesale & export')),
      UField(label: 'Your name', controller: _name),
      UField(label: 'Email address', controller: _email, keyboard: TextInputType.emailAddress),
      if (!_export) ...[
        UField(label: 'Phone number', controller: _phone, prefixText: '+91', keyboard: TextInputType.phone, formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)]),
        UPicker(
          label: 'Occasion',
          value: _occasion ?? cfg.bulkOccasions.first,
          onTap: () async {
            final v = await pickOption(context, title: 'Occasion', options: cfg.bulkOccasions, selected: _occasion);
            if (v != null) setState(() => _occasion = v);
          },
        ),
        UField(label: 'Estimated quantity', controller: _qty, keyboard: TextInputType.number, formatters: [FilteringTextInputFormatter.digitsOnly]),
        UPicker(
          label: 'Event date',
          value: _date == null ? 'Choose a date' : dayMonth(_date!),
          icon: Icons.calendar_today_outlined,
          onTap: () async {
            final now = DateTime.now();
            final d = await pickDate(context, initial: _date ?? now.add(const Duration(days: 7)), first: DateTime(now.year, now.month, now.day), last: now.add(const Duration(days: 730)));
            if (d != null) setState(() => _date = d);
          },
        ),
      ] else ...[
        UField(label: 'Company', controller: _company),
        UField(label: 'Country', controller: _country),
        UPicker(
          label: 'Enquiry type',
          value: _exportType ?? cfg.exportTypes.first,
          onTap: () async {
            final v = await pickOption(context, title: 'Enquiry type', options: cfg.exportTypes, selected: _exportType);
            if (v != null) setState(() => _exportType = v);
          },
        ),
      ],
      UField(
        label: _export ? 'Tell us about your requirement' : 'Products, packaging & delivery requirements',
        controller: _message,
        maxLines: 4,
        formatters: [LengthLimitingTextInputFormatter(2000)],
      ),
      const Gap(16),
      PrimaryButton(_busy ? 'Sending…' : 'Send enquiry', onTap: _busy ? null : _send),
      const Gap(12),
      const Note('Our team will confirm availability, lead time and a personalised quotation.'),
    ]);
  }
}
