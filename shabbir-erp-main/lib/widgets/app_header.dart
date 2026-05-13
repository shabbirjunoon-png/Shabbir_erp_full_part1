import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppHeaderAction {
  final IconData icon;
  final VoidCallback onPress;
  final bool destructive;
  const AppHeaderAction(
      {required this.icon, required this.onPress, this.destructive = false});
}

class ShabbirLogo extends StatelessWidget {
  final double size;
  final Color bgColor;
  final Color textColor;
  final Color badgeColor;
  final bool showBadge;

  const ShabbirLogo({
    super.key,
    this.size = 36,
    this.bgColor = AppColors.primary,
    this.textColor = AppColors.accent,
    this.badgeColor = AppColors.accent,
    this.showBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _SaIconPainter(),
    );
  }
}

// Faithful recreation of the SA rounded-square logo:
// navy left half + cream right half split by a diagonal swoosh,
// gold "S" on left, navy "A" on right, bar chart top-right, gold border.
class _SaIconPainter extends CustomPainter {
  static const _navy  = AppColors.primary;        // #1E1B4B
  static const _gold  = AppColors.accent;         // #F59E0B
  static const _goldS = Color(0xFFFFD166);        // lighter gold for "S"
  static const _cream = Color(0xFFFEF9E7);        // right-half cream

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width;
    final h = s.height;
    final r = w * 0.22; // corner radius (iOS-icon style)
    final bounds = Rect.fromLTWH(0, 0, w, h);
    final rr = RRect.fromRectAndRadius(bounds, Radius.circular(r));

    // ── 1. Clip everything to the rounded rect ────────────────────────────────
    canvas.save();
    canvas.clipRRect(rr);

    // ── 2. Full navy background ───────────────────────────────────────────────
    canvas.drawRect(bounds, Paint()..color = _navy);

    // ── 3. Cream right portion via diagonal swoosh clip ───────────────────────
    // The swoosh goes from (12%, 92%) → curve control → (88%, 8%)
    final creamPath = Path()
      ..moveTo(w * 0.12, h)        // bottom anchor
      ..quadraticBezierTo(         // smooth diagonal curve
          w * 0.55, h * 0.55,     // control point (centre-right)
          w,        h * 0.0)      // end at top-right corner
      ..lineTo(w, h)               // right edge down
      ..close();
    canvas.drawPath(creamPath, Paint()..color = _cream);

    // ── 4. Small dot at swoosh start (gold) ───────────────────────────────────
    canvas.drawCircle(
      Offset(w * 0.15, h * 0.86),
      w * 0.045,
      Paint()..color = _gold,
    );

    // ── 5. Bar chart in upper-right (navy bars on cream) ─────────────────────
    final barPaint = Paint()..color = _navy;
    final barW = w * 0.065;
    final barGap = w * 0.032;
    final barBaseY = h * 0.42;
    final barHeights = [h * 0.10, h * 0.17, h * 0.26];
    for (int i = 0; i < 3; i++) {
      final bx = w * 0.62 + i * (barW + barGap);
      final bh = barHeights[i];
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(bx, barBaseY - bh, barW, bh),
          const Radius.circular(2),
        ),
        barPaint,
      );
    }

    // ── 6. "S" — large, gold, left side ──────────────────────────────────────
    final stp = TextPainter(
      text: TextSpan(
        text: 'S',
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w900,
          fontSize: w * 0.52,
          color: _goldS,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    stp.paint(canvas, Offset(w * 0.04, h * 0.28));

    // ── 7. "A" — large, navy, right side ─────────────────────────────────────
    final atp = TextPainter(
      text: TextSpan(
        text: 'A',
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w900,
          fontSize: w * 0.46,
          color: _navy,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    atp.paint(canvas, Offset(w * 0.50, h * 0.38));

    canvas.restore();

    // ── 8. Gold border (drawn outside clip so it sits on top cleanly) ─────────
    canvas.drawRRect(
      rr,
      Paint()
        ..color = _gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.055,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final List<AppHeaderAction>? actions;

  const AppHeader(
      {super.key,
      required this.title,
      this.subtitle,
      this.onBack,
      this.actions});

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 20,
          right: 20,
          bottom: 14),
      decoration: const BoxDecoration(
          border: Border(
              bottom: BorderSide(color: AppColors.border, width: 0.5))),
      child: Row(
        children: [
          if (onBack != null)
            GestureDetector(
              onTap: onBack,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 16, color: AppColors.foreground),
              ),
            )
          else
            const ShabbirLogo(size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          letterSpacing: -0.4,
                          color: AppColors.foreground),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(subtitle!,
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                            color: AppColors.mutedForeground),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ]),
          ),
          if (actions != null)
            Row(
                children: actions!
                    .map((action) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: GestureDetector(
                            onTap: action.onPress,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                  color: action.destructive
                                      ? const Color(0xFFFEE2E2)
                                      : AppColors.secondary,
                                  borderRadius: BorderRadius.circular(10)),
                              child: Icon(action.icon,
                                  size: 18,
                                  color: action.destructive
                                      ? AppColors.destructive
                                      : AppColors.foreground),
                            ),
                          ),
                        ))
                    .toList()),
        ],
      ),
    );
  }
}
