import 'package:flutter/material.dart';

import '../../app/nav.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';
import '../../widgets/fields.dart';
import '../../widgets/u_scaffold.dart';

// ───────────────────────── 12 · Shopping bag ─────────────────────────
class BagScreen extends StatelessWidget {
  const BagScreen({super.key});

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
    return UScaffold(
      title: 'Your bag of joy',
      nav: NavKind.customer,
      navIndex: 1,
      trailing: null,
      bottom: Row(children: [
        Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Total', style: T.sans(11, color: AppColors.muted)),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(rupees(app.bagTotal), key: ValueKey(app.bagTotal), style: T.sans(20, weight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(width: 16),
        Expanded(child: PrimaryButton('Continue', onTap: () => go(context, R.redeem))),
      ]),
      children: [
        Align(alignment: Alignment.centerLeft, child: Pill('${app.cartCount} delicious choice${app.cartCount == 1 ? '' : 's'}', bg: AppColors.pink, fg: AppColors.berry)),
        const Gap(6),
        for (var i = 0; i < app.cart.length; i++) _BagLine(line: app.cart[i], index: i),
        const Gap(14),
        ColorBlock(
          color: AppColors.teal,
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Make your points count.', style: T.display(23, color: AppColors.white)),
                const Gap(4),
                Text('${grouped(app.points)} points available · Worth ${rupees(AppState.pointsValue(app.points))}', style: T.sans(11, color: AppColors.white)),
              ]),
            ),
            Material(
              color: AppColors.yellow,
              borderRadius: BorderRadius.circular(9),
              child: InkWell(
                borderRadius: BorderRadius.circular(9),
                onTap: () => go(context, R.redeem),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Text('Use →', style: T.sans(12, color: AppColors.berry, weight: FontWeight.w700)),
                ),
              ),
            ),
          ]),
        ),
        const Gap(6),
        ActionRow(
          icon: Icons.location_on_outlined,
          title: app.pickup ? 'Store pickup · Patel Nagar' : 'Deliver to ${app.area}',
          subtitle: app.pickup ? 'Ready in 30 minutes · Change' : '${app.street}, ${app.city.split(',').first} · Change',
          onTap: () => go(context, R.checkoutAddress),
        ),
        const Gap(8),
        KV('Items total', rupees(app.itemsTotal)),
        KV('Delivery', app.deliveryFee == 0 ? 'Free' : rupees(app.deliveryFee)),
        const Divider(color: AppColors.border, height: 18),
        KV('Bag total', rupees(app.bagTotal), strong: true),
        const FinePrint('Prices include applicable taxes. Earn points after successful delivery.'),
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
          ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset(line.image, width: 68, height: 68, fit: BoxFit.cover)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(line.name, style: T.display(22), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(line.subtitle, style: T.tiny(), maxLines: 1, overflow: TextOverflow.ellipsis),
              const Gap(4),
              Text(rupees(line.total), style: T.sans(13, weight: FontWeight.w700)),
            ]),
          ),
          QtyStepper(
            value: line.qty,
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

// ───────────────────────── 13 · Redeem loyalty points ─────────────────────────
class RedeemScreen extends StatelessWidget {
  const RedeemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final maxPts = ((app.points < app.itemsTotal * 10 ? app.points : app.itemsTotal * 10) ~/ 50) * 50;
    final options = <String, int>{'500 points': 500, '1,000 points': 1000, 'Use all': maxPts};
    final selectedLabel = options.entries.firstWhere((e) => e.value == app.pointsToRedeem, orElse: () => const MapEntry('', 0)).key;
    final remaining = app.points - app.redeemablePoints;
    return UScaffold(
      title: 'A sweeter checkout',
      nav: NavKind.customer,
      navIndex: 1,
      bottom: PrimaryButton(app.usePoints ? 'Apply points & continue' : 'Continue without points', onTap: () => go(context, R.checkoutAddress)),
      children: [
        const Eyebrow('Your rewards, your choice'),
        const Gap(10),
        const Headline('Turn your points\ninto *sweetness.*'),
        const Gap(16),
        ColorBlock(
          color: AppColors.purple,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('AVAILABLE  TO  REDEEM', style: T.sans(9.5, color: AppColors.white, weight: FontWeight.w700, spacing: 1.3)),
            const Gap(14),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(grouped(app.points), style: T.display(46, color: AppColors.white)),
              const SizedBox(width: 6),
              Padding(padding: const EdgeInsets.only(bottom: 8), child: Text('points', style: T.sans(12, color: AppColors.white))),
            ]),
            Text('Worth ${rupees(AppState.pointsValue(app.points))} toward eligible products', style: T.sans(11.5, color: AppColors.white)),
          ]),
        ),
        const Gap(12),
        UCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text('Use ${grouped(app.pointsToRedeem)} points', style: T.title())),
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(value: app.usePoints && app.pointsToRedeem > 0, onChanged: (v) => context.appRead.setUsePoints(v ?? false)),
              ),
            ]),
            const Gap(4),
            Text('Save ${rupees(AppState.pointsValue(app.pointsToRedeem))} on this order.', style: T.small()),
            const Gap(12),
            ChipGroup(options: options.keys.toList(), selected: app.usePoints ? selectedLabel : '', onSelected: (v) => context.appRead.setRedeem(options[v]!)),
          ]),
        ),
        const Gap(14),
        KV('Bag total', rupees(app.bagTotal)),
        KV('Rewards discount', '− ${rupees(app.discount)}', color: AppColors.teal),
        const DashedDivider(),
        KV('Amount to pay', rupees(app.payable), strong: true),
        const Gap(10),
        Note('$remaining points remain after redemption. Earn ${(app.itemsTotal / 10).floor() - 7} new points after this order is delivered.', tone: NoteTone.mint),
        const FinePrint('Illustrative rule: 100 points = ₹10. Points apply to eligible product value, not delivery. Final earning and redemption rules are configurable.'),
      ],
    );
  }
}

// ───────────────────────── 14 · Checkout address ─────────────────────────
class CheckoutAddressScreen extends StatelessWidget {
  const CheckoutAddressScreen({super.key});

  static const _slots = ['Today · 11:30 AM–12:00 PM', 'Today · 4:00–4:30 PM', 'Today · 7:00–7:30 PM', 'Tomorrow · 10:00–10:30 AM'];

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return UScaffold(
      title: 'The finishing touches',
      nav: NavKind.customer,
      navIndex: 1,
      bottom: PrimaryButton('Choose payment', onTap: () => go(context, R.payment)),
      children: [
        const Eyebrow('Delivery details'),
        const Gap(10),
        const Headline('A sweet parcel.\nThe *right place.*'),
        const Gap(14),
        ChipGroup(
          options: const ['Home delivery', 'Store pickup'],
          selected: app.pickup ? 'Store pickup' : 'Home delivery',
          onSelected: (v) => context.appRead.setPickup(v == 'Store pickup'),
        ),
        const Gap(12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: app.pickup
              ? UCard(
                  key: const ValueKey('pickup'),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const Icon(Icons.storefront_outlined, size: 16, color: AppColors.ink),
                      const SizedBox(width: 6),
                      Expanded(child: Text('Uttaranchal Dairy & Sweets', style: T.title())),
                      const Pill('Open now'),
                    ]),
                    const Gap(10),
                    Text('Patel Nagar, Kashipur\nUdham Singh Nagar · Open 7 AM–10 PM\nReady for pickup in 30 minutes', style: T.sans(12, height: 1.6)),
                  ]),
                )
              : UCard(
                  key: const ValueKey('home'),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const Icon(Icons.home_outlined, size: 16, color: AppColors.ink),
                      const SizedBox(width: 6),
                      Expanded(child: Text('Home · ${app.userName}', style: T.title())),
                      const Pill('Selected'),
                    ]),
                    const Gap(10),
                    Text('${app.street}, ${app.city.split(',').first}\n${app.city.split(',').last.trim()} · ${app.pincode}\n+91 ${app.phone}', style: T.sans(12, height: 1.6)),
                    const Gap(8),
                    GestureDetector(
                      onTap: () => go(context, R.location, args: 'edit'),
                      child: Text('Edit address →', style: T.sans(12, color: AppColors.teal, weight: FontWeight.w700)),
                    ),
                  ]),
                ),
        ),
        UPicker(
          label: app.pickup ? 'Pickup slot' : 'Delivery slot',
          value: app.deliverySlot,
          icon: Icons.schedule_rounded,
          onTap: () async {
            final v = await pickOption(context, title: app.pickup ? 'Pickup slot' : 'Delivery slot', options: _slots, selected: app.deliverySlot);
            if (v != null && context.mounted) context.appRead.setSlot(v);
          },
        ),
        const UField(label: 'A note for our team', initial: 'Please ring the bell on arrival.'),
        const Gap(16),
        ColorBlock(
          color: AppColors.yellow,
          child: Column(children: [
            KV(app.pickup ? 'Items (pickup)' : 'Items + delivery', rupees(app.bagTotal)),
            KV('${grouped(app.redeemablePoints)} points redeemed', '− ${rupees(app.discount)}'),
            const Gap(6),
            KV('Payable', rupees(app.payable), strong: true),
          ]),
        ),
      ],
    );
  }
}

// ───────────────────────── 15 · Payment method ─────────────────────────
class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  static const _methods = ['UPI · Google Pay / PhonePe / Paytm', 'Credit / debit card', 'Net banking', 'Cash on delivery'];

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final isUpi = app.paymentMethod.startsWith('UPI');
    return UScaffold(
      title: 'Pay with ease',
      nav: NavKind.customer,
      navIndex: 1,
      bottom: PrimaryButton(
        'Preview order confirmation',
        onTap: () async {
          await showProcessing(context, isUpi ? 'Waiting for UPI approval…' : 'Placing your order…');
          if (!context.mounted) return;
          context.appRead.placeOrder();
          Navigator.of(context).pushNamedAndRemoveUntil(R.orderConfirmation, (r) => r.isFirst);
        },
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
            Text(rupees(app.payable), style: T.display(46, color: AppColors.white)),
            Text(app.discount > 0 ? 'Includes ${rupees(app.discount)} saved with loyalty points' : 'No points applied to this order', style: T.sans(11.5, color: AppColors.white)),
          ]),
        ),
        UPicker(
          label: 'Payment method',
          value: app.paymentMethod,
          onTap: () async {
            final v = await pickOption(context, title: 'Payment method', options: _methods, selected: app.paymentMethod);
            if (v != null && context.mounted) context.appRead.setPayment(v);
          },
        ),
        if (isUpi) UField(label: 'UPI ID', initial: app.upiId, keyboard: TextInputType.emailAddress),
        if (app.paymentMethod.startsWith('Credit')) const UField(label: 'Card number', initial: '4111 1111 1111 1111', keyboard: TextInputType.number),
        const Gap(14),
        UCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.star_border_rounded, size: 16, color: AppColors.ink),
              const SizedBox(width: 6),
              Expanded(child: Text('Loyalty points applied', style: T.sans(13, weight: FontWeight.w500))),
              Text('${grouped(app.redeemablePoints)} pts', style: T.sans(13, color: AppColors.teal, weight: FontWeight.w700)),
            ]),
            const Gap(6),
            Text('Your remaining balance: ${grouped(app.points - app.redeemablePoints)} points.', style: T.small()),
          ]),
        ),
        const Gap(14),
        const Note('Design preview: continuing shows a sample confirmation. No payment is collected.'),
        const FinePrint('Payment gateway and eligible payment methods will be configured for launch.'),
      ],
    );
  }
}

// ───────────────────────── 16 · Order confirmation ─────────────────────────
class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final o = app.demoOrder;
    return UScaffold(
      title: 'Made your day sweeter',
      nav: NavKind.customer,
      navIndex: 0,
      onBack: () => goTab(context, R.home),
      bottom: PrimaryButton('Track my order', onTap: () => go(context, R.tracking)),
      children: [
        const Gap(4),
        const Center(child: CheckBadge(icon: Icons.shopping_bag_rounded)),
        const Gap(10),
        Eyebrow('Thank you, ${app.firstName}', align: TextAlign.center),
        const Gap(10),
        const Headline('A little joy\nis on its *way.*', align: TextAlign.center),
        const Gap(10),
        Text('Order #${o.id}', textAlign: TextAlign.center, style: T.sans(12, color: AppColors.muted)),
        Text('Placed today · Sample confirmation', textAlign: TextAlign.center, style: T.small()),
        const Gap(16),
        ColorBlock(
          color: AppColors.yellow,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(children: [
            KV(o.pickup ? 'Ready for pickup' : 'Estimated arrival', o.slot.split(' · ').last),
            KV('Amount paid', rupees(o.paid)),
            KV('Points redeemed', grouped(o.pointsRedeemed)),
          ]),
        ),
        const Gap(10),
        ColorBlock(
          color: AppColors.teal,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('More sweetness ahead.', style: T.display(24, color: AppColors.white)),
            const Gap(6),
            Text('You’ll earn ${o.pointsToEarn} points when this order is delivered.', style: T.sans(11.5, color: AppColors.white)),
          ]),
        ),
        const Gap(6),
        ActionRow(icon: Icons.delivery_dining_outlined, title: 'Track your order', subtitle: 'Follow every little step', onTap: () => go(context, R.tracking)),
        ActionRow(icon: Icons.receipt_long_outlined, title: 'View order receipt', subtitle: 'Products, savings and payment summary', onTap: () => go(context, R.receipt)),
      ],
    );
  }
}
