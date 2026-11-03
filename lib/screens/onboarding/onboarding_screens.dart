import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/nav.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../data/api.dart';
import '../../data/catalog.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../../widgets/feedback.dart';
import '../../widgets/fields.dart';
import '../../widgets/illustrations.dart';
import '../../widgets/u_scaffold.dart';

// ───────────────────────── 01 · Welcome ─────────────────────────
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _redirected = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final app = context.appRead;
      if (!app.ready) await app.init();
      if (!mounted) return;
      // Already signed in on this phone → straight to the shop.
      if (app.ready && app.signedIn && !_redirected) {
        _redirected = true;
        goTab(context, R.home);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final hindi = app.language == 'हिन्दी';
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.overlay,
      child: Scaffold(
        backgroundColor: AppColors.yellow,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, c) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: c.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(children: [
                        // Long-press the logo to open the screen index (handy while testing).
                        GestureDetector(
                          onLongPress: () {
                            HapticFeedback.heavyImpact();
                            go(context, R.screenIndex);
                          },
                          child: const BrandLogo(),
                        ),
                        const SizedBox(height: 22),
                        const _FadeUp(
                          child: ArchImage(Img.sweets, width: 224, height: 236, arch: 112),
                        ),
                        const SizedBox(height: 26),
                        Text('27   YEARS   OF   SWEET   BEGINNINGS', style: T.sans(10, color: AppColors.ink, weight: FontWeight.w600, spacing: 1)),
                        const SizedBox(height: 14),
                        const Headline('A little taste\nof *home.*', size: 44, align: TextAlign.center),
                        const SizedBox(height: 10),
                        Text('घर जैसा स्वाद, हर दिन', style: T.deva(13, color: AppColors.ink)),
                        const SizedBox(height: 4),
                        Text(hindi ? 'मिठाई, ताज़ा दूध और रोज़ की खुशियाँ।' : 'Sweets, fresh milk & everyday happiness.',
                            style: hindi ? T.deva(12.5, color: AppColors.ink) : T.sans(12.5, color: AppColors.ink)),
                      ]),
                      Column(children: [
                        const SizedBox(height: 24),
                        if (app.bootError != null) ...[
                          Note(app.bootError!),
                          const SizedBox(height: 10),
                          OutlineBtn('Try again', icon: Icons.refresh_rounded, onTap: () => context.appRead.init()),
                        ] else
                          PrimaryButton(
                            app.ready ? (hindi ? 'शुरू करें' : 'Let’s begin') : 'Opening the shop…',
                            icon: app.ready ? Icons.north_east_rounded : null,
                            onTap: app.ready ? () => go(context, app.signedIn ? R.home : R.signIn) : null,
                          ),
                        const SizedBox(height: 14),
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          _LangLink('English', active: !hindi, onTap: () => context.appRead.setLanguage('English')),
                          Text('   ·   ', style: T.sans(11, color: AppColors.berry)),
                          _LangLink('हिन्दी', active: hindi, onTap: () => context.appRead.setLanguage('हिन्दी')),
                        ]),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () => go(context, app.staffSignedIn ? R.staffOrders : R.staffSignIn),
                          child: Text('Shop staff? Staff sign in', style: T.sans(11, color: AppColors.ink, weight: FontWeight.w500).copyWith(decoration: TextDecoration.underline)),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LangLink extends StatelessWidget {
  final String text;
  final bool active;
  final VoidCallback onTap;
  const _LangLink(this.text, {required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDeva = text.codeUnitAt(0) > 0x0900;
    final base = isDeva ? T.deva(12, color: AppColors.berry) : T.sans(11.5, color: AppColors.berry);
    return GestureDetector(
      onTap: onTap,
      child: Text(text, style: base.copyWith(fontWeight: active ? FontWeight.w700 : FontWeight.w400, decoration: active ? TextDecoration.underline : null)),
    );
  }
}

class BrandLogo extends StatelessWidget {
  final double scale;
  const BrandLogo({super.key, this.scale = 1});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        width: 44 * scale,
        height: 56 * scale,
        alignment: Alignment.center,
        padding: EdgeInsets.only(top: 6 * scale),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.berry, width: 1.6),
          borderRadius: BorderRadius.vertical(top: Radius.circular(22 * scale), bottom: const Radius.circular(2)),
        ),
        child: Text('उ', style: T.deva(26 * scale, color: AppColors.berry, weight: FontWeight.w600)),
      ),
      SizedBox(height: 8 * scale),
      Text('UTTARANCHAL', style: T.display(28 * scale, weight: FontWeight.w500).copyWith(letterSpacing: 1.5)),
      Text('DAIRY  &  SWEETS', style: T.display(15 * scale, weight: FontWeight.w500).copyWith(letterSpacing: 1.2)),
    ]);
  }
}

class _FadeUp extends StatelessWidget {
  final Widget child;
  const _FadeUp({required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, v, c) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 24 * (1 - v)), child: c)),
      child: child,
    );
  }
}

// ───────────────────────── 02 · Sign in ─────────────────────────
/// Same accounts as the website: mobile number + password.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  late final _phone = TextEditingController(text: context.appRead.phone);
  final _password = TextEditingController();
  bool _busy = false;
  bool _hide = true;

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final digits = _phone.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) {
      toast(context, 'Please enter a valid 10-digit mobile number');
      return;
    }
    if (_password.text.isEmpty) {
      toast(context, 'Please enter your password');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      await context.appRead.login(phone: digits, password: _password.text);
      if (!mounted) return;
      toast(context, 'Welcome back, ${context.appRead.firstName}');
      goTab(context, context.appRead.hasAddress ? R.home : R.location);
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return UScaffold(
      title: 'Namaste.',
      trailing: const HelpButton(),
      bottom: PrimaryButton(_busy ? 'Signing in…' : 'Sign in', onTap: _busy ? null : _submit),
      children: [
        const Eyebrow('Welcome to the family'),
        const Gap(10),
        const Headline('Good things\nstart *here.*'),
        const Gap(12),
        const BodyText('Sign in with the same mobile number and password you use on our website. Your orders and favourites are shared between both.'),
        UField(
          label: 'Mobile number',
          controller: _phone,
          prefixText: '+91',
          keyboard: TextInputType.phone,
          action: TextInputAction.next,
          formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')), LengthLimitingTextInputFormatter(11)],
        ),
        UField(
          label: 'Password',
          controller: _password,
          obscure: _hide,
          action: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          suffix: IconButton(
            icon: Icon(_hide ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18, color: AppColors.muted),
            onPressed: () => setState(() => _hide = !_hide),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(onPressed: () => showForgotPassword(context), child: Text('Forgot password?', style: T.sans(12, color: AppColors.berry, weight: FontWeight.w600))),
        ),
        const Gap(6),
        ColorBlock(
          color: AppColors.yellow,
          onTap: () => go(context, R.verify),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('New here?', style: T.display(23)),
                const Gap(6),
                Text('Create your account in a minute — it works on the website too.', style: T.sans(12, height: 1.55)),
              ]),
            ),
            const IconTileButton(Icons.north_east_rounded),
          ]),
        ),
        const Gap(12),
        Center(
          child: TextButton(
            onPressed: () => goTab(context, R.home),
            child: Text('Continue as guest', style: T.sans(12.5, color: AppColors.ink, weight: FontWeight.w600).copyWith(decoration: TextDecoration.underline)),
          ),
        ),
        const Note('By continuing, you agree to the Terms of Use and Privacy Policy.'),
      ],
    );
  }
}

/// Emails the website's password-reset link.
Future<void> showForgotPassword(BuildContext context) async {
  final c = TextEditingController(text: context.appRead.email);
  final email = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, MediaQuery.viewInsetsOf(ctx).bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Reset your password', style: T.display(28)),
        const Gap(8),
        Text('We’ll email you a link. Choose a new password on the website, then sign in here.', style: T.body()),
        UField(label: 'Email on your account', controller: c, keyboard: TextInputType.emailAddress, autofocus: true),
        const Gap(18),
        PrimaryButton('Send reset link', icon: null, onTap: () => Navigator.pop(ctx, c.text.trim())),
      ]),
    ),
  );
  if (email == null || email.isEmpty || !context.mounted) return;
  try {
    final msg = await context.appRead.forgotPassword(email);
    if (context.mounted) toast(context, msg);
  } on ApiException catch (e) {
    if (context.mounted) toast(context, e.message);
  }
}

// ───────────────────────── 03 · Create account ─────────────────────────
/// (Route kept as R.verify so existing links still work.)
class VerifyScreen extends StatefulWidget {
  const VerifyScreen({super.key});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  final _name = TextEditingController();
  late final _phone = TextEditingController(text: context.appRead.phone);
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _newsletter = true;
  bool _busy = false;
  Map<String, String> _errors = {};

  @override
  void dispose() {
    for (final c in [_name, _phone, _email, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final digits = _phone.text.replaceAll(RegExp(r'\D'), '');
    final errors = <String, String>{};
    if (_name.text.trim().isEmpty) errors['name'] = 'Please enter your name';
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(digits)) errors['phone'] = 'Enter a valid 10-digit Indian mobile number';
    if (!_email.text.contains('@')) errors['email'] = 'Please enter a valid email';
    if (_password.text.length < 8) errors['password'] = 'Use at least 8 characters';
    setState(() => _errors = errors);
    if (errors.isNotEmpty) {
      toast(context, errors.values.first);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      await context.appRead.register(name: _name.text.trim(), phone: digits, email: _email.text.trim(), password: _password.text, newsletter: _newsletter);
      if (!mounted) return;
      toast(context, 'Welcome to the family, ${context.appRead.firstName}!');
      goTab(context, context.appRead.hasAddress ? R.home : R.location);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _errors = e.errors.map((k, v) => MapEntry(k, v.first)));
      toast(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _err(String field) => _errors[field] == null
      ? const SizedBox.shrink()
      : Padding(padding: const EdgeInsets.only(top: 4), child: Text(_errors[field]!, style: T.sans(11, color: AppColors.berry)));

  @override
  Widget build(BuildContext context) {
    return UScaffold(
      title: 'Create your account',
      trailing: const HelpButton(),
      bottom: PrimaryButton(_busy ? 'Creating account…' : 'Create account', onTap: _busy ? null : _submit),
      children: [
        const Eyebrow('One small step'),
        const Gap(10),
        const Headline('You’re nearly\n*home.*'),
        const Gap(8),
        const BodyText('One account for the app and the website — your orders and favourites follow you.'),
        UField(label: 'Full name', controller: _name, action: TextInputAction.next),
        _err('name'),
        UField(
          label: 'Mobile number',
          controller: _phone,
          prefixText: '+91',
          keyboard: TextInputType.phone,
          formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')), LengthLimitingTextInputFormatter(11)],
        ),
        _err('phone'),
        UField(label: 'Email', controller: _email, keyboard: TextInputType.emailAddress),
        _err('email'),
        UField(label: 'Password (at least 8 characters)', controller: _password, obscure: true),
        _err('password'),
        const Gap(12),
        ToggleCard(title: 'Send me festive offers & new sweets by email', value: _newsletter, onChanged: (v) => setState(() => _newsletter = v), card: false),
        const Gap(8),
        Center(
          child: TextButton(
            onPressed: () => Navigator.maybePop(context),
            child: Text('Already have an account? Sign in', style: T.sans(12.5, color: AppColors.berry, weight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

// ───────────────────────── 04 · Delivery location ─────────────────────────
class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  late final _pin = TextEditingController(text: context.appRead.pincode);
  late final _street = TextEditingController(text: context.appRead.street);
  late final _city = TextEditingController(text: context.appRead.city);
  String? _pinMessage;
  bool? _local;

  @override
  void initState() {
    super.initState();
    if (_pin.text.length == 6) WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    _pin.dispose();
    _street.dispose();
    _city.dispose();
    super.dispose();
  }

  bool get _fromAccount => ModalRoute.of(context)?.settings.arguments == 'edit';

  Future<void> _check() async {
    final pin = _pin.text.trim();
    if (pin.length != 6) return;
    final (local, message) = await context.appRead.checkPincode(pin);
    if (!mounted) return;
    setState(() {
      _local = local;
      _pinMessage = message;
    });
  }

  void _save() {
    if (_pin.text.trim().length != 6) {
      toast(context, 'Please enter a 6-digit pincode');
      return;
    }
    if (_street.text.trim().isEmpty) {
      toast(context, 'Please enter your house / street');
      return;
    }
    context.appRead.saveAddress(pincode: _pin.text.trim(), street: _street.text.trim(), city: _city.text.trim());
    if (_fromAccount) {
      Navigator.pop(context);
      toast(context, 'Address saved');
    } else {
      goTab(context, R.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return UScaffold(
      title: 'Your neighbourhood',
      trailing: const HelpButton(),
      bottom: PrimaryButton('Save this address', onTap: _save),
      children: [
        const Eyebrow('Let’s find you'),
        const Gap(10),
        const Headline('Where shall we\nbring the *sweetness?*'),
        const Gap(16),
        const RouteMap(height: 140),
        UField(
          label: 'Pincode',
          controller: _pin,
          keyboard: TextInputType.number,
          formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
          onChanged: (v) {
            if (v.length == 6) _check();
          },
        ),
        UField(label: 'House / flat & street', controller: _street),
        UField(label: 'City', controller: _city),
        const Gap(16),
        if (_pinMessage != null) Note(_pinMessage!, tone: _local == true ? NoteTone.mint : NoteTone.yellow),
        if (_pinMessage == null) const Note('Enter your pincode to see whether we deliver fresh sweets to you. Store pickup is always available.'),
        if (!_fromAccount) ...[
          const Gap(8),
          Center(child: TextButton(onPressed: () => goTab(context, R.home), child: Text('Skip for now', style: T.sans(12, color: AppColors.muted)))),
        ],
      ],
    );
  }
}
