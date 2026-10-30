import 'package:flutter/material.dart';

import '../../app/nav.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../data/catalog.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';
import '../../widgets/illustrations.dart';
import '../../widgets/product_widgets.dart';
import '../../widgets/u_scaffold.dart';

// ───────────────────────── 17 · Order history ─────────────────────────
class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final o = context.app.demoOrder;
    final showActive = _tab != 2;
    final showDelivered = _tab != 1;
    return UScaffold(
      title: 'Your sweet memories',
      nav: NavKind.customer,
      navIndex: 4,
      children: [
        UnderlineTabs(tabs: const ['All orders', 'In progress', 'Delivered'], index: _tab, onChanged: (i) => setState(() => _tab = i)),
        const Gap(16),
        if (showActive)
          UCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text('#${o.id}', style: T.sans(13, weight: FontWeight.w700))),
                const Pill('Out for delivery'),
              ]),
              const Gap(12),
              Row(children: [
                ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset(o.lines.first.image, width: 66, height: 66, fit: BoxFit.cover)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Your mithai favourites', style: T.display(22), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(o.lines.map((l) => l.name).join(' · '), style: T.tiny(), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const Gap(4),
                    Text('${rupees(o.paid)} · ${o.lines.length} item${o.lines.length == 1 ? '' : 's'}', style: T.sans(12.5, weight: FontWeight.w700)),
                  ]),
                ),
              ]),
              const Divider(color: AppColors.borderSoft, height: 24),
              Text('Today · Arriving ${o.slot.split(' · ').last}', style: T.sans(11.5, color: AppColors.muted)),
              const Gap(10),
              PrimaryButton('Track order', color: AppColors.teal, icon: Icons.north_east_rounded, height: 40, onTap: () => go(context, R.tracking)),
            ]),
          ),
        if (showActive && showDelivered) const Gap(12),
        if (showDelivered)
          UCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text('#UDS1021', style: T.sans(13, weight: FontWeight.w700))),
                const Pill('Delivered'),
              ]),
              const Gap(10),
              Text('A box of celebration.', style: T.display(26)),
              const Gap(6),
              Text('Festive Selection · ₹899\n24 October · 89 points earned', style: T.sans(11.5, color: AppColors.ink, height: 1.6)),
              const Gap(12),
              Row(children: [
                SmallButton('Reorder', filled: false, onTap: () => addToBag(context, Catalog.byId('kaju-katli'))),
                const Spacer(),
                GestureDetector(
                  onTap: () => go(context, R.receipt),
                  child: Text('View details →', style: T.sans(12, color: AppColors.teal, weight: FontWeight.w700)),
                ),
              ]),
            ]),
          ),
        const Gap(8),
        ActionRow(icon: Icons.local_drink_outlined, title: 'Looking for milk deliveries?', subtitle: 'See your daily delivery calendar', onTap: () => go(context, R.milkCalendar), divider: false),
      ],
    );
  }
}

// ───────────────────────── 18 · Live order tracking ─────────────────────────
class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final o = context.app.demoOrder;
    const steps = [
      ('Order confirmed', 'Today, 10:02 AM'),
      ('Preparing with care', 'Today, 10:20 AM'),
      ('Out for delivery', 'Arriving today · 11:30 AM–12:00 PM'),
      ('Delivered', 'A sweet moment is on its way'),
    ];
    const current = 2;
    return UScaffold(
      title: 'On its way to you',
      nav: NavKind.customer,
      navIndex: 0,
      bottom: OutlineBtn('Need help with this order?', icon: null, onTap: () => go(context, R.help, args: o.id)),
      children: [
        const Align(alignment: Alignment.centerLeft, child: Pill('Out for delivery')),
        const Gap(12),
        const RouteMap(height: 170, animated: true),
        const Gap(16),
        const Eyebrow('Estimated arrival'),
        const Gap(6),
        Row(children: [
          Expanded(child: Text(o.slot.split(' · ').last, style: T.display(27))),
          const Icon(Icons.delivery_dining_outlined, color: AppColors.berry, size: 26),
        ]),
        const Gap(12),
        for (var i = 0; i < steps.length; i++)
          _TimelineStep(index: i, title: steps[i].$1, subtitle: steps[i].$2, state: i < current ? 0 : (i == current ? 1 : 2), last: i == steps.length - 1),
        const Gap(12),
        UCard(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            const Avatar('R', size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Ravi · Delivery partner', style: T.title()),
                Text('Order #${o.id} · ${o.lines.length} items', style: T.small()),
              ]),
            ),
            IconTileButton(Icons.call_outlined, onTap: () => toast(context, 'Calling Ravi… (demo)')),
          ]),
        ),
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
              const Gap(2),
              Text(subtitle, style: T.tiny()),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ───────────────────────── 19 · Order receipt ─────────────────────────
class ReceiptScreen extends StatelessWidget {
  const ReceiptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final o = app.demoOrder;
    return UScaffold(
      title: 'Your order receipt',
      nav: NavKind.customer,
      navIndex: 4,
      children: [
        Eyebrow('Order #${o.id}'),
        const Gap(10),
        const Headline('A little record\nof *happiness.*'),
        const Gap(16),
        UCard(
          child: Column(children: [
            for (final l in o.lines) KV('${l.name} · ${l.subtitle.split(' · ').first}${l.qty > 1 ? ' × ${l.qty}' : ''}', rupees(l.total)),
            KV('Delivery', o.delivery == 0 ? 'Free' : rupees(o.delivery)),
            if (o.discount > 0) KV('Rewards · ${grouped(o.pointsRedeemed)} points', '− ${rupees(o.discount)}', color: AppColors.teal),
            const DashedDivider(),
            KV('Paid via ${o.shortPayment}', rupees(o.paid), strong: true),
          ]),
        ),
        const Gap(12),
        UCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('DELIVERY   ADDRESS', style: T.sans(11, weight: FontWeight.w700, spacing: 0.8)),
            const Gap(8),
            Text(app.userName, style: T.sans(12)),
            Text('${app.street}, ${app.city.split(',').first} · ${app.pincode}', style: T.sans(12)),
            const Divider(color: AppColors.borderSoft, height: 26),
            Text('REWARDS   SUMMARY', style: T.sans(11, weight: FontWeight.w700, spacing: 0.8)),
            const Gap(8),
            Text('Redeemed: ${grouped(o.pointsRedeemed)} points', style: T.sans(12)),
            Text('Earn after delivery: ${o.pointsToEarn} points', style: T.sans(12)),
          ]),
        ),
        const Gap(12),
        const Note('Sample receipt. Tax invoice details and the business’s verified tax information will be configured before launch.'),
        const Gap(14),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlineBtn('View sample receipt', expanded: false, icon: Icons.open_in_new_rounded, onTap: () => _showReceipt(context)),
        ),
      ],
    );
  }

  void _showReceipt(BuildContext context) {
    final o = context.appRead.demoOrder;
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('UTTARANCHAL', style: T.display(22, weight: FontWeight.w500).copyWith(letterSpacing: 1.4)),
            Text('DAIRY & SWEETS · KASHIPUR', style: T.tiny()),
            const DashedDivider(),
            for (final l in o.lines) KV('${l.name} × ${l.qty}', rupees(l.total), vPad: 4),
            KV('Delivery', rupees(o.delivery), vPad: 4),
            KV('Points discount', '− ${rupees(o.discount)}', vPad: 4),
            const DashedDivider(),
            KV('TOTAL PAID', rupees(o.paid), strong: true),
            const Gap(8),
            Text('Order #${o.id} · ${o.shortPayment}', style: T.tiny()),
            const Gap(16),
            PrimaryButton('Close', icon: null, height: 44, onTap: () => Navigator.pop(ctx)),
          ]),
        ),
      ),
    );
  }
}
