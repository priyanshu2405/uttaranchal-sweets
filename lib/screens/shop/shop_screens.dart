import 'package:flutter/material.dart';

import '../../app/nav.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
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
  String _chip = 'Mithai';

  List<Product> get _items => switch (_chip) {
        'Snacks' => Catalog.inCategory(Category.snacks),
        'Gifts' => [Catalog.byId('kaju-katli'), Catalog.byId('motichoor-laddoo')],
        _ => Catalog.inCategory(Category.sweets),
      };

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return UScaffold(
      nav: NavKind.customer,
      navIndex: 0,
      header: _HomeHeader(area: '${app.area}, ${app.city.split(',').first}'),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      children: [
        USearchBox(hint: 'Search mithai, milk & more', onTap: () => go(context, R.search)),
        const Gap(14),
        // Hero
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
        const Gap(10),
        ColorBlock(
          color: AppColors.teal,
          onTap: () => goTab(context, R.milkHub),
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('YOUR  MORNING,  SORTED', style: T.sans(9.5, color: AppColors.white, weight: FontWeight.w700, spacing: 1.2)),
                const Gap(8),
                Text('Fresh milk. At your door.', style: T.display(23, color: AppColors.white)),
                const Gap(4),
                Text(app.milkPlanActive ? 'Next delivery tomorrow · ${app.milkLitres} L, 6–7 AM' : 'Start or manage your daily delivery.',
                    style: T.sans(11, color: AppColors.white)),
              ]),
            ),
            const IconTileButton(Icons.north_east_rounded),
          ]),
        ),
        const Gap(14),
        Row(children: [
          Expanded(child: ChipGroup(options: const ['Mithai', 'Snacks', 'Gifts'], selected: _chip, scroll: true, onSelected: (v) => setState(() => _chip = v))),
          GestureDetector(
            onTap: () => goTab(context, R.rewards),
            child: Pill('${grouped(app.points)} pts', bg: AppColors.pink, fg: AppColors.berry, icon: Icons.star_rounded),
          ),
        ]),
        const Gap(18),
        SectionTitle(_chip == 'Gifts' ? 'Gifts with heart' : 'Little boxes of joy', action: 'View all', onAction: () => goTab(context, R.collection)),
        const Gap(12),
        AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: ProductGrid(_items.take(4).toList(), key: ValueKey(_chip))),
        const Gap(6),
        ActionRow(icon: Icons.card_giftcard_rounded, title: 'Festive gifting', subtitle: 'Thoughtful boxes for every occasion', onTap: () => go(context, R.gifting)),
        ActionRow(icon: Icons.receipt_long_outlined, title: 'Your orders', subtitle: 'Track #UDS1048 · arriving today', onTap: () => go(context, R.orderHistory)),
        ActionRow(icon: Icons.landscape_outlined, title: 'Our story', subtitle: '27 years of sweet beginnings', onTap: () => go(context, R.story), divider: false),
      ],
    );
  }
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
            IconTileButton(Icons.notifications_none_rounded, dot: true, onTap: () => go(context, R.notifications)),
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
  Category _cat = Category.sweets;
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final items = Catalog.inCategory(_cat).where((p) => p.matches(_q)).toList();
    return UScaffold(
      title: 'The collection',
      nav: NavKind.customer,
      navIndex: 1,
      children: [
        USearchBox(hint: 'Find your favourite', onChanged: (v) => setState(() => _q = v)),
        const Gap(14),
        ChipGroup(
          options: Category.values.map((c) => c.label).toList(),
          selected: _cat.label,
          scroll: true,
          onSelected: (v) => setState(() => _cat = Category.values.firstWhere((c) => c.label == v)),
        ),
        const Gap(14),
        Row(children: [
          Expanded(child: Text('Made for your sweet moments.', style: T.sans(12, color: AppColors.muted))),
          const Pill('Pure vegetarian'),
        ]),
        const Gap(16),
        SectionTitle(_cat.heading),
        const Gap(12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: items.isEmpty
              ? Padding(
                  key: const ValueKey('empty'),
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: Text('No sweets match “$_q” here yet.', style: T.body())),
                )
              : ProductGrid(items, key: ValueKey('${_cat.name}$_q')),
        ),
        const Gap(4),
        ActionRow(icon: Icons.card_giftcard_rounded, title: 'Build your own gift box', subtitle: 'Choose 4 favourites · From ₹899', onTap: () => go(context, R.giftBox), divider: false),
      ],
    );
  }
}

// ───────────────────────── 07 · Product details ─────────────────────────
class ProductScreen extends StatefulWidget {
  final String? productId;
  const ProductScreen({super.key, this.productId});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  late final Product p = Catalog.byId(widget.productId);
  late String _weight = p.defaultWeight;
  int _qty = 1;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final unit = p.hasWeights ? p.priceFor(_weight) : p.price500g;
    final total = unit * _qty;
    final fav = app.favourites.contains(p.id);
    return UScaffold(
      title: 'Crafted with care',
      nav: NavKind.customer,
      navIndex: 1,
      bottom: PrimaryButton(
        'Add to bag · ${rupees(total)}',
        icon: Icons.add_rounded,
        onTap: () {
          addToBag(context, p, weight: p.hasWeights ? _weight : null, qty: _qty);
          go(context, R.bag);
        },
      ),
      children: [
        Hero(
          tag: 'product-${p.id}',
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(70), bottom: Radius.circular(18)),
            child: AspectRatio(aspectRatio: 1.65, child: Image.asset(p.image, fit: BoxFit.cover)),
          ),
        ),
        const Gap(16),
        Row(children: [
          if (p.bestseller) const Pill('Bestseller', bg: AppColors.pink, fg: AppColors.berry),
          const Spacer(),
          IconTileButton(
            fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            onTap: () {
              context.appRead.toggleFavourite(p.id);
              toast(context, fav ? 'Removed from favourites' : 'Saved to favourites');
            },
          ),
        ]),
        Text(p.name, style: T.display(38)),
        const Gap(6),
        Row(children: [
          ...List.generate(5, (i) => Icon(i < p.rating.round() ? Icons.star_rounded : Icons.star_outline_rounded, size: 14, color: const Color(0xFFC58A27))),
          const SizedBox(width: 8),
          Text('${p.rating} · ${p.reviews} reviews', style: T.sans(12, color: AppColors.muted)),
        ]),
        const Gap(10),
        BodyText(p.description),
        const Gap(14),
        if (p.hasWeights) ChipGroup(options: Catalog.weights, selected: _weight, onSelected: (v) => setState(() => _weight = v)),
        if (!p.hasWeights) Pill(p.defaultWeight, bg: AppColors.peach, fg: AppColors.ink),
        const Gap(16),
        Row(children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (c, a) => FadeTransition(opacity: a, child: SlideTransition(position: Tween(begin: const Offset(0, .3), end: Offset.zero).animate(a), child: c)),
            child: Text(rupees(unit), key: ValueKey(unit), style: T.display(30, color: AppColors.teal, weight: FontWeight.w700)),
          ),
          const Spacer(),
          QtyStepper(value: _qty, min: 1, max: 20, onChanged: (v) => setState(() => _qty = v)),
        ]),
        const Gap(14),
        UCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Column(children: [
            KV('Ingredients', p.ingredients),
            KV('Allergens', p.allergens),
            const KV('Storage & shelf life', 'See pack instructions'),
          ]),
        ),
        FinePrint('Earn ${(total / 10).floor()} points after delivery. Delivery availability checked at checkout.'),
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
  final _c = TextEditingController(text: 'Mithai');

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _set(String v) {
    _c.text = v;
    _c.selection = TextSelection.collapsed(offset: v.length);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final q = _c.text;
    final results = Catalog.products.where((p) => p.matches(q)).take(4).toList();
    return UScaffold(
      title: 'Find your favourites',
      nav: NavKind.customer,
      navIndex: 1,
      children: [
        USearchBox(hint: 'Search mithai, milk & more', controller: _c, onChanged: (_) => setState(() {})),
        const Gap(14),
        const Eyebrow('Trending searches'),
        const Gap(10),
        ChipGroup(options: const ['Bal Mithai', 'Gift boxes', 'Fresh milk', 'Namkeen'], selected: q, onSelected: (v) {
          if (v == 'Fresh milk') {
            goTab(context, R.milkHub);
          } else if (v == 'Gift boxes') {
            go(context, R.gifting);
          } else {
            _set(v);
          }
        }),
        const Gap(18),
        const SectionTitle('A little inspiration'),
        const Gap(12),
        results.isEmpty
            ? Padding(padding: const EdgeInsets.symmetric(vertical: 30), child: Center(child: Text('Nothing found for “$q”. Try “Kaju” or “Milk”.', style: T.body())))
            : ProductGrid(results),
        ActionRow(icon: Icons.local_drink_outlined, title: 'Fresh milk subscriptions', subtitle: 'A fresh start, every morning', onTap: () => goTab(context, R.milkHub)),
        ActionRow(icon: Icons.card_giftcard_rounded, title: 'Festive gifting', subtitle: 'Thoughtful boxes for every occasion', onTap: () => go(context, R.gifting)),
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
    'Weddings': ('Shagun & celebrations', 'Sweetness for every guest.', 'Custom boxes, names and ribbons for your big day.'),
    'Corporate': ('Teams & clients', 'Thank-yous that taste good.', 'Branded sleeves, bulk pricing and doorstep delivery.'),
  };

  @override
  Widget build(BuildContext context) {
    final c = _copy[_occasion]!;
    return UScaffold(
      title: 'Gifts with heart',
      nav: NavKind.customer,
      navIndex: 1,
      bottom: PrimaryButton('Create a gift box', onTap: () => go(context, R.giftBox)),
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
        const Gap(8),
        ActionRow(icon: Icons.inventory_2_outlined, title: 'Build your own gift box', subtitle: 'Choose 4 favourites · From ₹899', onTap: () => go(context, R.giftBox)),
        ActionRow(icon: Icons.groups_outlined, title: 'Gift & bulk orders', subtitle: 'Weddings, events and corporate gifting', onTap: () => go(context, R.bulkEnquiry)),
        ActionRow(icon: Icons.public_rounded, title: 'Wholesale & export', subtitle: 'Request a tailored quotation', onTap: () => go(context, R.bulkEnquiry, args: 'Wholesale / export')),
      ],
    );
  }
}

// ───────────────────────── 10 · Build a gift box ─────────────────────────
class GiftBoxScreen extends StatefulWidget {
  const GiftBoxScreen({super.key});

  @override
  State<GiftBoxScreen> createState() => _GiftBoxScreenState();
}

class _GiftBoxScreenState extends State<GiftBoxScreen> {
  static const _max = 4;
  final Map<String, int> _picks = {'kaju-katli': 1, 'bal-mithai': 1, 'milk-cake': 0, 'motichoor-laddoo': 0};
  String _packaging = 'Festive rani pink · Included';

  int get _count => _picks.values.fold(0, (a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    return UScaffold(
      title: 'Your box. Your story.',
      nav: NavKind.customer,
      navIndex: 1,
      bottom: PrimaryButton(
        'Save gift box & continue',
        onTap: _count == 0
            ? null
            : () {
                context.appRead.addGiftBox(items: _count, packaging: _packaging.split(' · ').first);
                toast(context, 'Gift box added to your bag');
                go(context, R.bag);
              },
      ),
      children: [
        const Eyebrow('Step 1 of 3 · Choose your sweets'),
        const Gap(10),
        const Headline('A little of\n*everything lovely.*', size: 34),
        const Gap(10),
        Row(children: [
          Pill('$_count of $_max selections added', bg: AppColors.pink, fg: AppColors.berry),
          const Spacer(),
          Text('500 g box', style: T.sans(11, color: AppColors.muted)),
        ]),
        const Gap(12),
        GiftBanner(gifts: _count.clamp(1, 4)),
        const Gap(8),
        for (final id in _picks.keys) _pickRow(Catalog.byId(id)),
        UPicker(
          label: 'Gift packaging',
          value: _packaging,
          onTap: () async {
            final v = await pickOption(context,
                title: 'Gift packaging', options: const ['Festive rani pink · Included', 'Classic ivory & gold · Included', 'Kraft eco box · Included'], selected: _packaging);
            if (v != null) setState(() => _packaging = v);
          },
        ),
        const UField(label: 'Your message', initial: 'A little sweetness, with all our love.'),
        const FinePrint('Next: select the remaining sweets and recipient details.'),
      ],
    );
  }

  Widget _pickRow(Product p) {
    final n = _picks[p.id]!;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderSoft))),
      child: Row(children: [
        ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset(p.image, width: 60, height: 60, fit: BoxFit.cover)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.name, style: T.display(21)),
            Text(n > 0 ? '125 g · Selected' : '125 g', style: T.tiny()),
            const Gap(4),
            Text(n > 0 ? 'Included' : 'Tap + to add', style: T.sans(11.5, weight: FontWeight.w700, color: n > 0 ? AppColors.ink : AppColors.muted)),
          ]),
        ),
        QtyStepper(
          value: n,
          max: n + (_max - _count),
          onChanged: (v) => setState(() => _picks[p.id] = v),
        ),
      ]),
    );
  }
}

// ───────────────────────── 11 · Bulk & wholesale enquiry ─────────────────────────
class BulkEnquiryScreen extends StatefulWidget {
  final String? initialType;
  const BulkEnquiryScreen({super.key, this.initialType});

  @override
  State<BulkEnquiryScreen> createState() => _BulkEnquiryScreenState();
}

class _BulkEnquiryScreenState extends State<BulkEnquiryScreen> {
  late String _type = widget.initialType ?? 'Wedding / event gifting';
  DateTime _date = DateTime(2026, 11, 15);
  String _budget = '₹900–₹1,200';

  @override
  Widget build(BuildContext context) {
    return UScaffold(
      title: 'Celebrations, together',
      nav: NavKind.customer,
      navIndex: 1,
      bottom: PrimaryButton(
        'Prepare enquiry',
        onTap: () async {
          await showProcessing(context, 'Preparing your enquiry…', duration: const Duration(milliseconds: 900));
          if (!context.mounted) return;
          await showSuccess(context,
              title: 'Enquiry ready',
              message: 'Our gifting team will call you within one working day with availability and a personalised quotation.',
              cta: 'Back to gifting');
          if (context.mounted) Navigator.maybePop(context);
        },
      ),
      children: [
        const Eyebrow('Gifting · Wholesale · Export'),
        const Gap(10),
        const Headline('Big occasions.\n*Thoughtful details.*', size: 34),
        UPicker(
          label: 'Enquiry type',
          value: _type,
          onTap: () async {
            final v = await pickOption(context,
                title: 'Enquiry type', options: const ['Wedding / event gifting', 'Corporate gifting', 'Wholesale / export', 'Festival bulk order'], selected: _type);
            if (v != null) setState(() => _type = v);
          },
        ),
        UField(label: 'Your name / business', initial: context.appRead.userName),
        const UField(label: 'Quantity required', initial: '100 boxes'),
        UPicker(
          label: 'Delivery date',
          value: isoDate(_date),
          icon: Icons.calendar_today_outlined,
          onTap: () async {
            final d = await pickDate(context, initial: _date, first: DateTime(2026, 11, 1));
            if (d != null) setState(() => _date = d);
          },
        ),
        const UField(label: 'City / country', initial: 'Kashipur, India'),
        UPicker(
          label: 'Budget per box',
          value: _budget,
          onTap: () async {
            final v = await pickOption(context, title: 'Budget per box', options: const ['Under ₹500', '₹500–₹900', '₹900–₹1,200', '₹1,200+'], selected: _budget);
            if (v != null) setState(() => _budget = v);
          },
        ),
        const Gap(16),
        const Note('Our team will confirm availability, product suitability, lead time and a personalised quotation.'),
      ],
    );
  }
}
