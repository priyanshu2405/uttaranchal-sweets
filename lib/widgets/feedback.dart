import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/theme.dart';
import 'common.dart';

void toast(BuildContext context, String message, {String? action, VoidCallback? onAction}) {
  final m = ScaffoldMessenger.of(context);
  m.hideCurrentSnackBar();
  m.showSnackBar(SnackBar(
    content: Text(message),
    duration: const Duration(milliseconds: 2400),
    action: action == null ? null : SnackBarAction(label: action, onPressed: onAction ?? () {}),
  ));
}

/// Bottom-sheet single choice list. Returns the selected option or null.
Future<String?> pickOption(BuildContext context, {required String title, required List<String> options, String? selected}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: T.display(26)),
          const SizedBox(height: 8),
          Flexible(
            child: ListView(shrinkWrap: true, children: [
              for (final o in options)
                InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.pop(ctx, o);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderSoft))),
                    child: Row(children: [
                      Expanded(child: Text(o, style: T.sans(14, weight: o == selected ? FontWeight.w600 : FontWeight.w400))),
                      if (o == selected) const Icon(Icons.check_circle_rounded, color: AppColors.berry, size: 20),
                    ]),
                  ),
                ),
            ]),
          ),
        ]),
      ),
    ),
  );
}

/// Celebratory confirmation sheet used at the end of flows.
Future<void> showSuccess(
  BuildContext context, {
  required String title,
  required String message,
  String cta = 'Done',
  Color color = AppColors.teal,
  IconData icon = Icons.check_rounded,
}) {
  HapticFeedback.mediumImpact();
  return showModalBottomSheet<void>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          CheckBadge(color: color, icon: icon),
          const SizedBox(height: 16),
          Text(title, textAlign: TextAlign.center, style: T.display(30)),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center, style: T.body()),
          const SizedBox(height: 22),
          PrimaryButton(cta, color: color, icon: null, onTap: () => Navigator.pop(ctx)),
        ]),
      ),
    ),
  );
}

/// Short "processing" dialog used to make payments etc. feel real in a demo.
Future<void> showProcessing(BuildContext context, String message, {Duration duration = const Duration(milliseconds: 1400)}) async {
  final nav = Navigator.of(context, rootNavigator: true);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(width: 34, height: 34, child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.berry)),
            const SizedBox(height: 18),
            Text(message, textAlign: TextAlign.center, style: T.sans(14, weight: FontWeight.w600)),
          ]),
        ),
      ),
    ),
  );
  await Future<void>.delayed(duration);
  if (nav.mounted) nav.pop();
}

Future<bool> confirmDialog(BuildContext context, {required String title, required String message, String confirm = 'Confirm', Color color = AppColors.berry}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.cream,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title, style: T.display(26)),
      content: Text(message, style: T.body()),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: T.sans(13, color: AppColors.muted, weight: FontWeight.w600))),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirm, style: T.sans(13, color: AppColors.white, weight: FontWeight.w700)),
        ),
      ],
    ),
  );
  return r ?? false;
}

Future<DateTime?> pickDate(BuildContext context, {required DateTime initial, DateTime? first, DateTime? last}) {
  return showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: first ?? DateTime(2026, 1, 1),
    lastDate: last ?? DateTime(2027, 12, 31),
    builder: (ctx, child) => Theme(
      data: Theme.of(ctx).copyWith(
        colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: AppColors.berry, onPrimary: AppColors.white, surface: AppColors.cream),
      ),
      child: child!,
    ),
  );
}

String isoDate(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

const _months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
String monthName(int m) => _months[m - 1];
String dayMonth(DateTime d) => '${d.day} ${_months[d.month - 1]}';

/// Animated brand check badge (order confirmation, success sheets).
class CheckBadge extends StatelessWidget {
  final Color color;
  final IconData icon;
  final double size;
  const CheckBadge({super.key, this.color = AppColors.teal, this.icon = Icons.check_rounded, this.size = 72});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.elasticOut,
      builder: (context, v, child) => Transform.scale(scale: v, child: child),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(size * 0.32)),
        child: Icon(icon, color: AppColors.yellow, size: size * 0.5),
      ),
    );
  }
}
