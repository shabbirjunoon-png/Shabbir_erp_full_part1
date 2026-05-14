import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../providers/erp_provider.dart';
import '../services/backup_service.dart';
import '../services/locale_service.dart';
import '../services/security_service.dart';
import '../services/supabase_service.dart';
import '../widgets/app_header.dart';
import 'pattern_lock_screen.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onLogout;
  const SettingsScreen({super.key, required this.onLogout});
  @override
  State<SettingsScreen> createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {  // ignore: library_private_types_in_public_api
  bool _patternEnabled = false;
  bool _loadingBackupLocal = false;
  bool _loadingRestoreLocal = false;
  bool _loadingSupabaseSync = false;
  bool _loadingSupabaseRestore = false;
  bool _loadingLogout = false;
  String _offlineName = 'User';
  DateTime? _lastBackupDate;
  bool _backupNeeded = false;
  DateTime? _lastSupabaseSync;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final enabled = await SecurityService.instance.isPatternEnabled();
    final hasPattern = await SecurityService.instance.hasPatternSet();
    final prefs = await SharedPreferences.getInstance();
    final lastBackup = await BackupService.instance.lastBackupDate();
    final needed = await BackupService.instance.isBackupNeeded();
    final lastSyncMs = prefs.getInt('supabase_last_sync');
    if (mounted) {
      setState(() {
        _patternEnabled = enabled && hasPattern;
        _offlineName = prefs.getString('user_name') ?? 'User';
        _lastBackupDate = lastBackup;
        _backupNeeded = needed;
        _lastSupabaseSync = lastSyncMs != null
            ? DateTime.fromMillisecondsSinceEpoch(lastSyncMs)
            : null;
      });
    }
  }

  // ── Name Editing ───────────────────────────────────────────────────────────
  Future<void> _editName() async {
    final ctrl = TextEditingController(text: _offlineName);
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Naam Tabdeel Karo', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          style: GoogleFonts.inter(fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Apna naam likho',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Cancel', style: GoogleFonts.inter())),
          ElevatedButton(
            onPressed: () { final n = ctrl.text.trim(); if (n.isNotEmpty) Navigator.of(context).pop(n); },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Text('Save', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', name);
      if (mounted) setState(() => _offlineName = name);
      _snack('Naam update ho gaya!');
    }
  }

  // ── Pattern Lock ───────────────────────────────────────────────────────────
  Future<void> _togglePattern() async {
    if (_patternEnabled) {
      final verified = await Navigator.of(context).push<bool>(MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PatternLockScreen(mode: PatternLockMode.verify, onSuccess: () => Navigator.of(context).pop(true), onCancel: () => Navigator.of(context).pop(false)),
      ));
      if (verified == true) { await SecurityService.instance.disablePattern(); if (mounted) setState(() => _patternEnabled = false); _snack('Pattern lock band ho gaya'); }
    } else {
      final set = await Navigator.of(context).push<bool>(MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PatternLockScreen(mode: PatternLockMode.set, onSuccess: () => Navigator.of(context).pop(true), onCancel: () => Navigator.of(context).pop(false)),
      ));
      if (set == true) { if (mounted) setState(() => _patternEnabled = true); _snack('Pattern lock laga diya'); }
    }
  }

  Future<void> _changePattern() async {
    final changed = await Navigator.of(context).push<bool>(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => PatternLockScreen(mode: PatternLockMode.change, onSuccess: () => Navigator.of(context).pop(true), onCancel: () => Navigator.of(context).pop(false)),
    ));
    if (changed == true) _snack('Pattern tabdeel ho gaya');
  }

  // ── Local Backup ───────────────────────────────────────────────────────────
  Future<void> _backupLocal() async {
    setState(() => _loadingBackupLocal = true);
    try {
      await BackupService.instance.backupToLocalStorage();
      final newDate = await BackupService.instance.lastBackupDate();
      if (mounted) setState(() { _lastBackupDate = newDate; _backupNeeded = false; });
      _snack('Backup tayyar — save karo ya share karo');
    } catch (e) {
      _snack('Backup nahi hua: $e', error: true);
    } finally {
      if (mounted) setState(() => _loadingBackupLocal = false);
    }
  }

  Future<void> _restoreLocal() async {
    final mode = await _showRestoreModeDialog();
    if (mode == null) return;
    setState(() => _loadingRestoreLocal = true);
    try {
      final success = await BackupService.instance.restoreFromFiles(mode: mode);
      if (!success) { _snack('Koi file select nahi ki'); return; }
      if (mounted) await context.read<ERPProvider>().reload();
      _snack(mode == RestoreMode.merge ? 'Data merge ho gaya!' : 'Data replace ho gaya!');
    } catch (e) {
      _snack('Restore nahi hua: ${e.toString().replaceAll("Exception:", "").trim()}', error: true);
    } finally {
      if (mounted) setState(() => _loadingRestoreLocal = false);
    }
  }

  Future<String?> _showRestoreModeDialog() async {
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Restore Mode Chunain', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Aap backup file restore karna chahte hain. Pehle batao ke data kaise restore ho:', style: GoogleFonts.inter(fontSize: 13, color: AppColors.mutedForeground, height: 1.5)),
          const SizedBox(height: 16),
          _RestoreOptionCard(
            icon: Icons.swap_horiz_rounded,
            color: AppColors.destructive,
            title: 'Replace (Tabdeel Karo)',
            subtitle: 'Purana data delete hoga, sirf backup ka data rahega',
            onTap: () => Navigator.of(context).pop(RestoreMode.replace),
          ),
          const SizedBox(height: 10),
          _RestoreOptionCard(
            icon: Icons.merge_type_rounded,
            color: AppColors.success,
            title: 'Merge (Milaao)',
            subtitle: 'Purana data rahega, backup ka naya data uske saath jud jayega',
            onTap: () => Navigator.of(context).pop(RestoreMode.merge),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Cancel', style: GoogleFonts.inter())),
        ],
      ),
    );
  }

  // ── Supabase Sync ──────────────────────────────────────────────────────────
  Future<void> _supabaseSync() async {
    setState(() => _loadingSupabaseSync = true);
    try {
      final erp = context.read<ERPProvider>();
      await SupabaseService.instance.pushAll(
        parties: erp.parties.toList(),
        items: erp.inventory.toList(),
        transactions: erp.transactions.toList(),
      );
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      await prefs.setInt('supabase_last_sync', now.millisecondsSinceEpoch);
      if (mounted) setState(() => _lastSupabaseSync = now);
      _snack('Data Supabase par sync ho gaya!');
    } catch (e) {
      _snack('Sync nahi hua: ${e.toString().replaceAll("Exception:", "").trim()}', error: true);
    } finally {
      if (mounted) setState(() => _loadingSupabaseSync = false);
    }
  }

  Future<void> _supabaseRestore() async {
    final mode = await _showRestoreModeDialog();
    if (mode == null) return;
    setState(() => _loadingSupabaseRestore = true);
    try {
      final pulled = await SupabaseService.instance.pullAll();
      final parties = pulled['parties'] as List;
      final items = pulled['stock_items'] as List;
      final txs = pulled['transactions'] as List;
      if (parties.isEmpty && items.isEmpty && txs.isEmpty) {
        _snack('Supabase par koi data nahi mila', error: true);
        return;
      }
      final db = await _buildExportMap(parties, items, txs);
      if (mode == RestoreMode.replace) {
        await context.read<ERPProvider>().importFromSupabase(db);
      } else {
        await context.read<ERPProvider>().mergeFromSupabase(db);
      }
      if (mounted) await context.read<ERPProvider>().reload();
      _snack(mode == RestoreMode.merge
          ? 'Supabase data merge ho gaya!'
          : 'Supabase data restore ho gaya!');
    } catch (e) {
      _snack('Restore nahi hua: ${e.toString().replaceAll("Exception:", "").trim()}', error: true);
    } finally {
      if (mounted) setState(() => _loadingSupabaseRestore = false);
    }
  }

  Map<String, dynamic> _buildExportMap(List parties, List items, List txs) {
    return {
      'version': 1,
      'parties': parties.map((p) => (p as dynamic).toMap()).toList(),
      'stock_items': items.map((i) => (i as dynamic).toMap()).toList(),
      'transactions': txs.map((t) => (t as dynamic).toMap()).toList(),
    };
  }

  String _formatSyncDate(DateTime? d) {
    if (d == null) return 'Kabhi nahi';
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inMinutes < 1) return 'Abhi';
    if (diff.inHours < 1) return '${diff.inMinutes} min pehle';
    if (diff.inDays < 1) return '${diff.inHours} ghante pehle';
    return '${diff.inDays} din pehle';
  }

            // ── Supabase Cloud Sync ──
            _SectionLabel(locale.t3('Cloud Sync (Supabase)', 'Cloud Sync (Supabase)', 'کلاؤڈ سنک (Supabase)')),
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(children: [
                const Icon(Icons.cloud_done_outlined, size: 15, color: Color(0xFF1D4ED8)),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  '${locale.t3("Last sync", "Aakhri sync", "آخری سنک")}: ${_formatSyncDate(_lastSupabaseSync)}',
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF1D4ED8), fontWeight: FontWeight.w500),
                )),
              ]),
            ),
            _Tile(
              icon: Icons.cloud_upload_outlined,
              title: locale.t3('Sync to Supabase', 'Supabase pe Sync Karo', 'Supabase پر سنک کریں'),
              subtitle: locale.t3('Save all data to cloud', 'Sab data cloud par save karo', 'تمام ڈیٹا کلاؤڈ پر محفوظ کریں'),
              loading: _loadingSupabaseSync,
              onTap: _supabaseSync,
            ),
            _Tile(
              icon: Icons.cloud_download_outlined,
              title: locale.t3('Restore from Supabase', 'Supabase se Restore', 'Supabase سے ریسٹور'),
              subtitle: locale.t3('Pull data from cloud', 'Cloud se data wapas lao', 'کلاؤڈ سے ڈیٹا واپس لائیں'),
              loading: _loadingSupabaseRestore,
              onTap: _supabaseRestore,
            ),
            const SizedBox(height: 24),

            const SizedBox(height: 24),

            // ── App ──
            _SectionLabel(locale.t3('App', 'App', 'ایپ')),
            _Tile(icon: Icons.info_outline, title: locale.t3('About', 'About', 'بارے میں'), subtitle: 'Shabbir ERP v1.0', onTap: () => _showAboutDialog(context)),
            const SizedBox(height: 8),
            _Tile(icon: Icons.logout, title: locale.t3('Sign Out', 'Sign Out', 'سائن آؤٹ'), subtitle: locale.t3('Log out of the app', 'Logout karo', 'لاگ آؤٹ کریں'), loading: _loadingLogout, onTap: _logout, destructive: true),
          ],
        )),
      ]),
    );
  }
}

class _LangChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _LangChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.secondary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: selected ? Colors.white : AppColors.mutedForeground,
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.5, color: AppColors.mutedForeground)),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool loading;
  final bool destructive;

  const _Tile({required this.icon, required this.title, required this.subtitle, this.trailing, this.onTap, this.loading = false, this.destructive = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border), boxShadow: [AppColors.cardShadow]),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(width: 38, height: 38, decoration: BoxDecoration(color: destructive ? const Color(0xFFFEE2E2) : AppColors.secondary, borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 18, color: destructive ? AppColors.destructive : AppColors.primary)),
        title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: destructive ? AppColors.destructive : AppColors.foreground)),
        subtitle: Text(subtitle, style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.mutedForeground)),
        trailing: loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)) : (trailing ?? (onTap != null ? const Icon(Icons.chevron_right, size: 18, color: AppColors.mutedForeground) : null)),
        onTap: loading ? null : onTap,
      ),
    );
  }
}

class _RestoreOptionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RestoreOptionCard({required this.icon, required this.color, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 18, color: color)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.foreground)),
            Text(subtitle, style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.mutedForeground, height: 1.4)),
          ])),
          Icon(Icons.chevron_right, size: 16, color: color),
        ]),
      ),
    );
  }
}
