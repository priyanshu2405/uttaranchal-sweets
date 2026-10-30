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
import '../../widgets/u_scaffold.dart';

// ───────────────────────── 29 · Loyalty points wallet ─────────────────────────
class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    const milestone = 1500;
    final toNext = (milestone - app.points).clamp(0, milestone);
    return UScaffold(
      title: 'Sweet rewards',
      nav: NavKind.customer,
      navIndex: 3,
      children: [
        const Eyebrow('The Uttaranchal circle'),
        const Gap(10),
        const Headline('Good taste.\n*Great rewards.*'),
        const Gap(16),
        ColorBlock(
          color: AppColors.purple,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text('YOUR  AVAILABLE  POINTS', style: T.sans(9.5, color: AppColors.white, weight: FontWeight.w700, spacing: 1.2))),
              const Icon(Icons.stars_rounded, color: AppColors.yellow, size: 24),
            ]),
            const Gap(14),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: app.points.toDouble()),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, v, _) => Text(grouped(v.round()), style: T.display(46, color: AppColors.white)),
              ),
              const SizedBox(width: 6),
              Padding(padding: const EdgeInsets.only(bottom: 8), child: Text('points', style: T.sans(12, color: AppColors.white))),
            ]),
            Text('${rupees(AppState.pointsValue(app.points))} to spend on eligible products', style: T.sans(11.5, color: AppColors.white)),
            const Gap(14),
            UProgressBar(app.points / milestone),
            const Gap(10),
            Text(toNext == 0 ? 'Milestone reached — a sweet surprise awaits!' : '$toNext more points to your next reward milestone', style: T.sans(11, color: AppColors.white)),
          ]),
        ),
        const Gap(12),
        Row(children: [
          SmallButton('Shop with points', icon: Icons.north_east_rounded, onTap: () => goTab(context, R.collection)),
          const Spacer(),
          SmallButton('Points activity', filled: false, onTap: () => go(context, R.pointsActivity)),
        ]),
        const Gap(20),
        const SectionTitle('Earn a little more'),
        const Gap(4),
        ActionRow(icon: Icons.shopping_basket_outlined, title: 'Shop your favourites', subtitle: 'Sample earn rate: 1 point per ₹10 spent', onTap: () => goTab(context, R.collection)),
        ActionRow(icon: Icons.person_add_alt_outlined, title: 'Invite a friend', subtitle: 'Earn after their first eligible delivered order', onTap: () => _shareReferral(context)),
        ActionRow(icon: Icons.local_offer_outlined, title: 'Redeem at checkout', subtitle: 'Choose points, see savings, pay the rest', onTap: () => go(context, R.bag)),
        const Gap(12),
        const Note('100 points = ₹10 · No cash withdrawal. Final eligibility and expiry rules will be set before launch.'),
      ],
    );
  }
}

void _shareReferral(BuildContext context) {
  Clipboard.setData(const ClipboardData(text: 'Join me on Uttaranchal Dairy & Sweets! Use code AARAV200 for sweet rewards.'));
  toast(context, 'Invite message copied — share it on WhatsApp');
}

// ───────────────────────── 30 · Points activity & rules ─────────────────────────
class PointsActivityScreen extends StatefulWidget {
  const PointsActivityScreen({super.key});

  @override
  State<PointsActivityScreen> createState() => _PointsActivityScreenState();
}

class _PointsActivityScreenState extends State<PointsActivityScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return UScaffold(
      title: 'Every sweet reward',
      nav: NavKind.customer,
      navIndex: 3,
      bottom: PrimaryButton('Find your next favourite', onTap: () => goTab(context, R.collection)),
      children: [
        UnderlineTabs(tabs: const ['Activity', 'How it works'], index: _tab, onChanged: (i) => setState(() => _tab = i)),
        const Gap(16),
        ColorBlock(
          color: AppColors.purple,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Available points', style: T.sans(12, color: AppColors.white)),
            const Gap(10),
            Text(grouped(app.points), style: T.display(42, color: AppColors.white)),
            Text('Pending: 65 points · Order #UDS1048', style: T.sans(11.5, color: AppColors.white)),
          ]),
        ),
        const Gap(12),
        if (_tab == 0) ...[
          for (final a in app.pointsActivity)
            KV('${a.$1} · ${a.$2}', a.$3 > 0 ? '+ ${a.$3} pts' : '− ${-a.$3} pts', color: a.$3 > 0 ? AppColors.teal : AppColors.ink),
          const Gap(12),
          UCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('A few sweet details.', style: T.display(25)),
              const Gap(10),
              for (final t in const [
                'Earn after successful delivery.',
                'Use points toward eligible product purchases.',
                'Review the discount before paying.',
                'Refunds reverse applicable earned points.',
              ])
                Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('•  $t', style: T.sans(12))),
            ]),
          ),
        ] else ...[
          for (final s in const [
            (Icons.shopping_bag_outlined, 'Shop', 'Earn 1 point for every ₹10 on sweets, snacks and gift boxes.'),
            (Icons.local_shipping_outlined, 'Receive', 'Points are credited once your order is delivered.'),
            (Icons.local_offer_outlined, 'Redeem', 'Use points at checkout — 100 points = ₹10 off eligible products.'),
            (Icons.person_add_alt_outlined, 'Refer', 'Get 200 points when a friend completes their first order.'),
          ])
            ActionRow(icon: s.$1, title: s.$2, subtitle: s.$3, iconBg: AppColors.pink),
        ],
        const FinePrint('Illustrative programme. Point validity, earning exclusions, referral conditions and redemption limits are configurable.'),
      ],
    );
  }
}

// ───────────────────────── 31 · Account & referrals ─────────────────────────
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return UScaffold(
      title: 'Your little corner',
      nav: NavKind.customer,
      navIndex: 4,
      trailing: IconTileButton(Icons.notifications_none_rounded, dot: true, onTap: () => go(context, R.notifications)),
      children: [
        Row(children: [
          Avatar(app.initials, size: 50),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Namaste, ${app.firstName}.', style: T.display(27)),
              Text('+91 ${app.phone}', style: T.sans(12, color: AppColors.muted)),
            ]),
          ),
          GestureDetector(
            onTap: () => _editName(context),
            child: const Pill('Edit', bg: AppColors.peach, fg: AppColors.ink),
          ),
        ]),
        const Gap(14),
        ColorBlock(
          color: AppColors.purple,
          onTap: () => goTab(context, R.rewards),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('YOUR  SWEET  REWARDS', style: T.sans(9.5, color: AppColors.white, weight: FontWeight.w700, spacing: 1.2)),
                const Gap(8),
                Text('${grouped(app.points)} points', style: T.display(26, color: AppColors.white)),
              ]),
            ),
            const IconTileButton(Icons.north_east_rounded),
          ]),
        ),
        const Gap(4),
        ActionRow(icon: Icons.receipt_long_outlined, title: 'My orders', subtitle: 'Track, reorder and view receipts', onTap: () => go(context, R.orderHistory)),
        ActionRow(icon: Icons.local_drink_outlined, title: 'My milk plan', subtitle: 'Your everyday delivery routine', onTap: () => go(context, R.milkActive)),
        ActionRow(icon: Icons.location_on_outlined, title: 'Saved addresses', subtitle: 'Home, work and gifting addresses', onTap: () => go(context, R.location, args: 'edit')),
        ActionRow(icon: Icons.landscape_outlined, title: 'Our story & visit us', subtitle: '27 years of sweet beginnings', onTap: () => go(context, R.story)),
        ActionRow(icon: Icons.help_outline_rounded, title: 'Help & preferences', subtitle: 'Support, notifications & language', onTap: () => go(context, R.help)),
        const Gap(12),
        ColorBlock(
          color: AppColors.yellow,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Share a little sweetness.', style: T.display(25)),
            const Gap(8),
            Text.rich(TextSpan(style: T.sans(12), children: [
              const TextSpan(text: 'Your referral code: '),
              TextSpan(text: 'AARAV200', style: T.sans(12, weight: FontWeight.w700)),
            ])),
            const Gap(12),
            Material(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  Clipboard.setData(const ClipboardData(text: 'AARAV200'));
                  toast(context, 'Referral code copied');
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  child: Text('Copy referral code ↗', style: T.sans(11.5, weight: FontWeight.w500)),
                ),
              ),
            ),
          ]),
        ),
        const Gap(18),
        Text('PROTOTYPE', style: T.eyebrow(AppColors.muted)),
        ActionRow(
          icon: Icons.delivery_dining_outlined,
          title: 'Switch to delivery staff app',
          subtitle: 'Milk distribution partner experience',
          iconBg: AppColors.mint,
          iconColor: AppColors.teal,
          onTap: () => go(context, R.staffSignIn),
        ),
        ActionRow(
          icon: Icons.grid_view_rounded,
          title: 'Screen index',
          subtitle: 'Jump to any of the 42 designed screens',
          iconBg: AppColors.mint,
          iconColor: AppColors.teal,
          onTap: () => go(context, R.screenIndex),
        ),
        ActionRow(
          icon: Icons.logout_rounded,
          title: 'Sign out',
          subtitle: 'Return to the welcome screen',
          divider: false,
          onTap: () async {
            final ok = await confirmDialog(context, title: 'Sign out?', message: 'You can sign back in any time with your mobile number.', confirm: 'Sign out');
            if (ok && context.mounted) Navigator.of(context).pushNamedAndRemoveUntil(R.welcome, (_) => false);
          },
        ),
      ],
    );
  }

  Future<void> _editName(BuildContext context) async {
    final c = TextEditingController(text: context.appRead.userName);
    final name = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 0, 24, MediaQuery.viewInsetsOf(ctx).bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Edit profile', style: T.display(28)),
          UField(label: 'Full name', controller: c, autofocus: true),
          const Gap(18),
          PrimaryButton('Save', icon: null, onTap: () => Navigator.pop(ctx, c.text.trim())),
        ]),
      ),
    );
    if (name != null && name.isNotEmpty && context.mounted) {
      context.appRead.setName(name);
      toast(context, 'Profile updated');
    }
  }
}

// ───────────────────────── 32 · Our story & visit us ─────────────────────────
class StoryScreen extends StatelessWidget {
  const StoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return UScaffold(
      title: 'Rooted in Devbhoomi',
      nav: NavKind.customer,
      navIndex: 4,
      bottom: OutlineBtn('Ask us about your visit', onTap: () => go(context, R.help, args: 'visit')),
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(16), child: AspectRatio(aspectRatio: 2.4, child: Image.asset(Img.devbhoomi, fit: BoxFit.cover))),
        const Gap(14),
        const Eyebrow('27 years · One sweet journey'),
        const Gap(10),
        const Headline('From a dream.\nTo your *traditions.*'),
        const Gap(12),
        const BodyText(
            'Meet Mubarak Ali, the heart behind Uttaranchal Dairy & Sweets. A journey of 27 years, built around familiar flavours, everyday care and the joy of bringing people together.'),
        const Gap(16),
        Text('“A little taste of home.\nA lifetime of sweet memories.”', style: T.display(23, color: AppColors.teal, italic: true, weight: FontWeight.w500, height: 1.25)),
        const Gap(16),
        ColorBlock(
          color: AppColors.teal,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Come say namaste.', style: T.display(25, color: AppColors.white)),
            const Gap(10),
            Text('Patel Nagar, Kashipur\nUdham Singh Nagar, Uttarakhand', style: T.sans(11.5, color: AppColors.white, height: 1.6)),
            const Gap(8),
            Text('Temples, hills and the wild heart of Corbett.\nOur home. Our inspiration.', style: T.sans(11.5, color: AppColors.white, height: 1.6)),
            const Gap(12),
            Row(children: [
              SmallButton('Directions', color: AppColors.berry, icon: Icons.near_me_outlined, onTap: () => toast(context, 'Opening maps… (demo)')),
              const SizedBox(width: 8),
              SmallButton('Call shop', color: AppColors.tealDark, icon: Icons.call_outlined, onTap: () => toast(context, 'Calling the shop… (demo)')),
            ]),
          ]),
        ),
        const FinePrint('Owner story wording and quotation are design copy for review.'),
      ],
    );
  }
}

// ───────────────────────── 33 · Notifications ─────────────────────────
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return UScaffold(
      title: 'A little heads-up',
      nav: NavKind.customer,
      navIndex: 0,
      children: [
        const Eyebrow('Just for you'),
        const Gap(10),
        const Headline('Fresh updates.\n*Sweet reminders.*'),
        const Gap(16),
        ColorBlock(
          color: AppColors.teal,
          onTap: () => go(context, R.milkProof),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('MILK  DELIVERY  ·  6:32 AM', style: T.sans(9.5, color: AppColors.white, weight: FontWeight.w700, spacing: 1.2)),
            const Gap(8),
            Text('Your morning is here.', style: T.display(25, color: AppColors.white)),
            const Gap(6),
            Text('${app.milkLitres} L milk delivered. ${rupees(app.perDelivery)} charged to your milk balance.', style: T.sans(11.5, color: AppColors.white)),
            const Gap(8),
            Text('View delivery →', style: T.sans(11.5, color: AppColors.white, weight: FontWeight.w600)),
          ]),
        ),
        const Gap(10),
        UCard(
          onTap: () => go(context, R.tracking),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('ORDER  #UDS1048  ·  10:45 AM', style: T.sans(9.5, weight: FontWeight.w700, spacing: 1.2)),
            const Gap(8),
            Text('A sweet parcel is on its way.', style: T.display(25)),
            const Gap(6),
            Text('Your order is out for delivery.', style: T.sans(11.5)),
            const Gap(8),
            Text('Track order →', style: T.sans(11.5, color: AppColors.teal, weight: FontWeight.w600)),
          ]),
        ),
        const Gap(10),
        ColorBlock(
          color: AppColors.yellow,
          onTap: () => goTab(context, R.rewards),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('REWARDS', style: T.sans(9.5, weight: FontWeight.w700, spacing: 1.2)),
            const Gap(8),
            Text('You earned 89 points.', style: T.display(25)),
            const Gap(6),
            Text('Thank you for making us part of your celebration.', style: T.sans(11.5)),
            const Gap(8),
            Text('View rewards →', style: T.sans(11.5, weight: FontWeight.w600)),
          ]),
        ),
        const Gap(6),
        ActionRow(icon: Icons.tune_rounded, title: 'Notification preferences', subtitle: 'Choose the updates you receive', onTap: () => go(context, R.help), divider: false),
      ],
    );
  }
}

// ───────────────────────── 34 · Help & language preferences ─────────────────────────
class HelpScreen extends StatefulWidget {
  final String? reference;
  const HelpScreen({super.key, this.reference});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  late String _topic = switch (widget.reference) {
    'milk' => 'Milk delivery / missing quantity',
    'visit' => 'Shop visit & opening hours',
    null => 'Milk delivery / missing quantity',
    _ => 'Sweet order / delivery',
  };

  static const _topics = [
    'Milk delivery / missing quantity',
    'Sweet order / delivery',
    'Payments & refunds',
    'Loyalty points',
    'Shop visit & opening hours',
    'Something else',
  ];

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final ref = widget.reference != null && widget.reference!.startsWith('UDS') ? widget.reference! : 'UDS1048';
    return UScaffold(
      title: 'Here for you',
      nav: NavKind.customer,
      navIndex: 4,
      trailing: null,
      children: [
        const Eyebrow('A little help'),
        const Gap(10),
        const Headline('Let’s make\nthings *right.*'),
        UPicker(
          label: 'What can we help with?',
          value: _topic,
          onTap: () async {
            final v = await pickOption(context, title: 'What can we help with?', options: _topics, selected: _topic);
            if (v != null) setState(() => _topic = v);
          },
        ),
        UField(label: 'Order / delivery reference', initial: ref),
        const UField(label: 'Your message', hint: 'Tell us what happened…', maxLines: 3),
        const Gap(16),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlineBtn(
            'Prepare support request',
            expanded: false,
            icon: Icons.north_east_rounded,
            onTap: () => showSuccess(context,
                title: 'We’re on it',
                message: 'Request #SR-2207 is with our team. Expect a call or WhatsApp message within 2 hours (9 AM–8 PM).',
                cta: 'Thank you'),
          ),
        ),
        const Gap(16),
        const Divider(color: AppColors.border),
        UPicker(
          label: 'App language',
          value: app.language,
          icon: Icons.translate_rounded,
          onTap: () async {
            final v = await pickOption(context, title: 'App language', options: const ['English', 'हिन्दी'], selected: app.language);
            if (v != null && context.mounted) {
              context.appRead.setLanguage(v);
              if (v != 'English') toast(context, 'Hindi screens will be available at launch — preview shows English');
            }
          },
        ),
        const Gap(12),
        ToggleCard(title: 'Order & milk notifications', value: app.notifications, onChanged: context.appRead.toggleNotifications, card: false),
        const FinePrint('English screen designs shown. Hindi content and local support contact details will be configured before launch.'),
      ],
    );
  }
}
