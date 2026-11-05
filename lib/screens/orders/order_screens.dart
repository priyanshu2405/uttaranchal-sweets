import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
import '../../widgets/product_widgets.dart';
import '../../widgets/u_scaffold.dart';

/// Opens the order's PDF invoice (a short-lived link from the server) in the phone's PDF viewer / browser,
/// where it can be saved or shared.
Future<void> openInvoice(BuildContext context, String number) async {
  toast(context, 'Preparing your invoice…');
  try {
    final url = await context.appRead.invoiceLink(number);
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) toast(context, 'Couldn’t open the invoice. Please try again.');
  } on ApiException catch (e) {
    if (context.mounted) toast(context, e.message);
  }
}

String orderDate(DateTime? d) {
  if (d == null) return '';
  final now = DateTime.now();
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final time = '$h:${d.minute.toString().padLeft(2, '0')} ${d.hour < 12 ? 'AM' : 'PM'}';
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  if (day == today) return 'Today, $time';
  if (day == today.subtract(const Duration(days: 1))) return 'Yesterday, $time';
  return '${dayMonth(d)}${d.year != now.year ? ' ${d.year}' : ''}, $time';
}

Color _pillBg(ShopOrder o) => o.isCancelled ? AppColors.pink : (o.isDelivered ? AppColors.mint : AppColors.yellowSoft);
Color _pillFg(ShopOrder o) => o.isCancelled ? AppColors.berry : (o.isDelivered ? AppColors.teal : const Color(0xFF6B4A1E));

// ───────────────────────── 17 · Order history ─────────────────────────
class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  int _tab = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      await context.appRead.loadMyOrders();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final all = app.myOrders;
    final shown = switch (_tab) {
      1 => all.where((o) => o.isActive).toList(),
      2 => all.where((o) => o.isDelivered).toList(),
      _ => all,
    };
    return UScaffold(
      title: 'Your sweet memories',
      nav: NavKind.customer,
      navIndex: 4,
      trailing: IconTileButton(Icons.refresh_rounded, onTap: _load),
      children: [
        UnderlineTabs(tabs: const ['All orders', 'In progress', 'Delivered'], index: _tab, onChanged: (i) => setState(() => _tab = i)),
        const Gap(16),
        if (!app.signedIn) ...[
          ColorBlock(
            color: AppColors.yellow,
            onTap: () => go(context, R.signIn),
            child: Row(children: [
              Expanded(
                child: Text('Sign in to see every order on your account — including ones placed on the website.', style: T.sans(12, height: 1.5)),
              ),
              const SizedBox(width: 10),
              const IconTileButton(Icons.north_east_rounded),
            ]),
          ),
          const Gap(12),
        ],
        if (_error != null)
          LoadState(error: _error, onRetry: _load)
        else if (app.loadingOrders && all.isEmpty)
          const LoadState(loading: true)
        else if (shown.isEmpty)
          LoadState(empty: all.isEmpty ? 'No orders yet. Your first box of joy is a tap away.' : 'Nothing in this list.')
        else
          for (final o in shown) ...[_OrderCard(o), const Gap(12)],
        const Gap(4),
        ActionRow(icon: Icons.search_rounded, title: 'Track an order', subtitle: 'Use your order number and mobile number', onTap: () => go(context, R.tracking)),
        ActionRow(icon: Icons.storefront_outlined, title: 'Shop again', subtitle: 'Fresh sweets every day', onTap: () => goTab(context, R.collection), divider: false),
      ],
    );
  }
}

class _OrderCard extends StatelessWidget {
  final ShopOrder o;
  const _OrderCard(this.o);

  @override
  Widget build(BuildContext context) {
    return UCard(
      onTap: () => go(context, R.tracking, args: o.number),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('#${o.number}', style: T.sans(13, weight: FontWeight.w700))),
          Pill(o.needsPayment ? 'Payment pending' : o.statusLabel, bg: _pillBg(o), fg: _pillFg(o)),
        ]),
        const Gap(12),
        Row(children: [
          ClipRRect(borderRadius: BorderRadius.circular(12), child: NetImage(o.firstImage, width: 62, height: 62)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(o.items.isEmpty ? 'Your order' : o.items.map((i) => i.name).join(' · '), style: T.display(20), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(orderDate(o.createdAt), style: T.tiny()),
              const Gap(4),
              Text('${money(o.total)} · ${o.itemsCount} item${o.itemsCount == 1 ? '' : 's'}', style: T.sans(12.5, weight: FontWeight.w700)),
            ]),
          ),
        ]),
        const Divider(color: AppColors.borderSoft, height: 24),
        Row(children: [
          if (o.isDelivered || o.isCancelled)
            SmallButton('Reorder', filled: false, onTap: () async {
              final n = await context.appRead.reorder(o);
              if (!context.mounted) return;
              toast(context, n == 0 ? 'These items aren’t available right now' : 'Added to your bag', action: n == 0 ? null : 'View bag', onAction: () => go(context, R.bag));
            })
          else
            Text(o.deliveryLabel.split(' · ').first, style: T.sans(11.5, color: AppColors.muted)),
          const Spacer(),
          Text(o.isActive ? 'Track →' : 'Details →', style: T.sans(12, color: AppColors.teal, weight: FontWeight.w700)),
        ]),
      ]),
    );
  }
}

// ───────────────────────── 18 · Order tracking ─────────────────────────
/// With an order number: live status (refreshes every 30 s). Without: the website's "track an order" form.
class TrackingScreen extends StatefulWidget {
  final String? number;
  const TrackingScreen({super.key, this.number});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  ShopOrder? _order;
  String? _error;
  bool _busy = false;
  Timer? _timer;
  final _numberField = TextEditingController();
  final _contactField = TextEditingController();

  @override
  void initState() {
    super.initState();
    final n = widget.number;
    if (n != null) {
      final app = context.appRead;
      for (final o in [if (app.lastOrder != null) app.lastOrder!, ...app.myOrders]) {
        if (o.number == n) _order = o;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
      _timer = Timer.periodic(const Duration(seconds: 30), (_) => _refresh(quiet: true));
    } else {
      _contactField.text = context.appRead.phone;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _numberField.dispose();
    _contactField.dispose();
    super.dispose();
  }

  Future<void> _refresh({bool quiet = false}) async {
    final n = widget.number ?? _order?.number;
    if (n == null) return;
    try {
      final o = await context.appRead.fetchOrder(n);
      if (mounted) {
        setState(() {
          _order = o;
          _error = null;
        });
      }
      if (!o.isActive && !o.needsPayment) _timer?.cancel();
    } on ApiException catch (e) {
      if (mounted && !quiet) setState(() => _error = e.message);
    }
  }

  Future<void> _lookup() async {
    if (_numberField.text.trim().isEmpty || _contactField.text.trim().isEmpty) {
      toast(context, 'Enter your order number and the mobile number or email used on it');
      return;
    }
    setState(() => _busy = true);
    try {
      final o = await context.appRead.trackOrder(_numberField.text.trim(), _contactField.text.trim());
      if (mounted) setState(() => _order = o);
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel(ShopOrder o) async {
    final ok = await confirmDialog(context, title: 'Cancel this order?', message: 'Order #${o.number} will be cancelled. This can’t be undone.', confirm: 'Cancel order');
    if (!ok || !mounted) return;
    try {
      final updated = await context.appRead.cancelOrder(o.number);
      if (!mounted) return;
      setState(() => _order = updated);
      toast(context, 'Your order has been cancelled');
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message);
    }
  }

  Future<void> _pay(ShopOrder o) async {
    setState(() => _busy = true);
    final r = await payOnline(context.appRead, o);
    if (!mounted) return;
    setState(() => _busy = false);
    toast(context, r.message);
    _refresh(quiet: true);
  }

  @override
  Widget build(BuildContext context) {
    final o = _order;
    if (o == null && widget.number == null) return _form(context);
    if (o == null) {
      return UScaffold(title: 'On its way to you', nav: NavKind.customer, navIndex: 0, children: [
        LoadState(loading: _error == null, error: _error, onRetry: _refresh),
      ]);
    }
    final shopPhone = context.app.config.shopPhone;
    final eta = o.isPickup ? 'Ready for pickup' : 'Estimated arrival';
    return UScaffold(
      title: o.isCancelled ? 'Order cancelled' : 'On its way to you',
      nav: NavKind.customer,
      navIndex: 0,
      trailing: IconTileButton(Icons.refresh_rounded, onTap: () => _refresh()),
      bottom: o.needsPayment
          ? PrimaryButton(_busy ? 'Opening payment…' : 'Pay ${money(o.total)} now', onTap: _busy ? null : () => _pay(o))
          : OutlineBtn('Need help with this order?', icon: null, onTap: () => go(context, R.help, args: o.number)),
      children: [
        Row(children: [
          Pill(o.statusLabel, bg: _pillBg(o), fg: _pillFg(o)),
          const SizedBox(width: 8),
          if (o.isPaid) const Pill('Paid', icon: Icons.check_rounded),
          const Spacer(),
          Text('#${o.number}', style: T.sans(11.5, color: AppColors.muted, weight: FontWeight.w600)),
        ]),
        const Gap(12),
        const Gap(8),
        if (!o.isCancelled && !o.isDelivered) ...[
          Eyebrow(eta),
          const Gap(6),
          Row(children: [
            Expanded(child: Text(o.deliverySlotLabel ?? (o.isPickup ? 'The shop will confirm the time' : 'The shop will confirm the time'), style: T.display(24))),
            Icon(o.isPickup ? Icons.storefront_outlined : Icons.delivery_dining_outlined, color: AppColors.berry, size: 26),
          ]),
          const Gap(12),
        ],
        for (var i = 0; i < o.timeline.length; i++)
          _TimelineStep(
            index: i,
            title: o.timeline[i].label,
            subtitle: i == 0 ? orderDate(o.createdAt) : (o.timeline[i].state == 'current' ? 'In progress' : ''),
            state: switch (o.timeline[i].state) { 'done' => 0, 'current' => 1, _ => 2 },
            last: i == o.timeline.length - 1,
          ),
        if (o.needsPayment) ...[const Gap(4), Note('Payment pending. Unpaid online orders are cancelled automatically after ${context.app.config.unpaidCancelHours} hours.')],
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
        const Gap(10),
        if (shopPhone != null && shopPhone.isNotEmpty) Note('Questions? Call the shop on $shopPhone.', tone: NoteTone.mint),
        if (o.canCancel) ...[
          const Gap(8),
          Center(child: TextButton(onPressed: () => _cancel(o), child: Text('Cancel this order', style: T.sans(12.5, color: AppColors.berry, weight: FontWeight.w600)))),
        ],
        ActionRow(icon: Icons.receipt_long_outlined, title: 'View receipt', subtitle: 'Items, GST and payment', onTap: () => go(context, R.receipt, args: o.number)),
        ActionRow(icon: Icons.download_rounded, title: 'Download invoice', subtitle: 'PDF to save or share', onTap: () => openInvoice(context, o.number), divider: false),
      ],
    );
  }

  Widget _form(BuildContext context) {
    return UScaffold(
      title: 'Track an order',
      nav: NavKind.customer,
      navIndex: 0,
      bottom: PrimaryButton(_busy ? 'Looking…' : 'Find my order', onTap: _busy ? null : _lookup),
      children: [
        const Eyebrow('Order tracking'),
        const Gap(10),
        const Headline('Where’s my\n*sweet parcel?*'),
        const Gap(10),
        const BodyText('Works for orders placed on the website or in the app.'),
        UField(label: 'Order number', controller: _numberField, hint: 'UDS-261102-ABCD'),
        UField(label: 'Mobile number or email used on the order', controller: _contactField),
      ],
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final int index;
  final String title;
  final String subtitle;
  final int state; // 0 done, 1 current, 2 pending
  final bool last;
  const _TimelineStep({required this.index, required this.title, required this.subtitle, required this.state, required this.last});

  @override
  Widget build(BuildContext context) {
    final bg = state == 2 ? AppColors.peach : AppColors.teal;
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Column(children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
            child: state == 0
                ? const Icon(Icons.check_rounded, size: 15, color: AppColors.white)
                : Text('${index + 1}', style: T.sans(11, color: state == 2 ? AppColors.muted : AppColors.white, weight: FontWeight.w700)),
          ),
          if (!last) Expanded(child: Container(width: 1.5, color: state == 0 ? AppColors.teal : AppColors.border)),
        ]),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16, top: 2),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: T.sans(13, weight: FontWeight.w600, color: state == 2 ? AppColors.muted : AppColors.ink)),
              if (subtitle.isNotEmpty) ...[const Gap(2), Text(subtitle, style: T.tiny())],
            ]),
          ),
        ),
      ]),
    );
  }
}

// ───────────────────────── 19 · Order receipt ─────────────────────────
class ReceiptScreen extends StatefulWidget {
  final String? number;
  const ReceiptScreen({super.key, this.number});

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  ShopOrder? _order;
  String? _error;

  @override
  void initState() {
    super.initState();
    final app = context.appRead;
    final n = widget.number ?? app.lastOrder?.number;
    for (final o in [if (app.lastOrder != null) app.lastOrder!, ...app.myOrders]) {
      if (o.number == n) _order = o;
    }
    if (n != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          final o = await context.appRead.fetchOrder(n);
          if (mounted) setState(() => _order = o);
        } on ApiException catch (e) {
          if (mounted && _order == null) setState(() => _error = e.message);
        }
      });
    } else {
      _error = 'No order selected.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = _order;
    if (o == null) {
      return UScaffold(title: 'Your order receipt', nav: NavKind.customer, navIndex: 4, children: [LoadState(loading: _error == null, error: _error)]);
    }
    final gstin = context.app.config.shop['gstin'] as String?;
    return UScaffold(
      title: 'Your order receipt',
      nav: NavKind.customer,
      navIndex: 4,
      children: [
        Eyebrow('Order #${o.number}'),
        const Gap(10),
        const Headline('A little record\nof *happiness.*'),
        const Gap(6),
        Text(orderDate(o.createdAt), style: T.small()),
        const Gap(16),
        UCard(
          child: Column(children: [
            for (final i in o.items) KV('${i.name} · ${i.unit} ${i.quantityText}', money(i.lineTotal)),
            KV('Delivery', o.deliveryFee == 0 ? 'Free' : money(o.deliveryFee)),
            KV('GST included', money(o.taxAmount), color: AppColors.muted),
            const DashedDivider(),
            KV(o.isPaid ? 'Paid · ${o.paymentLabel}' : 'Total · ${o.paymentLabel}', money(o.total), strong: true),
          ]),
        ),
        const Gap(12),
        UCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(o.isPickup ? 'PICKUP' : 'DELIVERY   ADDRESS', style: T.sans(11, weight: FontWeight.w700, spacing: 0.8)),
            const Gap(8),
            Text(o.customerName, style: T.sans(12)),
            Text('+91 ${o.phone}', style: T.sans(12)),
            Text(o.isPickup ? 'Store pickup · Patel Nagar, Kashipur' : '${o.address} · ${o.pincode}', style: T.sans(12)),
            if (o.note != null && o.note!.isNotEmpty) ...[const Gap(8), Text('Note: ${o.note}', style: T.small())],
          ]),
        ),
        const Gap(12),
        PrimaryButton('Download invoice (PDF)', icon: Icons.download_rounded, onTap: () => openInvoice(context, o.number)),
        const Gap(12),
        Note(gstin != null && gstin.isNotEmpty ? 'GSTIN $gstin · Prices include GST.' : 'Prices include GST.'),
      ],
    );
  }
}
