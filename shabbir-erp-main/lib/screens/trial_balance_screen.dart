import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/party.dart';
import '../providers/erp_provider.dart';
import '../utils/format.dart';
import '../widgets/app_header.dart';
import '../services/pdf_service.dart';

class TrialBalanceScreen extends StatefulWidget {
  const TrialBalanceScreen({super.key});

  @override
  State<TrialBalanceScreen> createState() => _TrialBalanceScreenState();
}

class _TrialBalanceScreenState extends State<TrialBalanceScreen> {
  bool _exporting = false;
  String _sort = 'name'; // 'name' | 'balance' | 'type'

  Future<void> _exportPdf(BuildContext context, ERPProvider erp) async {
    setState(() => _exporting = true);
    try {
      await PdfService.generateTrialBalance(
        partiesWithBalance: erp.partiesWithBalance,
        totalReceivable: erp.totalReceivable,
        totalPayable: erp.totalPayable,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Export failed: $e', style: GoogleFonts.inter()),
          backgroundColor: AppColors.destructive,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  List<PartyWithBalance> _sorted(List<PartyWithBalance> list) {
    final copy = List<PartyWithBalance>.from(list);
    switch (_sort) {
      case 'balance':
        copy.sort((a, b) => b.balance.abs().compareTo(a.balance.abs()));
      case 'type':
        copy.sort((a, b) => a.type.compareTo(b.type));
      default:
        copy.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
    return copy;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ERPProvider>(
      builder: (context, erp, _) {
        final sorted = _sorted(erp.partiesWithBalance);
        final grandTotal = erp.totalReceivable - erp.totalPayable;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              AppHeader(
                title: 'Trial Balance',
                subtitle: '${sorted.length} parties',
                onBack: () => Navigator.of(context).pop(),
                actions: [
                  AppHeaderAction(
                    icon: _exporting ? Icons.hourglass_empty : Icons.picture_as_pdf_outlined,
                    onPress: () => _exportPdf(context, erp),
                  ),
                ],
              ),

              // ── Summary strip ─────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(color: AppColors.primary),
                child: Row(
                  children: [
                    _SummaryPill(label: 'Receivable', value: erp.totalReceivable, color: AppColors.accent),
                    _divider(),
                    _SummaryPill(label: 'Payable', value: erp.totalPayable, color: const Color(0xFFFCA5A5)),
                    _divider(),
                    _SummaryPill(
                      label: 'Net',
                      value: grandTotal.abs(),
                      color: grandTotal >= 0 ? AppColors.accent : const Color(0xFFFCA5A5),
                    ),
                  ],
                ),
              ),

              // ── Sort bar ──────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: AppColors.muted, border: const Border(bottom: BorderSide(color: AppColors.border, width: 0.5))),
                child: Row(
                  children: [
                    Text('Sort by:', style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 12, color: AppColors.mutedForeground)),
                    const SizedBox(width: 8),
                    ...[('Name', 'name'), ('Balance', 'balance'), ('Type', 'type')].map((s) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: () => setState(() => _sort = s.$2),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _sort == s.$2 ? AppColors.primary : AppColors.card,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _sort == s.$2 ? AppColors.primary : AppColors.border),
                          ),
                          child: Text(s.$1, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 11.5, color: _sort == s.$2 ? Colors.white : AppColors.foreground)),
                        ),
                      ),
                    )),
                  ],
                ),
              ),

              // ── Column headers ────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                color: AppColors.muted,
                child: Row(children: [
                  const SizedBox(width: 40),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Party', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 11.5, color: AppColors.mutedForeground))),
                  Text('Balance', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 11.5, color: AppColors.mutedForeground)),
                  const SizedBox(width: 8),
                  SizedBox(width: 72, child: Text('Status', textAlign: TextAlign.center, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 11.5, color: AppColors.mutedForeground))),
                ]),
              ),

              // ── Party rows ────────────────────────────────────────────
              Expanded(
                child: sorted.isEmpty
                    ? Center(
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.account_balance_outlined, size: 48, color: AppColors.mutedForeground),
                          const SizedBox(height: 12),
                          Text('No parties yet', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.foreground)),
                          const SizedBox(height: 6),
                          Text('Add parties from the Parties tab.', style: GoogleFonts.inter(fontSize: 13, color: AppColors.mutedForeground)),
                        ]),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: sorted.length,
                        separatorBuilder: (_, __) => const Divider(color: AppColors.border, height: 1, indent: 20, endIndent: 20),
                        itemBuilder: (_, i) => _PartyRow(party: sorted[i], isEven: i % 2 == 0),
                      ),
              ),

              // ── Grand Total footer ─────────────────────────────────────
              Container(
                padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  border: Border(top: BorderSide(color: Colors.white24)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('GRAND TOTAL', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 11, letterSpacing: 0.5, color: Colors.white60)),
                          const SizedBox(height: 2),
                          Text(
                            '${sorted.length} parties  •  Net ${grandTotal >= 0 ? "Receivable" : "Payable"}',
                            style: GoogleFonts.inter(fontSize: 11.5, color: Colors.white54),
                          ),
                        ]),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text(
                            formatCurrency(grandTotal.abs()),
                            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 24, color: grandTotal >= 0 ? AppColors.accent : const Color(0xFFFCA5A5)),
                          ),
                          Text(
                            grandTotal >= 0 ? 'Net in your favour' : 'Net against you',
                            style: GoogleFonts.inter(fontSize: 11, color: Colors.white60),
                          ),
                        ]),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _exporting ? null : () => _exportPdf(context, erp),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _exporting ? Colors.white24 : AppColors.accent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_exporting ? Icons.hourglass_empty : Icons.picture_as_pdf_outlined, size: 16, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(_exporting ? 'Generating PDF...' : 'Export Trial Balance PDF', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.primary)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _divider() => Container(width: 1, height: 32, color: Colors.white.withOpacity(0.15), margin: const EdgeInsets.symmetric(horizontal: 12));
}

class _SummaryPill extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _SummaryPill({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Column(children: [
      Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 10, color: Colors.white60, letterSpacing: 0.3)),
      const SizedBox(height: 2),
      FittedBox(
        child: Text(formatCurrency(value), style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: color)),
      ),
    ]));
  }
}

class _PartyRow extends StatelessWidget {
  final PartyWithBalance party;
  final bool isEven;

  const _PartyRow({required this.party, required this.isEven});

  @override
  Widget build(BuildContext context) {
    final meta = balanceLabel(party.balance, party.type);
    final (:bg, :fg) = _tone(meta.tone);
    final initial = party.name.isNotEmpty ? party.name[0].toUpperCase() : '?';
    final avatarColor = party.type == 'Customer' ? AppColors.primary : AppColors.supplierAvatar;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      color: isEven ? AppColors.background : AppColors.card,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: avatarColor, shape: BoxShape.circle),
            child: Center(child: Text(initial, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(party.name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.foreground), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(party.type, style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 11.5, color: AppColors.mutedForeground)),
            ]),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(
              formatCurrency(party.balance.abs()),
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.foreground),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
              child: Text(meta.label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 10, color: fg, letterSpacing: 0.3)),
            ),
          ]),
        ],
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
