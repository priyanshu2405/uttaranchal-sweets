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
import '../../widgets/u_scaffold.dart';

// ───────────────────────── 20 · Milk distribution hub ─────────────────────────
class MilkHubScreen extends StatelessWidget {
  const MilkHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return UScaffold(
      title: 'Fresh milk, every day',
      nav: NavKind.customer,
      navIndex: 2,
      children: [
        const Eyebrow('Good mornings begin here'),
        const Gap(10),
        const Headline('From our dairy.\nTo your *doorstep.*'),
        const Gap(16),
        MilkHero(onTap: () => go(context, R.milkProduct)),
        const Gap(10),
        ColorBlock(
          color: AppColors.teal,
          onTap: () => go(context, app.milkPlanActive ? R.milkActive : R.milkProduct),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(app.milkPlanActive ? 'YOUR  ACTIVE  PLAN' : 'NO  ACTIVE  PLAN', style: T.sans(9.5, color: AppColors.white, weight: FontWeight.w700, spacing: 1.2)),
                const Gap(8),
                Text(app.milkPlanActive ? '${app.milkLitres} L · ${app.milkFrequency == 'Every day' ? 'Every morning' : app.milkFrequency}' : 'Start your mornings fresh',
                    style: T.display(26, color: AppColors.white)),
                const Gap(6),
                Text(app.milkPlanActive ? 'Next delivery: Tomorrow, ${app.milkSlot.split(' · ').last.replaceAll(':00', '')}' : 'Build a plan in under a minute',
                    style: T.sans(11, color: AppColors.white)),
              ]),
            ),
            const IconTileButton(Icons.north_east_rounded),
          ]),
        ),
        const Gap(12),
        Row(children: [
          SmallButton('Start a milk plan', onTap: () => go(context, R.milkProduct)),
          const Spacer(),
          SmallButton('Delivery calendar', filled: false, onTap: () => go(context, R.milkCalendar)),
        ]),
        const Gap(20),
        const SectionTitle('Made for your routine'),
        const Gap(12),
        StatPair(
          const StatCard('₹68', 'Full cream milk / litre'),
          StatCard(rupees(app.milkBalance), 'Prepaid milk balance'),
        ),
        ActionRow(icon: Icons.account_balance_wallet_outlined, title: 'Top up your milk balance', subtitle: 'Keep your mornings uninterrupted', onTap: () => go(context, R.milkTopUp)),
        ActionRow(icon: Icons.verified_outlined, title: 'Today’s delivery', subtitle: 'Delivered 6:32 AM · Proof & details', onTap: () => go(context, R.milkProof), divider: false),
      ],
    );
  }
}

// ───────────────────────── 21 · Milk product ─────────────────────────
class MilkProductScreen extends StatelessWidget {
  const MilkProductScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return UScaffold(
      title: 'Freshness, bottled',
      nav: NavKind.customer,
      navIndex: 2,
      bottom: PrimaryButton('Build my milk plan', onTap: () => go(context, R.milkConfigure)),
      children: [
        const MilkHero(),
        const Gap(14),
        const Row(children: [
          Pill('Local delivery only'),
          Spacer(),
          Pill('1 L bottle', bg: AppColors.peach, fg: AppColors.ink),
        ]),
        const Gap(14),
        Text('Full Cream Milk', style: T.display(36)),
        const Gap(8),
        const BodyText('Fresh dairy for your morning chai, family breakfasts and everyday rituals.'),
        const Gap(12),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('₹68', style: T.display(32, color: AppColors.teal, weight: FontWeight.w700)),
          Padding(padding: const EdgeInsets.only(bottom: 6, left: 4), child: Text('/ litre', style: T.sans(12, color: AppColors.teal, weight: FontWeight.w600))),
          const Spacer(),
          ...List.generate(5, (_) => const Icon(Icons.star_rounded, size: 13, color: Color(0xFFC58A27))),
          const SizedBox(width: 6),
          Text('4.9', style: T.sans(12, color: const Color(0xFFC58A27), weight: FontWeight.w600)),
        ]),
        const Gap(12),
        const UCard(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Column(children: [
            KV('Delivered locally', 'Kashipur service areas'),
            KV('Storage', 'Keep refrigerated'),
            KV('Ingredients & allergens', 'Milk · Contains milk'),
          ]),
        ),
        const FinePrint('Product specifications, handling and use-by instructions appear on the supplied pack.'),
      ],
    );
  }
}

// ───────────────────────── 22 · Configure milk plan ─────────────────────────
class MilkConfigureScreen extends StatelessWidget {
  const MilkConfigureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final qtyLabel = app.milkLitres <= 3 ? '${app.milkLitres} L' : 'Custom';
    return UScaffold(
      title: 'Make mornings yours',
      nav: NavKind.customer,
      navIndex: 2,
      bottom: PrimaryButton('Review my plan', onTap: () => go(context, R.milkReview)),
      children: [
        const Eyebrow('Your milk plan'),
        const Gap(10),
        const Headline('Just the way\nyour family *likes it.*'),
        const Gap(16),
        UCard(
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Full Cream Milk', style: T.display(24)),
                const Gap(6),
                Text('₹68 per litre', style: T.sans(12)),
              ]),
            ),
            const MilkBottle(height: 70),
          ]),
        ),
        const Gap(18),
        const Eyebrow('Daily quantity'),
        const Gap(10),
        ChipGroup(
          options: Milk.quantities,
          selected: qtyLabel,
          onSelected: (v) async {
            if (v == 'Custom') {
              final n = await _customQty(context, app.milkLitres);
              if (n != null && context.mounted) context.appRead.configureMilk(litres: n);
            } else {
              context.appRead.configureMilk(litres: int.parse(v.split(' ').first));
            }
          },
        ),
        if (qtyLabel == 'Custom') Padding(padding: const EdgeInsets.only(top: 8), child: Text('${app.milkLitres} litres per delivery', style: T.small(AppColors.teal))),
        const Gap(18),
        const Eyebrow('Delivery frequency'),
        const Gap(10),
        ChipGroup(options: Milk.frequencies, selected: app.milkFrequency, onSelected: (v) => context.appRead.configureMilk(frequency: v)),
        UPicker(
          label: 'Start date',
          value: isoDate(app.milkStart),
          icon: Icons.calendar_today_outlined,
          onTap: () async {
            final d = await pickDate(context, initial: app.milkStart, first: DateTime(2026, 10, 30));
            if (d != null && context.mounted) context.appRead.configureMilk(start: d);
          },
        ),
        UPicker(
          label: 'Delivery slot',
          value: app.milkSlot,
          icon: Icons.schedule_rounded,
          onTap: () async {
            final v = await pickOption(context, title: 'Delivery slot', options: Milk.slots, selected: app.milkSlot);
            if (v != null && context.mounted) context.appRead.configureMilk(slot: v);
          },
        ),
        const Gap(16),
        Row(children: [
          Expanded(child: Text('Per scheduled delivery', style: T.sans(12.5, color: AppColors.muted))),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(rupees(app.perDelivery), key: ValueKey(app.perDelivery), style: T.sans(14, color: AppColors.teal, weight: FontWeight.w700)),
          ),
        ]),
      ],
    );
  }

  Future<int?> _customQty(BuildContext context, int current) {
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
                QtyStepper(value: n, min: 1, max: 10, onChanged: (v) => set(() => n = v)),
                const SizedBox(width: 12),
                Text('litres / day', style: T.sans(14)),
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

// ───────────────────────── 23 · Review & activate ─────────────────────────
class MilkReviewScreen extends StatelessWidget {
  const MilkReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final topUp = app.nextSevenDays > app.milkBalance ? 1000 : 500;
    return UScaffold(
      title: 'Your fresh start',
      nav: NavKind.customer,
      navIndex: 2,
      bottom: PrimaryButton(
        'Preview active milk plan',
        onTap: () async {
          await showProcessing(context, 'Activating your plan…', duration: const Duration(milliseconds: 1000));
          if (!context.mounted) return;
          context.appRead.activateMilkPlan();
          final nav = Navigator.of(context);
          nav.pushNamedAndRemoveUntil(R.milkHub, (_) => false, arguments: kTabSwitch);
          nav.pushNamed(R.milkActive);
          toast(context, 'Your milk plan is active');
        },
      ),
      children: [
        const Eyebrow('Review your milk plan'),
        const Gap(10),
        const Headline('A routine worth\n*waking up for.*'),
        const Gap(16),
        ColorBlock(
          color: AppColors.teal,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Full Cream Milk', style: T.display(26, color: AppColors.white)),
            const Gap(6),
            Text('${app.milkLitres} litre${app.milkLitres == 1 ? '' : 's'} · ${app.milkFrequency == 'Every day' ? 'Daily' : app.milkFrequency} · ${rupees(app.perDelivery)} per delivery',
                style: T.sans(11.5, color: AppColors.white)),
            const Divider(color: Color(0x55FFFFFF), height: 26),
            Text('${app.milkSlot}\nStarts ${dayMonth(app.milkStart)}\n${app.street}, ${app.city.split(',').first}', style: T.sans(11.5, color: AppColors.white, height: 1.7)),
          ]),
        ),
        const Gap(12),
        KV('Next 7 deliveries', rupees(app.nextSevenDays)),
        KV('Milk balance available', rupees(app.milkBalance)),
        const DashedDivider(),
        KV('Suggested top-up', rupees(topUp), strong: true),
        const Gap(10),
        const Note('Deliveries are charged from the milk balance after completion. Skipped or paused deliveries are not charged.', tone: NoteTone.mint),
        const Gap(12),
        ToggleCard(
          title: 'Delivery reminders',
          subtitle: 'Pause or skip by the displayed cut-off time.',
          value: app.milkReminders,
          onChanged: (v) => context.appRead.setMilkReminders(v),
        ),
        const FinePrint('This screen previews activation. No milk service is booked.'),
      ],
    );
  }
}

// ───────────────────────── 24 · Active milk subscription ─────────────────────────
class MilkActiveScreen extends StatelessWidget {
  const MilkActiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return UScaffold(
      title: 'Your daily milk',
      nav: NavKind.customer,
      navIndex: 2,
      children: [
        Row(children: [
          const Pill('Plan active'),
          const Spacer(),
          GestureDetector(
            onTap: () => go(context, R.milkConfigure),
            child: Text('Edit plan →', style: T.sans(12, color: AppColors.teal, weight: FontWeight.w700)),
          ),
        ]),
        const Gap(12),
        ColorBlock(
          color: AppColors.teal,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('NEXT  DELIVERY  ·  TOMORROW', style: T.sans(9.5, color: AppColors.white, weight: FontWeight.w700, spacing: 1.2)),
            const Gap(12),
            Text('A fresh morning\nis on its way.', style: T.display(30, color: AppColors.white, height: 1.15)),
            const Gap(10),
            Text('${app.milkLitres} L Full Cream Milk · ${rupees(app.perDelivery)}\n${app.milkSlot.split(' · ').last} · ${app.area}', style: T.sans(11.5, color: AppColors.white, height: 1.6)),
          ]),
        ),
        const Gap(10),
        StatPair(
          StatCard('${app.milkLitres} L', app.milkFrequency),
          StatCard(rupees(app.milkBalance), 'Milk balance'),
        ),
        const Gap(4),
        ActionRow(icon: Icons.calendar_month_outlined, title: 'Delivery calendar', subtitle: 'Completed, scheduled and skipped days', onTap: () => go(context, R.milkCalendar)),
        ActionRow(icon: Icons.pause_circle_outline_rounded, title: 'Pause / skip delivery', subtitle: 'Holiday mode and single-day skips', onTap: () => go(context, R.milkPause)),
        ActionRow(icon: Icons.tune_rounded, title: 'Change quantity or schedule', subtitle: 'Manage your recurring plan', onTap: () => go(context, R.milkConfigure)),
        ActionRow(icon: Icons.local_shipping_outlined, title: 'Today’s delivery status', subtitle: 'See delivery details and proof', onTap: () => go(context, R.milkProof)),
        ActionRow(icon: Icons.account_balance_wallet_outlined, title: 'Milk balance & statement', subtitle: 'Top up and review charges', onTap: () => go(context, R.milkTopUp), divider: false),
      ],
    );
  }
}

// ───────────────────────── 25 · Milk delivery calendar ─────────────────────────
enum _Day { delivered, today, skipped, scheduled }

class MilkCalendarScreen extends StatefulWidget {
  const MilkCalendarScreen({super.key});

  @override
  State<MilkCalendarScreen> createState() => _MilkCalendarScreenState();
}

class _MilkCalendarScreenState extends State<MilkCalendarScreen> {
  static const _today = 7; // demo "today" – 7 November 2026
  int _selected = _today;

  _Day _state(AppState app, int d) {
    if (app.pausedDays.contains(d)) return _Day.skipped;
    if (d == _today) return _Day.today;
    if (d < _today) return _Day.delivered;
    return _Day.scheduled;
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final first = DateTime(2026, 11, 1);
    final leading = first.weekday - 1; // Monday-first grid
    const days = 30;
    final cells = <int?>[...List.filled(leading, null), for (var d = 1; d <= days; d++) d];
    final sel = _state(app, _selected);
    final completed = List.generate(_today - 1, (i) => i + 1).where((d) => !app.pausedDays.contains(d)).length;
    final statusText = switch (sel) {
      _Day.delivered => 'Delivered',
      _Day.today => 'Delivered 6:32 AM',
      _Day.skipped => 'Paused',
      _Day.scheduled => 'Scheduled',
    };

    return UScaffold(
      title: 'Every drop, accounted for',
      nav: NavKind.customer,
      navIndex: 2,
      bottom: OutlineBtn(
        sel == _Day.delivered || sel == _Day.today ? 'View delivery proof' : 'Manage this delivery',
        onTap: () => go(context, sel == _Day.delivered || sel == _Day.today ? R.milkProof : R.milkPause),
      ),
      children: [
        Row(children: [
          Expanded(child: Text.rich(TextSpan(children: [TextSpan(text: 'November ', style: T.display(32)), TextSpan(text: '2026', style: T.display(32, color: AppColors.teal, italic: true, weight: FontWeight.w500))]))),
          IconButton(onPressed: () => toast(context, 'October deliveries are in your statement'), icon: const Icon(Icons.chevron_left_rounded, color: AppColors.ink)),
          IconButton(onPressed: () => toast(context, 'December schedule opens on 25 November'), icon: const Icon(Icons.chevron_right_rounded, color: AppColors.ink)),
        ]),
        const Gap(10),
        Row(children: [for (final w in const ['M', 'T', 'W', 'T', 'F', 'S', 'S']) Expanded(child: Center(child: Text(w, style: T.sans(10.5, color: AppColors.muted))))]),
        const Gap(8),
        for (var r = 0; r < (cells.length / 7).ceil(); r++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              for (var c = 0; c < 7; c++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: () {
                      final i = r * 7 + c;
                      final d = i < cells.length ? cells[i] : null;
                      if (d == null) return const SizedBox(height: 32);
                      return _DayCell(day: d, state: _state(app, d), selected: d == _selected, onTap: () => setState(() => _selected = d));
                    }(),
                  ),
                ),
            ]),
          ),
        const Gap(6),
        Wrap(spacing: 14, runSpacing: 6, children: [
          _legend(AppColors.teal, 'Delivered'),
          _legend(AppColors.berry, 'Today'),
          _legend(const Color(0xFFC07B4F), 'Skipped'),
          _legend(AppColors.ink, 'Scheduled'),
        ]),
        const Gap(14),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: ColorBlock(
            key: ValueKey(_selected),
            color: sel == _Day.skipped ? const Color(0xFFC07B4F) : AppColors.teal,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('SELECTED  ·  $_selected  NOVEMBER', style: T.sans(9.5, color: AppColors.white, weight: FontWeight.w700, spacing: 1.2)),
              const Gap(10),
              Text(sel == _Day.skipped ? 'Paused · No charge' : '${app.milkLitres} L · $statusText', style: T.display(27, color: AppColors.white)),
              const Gap(8),
              Text('Full Cream Milk · ${sel == _Day.skipped ? '₹0' : rupees(app.perDelivery)}\nMorning route · ${app.milkSlot.split(' · ').last}',
                  style: T.sans(11.5, color: AppColors.white, height: 1.6)),
            ]),
          ),
        ),
        const Gap(10),
        StatPair(StatCard('$completed', 'Completed deliveries'), StatCard(rupees(completed * app.perDelivery), 'Charged this month')),
        const FinePrint('Illustrative calendar states. Delivery dates and balances will reflect the customer’s actual plan.'),
      ],
    );
  }

  Widget _legend(Color c, String t) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 5),
        Text(t, style: T.tiny(c)),
      ]);
}

class _DayCell extends StatelessWidget {
  final int day;
  final _Day state;
  final bool selected;
  final VoidCallback onTap;
  const _DayCell({required this.day, required this.state, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (state) {
      _Day.delivered => (AppColors.mint, AppColors.teal, AppColors.mint),
      _Day.today => (AppColors.berry, AppColors.white, AppColors.berry),
      _Day.skipped => (const Color(0xFFF9DFC9), const Color(0xFFC07B4F), const Color(0xFFF9DFC9)),
      _Day.scheduled => (AppColors.surface, AppColors.ink, const Color(0xFFB5CEC0)),
    };
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected && state != _Day.today ? AppColors.berry : border, width: selected ? 1.8 : 1),
        ),
        child: Text('$day', style: T.sans(11.5, color: fg, weight: selected ? FontWeight.w700 : FontWeight.w500)),
      ),
    );
  }
}

// ───────────────────────── 26 · Pause / skip / holiday ─────────────────────────
class MilkPauseScreen extends StatefulWidget {
  const MilkPauseScreen({super.key});

  @override
  State<MilkPauseScreen> createState() => _MilkPauseScreenState();
}

class _MilkPauseScreenState extends State<MilkPauseScreen> {
  String _mode = 'Holiday pause';
  DateTime _from = DateTime(2026, 11, 11);
  DateTime _resume = DateTime(2026, 11, 13);

  List<DateTime> get _days {
    if (_mode == 'Skip one day') return [_from];
    final n = _resume.difference(_from).inDays;
    return List.generate(n < 1 ? 1 : n, (i) => _from.add(Duration(days: i)));
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final days = _days;
    final resume = _mode == 'Skip one day' ? _from.add(const Duration(days: 1)) : _resume;
    final dayList = days.length <= 3 ? days.map((d) => d.day).join(' & ') : '${days.first.day}–${days.last.day}';
    return UScaffold(
      title: 'Your routine. Your rules.',
      nav: NavKind.customer,
      navIndex: 2,
      bottom: PrimaryButton(
        'Save pause & view calendar',
        onTap: () {
          context.appRead.pauseDays(days.where((d) => d.month == 11).map((d) => d.day));
          toast(context, '${days.length} deliver${days.length == 1 ? 'y' : 'ies'} paused');
          Navigator.of(context).pushNamedAndRemoveUntil(
            R.milkCalendar,
            (r) => r.isFirst || r.settings.name == R.milkHub || r.settings.name == R.milkActive,
          );
        },
      ),
      children: [
        const Eyebrow('A little flexibility'),
        const Gap(10),
        const Headline('Away for a while?\nWe’ll *hold your milk.*', size: 34),
        const Gap(14),
        ChipGroup(options: const ['Skip one day', 'Holiday pause'], selected: _mode, onSelected: (v) => setState(() => _mode = v)),
        UPicker(
          label: _mode == 'Skip one day' ? 'Skip delivery on' : 'Pause from',
          value: isoDate(_from),
          icon: Icons.calendar_today_outlined,
          onTap: () async {
            final d = await pickDate(context, initial: _from, first: DateTime(2026, 11, 8), last: DateTime(2026, 12, 31));
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
            label: 'Resume on',
            value: isoDate(_resume),
            icon: Icons.calendar_today_outlined,
            onTap: () async {
              final d = await pickDate(context, initial: _resume, first: _from.add(const Duration(days: 1)), last: DateTime(2027, 1, 31));
              if (d != null) setState(() => _resume = d);
            },
          ),
        const Gap(14),
        UCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${days.length} deliver${days.length == 1 ? 'y' : 'ies'} will be paused', style: T.display(25)),
            const Gap(10),
            Text('$dayList ${monthName(days.first.month)}', style: T.sans(12)),
            Text('Your regular ${app.milkLitres} L plan resumes on ${dayMonth(resume)}.', style: T.sans(12)),
            const Divider(color: AppColors.border, height: 26),
            const KV('Charges for paused days', '₹0', color: AppColors.teal),
          ]),
        ),
        const Gap(12),
        const Note('Sample cut-off: changes before 8 PM apply to the following morning. Any later change is reviewed by the dairy team.'),
        const FinePrint('You’ll see the affected dates before confirming. Your prepaid milk balance remains available.'),
      ],
    );
  }
}

// ───────────────────────── 27 · Milk delivery proof ─────────────────────────
class MilkProofScreen extends StatelessWidget {
  const MilkProofScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return UScaffold(
      title: 'Your morning delivery',
      nav: NavKind.customer,
      navIndex: 2,
      children: [
        const Align(alignment: Alignment.centerLeft, child: Pill('Delivered · 6:32 AM')),
        const Gap(12),
        ColorBlock(
          color: AppColors.teal,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Freshness has arrived.', style: T.display(26, color: AppColors.white)),
            const Gap(8),
            Text('${app.milkLitres} L Full Cream Milk\nDelivered to ${app.street}', style: T.sans(11.5, color: AppColors.white, height: 1.6)),
          ]),
        ),
        const Gap(14),
        Row(children: [
          const Avatar('R', size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Ravi Kumar', style: T.title()),
              Text('Your milk delivery partner', style: T.small()),
            ]),
          ),
          const Icon(Icons.verified_rounded, size: 16, color: AppColors.teal),
          const SizedBox(width: 4),
          Text('Verified', style: T.sans(12, color: AppColors.teal, weight: FontWeight.w600)),
        ]),
        const Gap(14),
        UCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Column(children: [
            const KV('Delivery date', '7 November'),
            KV('Scheduled quantity', '${app.milkLitres} L'),
            KV('Delivered quantity', '${app.milkLitres} L'),
            KV('Milk balance debited', rupees(app.perDelivery)),
            const KV('Proof of delivery', 'Customer OTP verified'),
          ]),
        ),
        const Gap(12),
        const Note('Something missing? Report an issue with this delivery and our team will review it.'),
        const Gap(14),
        Row(children: [
          SmallButton('Report an issue', filled: false, onTap: () => go(context, R.help, args: 'milk')),
          const Spacer(),
          SmallButton('View calendar', color: AppColors.teal, onTap: () => go(context, R.milkCalendar)),
        ]),
      ],
    );
  }
}

// ───────────────────────── 28 · Milk balance top-up ─────────────────────────
class MilkTopUpScreen extends StatefulWidget {
  const MilkTopUpScreen({super.key});

  @override
  State<MilkTopUpScreen> createState() => _MilkTopUpScreenState();
}

class _MilkTopUpScreenState extends State<MilkTopUpScreen> {
  int _amount = 1000;
  String _method = 'UPI';

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final deliveries = app.perDelivery == 0 ? 0 : app.milkBalance ~/ app.perDelivery;
    return UScaffold(
      title: 'Your milk account',
      nav: NavKind.customer,
      navIndex: 2,
      children: [
        const Eyebrow('Prepaid milk balance'),
        const Gap(10),
        const Headline('A little top-up.\nA lot of *good mornings.*', size: 34),
        const Gap(14),
        ColorBlock(
          color: AppColors.teal,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('AVAILABLE  MILK  BALANCE', style: T.sans(9.5, color: AppColors.white, weight: FontWeight.w700, spacing: 1.2)),
            const Gap(10),
            TweenAnimationBuilder<double>(
              tween: Tween(end: app.milkBalance.toDouble()),
              duration: const Duration(milliseconds: 700),
              builder: (context, v, _) => Text(rupees(v.round()), style: T.display(46, color: AppColors.white)),
            ),
            Text('Enough for $deliveries deliveries at ${app.milkLitres} L per day', style: T.sans(11.5, color: AppColors.white)),
          ]),
        ),
        const Gap(12),
        ChipGroup(options: const ['₹500', '₹1,000', '₹2,000'], selected: rupees(_amount), onSelected: (v) => setState(() => _amount = int.parse(v.replaceAll(RegExp(r'[^0-9]'), '')))),
        UPicker(
          label: 'Top-up payment method',
          value: _method,
          onTap: () async {
            final v = await pickOption(context, title: 'Payment method', options: const ['UPI', 'Credit / debit card', 'Net banking'], selected: _method);
            if (v != null) setState(() => _method = v);
          },
        ),
        const Gap(14),
        Align(
          alignment: Alignment.centerLeft,
          child: PrimaryButton(
            'Preview ${rupees(_amount)} top-up',
            expanded: false,
            onTap: () async {
              final ok = await confirmDialog(context, title: 'Add ${rupees(_amount)}?', message: 'This adds ${rupees(_amount)} to your prepaid milk balance via $_method. (Demo — no money moves.)', confirm: 'Top up');
              if (!ok || !context.mounted) return;
              await showProcessing(context, 'Processing top-up…', duration: const Duration(milliseconds: 900));
              if (!context.mounted) return;
              context.appRead.topUpMilk(_amount);
              toast(context, 'Balance topped up by ${rupees(_amount)}');
            },
          ),
        ),
        const Gap(20),
        const SectionTitle('Recent milk activity'),
        const Gap(8),
        for (final t in app.milkActivity.take(5))
          KV(t.label, t.amount > 0 ? '+ ${rupees(t.amount)}' : '− ${rupees(-t.amount)}', color: t.amount > 0 ? AppColors.teal : AppColors.ink),
        const Gap(10),
        const Note('Milk balance is prepaid money. Loyalty points are a separate reward balance and are redeemed on eligible product orders.', tone: NoteTone.mint),
      ],
    );
  }
}
