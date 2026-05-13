import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../models/stock_item.dart';
import '../utils/format.dart';

class ItemCard extends StatelessWidget {
  final StockItem item;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onMenuPress;

  const ItemCard({super.key, required this.item, required this.onTap, this.onLongPress, this.onMenuPress});

  @override
  Widget build(BuildContext context) {
    final isLow = item.currentQty <= 0;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border), boxShadow: [AppColors.cardShadow]),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: isLow ? const Color(0xFFFEE2E2) : AppColors.secondary, borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.inventory_2_outlined, size: 20, color: isLow ? AppColors.destructive : AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15.5, letterSpacing: -0.2, color: AppColors.foreground), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text('Unit: ${item.unit}', style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 12, color: AppColors.mutedForeground)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(formatNumber(item.currentQty), style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20, color: AppColors.foreground)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: isLow ? const Color(0xFFFEE2E2) : AppColors.secondary, borderRadius: BorderRadius.circular(8)),
                child: Text(isLow ? 'OUT OF STOCK' : item.unit.toUpperCase(), style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 10, letterSpacing: 0.3, color: isLow ? AppColors.destructive : AppColors.secondaryForeground)),
              ),
            ]),
            if (onMenuPress != null) ...[
              const SizedBox(width: 4),
              GestureDetector(onTap: onMenuPress, child: const SizedBox(width: 32, height: 32, child: Icon(Icons.more_vert, size: 18, color: AppColors.mutedForeground))),
            ],
          ],
        ),
      ),
    );
  }
}
