import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../models/party.dart';
import '../utils/format.dart';

class PartyCard extends StatelessWidget {
  final PartyWithBalance party;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onMenuPress;

  const PartyCard({super.key, required this.party, required this.onTap, this.onLongPress, this.onMenuPress});

  @override
  Widget build(BuildContext context) {
    final meta = balanceLabel(party.balance, party.type);
    final (:bg, :fg) = _tone(meta.tone);
    final initial = party.name.trim().isNotEmpty ? party.name.trim()[0].toUpperCase() : '?';
    final avatarColor = party.type == 'Customer' ? AppColors.primary : AppColors.supplierAvatar;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [AppColors.cardShadow],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: avatarColor, shape: BoxShape.circle),
              child: Center(
                child: Text(
                  initial,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  party.name,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    letterSpacing: -0.2,
                    color: AppColors.foreground,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(
                    party.type == 'Customer' ? Icons.person_outline : Icons.local_shipping_outlined,
                    size: 11,
                    color: AppColors.mutedForeground,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    party.type,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 11.5, color: AppColors.mutedForeground),
                  ),
                ]),
              ]),
            ),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(
                formatCurrency(party.balance.abs()),
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: AppColors.foreground,
                ),
              ),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  meta.label.toUpperCase(),
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 9.5, letterSpacing: 0.3, color: fg),
                ),
              ),
            ]),
            if (onMenuPress != null) ...[
              const SizedBox(width: 2),
              GestureDetector(
                onTap: onMenuPress,
                child: const SizedBox(width: 28, height: 28, child: Icon(Icons.more_vert, size: 16, color: AppColors.mutedForeground)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  ({Color bg, Color fg}) _tone(String tone) {
    switch (tone) {
      case 'receivable': return (bg: const Color(0xFFFEF3C7), fg: const Color(0xFFA16207));
      case 'payable': return (bg: const Color(0xFFFEE2E2), fg: const Color(0xFFB91C1C));
      case 'advance': return (bg: const Color(0xFFDCFCE7), fg: const Color(0xFF15803D));
      default: return (bg: AppColors.secondary, fg: AppColors.mutedForeground);
    }
  }
}
