import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/theme.dart';

InputDecoration _decoration({String? hint, Widget? prefix, Widget? suffix}) {
  OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: c, width: w));
  return InputDecoration(
    isDense: true,
    filled: true,
    fillColor: AppColors.surface,
    hintText: hint,
    hintStyle: T.sans(12.5, color: AppColors.muted),
    prefixIcon: prefix,
    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
    suffixIcon: suffix,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: b(AppColors.border),
    enabledBorder: b(AppColors.border),
    focusedBorder: b(AppColors.berry, 1.4),
  );
}

class FieldLabel extends StatelessWidget {
  final String text;
  const FieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 7, top: 14),
        child: Text(text, style: T.sans(11.5, color: AppColors.ink, weight: FontWeight.w500)),
      );
}

/// Labelled text input that owns its controller (prefilled with demo data).
class UField extends StatefulWidget {
  final String? label;
  final String initial;
  final String? hint;
  final TextInputType? keyboard;
  final int maxLines;
  final String? prefixText;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? formatters;
  final TextEditingController? controller;
  final bool autofocus;
  final TextInputAction? action;
  final ValueChanged<String>? onSubmitted;

  const UField({
    super.key,
    this.label,
    this.initial = '',
    this.hint,
    this.keyboard,
    this.maxLines = 1,
    this.prefixText,
    this.suffix,
    this.onChanged,
    this.formatters,
    this.controller,
    this.autofocus = false,
    this.action,
    this.onSubmitted,
  });

  @override
  State<UField> createState() => _UFieldState();
}

class _UFieldState extends State<UField> {
  late final TextEditingController _c = widget.controller ?? TextEditingController(text: widget.initial);

  @override
  void dispose() {
    if (widget.controller == null) _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: _c,
      keyboardType: widget.keyboard,
      maxLines: widget.maxLines,
      minLines: widget.maxLines > 1 ? widget.maxLines : null,
      inputFormatters: widget.formatters,
      onChanged: widget.onChanged,
      autofocus: widget.autofocus,
      textInputAction: widget.action,
      onSubmitted: widget.onSubmitted,
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      style: T.sans(13, color: AppColors.ink),
      decoration: _decoration(
        hint: widget.hint,
        suffix: widget.suffix,
        prefix: widget.prefixText == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(left: 14, right: 8),
                child: Text(widget.prefixText!, style: T.sans(13, color: AppColors.ink, weight: FontWeight.w600)),
              ),
      ),
    );
    if (widget.label == null) return field;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [FieldLabel(widget.label!), field]);
  }
}

/// Read-only "select" field – opens a sheet / date picker on tap.
class UPicker extends StatelessWidget {
  final String? label;
  final String value;
  final VoidCallback onTap;
  final IconData icon;
  const UPicker({super.key, this.label, required this.value, required this.onTap, this.icon = Icons.keyboard_arrow_down_rounded});

  @override
  Widget build(BuildContext context) {
    final box = Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: AppColors.border)),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
          child: Row(children: [
            Expanded(child: Text(value, style: T.sans(13), overflow: TextOverflow.ellipsis)),
            Icon(icon, size: 18, color: AppColors.muted),
          ]),
        ),
      ),
    );
    if (label == null) return box;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [FieldLabel(label!), box]);
  }
}

/// Search box used on Home / Collection / Search.
class USearchBox extends StatelessWidget {
  final String hint;
  final VoidCallback? onTap;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  const USearchBox({super.key, required this.hint, this.onTap, this.controller, this.onChanged, this.autofocus = false});

  @override
  Widget build(BuildContext context) {
    final readOnly = onTap != null;
    return TextField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      autofocus: autofocus,
      onChanged: onChanged,
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      textInputAction: TextInputAction.search,
      style: T.sans(13),
      decoration: _decoration(
        hint: hint,
        prefix: const Padding(
          padding: EdgeInsets.only(left: 14, right: 10),
          child: Icon(Icons.search_rounded, size: 18, color: AppColors.muted),
        ),
      ),
    );
  }
}
