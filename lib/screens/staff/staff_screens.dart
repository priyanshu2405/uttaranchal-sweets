import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/nav.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../data/api.dart';
import '../../data/catalog.dart';
import '../../data/location.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';
import '../../widgets/fields.dart';
import '../../widgets/product_widgets.dart';
import '../../widgets/u_scaffold.dart';
import 'shop_staff_screens.dart' show staffSignOut;

// Milk delivery round for the staff app (server: Api/Staff/StaffMilkController).
// Delivery staff see their own route for today; admins can open any route.

const _subtitle = 'Uttaranchal Dairy · Milk round';

String _clock(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  return '$h:${d.minute.toString().padLeft(2, '0')} ${d.hour < 12 ? 'AM' : 'PM'}';
}

void _err(BuildContext context, Object e) => toast(context, e is ApiException ? e.message : 'Something went wrong. Please try again.');

bool _needsStaff(BuildContext context) {
  if (context.appRead.staffSignedIn) return false;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (context.mounted) Navigator.of(context).pushNamedAndRemoveUntil(R.staffSignIn, (r) => r.isFirst);
  });
  return true;
}

Future<void> _open(BuildContext context, Uri uri) async {
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && context.mounted) toast(context, 'Couldn’t open that');
}

Future<int?> _askNumber(BuildContext context, {required String title, required String label, int initial = 0, String? hint}) async {
  final c = TextEditingController(text: initial == 0 ? '' : '$initial');
  final v = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, MediaQuery.viewInsetsOf(ctx).bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: T.display(26)),
        if (hint != null) ...[const Gap(6), Text(hint, style: T.body())],
        UField(label: label, controller: c, keyboard: TextInputType.number, autofocus: true, formatters: [FilteringTextInputFormatter.digitsOnly]),
        const Gap(18),
        PrimaryButton('Save', color: AppColors.teal, icon: null, onTap: () => Navigator.pop(ctx, c.text.trim())),
      ]),
    ),
  );
  if (v == null) return null;
  return int.tryParse(v) ?? 0;
}

/// Loads the day on first open and shows a loader / error until it arrives.
abstract class _DayState<T extends StatefulWidget> extends State<T> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.appRead.staffSignedIn && (context.appRead.staffDay == null || reloadOnOpen)) context.appRead.loadStaffDay();
    });
  }

  bool get reloadOnOpen => true;

  Widget? loader(String title, {int navIndex = 0}) {
    final app = context.app;
    if (app.staffDay != null) return null;
    return UScaffold(title: title, subtitle: _subtitle, nav: NavKind.staff, navIndex: navIndex, trailing: null, children: [
      LoadState(loading: app.staffDayError == null, error: app.staffDayError, onRetry: () => context.appRead.loadStaffDay()),
      if (app.staffDayError != null && app.isDeliveryStaff) OutlineBtn('Sign out', icon: Icons.logout_rounded, onTap: () => staffSignOut(context)),
    ]);
  }
}

// ───────────────────────── 36 · Milk round (home) ─────────────────────────
class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends _DayState<StaffDashboardScreen> {
  bool _busy = false;

  Future<void> _start(StaffMilkDay day) async {
    final litres = await _askNumber(context, title: 'Start your round', label: 'Litres loaded', initial: day.sum('litres_planned'), hint: 'Today’s round needs ${day.sum('litres_planned')} L for ${day.stops.length} stops.');
    if (litres == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await context.appRead.staffStartShift(litresLoaded: litres, bottlesLoaded: litres);
      if (mounted) toast(context, 'Round started — have a good morning!');
    } catch (e) {
      if (mounted) _err(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_needsStaff(context)) return const Scaffold(backgroundColor: AppColors.cream);
    final wait = loader('Milk round');
    if (wait != null) return wait;
    final app = context.app;
    final day = app.staffDay!;
    final done = day.sum('delivered') + day.sum('exceptions');
    final total = day.stops.length;
    final next = day.next;
    return UScaffold(
      title: 'Namaste, ${(app.staffName ?? 'team').split(' ').first}.',
      subtitle: _subtitle,
      nav: NavKind.staff,
      navIndex: app.isDeliveryStaff ? 0 : 2,
      trailing: app.isDeliveryStaff ? IconTileButton(Icons.logout_rounded, onTap: () => staffSignOut(context)) : IconTileButton(Icons.refresh_rounded, onTap: () => context.appRead.loadStaffDay()),
      children: [
        if (day.routes.length > 1) ...[
          UPicker(
            label: 'Route',
            value: day.route.staffName == null || day.route.id == 0 ? day.route.name : '${day.route.name} · ${day.route.staffName}',
            icon: Icons.alt_route_rounded,
            onTap: () async {
              final labels = {for (final r in day.routes) r.staffName == null || r.id == 0 ? r.name : '${r.name} · ${r.staffName}': r.id};
              final v = await pickOption(context, title: 'Choose route', options: labels.keys.toList());
              if (v != null && context.mounted) context.appRead.loadStaffDay(routeId: labels[v]);
            },
          ),
          const Gap(10),
        ] else ...[
          Eyebrow('${day.route.name} · ${dayMonth(day.date)}'),
          const Gap(10),
        ],
        ColorBlock(
          color: AppColors.teal,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              day.shiftEnded != null
                  ? 'ROUND  FINISHED  ·  ${_clock(day.shiftEnded!)}'
                  : day.shiftStarted != null
                      ? 'ON  ROUND  SINCE  ${_clock(day.shiftStarted!)}'
                      : 'NOT  STARTED',
              style: T.sans(9.5, color: AppColors.white, weight: FontWeight.w700, spacing: 1.2),
            ),
            const Gap(10),
            Text('$done of $total stops', style: T.display(32, color: AppColors.white)),
            const Gap(8),
            UProgressBar(total == 0 ? 1.0 : (done / total).clamp(0.0, 1.0).toDouble()),
            const Gap(8),
            Text('${day.sum('litres_delivered')} of ${day.sum('litres_planned')} L delivered${day.litresLoaded > 0 ? ' · ${day.litresLoaded} L loaded' : ''}', style: T.sans(11.5, color: AppColors.white)),
          ]),
        ),
        const Gap(10),
        if (day.shiftStarted == null && total > 0)
          PrimaryButton(_busy ? 'Starting…' : 'Start my round', color: AppColors.teal, icon: Icons.play_arrow_rounded, onTap: _busy ? null : () => _start(day))
        else if (next != null)
          UCard(
            onTap: () => go(context, R.staffStop, args: next.id),
            child: Row(children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.berry, borderRadius: BorderRadius.circular(10)),
                child: Text('${next.position}', style: T.sans(14, color: AppColors.white, weight: FontWeight.w700)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Next: ${next.customerName}', style: T.title()),
                  Text('${next.litres} L · ${next.address}', style: T.small(), maxLines: 1, overflow: TextOverflow.ellipsis),
                ]),
              ),
              const Icon(Icons.chevron_right_rounded),
            ]),
          )
        else if (total > 0 && day.shiftEnded == null)
          PrimaryButton('All stops done — finish round', color: AppColors.teal, onTap: () => go(context, R.staffSummary)),
        if (total == 0) const LoadState(empty: 'No deliveries on this route today.'),
        const Gap(14),
        StatPair(StatCard('${day.sum('delivered')}', 'Delivered', valueColor: AppColors.teal), StatCard('${day.sum('exceptions')}', 'Not delivered')),
        const Gap(10),
        StatPair(StatCard('${day.sum('pending')}', 'To go', valueColor: AppColors.ink), StatCard(money(day.amountOf('cash_collected')), 'Cash collected', valueColor: AppColors.teal)),
        const Gap(6),
        ActionRow(icon: Icons.format_list_numbered_rounded, title: 'All stops', subtitle: '$total stops in order', onTap: () => go(context, R.staffRoute)),
        ActionRow(icon: Icons.inventory_2_outlined, title: 'Milk & bottles', subtitle: 'Loaded, delivered and empties', onTap: () => go(context, R.staffStock)),
        ActionRow(icon: Icons.summarize_outlined, title: 'Round summary', subtitle: day.shiftEnded != null ? 'Finished' : 'Finish your round here', onTap: () => go(context, R.staffSummary), divider: false),
      ],
    );
  }
}

// ───────────────────────── 37 · All stops ─────────────────────────
class StaffRouteScreen extends StatefulWidget {
  const StaffRouteScreen({super.key});

  @override
  State<StaffRouteScreen> createState() => _StaffRouteScreenState();
}

class _StaffRouteScreenState extends _DayState<StaffRouteScreen> {
  String _filter = 'To go';

  @override
  Widget build(BuildContext context) {
    if (_needsStaff(context)) return const Scaffold(backgroundColor: AppColors.cream);
    final app = context.app;
    final wait = loader('Stops', navIndex: app.isDeliveryStaff ? 1 : 2);
    if (wait != null) return wait;
    final day = app.staffDay!;
    final shown = switch (_filter) {
      'To go' => day.stops.where((s) => s.isPending).toList(),
      'Done' => day.stops.where((s) => !s.isPending).toList(),
      _ => day.stops,
    };
    return UScaffold(
      title: 'Stops · ${day.route.name}',
      subtitle: _subtitle,
      nav: NavKind.staff,
      navIndex: app.isDeliveryStaff ? 1 : 2,
      trailing: IconTileButton(Icons.refresh_rounded, onTap: () => context.appRead.loadStaffDay()),
      children: [
        ChipGroup(
          options: ['To go · ${day.sum('pending')}', 'Done · ${day.sum('delivered') + day.sum('exceptions')}', 'All · ${day.stops.length}'],
          selected: '$_filter · ${_filter == 'To go' ? day.sum('pending') : _filter == 'Done' ? day.sum('delivered') + day.sum('exceptions') : day.stops.length}',
          onSelected: (v) => setState(() => _filter = v.split(' · ').first),
        ),
        const Gap(12),
        if (app.staffDayLoading) const LinearProgressIndicator(minHeight: 2, color: AppColors.teal),
        if (shown.isEmpty) LoadState(empty: _filter == 'To go' ? 'Nothing left — well done!' : 'No stops here.'),
        for (final s in shown) _StopRow(s),
      ],
    );
  }
}

class _StopRow extends StatelessWidget {
  final MilkStop s;
  const _StopRow(this.s);

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon) = s.isDelivered
        ? (AppColors.mint, AppColors.teal, Icons.check_rounded)
        : s.isException
            ? (AppColors.pink, AppColors.berry, Icons.close_rounded)
            : (AppColors.peach, AppColors.ink, null);
    return InkWell(
      onTap: () => go(context, R.staffStop, args: s.id),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderSoft))),
        child: Row(children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9)),
            child: icon != null ? Icon(icon, size: 18, color: fg) : Text('${s.position}', style: T.sans(13, weight: FontWeight.w700, color: fg)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.customerName, style: T.title()),
              Text(s.address, style: T.small(), maxLines: 1, overflow: TextOverflow.ellipsis),
              if (s.isException) Text(s.statusLabel, style: T.tiny(AppColors.berry)),
            ]),
          ),
          Text('${s.litres} L', style: T.sans(14, weight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

// ───────────────────────── 38 · One stop ─────────────────────────
class StaffStopScreen extends StatefulWidget {
  /// The delivery id (from the stops list).
  final int? stopNumber;
  const StaffStopScreen({super.key, this.stopNumber});

  @override
  State<StaffStopScreen> createState() => _StaffStopScreenState();
}

class _StaffStopScreenState extends _DayState<StaffStopScreen> {
  bool _busy = false;

  @override
  bool get reloadOnOpen => false;

  Future<void> _run(Future<String> Function() action) async {
    setState(() => _busy = true);
    try {
      final msg = await action();
      if (mounted) toast(context, msg);
    } catch (e) {
      if (mounted) _err(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_needsStaff(context)) return const Scaffold(backgroundColor: AppColors.cream);
    final app = context.app;
    final wait = loader('Stop');
    if (wait != null) return wait;
    final s = app.staffDay!.stopById(widget.stopNumber) ?? app.staffDay!.next;
    if (s == null) {
      return UScaffold(title: 'Stop', subtitle: _subtitle, trailing: null, children: const [LoadState(empty: 'This stop is no longer on today’s list.')]);
    }
    return UScaffold(
      title: 'Stop ${s.position}',
      subtitle: _subtitle,
      trailing: null,
      bottom: s.isPending
          ? Row(children: [
              Expanded(child: OutlineBtn('Not delivered', icon: null, onTap: _busy ? null : () => go(context, R.staffException, args: s.id))),
              const SizedBox(width: 10),
              Expanded(child: PrimaryButton('Delivered', color: AppColors.teal, icon: Icons.check_rounded, onTap: _busy ? null : () => go(context, R.staffConfirm, args: s.id))),
            ])
          : OutlineBtn(_busy ? 'Please wait…' : 'Undo — mark as not done yet', icon: Icons.undo_rounded, onTap: _busy ? null : () => _run(() => context.appRead.staffUndo(s.id))),
      children: [
        Row(children: [
          Pill(s.isPending ? 'To deliver' : s.statusLabel, bg: s.isDelivered ? AppColors.mint : (s.isException ? AppColors.pink : AppColors.yellowSoft), fg: s.isException ? AppColors.berry : AppColors.teal),
          const Spacer(),
          Text(s.subscriptionNumber, style: T.tiny()),
        ]),
        const Gap(10),
        Text(s.customerName, style: T.display(34)),
        Text('${s.address} · ${s.pincode}', style: T.body()),
        const Gap(12),
        Row(children: [
          Expanded(child: OutlineBtn('Call', icon: Icons.call_outlined, color: AppColors.teal, onTap: () => _open(context, Uri.parse('tel:${s.phone}')))),
          const SizedBox(width: 10),
          Expanded(
            child: OutlineBtn('Directions', icon: Icons.near_me_outlined, color: AppColors.teal, onTap: () => _open(context, Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('${s.address}, ${s.pincode}')}'))),
          ),
        ]),
        const Gap(14),
        ColorBlock(
          color: AppColors.teal,
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${s.litres} L', style: T.display(40, color: AppColors.white)),
                Text('${s.slotLabel} · ${money(s.amount)}', style: T.sans(11.5, color: AppColors.white)),
              ]),
            ),
            const Icon(Icons.local_drink_rounded, color: AppColors.white, size: 40),
          ]),
        ),
        if (s.customerNote != null && s.customerNote!.isNotEmpty) ...[const Gap(10), Note('Customer note: ${s.customerNote}', tone: NoteTone.mint)],
        if (s.note != null && s.note!.isNotEmpty) ...[const Gap(10), Note('Your note: ${s.note}')],
        const Gap(10),
        UCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Column(children: [
            KV('Milk balance', money(s.balance), color: s.lowBalance ? AppColors.berry : null),
            if (s.deliveredAt != null) KV('Delivered at', _clock(s.deliveredAt!)),
            if (s.bottlesBack > 0) KV('Empty bottles collected', '${s.bottlesBack}'),
          ]),
        ),
        if (s.lowBalance) ...[const Gap(8), const Note('Balance is low — remind the customer to top up, or collect cash.')],
        const Gap(10),
        ActionRow(
          icon: Icons.payments_outlined,
          title: 'Record cash payment',
          subtitle: 'Added to the customer’s milk balance',
          onTap: _busy
              ? null
              : () async {
                  final amt = await _askNumber(context, title: 'Cash collected', label: 'Amount (₹)', hint: 'From ${s.customerName}.');
                  if (amt != null && amt > 0 && context.mounted) _run(() => context.appRead.staffCash(s.id, amt.toDouble()));
                },
        ),
        ActionRow(
          icon: Icons.photo_camera_outlined,
          title: 'Report damaged bottle / packet',
          subtitle: 'Photo, place and time go to the shop for approval',
          onTap: () => go(context, R.staffDamage, args: s.id),
          divider: false,
        ),
      ],
    );
  }
}

// ───────────────────────── 39 · Confirm delivery ─────────────────────────
class StaffConfirmScreen extends StatefulWidget {
  final int? stopNumber;
  const StaffConfirmScreen({super.key, this.stopNumber});

  @override
  State<StaffConfirmScreen> createState() => _StaffConfirmScreenState();
}

class _StaffConfirmScreenState extends State<StaffConfirmScreen> {
  int _bottles = 0;
  final _note = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _confirm(MilkStop s) async {
    setState(() => _busy = true);
    try {
      final msg = await context.appRead.staffDeliver(s.id, bottlesBack: _bottles, note: _note.text.trim());
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      toast(context, msg);
      final next = context.appRead.staffDay?.next;
      final nav = Navigator.of(context);
      nav.popUntil((r) => r.settings.name == R.staffRoute || r.settings.name == R.staffDashboard || r.isFirst);
      if (next != null) nav.pushNamed(R.staffStop, arguments: next.id);
    } catch (e) {
      if (mounted) _err(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.app.staffDay?.stopById(widget.stopNumber);
    if (s == null) return UScaffold(title: 'Confirm delivery', subtitle: _subtitle, trailing: null, children: const [LoadState(empty: 'Stop not found.')]);
    return UScaffold(
      title: 'Confirm delivery',
      subtitle: _subtitle,
      trailing: null,
      bottom: PrimaryButton(_busy ? 'Saving…' : 'Confirm ${s.litres} L delivered', color: AppColors.teal, icon: Icons.check_rounded, onTap: _busy ? null : () => _confirm(s)),
      children: [
        Text(s.customerName, style: T.display(32)),
        Text(s.address, style: T.body()),
        const Gap(16),
        ColorBlock(
          color: AppColors.mint,
          child: Row(children: [
            const Icon(Icons.local_drink_rounded, color: AppColors.teal, size: 30),
            const SizedBox(width: 12),
            Expanded(child: Text('${s.litres} L handed over · ${money(s.amount)} charged to their milk balance', style: T.sans(12.5, color: AppColors.teal, weight: FontWeight.w600))),
          ]),
        ),
        const Gap(16),
        Row(children: [
          Expanded(child: Text('Empty bottles collected', style: T.sans(13, weight: FontWeight.w600))),
          QtyStepper(value: _bottles, min: 0, max: 20, onChanged: (v) => setState(() => _bottles = v)),
        ]),
        UField(label: 'Note (optional)', controller: _note, hint: 'e.g. left with neighbour'),
      ],
    );
  }
}

// ───────────────────────── 40 · Not delivered ─────────────────────────
class StaffExceptionScreen extends StatefulWidget {
  final int? stopNumber;
  const StaffExceptionScreen({super.key, this.stopNumber});

  @override
  State<StaffExceptionScreen> createState() => _StaffExceptionScreenState();
}

class _StaffExceptionScreenState extends State<StaffExceptionScreen> {
  String? _reason;
  final _note = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save(MilkStop s) async {
    if (_reason == null) {
      toast(context, 'Choose what happened');
      return;
    }
    setState(() => _busy = true);
    try {
      final msg = await context.appRead.staffException(s.id, reason: _reason!, note: _note.text.trim());
      if (!mounted) return;
      toast(context, msg);
      Navigator.of(context).popUntil((r) => r.settings.name == R.staffRoute || r.settings.name == R.staffDashboard || r.isFirst);
    } catch (e) {
      if (mounted) _err(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final day = context.app.staffDay;
    final s = day?.stopById(widget.stopNumber);
    if (s == null || day == null) return UScaffold(title: 'Not delivered', subtitle: _subtitle, trailing: null, children: const [LoadState(empty: 'Stop not found.')]);
    return UScaffold(
      title: 'Not delivered',
      subtitle: _subtitle,
      trailing: null,
      bottom: PrimaryButton(_busy ? 'Saving…' : 'Save — no charge', onTap: _busy ? null : () => _save(s)),
      children: [
        Text(s.customerName, style: T.display(30)),
        Text(s.address, style: T.body()),
        const Gap(14),
        const FieldLabel('What happened?'),
        for (final r in day.exceptionReasons)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: _reason == r.key ? AppColors.pink : AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: _reason == r.key ? AppColors.berry : AppColors.border)),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => _reason = r.key),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    Icon(_reason == r.key ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, size: 20, color: AppColors.berry),
                    const SizedBox(width: 10),
                    Expanded(child: Text(r.label, style: T.sans(13, weight: FontWeight.w600))),
                  ]),
                ),
              ),
            ),
          ),
        UField(label: 'Note for the shop (optional)', controller: _note, maxLines: 2),
        const Gap(10),
        const Note('The customer is not charged, and the shop sees this straight away.'),
      ],
    );
  }
}

// ───────────────────────── 41 · Milk & bottles ─────────────────────────
class StaffStockScreen extends StatefulWidget {
  const StaffStockScreen({super.key});

  @override
  State<StaffStockScreen> createState() => _StaffStockScreenState();
}

class _StaffStockScreenState extends _DayState<StaffStockScreen> {
  @override
  Widget build(BuildContext context) {
    if (_needsStaff(context)) return const Scaffold(backgroundColor: AppColors.cream);
    final app = context.app;
    final wait = loader('Milk & bottles');
    if (wait != null) return wait;
    final day = app.staffDay!;
    final remaining = day.litresLoaded - day.sum('litres_delivered');
    return UScaffold(
      title: 'Milk & bottles',
      subtitle: _subtitle,
      nav: NavKind.staff,
      navIndex: app.isDeliveryStaff ? 0 : 2,
      trailing: null,
      children: [
        StatPair(StatCard('${day.litresLoaded} L', 'Loaded', valueColor: AppColors.ink), StatCard('${day.sum('litres_delivered')} L', 'Delivered', valueColor: AppColors.teal)),
        const Gap(10),
        StatPair(StatCard('${remaining < 0 ? 0 : remaining} L', 'Still on the van', valueColor: AppColors.ink), StatCard('${day.sum('bottles_back')}', 'Empties collected', valueColor: AppColors.teal)),
        const Gap(14),
        UCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Column(children: [
            KV('Planned for today', '${day.sum('litres_planned')} L · ${day.stops.length} stops'),
            KV('Not delivered', '${day.sum('exceptions')} stops'),
            KV('Bottles handed out', '${day.sum('bottles_out')}'),
          ]),
        ),
        const Gap(12),
        _DamageSection(day),
        const Gap(12),
        OutlineBtn(
          'Update litres loaded',
          icon: Icons.edit_outlined,
          color: AppColors.teal,
          onTap: () async {
            final n = await _askNumber(context, title: 'Litres loaded', label: 'Litres', initial: day.litresLoaded);
            if (n == null || !context.mounted) return;
            try {
              await context.appRead.staffStartShift(litresLoaded: n, bottlesLoaded: n);
            } catch (e) {
              if (context.mounted) _err(context, e);
            }
          },
        ),
      ],
    );
  }
}

// ───────────────────────── 42 · Round summary ─────────────────────────
class StaffSummaryScreen extends StatefulWidget {
  const StaffSummaryScreen({super.key});

  @override
  State<StaffSummaryScreen> createState() => _StaffSummaryScreenState();
}

class _StaffSummaryScreenState extends _DayState<StaffSummaryScreen> {
  final _note = TextEditingController();
  int? _empties;
  int? _returned;
  bool _busy = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _finish(StaffMilkDay day) async {
    if (day.sum('pending') > 0) {
      final ok = await confirmDialog(context, title: '${day.sum('pending')} stops not done', message: 'Finish anyway? Those customers will show as not visited until you mark them.', confirm: 'Finish round', color: AppColors.teal);
      if (!ok || !mounted) return;
    }
    setState(() => _busy = true);
    try {
      await context.appRead.staffEndShift(bottlesReturned: _empties ?? day.sum('bottles_back'), litresReturned: _returned ?? day.litresReturned, note: _note.text.trim());
      if (mounted) toast(context, 'Round finished — the shop can see your summary');
    } catch (e) {
      if (mounted) _err(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_needsStaff(context)) return const Scaffold(backgroundColor: AppColors.cream);
    final app = context.app;
    final wait = loader('Round summary', navIndex: app.isDeliveryStaff ? 2 : 2);
    if (wait != null) return wait;
    final day = app.staffDay!;
    final finished = day.shiftEnded != null;
    final empties = _empties ?? (finished ? day.bottlesReturned : day.sum('bottles_back'));
    return UScaffold(
      title: 'Round summary',
      subtitle: _subtitle,
      nav: NavKind.staff,
      navIndex: 2,
      trailing: null,
      bottom: PrimaryButton(_busy ? 'Saving…' : (finished ? 'Update summary' : 'Finish my round'), color: AppColors.teal, onTap: _busy ? null : () => _finish(day)),
      children: [
        Eyebrow('${day.route.name} · ${dayMonth(day.date)}'),
        const Gap(10),
        Text(finished ? 'Round finished at ${_clock(day.shiftEnded!)}' : 'Wrapping up', style: T.display(30)),
        const Gap(14),
        StatPair(StatCard('${day.sum('delivered')}', 'Delivered', valueColor: AppColors.teal), StatCard('${day.sum('exceptions')}', 'Not delivered')),
        const Gap(10),
        StatPair(StatCard('${day.sum('litres_delivered')} L', 'Milk delivered', valueColor: AppColors.ink), StatCard(money(day.amountOf('cash_collected')), 'Cash collected', valueColor: AppColors.teal)),
        const Gap(14),
        if (day.exceptionCounts.isNotEmpty)
          UCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Column(children: [for (final (reason, n) in day.exceptionCounts) KV(reason, '$n')]),
          ),
        const Gap(10),
        Row(children: [
          Expanded(child: Text('Empty bottles returned to the shop', style: T.sans(13, weight: FontWeight.w600))),
          QtyStepper(value: empties, min: 0, max: 500, onChanged: (v) => setState(() => _empties = v)),
        ]),
        const Gap(10),
        Row(children: [
          Expanded(child: Text('Unsold milk brought back (litres)', style: T.sans(13, weight: FontWeight.w600))),
          QtyStepper(value: _returned ?? day.litresReturned, min: 0, max: 500, onChanged: (v) => setState(() => _returned = v)),
        ]),
        _DamageSection(day),
        UField(label: 'Note for the shop (optional)', controller: _note, maxLines: 2),
        const Gap(10),
        if (app.isDeliveryStaff) Center(child: TextButton(onPressed: () => staffSignOut(context), child: Text('Sign out', style: T.sans(12.5, color: AppColors.muted)))),
      ],
    );
  }
}

// ───────────────────────── Report damaged milk ─────────────────────────
/// Camera-only photo + location + time. The shop approves it in Admin → Damage Reports;
/// approved damage is counted in the delivery person's milk stock.
class StaffDamageScreen extends StatefulWidget {
  /// Optional: the stop where it happened.
  final int? deliveryId;
  const StaffDamageScreen({super.key, this.deliveryId});

  @override
  State<StaffDamageScreen> createState() => _StaffDamageScreenState();
}

class _StaffDamageScreenState extends State<StaffDamageScreen> {
  XFile? _photo;
  DateTime? _takenAt;
  double? _lat;
  double? _lng;
  double? _accuracy;
  bool _locating = false;
  String? _item;
  int _count = 1;
  String? _reason;
  final _note = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    try {
      final x = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 70, maxWidth: 1600, maxHeight: 1600, preferredCameraDevice: CameraDevice.rear);
      if (x == null || !mounted) return;
      setState(() {
        _photo = x;
        _takenAt = DateTime.now();
        _locating = true;
      });
      final pos = await currentPositionOrNull();
      if (!mounted) return;
      setState(() {
        _lat = pos?.latitude;
        _lng = pos?.longitude;
        _accuracy = pos?.accuracy;
        _locating = false;
      });
      if (pos == null) toast(context, 'Location is off or not allowed. Turn it on so the shop can approve your report.');
    } catch (e) {
      if (mounted) toast(context, 'Couldn’t open the camera. Please allow camera access in Settings.');
    }
  }

  Future<void> _submit() async {
    final day = context.appRead.staffDay;
    if (_photo == null) {
      toast(context, 'Please take a photo of the damaged milk');
      return;
    }
    final item = _item ?? (day != null && day.damageItems.isNotEmpty ? day.damageItems.first.key : 'bottle');
    if (_reason == null) {
      toast(context, 'Choose what happened');
      return;
    }
    if (_lat == null) {
      final ok = await confirmDialog(context, title: 'Send without location?', message: 'The shop may reject reports without a location. You can turn location on and retake the photo instead.', confirm: 'Send anyway', color: AppColors.teal);
      if (!ok || !mounted) return;
    }
    setState(() => _busy = true);
    try {
      final msg = await context.appRead.staffReportDamage(
        photoPath: _photo!.path,
        itemType: item,
        count: _count,
        reason: _reason!,
        note: _note.text.trim(),
        latitude: _lat,
        longitude: _lng,
        accuracy: _accuracy,
        capturedAt: _takenAt ?? DateTime.now(),
        deliveryId: widget.deliveryId,
      );
      if (!mounted) return;
      toast(context, msg);
      Navigator.maybePop(context);
    } catch (e) {
      if (mounted) _err(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final day = context.app.staffDay;
    final items = day?.damageItems.isNotEmpty == true ? day!.damageItems : const [DamageItem('bottle', 'Bottle', 1), DamageItem('packet', 'Packet', 0.5)];
    final reasons = day?.damageReasons ?? const <KeyLabel>[];
    final item = items.firstWhere((i) => i.key == (_item ?? items.first.key), orElse: () => items.first);
    final litres = item.litres * _count;
    final stop = day?.stopById(widget.deliveryId);
    String fmt(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
    return UScaffold(
      title: 'Report damage',
      subtitle: _subtitle,
      trailing: null,
      bottom: PrimaryButton(_busy ? 'Sending…' : 'Send to the shop', color: AppColors.teal, icon: Icons.send_rounded, onTap: _busy ? null : _submit),
      children: [
        const Eyebrow('Damaged bottle or packet'),
        const Gap(10),
        Text('Take a photo right now', style: T.display(28)),
        const Gap(4),
        Text('The shop checks the photo, place and time before approving. Approved damage isn’t counted as a shortage on your round.', style: T.small()),
        if (stop != null) ...[const Gap(10), Note('At stop ${stop.position}: ${stop.customerName}', tone: NoteTone.mint)],
        const Gap(14),
        GestureDetector(
          onTap: _busy ? null : _takePhoto,
          child: Container(
            height: 220,
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
            child: _photo == null
                ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.photo_camera_rounded, size: 46, color: AppColors.teal),
                    const Gap(8),
                    Text('Open camera', style: T.sans(14, weight: FontWeight.w700, color: AppColors.teal)),
                    Text('Photos from the gallery can’t be used', style: T.tiny()),
                  ])
                : Stack(fit: StackFit.expand, children: [
                    Image.file(File(_photo!.path), fit: BoxFit.cover),
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: SmallButton('Retake', icon: Icons.refresh_rounded, color: AppColors.teal, onTap: _busy ? null : _takePhoto),
                    ),
                  ]),
          ),
        ),
        if (_photo != null) ...[
          const Gap(10),
          UCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Column(children: [
              KV('Date & time', _takenAt == null ? '—' : '${dayMonth(_takenAt!)} ${_takenAt!.year}, ${_clock(_takenAt!)}'),
              KV('Location', _locating ? 'Finding…' : (_lat == null ? 'Not available' : '${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}'), color: !_locating && _lat == null ? AppColors.berry : null),
              if (_accuracy != null) KV('Accuracy', '±${_accuracy!.round()} m'),
            ]),
          ),
        ],
        const FieldLabel('What was damaged?'),
        ChipGroup(options: items.map((i) => '${i.label} (${fmt(i.litres)} L)').toList(), selected: '${item.label} (${fmt(item.litres)} L)', onSelected: (v) => setState(() => _item = items.firstWhere((i) => v.startsWith(i.label)).key)),
        const Gap(12),
        Row(children: [
          Expanded(child: Text('How many?', style: T.sans(13, weight: FontWeight.w600))),
          QtyStepper(value: _count, min: 1, max: 100, onChanged: (v) => setState(() => _count = v)),
        ]),
        const Gap(4),
        Text('${fmt(litres)} litres of milk', style: T.small(AppColors.teal)),
        const FieldLabel('What happened?'),
        ChipGroup(
          options: reasons.map((r) => r.label).toList(),
          selected: reasons.firstWhere((r) => r.key == _reason, orElse: () => const KeyLabel('', '')).label,
          scroll: false,
          onSelected: (v) => setState(() => _reason = reasons.firstWhere((r) => r.label == v).key),
        ),
        UField(label: 'Note (optional)', controller: _note, maxLines: 2, hint: 'e.g. crate slipped at the gate'),
      ],
    );
  }
}

/// Damage reports and stock check for today — shown on the bottles screen and the round summary.
class _DamageSection extends StatelessWidget {
  final StaffMilkDay day;
  const _DamageSection(this.day);

  @override
  Widget build(BuildContext context) {
    String fmt(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Gap(16),
      Row(children: [
        Expanded(child: Text('Damaged milk', style: T.display(22))),
        SmallButton('Report damage', icon: Icons.photo_camera_outlined, color: AppColors.teal, onTap: () => go(context, R.staffDamage)),
      ]),
      const Gap(8),
      if (day.damageReports.isEmpty) Text('No damage reported today.', style: T.small()),
      for (final r in day.damageReports)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderSoft))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(
              r.status == 'approved' ? Icons.check_circle_rounded : (r.status == 'rejected' ? Icons.cancel_rounded : Icons.hourglass_top_rounded),
              size: 20,
              color: r.status == 'approved' ? AppColors.teal : (r.status == 'rejected' ? AppColors.berry : AppColors.muted),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${r.count} × ${r.itemLabel} · ${fmt(r.litres)} L', style: T.sans(13, weight: FontWeight.w600)),
                Text('${r.reasonLabel}${r.capturedAt != null ? ' · ${_clock(r.capturedAt!)}' : ''}', style: T.tiny()),
                if (r.status == 'rejected' && r.reviewNote != null) Text('Shop: ${r.reviewNote}', style: T.tiny(AppColors.berry)),
              ]),
            ),
            Text(r.statusLabel, style: T.tiny(r.status == 'approved' ? AppColors.teal : (r.status == 'rejected' ? AppColors.berry : AppColors.muted))),
          ]),
        ),
      if (day.litresLoaded > 0) ...[
        const Gap(14),
        UCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Column(children: [
            KV('Milk loaded', '${fmt(day.stockOf('loaded'))} L'),
            KV('Delivered', '${fmt(day.stockOf('delivered'))} L'),
            KV('Damaged (approved)', '${fmt(day.stockOf('damaged_approved'))} L'),
            if (day.stockOf('damaged_pending') > 0) KV('Damaged (waiting for shop)', '${fmt(day.stockOf('damaged_pending'))} L', color: AppColors.muted),
            KV('Returned unsold', '${fmt(day.stockOf('returned'))} L'),
            const DashedDivider(),
            KV(day.stockOf('shortage') > 0 ? 'Not accounted for' : 'Stock check', day.stockOf('shortage') > 0 ? '${fmt(day.stockOf('shortage'))} L' : 'Balanced', strong: true, color: day.stockOf('shortage') > 0 ? AppColors.berry : AppColors.teal),
          ]),
        ),
        const FinePrint('Loaded = delivered + approved damage + returned. Damage waiting for approval counts once the shop approves it.'),
      ],
    ]);
  }
}
