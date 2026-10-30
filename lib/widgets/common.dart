import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/theme.dart';

// ─────────────────────────── Typography blocks ───────────────────────────

class Eyebrow extends StatelessWidget {
  final String text;
  final Color color;
  final TextAlign align;
  const Eyebrow(this.text, {super.key, this.color = AppColors.teal, this.align = TextAlign.start});

  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(), style: T.eyebrow(color), textAlign: align);
}

/// Serif headline. Wrap words in *asterisks* to render them in the teal italic
/// accent used throughout the design, e.g. `'Good things\nstart *here.*'`.
class Headline extends StatelessWidget {
  final String text;
  final double size;
  final TextAlign align;
  final Color color;
  final Color accent;
  const Headline(this.text, {super.key, this.size = 36, this.align = TextAlign.start, this.color = AppColors.berry, this.accent = AppColors.teal});

  @override
  Widget build(BuildContext context) {
    final parts = text.split('*');
    return Text.rich(
      TextSpan(children: [
        for (var i = 0; i < parts.length; i++)
          TextSpan(
            text: parts[i],
            style: i.isOdd
                ? T.display(size, color: accent, italic: true, weight: FontWeight.w500, height: 1.02)
                : T.display(size, color: color, height: 1.02),
          ),
      ]),
      textAlign: align,
    );
  }
}

class BodyText extends StatelessWidget {
  final String text;
  final Color color;
  final TextAlign align;
  const BodyText(this.text, {super.key, this.color = AppColors.muted, this.align = TextAlign.start});

  @override
  Widget build(BuildContext context) => Text(text, style: T.body(color), textAlign: align);
}

class FinePrint extends StatelessWidget {
  final String text;
  final TextAlign align;
  const FinePrint(this.text, {super.key, this.align = TextAlign.start});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Text(text, style: T.tiny(), textAlign: align),
      );
}

class SectionTitle extends StatelessWidget {
  final String text;
  final String? action;
  final VoidCallback? onAction;
  final double size;
  const SectionTitle(this.text, {super.key, this.action, this.onAction, this.size = 26});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: Text(text, style: T.display(size))),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(action!, style: T.sans(11.5, color: AppColors.berry, weight: FontWeight.w600)),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────── Buttons ───────────────────────────

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color color;
  final Color textColor;
  final IconData? icon;
  final double height;
  final bool expanded;
  const PrimaryButton(
    this.label, {
    super.key,
    this.onTap,
    this.color = AppColors.berry,
    this.textColor = AppColors.white,
    this.icon = Icons.arrow_forward_rounded,
    this.height = 50,
    this.expanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final btn = Material(
      color: enabled ? color : color.withAlpha(110),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                onTap!();
              },
        child: SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(label, style: T.sans(13.5, color: textColor, weight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                ),
                if (icon != null) ...[const SizedBox(width: 6), Icon(icon, size: 16, color: textColor)],
              ],
            ),
          ),
        ),
      ),
    );
    return expanded ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}

class OutlineBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color color;
  final IconData? icon;
  final bool expanded;
  final double height;
  const OutlineBtn(this.label, {super.key, this.onTap, this.color = AppColors.berry, this.icon = Icons.arrow_forward_rounded, this.expanded = true, this.height = 50});

  @override
  Widget build(BuildContext context) {
    final btn = Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: color.withAlpha(90))),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(child: Text(label, style: T.sans(13, color: color, weight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
                if (icon != null) ...[const SizedBox(width: 6), Icon(icon, size: 15, color: color)],
              ],
            ),
          ),
        ),
      ),
    );
    return expanded ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}

/// Compact pill button – "Explore mithai ↗", "Reorder", "View calendar".
class SmallButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool filled;
  final Color color;
  final IconData? icon;
  const SmallButton(this.label, {super.key, this.onTap, this.filled = true, this.color = AppColors.berry, this.icon});

  @override
  Widget build(BuildContext context) {
    final fg = filled ? AppColors.white : color;
    return Material(
      color: filled ? color : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(9),
        side: filled ? BorderSide.none : BorderSide(color: color.withAlpha(90)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(label, style: T.sans(11.5, color: fg, weight: FontWeight.w700)),
            if (icon != null) ...[const SizedBox(width: 4), Icon(icon, size: 13, color: fg)],
          ]),
        ),
      ),
    );
  }
}

class IconTileButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final int badge;
  final bool dot;
  final Color color;
  final Color background;
  const IconTileButton(this.icon, {super.key, this.onTap, this.badge = 0, this.dot = false, this.color = AppColors.berry, this.background = const Color(0xFFFFF1D3)});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.border)),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: SizedBox(width: 40, height: 40, child: Icon(icon, size: 19, color: color)),
          ),
        ),
        if (badge > 0)
          Positioned(
            right: -5,
            top: -5,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
              child: Container(
                key: ValueKey(badge),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                constraints: const BoxConstraints(minWidth: 18),
                decoration: BoxDecoration(color: AppColors.berry, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.cream, width: 1.5)),
                child: Text('$badge', textAlign: TextAlign.center, style: T.sans(9.5, color: AppColors.white, weight: FontWeight.w700, height: 1.2)),
              ),
            ),
          ),
        if (dot)
          Positioned(
            right: 8,
            top: 8,
            child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.berry, shape: BoxShape.circle)),
          ),
      ],
    );
  }
}

// ─────────────────────────── Chips & pills ───────────────────────────

class ChipGroup extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;
  final bool scroll;
  const ChipGroup({super.key, required this.options, required this.selected, required this.onSelected, this.scroll = false});

  @override
  Widget build(BuildContext context) {
    final chips = [
      for (final o in options)
        _UChip(
          label: o,
          selected: o == selected,
          onTap: () {
            HapticFeedback.selectionClick();
            onSelected(o);
          },
        ),
    ];
    if (scroll) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        child: Row(children: [for (final c in chips) Padding(padding: const EdgeInsets.only(right: 8), child: c)]),
      );
    }
    return Wrap(spacing: 8, runSpacing: 8, children: chips);
  }
}

class _UChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _UChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.berry : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.berry : AppColors.border),
        ),
        child: Text(label, style: T.sans(11.5, color: selected ? AppColors.white : AppColors.ink, weight: FontWeight.w500)),
      ),
    );
  }
}

class Pill extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  final IconData? icon;
  const Pill(this.text, {super.key, this.bg = AppColors.mint, this.fg = AppColors.teal, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 11, color: fg), const SizedBox(width: 4)],
        Text(text.toUpperCase(), style: T.sans(8.5, color: fg, weight: FontWeight.w700, spacing: 0.6)),
      ]),
    );
  }
}

// ─────────────────────────── Cards & rows ───────────────────────────

class UCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final bool border;
  final double radius;
  final VoidCallback? onTap;
  const UCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.color = AppColors.surface, this.border = true, this.radius = 16, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: border ? const BorderSide(color: AppColors.border) : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
    );
  }
}

/// Solid brand-colour block (teal / purple / yellow / berry).
class ColorBlock extends StatelessWidget {
  final Color color;
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  const ColorBlock({super.key, required this.color, required this.child, this.padding = const EdgeInsets.all(18), this.onTap});

  @override
  Widget build(BuildContext context) => UCard(color: color, border: false, padding: padding, onTap: onTap, child: child);
}

enum NoteTone { yellow, mint, pink }

class Note extends StatelessWidget {
  final String text;
  final NoteTone tone;
  const Note(this.text, {super.key, this.tone = NoteTone.yellow});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      NoteTone.yellow => (AppColors.yellowSoft, const Color(0xFF6B4A1E)),
      NoteTone.mint => (AppColors.mint, const Color(0xFF1F5E57)),
      NoteTone.pink => (AppColors.pink, AppColors.berry),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: T.sans(11, color: fg, height: 1.5)),
    );
  }
}

class ActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Color iconColor;
  final Color iconBg;
  final bool divider;
  const ActionRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.iconColor = AppColors.berry,
    this.iconBg = AppColors.peach,
    this.divider = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(border: divider ? const Border(bottom: BorderSide(color: AppColors.borderSoft)) : null),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: T.title()),
              const SizedBox(height: 2),
              Text(subtitle, style: T.small(), maxLines: 2, overflow: TextOverflow.ellipsis),
            ]),
          ),
          const Icon(Icons.north_east_rounded, size: 15, color: AppColors.berry),
        ]),
      ),
    );
  }
}

class KV extends StatelessWidget {
  final String label;
  final String value;
  final bool strong;
  final Color? color;
  final Color? valueColor;
  final double vPad;
  const KV(this.label, this.value, {super.key, this.strong = false, this.color, this.valueColor, this.vPad = 6});

  @override
  Widget build(BuildContext context) {
    final base = strong ? T.sans(15, weight: FontWeight.w700, color: color ?? AppColors.ink) : T.sans(12.5, color: color ?? AppColors.ink);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: vPad),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Text(label, style: base)),
        const SizedBox(width: 12),
        Flexible(child: Text(value, textAlign: TextAlign.end, style: base.copyWith(color: valueColor ?? color ?? AppColors.ink))),
      ]),
    );
  }
}

class DashedDivider extends StatelessWidget {
  final Color color;
  const DashedDivider({super.key, this.color = AppColors.border});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: LayoutBuilder(builder: (context, c) {
        final count = (c.maxWidth / 7).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(count, (_) => SizedBox(width: 4, height: 1.2, child: DecoratedBox(decoration: BoxDecoration(color: color)))),
        );
      }),
    );
  }
}

class StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;
  const StatCard(this.value, this.label, {super.key, this.valueColor = AppColors.berry});

  @override
  Widget build(BuildContext context) {
    return UCard(
      padding: const EdgeInsets.fromLTRB(16, 18, 12, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: T.display(32, color: valueColor))),
        const SizedBox(height: 6),
        Text(label, style: T.tiny(), maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}

class StatPair extends StatelessWidget {
  final StatCard left;
  final StatCard right;
  const StatPair(this.left, this.right, {super.key});

  @override
  Widget build(BuildContext context) => Row(children: [Expanded(child: left), const SizedBox(width: 10), Expanded(child: right)]);
}

class QtyStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  const QtyStepper({super.key, required this.value, required this.onChanged, this.min = 0, this.max = 99});

  @override
  Widget build(BuildContext context) {
    Widget btn(String s, bool enabled, VoidCallback f) => InkWell(
          onTap: enabled
              ? () {
                  HapticFeedback.selectionClick();
                  f();
                }
              : null,
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            width: 28,
            height: 32,
            child: Center(child: Text(s, style: T.sans(15, color: enabled ? AppColors.ink : AppColors.border, weight: FontWeight.w500))),
          ),
        );
    return Container(
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        btn('−', value > min, () => onChanged(value - 1)),
        SizedBox(
          width: 20,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Text('$value', key: ValueKey(value), textAlign: TextAlign.center, style: T.sans(13, weight: FontWeight.w700)),
          ),
        ),
        btn('+', value < max, () => onChanged(value + 1)),
      ]),
    );
  }
}

class Avatar extends StatelessWidget {
  final String letters;
  final double size;
  const Avatar(this.letters, {super.key, this.size = 46});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: AppColors.yellow, shape: BoxShape.circle),
      child: Text(letters, style: T.display(size * 0.5, color: AppColors.berry, weight: FontWeight.w500)),
    );
  }
}

class UProgressBar extends StatelessWidget {
  final double value;
  final Color track;
  final Color fill;
  const UProgressBar(this.value, {super.key, this.track = const Color(0x33FFFFFF), this.fill = AppColors.yellow});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(value: v, minHeight: 5, backgroundColor: track, valueColor: AlwaysStoppedAnimation(fill)),
      ),
    );
  }
}

class UnderlineTabs extends StatelessWidget {
  final List<String> tabs;
  final int index;
  final ValueChanged<int> onChanged;
  const UnderlineTabs({super.key, required this.tabs, required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
      child: Row(children: [
        for (var i = 0; i < tabs.length; i++)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: i == index ? AppColors.berry : Colors.transparent, width: 2)),
              ),
              child: Text(tabs[i], style: T.sans(12, color: i == index ? AppColors.berry : AppColors.ink, weight: i == index ? FontWeight.w600 : FontWeight.w400)),
            ),
          ),
      ]),
    );
  }
}

class ToggleCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool card;
  const ToggleCard({super.key, required this.title, this.subtitle, required this.value, required this.onChanged, this.card = true});

  @override
  Widget build(BuildContext context) {
    final row = Row(children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: T.sans(13)),
          if (subtitle != null) ...[const SizedBox(height: 6), Text(subtitle!, style: T.small())],
        ]),
      ),
      Switch.adaptive(value: value, onChanged: onChanged, activeColor: AppColors.teal),
    ]);
    return card ? UCard(child: row) : row;
  }
}

/// Space between stacked blocks.
class Gap extends StatelessWidget {
  final double size;
  const Gap(this.size, {super.key});

  @override
  Widget build(BuildContext context) => SizedBox(height: size, width: size);
}
