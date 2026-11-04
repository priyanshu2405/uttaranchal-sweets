import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/nav.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../data/api.dart';
import '../../data/catalog.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';
import '../../widgets/fields.dart';
import '../../widgets/product_widgets.dart';
import '../../widgets/u_scaffold.dart';

Future<void> openLink(BuildContext context, String url) async {
  final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) toast(context, 'Couldn’t open $url');
}

// ───────────────────────── 29 · Rewards (coming soon) ─────────────────────────
class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
              Expanded(child: Text('COMING  SOON', style: T.sans(9.5, color: AppColors.white, weight: FontWeight.w700, spacing: 1.2))),
              const Icon(Icons.stars_rounded, color: AppColors.yellow, size: 24),
            ]),
            const Gap(14),
            Text('Points on every order.', style: T.display(30, color: AppColors.white)),
            const Gap(8),
            Text('We’re building loyalty points for the app and the website together, so your points are the same wherever you shop.',
                style: T.sans(11.5, color: AppColors.white, height: 1.55)),
          ]),
        ),
        const Gap(12),
        SmallButton('Shop now', icon: Icons.north_east_rounded, onTap: () => goTab(context, R.collection)),
        const Gap(20),
        ActionRow(icon: Icons.favorite_border_rounded, title: 'Your favourites', subtitle: 'Saved sweets, shared with the website', onTap: () => go(context, R.favourites)),
        ActionRow(icon: Icons.receipt_long_outlined, title: 'Your orders', subtitle: 'Track and reorder', onTap: () => go(context, R.orderHistory), divider: false),
      ],
    );
  }
}

class PointsActivityScreen extends StatelessWidget {
  const PointsActivityScreen({super.key});

  @override
  Widget build(BuildContext context) => const RewardsScreen();
}

// ───────────────────────── 31 · Account ─────────────────────────
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return UScaffold(
      title: 'Your little corner',
      nav: NavKind.customer,
      navIndex: 4,
      trailing: IconTileButton(Icons.notifications_none_rounded, onTap: () => go(context, R.notifications)),
      children: [
        if (app.signedIn)
          Row(children: [
            Avatar(app.initials, size: 50),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Namaste, ${app.firstName}.', style: T.display(27), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('+91 ${app.phoneDisplay}${app.email.isNotEmpty ? ' · ${app.email}' : ''}', style: T.sans(12, color: AppColors.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
            ),
            GestureDetector(onTap: () => _editProfile(context), child: const Pill('Edit', bg: AppColors.peach, fg: AppColors.ink)),
          ])
        else
          ColorBlock(
            color: AppColors.yellow,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Sign in for the full experience.', style: T.display(24)),
              const Gap(6),
              Text('See every order (app & website), keep favourites in sync and check out faster.', style: T.sans(12, height: 1.5)),
              const Gap(12),
              Row(children: [
                SmallButton('Sign in', onTap: () => go(context, R.signIn)),
                const SizedBox(width: 8),
                SmallButton('Create account', filled: false, onTap: () => go(context, R.verify)),
              ]),
            ]),
          ),
        const Gap(8),
        ActionRow(icon: Icons.receipt_long_outlined, title: 'My orders', subtitle: 'Track, reorder and view receipts', onTap: () => go(context, R.orderHistory)),
        ActionRow(icon: Icons.favorite_border_rounded, title: 'Favourites', subtitle: '${app.favourites.length} saved', onTap: () => go(context, R.favourites)),
        ActionRow(icon: Icons.location_on_outlined, title: 'Delivery address', subtitle: app.hasAddress ? '${app.fullAddress} · ${app.pincode}' : 'Add your address', onTap: () => go(context, R.location, args: 'edit')),
        ActionRow(icon: Icons.local_drink_outlined, title: 'Milk subscription', subtitle: context.app.milkPlan == null ? 'Daily milk at your door' : '${context.app.milkPlan!.litres} L · ${context.app.milkPlan!.statusLabel}', onTap: () => goTab(context, R.milkHub)),
        ActionRow(icon: Icons.landscape_outlined, title: 'Our story & visit us', subtitle: '27 years of sweet beginnings', onTap: () => go(context, R.story)),
        ActionRow(icon: Icons.help_outline_rounded, title: 'Help & preferences', subtitle: 'Message the shop & notifications', onTap: () => go(context, R.help)),
        ActionRow(icon: Icons.policy_outlined, title: 'FAQ & policies', subtitle: 'Delivery, returns, privacy and terms', onTap: () => go(context, R.info, args: 'faq')),
        if (app.signedIn) ...[
          ActionRow(icon: Icons.lock_outline_rounded, title: 'Change password', subtitle: 'Also changes it for the website', onTap: () => _changePassword(context)),
          ActionRow(
            icon: Icons.logout_rounded,
            title: 'Sign out',
            subtitle: 'You can sign back in any time',
            onTap: () async {
              final ok = await confirmDialog(context, title: 'Sign out?', message: 'Your bag stays on this phone.', confirm: 'Sign out');
              if (!ok || !context.mounted) return;
              await context.appRead.logout();
              if (context.mounted) Navigator.of(context).pushNamedAndRemoveUntil(R.welcome, (_) => false);
            },
          ),
          ActionRow(icon: Icons.delete_outline_rounded, title: 'Delete my account', subtitle: 'Permanently remove your account', onTap: () => _deleteAccount(context)),
        ],
      ],
    );
  }

  Future<void> _editProfile(BuildContext context) async {
    final app = context.appRead;
    final name = TextEditingController(text: app.userName);
    final email = TextEditingController(text: app.email);
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 0, 24, MediaQuery.viewInsetsOf(ctx).bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Edit profile', style: T.display(28)),
          UField(label: 'Full name', controller: name),
          UField(label: 'Email', controller: email, keyboard: TextInputType.emailAddress),
          const Gap(18),
          PrimaryButton('Save', icon: null, onTap: () => Navigator.pop(ctx, true)),
        ]),
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await context.appRead.updateProfile(name: name.text.trim(), email: email.text.trim());
      if (context.mounted) toast(context, 'Profile updated');
    } on ApiException catch (e) {
      if (context.mounted) toast(context, e.message);
    }
  }

  Future<void> _changePassword(BuildContext context) async {
    final current = TextEditingController();
    final next = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 0, 24, MediaQuery.viewInsetsOf(ctx).bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Change password', style: T.display(28)),
          UField(label: 'Current password', controller: current, obscure: true),
          UField(label: 'New password (at least 8 characters)', controller: next, obscure: true),
          const Gap(18),
          PrimaryButton('Change password', icon: null, onTap: () => Navigator.pop(ctx, true)),
        ]),
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await context.appRead.changePassword(current.text, next.text);
      if (context.mounted) toast(context, 'Password changed. Other devices have been signed out.');
    } on ApiException catch (e) {
      if (context.mounted) toast(context, e.message);
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final pw = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 0, 24, MediaQuery.viewInsetsOf(ctx).bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Delete your account?', style: T.display(28)),
          const Gap(8),
          Text('This removes your account and favourites from the app and the website. Past orders are kept by the shop for its records. This can’t be undone.', style: T.body()),
          UField(label: 'Enter your password to confirm', controller: pw, obscure: true),
          const Gap(18),
          PrimaryButton('Delete my account', icon: null, onTap: () => Navigator.pop(ctx, true)),
        ]),
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await context.appRead.deleteAccount(pw.text);
      if (!context.mounted) return;
      toast(context, 'Your account has been deleted');
      Navigator.of(context).pushNamedAndRemoveUntil(R.welcome, (_) => false);
    } on ApiException catch (e) {
      if (context.mounted) toast(context, e.message);
    }
  }
}

// ───────────────────────── Favourites ─────────────────────────
class FavouritesScreen extends StatefulWidget {
  const FavouritesScreen({super.key});

  @override
  State<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen> {
  List<Product>? _items;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final list = await context.appRead.fetchWishlist();
      if (mounted) setState(() => _items = list);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final favs = context.app.favourites;
    final shown = (_items ?? const <Product>[]).where((p) => favs.contains(p.id)).toList();
    return UScaffold(
      title: 'Your favourites',
      nav: NavKind.customer,
      navIndex: 4,
      children: [
        const Eyebrow('Saved for later'),
        const Gap(10),
        const Headline('The ones you\n*love most.*'),
        const Gap(16),
        if (_error != null)
          LoadState(error: _error, onRetry: _load)
        else if (_items == null)
          const LoadState(loading: true)
        else if (shown.isEmpty)
          const LoadState(empty: 'Tap the heart on any sweet to save it here.')
        else
          ProductGrid(shown),
        if (!context.app.signedIn) const Note('Sign in to keep your favourites in sync with the website.'),
      ],
    );
  }
}

// ───────────────────────── FAQ & policies ─────────────────────────
class InfoPageScreen extends StatefulWidget {
  final String page;
  const InfoPageScreen({super.key, this.page = 'faq'});

  @override
  State<InfoPageScreen> createState() => _InfoPageScreenState();
}

class _InfoPageScreenState extends State<InfoPageScreen> {
  static const _pages = {'faq': 'FAQ', 'shipping': 'Delivery', 'returns': 'Returns', 'privacy': 'Privacy', 'terms': 'Terms'};
  late String _page = _pages.containsKey(widget.page) ? widget.page : 'faq';
  List<(String, String)>? _items;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _items = null;
      _error = null;
    });
    try {
      final items = await context.appRead.fetchPage(_page);
      if (mounted) setState(() => _items = items);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return UScaffold(
      title: 'A little help, with love',
      nav: NavKind.customer,
      navIndex: 4,
      children: [
        ChipGroup(
          options: _pages.values.toList(),
          selected: _pages[_page]!,
          scroll: true,
          onSelected: (v) {
            _page = _pages.entries.firstWhere((e) => e.value == v).key;
            _load();
          },
        ),
        const Gap(16),
        if (_error != null)
          LoadState(error: _error, onRetry: _load)
        else if (_items == null)
          const LoadState(loading: true)
        else
          for (final (title, body) in _items!)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: T.title()),
                const Gap(4),
                Text(body, style: T.body()),
              ]),
            ),
      ],
    );
  }
}

// ───────────────────────── 32 · Our story & visit us ─────────────────────────
class StoryScreen extends StatelessWidget {
  const StoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cfg = context.app.config;
    return UScaffold(
      title: 'Rooted in Devbhoomi',
      nav: NavKind.customer,
      navIndex: 4,
      bottom: OutlineBtn('Send the shop a message', onTap: () => go(context, R.help, args: 'visit')),
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
            Text(cfg.shopAddress, style: T.sans(11.5, color: AppColors.white, height: 1.6)),
            if (cfg.shopHours != null && cfg.shopHours!.isNotEmpty) ...[const Gap(4), Text(cfg.shopHours!, style: T.sans(11.5, color: AppColors.white, height: 1.6))],
            const Gap(12),
            Row(children: [
              if (cfg.mapsUrl != null) SmallButton('Directions', color: AppColors.berry, icon: Icons.near_me_outlined, onTap: () => openLink(context, cfg.mapsUrl!)),
              const SizedBox(width: 8),
              if (cfg.shopPhone != null && cfg.shopPhone!.isNotEmpty)
                SmallButton('Call shop', color: AppColors.tealDark, icon: Icons.call_outlined, onTap: () => openLink(context, 'tel:${cfg.shopPhone!.replaceAll(' ', '')}')),
            ]),
          ]),
        ),
      ],
    );
  }
}

// ───────────────────────── 33 · Notifications ─────────────────────────
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.appRead.loadMyOrders().catchError((_) {}));
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final recent = app.myOrders.take(5).toList();
    return UScaffold(
      title: 'A little heads-up',
      nav: NavKind.customer,
      navIndex: 0,
      children: [
        const Eyebrow('Order updates'),
        const Gap(10),
        const Headline('Fresh updates.\n*Sweet reminders.*'),
        const Gap(16),
        if (app.loadingOrders && recent.isEmpty) const LoadState(loading: true),
        if (!app.loadingOrders && recent.isEmpty) const LoadState(empty: 'No updates yet. Your order updates will appear here.'),
        for (final o in recent) ...[
          UCard(
            onTap: () => go(context, R.tracking, args: o.number),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('ORDER  #${o.number}', style: T.sans(9.5, weight: FontWeight.w700, spacing: 1.2)),
              const Gap(8),
              Text(o.needsPayment ? 'Payment pending' : o.statusLabel, style: T.display(24)),
              const Gap(6),
              Text('${money(o.total)} · updated ${o.updatedAt == null ? '' : dayMonth(o.updatedAt!)}', style: T.sans(11.5)),
            ]),
          ),
          const Gap(10),
        ],
        const Note('We also email every order update to the address on your order.'),
      ],
    );
  }
}

// ───────────────────────── 34 · Help & preferences ─────────────────────────
/// Sends the website's contact form (lands in Admin → Messages).
class HelpScreen extends StatefulWidget {
  final String? reference;
  const HelpScreen({super.key, this.reference});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  late String _topic = (widget.reference ?? '').startsWith('UDS') ? 'Existing order support' : 'Product enquiry';
  late final _name = TextEditingController(text: context.appRead.signedIn || context.appRead.guestName.isNotEmpty ? context.appRead.userName : '');
  late final _email = TextEditingController(text: context.appRead.email);
  late final _ref = TextEditingController(text: (widget.reference ?? '').startsWith('UDS') ? widget.reference : '');
  final _message = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_name, _email, _ref, _message]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _send() async {
    if (_message.text.trim().isEmpty) {
      toast(context, 'Please tell us how we can help');
      return;
    }
    setState(() => _busy = true);
    try {
      final app = context.appRead;
      final msg = await app.sendEnquiry('contact', {
        'name': _name.text.trim(),
        'email': _email.text.trim(),
        if (app.phone.length == 10) 'phone': app.phone,
        'topic': _topic,
        'message': _message.text.trim(),
        if (_ref.text.trim().isNotEmpty) 'order_number': _ref.text.trim(),
      });
      if (!mounted) return;
      _message.clear();
      await showSuccess(context, title: 'We’re on it', message: msg, cta: 'Thank you');
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final topics = app.config.contactTopics;
    if (!topics.contains(_topic) && topics.isNotEmpty) _topic = topics.first;
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
            final v = await pickOption(context, title: 'What can we help with?', options: topics, selected: _topic);
            if (v != null) setState(() => _topic = v);
          },
        ),
        UField(label: 'Your name', controller: _name),
        UField(label: 'Email (we reply here)', controller: _email, keyboard: TextInputType.emailAddress),
        UField(label: 'Order number (optional)', controller: _ref, hint: 'UDS-…'),
        UField(label: 'Your message', controller: _message, hint: 'Tell us what happened…', maxLines: 4),
        const Gap(16),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlineBtn(_busy ? 'Sending…' : 'Send to the shop', expanded: false, icon: Icons.north_east_rounded, onTap: _busy ? null : _send),
        ),
        if (app.config.shopPhone != null && app.config.shopPhone!.isNotEmpty) ...[
          const Gap(10),
          TextButton.icon(
            onPressed: () => openLink(context, 'tel:${app.config.shopPhone!.replaceAll(' ', '')}'),
            icon: const Icon(Icons.call_outlined, size: 16, color: AppColors.teal),
            label: Text('Or call ${app.config.shopPhone}', style: T.sans(12, color: AppColors.teal, weight: FontWeight.w600)),
          ),
        ],
        const Gap(16),
        const Divider(color: AppColors.border),
        const Gap(12),
        ToggleCard(title: 'Order notifications', value: app.notifications, onChanged: context.appRead.toggleNotifications, card: false),
      ],
    );
  }
}

// Kept so older code that copied the referral text still compiles.
void copyText(BuildContext context, String text, String done) {
  Clipboard.setData(ClipboardData(text: text));
  toast(context, done);
}
