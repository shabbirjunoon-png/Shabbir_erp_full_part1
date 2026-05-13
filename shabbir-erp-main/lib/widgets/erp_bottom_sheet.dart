import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class ERPBottomSheet extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? footer;
  final bool scrollable;

  const ERPBottomSheet({super.key, required this.title, required this.child, this.footer, this.scrollable = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Row(children: [
              Expanded(child: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: -0.3, color: AppColors.foreground))),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(color: AppColors.muted, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.close, size: 16, color: AppColors.mutedForeground),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.border, height: 1),
          if (scrollable)
            Flexible(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 0), child: child))
          else
            Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 0), child: child),
          if (footer != null) ...[
            const Divider(color: AppColors.border, height: 1),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
              child: footer,
            ),
          ] else
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 24),
        ],
      ),
    );
  }
}

Future<T?> showERPSheet<T>({required BuildContext context, required String title, required Widget child, Widget? footer}) {
  return showModalBottomSheet<T>(
    context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
    builder: (_) => ERPBottomSheet(title: title, footer: footer, child: child),
  );
}

class ERPField extends StatelessWidget {
  final String label;
  final String? error;
  final Widget child;

  const ERPField({super.key, required this.label, this.error, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12.5, color: AppColors.foreground, letterSpacing: 0.1)),
      const SizedBox(height: 6),
      child,
      if (error != null) ...[
        const SizedBox(height: 4),
        Text(error!, style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.destructive)),
      ],
    ]);
  }
}

class ERPTextInput extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final TextInputType? keyboardType;
  final String? prefix;
  final bool enabled;

  const ERPTextInput({super.key, required this.controller, this.placeholder = '', this.keyboardType, this.prefix, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: enabled ? AppColors.card : AppColors.muted, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Row(children: [
        if (prefix != null)
          Padding(padding: const EdgeInsets.only(left: 14), child: Text(prefix!, style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14, color: AppColors.mutedForeground))),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            enabled: enabled,
            style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14, color: AppColors.foreground),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: GoogleFonts.inter(fontWeight: FontWeight.w400, fontSize: 14, color: AppColors.mutedForeground),
              border: InputBorder.none,
              contentPadding: EdgeInsets.fromLTRB(prefix != null ? 8 : 14, 12, 14, 12),
            ),
          ),
        ),
      ]),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final Color? color;

  const PrimaryButton({super.key, required this.label, this.onPressed, this.loading = false, this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity, height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: loading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
                Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15)),
              ]),
      ),
    );
  }
}

class ActionMenu extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final List<ActionMenuItem> items;

  const ActionMenu({super.key, this.title, this.subtitle, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(0, 0, 0, MediaQuery.of(context).padding.bottom + 16),
      decoration: const BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(padding: const EdgeInsets.only(top: 12, bottom: 8), child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title!, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.foreground)),
                if (subtitle != null) Text(subtitle!, style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 12, color: AppColors.mutedForeground)),
                const SizedBox(height: 8),
                const Divider(color: AppColors.border, height: 1),
              ]),
            ),
          ...items.map((item) => ListTile(
            leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: item.destructive ? const Color(0xFFFEE2E2) : AppColors.secondary, borderRadius: BorderRadius.circular(10)), child: Icon(item.icon, size: 16, color: item.destructive ? AppColors.destructive : AppColors.foreground)),
            title: Text(item.label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: item.destructive ? AppColors.destructive : AppColors.foreground)),
            onTap: () { Navigator.of(context).pop(); item.onPress(); },
          )),
        ],
      ),
    );
  }
}

class ActionMenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onPress;
  final bool destructive;
  const ActionMenuItem({required this.icon, required this.label, required this.onPress, this.destructive = false});
}

void showActionMenu(BuildContext context, {String? title, String? subtitle, required List<ActionMenuItem> items}) {
  showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (_) => ActionMenu(title: title, subtitle: subtitle, items: items));
}
