import 'package:flutter/material.dart';

import '../../app/nav.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../data/api.dart';
import '../../data/catalog.dart';
import '../../data/payments.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';
import '../../widgets/fields.dart';
import '../../widgets/illustrations.dart';
import '../../widgets/product_widgets.dart';
import '../../widgets/u_scaffold.dart';

const _weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// Milk plans belong to an account, so the milk screens ask guests to sign in first.
Widget? _needsAccount(BuildContext context, {String title = 'Fresh milk, every day'}) {
  if (context.app.signedIn) return null;
  return UScaffold(title: title, nav: NavKind.customer, navIndex: 2, children: [
    const MilkHero(),
    const Gap(16),
    const Headline('Sign in to start\nyour *milk plan.*'),
    const Gap(10),
    const BodyText('Milk plans are linked to your account, so your balance, deliveries and pauses are kept safe.'),
    const Gap(18),
    PrimaryButton('Sign in', onTap: () => go(context, R.signIn)),
    const Gap(10),
    OutlineBtn('Create an account', icon: null, onTap: () => go(context, R.verify)),
  ]);
}

void _snack(BuildContext context, Object e) => toast(context, e is ApiException ? e.message : 'Something went wrong. Please try again.');

// ───────────────────────── 20 · Milk hub ─────────────────────────
class MilkHubScreen extends StatefulWidget {
  const MilkHubScreen({super.key});

  @override
  State<MilkHubScreen> createState() => _MilkHubScreenState();
}

class _MilkHubScreenState extends State<MilkHubScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.appRead.loadMilk());
  }

  @override
  Widget build(BuildContext context) {
    final guest = _needsAccount(context);
    if (guest != null) return guest;
    final app = context.app;
    final p = app.milkPlan;
    final cfg = app.milkConfig;
    return UScaffold(
      title: 'Fresh milk, every day',
      nav: NavKind.customer,
      navIndex: 2,
      trailing: IconTileButton(Icons.refresh_rounded, onTap: () => context.appRead.loadMilk()),
      children: [
        const Eyebrow('Good mornings begin here'),
        const Gap(10),
        const Headline('From our dairy.\nTo your *doorstep.*'),
        const Gap(16),
        if (!app.milkLoaded && app.milkLoading)
          const LoadState(loading: true)
        else if (app.milkError != null && !app.milkLoaded)
          LoadState(error: app.milkError, onRetry: () => context.appRead.loadMilk())
        else ...[
          MilkHero(onTap: () => go(context, R.milkProduct)),
          const Gap(10),
          ColorBlock(
            color: p?.awaitingPayment == true ? AppColors.berry : AppColors.teal,
            onTap: () => go(context, p == null ? R.milkProduct : (p.awaitingPayment ? R.milkPayment : R.milkActive)),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p == null ? 'NO  ACTIVE  PLAN' : p.statusLabel.toUpperCase(), style: T.sans(9.5, color: AppColors.white, weight: FontWeight.w700, spacing: 1.2)),
                  const Gap(8),
                  Text(p == null ? 'Start your mornings fresh' : '${p.litres} L · ${p.frequencyLabel}', style: T.display(26, color: AppColors.white)),
                  const Gap(6),
                  Text(
                    p == null
                        ? 'Choose your quantity, days and time'
                        : p.awaitingPayment
                            ? 'Pay ${money(p.firstPayment)} to start your deliveries'
                            : p.nextDelivery != null
                                ? 'Next delivery ${dayMonth(p.nextDelivery!)} · ${p.slotLabel}'
                                : p.slotLabel,
                    style: T.sans(11, color: AppColors.white),
                  ),
                ]),
              ),
              const IconTileButton(Icons.north_east_rounded),
            ]),
          ),
          if (p != null && p.lowBalance) ...[
            const Gap(10),
            Note('Your milk balance is running low (${money(p.balance)}). Top up to keep deliveries coming.'),
          ],
          const Gap(12),
          Row(children: [
            SmallButton(p == null ? 'Start a milk plan' : (p.awaitingPayment ? 'Complete payment' : 'Manage my plan'),
                onTap: () => go(context, p == null ? R.milkProduct : (p.awaitingPayment ? R.milkPayment : R.milkActive))),
            const Spacer(),
            if (p?.isActive == true) SmallButton('Delivery calendar', filled: false, onTap: () => go(context, R.milkCalendar)),
          ]),
          const Gap(20),
          const SectionTitle('Made for your routine'),
          const Gap(12),
          StatPair(
            StatCard(money(cfg.pricePerLitre), '${cfg.productName} / litre'),
            StatCard(money(p?.balance ?? 0), 'Prepaid milk balance'),
          ),
          if (p?.isActive == true) ...[
            ActionRow(icon: Icons.account_balance_wallet_outlined, title: 'Top up your milk balance', subtitle: 'Keep your mornings uninterrupted', onTap: () => go(context, R.milkTopUp)),
            ActionRow(icon: Icons.verified_outlined, title: 'Deliveries', subtitle: p!.today != null ? 'Today: ${p.today!.statusLabel}' : 'Recent deliveries and details', onTap: () => go(context, R.milkProof)),
            ActionRow(icon: Icons.pause_circle_outline_rounded, title: 'Pause or skip a delivery', subtitle: 'Before ${cfg.cutoffText} the evening before', onTap: () => go(context, R.milkPause), divider: false),
          ] else if (p == null)
            const Note('Pick every day, alternate days or just the days you want — then pay for your first month to start.', tone: NoteTone.mint),
        ],
      ],
    );
  }
}

// ───────────────────────── 21 · Milk product ─────────────────────────
class MilkProductScreen extends StatelessWidget {
  const MilkProductScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cfg = context.app.milkConfig;
    return UScaffold(
      title: 'Freshness, bottled',
      nav: NavKind.customer,
      navIndex: 2,
      bottom: PrimaryButton(
        context.app.milkPlan == null ? 'Build my milk plan' : 'Change my milk plan',
        onTap: () {
          if (!context.appRead.signedIn) {
            go(context, R.signIn);
            return;
          }
          context.appRead.startMilkDraft(edit: context.appRead.milkPlan != null);
          go(context, R.milkConfigure);
        },
      ),
      children: [
        const MilkHero(),
        const Gap(14),
        const Row(children: [
          Pill('Local delivery only'),
          Spacer(),
          Pill('1 L bottles', bg: AppColors.peach, fg: AppColors.ink),
        ]),
        const Gap(14),
        Text(cfg.productName, style: T.display(36)),
        const Gap(8),
        const BodyText('Fresh dairy for your morning chai, family breakfasts and everyday rituals.'),
        const Gap(12),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(money(cfg.pricePerLitre), style: T.display(32, color: AppColors.teal, weight: FontWeight.w700)),
          Padding(padding: const EdgeInsets.only(bottom: 6, left: 4), child: Text('/ litre', style: T.sans(12, color: AppColors.teal, weight: FontWeight.w600))),
        ]),
        const Gap(12),
        UCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Column(children: [
            const KV('Delivered locally', 'Kashipur service areas'),
            const KV('Storage', 'Keep refrigerated'),
            KV('Changes', 'Skip or pause before ${cfg.cutoffText} the evening before'),
          ]),
        ),
        const FinePrint('You pay for your first month up front. Each delivery is then charged from your milk balance; skipped days are free.'),
      ],
    );
  }
}

// ───────────────────────── 22 · Configure milk plan ─────────────────────────
class MilkConfigureScreen extends StatelessWidget {
  const MilkConfigureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final guest = _needsAccount(context, title: 'Make mornings yours');
    if (guest != null) return guest;
    final app = context.app;
    final cfg = app.milkConfig;
    final qtyLabel = app.milkLitres == 0 ? '' : (app.milkLitres <= 3 ? '${app.milkLitres} L' : 'Custom');
    final freq = app.milkFrequency;
    final canMoveStart = !app.milkEditing || app.milkPlan!.awaitingPayment || app.milkPlan!.startDate.isAfter(DateTime.now());
    return UScaffold(
      title: app.milkEditing ? 'Change your plan' : 'Make mornings yours',
      nav: NavKind.customer,
      navIndex: 2,
      bottom: PrimaryButton(
        'Review my plan',
        onTap: () {
          final problem = app.milkLitres == 0
              ? 'Choose how much milk you need'
              : freq == null
                  ? 'Choose how often you want milk'
                  : (freq == 'custom' && app.milkWeekdays.isEmpty && app.milkExtraDates.isEmpty)
                      ? 'Pick your delivery days'
                      : app.milkSlot == null
                          ? 'Choose a delivery time'
                          : null;
          if (problem != null) {
            toast(context, problem);
            return;
          }
          go(context, R.milkReview);
        },
      ),
      children: [
        const Eyebrow('Your milk plan'),
        const Gap(10),
        const Headline('Just the way\nyour family *likes it.*'),
        const Gap(16),
        UCard(
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(cfg.productName, style: T.display(24)),
                const Gap(6),
                Text('${money(cfg.pricePerLitre)} per litre', style: T.sans(12)),
              ]),
            ),
            const MilkBottle(height: 70),
          ]),
        ),
        const Gap(18),
        const Eyebrow('1 · Daily quantity'),
        const Gap(10),
        ChipGroup(
          options: const ['1 L', '2 L', '3 L', 'Custom'],
          selected: qtyLabel,
          onSelected: (v) async {
            if (v == 'Custom') {
              final n = await _customQty(context, app.milkLitres, cfg.maxLitres);
              if (n != null && context.mounted) context.appRead.configureMilk(litres: n);
            } else {
              context.appRead.configureMilk(litres: int.parse(v.split(' ').first));
            }
          },
        ),
        if (qtyLabel == 'Custom') Padding(padding: const EdgeInsets.only(top: 8), child: Text('${app.milkLitres} litres per delivery', style: T.small(AppColors.teal))),
        const Gap(18),
        const Eyebrow('2 · How often'),
        const Gap(10),
        ChipGroup(
          options: cfg.frequencies.map((f) => f.label).toList(),
          selected: freq == null ? '' : cfg.frequencyLabel(freq),
          onSelected: (v) => context.appRead.configureMilk(frequency: cfg.frequencies.firstWhere((f) => f.label == v).key),
        ),
        if (freq == 'daily' && canMoveStart)
          UPicker(
            label: 'First delivery',
            value: dayMonth(app.milkStart),
            icon: Icons.calendar_today_outlined,
            onTap: () async {
              final now = DateTime.now();
              final d = await pickDate(context, initial: app.milkStart, first: DateTime(now.year, now.month, now.day).add(const Duration(days: 1)), last: now.add(const Duration(days: 90)));
              if (d != null && context.mounted) context.appRead.configureMilk(start: d);
            },
          ),
        if (freq == 'alternate') ...[
          const Gap(12),
          Note(canMoveStart ? 'Tap the date of your first delivery. We’ll come every other day from then.' : 'Every other day, continuing your current pattern.', tone: NoteTone.mint),
          const Gap(10),
          MilkPlanCalendar(mode: canMoveStart ? MilkCalendarMode.alternate : MilkCalendarMode.view),
        ],
        if (freq == 'custom') ...[
          const Gap(14),
          Text('Repeat every week on', style: T.sans(12, weight: FontWeight.w600)),
          const Gap(8),
          Row(children: [
            for (var w = 1; w <= 7; w++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: _WeekdayChip(weekday: w, selected: app.milkWeekdays.contains(w), onTap: () => context.appRead.toggleMilkWeekday(w)),
                ),
              ),
          ]),
          if (!app.milkEditing) ...[
            const Gap(12),
            const Note('Then tap any date on the calendar to add or remove just that day.', tone: NoteTone.mint),
            const Gap(10),
            const MilkPlanCalendar(mode: MilkCalendarMode.select),
          ],
        ],
        const Gap(6),
        const Eyebrow('3 · Delivery time'),
        UPicker(
          label: 'Delivery slot',
          value: app.milkSlot == null ? 'Choose a time' : cfg.slotLabel(app.milkSlot),
          icon: Icons.schedule_rounded,
          onTap: () async {
            final labels = {for (final s in cfg.slots) s.label: s.key};
            final v = await pickOption(context, title: 'Delivery slot', options: labels.keys.toList(), selected: app.milkSlot == null ? null : cfg.slotLabel(app.milkSlot));
            if (v != null && context.mounted) context.appRead.configureMilk(slot: labels[v]);
          },
        ),
        const Gap(16),
        if (app.milkLitres > 0 && freq != null && !app.milkEditing)
          ColorBlock(
            color: AppColors.yellow,
            child: Column(children: [
              KV('Per delivery', money(app.perDelivery)),
              KV('Deliveries in first ${cfg.firstPaymentDays} days', '${app.milkDeliveriesFirstMonth}'),
              const Gap(4),
              KV('First payment', money(app.milkFirstPayment), strong: true),
            ]),
          ),
        if (app.milkEditing) Note('Changes apply from the next day that can still be changed (before ${cfg.cutoffText} the evening before).'),
      ],
    );
  }

  Future<int?> _customQty(BuildContext context, int current, int max) {
    var n = current < 4 ? 4 : current;
    return showModalBottomSheet<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('Custom quantity', style: T.display(28)),
              const Gap(16),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                QtyStepper(value: n, min: 1, max: max, onChanged: (v) => set(() => n = v)),
                const SizedBox(width: 12),
                Text('litres / delivery', style: T.sans(14)),
              ]),
              const Gap(20),
              PrimaryButton('Use $n litres', icon: null, onTap: () => Navigator.pop(ctx, n)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _WeekdayChip extends StatelessWidget {
  final int weekday;
  final bool selected;
  final VoidCallback onTap;
  const _WeekdayChip({required this.weekday, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.teal : AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: selected ? AppColors.teal : AppColors.border)),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: SizedBox(
          height: 40,
          child: Center(child: Text(_weekdayNames[weekday - 1], style: T.sans(11, weight: FontWeight.w600, color: selected ? AppColors.white : AppColors.ink))),
        ),
      ),
    );
  }
}

enum MilkCalendarMode { alternate, select, view }

/// Month calendar for the plan being built.
/// alternate: tap = first delivery date (every other day highlighted). select: tap = add/remove that date.
class MilkPlanCalendar extends StatefulWidget {
  final MilkCalendarMode mode;
  const MilkPlanCalendar({super.key, required this.mode});

  @override
  State<MilkPlanCalendar> createState() => _MilkPlanCalendarState();
}

class _MilkPlanCalendarState extends State<MilkPlanCalendar> {
  late DateTime _month = DateTime(context.appRead.milkStart.year, context.appRead.milkStart.month);

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    final lastDay = tomorrow.add(const Duration(days: 90));
    return _MonthGrid(
      month: _month,
      canBack: DateTime(_month.year, _month.month).isAfter(DateTime(tomorrow.year, tomorrow.month)),
      canNext: DateTime(_month.year, _month.month + 1).isBefore(lastDay),
      onMonth: (m) => setState(() => _month = m),
      legend: [if (widget.mode == MilkCalendarMode.alternate) (AppColors.berry, 'First delivery'), (AppColors.teal, 'Milk delivered')],
      cell: (d) {
        final selectable = widget.mode != MilkCalendarMode.view && !d.isBefore(tomorrow) && !d.isAfter(lastDay);
        final on = app.milkDeliversOn(d);
        final isStart = widget.mode == MilkCalendarMode.alternate && d == app.milkStart;
        return _DayDot(
          day: d.day,
          bg: isStart ? AppColors.berry : (on ? AppColors.teal : AppColors.surface),
          fg: on || isStart ? AppColors.white : (selectable ? AppColors.ink : AppColors.border),
          border: on || isStart ? Colors.transparent : (selectable ? AppColors.border : AppColors.borderSoft),
          onTap: !selectable ? null : () => widget.mode == MilkCalendarMode.alternate ? context.appRead.configureMilk(start: d) : context.appRead.toggleMilkDate(d),
        );
      },
    );
  }
}

/// Shared month grid (Monday first).
class _MonthGrid extends StatelessWidget {
  final DateTime month;
  final bool canBack;
  final bool canNext;
  final ValueChanged<DateTime> onMonth;
  final Widget Function(DateTime day) cell;
  final List<(Color, String)> legend;
  const _MonthGrid({required this.month, required this.canBack, required this.canNext, required this.onMonth, required this.cell, this.legend = const []});

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final cells = <DateTime?>[...List.filled(first.weekday - 1, null), for (var d = 1; d <= daysInMonth; d++) DateTime(month.year, month.month, d)];
    return UCard(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 12),
      child: Column(children: [
        Row(children: [
          IconButton(onPressed: canBack ? () => onMonth(DateTime(month.year, month.month - 1)) : null, icon: const Icon(Icons.chevron_left_rounded)),
          Expanded(child: Center(child: Text('${monthName(month.month)} ${month.year}', style: T.display(22)))),
          IconButton(onPressed: canNext ? () => onMonth(DateTime(month.year, month.month + 1)) : null, icon: const Icon(Icons.chevron_right_rounded)),
        ]),
        Row(children: [for (final w in const ['M', 'T', 'W', 'T', 'F', 'S', 'S']) Expanded(child: Center(child: Text(w, style: T.sans(10.5, color: AppColors.muted))))]),
        const Gap(6),
        for (var r = 0; r < (cells.length / 7).ceil(); r++)
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(children: [
              for (var c = 0; c < 7; c++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: () {
                      final i = r * 7 + c;
                      final d = i < cells.length ? cells[i] : null;
                      return d == null ? const SizedBox(height: 34) : cell(d);
                    }(),
                  ),
                ),
            ]),
          ),
        if (legend.isNotEmpty) ...[
          const Gap(4),
          Wrap(spacing: 14, runSpacing: 6, children: [
            for (final (c, t) in legend)
              Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 5),
                Text(t, style: T.tiny(c)),
              ]),
          ]),
        ],
      ]),
    );
  }
}

class _DayDot extends StatelessWidget {
  final int day;
  final Color bg;
  final Color fg;
  final Color border;
  final VoidCallback? onTap;
  final bool strike;
  final bool outline;
  const _DayDot({required this.day, required this.bg, required this.fg, required this.border, this.onTap, this.strike = false, this.outline = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: outline ? AppColors.berry : border, width: outline ? 1.8 : 1),
        ),
        child: Text('$day', style: T.sans(11.5, weight: FontWeight.w600, color: fg).copyWith(decoration: strike ? TextDecoration.lineThrough : null)),
      ),
    );
  }
}

// ───────────────────────── 23 · Review ─────────────────────────
class MilkReviewScreen extends StatefulWidget {
  const MilkReviewScreen({super.key});

  @override
  State<MilkReviewScreen> createState() => _MilkReviewScreenState();
}

class _MilkReviewScreenState extends State<MilkReviewScreen> {
  bool _busy = false;

  Future<void> _save() async {
    final app = context.appRead;
    if (!app.hasAddress) {
      toast(context, 'Please add your delivery address first');
      go(context, R.location, args: 'edit');
      return;
    }
    setState(() => _busy = true);
    try {
      final editing = app.milkEditing;
      final plan = await app.saveMilkDraft();
      if (!mounted) return;
      if (editing && !plan.awaitingPayment) {
        toast(context, 'Your milk plan has been updated');
        Navigator.of(context).popUntil((r) => r.settings.name == R.milkActive || r.settings.name == R.milkHub || r.isFirst);
      } else {
        goReplace(context, R.milkPayment);
      }
    } catch (e) {
      if (mounted) _snack(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final cfg = app.milkConfig;
    final editing = app.milkEditing;
    return UScaffold(
      title: 'Your fresh start',
      nav: NavKind.customer,
      navIndex: 2,
      bottom: PrimaryButton(
        _busy ? 'Saving…' : (editing ? 'Save changes' : 'Continue to payment · ${money(app.milkFirstPayment)}'),
        onTap: _busy || !app.milkPlanComplete ? null : _save,
      ),
      children: [
        Eyebrow(editing ? 'Check your changes' : 'Review your milk plan'),
        const Gap(10),
        const Headline('A routine worth\n*waking up for.*'),
        const Gap(16),
        ColorBlock(
          color: AppColors.teal,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(cfg.productName, style: T.display(26, color: AppColors.white)),
            const Gap(6),
            Text('${app.milkLitres} litre${app.milkLitres == 1 ? '' : 's'} · ${app.milkScheduleText} · ${money(app.perDelivery)} per delivery', style: T.sans(11.5, color: AppColors.white)),
            const Divider(color: Color(0x55FFFFFF), height: 26),
            Text('${cfg.slotLabel(app.milkSlot)}\nFirst delivery ${dayMonth(app.milkStart)}${app.hasAddress ? '\n${app.street}, ${app.city.split(',').first} · ${app.pincode}' : ''}',
                style: T.sans(11.5, color: AppColors.white, height: 1.7)),
          ]),
        ),
        const Gap(10),
        ActionRow(
          icon: Icons.location_on_outlined,
          title: app.hasAddress ? 'Delivery address' : 'Add your delivery address',
          subtitle: app.hasAddress ? '${app.fullAddress} · ${app.pincode}' : 'Needed before we can deliver milk',
          onTap: () => go(context, R.location, args: 'edit'),
        ),
        if (!editing) ...[
          const Gap(12),
          KV('Deliveries in first ${cfg.firstPaymentDays} days', '${app.milkDeliveriesFirstMonth}'),
          KV('Per delivery', money(app.perDelivery)),
          const DashedDivider(),
          KV('Pay now (first month)', money(app.milkFirstPayment), strong: true),
          const Gap(10),
          const Note('Your payment is added to your milk balance. Each delivery is charged from it, and skipped or paused days are not charged.', tone: NoteTone.mint),
        ],
        const Gap(12),
        ToggleCard(
          title: 'Delivery reminders',
          subtitle: 'Pause or skip before ${cfg.cutoffText} the evening before.',
          value: app.milkReminders,
          onChanged: (v) => context.appRead.setMilkReminders(v),
        ),
      ],
    );
  }
}

// ───────────────────────── Milk plan: first payment ─────────────────────────
class MilkPaymentScreen extends StatefulWidget {
  const MilkPaymentScreen({super.key});

  @override
  State<MilkPaymentScreen> createState() => _MilkPaymentScreenState();
}

class _MilkPaymentScreenState extends State<MilkPaymentScreen> {
  bool _busy = false;

  Future<void> _pay() async {
    final app = context.appRead;
    final p = app.milkPlan;
    if (p == null) return;
    setState(() => _busy = true);
    try {
      if (app.milkPaymentMethod == 'cash') {
        final msg = await app.milkStartWithCash();
        if (!mounted) return;
        toast(context, msg);
      } else {
        final r = await payMilk(app, p.firstPayment, app.milkPaymentMethod);
        if (!mounted) return;
        toast(context, r.message);
        if (!r.paid) return;
      }
      final nav = Navigator.of(context);
      nav.pushNamedAndRemoveUntil(R.home, (_) => false, arguments: kTabSwitch);
      nav.pushNamed(R.milkHub, arguments: kTabSwitch);
      nav.pushNamed(R.milkActive);
    } catch (e) {
      if (mounted) _snack(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final p = app.milkPlan;
    final cfg = app.milkConfig;
    if (p == null) {
      return UScaffold(title: 'Pay with ease', nav: NavKind.customer, navIndex: 2, children: [
        const LoadState(empty: 'You don’t have a milk plan waiting for payment.'),
        PrimaryButton('Start a milk plan', onTap: () => goReplace(context, R.milkProduct)),
      ]);
    }
    final methods = <(String, String, IconData)>[
      if (cfg.onlinePayments) ('upi', 'UPI', Icons.qr_code_2_rounded),
      if (cfg.onlinePayments) ('card', 'Debit / credit card', Icons.credit_card_rounded),
      if (cfg.allowCash) ('cash', 'Cash to the delivery person', Icons.payments_outlined),
    ];
    if (methods.isNotEmpty && !methods.any((m) => m.$1 == app.milkPaymentMethod)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.appRead.setMilkPayment(methods.first.$1));
    }
    return UScaffold(
      title: 'Pay with ease',
      nav: NavKind.customer,
      navIndex: 2,
      bottom: PrimaryButton(
        _busy ? 'Please wait…' : (app.milkPaymentMethod == 'cash' ? 'Start plan · pay on first delivery' : 'Pay ${money(p.firstPayment)} & start'),
        onTap: _busy || methods.isEmpty ? null : _pay,
      ),
      children: [
        const Eyebrow('First month'),
        const Gap(10),
        const Headline('One last step\nto *fresh mornings.*'),
        const Gap(16),
        ColorBlock(
          color: AppColors.teal,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Amount payable', style: T.sans(12, color: AppColors.white)),
            const Gap(10),
            Text(money(p.firstPayment), style: T.display(46, color: AppColors.white)),
            Text('${p.deliveriesFirstPeriod} deliveries · ${p.litres} L each · from ${dayMonth(p.startDate)}', style: T.sans(11.5, color: AppColors.white)),
            Text('Plan ${p.number}', style: T.sans(10.5, color: AppColors.white)),
          ]),
        ),
        const FieldLabel('Payment method'),
        for (final (key, label, icon) in methods)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: app.milkPaymentMethod == key ? AppColors.pink : AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: app.milkPaymentMethod == key ? AppColors.berry : AppColors.border)),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => context.appRead.setMilkPayment(key),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    Icon(app.milkPaymentMethod == key ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, size: 20, color: AppColors.berry),
                    const SizedBox(width: 10),
                    Icon(icon, size: 18, color: AppColors.ink),
                    const SizedBox(width: 8),
                    Expanded(child: Text(label, style: T.sans(13, weight: FontWeight.w600))),
                  ]),
                ),
              ),
            ),
          ),
        if (methods.isEmpty) const Note('Payments are being set up by the shop. Please try again later.'),
        if (app.milkPaymentMethod == 'cash') const Note('Your plan starts now. Please pay the delivery person — they’ll record it and it shows in your milk balance.', tone: NoteTone.mint),
        const FinePrint('UPI and card payments are completed securely with Razorpay. Your payment is added to your milk balance.'),
      ],
    );
  }
}

// ───────────────────────── 24 · Active milk plan ─────────────────────────
class MilkActiveScreen extends StatefulWidget {
  const MilkActiveScreen({super.key});

  @override
  State<MilkActiveScreen> createState() => _MilkActiveScreenState();
}

class _MilkActiveScreenState extends State<MilkActiveScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.appRead.loadMilk());
  }

  Future<void> _cancel() async {
    final ok = await confirmDialog(context, title: 'Cancel your milk plan?', message: 'Deliveries stop from tomorrow. The shop will contact you about any remaining balance.', confirm: 'Cancel plan');
    if (!ok || !mounted) return;
    try {
      final msg = await context.appRead.milkCancel();
      if (!mounted) return;
      toast(context, msg);
      goTab(context, R.milkHub);
    } catch (e) {
      if (mounted) _snack(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final guest = _needsAccount(context, title: 'Your daily milk');
    if (guest != null) return guest;
    final app = context.app;
    final p = app.milkPlan;
    if (p == null || !p.isActive && !p.awaitingPayment && p.status != 'paused') {
      return UScaffold(title: 'Your daily milk', nav: NavKind.customer, navIndex: 2, children: [
        if (app.milkLoading) const LoadState(loading: true) else const LoadState(empty: 'You don’t have a milk plan yet.'),
        PrimaryButton('Start a milk plan', onTap: () => goReplace(context, R.milkProduct)),
      ]);
    }
    final today = p.today;
    return UScaffold(
      title: 'Your daily milk',
      nav: NavKind.customer,
      navIndex: 2,
      trailing: IconTileButton(Icons.refresh_rounded, onTap: () => context.appRead.loadMilk()),
      children: [
        Row(children: [
          Pill(p.statusLabel, bg: p.isActive ? AppColors.mint : AppColors.yellowSoft, fg: p.isActive ? AppColors.teal : const Color(0xFF6B4A1E)),
          const Spacer(),
          GestureDetector(
            onTap: () {
              context.appRead.startMilkDraft(edit: true);
              go(context, R.milkConfigure);
            },
            child: Text('Edit plan →', style: T.sans(12, color: AppColors.teal, weight: FontWeight.w700)),
          ),
        ]),
        const Gap(12),
        if (p.awaitingPayment) ...[
          Note('Your plan starts after the first payment of ${money(p.firstPayment)}.'),
          const Gap(8),
          PrimaryButton('Complete payment', onTap: () => go(context, R.milkPayment)),
          const Gap(12),
        ],
        ColorBlock(
          color: AppColors.teal,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('NEXT  DELIVERY  ·  ${p.nextDelivery == null ? '—' : dayMonth(p.nextDelivery!).toUpperCase()}', style: T.sans(9.5, color: AppColors.white, weight: FontWeight.w700, spacing: 1.2)),
            const Gap(12),
            Text('A fresh morning\nis on its way.', style: T.display(30, color: AppColors.white, height: 1.15)),
            const Gap(10),
            Text('${p.litres} L ${p.productName} · ${money(p.perDelivery)}\n${p.slotLabel} · ${p.frequencyLabel}', style: T.sans(11.5, color: AppColors.white, height: 1.6)),
          ]),
        ),
        if (today != null) ...[
          const Gap(10),
          UCard(
            onTap: () => go(context, R.milkProof),
            child: Row(children: [
              Icon(today.status == 'delivered' ? Icons.check_circle_rounded : (today.status == 'exception' ? Icons.error_outline_rounded : Icons.schedule_rounded),
                  color: today.status == 'exception' ? AppColors.berry : AppColors.teal),
              const SizedBox(width: 10),
              Expanded(child: Text('Today · ${today.statusLabel}${today.deliveredAt != null ? ' at ${_time(today.deliveredAt!)}' : ''}', style: T.sans(12.5, weight: FontWeight.w600))),
              const Icon(Icons.chevron_right_rounded),
            ]),
          ),
        ],
        const Gap(10),
        StatPair(
          StatCard('${p.litres} L', p.frequencyLabel),
          StatCard(money(p.balance), 'Milk balance', valueColor: p.lowBalance ? AppColors.berry : AppColors.teal),
        ),
        if (p.lowBalance) ...[const Gap(8), Note('Your balance covers fewer than 2 deliveries. Top up to avoid missing milk.')],
        const Gap(4),
        ActionRow(icon: Icons.calendar_month_outlined, title: 'Delivery calendar', subtitle: 'Skip a day or add milk on a day', onTap: () => go(context, R.milkCalendar)),
        ActionRow(icon: Icons.pause_circle_outline_rounded, title: 'Pause for a while', subtitle: 'Holiday mode — no milk, no charge', onTap: () => go(context, R.milkPause)),
        ActionRow(icon: Icons.local_shipping_outlined, title: 'Deliveries', subtitle: 'Who delivered and when', onTap: () => go(context, R.milkProof)),
        ActionRow(icon: Icons.account_balance_wallet_outlined, title: 'Milk balance & statement', subtitle: 'Top up and see every charge', onTap: () => go(context, R.milkTopUp)),
        ActionRow(icon: Icons.cancel_outlined, title: 'Cancel milk plan', subtitle: 'Stop deliveries', onTap: _cancel, divider: false),
        FinePrint('Plan ${p.number}. Change or skip before ${app.milkConfig.cutoffText} the evening before.'),
      ],
    );
  }
}

String _time(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  return '$h:${d.minute.toString().padLeft(2, '0')} ${d.hour < 12 ? 'AM' : 'PM'}';
}

// ───────────────────────── 25 · Delivery calendar (live) ─────────────────────────
class MilkCalendarScreen extends StatefulWidget {
  const MilkCalendarScreen({super.key});

  @override
  State<MilkCalendarScreen> createState() => _MilkCalendarScreenState();
}

class _MilkCalendarScreenState extends State<MilkCalendarScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  bool _busy = false;

  Future<void> _tap(MilkDay d) async {
    if (!d.canChange) {
      toast(context, d.date.isBefore(DateTime.now()) ? 'Past days can’t be changed' : 'Too late to change this day (cut-off ${context.appRead.milkConfig.cutoffText} the evening before)');
      return;
    }
    final deliver = d.state != 'scheduled';
    final ok = await confirmDialog(
      context,
      title: deliver ? 'Milk on ${dayMonth(d.date)}?' : 'Skip ${dayMonth(d.date)}?',
      message: deliver ? 'We’ll deliver your usual quantity that day.' : 'No milk and no charge that day.',
      confirm: deliver ? 'Add milk' : 'Skip day',
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      await context.appRead.milkSetDay(d.date, deliver);
      if (mounted) toast(context, deliver ? 'Milk added for ${dayMonth(d.date)}' : 'Skipped ${dayMonth(d.date)}');
    } catch (e) {
      if (mounted) _snack(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.app.milkPlan;
    if (p == null) {
      return UScaffold(title: 'Every drop, accounted for', nav: NavKind.customer, navIndex: 2, children: const [LoadState(empty: 'No milk plan yet.')]);
    }
    final first = p.calendar.isEmpty ? DateTime.now() : p.calendar.first.date;
    final last = p.calendar.isEmpty ? DateTime.now() : p.calendar.last.date;
    final delivered = p.calendar.where((c) => c.state == 'delivered').length;
    final upcoming = p.calendar.where((c) => c.state == 'scheduled').length;
    return UScaffold(
      title: 'Every drop, accounted for',
      nav: NavKind.customer,
      navIndex: 2,
      bottom: OutlineBtn('Pause for a few days', onTap: () => go(context, R.milkPause)),
      children: [
        const Eyebrow('Your schedule'),
        const Gap(10),
        Text('${p.litres} L · ${p.frequencyLabel}', style: T.display(28)),
        const Gap(4),
        Text('Tap a day to skip it or add milk.', style: T.small()),
        const Gap(12),
        if (_busy) const LinearProgressIndicator(minHeight: 2, color: AppColors.berry),
        _MonthGrid(
          month: _month,
          canBack: DateTime(_month.year, _month.month).isAfter(DateTime(first.year, first.month)),
          canNext: DateTime(_month.year, _month.month + 1).isBefore(DateTime(last.year, last.month + 1)),
          onMonth: (m) => setState(() => _month = m),
          legend: const [(AppColors.teal, 'Scheduled'), (Color(0xFF2E7D4F), 'Delivered'), (AppColors.berry, 'Not delivered'), (Color(0xFFC07B4F), 'Skipped')],
          cell: (date) {
            final d = p.dayFor(date);
            final now = DateTime.now();
            final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
            final (bg, fg, border) = switch (d?.state) {
              'scheduled' => (AppColors.teal, AppColors.white, Colors.transparent),
              'delivered' => (AppColors.mint, const Color(0xFF2E7D4F), AppColors.mint),
              'not_delivered' => (AppColors.pink, AppColors.berry, AppColors.pink),
              'skipped' => (const Color(0xFFF9DFC9), const Color(0xFFC07B4F), const Color(0xFFF9DFC9)),
              _ => (AppColors.surface, d == null ? AppColors.border : AppColors.ink, d?.canChange == true ? AppColors.border : AppColors.borderSoft),
            };
            return _DayDot(day: date.day, bg: bg, fg: fg, border: border, strike: d?.state == 'skipped', outline: isToday, onTap: d == null || _busy ? null : () => _tap(d));
          },
        ),
        const Gap(12),
        StatPair(StatCard('$upcoming', 'Upcoming deliveries'), StatCard('$delivered', 'Delivered this week')),
        FinePrint('Changes for tomorrow close at ${context.app.milkConfig.cutoffText} today.'),
      ],
    );
  }
}

// ───────────────────────── 26 · Pause ─────────────────────────
class MilkPauseScreen extends StatefulWidget {
  const MilkPauseScreen({super.key});

  @override
  State<MilkPauseScreen> createState() => _MilkPauseScreenState();
}

class _MilkPauseScreenState extends State<MilkPauseScreen> {
  String _mode = 'Holiday pause';
  late DateTime _from = _firstChangeable();
  late DateTime _resume = _from.add(const Duration(days: 2));
  bool _busy = false;

  DateTime _firstChangeable() {
    final n = DateTime.now();
    final cutoff = context.appRead.milkConfig.cutoffHour;
    return DateTime(n.year, n.month, n.day).add(Duration(days: n.hour < cutoff ? 1 : 2));
  }

  Future<void> _save() async {
    final resume = _mode == 'Skip one day' ? _from.add(const Duration(days: 1)) : _resume;
    setState(() => _busy = true);
    try {
      final msg = await context.appRead.milkPause(_from, resume);
      if (!mounted) return;
      toast(context, msg);
      goReplace(context, R.milkCalendar);
    } catch (e) {
      if (mounted) _snack(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final resume = _mode == 'Skip one day' ? _from.add(const Duration(days: 1)) : _resume;
    final days = resume.difference(_from).inDays;
    return UScaffold(
      title: 'Your routine. Your rules.',
      nav: NavKind.customer,
      navIndex: 2,
      bottom: PrimaryButton(_busy ? 'Saving…' : 'Save pause', onTap: _busy || app.milkPlan == null ? null : _save),
      children: [
        const Eyebrow('A little flexibility'),
        const Gap(10),
        const Headline('Away for a while?\nWe’ll *hold your milk.*', size: 34),
        const Gap(14),
        ChipGroup(options: const ['Skip one day', 'Holiday pause'], selected: _mode, onSelected: (v) => setState(() => _mode = v)),
        UPicker(
          label: _mode == 'Skip one day' ? 'Skip delivery on' : 'No milk from',
          value: dayMonth(_from),
          icon: Icons.calendar_today_outlined,
          onTap: () async {
            final first = _firstChangeable();
            final d = await pickDate(context, initial: _from, first: first, last: first.add(const Duration(days: 90)));
            if (d != null) {
              setState(() {
                _from = d;
                if (!_resume.isAfter(_from)) _resume = _from.add(const Duration(days: 1));
              });
            }
          },
        ),
        if (_mode == 'Holiday pause')
          UPicker(
            label: 'Milk again from',
            value: dayMonth(_resume),
            icon: Icons.calendar_today_outlined,
            onTap: () async {
              final d = await pickDate(context, initial: _resume, first: _from.add(const Duration(days: 1)), last: _from.add(const Duration(days: 90)));
              if (d != null) setState(() => _resume = d);
            },
          ),
        const Gap(14),
        UCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_mode == 'Skip one day' ? 'No milk on ${dayMonth(_from)}' : 'No milk for $days day${days == 1 ? '' : 's'}', style: T.display(25)),
            const Gap(10),
            Text(_mode == 'Skip one day' ? dayMonth(_from) : '${dayMonth(_from)} – ${dayMonth(resume.subtract(const Duration(days: 1)))}', style: T.sans(12)),
            Text('Your regular plan continues from ${dayMonth(resume)}.', style: T.sans(12)),
            const Divider(color: AppColors.border, height: 26),
            const KV('Charges for paused days', '₹0', color: AppColors.teal),
          ]),
        ),
        const Gap(12),
        Note('Changes for tomorrow must be made before ${app.milkConfig.cutoffText} today.'),
      ],
    );
  }
}

// ───────────────────────── 27 · Deliveries ─────────────────────────
class MilkProofScreen extends StatelessWidget {
  const MilkProofScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.app.milkPlan;
    final list = [if (p?.today != null && p!.today!.status != 'scheduled') p.today!, ...?p?.recentDeliveries.where((d) => d.id != p.today?.id)];
    final latest = list.isEmpty ? null : list.first;
    return UScaffold(
      title: 'Delivered with care',
      nav: NavKind.customer,
      navIndex: 2,
      children: [
        if (latest == null)
          const LoadState(empty: 'No deliveries yet. Each delivery shows here as soon as the delivery person marks it.')
        else ...[
          ColorBlock(
            color: latest.status == 'delivered' ? AppColors.teal : AppColors.berry,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(dayMonth(latest.date).toUpperCase(), style: T.sans(9.5, color: AppColors.white, weight: FontWeight.w700, spacing: 1.2)),
              const Gap(10),
              Text(latest.status == 'delivered' ? 'Delivered${latest.deliveredAt != null ? ' at ${_time(latest.deliveredAt!)}' : ''}' : 'Not delivered', style: T.display(28, color: AppColors.white)),
              const Gap(8),
              Text(
                latest.status == 'delivered'
                    ? '${latest.litres} L · ${money(latest.amount)}${latest.deliveredBy != null ? '\nBy ${latest.deliveredBy}' : ''}'
                    : '${latest.exceptionReason ?? ''}\nNo charge for this day',
                style: T.sans(11.5, color: AppColors.white, height: 1.6),
              ),
            ]),
          ),
          if (latest.note != null && latest.note!.isNotEmpty) ...[const Gap(10), Note('Note from the delivery person: ${latest.note}')],
          const Gap(16),
          const SectionTitle('Recent deliveries', size: 22),
          const Gap(8),
          for (final d in list)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderSoft))),
              child: Row(children: [
                Icon(d.status == 'delivered' ? Icons.check_circle_rounded : Icons.error_outline_rounded, color: d.status == 'delivered' ? AppColors.teal : AppColors.berry, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text('${dayMonth(d.date)} · ${d.statusLabel}', style: T.sans(12.5))),
                Text(d.status == 'delivered' ? money(d.amount) : '₹0', style: T.sans(12.5, weight: FontWeight.w700)),
              ]),
            ),
        ],
      ],
    );
  }
}

// ───────────────────────── 28 · Balance & top-up ─────────────────────────
class MilkTopUpScreen extends StatefulWidget {
  const MilkTopUpScreen({super.key});

  @override
  State<MilkTopUpScreen> createState() => _MilkTopUpScreenState();
}

class _MilkTopUpScreenState extends State<MilkTopUpScreen> {
  double? _amount;
  String _method = 'upi';
  bool _busy = false;

  Future<void> _pay(double amount) async {
    setState(() => _busy = true);
    final r = await payMilk(context.appRead, amount, _method);
    if (!mounted) return;
    setState(() => _busy = false);
    toast(context, r.message);
  }

  Future<void> _custom() async {
    final c = TextEditingController();
    final v = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 0, 24, MediaQuery.viewInsetsOf(ctx).bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Top-up amount', style: T.display(28)),
          UField(label: 'Amount (₹)', controller: c, keyboard: TextInputType.number, autofocus: true),
          const Gap(18),
          PrimaryButton('Use this amount', icon: null, onTap: () => Navigator.pop(ctx, c.text.trim())),
        ]),
      ),
    );
    final n = double.tryParse(v ?? '');
    if (n != null && mounted) setState(() => _amount = n);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final p = app.milkPlan;
    final cfg = app.milkConfig;
    if (p == null) {
      return UScaffold(title: 'Your milk balance', nav: NavKind.customer, navIndex: 2, children: const [LoadState(empty: 'No milk plan yet.')]);
    }
    final suggestions = <double>{p.perDelivery * 7, p.perDelivery * 15, p.perDelivery * 30}.where((a) => a >= cfg.minTopup).toList();
    final amount = _amount ?? (suggestions.isEmpty ? cfg.minTopup : suggestions[1 < suggestions.length ? 1 : 0]);
    final covers = p.perDelivery == 0 ? 0 : (p.balance / p.perDelivery).floor();
    return UScaffold(
      title: 'Your milk balance',
      nav: NavKind.customer,
      navIndex: 2,
      bottom: cfg.onlinePayments
          ? PrimaryButton(_busy ? 'Opening payment…' : 'Add ${money(amount)}', onTap: _busy || amount < cfg.minTopup ? null : () => _pay(amount))
          : null,
      children: [
        ColorBlock(
          color: AppColors.teal,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Available balance', style: T.sans(12, color: AppColors.white)),
            const Gap(8),
            Text(money(p.balance), style: T.display(44, color: AppColors.white)),
            Text('Enough for about ${covers < 0 ? 0 : covers} deliveries at ${p.litres} L', style: T.sans(11.5, color: AppColors.white)),
          ]),
        ),
        const Gap(16),
        if (cfg.onlinePayments) ...[
          const Eyebrow('Top up'),
          const Gap(10),
          ChipGroup(
            options: [...suggestions.map((a) => money(a)), 'Other'],
            selected: _amount != null && !suggestions.contains(_amount) ? 'Other' : money(amount),
            onSelected: (v) {
              if (v == 'Other') {
                _custom();
              } else {
                setState(() => _amount = suggestions.firstWhere((a) => money(a) == v));
              }
            },
          ),
          const Gap(12),
          ChipGroup(options: const ['UPI', 'Card'], selected: _method == 'upi' ? 'UPI' : 'Card', onSelected: (v) => setState(() => _method = v == 'UPI' ? 'upi' : 'card')),
        ] else
          const Note('Online top-ups are being set up. You can pay the delivery person in cash — it’s added to your balance straight away.'),
        const Gap(18),
        const SectionTitle('Statement', size: 22),
        const Gap(8),
        if (p.transactions.isEmpty) const LoadState(empty: 'No payments or charges yet.'),
        for (final t in p.transactions)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderSoft))),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(t.description, style: T.sans(12.5)),
                  if (t.createdAt != null) Text(dayMonth(t.createdAt!), style: T.tiny()),
                ]),
              ),
              Text('${t.amount >= 0 ? '+' : '−'}${money(t.amount.abs())}', style: T.sans(13, weight: FontWeight.w700, color: t.amount >= 0 ? AppColors.teal : AppColors.ink)),
            ]),
          ),
      ],
    );
  }
}
