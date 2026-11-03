import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/nav.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../config.dart';
import '../../data/api.dart';
import '../../data/catalog.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';
import '../../widgets/fields.dart';
import '../../widgets/illustrations.dart';
import '../../widgets/product_widgets.dart';
import '../../widgets/u_scaffold.dart';
import '../orders/order_screens.dart' show orderDate;

const _subtitle = 'Uttaranchal Dairy · Staff';

Future<void> staffSignOut(BuildContext context) async {
  final ok = await confirmDialog(context, title: 'Sign out of the staff app?', message: 'You’ll go back to the customer welcome screen.', confirm: 'Sign out', color: AppColors.teal);
  if (!ok || !context.mounted) return;
  await context.appRead.staffLogout();
  if (context.mounted) Navigator.of(context).pushNamedAndRemoveUntil(R.welcome, (_) => false);
}

/// Redirects to staff sign-in when the staff token is missing or expired.
bool _needsLogin(BuildContext context) {
  if (context.appRead.staffSignedIn) return false;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (context.mounted) Navigator.of(context).pushNamedAndRemoveUntil(R.staffSignIn, (r) => r.isFirst);
  });
  return true;
}

// ───────────────────────── 35 · Staff sign in ─────────────────────────
class StaffSignInScreen extends StatefulWidget {
  const StaffSignInScreen({super.key});

  @override
  State<StaffSignInScreen> createState() => _StaffSignInScreenState();
}

class _StaffSignInScreenState extends State<StaffSignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_email.text.contains('@') || _password.text.isEmpty) {
      toast(context, 'Enter your staff email and password');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      await context.appRead.staffLogin(_email.text.trim(), _password.text);
      if (mounted) goTab(context, R.staffOrders);
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return UScaffold(
      title: 'Shop staff',
      trailing: null,
      bottom: PrimaryButton(_busy ? 'Signing in…' : 'Open shop orders', color: AppColors.teal, onTap: _busy ? null : _submit),
      children: [
        const Eyebrow('Staff app'),
        const Gap(10),
        const Headline('Every order,\n*right here.*'),
        const Gap(16),
        const MilkHero(),
        const Gap(10),
        ColorBlock(
          color: AppColors.teal,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Website + app orders', style: T.display(25, color: AppColors.white)),
            const Gap(8),
            Text('Sign in with the same email and password you use for the website admin panel.', style: T.sans(11.5, color: AppColors.white)),
          ]),
        ),
        UField(label: 'Staff email', controller: _email, keyboard: TextInputType.emailAddress),
        UField(label: 'Password', controller: _password, obscure: true, onSubmitted: (_) => _submit()),
        const FinePrint('Staff accounts are managed in the website admin under Staff.'),
      ],
    );
  }
}

// ───────────────────────── Shop orders (live) ─────────────────────────
class StaffOrdersScreen extends StatefulWidget {
  const StaffOrdersScreen({super.key});

  @override
  State<StaffOrdersScreen> createState() => _StaffOrdersScreenState();
}

class _StaffOrdersScreenState extends State<StaffOrdersScreen> {
  static const _tabs = [('New', 'received'), ('Preparing', 'preparing'), ('On the way', 'dispatched'), ('Done', 'delivered'), ('All', null)];
  int _tab = 0;
  List<ShopOrder>? _orders;
  Map<String, int> _counts = const {};
  StaffDashboard? _dash;
  String? _error;
  String _q = '';
  Timer? _timer;
  Timer? _debounce;
  final Set<int> _busy = {};
  Set<int> _seen = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    _timer = Timer.periodic(kStaffRefreshEvery, (_) => _load(quiet: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _load({bool quiet = false}) async {
    final app = context.appRead;
    if (!app.staffSignedIn) return;
    try {
      final results = await Future.wait([
        app.staffOrders(status: _tabs[_tab].$2, query: _q.isEmpty ? null : _q),
        app.staffDashboard(),
      ]);
      if (!mounted) return;
      final (orders, counts) = results[0] as (List<ShopOrder>, Map<String, int>);
      final dash = results[1] as StaffDashboard;
      // Buzz when a brand-new order arrives while the screen is open.
      final newIds = orders.where((o) => o.status == 'received').map((o) => o.id).toSet();
      if (quiet && _seen.isNotEmpty && newIds.difference(_seen).isNotEmpty) {
        HapticFeedback.heavyImpact();
        toast(context, 'New order received');
      }
      if (_tab == 0 || _seen.isEmpty) _seen = {..._seen, ...newIds};
      setState(() {
        _orders = orders;
        _counts = counts;
        _dash = dash;
        _error = null;
      });
    } on ApiException catch (e) {
      if (mounted && !quiet) setState(() => _error = e.message);
    }
  }

  Future<void> _advance(ShopOrder o) async {
    setState(() => _busy.add(o.id));
    try {
      await context.appRead.staffAdvance(o.id);
      if (mounted) toast(context, '${o.number} moved on — the customer has been emailed');
      await _load(quiet: true);
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message);
    } finally {
      if (mounted) setState(() => _busy.remove(o.id));
    }
  }

  String _nextLabel(ShopOrder o) => switch (o.nextStatus) {
        'preparing' => 'Start preparing',
        'dispatched' => switch (o.deliveryMethod) { 'pickup' => 'Ready for pickup', 'courier' => 'Mark shipped', _ => 'Out for delivery' },
        'delivered' => o.isPickup ? 'Mark collected' : 'Mark delivered',
        _ => '',
      };

  @override
  Widget build(BuildContext context) {
    if (_needsLogin(context)) return const Scaffold(backgroundColor: AppColors.cream);
    final app = context.app;
    final d = _dash;
    return UScaffold(
      title: 'Namaste, ${(app.staffName ?? 'team').split(' ').first}.',
      subtitle: _subtitle,
      nav: NavKind.staff,
      navIndex: 0,
      trailing: IconTileButton(Icons.logout_rounded, onTap: () => staffSignOut(context)),
      children: [
        if (d != null) ...[
          StatPair(StatCard(money(d.todayRevenue), 'Sales today'), StatCard('${d.ordersToday}', 'Orders today')),
          const Gap(10),
          StatPair(StatCard('${d.newOrders}', 'New — not started'), StatCard('${d.outNow}', 'Out / ready now', valueColor: AppColors.teal)),
          if (d.lowStock.isNotEmpty) ...[
            const Gap(10),
            Note('Low stock: ${d.lowStock.map((p) => '${p.$2} (${p.$3})').join(', ')}'),
          ],
          const Gap(14),
        ],
        USearchBox(
          hint: 'Search order no., name, phone',
          onChanged: (v) {
            _q = v.trim();
            _debounce?.cancel();
            _debounce = Timer(const Duration(milliseconds: 400), _load);
          },
        ),
        const Gap(12),
        ChipGroup(
          options: [for (final t in _tabs) t.$2 == null ? t.$1 : '${t.$1} · ${_counts[t.$2] ?? 0}'],
          selected: _tabs[_tab].$2 == null ? _tabs[_tab].$1 : '${_tabs[_tab].$1} · ${_counts[_tabs[_tab].$2] ?? 0}',
          scroll: true,
          onSelected: (v) {
            setState(() {
              _tab = _tabs.indexWhere((t) => v.startsWith(t.$1));
              _orders = null;
            });
            _load();
          },
        ),
        const Gap(14),
        if (_error != null)
          LoadState(error: _error, onRetry: _load)
        else if (_orders == null)
          const LoadState(loading: true)
        else if (_orders!.isEmpty)
          const LoadState(empty: 'No orders here right now.')
        else
          for (final o in _orders!) ...[
            UCard(
              onTap: () async {
                await go(context, R.staffOrder, args: o.id);
                _load(quiet: true);
              },
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text('#${o.number}', style: T.sans(13, weight: FontWeight.w700))),
                  Pill(o.statusLabel, bg: o.status == 'received' ? AppColors.pink : AppColors.mint, fg: o.status == 'received' ? AppColors.berry : AppColors.teal),
                ]),
                const Gap(6),
                Text('${o.customerName} · +91 ${o.phone}', style: T.sans(12.5, weight: FontWeight.w600)),
                Text('${o.deliveryLabel.split(' · ').first}${o.deliverySlotLabel != null ? ' · ${o.deliverySlotLabel}' : ''}', style: T.tiny()),
                const Gap(6),
                Text(o.items.map((i) => '${i.name} ${i.unit} ${i.quantityText}').join(', '), style: T.small(AppColors.ink), maxLines: 2, overflow: TextOverflow.ellipsis),
                const Gap(8),
                Row(children: [
                  Text(money(o.total), style: T.sans(14, weight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  Pill(o.isPaid ? 'Paid' : (o.paymentMethod == 'cod' ? 'Collect cash' : 'Unpaid'), bg: o.isPaid ? AppColors.mint : AppColors.yellowSoft, fg: o.isPaid ? AppColors.teal : const Color(0xFF6B4A1E)),
                  const Spacer(),
                  Text(orderDate(o.createdAt), style: T.tiny()),
                ]),
                if (o.nextStatus != null) ...[
                  const Gap(10),
                  PrimaryButton(
                    _busy.contains(o.id) ? 'Updating…' : _nextLabel(o),
                    color: AppColors.teal,
                    height: 40,
                    icon: Icons.arrow_forward_rounded,
                    onTap: _busy.contains(o.id) ? null : () => _advance(o),
                  ),
                ],
              ]),
            ),
            const Gap(12),
          ],
        FinePrint('Refreshes every ${kStaffRefreshEvery.inSeconds} seconds. Orders from the website and the app appear here together.'),
      ],
    );
  }
}

// ───────────────────────── Order detail (staff) ─────────────────────────
class StaffOrderScreen extends StatefulWidget {
  final int? orderId;
  const StaffOrderScreen({super.key, this.orderId});

  @override
  State<StaffOrderScreen> createState() => _StaffOrderScreenState();
}

class _StaffOrderScreenState extends State<StaffOrderScreen> {
  ShopOrder? _o;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (widget.orderId == null) {
      setState(() => _error = 'No order selected.');
      return;
    }
    try {
      final o = await context.appRead.staffOrder(widget.orderId!);
      if (mounted) setState(() => _o = o);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _run(Future<ShopOrder> Function() action, String done) async {
    setState(() => _busy = true);
    try {
      final o = await action();
      if (!mounted) return;
      setState(() => _o = o);
      toast(context, done);
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_needsLogin(context)) return const Scaffold(backgroundColor: AppColors.cream);
    final o = _o;
    if (o == null) {
      return UScaffold(title: 'Order', subtitle: _subtitle, trailing: null, children: [LoadState(loading: _error == null, error: _error, onRetry: _load)]);
    }
    final app = context.appRead;
    return UScaffold(
      title: '#${o.number}',
      subtitle: _subtitle,
      trailing: IconTileButton(Icons.refresh_rounded, onTap: _load),
      bottom: o.nextStatus == null
          ? null
          : PrimaryButton(
              _busy ? 'Updating…' : 'Move to: ${switch (o.nextStatus) { 'preparing' => 'Preparing', 'dispatched' => o.isPickup ? 'Ready for pickup' : 'Out for delivery', _ => 'Delivered' }}',
              color: AppColors.teal,
              onTap: _busy ? null : () => _run(() => app.staffAdvance(o.id), 'Updated — the customer has been emailed'),
            ),
      children: [
        Row(children: [
          Pill(o.statusLabel, bg: AppColors.mint, fg: AppColors.teal),
          const SizedBox(width: 8),
          Pill(o.isPaid ? 'Paid' : (o.paymentStatus == 'refunded' ? 'Refunded' : 'Payment pending'), bg: o.isPaid ? AppColors.mint : AppColors.yellowSoft, fg: o.isPaid ? AppColors.teal : const Color(0xFF6B4A1E)),
        ]),
        const Gap(12),
        Text(o.customerName, style: T.display(30)),
        Text('+91 ${o.phone}${o.email != null ? ' · ${o.email}' : ''}', style: T.small()),
        const Gap(12),
        UCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Column(children: [
            KV('Placed', orderDate(o.createdAt)),
            KV('How', o.deliveryLabel.split(' · ').first),
            if (o.deliverySlotLabel != null) KV('Preferred time', o.deliverySlotLabel!),
            if (!o.isPickup) KV('Address', '${o.address} · ${o.pincode}'),
            KV('Payment', o.paymentLabel),
          ]),
        ),
        if (o.note != null && o.note!.isNotEmpty) ...[const Gap(10), Note('Customer note: ${o.note}')],
        const Gap(12),
        UCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Column(children: [
            for (final i in o.items) KV('${i.name} · ${i.unit} ${i.quantityText}', money(i.lineTotal)),
            KV('Delivery', o.deliveryFee == 0 ? 'Free' : money(o.deliveryFee)),
            const DashedDivider(),
            KV('Total', money(o.total), strong: true),
          ]),
        ),
        const Gap(14),
        if (!o.isPaid && !o.isCancelled)
          OutlineBtn('Mark as paid', color: AppColors.teal, icon: Icons.check_rounded, onTap: _busy ? null : () => _run(() => app.staffUpdateOrder(o.id, paymentStatus: 'paid'), 'Marked as paid')),
        if (!o.isCancelled) ...[
          const Gap(10),
          OutlineBtn('Cancel order', icon: Icons.close_rounded, onTap: _busy
              ? null
              : () async {
                  final ok = await confirmDialog(context, title: 'Cancel #${o.number}?', message: 'Stock is put back and the customer is emailed. A cancelled order can’t be reopened.', confirm: 'Cancel order');
                  if (ok) _run(() => app.staffUpdateOrder(o.id, status: 'cancelled'), 'Order cancelled');
                }),
        ],
      ],
    );
  }
}

// ───────────────────────── Stock (staff) ─────────────────────────
class StaffProductsScreen extends StatefulWidget {
  const StaffProductsScreen({super.key});

  @override
  State<StaffProductsScreen> createState() => _StaffProductsScreenState();
}

class _StaffProductsScreenState extends State<StaffProductsScreen> {
  List<StaffProduct>? _items;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final list = await context.appRead.staffProducts();
      if (mounted) setState(() => _items = list);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _edit(String title, int? current, Future<void> Function(int? value) save) async {
    final c = TextEditingController(text: current?.toString() ?? '');
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 0, 24, MediaQuery.viewInsetsOf(ctx).bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: T.display(26)),
          const Gap(6),
          Text('Units in stock. Leave empty if you don’t track stock for this item.', style: T.body()),
          UField(label: 'In stock', controller: c, keyboard: TextInputType.number, autofocus: true, formatters: [FilteringTextInputFormatter.digitsOnly]),
          const Gap(18),
          PrimaryButton('Save', color: AppColors.teal, icon: null, onTap: () => Navigator.pop(ctx, c.text.trim())),
        ]),
      ),
    );
    if (result == null || !mounted) return;
    try {
      await save(result.isEmpty ? null : int.parse(result));
      if (mounted) toast(context, 'Stock saved — the website shows it straight away');
      _load();
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_needsLogin(context)) return const Scaffold(backgroundColor: AppColors.cream);
    final app = context.appRead;
    return UScaffold(
      title: 'Stock',
      subtitle: _subtitle,
      nav: NavKind.staff,
      navIndex: 1,
      trailing: IconTileButton(Icons.refresh_rounded, onTap: _load),
      children: [
        const Eyebrow('Shop stock'),
        const Gap(10),
        const Headline('Nothing\n*sold twice.*'),
        const Gap(14),
        if (_error != null)
          LoadState(error: _error, onRetry: _load)
        else if (_items == null)
          const LoadState(loading: true)
        else
          for (final s in _items!)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderSoft))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(s.product.name, style: T.title(s.isActive ? AppColors.ink : AppColors.muted))),
                  if (!s.isActive) const Pill('Hidden', bg: AppColors.peach, fg: AppColors.ink),
                ]),
                if (!s.product.hasOptions)
                  _StockRow(
                    label: s.product.unit,
                    stock: s.stockQty,
                    onMinus: s.stockQty == null || s.stockQty == 0 ? null : () async {
                      await app.staffStock(s.product.id, delta: -1);
                      _load();
                    },
                    onPlus: s.stockQty == null ? null : () async {
                      await app.staffStock(s.product.id, delta: 1);
                      _load();
                    },
                    onEdit: () => _edit(s.product.name, s.stockQty, (v) => app.staffStock(s.product.id, setTo: v, stopTracking: v == null)),
                  )
                else
                  for (final o in s.product.options)
                    _StockRow(
                      label: o.label,
                      stock: o.stockQty,
                      onMinus: o.stockQty == null || o.stockQty == 0 ? null : () async {
                        await app.staffOptionStock(o.id, delta: -1);
                        _load();
                      },
                      onPlus: o.stockQty == null ? null : () async {
                        await app.staffOptionStock(o.id, delta: 1);
                        _load();
                      },
                      onEdit: () => _edit('${s.product.name} · ${o.label}', o.stockQty, (v) => app.staffOptionStock(o.id, setTo: v, stopTracking: v == null)),
                    ),
              ]),
            ),
        const FinePrint('“Not tracked” means the item never sells out online. Tap a number to set it.'),
      ],
    );
  }
}

class _StockRow extends StatelessWidget {
  final String label;
  final int? stock;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;
  final VoidCallback onEdit;
  const _StockRow({required this.label, required this.stock, required this.onMinus, required this.onPlus, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final low = stock != null && stock! <= 5;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(children: [
        Expanded(child: Text(label, style: T.small(AppColors.ink))),
        IconButton(onPressed: onMinus, icon: const Icon(Icons.remove_circle_outline_rounded, size: 22), color: AppColors.berry),
        GestureDetector(
          onTap: onEdit,
          child: Container(
            constraints: const BoxConstraints(minWidth: 86),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: low ? AppColors.pink : AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
            child: Text(stock == null ? 'Not tracked' : '$stock', textAlign: TextAlign.center, style: T.sans(12.5, weight: FontWeight.w700, color: low ? AppColors.berry : AppColors.ink)),
          ),
        ),
        IconButton(onPressed: onPlus, icon: const Icon(Icons.add_circle_outline_rounded, size: 22), color: AppColors.teal),
      ]),
    );
  }
}
