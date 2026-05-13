import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/party.dart';
import '../providers/erp_provider.dart';
import '../widgets/erp_bottom_sheet.dart';

class AddPartySheet extends StatefulWidget {
  final Party? editing;
  const AddPartySheet({super.key, this.editing});

  @override
  State<AddPartySheet> createState() => _AddPartySheetState();
}

class _AddPartySheetState extends State<AddPartySheet> {
  final _nameCtrl = TextEditingController();
  final _balCtrl = TextEditingController();
  String _type = 'Customer';
  bool _saving = false;
  Map<String, String> _errors = {};

  @override
  void initState() {
    super.initState();
    if (widget.editing != null) {
      _nameCtrl.text = widget.editing!.name;
      _balCtrl.text = widget.editing!.openingBal != 0 ? widget.editing!.openingBal.toStringAsFixed(widget.editing!.openingBal.truncateToDouble() == widget.editing!.openingBal ? 0 : 2) : '';
      _type = widget.editing!.type;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final errors = <String, String>{};
    if (_nameCtrl.text.trim().isEmpty) errors['name'] = 'Enter a name';
    setState(() => _errors = errors);
    if (errors.isNotEmpty) return;
    setState(() => _saving = true);
    final erp = context.read<ERPProvider>();
    final bal = double.tryParse(_balCtrl.text) ?? 0;
    try {
      if (widget.editing != null) {
        await erp.updateParty(widget.editing!.id, name: _nameCtrl.text, type: _type, openingBal: bal);
      } else {
        await erp.addParty(name: _nameCtrl.text, type: _type, openingBal: bal);
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ERPBottomSheet(
      title: widget.editing != null ? 'Edit Party' : 'Add Party',
      footer: PrimaryButton(label: widget.editing != null ? 'Save Changes' : 'Add Party', icon: Icons.check, loading: _saving, onPressed: _save),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ERPField(label: 'Party Name *', error: _errors['name'], child: ERPTextInput(controller: _nameCtrl, placeholder: 'Full name or business name')),
          const SizedBox(height: 16),
          ERPField(
            label: 'Party Type',
            child: Row(children: ['Customer', 'Supplier'].asMap().entries.map((e) {
              final t = e.value;
              final active = _type == t;
              return Expanded(child: Padding(
                padding: EdgeInsets.only(right: e.key == 0 ? 8 : 0),
                child: GestureDetector(
                  onTap: () => setState(() => _type = t),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: active ? AppColors.foreground : AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: active ? AppColors.foreground : AppColors.border),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(t == 'Customer' ? Icons.person_outline : Icons.local_shipping_outlined, size: 16, color: active ? AppColors.background : AppColors.foreground),
                      const SizedBox(width: 6),
                      Text(t, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: active ? AppColors.background : AppColors.foreground)),
                    ]),
                  ),
                ),
              ));
            }).toList()),
          ),
          const SizedBox(height: 16),
          ERPField(
            label: 'Opening Balance (optional)',
            child: ERPTextInput(controller: _balCtrl, placeholder: '0.00', keyboardType: TextInputType.number, prefix: 'Rs.'),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('Enter a positive amount for existing balances. Leave blank for zero.', style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.mutedForeground)),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
