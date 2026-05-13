import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/stock_item.dart';
import '../providers/erp_provider.dart';
import '../utils/format.dart';
import '../widgets/app_header.dart';
import '../widgets/erp_bottom_sheet.dart';
import '../widgets/item_card.dart';
import 'add_item_sheet.dart';
import 'new_transaction_sheet.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _query = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<StockItem> _filtered(List<StockItem> items) {
    if (_query.isEmpty) return items;
    return items.where((i) => i.name.toLowerCase().contains(_query.toLowerCase())).toList();
  }

  void _showMenu(BuildContext context, StockItem item, ERPProvider erp) {
    showActionMenu(context,
      title: item.name,
      subtitle: 'Unit: ${item.unit}',
      items: [
        ActionMenuItem(icon: Icons.edit_outlined, label: 'Edit / Rename', onPress: () => _showEditItem(context, item)),
        ActionMenuItem(
          icon: Icons.delete_outline,
          label: 'Delete Item',
          destructive: true,
          onPress: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                title: Text('Delete item?', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                content: Text('${item.name} will be removed from inventory.', style: GoogleFonts.inter()),
                actions: [
                  TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('Cancel', style: GoogleFonts.inter())),
                  TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text('Delete', style: GoogleFonts.inter(color: AppColors.destructive, fontWeight: FontWeight.w600))),
                ],
              ),
            ) ?? false;
            if (ok) await erp.deleteItem(item.id);
          },
        ),
      ],
    );
  }

  void _showEditItem(BuildContext context, StockItem item) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => AddItemSheet(editing: item));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ERPProvider>(
      builder: (context, erp, _) {
        final filtered = _filtered(erp.inventory);
        final lowStock = erp.inventory.where((i) => i.currentQty <= 0).length;
        final totalUnits = erp.inventory.fold(0.0, (s, i) => s + i.currentQty);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              AppHeader(
                title: 'Inventory',
                subtitle: '${erp.inventory.length} items in catalog',
                actions: [AppHeaderAction(icon: Icons.add, onPress: () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => const AddItemSheet()))],
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                  children: [
                    Row(children: [
                      Expanded(child: _StatCard(icon: Icons.layers_outlined, iconBg: AppColors.secondary, iconColor: AppColors.primary, value: formatNumber(totalUnits), label: 'Total Units')),
                      const SizedBox(width: 12),
                      Expanded(child: _StatCard(icon: Icons.warning_amber_outlined, iconBg: lowStock > 0 ? const Color(0xFFFEE2E2) : AppColors.secondary, iconColor: lowStock > 0 ? AppColors.destructive : AppColors.primary, value: lowStock.toString(), label: 'Out of Stock')),
                    ]),
                    const SizedBox(height: 14),
                    _SearchBar(controller: _searchController, onChanged: (v) => setState(() => _query = v), placeholder: 'Search inventory'),
                    const SizedBox(height: 14),
                    if (filtered.isEmpty)
                      _EmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: _query.isNotEmpty ? 'No matches' : 'No items yet',
                        desc: _query.isNotEmpty ? 'Try a different search term.' : 'Add your first stock item to start tracking quantities.',
                      )
                    else
                      ...filtered.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ItemCard(
                          item: item,
                          onTap: () => _showEditItem(context, item),
                          onLongPress: () => _showMenu(context, item, erp),
                          onMenuPress: () => _showMenu(context, item, erp),
                        ),
                      )),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => const NewTransactionSheet()),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.receipt_long_outlined, size: 18),
            label: Text('New Voucher', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String value;
  final String label;

  const _StatCard({required this.icon, required this.iconBg, required this.iconColor, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border), boxShadow: [AppColors.cardShadow]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 16, color: iconColor)),
        const SizedBox(height: 8),
        Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 22, letterSpacing: -0.5, color: AppColors.foreground)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 12, color: AppColors.mutedForeground)),
      ]),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String placeholder;

  const _SearchBar({required this.controller, required this.onChanged, required this.placeholder});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Row(children: [
        const SizedBox(width: 14),
        const Icon(Icons.search, size: 16, color: AppColors.mutedForeground),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14, color: AppColors.foreground),
            decoration: InputDecoration(hintText: placeholder, hintStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14, color: AppColors.mutedForeground), border: InputBorder.none, contentPadding: EdgeInsets.zero, isDense: true),
          ),
        ),
        if (controller.text.isNotEmpty)
          GestureDetector(onTap: () { controller.clear(); onChanged(''); }, child: const Padding(padding: EdgeInsets.only(right: 14), child: Icon(Icons.cancel_outlined, size: 16, color: AppColors.mutedForeground))),
      ]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;

  const _EmptyState({required this.icon, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(children: [
        Container(width: 64, height: 64, decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(18)), child: Icon(icon, size: 28, color: AppColors.primary)),
        const SizedBox(height: 16),
        Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.foreground)),
        const SizedBox(height: 8),
        Text(desc, textAlign: TextAlign.center, style: GoogleFonts.inter(fontWeight: FontWeight.w400, fontSize: 13, color: AppColors.mutedForeground, height: 1.5)),
      ]),
    );
  }
}
