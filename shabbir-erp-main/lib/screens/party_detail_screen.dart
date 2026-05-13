import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/transaction.dart';
import '../providers/erp_provider.dart';
import '../services/pdf_service.dart';
import '../utils/format.dart';
import '../widgets/app_header.dart';
import '../widgets/erp_bottom_sheet.dart';
import '../widgets/transaction_row.dart';
import 'add_party_sheet.dart';
import 'new_transaction_sheet.dart';
import 'pdf_preview_screen.dart';

class PartyDetailScreen extends StatefulWidget {
  final String partyId;
  const PartyDetailScreen({super.key, required this.partyId});

  @override
  State<PartyDetailScreen> createState() => _PartyDetailScreenState();
}

class _PartyDetailScreenState extends State<PartyDetailScreen> {
  late DateTime _startDate;
  late DateTime _endDate;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _endDate = now;
    _startDate = now.subtract(const Duration(days: 30));
  }

  List<Transaction> _filtered(List<Transaction> txs) {
    final s = DateTime(_startDate.year, _startDate.month, _startDate.day);
    final e = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);
    return txs.where((tx) {
      final d = parseDate(tx.date);
      return !d.isBefore(s) && !d.isAfter(e);
    }).toList();
  }

  double _openingBefore(List<Transaction> allTxs, double openingBal) {
    final cutoff = DateTime(_startDate.year, _startDate.month, _startDate.day);
    double bal = openingBal;
    for (final tx in allTxs) {
      if (!parseDate(tx.date).isBefore(cutoff)) continue;
      if (tx.type == 'Sale') bal += tx.total;
      else if (tx.type == 'Receipt') bal -= tx.total;
      else if (tx.type == 'Purchase') bal -= tx.total;
      else if (tx.type == 'Payment') bal += tx.total;
    }
    return bal;
  }

  double _periodNet(List<Transaction> filtered) {
    double bal = 0;
    for (final tx in filtered) {
      if (tx.type == 'Sale') bal += tx.total;
      else if (tx.type == 'Receipt') bal -= tx.total;
      else if (tx.type == 'Purchase') bal -= tx.total;
      else if (tx.type == 'Payment') bal += tx.total;
    }
    return bal;
  }

  Future<void> _showExportDialog(BuildContext context, ERPProvider erp) async {
    final party = erp.getPartyById(widget.partyId);
    if (party == null) return;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.card,
        title: Text('Export Ledger', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.foreground)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Choose how to export the ledger for ${party.name}', style: GoogleFonts.inter(fontSize: 13, color: AppColors.mutedForeground, height: 1.5)),
            const SizedBox(height: 20),
            _ExportOption(
              icon: Icons.visibility_outlined,
              color: AppColors.primary,
              bgColor: AppColors.secondary,
              title: 'Preview',
              subtitle: 'View the PDF before downloading',
              onTap: () async {
                Navigator.of(context).pop();
                await _previewPdf(context, erp);
              },
            ),
            const SizedBox(height: 10),
            _ExportOption(
              icon: Icons.download_rounded,
              color: AppColors.success,
              bgColor: const Color(0xFFDCFCE7),
              title: 'Download',
              subtitle: 'Save PDF directly to your device',
              onTap: () async {
                Navigator.of(context).pop();
                await _exportPdf(context, erp);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.mutedForeground)),
          ),
        ],
      ),
    );
  }

  Future<void> _previewPdf(BuildContext context, ERPProvider erp) async {
    final party = erp.getPartyById(widget.partyId);
    if (party == null) return;
    setState(() => _exporting = true);
    try {
      final allTxs = erp.getPartyTransactions(widget.partyId);
      final filtered = _filtered(allTxs)..sort((a, b) => parseDate(a.date).compareTo(parseDate(b.date)));
      final opening = _openingBefore(allTxs, party.openingBal);
      final bytes = await PdfService.buildLedgerBytes(
        party: party,
        transactions: filtered,
        startDate: _startDate,
        endDate: _endDate,
        openingBefore: opening,
        itemNameById: (id) => erp.getItemById(id ?? '')?.name ?? '',
      );
      final safeName = party.name.replaceAll(' ', '_');
      if (context.mounted) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => PdfPreviewScreen(pdfBytes: bytes, filename: 'ledger_$safeName.pdf'),
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Preview failed: $e', style: GoogleFonts.inter()),
          backgroundColor: AppColors.destructive,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _exportPdf(BuildContext context, ERPProvider erp) async {
    final party = erp.getPartyById(widget.partyId);
    if (party == null) return;
    setState(() => _exporting = true);
    try {
      final allTxs = erp.getPartyTransactions(widget.partyId);
      final filtered = _filtered(allTxs)..sort((a, b) => parseDate(a.date).compareTo(parseDate(b.date)));
      final opening = _openingBefore(allTxs, party.openingBal);
      await PdfService.generateLedger(
        party: party,
        transactions: filtered,
        startDate: _startDate,
        endDate: _endDate,
        openingBefore: opening,
        itemNameById: (id) => erp.getItemById(id ?? '')?.name ?? '',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('PDF downloaded!', style: GoogleFonts.inter()),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
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

  @override
  Widget build(BuildContext context) {
    return Consumer<ERPProvider>(
      builder: (context, erp, _) {
        final party = erp.getPartyById(widget.partyId);
        if (party == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(leading: IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => Navigator.of(context).pop())),
            body: const Center(child: Text('Party not found')),
          );
        }

        final allTxs = erp.getPartyTransactions(widget.partyId);
        final filtered = _filtered(allTxs);
        final opening = _openingBefore(allTxs, party.openingBal);
        final net = _periodNet(filtered);
        final closing = opening + net;
        final meta = balanceLabel(closing, party.type);
        final toneColor = () {
          switch (meta.tone) {
            case 'receivable': return AppColors.accent;
            case 'payable': return const Color(0xFFFCA5A5);
            case 'advance': return const Color(0xFF86EFAC);
            default: return Colors.white70;
          }
        }();

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              AppHeader(
                title: party.name,
                subtitle: party.type,
                onBack: () => Navigator.of(context).pop(),
                actions: [
                  AppHeaderAction(icon: Icons.edit_outlined, onPress: () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => AddPartySheet(editing: party))),
                  AppHeaderAction(icon: _exporting ? Icons.hourglass_empty : Icons.ios_share_outlined, onPress: () => _showExportDialog(context, erp)),
                  AppHeaderAction(icon: Icons.delete_outline, onPress: () => _deleteParty(context, erp), destructive: true),
                ],
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${meta.label.toUpperCase()} BALANCE', style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 11, letterSpacing: 0.5, color: Colors.white70)),
                        const SizedBox(height: 8),
                        Text(formatCurrency(closing.abs()), style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 32, letterSpacing: -0.8, color: toneColor)),
                        const SizedBox(height: 8),
                        Row(children: [
                          const Icon(Icons.person_outline, size: 12, color: Colors.white54),
                          const SizedBox(width: 6),
                          Text('Opening ${formatCurrency(party.openingBal.abs())} · ${filtered.length} entries in period', style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 12, color: Colors.white70)),
                        ]),
                      ]),
                    ),
                    const SizedBox(height: 14),

                    _DateRangeBar(
                      start: _startDate,
                      end: _endDate,
                      onChanged: (start, end) => setState(() { _startDate = start; _endDate = end; }),
                    ),
                    const SizedBox(height: 12),

                    Row(children: [
                      Expanded(child: _ActionBtn(icon: Icons.receipt_long_outlined, label: 'New Voucher', onPress: () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => NewTransactionSheet(defaultPartyId: party.id)))),
                      const SizedBox(width: 10),
                      Expanded(child: _ActionBtn(
                        icon: _exporting ? Icons.hourglass_empty : Icons.ios_share_outlined,
                        label: _exporting ? 'Exporting...' : 'Export PDF',
                        onPress: _exporting ? null : () => _showExportDialog(context, erp),
                      )),
                    ]),
                    const SizedBox(height: 14),

                    Text('History', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: -0.2, color: AppColors.foreground)),
                    const SizedBox(height: 10),

                    if (filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Column(children: [
                          Container(width: 56, height: 56, decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.receipt_long_outlined, size: 24, color: AppColors.primary)),
                          const SizedBox(height: 12),
                          Text(allTxs.isEmpty ? 'No vouchers yet' : 'Nothing in this period', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.foreground)),
                          const SizedBox(height: 6),
                          Text(allTxs.isEmpty ? 'Tap New Voucher to add first transaction.' : 'Widen the date range to see more entries.', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13, color: AppColors.mutedForeground, height: 1.5)),
                        ]),
                      )
                    else
                      ...filtered.map((tx) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: TransactionRow(
                          tx: tx,
                          itemName: tx.itemId != null ? erp.getItemById(tx.itemId!)?.name : null,
                          onTap: () => _editTx(context, tx, party.id),
                          onLongPress: () => _txMenu(context, tx, erp),
                          onMenuPress: () => _txMenu(context, tx, erp),
                        ),
                      )),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => NewTransactionSheet(defaultPartyId: party.id)),
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

  void _editTx(BuildContext context, Transaction tx, String partyId) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => NewTransactionSheet(defaultPartyId: partyId, editing: tx));
  }

  void _txMenu(BuildContext context, Transaction tx, ERPProvider erp) {
    showActionMenu(context,
      title: '${tx.type} · ${tx.date}',
      subtitle: formatCurrency(tx.total),
      items: [
        ActionMenuItem(icon: Icons.edit_outlined, label: 'Edit Voucher', onPress: () => _editTx(context, tx, tx.partyId)),
        ActionMenuItem(
          icon: Icons.delete_outline,
          label: 'Delete Voucher',
          destructive: true,
          onPress: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                title: Text('Delete voucher?', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                content: Text('This entry will be removed and stock reverted.', style: GoogleFonts.inter()),
                actions: [
                  TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('Cancel', style: GoogleFonts.inter())),
                  TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text('Delete', style: GoogleFonts.inter(color: AppColors.destructive, fontWeight: FontWeight.w600))),
                ],
              ),
            ) ?? false;
            if (ok) await erp.deleteTransaction(tx.id);
          },
        ),
      ],
    );
  }

  Future<void> _deleteParty(BuildContext context, ERPProvider erp) async {
    final party = erp.getPartyById(widget.partyId);
    if (party == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Delete party?', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text('${party.name} and all related vouchers will be removed.', style: GoogleFonts.inter()),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('Cancel', style: GoogleFonts.inter())),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text('Delete', style: GoogleFonts.inter(color: AppColors.destructive, fontWeight: FontWeight.w600))),
        ],
      ),
    ) ?? false;
    if (ok && context.mounted) {
      await erp.deleteParty(widget.partyId);
      Navigator.of(context).pop();
    }
  }
}

class _ExportOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ExportOption({required this.icon, required this.color, required this.bgColor, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: bgColor),
        ),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.foreground)),
            Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: AppColors.mutedForeground, height: 1.4)),
          ])),
          Icon(Icons.chevron_right_rounded, size: 20, color: color),
        ]),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPress;

  const _ActionBtn({required this.icon, required this.label, this.onPress});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPress,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.foreground)),
        ]),
      ),
    );
  }
}

class _DateRangeBar extends StatelessWidget {
  final DateTime start;
  final DateTime end;
  final void Function(DateTime, DateTime) onChanged;

  const _DateRangeBar({required this.start, required this.end, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final presets = [('7d', 7), ('30d', 30), ('90d', 90), ('This Year', -1)];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Column(children: [
        Row(children: [
          Expanded(child: _DateBtn(label: 'From', date: start, onTap: () async {
            final d = await showDatePicker(context: context, initialDate: start, firstDate: DateTime(2000), lastDate: end);
            if (d != null) onChanged(d, end);
          })),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward, size: 14, color: AppColors.mutedForeground),
          const SizedBox(width: 8),
          Expanded(child: _DateBtn(label: 'To', date: end, onTap: () async {
            final d = await showDatePicker(context: context, initialDate: end, firstDate: start, lastDate: DateTime(2100));
            if (d != null) onChanged(start, d);
          })),
        ]),
        const SizedBox(height: 10),
        Row(children: presets.map((p) => Padding(
          padding: const EdgeInsets.only(right: 6),
          child: GestureDetector(
            onTap: () {
              final now = DateTime.now();
              if (p.$2 == -1) onChanged(DateTime(now.year, 1, 1), now);
              else onChanged(now.subtract(Duration(days: p.$2)), now);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(8)),
              child: Text(p.$1, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 11.5, color: AppColors.primary)),
            ),
          ),
        )).toList()),
      ]),
    );
  }
}

class _DateBtn extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const _DateBtn({required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(color: AppColors.muted, borderRadius: BorderRadius.circular(10)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 10, color: AppColors.mutedForeground, letterSpacing: 0.3)),
          Text(formatDateDisplay(formatDate(date)), style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12.5, color: AppColors.foreground)),
        ]),
      ),
    );
  }
}
