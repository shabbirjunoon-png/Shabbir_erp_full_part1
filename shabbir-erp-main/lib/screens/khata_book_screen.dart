import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/transaction.dart' show Transaction, txTypes;
import '../providers/erp_provider.dart';
import '../utils/format.dart';
import '../widgets/app_header.dart';
import 'new_transaction_sheet.dart';

class KhataBookScreen extends StatefulWidget {
  const KhataBookScreen({super.key});

  @override
  State<KhataBookScreen> createState() => _KhataBookScreenState();
}

class _KhataBookScreenState extends State<KhataBookScreen> {
  late DateTime _startDate;
  late DateTime _endDate;
  String _filterType = 'All';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = now;
  }

  /// Group transactions by date string (dd-MM-yyyy), sorted newest first
  Map<String, List<Transaction>> _grouped(List<Transaction> all) {
    final s = DateTime(_startDate.year, _startDate.month, _startDate.day);
    final e = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);

    final filtered = all.where((tx) {
      final d = parseDate(tx.date);
      if (d.isBefore(s) || d.isAfter(e)) return false;
      if (_filterType != 'All' && tx.type != _filterType) return false;
      return true;
    }).toList()
      ..sort((a, b) {
        final da = parseDate(a.date);
        final db = parseDate(b.date);
        return db.compareTo(da); // newest first
      });

    final Map<String, List<Transaction>> grouped = {};
    for (final tx in filtered) {
      grouped.putIfAbsent(tx.date, () => []).add(tx);
    }
    return grouped;
  }

  /// Cash-in = Receipts (money received from customers)
  /// Cash-out = Payments (money paid to suppliers)
  double _cashIn(List<Transaction> txs) => txs.where((t) => t.type == 'Receipt').fold(0.0, (s, t) => s + t.total);
  double _cashOut(List<Transaction> txs) => txs.where((t) => t.type == 'Payment').fold(0.0, (s, t) => s + t.total);
  double _salesTotal(List<Transaction> txs) => txs.where((t) => t.type == 'Sale').fold(0.0, (s, t) => s + t.total);
  double _purchaseTotal(List<Transaction> txs) => txs.where((t) => t.type == 'Purchase').fold(0.0, (s, t) => s + t.total);

  @override
  Widget build(BuildContext context) {
    return Consumer<ERPProvider>(
      builder: (context, erp, _) {
        final all = erp.transactions;
        final grouped = _grouped(all);
        final allFiltered = grouped.values.expand((l) => l).toList();

        final totalCashIn = _cashIn(allFiltered);
        final totalCashOut = _cashOut(allFiltered);
        final totalSales = _salesTotal(allFiltered);
        final totalPurchases = _purchaseTotal(allFiltered);
        final netCash = totalCashIn - totalCashOut;

        // Sort date keys newest first
        final dateKeys = grouped.keys.toList()
          ..sort((a, b) => parseDate(b).compareTo(parseDate(a)));

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              const AppHeader(title: 'Khata Book', subtitle: 'Daily journal of all entries'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                  children: [
                    // ── Net cash summary ──────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(22)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('NET CASH POSITION', style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 11, letterSpacing: 0.5, color: Colors.white70)),
                          const SizedBox(height: 8),
                          Text(
                            formatCurrency(netCash.abs()),
                            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 32, letterSpacing: -0.8, color: netCash >= 0 ? AppColors.accent : const Color(0xFFFCA5A5)),
                          ),
                          Text(netCash >= 0 ? 'Cash surplus (more received than paid)' : 'Cash deficit (more paid than received)',
                              style: GoogleFonts.inter(fontSize: 12, color: Colors.white60)),
                          const SizedBox(height: 16),
                          Row(children: [
                            _CashPill(label: 'Cash In', value: totalCashIn, color: AppColors.accent),
                            const SizedBox(width: 8),
                            _CashPill(label: 'Cash Out', value: totalCashOut, color: const Color(0xFFFCA5A5)),
                            const SizedBox(width: 8),
                            _CashPill(label: 'Sales', value: totalSales, color: const Color(0xFF93C5FD)),
                          ]),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Date range filter ─────────────────────────────────
                    _DateFilterBar(
                      start: _startDate,
                      end: _endDate,
                      onChanged: (s, e) => setState(() { _startDate = s; _endDate = e; }),
                    ),
                    const SizedBox(height: 12),

                    // ── Type filter pills ─────────────────────────────────
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['All', ...txTypes].map((t) {
                          final active = _filterType == t;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => setState(() => _filterType = t),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: active ? AppColors.foreground : AppColors.card,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: active ? AppColors.foreground : AppColors.border),
                                ),
                                child: Text(t, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12.5, color: active ? AppColors.background : AppColors.foreground)),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Entry count summary ────────────────────────────────
                    if (allFiltered.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text('${allFiltered.length} entries across ${dateKeys.length} days', style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 12, color: AppColors.mutedForeground)),
                      ),

                    // ── Empty state ───────────────────────────────────────
                    if (dateKeys.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        child: Column(children: [
                          Container(width: 64, height: 64, decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(18)), child: const Icon(Icons.book_outlined, size: 28, color: AppColors.primary)),
                          const SizedBox(height: 16),
                          Text('No entries in this period', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.foreground)),
                          const SizedBox(height: 8),
                          Text('Add vouchers from the Parties screen\nor tap "New Voucher" below.', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13, color: AppColors.mutedForeground, height: 1.5)),
                        ]),
                      )
                    else
                      // ── Date groups ────────────────────────────────────
                      ...dateKeys.map((dateStr) {
                        final dayTxs = grouped[dateStr]!;
                        final dayIn = _cashIn(dayTxs);
                        final dayOut = _cashOut(dayTxs);
                        final daySales = _salesTotal(dayTxs);
                        final dayPurchases = _purchaseTotal(dayTxs);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Date header row
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                                    child: Text(formatDateDisplay(dateStr), style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.white)),
                                  ),
                                  const SizedBox(width: 8),
                                  if (dayIn > 0)
                                    _DayBadge(label: '+${_fmt(dayIn)}', color: AppColors.success),
                                  if (dayOut > 0) ...[
                                    const SizedBox(width: 4),
                                    _DayBadge(label: '-${_fmt(dayOut)}', color: AppColors.destructive),
                                  ],
                                  if (daySales > 0 && dayIn == 0) ...[
                                    const SizedBox(width: 4),
                                    _DayBadge(label: 'S ${_fmt(daySales)}', color: const Color(0xFF0EA5E9)),
                                  ],
                                  if (dayPurchases > 0 && dayOut == 0) ...[
                                    const SizedBox(width: 4),
                                    _DayBadge(label: 'P ${_fmt(dayPurchases)}', color: const Color(0xFF7C3AED)),
                                  ],
                                  const Spacer(),
                                  Text('${dayTxs.length} entries', style: GoogleFonts.inter(fontSize: 11, color: AppColors.mutedForeground)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Transaction rows for this day
                              ...dayTxs.map((tx) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: _JournalRow(
                                  tx: tx,
                                  partyName: erp.getPartyById(tx.partyId)?.name ?? 'Unknown',
                                  itemName: tx.itemId != null ? erp.getItemById(tx.itemId!)?.name : null,
                                  onTap: () => _editTx(context, tx),
                                ),
                              )),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => const NewTransactionSheet()),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add, size: 20),
            label: Text('New Voucher', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      },
    );
  }

  String _fmt(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  void _editTx(BuildContext context, Transaction tx) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => NewTransactionSheet(editing: tx));
  }
}

class _CashPill extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _CashPill({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: Colors.white60, letterSpacing: 0.3)),
        const SizedBox(height: 2),
        Text(formatCurrency(value), style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 11, color: color)),
      ]),
    );
  }
}

class _DayBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _DayBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 10.5, color: color)),
    );
  }
}

class _JournalRow extends StatelessWidget {
  final Transaction tx;
  final String partyName;
  final String? itemName;
  final VoidCallback onTap;

  const _JournalRow({required this.tx, required this.partyName, this.itemName, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final config = _config(tx.type);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Type icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: config.bg, borderRadius: BorderRadius.circular(9)),
              child: Icon(config.icon, size: 16, color: config.color),
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(tx.type, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.foreground)),
                    const SizedBox(width: 6),
                    Expanded(child: Text('· $partyName', style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 12.5, color: AppColors.mutedForeground), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ]),
                  if (itemName != null || tx.remarks.isNotEmpty)
                    Text(
                      [if (itemName != null) itemName!, if (tx.remarks.isNotEmpty) tx.remarks].join(' · '),
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.mutedForeground),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (!tx.isMoneyOnly && tx.qty > 0)
                    Text('${formatNumber(tx.qty)} × ${formatCurrency(tx.rate)}', style: GoogleFonts.inter(fontSize: 11, color: AppColors.mutedForeground)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(formatCurrency(tx.total), style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: config.color)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  ({Color color, Color bg, IconData icon}) _config(String type) {
    switch (type) {
      case 'Sale':      return (color: const Color(0xFF0EA5E9), bg: const Color(0xFFE0F2FE), icon: Icons.arrow_upward);
      case 'Purchase':  return (color: const Color(0xFF7C3AED), bg: const Color(0xFFEDE9FE), icon: Icons.arrow_downward);
      case 'Receipt':   return (color: AppColors.success, bg: const Color(0xFFDCFCE7), icon: Icons.south_west);
      case 'Payment':   return (color: AppColors.destructive, bg: const Color(0xFFFEE2E2), icon: Icons.north_east);
      default:          return (color: AppColors.mutedForeground, bg: AppColors.muted, icon: Icons.receipt_long_outlined);
    }
  }
}

class _DateFilterBar extends StatelessWidget {
  final DateTime start;
  final DateTime end;
  final void Function(DateTime, DateTime) onChanged;

  const _DateFilterBar({required this.start, required this.end, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final presets = [
      ('Today', 0),
      ('7 Days', 7),
      ('This Month', -1),
      ('90 Days', 90),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Column(
        children: [
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
          Row(
            children: presets.map((p) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () {
                  final now = DateTime.now();
                  if (p.$2 == 0) {
                    onChanged(DateTime(now.year, now.month, now.day), now);
                  } else if (p.$2 == -1) {
                    onChanged(DateTime(now.year, now.month, 1), now);
                  } else {
                    onChanged(now.subtract(Duration(days: p.$2)), now);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(8)),
                  child: Text(p.$1, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 11.5, color: AppColors.primary)),
                ),
              ),
            )).toList(),
          ),
        ],
      ),
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
