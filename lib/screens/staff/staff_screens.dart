import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

const _staffSubtitle = 'Uttaranchal Dairy · Staff';

// ───────────────────────── 35 · Delivery staff sign in ─────────────────────────
class StaffSignInScreen extends StatelessWidget {
  const StaffSignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return UScaffold(
      title: 'Milk distribution',
      trailing: const HelpButton(),
      bottom: PrimaryButton(
        'Open my morning route',
        color: AppColors.teal,
        onTap: () async {
          await showProcessing(context, 'Loading today’s route…', duration: const Duration(milliseconds: 900));
          if (context.mounted) goTab(context, R.staffDashboard);
        },
      ),
      children: [
        const Eyebrow('Delivery partner app'),
        const Gap(10),
        const Headline('Good mornings,\n*delivered.*'),
        const Gap(16),
        const MilkHero(),
        const Gap(10),
        ColorBlock(
          color: AppColors.teal,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Uttaranchal dairy team', style: T.display(25, color: AppColors.white)),
            const Gap(8),
            Text('Your route, customer quantities and delivery records—in one place.', style: T.sans(11.5, color: AppColors.white)),
          ]),
        ),
        const UField(label: 'Staff mobile number', initial: '98970 12345', prefixText: '+91', keyboard: TextInputType.phone),
        const UField(label: 'Verification code', initial: '2468', keyboard: TextInputType.number),
        const FinePrint('Staff access is assigned by the dairy team. This preview uses sample delivery data.'),
      ],
    );
  }
}

// ───────────────────────── 36 · Distribution dashboard ─────────────────────────
class StaffDashboardScreen extends StatelessWidget {
  const StaffDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final total = app.route.length;
    final done = app.completedStops;
    final next = app.nextStop;
    return UScaffold(
      title: 'Namaste, Ravi.',
      subtitle: _staffSubtitle,
      nav: NavKind.staff,
      navIndex: 0,
      trailing: IconTileButton(Icons.logout_rounded, onTap: () => _exit(context)),
      bottom: PrimaryButton(
        next == null ? 'Close today’s shift' : 'Continue my route',
        color: AppColors.teal,
        onTap: () {
          if (next == null) {
            goTab(context, R.staffSummary);
          } else {
            go(context, R.staffStop, args: next.number);
          }
        },
      ),
      children: [
        const Eyebrow('Morning shift · 7 November'),
        const Gap(10),
        const Headline('A fresh route.\nA *good morning.*'),
        const Gap(16),
        ColorBlock(
          color: AppColors.teal,
          onTap: () => goTab(context, R.staffRoute),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('PATEL  NAGAR  ·  ROUTE  A', style: T.sans(9.5, color: AppColors.white, weight: FontWeight.w700, spacing: 1.2)),
            const Gap(12),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('$total', style: T.display(44, color: AppColors.white)),
              const SizedBox(width: 8),
              Padding(padding: const EdgeInsets.only(bottom: 8), child: Text('households', style: T.sans(12, color: AppColors.white))),
            ]),
            Text('${app.assignedLitres} L assigned · 6:00–8:00 AM', style: T.sans(11.5, color: AppColors.white)),
            const Gap(14),
            UProgressBar(done / total),
            const Gap(10),
            Text('$done completed · ${app.pendingStops.length} remaining${app.exceptionStops > 0 ? ' · ${app.exceptionStops} exception' : ''}',
                style: T.sans(11, color: AppColors.white)),
          ]),
        ),
        const Gap(10),
        StatPair(
          StatCard('${app.deliveredLitres} L', 'Delivered so far'),
          StatCard('${app.assignedLitres - app.deliveredLitres} L', 'Remaining to deliver'),
        ),
        const Gap(4),
        ActionRow(
          icon: Icons.alt_route_rounded,
          title: 'Open route & stops',
          subtitle: next == null ? 'All stops completed' : 'Next: ${next.name} · ${next.litres} L',
          onTap: () => goTab(context, R.staffRoute),
        ),
        ActionRow(icon: Icons.inventory_2_outlined, title: 'Bottle returns & stock', subtitle: 'Record empty bottles and leftover milk', onTap: () => goTab(context, R.staffStock)),
        ActionRow(icon: Icons.task_alt_rounded, title: 'Close today’s shift', subtitle: 'Review quantities and exceptions', onTap: () => goTab(context, R.staffSummary), divider: false),
      ],
    );
  }
}

Future<void> _exit(BuildContext context) async {
  final ok = await confirmDialog(context, title: 'Leave staff app?', message: 'Return to the customer welcome screen. Route progress is kept for this demo.', confirm: 'Leave', color: AppColors.teal);
  if (ok && context.mounted) Navigator.of(context).pushNamedAndRemoveUntil(R.welcome, (_) => false);
}

// ───────────────────────── 37 · Route & delivery stops ─────────────────────────
class StaffRouteScreen extends StatefulWidget {
  const StaffRouteScreen({super.key});

  @override
  State<StaffRouteScreen> createState() => _StaffRouteScreenState();
}

class _StaffRouteScreenState extends State<StaffRouteScreen> {
  String _filter = 'Remaining';

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final next = app.nextStop;
    final stops = switch (_filter) {
      'Completed' => app.route.where((s) => s.status != StopStatus.scheduled).toList(),
      'All' => app.route,
      _ => app.pendingStops,
    };
    return UScaffold(
      title: 'Today’s route',
      subtitle: _staffSubtitle,
      nav: NavKind.staff,
      navIndex: 1,
      trailing: null,
      bottom: PrimaryButton(
        next == null ? 'View shift summary' : 'Open next delivery',
        color: AppColors.teal,
        onTap: () {
          if (next == null) {
            goTab(context, R.staffSummary);
          } else {
            go(context, R.staffStop, args: next.number);
          }
        },
      ),
      children: [
        const RouteMap(height: 160, animated: true),
        const Gap(16),
        Row(children: [
          Expanded(child: Text('Route A · Patel Nagar', style: T.display(26))),
          Pill('${app.pendingStops.length} left'),
        ]),
        const Gap(10),
        ChipGroup(options: const ['Remaining', 'Completed', 'All'], selected: _filter, onSelected: (v) => setState(() => _filter = v)),
        const Gap(6),
        if (stops.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Center(child: Text(_filter == 'Remaining' ? 'Every stop is done. Lovely work!' : 'No stops here yet.', style: T.body())),
          ),
        for (final s in stops) _StopRow(stop: s),
        const Gap(12),
        const Note('Paused subscriptions are excluded from today’s route. Open a stop to check the requested quantity.', tone: NoteTone.mint),
      ],
    );
  }
}

class _StopRow extends StatelessWidget {
  final DeliveryStop stop;
  const _StopRow({required this.stop});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (stop.status) {
      StopStatus.delivered => ('Delivered', AppColors.teal),
      StopStatus.exception => ('Exception', AppColors.berry),
      StopStatus.scheduled => ('Scheduled', AppColors.teal),
    };
    final done = stop.status != StopStatus.scheduled;
    return InkWell(
      onTap: () => go(context, R.staffStop, args: stop.number),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderSoft))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: done ? AppColors.mint : AppColors.peach, borderRadius: BorderRadius.circular(9)),
            child: done
                ? Icon(stop.status == StopStatus.delivered ? Icons.check_rounded : Icons.priority_high_rounded, size: 16, color: color)
                : Text('${stop.number}', style: T.sans(11.5, color: AppColors.berry, weight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(stop.name, style: T.title()),
              const Gap(2),
              Text('${stop.address.split(',').take(2).join(',')}\nFull Cream Milk', style: T.tiny()),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${stop.litres} L · ${rupees(stop.charge)}', style: T.sans(12, color: AppColors.teal, weight: FontWeight.w600)),
            const Gap(2),
            Text(label, style: T.sans(9.5, color: color, weight: FontWeight.w600)),
          ]),
        ]),
      ),
    );
  }
}

// ───────────────────────── 38 · Delivery stop details ─────────────────────────
class StaffStopScreen extends StatelessWidget {
  final int? stopNumber;
  const StaffStopScreen({super.key, this.stopNumber});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final s = app.stopByNumber(stopNumber);
    final done = s.status != StopStatus.scheduled;
    return UScaffold(
      title: 'Stop ${s.number} of ${app.route.length}',
      subtitle: _staffSubtitle,
      nav: NavKind.staff,
      navIndex: 0,
      trailing: IconTileButton(Icons.call_outlined, onTap: () => toast(context, 'Calling ${s.name}… (demo)')),
      bottom: done
          ? OutlineBtn('Back to route', color: AppColors.teal, onTap: () => Navigator.maybePop(context))
          : PrimaryButton('Record delivery', color: AppColors.teal, onTap: () => go(context, R.staffConfirm, args: s.number)),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Pill(switch (s.status) {
            StopStatus.delivered => 'Delivered · Prepaid',
            StopStatus.exception => 'Exception recorded',
            StopStatus.scheduled => 'Scheduled · Prepaid',
          }, bg: s.status == StopStatus.exception ? AppColors.pink : AppColors.mint, fg: s.status == StopStatus.exception ? AppColors.berry : AppColors.teal),
        ),
        const Gap(12),
        Text(s.name, style: T.display(36)),
        const Gap(6),
        Text('${s.address}\nMorning window · 6:00–7:00 AM', style: T.sans(12, color: AppColors.muted, height: 1.6)),
        const Gap(14),
        ColorBlock(
          color: AppColors.teal,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('TODAY’S  DELIVERY', style: T.sans(9.5, color: AppColors.white, weight: FontWeight.w700, spacing: 1.2)),
            const Gap(10),
            Text('${s.litres} L', style: T.display(52, color: AppColors.white)),
            Text('Full Cream Milk · ${s.litres} × 1 L bottle${s.litres == 1 ? '' : 's'}\nCharge after delivery: ${rupees(s.charge)}', style: T.sans(11.5, color: AppColors.white, height: 1.6)),
          ]),
        ),
        const Gap(10),
        UCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Delivery note', style: T.display(25)),
            const Gap(6),
            Text(s.note, style: T.sans(12)),
          ]),
        ),
        const Gap(10),
        KV('Empty bottles expected', '${s.bottles} bottle${s.bottles == 1 ? '' : 's'}'),
        const KV('Customer balance', 'Sufficient', color: AppColors.teal),
        if (!done)
          ActionRow(
            icon: Icons.priority_high_rounded,
            title: 'Unable to deliver?',
            subtitle: 'Record an exception and reason',
            onTap: () => go(context, R.staffException, args: s.number),
          ),
        const FinePrint('Confirm the actual quantity and delivery proof on the next screen.'),
      ],
    );
  }
}

// ───────────────────────── 39 · Confirm milk delivery ─────────────────────────
class StaffConfirmScreen extends StatefulWidget {
  final int? stopNumber;
  const StaffConfirmScreen({super.key, this.stopNumber});

  @override
  State<StaffConfirmScreen> createState() => _StaffConfirmScreenState();
}

class _StaffConfirmScreenState extends State<StaffConfirmScreen> {
  late final DeliveryStop s = context.appRead.stopByNumber(widget.stopNumber);
  late String _qty = '${s.litres} L · Full delivery';
  late int _bottles = s.bottles;

  int get _deliveredLitres => int.tryParse(_qty.split(' ').first) ?? s.litres;

  @override
  Widget build(BuildContext context) {
    final charge = _deliveredLitres * Milk.pricePerLitre;
    final qtyOptions = [for (var l = s.litres; l >= 1; l--) '$l L · ${l == s.litres ? 'Full' : 'Partial'} delivery'];
    return UScaffold(
      title: 'Freshness delivered',
      subtitle: _staffSubtitle,
      nav: NavKind.staff,
      navIndex: 0,
      trailing: null,
      bottom: PrimaryButton(
        'Confirm delivery · ${rupees(charge)}',
        color: AppColors.teal,
        onTap: () async {
          await showProcessing(context, 'Saving delivery…', duration: const Duration(milliseconds: 700));
          if (!context.mounted) return;
          context.appRead.markDelivered(s, bottles: _bottles);
          HapticFeedback.mediumImpact();
          final next = context.appRead.nextStop;
          await showSuccess(context,
              title: 'Delivered to ${s.name.split(' ').first}',
              message: next == null ? 'That was the last stop. Time to close your shift.' : 'Next up: ${next.name} · ${next.litres} L',
              cta: next == null ? 'Shift summary' : 'Next stop');
          if (!context.mounted) return;
          final nav = Navigator.of(context);
          if (next == null) {
            nav.pushNamedAndRemoveUntil(R.staffSummary, (_) => false, arguments: kTabSwitch);
          } else {
            nav.pushNamedAndRemoveUntil(R.staffStop, (r) => r.isFirst, arguments: next.number);
          }
        },
      ),
      children: [
        const Eyebrow('Delivery confirmation'),
        const Gap(10),
        const Headline('Every litre.\n*Properly recorded.*'),
        const Gap(16),
        ColorBlock(
          color: AppColors.teal,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.name, style: T.display(26, color: AppColors.white)),
            const Gap(6),
            Text('${s.address.split(',').take(2).join(',')} · Scheduled ${s.litres} L', style: T.sans(11.5, color: AppColors.white)),
          ]),
        ),
        UPicker(
          label: 'Quantity actually delivered',
          value: _qty,
          onTap: () async {
            final v = await pickOption(context, title: 'Quantity delivered', options: qtyOptions, selected: _qty);
            if (v != null) setState(() => _qty = v);
          },
        ),
        const UField(label: 'Customer delivery OTP', initial: '2468', keyboard: TextInputType.number),
        UPicker(
          label: 'Empty bottles collected',
          value: '$_bottles bottle${_bottles == 1 ? '' : 's'}',
          onTap: () async {
            final v = await pickOption(context, title: 'Empty bottles collected', options: const ['0 bottles', '1 bottle', '2 bottles', '3 bottles', '4 bottles'], selected: '$_bottles bottle${_bottles == 1 ? '' : 's'}');
            if (v != null) setState(() => _bottles = int.parse(v.split(' ').first));
          },
        ),
        const UField(label: 'Delivery note', initial: 'Handed to customer at the door.'),
        const Gap(14),
        Note(
          _deliveredLitres == s.litres
              ? 'Full delivery: ${rupees(charge)} will be debited from the customer’s prepaid milk balance. Partial deliveries use the actual delivered quantity.'
              : 'Partial delivery: only ${rupees(charge)} for $_deliveredLitres L will be debited. The shortfall is flagged for the dairy team.',
          tone: NoteTone.mint,
        ),
        const FinePrint('Prototype confirmation only. No customer balance is changed.'),
      ],
    );
  }
}

// ───────────────────────── 40 · Delivery exception ─────────────────────────
class StaffExceptionScreen extends StatefulWidget {
  final int? stopNumber;
  const StaffExceptionScreen({super.key, this.stopNumber});

  @override
  State<StaffExceptionScreen> createState() => _StaffExceptionScreenState();
}

class _StaffExceptionScreenState extends State<StaffExceptionScreen> {
  late final DeliveryStop s = context.appRead.stopByNumber(widget.stopNumber);
  String _reason = 'Customer unavailable';
  String _action = 'Hold for team review';

  @override
  Widget build(BuildContext context) {
    return UScaffold(
      title: 'A little change of plan',
      subtitle: _staffSubtitle,
      nav: NavKind.staff,
      navIndex: 0,
      trailing: null,
      bottom: PrimaryButton(
        'Save exception & continue',
        color: AppColors.teal,
        onTap: () {
          context.appRead.markException(s);
          toast(context, 'Exception saved for stop ${s.number}');
          Navigator.of(context).pushNamedAndRemoveUntil(R.staffRoute, (_) => false, arguments: kTabSwitch);
        },
      ),
      children: [
        const Eyebrow('Unable to complete delivery'),
        const Gap(10),
        const Headline('Keep the team\n*in the loop.*'),
        const Gap(16),
        UCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${s.name} · ${s.litres} L', style: T.display(25)),
            const Gap(4),
            Text('Stop ${s.number} · Patel Nagar', style: T.sans(12)),
          ]),
        ),
        UPicker(
          label: 'Reason',
          value: _reason,
          onTap: () async {
            final v = await pickOption(context,
                title: 'Reason', options: const ['Customer unavailable', 'Address not found', 'Customer refused', 'Short stock in van', 'Other'], selected: _reason);
            if (v != null) setState(() => _reason = v);
          },
        ),
        UPicker(
          label: 'Action',
          value: _action,
          onTap: () async {
            final v = await pickOption(context, title: 'Action', options: const ['Hold for team review', 'Retry later today', 'Leave with neighbour', 'Return to dairy'], selected: _action);
            if (v != null) setState(() => _action = v);
          },
        ),
        const UField(label: 'Notes', initial: 'Customer not available at the door. Team to confirm whether a retry is required.', maxLines: 3),
        const Gap(14),
        const Note('Undelivered quantities are not charged. A partial delivery must record the actual delivered quantity.'),
        const FinePrint('Exception reports are visible to the dairy team for follow-up.'),
      ],
    );
  }
}

// ───────────────────────── 41 · Bottle returns & stock ─────────────────────────
class StaffStockScreen extends StatefulWidget {
  const StaffStockScreen({super.key});

  @override
  State<StaffStockScreen> createState() => _StaffStockScreenState();
}

class _StaffStockScreenState extends State<StaffStockScreen> {
  String? _customer;
  String _adjustment = 'No adjustment';
  final _qty = TextEditingController(text: '2');

  @override
  void dispose() {
    _qty.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final customers = app.route.where((s) => s.status == StopStatus.delivered).map((s) => '${s.name} · ${s.bottles} bottle${s.bottles == 1 ? '' : 's'}').toList();
    final customer = _customer ?? (customers.isNotEmpty ? customers.last : 'No deliveries yet');
    final pending = (app.route.where((s) => s.status == StopStatus.delivered).fold<int>(0, (a, s) => a + s.bottles) + 12 - app.bottlesCollected).clamp(0, 999);
    return UScaffold(
      title: 'Keep every bottle counted',
      subtitle: _staffSubtitle,
      nav: NavKind.staff,
      navIndex: 2,
      trailing: null,
      bottom: PrimaryButton(
        'Save stock record',
        color: AppColors.teal,
        onTap: () {
          final n = int.tryParse(_qty.text) ?? 0;
          context.appRead.recordBottles(n);
          toast(context, 'Stock record saved · $n bottles');
          goTab(context, R.staffSummary);
        },
      ),
      children: [
        const Eyebrow('Route A · Stock reconciliation'),
        const Gap(10),
        const Headline('A complete round.\n*Nothing missed.*'),
        const Gap(16),
        StatPair(StatCard('${app.assignedLitres} L', 'Loaded at the dairy'), StatCard('${app.deliveredLitres} L', 'Delivered so far')),
        const Gap(10),
        UCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Column(children: [
            KV('Remaining milk', '${app.assignedLitres - app.deliveredLitres} L'),
            KV('Empty bottles collected', '${app.bottlesCollected}'),
            KV('Bottles pending collection', '$pending'),
          ]),
        ),
        UPicker(
          label: 'Record bottle return',
          value: customer,
          onTap: () async {
            if (customers.isEmpty) return;
            final v = await pickOption(context, title: 'Customer', options: customers.reversed.toList(), selected: customer);
            if (v != null) setState(() => _customer = v);
          },
        ),
        UField(label: 'Quantity collected', controller: _qty, keyboard: TextInputType.number, formatters: [FilteringTextInputFormatter.digitsOnly]),
        UPicker(
          label: 'Stock adjustment',
          value: _adjustment,
          onTap: () async {
            final v = await pickOption(context, title: 'Stock adjustment', options: const ['No adjustment', 'Bottle damaged', 'Milk spoiled', 'Extra milk issued'], selected: _adjustment);
            if (v != null) setState(() => _adjustment = v);
          },
        ),
        const FinePrint('Stock adjustments require a reason and remain visible in the shift summary.'),
      ],
    );
  }
}

// ───────────────────────── 42 · End-of-route summary ─────────────────────────
class StaffSummaryScreen extends StatelessWidget {
  const StaffSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final returned = app.assignedLitres - app.deliveredLitres;
    return UScaffold(
      title: 'A morning well delivered',
      subtitle: _staffSubtitle,
      nav: NavKind.staff,
      navIndex: 3,
      trailing: null,
      bottom: PrimaryButton(
        'Submit shift preview',
        color: AppColors.teal,
        onTap: () async {
          await showProcessing(context, 'Submitting shift…', duration: const Duration(milliseconds: 900));
          if (!context.mounted) return;
          await showSuccess(context, title: 'Shift submitted', message: 'The dairy team will reconcile your record. Thank you for a lovely morning, Ravi.', cta: 'Finish');
          if (context.mounted) Navigator.of(context).pushNamedAndRemoveUntil(R.welcome, (_) => false);
        },
      ),
      children: [
        const Center(child: CheckBadge(icon: Icons.local_drink_rounded)),
        const Gap(10),
        const Eyebrow('Route A · Shift summary', align: TextAlign.center),
        const Gap(10),
        const Headline('Fresh starts.\n*Happy homes.*', align: TextAlign.center),
        const Gap(16),
        StatPair(StatCard('${app.completedStops}', 'Completed stops'), StatCard('${app.deliveredLitres} L', 'Milk delivered')),
        const Gap(10),
        UCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Column(children: [
            KV('Assigned milk', '${app.assignedLitres} L'),
            KV('Delivered', '${app.deliveredLitres} L'),
            KV('Returned to dairy', '$returned L'),
            KV('Delivery exceptions', '${app.exceptionStops} stop${app.exceptionStops == 1 ? '' : 's'}'),
            KV('Milk charges recorded', rupees(app.chargesRecorded)),
            KV('Empty bottles collected', '${app.bottlesCollected}'),
          ]),
        ),
        const Gap(12),
        Note(
          app.pendingStops.isNotEmpty
              ? 'Review: ${app.pendingStops.length} stop${app.pendingStops.length == 1 ? '' : 's'} still scheduled and $returned L not yet delivered. Finish the route or record exceptions before submitting.'
              : 'Review: ${app.exceptionStops} undelivered stop${app.exceptionStops == 1 ? '' : 's'} and $returned L returned milk. The dairy team will reconcile the shift record.',
          tone: NoteTone.mint,
        ),
        const FinePrint('Final shift example. No charges are collected or records submitted in this design prototype.'),
      ],
    );
  }
}
