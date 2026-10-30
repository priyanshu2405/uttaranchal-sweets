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
import '../../widgets/illustrations.dart';
import '../../widgets/u_scaffold.dart';

// ───────────────────────── 01 · Welcome ─────────────────────────
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

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
                        // Long-press the logo to open the presenter's screen index.
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
                        PrimaryButton(hindi ? 'शुरू करें' : 'Let’s begin', icon: Icons.north_east_rounded, onTap: () => go(context, R.signIn)),
                        const SizedBox(height: 14),
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          _LangLink('English', active: !hindi, onTap: () => context.appRead.setLanguage('English')),
                          Text('   ·   ', style: T.sans(11, color: AppColors.berry)),
                          _LangLink('हिन्दी', active: hindi, onTap: () => context.appRead.setLanguage('हिन्दी')),
                        ]),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () => go(context, R.staffSignIn),
                          child: Text('Delivery partner? Staff sign in', style: T.sans(11, color: AppColors.ink, weight: FontWeight.w500).copyWith(decoration: TextDecoration.underline)),
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

// ───────────────────────── 02 · Mobile sign in ─────────────────────────
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  late final _phone = TextEditingController(text: context.appRead.phone);

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  void _submit() {
    final digits = _phone.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) {
      toast(context, 'Please enter a valid 10-digit mobile number');
      return;
    }
    context.appRead.phone = '${digits.substring(0, 5)} ${digits.substring(5)}';
    FocusScope.of(context).unfocus();
    go(context, R.verify);
  }

  @override
  Widget build(BuildContext context) {
    return UScaffold(
      title: 'Namaste.',
      trailing: const HelpButton(),
      bottom: PrimaryButton('Send verification code', onTap: _submit),
      children: [
        const Eyebrow('Welcome to the family'),
        const Gap(10),
        const Headline('Good things\nstart *here.*'),
        const Gap(12),
        const BodyText('Sign in to order your favourites, manage milk deliveries and collect sweet rewards.'),
        const Gap(18),
        ColorBlock(
          color: AppColors.yellow,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Every visit. More sweetness.', style: T.display(23)),
            const Gap(8),
            Text('Your rewards stay with you, from your morning milk to your next celebration.', style: T.sans(12, height: 1.55)),
          ]),
        ),
        UField(
          label: 'Mobile number',
          controller: _phone,
          prefixText: '+91',
          keyboard: TextInputType.phone,
          action: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')), LengthLimitingTextInputFormatter(11)],
        ),
        const FinePrint('We’ll send a verification code to this number.'),
        const Gap(14),
        const Note('By continuing, you agree to the Terms of Use and Privacy Policy.'),
        const Gap(18),
        Center(child: Text('Fresh traditions. Familiar warmth.', style: T.sans(12, color: AppColors.muted))),
      ],
    );
  }
}

// ───────────────────────── 03 · Verify mobile ─────────────────────────
class VerifyScreen extends StatefulWidget {
  const VerifyScreen({super.key});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  final _controllers = List.generate(4, (i) => TextEditingController(text: '2468'[i]));
  final _nodes = List.generate(4, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  void _verify() async {
    if (_code.length != 4) {
      toast(context, 'Enter the 4-digit code');
      return;
    }
    FocusScope.of(context).unfocus();
    await showProcessing(context, 'Verifying…', duration: const Duration(milliseconds: 900));
    if (mounted) go(context, R.location);
  }

  @override
  Widget build(BuildContext context) {
    return UScaffold(
      title: 'Verify your number',
      trailing: const HelpButton(),
      bottom: PrimaryButton('Verify & continue', onTap: _verify),
      children: [
        const Eyebrow('One small step'),
        const Gap(10),
        const Headline('You’re nearly\n*home.*'),
        const Gap(14),
        Text('Enter the 4-digit code sent to', style: T.body()),
        const Gap(2),
        Row(children: [
          Text('+91 ${context.app.phone}', style: T.sans(12.5, weight: FontWeight.w700)),
          Text(' · ', style: T.body()),
          GestureDetector(onTap: () => Navigator.maybePop(context), child: Text('Change', style: T.sans(12.5, color: AppColors.berry, weight: FontWeight.w600))),
        ]),
        const Gap(22),
        Row(children: [
          for (var i = 0; i < 4; i++)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: SizedBox(
                width: 48,
                height: 54,
                child: TextField(
                  controller: _controllers[i],
                  focusNode: _nodes[i],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(1)],
                  style: T.display(26, color: AppColors.berry),
                  onChanged: (v) {
                    if (v.isNotEmpty && i < 3) _nodes[i + 1].requestFocus();
                    if (v.isEmpty && i > 0) _nodes[i - 1].requestFocus();
                    if (_code.length == 4) FocusScope.of(context).unfocus();
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: EdgeInsets.zero,
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.berry, width: 1.5)),
                  ),
                ),
              ),
            ),
        ]),
        const Gap(22),
        Row(children: [
          Text('Didn’t receive a code?  ', style: T.sans(12, color: AppColors.muted)),
          SmallButton('Resend code', filled: false, color: AppColors.ink, onTap: () => toast(context, 'A new code is on its way')),
        ]),
        const Gap(18),
        ColorBlock(
          color: AppColors.teal,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Welcome to something sweet.', style: T.display(23, color: AppColors.white)),
            const Gap(8),
            Text('Your milk plans, favourites and loyalty points—all in one place.', style: T.sans(12, color: AppColors.white)),
          ]),
        ),
        const FinePrint('Demo code: 2468'),
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

  @override
  void dispose() {
    _pin.dispose();
    _street.dispose();
    _city.dispose();
    super.dispose();
  }

  bool get _fromAccount => ModalRoute.of(context)?.settings.arguments == 'edit';

  void _save() {
    if (_pin.text.trim().length != 6) {
      toast(context, 'Please enter a 6-digit pincode');
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
      bottom: PrimaryButton('Save this location', onTap: _save),
      children: [
        const Eyebrow('Let’s find you'),
        const Gap(10),
        const Headline('Where shall we\nbring the *sweetness?*'),
        const Gap(16),
        const RouteMap(height: 160),
        const Gap(4),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => toast(context, 'Location detected · Patel Nagar, Kashipur'),
            icon: const Icon(Icons.my_location_rounded, size: 16, color: AppColors.teal),
            label: Text('Use my current location', style: T.sans(12, color: AppColors.teal, weight: FontWeight.w600)),
          ),
        ),
        UField(label: 'Pincode', controller: _pin, keyboard: TextInputType.number, formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)]),
        UField(label: 'House / flat & street', controller: _street),
        UField(label: 'City', controller: _city),
        const Gap(16),
        const Note('Good news! Fresh milk delivery and local shopping are available in this sample area.', tone: NoteTone.mint),
      ],
    );
  }
}
