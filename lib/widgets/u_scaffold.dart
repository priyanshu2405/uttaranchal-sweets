import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/nav.dart';
import '../app/routes.dart';
import '../app/theme.dart';
import '../state/app_state.dart';
import 'common.dart';

enum NavKind { none, customer, staff }

/// Standard page shell matching the design: cream header with serif title,
/// scrollable body, optional sticky CTA area and bottom navigation.
class UScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;
  final Widget? bottom;
  final NavKind nav;
  final int navIndex;
  final Widget? trailing;
  final bool showHeader;
  final EdgeInsets padding;
  final VoidCallback? onBack;
  final Color background;
  final Widget? header;

  const UScaffold({
    super.key,
    this.title = '',
    this.subtitle = 'Uttaranchal Dairy & Sweets',
    required this.children,
    this.bottom,
    this.nav = NavKind.none,
    this.navIndex = 0,
    this.trailing = const BagButton(),
    this.showHeader = true,
    this.padding = const EdgeInsets.fromLTRB(20, 18, 20, 28),
    this.onBack,
    this.background = AppColors.cream,
    this.header,
  });

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final showNav = nav != NavKind.none && !keyboardOpen;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.overlay,
      child: Scaffold(
        backgroundColor: background,
        body: Column(children: [
          if (header != null) header!,
          if (header == null && showHeader) UHeader(title: title, subtitle: subtitle, trailing: trailing, onBack: onBack),
          Expanded(
            child: ListView(
              padding: padding,
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: children,
            ),
          ),
          if (bottom != null)
            Container(
              decoration: const BoxDecoration(color: AppColors.cream, border: Border(top: BorderSide(color: AppColors.borderSoft))),
              child: SafeArea(
                top: false,
                bottom: !showNav,
                child: Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 12), child: bottom),
              ),
            ),
          if (showNav && nav == NavKind.customer) CustomerNav(index: navIndex),
          if (showNav && nav == NavKind.staff) StaffNav(index: navIndex),
          if (!showNav && bottom == null) SizedBox(height: MediaQuery.paddingOf(context).bottom),
        ]),
      ),
    );
  }
}

class UHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onBack;
  const UHeader({super.key, required this.title, required this.subtitle, this.trailing, this.onBack});

  @override
  Widget build(BuildContext context) {
    final canPop = onBack != null || (ModalRoute.of(context)?.canPop ?? false);
    return Container(
      decoration: const BoxDecoration(color: AppColors.header, border: Border(bottom: BorderSide(color: AppColors.borderSoft))),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(canPop ? 4 : 20, 8, 16, 10),
          child: Row(children: [
            if (canPop)
              IconButton(
                onPressed: onBack ?? () => Navigator.maybePop(context),
                icon: const Icon(Icons.chevron_left_rounded, size: 30, color: AppColors.ink),
                tooltip: 'Back',
              ),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(title, style: T.display(25), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(subtitle.toUpperCase(), style: T.sans(8.5, color: AppColors.muted, weight: FontWeight.w600, spacing: 1.1)),
              ]),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ]),
        ),
      ),
    );
  }
}

/// Header shortcut to the shopping bag with a live item count.
class BagButton extends StatelessWidget {
  const BagButton({super.key});

  @override
  Widget build(BuildContext context) {
    final count = context.app.cartCount;
    return IconTileButton(
      Icons.shopping_bag_outlined,
      badge: count,
      onTap: () {
        if (ModalRoute.of(context)?.settings.name == R.bag) return;
        go(context, R.bag);
      },
    );
  }
}

class HelpButton extends StatelessWidget {
  const HelpButton({super.key});

  @override
  Widget build(BuildContext context) => IconTileButton(Icons.headset_mic_outlined, onTap: () => go(context, R.help));
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
  const _NavItem(this.icon, this.activeIcon, this.label, this.route);
}

class _UBottomNav extends StatelessWidget {
  final List<_NavItem> items;
  final int index;
  const _UBottomNav({required this.items, required this.index});

  @override
  Widget build(BuildContext context) {
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    return Container(
      decoration: const BoxDecoration(color: AppColors.header, border: Border(top: BorderSide(color: AppColors.borderSoft))),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: InkResponse(
                  highlightShape: BoxShape.rectangle,
                  containedInkWell: true,
                  onTap: () {
                    if (i == index && !canPop) return;
                    HapticFeedback.selectionClick();
                    goTab(context, items[i].route);
                  },
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: i == index ? 18 : 0,
                      height: 2.5,
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(color: AppColors.berry, borderRadius: BorderRadius.circular(2)),
                    ),
                    Icon(i == index ? items[i].activeIcon : items[i].icon, size: 22, color: i == index ? AppColors.berry : AppColors.muted),
                    const SizedBox(height: 3),
                    Text(
                      items[i].label,
                      style: T.sans(10, color: i == index ? AppColors.berry : AppColors.muted, weight: i == index ? FontWeight.w700 : FontWeight.w500),
                    ),
                  ]),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

class CustomerNav extends StatelessWidget {
  final int index;
  const CustomerNav({super.key, required this.index});

  static const _items = [
    _NavItem(Icons.home_outlined, Icons.home_rounded, 'Home', R.home),
    _NavItem(Icons.storefront_outlined, Icons.storefront_rounded, 'Shop', R.collection),
    _NavItem(Icons.local_drink_outlined, Icons.local_drink_rounded, 'Milk', R.milkHub),
    _NavItem(Icons.redeem_outlined, Icons.redeem_rounded, 'Rewards', R.rewards),
    _NavItem(Icons.person_outline_rounded, Icons.person_rounded, 'You', R.account),
  ];

  @override
  Widget build(BuildContext context) => _UBottomNav(items: _items, index: index);
}

class StaffNav extends StatelessWidget {
  final int index;
  const StaffNav({super.key, required this.index});

  static const _items = [
    _NavItem(Icons.alt_route_outlined, Icons.alt_route_rounded, 'Route', R.staffDashboard),
    _NavItem(Icons.format_list_numbered_rounded, Icons.format_list_numbered_rounded, 'Stops', R.staffRoute),
    _NavItem(Icons.inventory_2_outlined, Icons.inventory_2_rounded, 'Stock', R.staffStock),
    _NavItem(Icons.summarize_outlined, Icons.summarize_rounded, 'Summary', R.staffSummary),
  ];

  @override
  Widget build(BuildContext context) => _UBottomNav(items: _items, index: index);
}
