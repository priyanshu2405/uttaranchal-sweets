import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

// ───────────────────────── 12 · Shopping bag ─────────────────────────
class BagScreen extends StatefulWidget {
  const BagScreen({super.key});

  @override
  State<BagScreen> createState() => _BagScreenState();
}

class _BagScreenState extends State<BagScreen> {
  late final _note = TextEditingController(text: context.appRead.cartNote);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.appRead.refreshQuote());
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    if (app.cart.isEmpty) {
      return UScaffold(
        title: 'Your bag of joy',
        nav: NavKind.customer,
        navIndex: 1,
        trailing: null,
        children: [
          const Gap(60),
          const Center(child: Icon(Icons.shopping_bag_outlined, size: 56, color: AppColors.border)),
          const Gap(16),
          const Center(child: Headline('Your bag is\n*waiting.*', align: TextAlign.center)),
          const Gap(10),
          const BodyText('Add a few favourites and we’ll keep them fresh for you.', align: TextAlign.center),
          const Gap(24),
          PrimaryButton('Explore mithai', onTap: () => goTab(context, R.collection)),
        ],
      );
    }
    final q = app.quote;
    return UScaffold(
      title: 'Your bag of joy',
      nav: NavKind.customer,
      navIndex: 1,
      trailing: null,
      bottom: Row(children: [
        Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Items total', style: T.sans(11, color: AppColors.muted)),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(money(app.itemsTotal), key: ValueKey(app.itemsTotal), style: T.sans(20, weight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(width: 16),
        Expanded(
          child: PrimaryButton(
            app.quoting ? 'Checking…' : 'Continue',
            onTap: app.quoting
                ? null
                : () {
                    context.appRead.setNote(_note.text);
                    go(context, R.checkoutAddress);
                  },
          ),
        ),
      ]),
      children: [
        Row(children: [
          Pill('${app.cartCount} delicious choice${app.cartCount == 1 ? '' : 's'}', bg: AppColors.pink, fg: AppColors.berry),
          const Spacer(),
          if (app.quoting) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.berry)),
        ]),
        if (q != null && q.problems.isNotEmpty) ...[const Gap(10), Note(q.problems.join('\n'))],
        if (app.quoteError != null) ...[const Gap(10), Note('${app.quoteError} Prices shown may not be current.')],
        const Gap(6),
        for (var i = 0; i < app.cart.length; i++) _BagLine(line: app.cart[i], index: i),
        const Gap(14),
        if (q != null && q.freeThreshold > 0)
          ColorBlock(
            color: AppColors.teal,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(q.freeReached ? 'Free local delivery unlocked.' : 'Add ${money(q.freeRemaining)} for free local delivery.', style: T.display(22, color: AppColors.white)),
              const Gap(10),
              UProgressBar(q.freeThreshold <= 0 ? 1.0 : (q.subtotal / q.freeThreshold).clamp(0.0, 1.0).toDouble()),
            ]),
          ),
        const Gap(6),
        ActionRow(
          icon: Icons.location_on_outlined,
          title: app.pickup ? 'Store pickup · Patel Nagar' : (app.hasAddress ? 'Deliver to ${app.area}' : 'Add a delivery address'),
          subtitle: app.pickup ? 'Collect from the shop · Change' : (app.hasAddress ? '${app.street}, ${app.pincode} · Change' : 'Needed for local delivery or courier'),
          onTap: () => go(context, R.checkoutAddress),
        ),
        UField(label: 'A note for the shop (optional)', controller: _note, hint: 'e.g. less sugar, ring the bell', maxLines: 2, onChanged: context.appRead.setNote),
        const Gap(10),
        KV('Items total', money(app.itemsTotal)),
        if (q != null) KV('GST included', money(q.tax)),
        const Divider(color: AppColors.border, height: 18),
        const KV('Delivery', 'Calculated at the next step'),
        const FinePrint('Prices include GST. Fresh items are available for pickup and local delivery only.'),
        if (q != null && q.suggestions.isNotEmpty) ...[
          const Gap(18),
          const SectionTitle('Little extras', size: 22),
          const Gap(12),
          ProductGrid(q.suggestions.take(2).toList()),
        ],
      ],
    );
  }
}

class _BagLine extends StatelessWidget {
  final CartLine line;
  final int index;
  const _BagLine({required this.line, required this.index});

  @override
  Widget build(BuildContext context) {
    final max = line.available ?? context.app.config.maxLineQuantity;
    return Dismissible(
      key: ValueKey(line.key),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.pink,
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.berry),
      ),
      onDismissed: (_) => _remove(context),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderSoft))),
        child: Row(children: [
          ClipRRect(borderRadius: BorderRadius.circular(12), child: NetImage(line.imageUrl, width: 68, height: 68)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(line.name, style: T.display(22), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text('${line.label} · ${money(line.unitPrice)}', style: T.tiny(), maxLines: 1, overflow: TextOverflow.ellipsis),
              const Gap(4),
              Text(money(line.total), style: T.sans(13, weight: FontWeight.w700)),
            ]),
          ),
          QtyStepper(
            value: line.qty,
            max: max < line.qty ? line.qty : max,
            onChanged: (v) {
              if (v == 0) {
                _remove(context);
              } else {
                context.appRead.setQty(line, v);
              }
            },
          ),
        ]),
      ),
    );
  }

  void _remove(BuildContext context) {
    final app = context.appRead;
    final qty = line.qty;
    app.setQty(line, 0);
    toast(context, '${line.name} removed', action: 'Undo', onAction: () {
      line.qty = qty;
      app.restoreLine(line, index);
    });
  }
}

// ───────────────────────── 13 · Loyalty points (coming soon) ─────────────────────────
class RedeemScreen extends StatelessWidget {
  const RedeemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return UScaffold(
      title: 'A sweeter checkout',
      nav: NavKind.customer,
      navIndex: 1,
      bottom: PrimaryButton('Continue to checkout', onTap: () => goReplace(context, R.checkoutAddress)),
      children: const [
        Eyebrow('Rewards'),
        Gap(10),
        Headline('Points are\n*coming soon.*'),
        Gap(14),
        Note('Loyalty points will be added to the app and the website together, so they are the same wherever you shop.'),
      ],
    );
  }
}

// ───────────────────────── 14 · Checkout details ─────────────────────────
class CheckoutAddressScreen extends StatefulWidget {
  const CheckoutAddressScreen({super.key});

  @override
  State<CheckoutAddressScreen> createState() => _CheckoutAddressScreenState();
}

class _CheckoutAddressScreenState extends State<CheckoutAddressScreen> {
  late final _name = TextEditingController(text: context.appRead.checkoutName);
  late final _phone = TextEditingController(text: context.appRead.checkoutPhone);
  late final _email = TextEditingController(text: context.appRead.checkoutEmail);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.appRead.refreshQuote());
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  void _continue() {
    final app = context.appRead;
    final phone = _phone.text.replaceAll(RegExp(r'\D'), '');
    String? problem;
    if (_name.text.trim().isEmpty) {
      problem = 'Please enter your name';
    } else if (!RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
      problem = 'Enter a valid 10-digit Indian mobile number';
    } else if (!_email.text.contains('@')) {
      problem = 'Please enter your email — we send your order updates there';
    } else if (app.pincode.length != 6) {
      problem = 'Please add your pincode';
    } else if (!app.pickup && app.street.trim().isEmpty) {
      problem = 'Please add your delivery address';
    } else {
      final m = app.quote?.method(app.deliveryMethod);
      if (m != null && !m.available) problem = m.reason ?? 'This delivery option isn’t available for your bag';
    }
    if (problem != null) {
      toast(context, problem);
      return;
    }
    app.setCheckoutContact(name: _name.text.trim(), phone: phone, email: _email.text.trim());
    go(context, R.payment);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final methods = app.quote?.deliveryMethods ?? app.config.deliveryMethods;
    return UScaffold(
      title: 'The finishing touches',
      nav: NavKind.customer,
      navIndex: 1,
      bottom: PrimaryButton('Choose payment', onTap: _continue),
      children: [
        const Eyebrow('Your details'),
        const Gap(10),
        const Headline('A sweet parcel.\nThe *right place.*'),
        UField(label: 'Name', controller: _name),
        UField(label: 'Mobile number', controller: _phone, prefixText: '+91', keyboard: TextInputType.phone, formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')), LengthLimitingTextInputFormatter(11)]),
        UField(label: 'Email (for order updates)', controller: _email, keyboard: TextInputType.emailAddress),
        const FieldLabel('How would you like it?'),
        for (final m in methods) _MethodTile(m),
        const Gap(8),
        UCard(
          onTap: () => go(context, R.location, args: 'edit'),
          child: Row(children: [
            Icon(app.pickup ? Icons.storefront_outlined : Icons.home_outlined, size: 18, color: AppColors.ink),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(app.pickup ? 'Your pincode' : 'Deliver to', style: T.title()),
                const Gap(4),
                Text(
                  app.pickup
                      ? (app.pincode.isEmpty ? 'Add your pincode' : app.pincode)
                      : (app.hasAddress ? '${app.fullAddress} · ${app.pincode}' : 'Add your address'),
                  style: T.sans(12, height: 1.5),
                ),
              ]),
            ),
            Text('Edit', style: T.sans(12, color: AppColors.teal, weight: FontWeight.w700)),
          ]),
        ),
        if (app.pickup) ...[
          const Gap(8),
          Note('Pickup from ${app.config.shopAddress}. The shop confirms your collection time once the order is received.', tone: NoteTone.mint),
        ],
        if (app.deliveryMethod != 'courier' && app.config.deliverySlots.isNotEmpty)
          UPicker(
            label: app.pickup ? 'Preferred pickup time' : 'Preferred delivery time',
            value: app.slotLabel ?? 'Any time',
            icon: Icons.schedule_rounded,
            onTap: () async {
              final labels = {'Any time': null, for (final s in app.config.deliverySlots) s.label: s.key};
              final v = await pickOption(context, title: 'Preferred time', options: labels.keys.toList(), selected: app.slotLabel ?? 'Any time');
              if (v != null && context.mounted) context.appRead.setSlot(labels[v]);
            },
          ),
        const Gap(16),
        ColorBlock(
          color: AppColors.yellow,
          child: Column(children: [
            KV('Items', money(app.itemsTotal)),
            KV('Delivery', app.deliveryFee == 0 ? 'Free' : money(app.deliveryFee)),
            const Gap(6),
            KV('Total', money(app.bagTotal), strong: true),
          ]),
        ),
      ],
    );
  }
}

class _MethodTile extends StatelessWidget {
  final DeliveryMethodOption m;
  const _MethodTile(this.m);

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final selected = app.deliveryMethod == m.key;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? AppColors.pink : AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: selected ? AppColors.berry : AppColors.border)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: m.available ? () => context.appRead.setDeliveryMethod(m.key) : () => toast(context, m.reason ?? 'Not available for this bag'),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, size: 20, color: m.available ? AppColors.berry : AppColors.border),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(m.shortLabel, style: T.sans(13, weight: FontWeight.w600, color: m.available ? AppColors.ink : AppColors.muted)),
                  Text(m.available ? m.detail : (m.reason ?? ''), style: T.tiny()),
                ]),
              ),
              Text(m.fee == 0 ? 'Free' : money(m.fee), style: T.sans(12.5, weight: FontWeight.w700, color: m.available ? AppColors.teal : AppColors.muted)),
            ]),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── 15 · Payment & place order ─────────────────────────
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _busy = false;

  Future<void> _place() async {
    final app = context.appRead;
    setState(() => _busy = true);
    ShopOrder order;
    try {
      order = await app.placeOrder(name: app.checkoutName, phone: app.checkoutPhone, email: app.checkoutEmail);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      toast(context, e.message);
      // Prices or stock changed — send them back to the bag to review.
      if (e.errors.containsKey('cart')) {
        await app.refreshQuote();
        if (mounted) Navigator.of(context).popUntil((r) => r.settings.name == R.bag || r.isFirst);
      }
      return;
    }
    if (!mounted) return;
    if (order.needsPayment) {
      final result = await payOnline(app, order);
      if (!mounted) return;
      toast(context, result.message);
    }
    if (!mounted) return;
    setState(() => _busy = false);
    Navigator.of(context).pushNamedAndRemoveUntil(R.orderConfirmation, (r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final methods = app.config.usablePayments.where((p) => !(p.key == 'cod' && app.deliveryMethod == 'courier')).toList();
    if (methods.isNotEmpty && !methods.any((m) => m.key == app.paymentMethod)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.appRead.setPayment(methods.first.key));
    }
    return UScaffold(
      title: 'Pay with ease',
      nav: NavKind.customer,
      navIndex: 1,
      bottom: PrimaryButton(
        _busy ? 'Placing your order…' : 'Place order · ${money(app.payable)}',
        onTap: _busy || methods.isEmpty || app.cart.isEmpty ? null : _place,
      ),
      children: [
        const Eyebrow('Safe & simple'),
        const Gap(10),
        const Headline('One last step\nto *happiness.*'),
        const Gap(16),
        ColorBlock(
          color: AppColors.teal,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Amount payable', style: T.sans(12, color: AppColors.white)),
            const Gap(10),
            Text(money(app.payable), style: T.display(46, color: AppColors.white)),
            Text('${app.cartCount} item${app.cartCount == 1 ? '' : 's'} · ${app.deliveryShortLabel}${app.deliveryFee > 0 ? ' · delivery ${money(app.deliveryFee)}' : ''}', style: T.sans(11.5, color: AppColors.white)),
          ]),
        ),
        const FieldLabel('Payment method'),
        for (final m in methods)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: app.paymentMethod == m.key ? AppColors.pink : AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: app.paymentMethod == m.key ? AppColors.berry : AppColors.border)),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => context.appRead.setPayment(m.key),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    Icon(app.paymentMethod == m.key ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, size: 20, color: AppColors.berry),
                    const SizedBox(width: 10),
                    Icon(switch (m.key) { 'upi' => Icons.qr_code_2_rounded, 'card' => Icons.credit_card_rounded, _ => Icons.payments_outlined }, size: 18, color: AppColors.ink),
                    const SizedBox(width: 8),
                    Expanded(child: Text(m.label, style: T.sans(13, weight: FontWeight.w600))),
                  ]),
                ),
              ),
            ),
          ),
        if (methods.isEmpty) const Note('No payment method is available for this delivery option. Please go back and choose store pickup or local delivery.'),
        if (!app.config.razorpayEnabled) const Note('Online payment is being set up by the shop. Cash on delivery / pay at pickup is available.'),
        const Gap(8),
        UCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Column(children: [
            KV('Name', app.checkoutName),
            KV('Mobile', '+91 ${app.checkoutPhone}'),
            KV(app.pickup ? 'Pickup' : 'Deliver to', app.pickup ? 'Patel Nagar, Kashipur' : '${app.fullAddress} · ${app.pincode}'),
            if (app.slotLabel != null && app.deliveryMethod != 'courier') KV('Preferred time', app.slotLabel!),
          ]),
        ),
        const FinePrint('UPI and card payments are completed securely with Razorpay right after you place the order.'),
      ],
    );
  }
}

// ───────────────────────── 16 · Order confirmation ─────────────────────────
class OrderConfirmationScreen extends StatefulWidget {
  const OrderConfirmationScreen({super.key});

  @override
  State<OrderConfirmationScreen> createState() => _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> {
  bool _paying = false;

  Future<void> _pay(ShopOrder o) async {
    setState(() => _paying = true);
    final r = await payOnline(context.appRead, o);
    if (!mounted) return;
    setState(() => _paying = false);
    toast(context, r.message);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final o = app.lastOrder;
    if (o == null) {
      return UScaffold(title: 'Your orders', nav: NavKind.customer, navIndex: 0, children: [
        const LoadState(empty: 'No recent order on this phone.'),
        PrimaryButton('See all orders', onTap: () => goFromRoot(context, R.orderHistory)),
      ]);
    }
    final unpaid = o.needsPayment;
    return UScaffold(
      title: 'Made your day sweeter',
      nav: NavKind.customer,
      navIndex: 0,
      onBack: () => goTab(context, R.home),
      bottom: unpaid
          ? PrimaryButton(_paying ? 'Opening payment…' : 'Pay ${money(o.total)} now', onTap: _paying ? null : () => _pay(o))
          : PrimaryButton('Track my order', onTap: () => go(context, R.tracking, args: o.number)),
      children: [
        const Gap(4),
        Center(child: CheckBadge(icon: unpaid ? Icons.hourglass_top_rounded : Icons.shopping_bag_rounded)),
        const Gap(10),
        Eyebrow('Thank you, ${o.customerName.split(' ').first}', align: TextAlign.center),
        const Gap(10),
        Headline(unpaid ? 'Almost there —\n*just the payment.*' : 'A little joy\nis on its *way.*', align: TextAlign.center),
        const Gap(10),
        Text('Order #${o.number}', textAlign: TextAlign.center, style: T.sans(12, color: AppColors.muted)),
        Text('We’ve emailed your confirmation to ${o.email ?? 'you'}.', textAlign: TextAlign.center, style: T.small()),
        const Gap(16),
        ColorBlock(
          color: AppColors.yellow,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(children: [
            KV('Status', o.statusLabel),
            KV(o.isPickup ? 'Pickup' : 'Delivery', o.deliveryLabel.split(' · ').first),
            if (o.deliverySlotLabel != null) KV('Preferred time', o.deliverySlotLabel!),
            KV(o.isPaid ? 'Paid' : 'Amount', money(o.total)),
            KV('Payment', '${o.paymentLabel}${o.isPaid ? ' · paid' : ''}'),
          ]),
        ),
        if (unpaid) ...[
          const Gap(10),
          Note('Your order is saved. Please complete the payment — unpaid online orders are cancelled automatically after ${app.config.unpaidCancelHours} hours.'),
        ],
        const Gap(6),
        ActionRow(icon: Icons.delivery_dining_outlined, title: 'Track your order', subtitle: 'Follow every little step', onTap: () => go(context, R.tracking, args: o.number)),
        ActionRow(icon: Icons.receipt_long_outlined, title: 'View order receipt', subtitle: 'Products, GST and payment summary', onTap: () => go(context, R.receipt, args: o.number), divider: false),
      ],
    );
  }
}
