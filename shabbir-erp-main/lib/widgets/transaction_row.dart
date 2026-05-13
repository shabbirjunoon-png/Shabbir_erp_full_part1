import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../models/transaction.dart';
import '../utils/format.dart';

class TransactionRow extends StatelessWidget {
  final Transaction tx;
  final String? partyName;
  final String? itemName;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onMenuPress;
  final bool showParty;

  const TransactionRow({super.key, required this.tx, this.partyName, this.itemName, this.onTap, this.onLongPress, this.onMenuPress, this.showParty = false});

  @override
  Widget build(BuildContext context) {
    final config = _txConfig(tx.type);
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
        child: Row(
          children: [
            Container(width: 38, height: 38, decoration: BoxDecoration(color: config.bgColor, borderRadius: BorderRadius.circular(10)), child: Icon(config.icon, size: 16, color: config.color)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tx.type, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.foreground)),
              const SizedBox(height: 2),
              Text(
                showParty && partyName != null ? '$partyName · ${formatDateDisplay(tx.date)}' : itemName != null ? '$itemName · ${formatDateDisplay(tx.date)}' : formatDateDisplay(tx.date),
                style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 11.5, color: AppColors.mutedForeground),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
              if (tx.remarks.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(tx.remarks, style: GoogleFonts.inter(fontWeight: FontWeight.w400, fontSize: 11, color: AppColors.mutedForeground), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(formatCurrency(tx.total), style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: config.color)),
              if (!tx.isMoneyOnly && tx.qty > 0) ...[
                const SizedBox(height: 2),
                Text('${formatNumber(tx.qty)} × ${formatCurrency(tx.rate)}', style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 10.5, color: AppColors.mutedForeground)),
              ],
            ]),
            if (onMenuPress != null) ...[
              const SizedBox(width: 4),
              GestureDetector(onTap: onMenuPress, child: const SizedBox(width: 28, height: 28, child: Icon(Icons.more_vert, size: 16, color: AppColors.mutedForeground))),
            ],
          ],
        ),
      ),
    );
  }

  ({Color color, Color bgColor, IconData icon}) _txConfig(String type) {
    switch (type) {
      case 'Sale':     return (color: const Color(0xFF0EA5E9), bgColor: const Color(0xFFE0F2FE), icon: Icons.arrow_upward);
      case 'Purchase': return (color: const Color(0xFF7C3AED), bgColor: const Color(0xFFEDE9FE), icon: Icons.arrow_downward);
      case 'Receipt':  return (color: AppColors.success, bgColor: const Color(0xFFDCFCE7), icon: Icons.south_west);
      case 'Payment':  return (color: AppColors.destructive, bgColor: const Color(0xFFFEE2E2), icon: Icons.north_east);
      default:         return (color: AppColors.mutedForeground, bgColor: AppColors.muted, icon: Icons.receipt_long_outlined);
    }
  }
}
