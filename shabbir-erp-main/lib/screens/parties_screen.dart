import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/party.dart';
import '../providers/erp_provider.dart';
import '../services/locale_service.dart';
import '../utils/format.dart';
import '../widgets/app_header.dart';
import '../widgets/erp_bottom_sheet.dart';
import '../widgets/party_card.dart';
import 'party_detail_screen.dart';
import 'add_party_sheet.dart';
import 'new_transaction_sheet.dart';

class PartiesScreen extends StatefulWidget {
  const PartiesScreen({super.key});

  @override
  State<PartiesScreen> createState() => _PartiesScreenState();
}

class _PartiesScreenState extends State<PartiesScreen> {
  String _query = '';
  String _filter = 'All';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PartyWithBalance> _filtered(List<PartyWithBalance> parties) {
    return parties.where((p) {
      if (_filter != 'All' && p.type != _filter) return false;
      if (_query.isNotEmpty && !p.name.toLowerCase().contains(_query.toLowerCase())) return false;
      return true;
    }).toList();
  }

  void _showAddParty(BuildContext context, [Party? editing]) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => AddPartySheet(editing: editing));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ERPProvider>(
      builder: (context, erp, _) {
        final filtered = _filtered(erp.partiesWithBalance);
        return Scaffold(
          backgroundColor: AppColors.background,
          body: Builder(builder: (context) {
            final locale = context.watch<LocaleService>();
            return Column(
            children: [
              AppHeader(
                title: 'Shabbir Ledger',
                subtitle: locale.t3('Parties & balances', 'Parties & balances', 'پارٹیاں اور بیلنس'),
                actions: [AppHeaderAction(icon: Icons.add, onPress: () => _showAddParty(context))],
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                  children: [
                    Row(children: [
                      Expanded(child: _SummaryCard(label: locale.t3('Total Receivable', 'Total Receivable', 'کل وصولی'), value: formatCurrency(erp.totalReceivable), primary: true, foot: locale.t3('From customers', 'From customers', 'گاہکوں سے'), footIsPositive: true)),
                      const SizedBox(width: 12),
                      Expanded(child: _SummaryCard(label: locale.t3('Total Payable', 'Total Payable', 'کل ادائیگی'), value: formatCurrency(erp.totalPayable), primary: false, foot: locale.t3('To suppliers', 'To suppliers', 'سپلائرز کو'), footIsPositive: false)),
                    ]),
                    const SizedBox(height: 14),
                    _SearchBar(controller: _searchController, onChanged: (v) => setState(() => _query = v), placeholder: locale.t3('Search parties', 'Search parties', 'پارٹی تلاش کریں')),
                    const SizedBox(height: 12),
                    Row(
                      children: ['All', 'Customer', 'Supplier'].map((f) {
                        final active = _filter == f;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _filter = f),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(color: active ? AppColors.foreground : AppColors.card, borderRadius: BorderRadius.circular(999), border: Border.all(color: active ? AppColors.foreground : AppColors.border)),
                              child: Text(f, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12.5, color: active ? AppColors.background : AppColors.foreground)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    if (filtered.isEmpty)
                      _EmptyState(
                        icon: Icons.people_outline,
                        title: _query.isNotEmpty ? 'No matches' : 'No parties yet',
                        desc: _query.isNotEmpty ? 'Try a different search term.' : 'Add your first customer or supplier to start tracking ledgers.',
                      )
                    else
                      ...filtered.map((party) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: PartyCard(
                          party: party,
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PartyDetailScreen(partyId: party.id))),
                          onLongPress: () => _showMenu(context, party, erp),
                          onMenuPress: () => _showMenu(context, party, erp),
                        ),
                      )),
                  ],
                ),
              ),
            ],
          );
          }),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => const NewTransactionSheet()),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.receipt_long_outlined, size: 18),
            label: Builder(builder: (context) {
              final locale = context.watch<LocaleService>();
              return Text(locale.t3('New Voucher', 'New Voucher', 'نیا واؤچر'), style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14));
            }),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      },
    );
  }

  void _showMenu(BuildContext context, PartyWithBalance party, ERPProvider erp) {
    showActionMenu(context,
      title: party.name,
      subtitle: party.type,
      items: [
        ActionMenuItem(icon: Icons.edit_outlined, label: 'Edit / Rename', onPress: () => _showAddParty(context, party)),
        ActionMenuItem(
          icon: Icons.delete_outline,
          label: 'Delete Party',
          destructive: true,
          onPress: () async {
            final ok = await _confirm(context, 'Delete party?', '${party.name} and all related vouchers will be removed.', 'Delete');
            if (ok) await erp.deleteParty(party.id);
          },
        ),
      ],
    );
  }

  Future<bool> _confirm(BuildContext context, String title, String message, String confirmLabel) async {
    return await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(message, style: GoogleFonts.inter()),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('Cancel', style: GoogleFonts.inter())),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(confirmLabel, style: GoogleFonts.inter(color: AppColors.destructive, fontWeight: FontWeight.w600))),
        ],
      ),
    ) ?? false;
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final bool primary;
  final String foot;
  final bool footIsPositive;

  const _SummaryCard({required this.label, required this.value, required this.primary, required this.foot, required this.footIsPositive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: primary ? AppColors.primary : AppColors.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: primary ? AppColors.primary : AppColors.border), boxShadow: [AppColors.cardShadow]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label.toUpperCase(), style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 11, letterSpacing: 0.5, color: primary ? Colors.white70 : AppColors.mutedForeground)),
        const SizedBox(height: 6),
        Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20, letterSpacing: -0.5, color: primary ? Colors.white : AppColors.foreground)),
        const SizedBox(height: 6),
        Row(children: [
          Icon(footIsPositive ? Icons.trending_up : Icons.trending_down, size: 12, color: footIsPositive ? AppColors.accent : AppColors.destructive),
          const SizedBox(width: 4),
          Text(foot, style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 11.5, color: footIsPositive ? AppColors.accent : AppColors.destructive)),
        ]),
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
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14, color: AppColors.mutedForeground),
              border: InputBorder.none, contentPadding: EdgeInsets.zero, isDense: true,
            ),
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
