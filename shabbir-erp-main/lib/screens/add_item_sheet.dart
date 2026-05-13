import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/stock_item.dart';
import '../providers/erp_provider.dart';
import '../widgets/erp_bottom_sheet.dart';

class AddItemSheet extends StatefulWidget {
  final StockItem? editing;
  const AddItemSheet({super.key, this.editing});

  @override
  State<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<AddItemSheet> {
  final _nameCtrl = TextEditingController();
  final _unitCtrl = TextEditingController(text: 'Pcs');
  final _qtyCtrl = TextEditingController();
  bool _saving = false;
  Map<String, String> _errors = {};

  static const List<String> _commonUnits = ['Pcs', 'Kg', 'Ltr', 'Meter', 'Box', 'Bag', 'Dozen', 'Ton'];

  @override
  void initState() {
    super.initState();
    if (widget.editing != null) {
      _nameCtrl.text = widget.editing!.name;
      _unitCtrl.text = widget.editing!.unit;
      _qtyCtrl.text = widget.editing!.currentQty.toStringAsFixed(widget.editing!.currentQty.truncateToDouble() == widget.editing!.currentQty ? 0 : 2);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _unitCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final errors = <String, String>{};
    if (_nameCtrl.text.trim().isEmpty) errors['name'] = 'Enter an item name';
    if (_unitCtrl.text.trim().isEmpty) errors['unit'] = 'Enter a unit (e.g. Pcs, Kg)';
    setState(() => _errors = errors);
    if (errors.isNotEmpty) return;
    setState(() => _saving = true);
    final erp = context.read<ERPProvider>();
    final qty = double.tryParse(_qtyCtrl.text) ?? 0;
    try {
      if (widget.editing != null) {
        await erp.updateItem(widget.editing!.id, name: _nameCtrl.text, unit: _unitCtrl.text, currentQty: qty);
      } else {
        await erp.addItem(name: _nameCtrl.text, unit: _unitCtrl.text, openingQty: qty);
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ERPBottomSheet(
      title: widget.editing != null ? 'Edit Item' : 'Add Stock Item',
      footer: PrimaryButton(label: widget.editing != null ? 'Save Changes' : 'Add Item', icon: Icons.check, loading: _saving, onPressed: _save),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ERPField(label: 'Item Name *', error: _errors['name'], child: ERPTextInput(controller: _nameCtrl, placeholder: 'e.g. Cement Bag, Rice 50Kg')),
          const SizedBox(height: 16),
          ERPField(label: 'Unit *', error: _errors['unit'], child: ERPTextInput(controller: _unitCtrl, placeholder: 'Pcs, Kg, Ltr...')),
          const SizedBox(height: 8),
          // Quick unit selector
          Wrap(
            spacing: 6, runSpacing: 6,
            children: _commonUnits.map((u) => GestureDetector(
              onTap: () => setState(() => _unitCtrl.text = u),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _unitCtrl.text == u ? AppColors.primary : AppColors.secondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(u, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12, color: _unitCtrl.text == u ? Colors.white : AppColors.primary)),
              ),
            )).toList(),
          ),
          const SizedBox(height: 16),
          ERPField(
            label: widget.editing != null ? 'Current Quantity' : 'Opening Quantity',
            child: ERPTextInput(controller: _qtyCtrl, placeholder: '0', keyboardType: TextInputType.number),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
