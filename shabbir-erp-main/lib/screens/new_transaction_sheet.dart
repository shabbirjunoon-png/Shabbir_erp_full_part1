import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/transaction.dart';
import '../providers/erp_provider.dart';
import '../utils/format.dart';
import '../widgets/erp_bottom_sheet.dart';

// txTypes is exported from models/transaction.dart — no redefinition needed here

class NewTransactionSheet extends StatefulWidget {
  final String? defaultPartyId;
  final Transaction? editing;

  const NewTransactionSheet({super.key, this.defaultPartyId, this.editing});

  @override
  State<NewTransactionSheet> createState() => _NewTransactionSheetState();
}

class _NewTransactionSheetState extends State<NewTransactionSheet> {
  String _type = 'Sale';
  String? _partyId;
  String? _itemId;
  final _qtyCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _amtCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  Map<String, String> _errors = {};
  bool _saving = false;

  bool get _isMoneyOnly => _type == 'Receipt' || _type == 'Payment';

  double get _total {
    if (_isMoneyOnly) return double.tryParse(_amtCtrl.text) ?? 0;
    return (double.tryParse(_qtyCtrl.text) ?? 0) * (double.tryParse(_rateCtrl.text) ?? 0);
  }

  @override
  void initState() {
    super.initState();
    _partyId = widget.defaultPartyId;
    if (widget.editing != null) {
      final e = widget.editing!;
      _type = e.type;
      _partyId = e.partyId;
      _itemId = e.itemId;
      if (e.isMoneyOnly) {
        _amtCtrl.text = e.total == 0 ? '' : e.total.toStringAsFixed(e.total.truncateToDouble() == e.total ? 0 : 2);
      } else {
        _qtyCtrl.text = e.qty == 0 ? '' : e.qty.toStringAsFixed(e.qty.truncateToDouble() == e.qty ? 0 : 2);
        _rateCtrl.text = e.rate == 0 ? '' : e.rate.toStringAsFixed(e.rate.truncateToDouble() == e.rate ? 0 : 2);
      }
      _remarksCtrl.text = e.remarks;
      _date = parseDate(e.date);
    }
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _rateCtrl.dispose();
    _amtCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final errors = <String, String>{};
    if (_partyId == null) errors['party'] = 'Select a party';
    if (!_isMoneyOnly && _itemId == null) errors['item'] = 'Select an item';
    if (!_isMoneyOnly && (double.tryParse(_qtyCtrl.text) ?? 0) <= 0) errors['qty'] = 'Enter quantity > 0';
    if (!_isMoneyOnly && (double.tryParse(_rateCtrl.text) ?? 0) <= 0) errors['rate'] = 'Enter rate > 0';
    if (_isMoneyOnly && (double.tryParse(_amtCtrl.text) ?? 0) <= 0) errors['amount'] = 'Enter amount > 0';
    setState(() => _errors = errors);
    if (errors.isNotEmpty) return;

    setState(() => _saving = true);
    final erp = context.read<ERPProvider>();
    try {
      if (widget.editing != null) {
        await erp.updateTransaction(
          widget.editing!.id,
          partyId: _partyId!,
          itemId: _isMoneyOnly ? null : _itemId,
          qty: _isMoneyOnly ? 0 : (double.tryParse(_qtyCtrl.text) ?? 0),
          rate: _isMoneyOnly ? (double.tryParse(_amtCtrl.text) ?? 0) : (double.tryParse(_rateCtrl.text) ?? 0),
          type: _type,
          remarks: _remarksCtrl.text,
          date: _date,
        );
      } else {
        await erp.addTransaction(
          partyId: _partyId!,
          itemId: _isMoneyOnly ? null : _itemId,
          qty: _isMoneyOnly ? 0 : (double.tryParse(_qtyCtrl.text) ?? 0),
          rate: _isMoneyOnly ? (double.tryParse(_amtCtrl.text) ?? 0) : (double.tryParse(_rateCtrl.text) ?? 0),
          type: _type,
          remarks: _remarksCtrl.text,
          date: _date,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final erp = context.read<ERPProvider>();
    return ERPBottomSheet(
      title: widget.editing != null ? 'Edit Voucher' : 'New Voucher',
      footer: Column(
        children: [
          // Running total preview
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_isMoneyOnly ? 'AMOUNT' : 'TOTAL AMOUNT', style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 12, letterSpacing: 0.5, color: AppColors.mutedForeground)),
                Text(formatCurrency(_total), style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20, color: AppColors.primary)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: widget.editing != null ? 'Update Voucher' : 'Save Voucher',
            icon: Icons.check,
            loading: _saving,
            onPressed: _save,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type selector
          ERPField(
            label: 'Voucher Type',
            child: Row(
              children: txTypes.asMap().entries.map((e) {
                final t = e.value;
                final active = _type == t;
                final isLast = e.key == txTypes.length - 1;
                return Expanded(child: Padding(
                  padding: EdgeInsets.only(right: isLast ? 0 : 6),
                  child: GestureDetector(
                    onTap: () => setState(() { _type = t; _errors = {}; }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: active ? AppColors.foreground : AppColors.card,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: active ? AppColors.foreground : AppColors.border),
                      ),
                      child: Center(child: Text(t, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12, color: active ? AppColors.background : AppColors.foreground))),
                    ),
                  ),
                ));
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Date picker
          ERPField(
            label: 'Date',
            child: GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2000), lastDate: DateTime(2100));
                if (picked != null) setState(() => _date = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                child: Row(children: [
                  const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.mutedForeground),
                  const SizedBox(width: 10),
                  Text(formatDateDisplay(formatDate(_date)), style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14, color: AppColors.foreground)),
                  const Spacer(),
                  Text('Tap to change', style: GoogleFonts.inter(fontSize: 11, color: AppColors.mutedForeground)),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Party
          ERPField(
            label: 'Party *',
            error: _errors['party'],
            child: _Picker(
              placeholder: 'Select a party',
              selectedLabel: erp.parties.where((p) => p.id == _partyId).firstOrNull?.name,
              options: erp.parties.map((p) => _Option(label: p.name, value: p.id, subtitle: p.type)).toList(),
              onSelect: (v) => setState(() { _partyId = v; _errors.remove('party'); }),
            ),
          ),
          const SizedBox(height: 16),

          if (!_isMoneyOnly) ...[
            ERPField(
              label: 'Item *',
              error: _errors['item'],
              child: _Picker(
                placeholder: 'Select an item from inventory',
                selectedLabel: erp.inventory.where((i) => i.id == _itemId).firstOrNull?.name,
                options: erp.inventory.map((i) => _Option(label: i.name, value: i.id, subtitle: 'In stock: ${i.currentQty} ${i.unit}')).toList(),
                onSelect: (v) => setState(() { _itemId = v; _errors.remove('item'); }),
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: ERPField(label: 'Quantity *', error: _errors['qty'], child: ERPTextInput(controller: _qtyCtrl, placeholder: '0', keyboardType: TextInputType.number))),
              const SizedBox(width: 12),
              Expanded(child: ERPField(label: 'Rate (Rs.) *', error: _errors['rate'], child: ERPTextInput(controller: _rateCtrl, placeholder: '0.00', keyboardType: TextInputType.number, prefix: 'Rs.'))),
            ]),
            const SizedBox(height: 16),
          ] else ...[
            ERPField(
              label: 'Amount (Rs.) *',
              error: _errors['amount'],
              child: ERPTextInput(controller: _amtCtrl, placeholder: '0.00', keyboardType: TextInputType.number, prefix: 'Rs.'),
            ),
            const SizedBox(height: 16),
          ],

          ERPField(label: 'Remarks (optional)', child: ERPTextInput(controller: _remarksCtrl, placeholder: 'Add a note for this entry')),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _Option {
  final String label;
  final String value;
  final String? subtitle;
  const _Option({required this.label, required this.value, this.subtitle});
}

class _Picker extends StatelessWidget {
  final String placeholder;
  final String? selectedLabel;
  final List<_Option> options;
  final void Function(String) onSelect;

  const _Picker({required this.placeholder, this.selectedLabel, required this.options, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
        child: Row(children: [
          Expanded(child: Text(selectedLabel ?? placeholder, style: GoogleFonts.inter(fontWeight: selectedLabel != null ? FontWeight.w600 : FontWeight.w400, fontSize: 14, color: selectedLabel != null ? AppColors.foreground : AppColors.mutedForeground))),
          const Icon(Icons.expand_more, size: 18, color: AppColors.mutedForeground),
        ]),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
        decoration: const BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            ),
            if (options.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text('No items available. Add some first.', style: GoogleFonts.inter(color: AppColors.mutedForeground)),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.fromLTRB(0, 0, 0, MediaQuery.of(context).padding.bottom + 16),
                  itemCount: options.length,
                  itemBuilder: (_, i) => ListTile(
                    title: Text(options[i].label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.foreground)),
                    subtitle: options[i].subtitle != null ? Text(options[i].subtitle!, style: GoogleFonts.inter(fontSize: 12, color: AppColors.mutedForeground)) : null,
                    trailing: selectedLabel == options[i].label ? const Icon(Icons.check_circle, color: AppColors.primary, size: 20) : null,
                    onTap: () { Navigator.of(context).pop(); onSelect(options[i].value); },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
