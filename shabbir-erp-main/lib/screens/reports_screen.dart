import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/transaction.dart';
import '../providers/erp_provider.dart';
import '../utils/format.dart';
import '../widgets/app_header.dart';
import '../widgets/transaction_row.dart';
import 'new_transaction_sheet.dart';
import 'trial_balance_screen.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ERPProvider>(
      builder: (context, erp, _) {
        final now = DateTime.now();
        double sales = 0, purchases = 0, receipts = 0, payments = 0;
        for (final tx in erp.transactions) {
          final d = parseDate(tx.date);
          if (d.month != now.month || d.year != now.year) continue;
          if (tx.type == 'Sale') sales += tx.total;
          else if (tx.type == 'Purchase') purchases += tx.total;
          else if (tx.type == 'Receipt') receipts += tx.total;
          else if (tx.type == 'Payment') payments += tx.total;
        }

        final topReceivables = erp.partiesWithBalance.where((p) => p.balance > 0).toList()
          ..sort((a, b) => b.balance.compareTo(a.balance));
        final top5 = topReceivables.take(5).toList();
        final recentTx = erp.transactions.take(8).toList();

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              AppHeader(
                title: 'Reports',
                subtitle: 'Business overview',
                actions: [AppHeaderAction(icon: Icons.account_balance_outlined, onPress: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TrialBalanceScreen())))],
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  children: [
                    // Hero net outstanding card
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(22)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text('NET OUTSTANDING', style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 12, letterSpacing: 0.5, color: Colors.white70)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(999)),
                            child: Row(children: [
                              const Icon(Icons.circle, size: 6, color: AppColors.accent),
                              const SizedBox(width: 4),
                              Text('Live', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 10.5, color: AppColors.accent, letterSpacing: 0.5)),
                            ]),
                          ),
                        ]),
                        const SizedBox(height: 10),
                        Text(formatCurrency(erp.totalReceivable - erp.totalPayable), style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 36, letterSpacing: -1, color: Colors.white)),
                        const SizedBox(height: 14),
                        Row(children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('RECEIVABLE', style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 10, letterSpacing: 0.5, color: Colors.white60)),
                            const SizedBox(height: 2),
                            Text(formatCurrency(erp.totalReceivable), style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.accent)),
                          ])),
                          Container(width: 1, height: 28, color: Colors.white.withOpacity(0.15)),
                          Expanded(child: Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('PAYABLE', style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 10, letterSpacing: 0.5, color: Colors.white60)),
                              const SizedBox(height: 2),
                              Text(formatCurrency(erp.totalPayable), style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: const Color(0xFFFCA5A5))),
                            ]),
                          )),
                        ]),
                      ]),
                    ),
                    const SizedBox(height: 20),

                    // Trial Balance button
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TrialBalanceScreen())),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.tint.withOpacity(0.3))),
                        child: Row(children: [
                          Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.account_balance_outlined, color: Colors.white, size: 20)),
                          const SizedBox(width: 14),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Trial Balance', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.primary)),
                            Text('View all parties with grand total + PDF', style: GoogleFonts.inter(fontWeight: FontWeight.w400, fontSize: 12, color: AppColors.mutedForeground)),
                          ])),
                          const Icon(Icons.chevron_right, color: AppColors.primary),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // This month metrics
                    Text('THIS MONTH', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12, letterSpacing: 0.5, color: AppColors.mutedForeground)),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: _MetricCard(icon: Icons.arrow_upward, tone: const Color(0xFF0EA5E9), label: 'Sales', value: formatCurrency(sales))),
                      const SizedBox(width: 10),
                      Expanded(child: _MetricCard(icon: Icons.arrow_downward, tone: const Color(0xFF7C3AED), label: 'Purchases', value: formatCurrency(purchases))),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: _MetricCard(icon: Icons.south_west, tone: AppColors.success, label: 'Receipts In', value: formatCurrency(receipts))),
                      const SizedBox(width: 10),
                      Expanded(child: _MetricCard(icon: Icons.north_east, tone: AppColors.destructive, label: 'Payments Out', value: formatCurrency(payments))),
                    ]),
                    const SizedBox(height: 20),

                    // Top receivables
                    _Surface(
                      title: 'Top Receivables',
                      meta: '${top5.length} parties',
                      child: top5.isEmpty
                          ? Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('All accounts are settled.', style: GoogleFonts.inter(fontSize: 13, color: AppColors.mutedForeground)))
                          : Column(children: top5.map((p) => Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0x0F000000), width: 1))),
                              child: Row(children: [
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(p.name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.foreground), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  Text(p.type, style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 11.5, color: AppColors.mutedForeground)),
                                ])),
                                Text(formatCurrency(p.balance), style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.primary)),
                              ]),
                            )).toList()),
                    ),
                    const SizedBox(height: 16),

                    // Catalog summary
                    _Surface(
                      title: 'Catalog Summary',
                      child: Row(children: [
                        _SummaryStat(icon: Icons.people_outline, label: 'Parties', value: erp.parties.length.toString()),
                        _SummaryStat(icon: Icons.inventory_2_outlined, label: 'Items', value: erp.inventory.length.toString()),
                        _SummaryStat(icon: Icons.receipt_long_outlined, label: 'Vouchers', value: erp.transactions.length.toString()),
                      ]),
                    ),
                    const SizedBox(height: 16),

                    // Recent activity
                    _Surface(
                      title: 'Recent Activity',
                      meta: 'Latest ${recentTx.length}',
                      child: recentTx.isEmpty
                          ? Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('No activity yet.', style: GoogleFonts.inter(fontSize: 13, color: AppColors.mutedForeground)))
                          : Column(children: recentTx.map((tx) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: TransactionRow(
                                tx: tx,
                                partyName: context.read<ERPProvider>().getPartyById(tx.partyId)?.name,
                                itemName: tx.itemId != null ? context.read<ERPProvider>().getItemById(tx.itemId!)?.name : null,
                                showParty: true,
                                onTap: () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => NewTransactionSheet(editing: tx)),
                              ),
                            )).toList()),
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
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final Color tone;
  final String label;
  final String value;

  const _MetricCard({required this.icon, required this.tone, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 30, height: 30, decoration: BoxDecoration(color: tone.withOpacity(0.12), borderRadius: BorderRadius.circular(9)), child: Icon(icon, size: 14, color: tone)),
        const SizedBox(height: 6),
        Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 11.5, color: AppColors.mutedForeground)),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: -0.3, color: AppColors.foreground), maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}

class _Surface extends StatelessWidget {
  final String title;
  final String? meta;
  final Widget child;

  const _Surface({required this.title, this.meta, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: -0.2, color: AppColors.foreground)),
          if (meta != null) Text(meta!, style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 12, color: AppColors.mutedForeground)),
        ]),
        const SizedBox(height: 12),
        child,
      ]),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryStat({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Column(children: [
      Container(width: 30, height: 30, decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(9)), child: Icon(icon, size: 14, color: AppColors.primary)),
      const SizedBox(height: 6),
      Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.foreground)),
      Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 11.5, color: AppColors.mutedForeground)),
    ]));
  }
}
