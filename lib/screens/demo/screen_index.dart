import 'package:flutter/material.dart';

import '../../app/nav.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../widgets/common.dart';
import '../../widgets/u_scaffold.dart';

/// Presenter tool: jump to any of the 42 designed screens during a demo.
/// Open it by long-pressing the logo on the Welcome screen, or from You → Screen index.
class ScreenIndexScreen extends StatelessWidget {
  const ScreenIndexScreen({super.key});

  static const customer = <(String, String, String)>[
    ('01', 'Welcome', R.welcome),
    ('02', 'Mobile sign in', R.signIn),
    ('03', 'Verify mobile', R.verify),
    ('04', 'Delivery location', R.location),
    ('05', 'Customer home', R.home),
    ('06', 'Shop collection', R.collection),
    ('07', 'Product details', R.product),
    ('08', 'Search & discover', R.search),
    ('09', 'Festive gifting', R.gifting),
    ('10', 'Build a gift box', R.giftBox),
    ('11', 'Bulk / wholesale enquiry', R.bulkEnquiry),
    ('12', 'Shopping bag', R.bag),
    ('13', 'Redeem loyalty points', R.redeem),
    ('14', 'Checkout address', R.checkoutAddress),
    ('15', 'Payment method', R.payment),
    ('16', 'Order confirmation', R.orderConfirmation),
    ('17', 'Order history', R.orderHistory),
    ('18', 'Live order tracking', R.tracking),
    ('19', 'Order receipt', R.receipt),
    ('20', 'Milk distribution hub', R.milkHub),
    ('21', 'Milk product', R.milkProduct),
    ('22', 'Configure milk plan', R.milkConfigure),
    ('23', 'Review & activate plan', R.milkReview),
    ('24', 'Active milk subscription', R.milkActive),
    ('25', 'Milk delivery calendar', R.milkCalendar),
    ('26', 'Pause / skip / holiday', R.milkPause),
    ('27', 'Milk delivery proof', R.milkProof),
    ('28', 'Milk balance top-up', R.milkTopUp),
    ('29', 'Loyalty points wallet', R.rewards),
    ('30', 'Points activity & rules', R.pointsActivity),
    ('31', 'Account & referrals', R.account),
    ('32', 'Our story & visit us', R.story),
    ('33', 'Notifications', R.notifications),
    ('34', 'Help & language', R.help),
  ];

  static const staff = <(String, String, String)>[
    ('35', 'Delivery staff sign in', R.staffSignIn),
    ('36', 'Distribution dashboard', R.staffDashboard),
    ('37', 'Route & delivery stops', R.staffRoute),
    ('38', 'Delivery stop details', R.staffStop),
    ('39', 'Confirm milk delivery', R.staffConfirm),
    ('40', 'Delivery exception', R.staffException),
    ('41', 'Bottle returns & stock', R.staffStock),
    ('42', 'End-of-route summary', R.staffSummary),
  ];

  @override
  Widget build(BuildContext context) {
    return UScaffold(
      title: 'Screen index',
      subtitle: 'Prototype · 42 screens',
      trailing: null,
      children: [
        const Note('Presenter tool. Tap any screen to open it. Use the back arrow to return here.', tone: NoteTone.mint),
        const Gap(18),
        const Eyebrow('Customer app · 01–34'),
        const Gap(6),
        for (final s in customer) _row(context, s),
        const Gap(22),
        const Eyebrow('Milk delivery staff app · 35–42'),
        const Gap(6),
        for (final s in staff) _row(context, s),
      ],
    );
  }

  Widget _row(BuildContext context, (String, String, String) s) {
    return InkWell(
      onTap: () => go(context, s.$3),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderSoft))),
        child: Row(children: [
          Container(
            width: 34,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.peach, borderRadius: BorderRadius.circular(7)),
            child: Text(s.$1, style: T.sans(11, color: AppColors.berry, weight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(s.$2, style: T.sans(13.5))),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted, size: 20),
        ]),
      ),
    );
  }
}
