import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../providers/erp_provider.dart';
import '../services/backup_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/locale_service.dart';
import '../services/security_service.dart';
import '../widgets/app_header.dart';
import 'pattern_lock_screen.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onLogout;
  const SettingsScreen({super.key, required this.onLogout});
  @override
  State<SettingsScreen> createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  bool _patternEnabled = false;
  bool _loadingBackupLocal = false;
  bool _loadingRestoreLocal = false;
  bool _loadingLogout = false;
  String _offlineName = 'User';
  DateTime? _lastBackupDate;
  bool _backupNeeded = false;

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
    if (mounted) {
      setState(() {
        _patternEnabled = enabled && hasPattern;
        _offlineName = prefs.getString('user_name') ?? 'User';
        _lastBackupDate = lastBackup;
        _backupNeeded = needed;
      });
    }
  }

  // ── Name Editing ───────────────────────────────────────────────────────────
  Future<void> _editName() async {
    final locale = context.read<LocaleService>();
    final ctrl = TextEditingController(text: _offlineName);
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          locale.t3('Edit Name', 'Naam Tabdeel Karo', 'نام تبدیل کریں'),
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          style: GoogleFonts.inter(fontSize: 15),
          decoration: InputDecoration(
            hintText: locale.t3('Enter your name', 'Apna naam likho', 'اپنا نام لکھیں'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(locale.t3('Cancel', 'Cancel', 'منسوخ'), style: GoogleFonts.inter()),
          ),
          ElevatedButton(
            onPressed: () { final n = ctrl.text.trim(); if (n.isNotEmpty) Navigator.of(context).pop(n); },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Text(locale.t3('Save', 'Save', 'محفوظ کریں'), style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', name);
      if (mounted) setState(() => _offlineName = name);
      _snack(locale.t3('Name updated!', 'Naam update ho gaya!', 'نام اپ ڈیٹ ہو گیا!'));
    }
  }

  // ── Pattern Lock ───────────────────────────────────────────────────────────
  Future<void> _togglePattern() async {
    final locale = context.read<LocaleService>();
    if (_patternEnabled) {
      final verified = await Navigator.of(context).push<bool>(MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PatternLockScreen(mode: PatternLockMode.verify, onSuccess: () => Navigator.of(context).pop(true), onCancel: () => Navigator.of(context).pop(false)),
      ));
      if (verified == true) {
        await SecurityService.instance.disablePattern();
        if (mounted) setState(() => _patternEnabled = false);
        _snack(locale.t3('Pattern lock disabled', 'Pattern lock band ho gaya', 'پیٹرن لاک بند ہو گیا'));
      }
    } else {
      final set = await Navigator.of(context).push<bool>(MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PatternLockScreen(mode: PatternLockMode.set, onSuccess: () => Navigator.of(context).pop(true), onCancel: () => Navigator.of(context).pop(false)),
      ));
      if (set == true) {
        if (mounted) setState(() => _patternEnabled = true);
        _snack(locale.t3('Pattern lock enabled', 'Pattern lock laga diya', 'پیٹرن لاک لگا دیا'));
      }
    }
  }

  Future<void> _changePattern() async {
    final locale = context.read<LocaleService>();
    final changed = await Navigator.of(context).push<bool>(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => PatternLockScreen(mode: PatternLockMode.change, onSuccess: () => Navigator.of(context).pop(true), onCancel: () => Navigator.of(context).pop(false)),
    ));
    if (changed == true) _snack(locale.t3('Pattern changed', 'Pattern tabdeel ho gaya', 'پیٹرن تبدیل ہو گیا'));
  }

  // ── Local Backup ───────────────────────────────────────────────────────────
  Future<void> _backupLocal() async {
    final locale = context.read<LocaleService>();
    setState(() => _loadingBackupLocal = true);
    try {
      await BackupService.instance.backupToLocalStorage();
      final newDate = await BackupService.instance.lastBackupDate();
      if (mounted) setState(() { _lastBackupDate = newDate; _backupNeeded = false; });
      _snack(locale.t3('Backup ready — save or share it', 'Backup tayyar — save karo ya share karo', 'بیک اپ تیار — محفوظ کریں یا شیئر کریں'));
    } catch (e) {
      _snack(locale.t3('Backup failed: $e', 'Backup nahi hua: $e', 'بیک اپ ناکام: $e'), error: true);
    } finally {
      if (mounted) setState(() => _loadingBackupLocal = false);
    }
  }

  Future<void> _restoreLocal() async {
    final locale = context.read<LocaleService>();
    final mode = await _showRestoreModeDialog(locale);
    if (mode == null) return;
    setState(() => _loadingRestoreLocal = true);
    try {
      final success = await BackupService.instance.restoreFromFiles(mode: mode);
      if (!success) {
        _snack(locale.t3('No file selected', 'Koi file select nahi ki', 'کوئی فائل منتخب نہیں کی'));
        return;
      }
      if (mounted) await context.read<ERPProvider>().reload();
      _snack(mode == RestoreMode.merge
          ? locale.t3('Data merged!', 'Data merge ho gaya!', 'ڈیٹا ضم ہو گیا!')
          : locale.t3('Data replaced!', 'Data replace ho gaya!', 'ڈیٹا تبدیل ہو گیا!'));
    } catch (e) {
      _snack(locale.t3(
        'Restore failed: ${e.toString().replaceAll("Exception:", "").trim()}',
        'Restore nahi hua: ${e.toString().replaceAll("Exception:", "").trim()}',
        'ریسٹور ناکام: ${e.toString().replaceAll("Exception:", "").trim()}',
      ), error: true);
    } finally {
      if (mounted) setState(() => _loadingRestoreLocal = false);
    }
  }

  Future<String?> _showRestoreModeDialog(LocaleService locale) async {
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          locale.t3('Choose Restore Mode', 'Restore Mode Chunain', 'ریسٹور موڈ منتخب کریں'),
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
            locale.t3(
              'How would you like to restore your backup?',
              'Aap backup file restore karna chahte hain. Pehle batao ke data kaise restore ho:',
              'آپ بیک اپ ڈیٹا کیسے ریسٹور کرنا چاہتے ہیں؟',
            ),
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.mutedForeground, height: 1.5),
          ),
          const SizedBox(height: 16),
          _RestoreOptionCard(
            icon: Icons.swap_horiz_rounded,
            color: AppColors.destructive,
            title: locale.t3('Replace', 'Replace (Tabdeel Karo)', 'تبدیل کریں'),
            subtitle: locale.t3(
              'Delete existing data, keep only backup data',
              'Purana data delete hoga, sirf backup ka data rahega',
              'پرانا ڈیٹا حذف ہو گا، صرف بیک اپ کا ڈیٹا رہے گا',
            ),
            onTap: () => Navigator.of(context).pop(RestoreMode.replace),
          ),
          const SizedBox(height: 10),
          _RestoreOptionCard(
            icon: Icons.merge_type_rounded,
            color: AppColors.success,
            title: locale.t3('Merge', 'Merge (Milaao)', 'ضم کریں'),
            subtitle: locale.t3(
              'Keep existing data and add backup data alongside it',
              'Purana data rahega, backup ka naya data uske saath jud jayega',
              'پرانا ڈیٹا رہے گا، بیک اپ کا نیا ڈیٹا اس کے ساتھ شامل ہو گا',
            ),
            onTap: () => Navigator.of(context).pop(RestoreMode.merge),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(locale.t3('Cancel', 'Cancel', 'منسوخ'), style: GoogleFonts.inter()),
          ),
        ],
      ),
    );
  }

  // ── Logout ─────────────────────────────────────────────────────────────────
  Future<void> _logout() async {
    final locale = context.read<LocaleService>();
    final confirm = await _confirmDialog(
      locale.t3('Sign Out?', 'Sign Out?', 'سائن آؤٹ؟'),
      locale.t3(
        'You will return to the login screen. Your data will remain safe.',
        'Aap login screen par wapas jayenge. Data safe rahega.',
        'آپ لاگ ان اسکرین پر واپس جائیں گے۔ ڈیٹا محفوظ رہے گا۔',
      ),
      locale,
    );
    if (!confirm) return;
    setState(() => _loadingLogout = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('offline_logged_in');
    try { await FirebaseAuthService.instance.signOut(); } catch (_) {}
    if (mounted) {
      setState(() => _loadingLogout = false);
      widget.onLogout();
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Future<bool> _confirmDialog(String title, String body, LocaleService locale) async {
    return await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(body, style: GoogleFonts.inter(fontSize: 14, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(locale.t3('Cancel', 'Cancel', 'منسوخ'), style: GoogleFonts.inter()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.destructive, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Text(locale.t3('Yes', 'Haan', 'ہاں'), style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    ) ?? false;
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13)),
      backgroundColor: error ? AppColors.destructive : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text('About Shabbir ERP', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      content: Text('Powered by Shabbir Ahmed.\n\nThis app is totally AI-generated.', style: GoogleFonts.inter(fontSize: 14, height: 1.5)),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Close', style: GoogleFonts.inter()))],
    ));
  }

  String _formatBackupDate(DateTime? d, LocaleService locale) {
    if (d == null) return locale.t3('Never', 'Kabhi nahi', 'کبھی نہیں');
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inDays == 0) return locale.t3('Today', 'Aaj', 'آج');
    if (diff.inDays == 1) return locale.t3('1 day ago', '1 din pehle', '1 دن پہلے');
    return locale.t3('${diff.inDays} days ago', '${diff.inDays} din pehle', '${diff.inDays} دن پہلے');
  }

  String _currentLangLabel(LocaleService locale) {
    if (locale.isEnglish) return locale.t3('Current: English', 'Current: English', 'ابھی: انگریزی');
    if (locale.isUrdu) return locale.t3('Current: Urdu', 'Current: Urdu', 'ابھی: اردو');
    return locale.t3('Current: Roman Urdu', 'Current: Roman Urdu', 'ابھی: رومن اردو');
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleService>();

    final firebaseUser = FirebaseAuthService.instance.currentUser;
    final isGoogleUser = firebaseUser != null;
    final displayName = isGoogleUser
        ? (firebaseUser.displayName ?? firebaseUser.email ?? 'User')
        : _offlineName;
    final displayEmail = isGoogleUser ? firebaseUser.email ?? '' : '';
    final photoUrl = firebaseUser?.photoURL;

    final initials = displayName.trim().isNotEmpty
        ? displayName.trim().split(' ').map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').take(2).join()
        : 'U';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        AppHeader(
          title: locale.t3('Settings', 'Settings', 'ترتیبات'),
          subtitle: locale.t3('Account, security & data', 'Account, security & data', 'اکاؤنٹ، سیکیورٹی اور ڈیٹا'),
        ),
        Expanded(child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
          children: [
            // ── Backup Alert ──
            if (_backupNeeded) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFED7AA)),
                ),
                child: Row(children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFEA580C), size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      locale.t3('Backup required!', 'Backup lena zaruri hai!', 'بیک اپ لینا ضروری ہے!'),
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: const Color(0xFF9A3412)),
                    ),
                    Text(
                      locale.t3(
                        '3+ days since last backup. Tap "Backup to Device".',
                        '3+ din se backup nahi liya. "Device pe Backup" tap karo.',
                        '3+ دن سے بیک اپ نہیں لیا۔ "ڈیوائس پر بیک اپ" ٹیپ کریں۔',
                      ),
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFC2410C), height: 1.4),
                    ),
                  ])),
                ]),
              ),
            ],

            // ── Language Toggle ──
            _SectionLabel(locale.t3('Language', 'Language', 'زبان')),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border), boxShadow: [AppColors.cardShadow]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(12)),
                    child: const Center(child: Text('🌐', style: TextStyle(fontSize: 22))),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(locale.t3('App Language', 'App Language', 'ایپ کی زبان'), style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.foreground)),
                    Text(_currentLangLabel(locale), style: GoogleFonts.inter(fontSize: 12, color: AppColors.mutedForeground)),
                  ])),
                ]),
                const SizedBox(height: 14),
                Row(children: [
                  _LangChip(label: 'English', selected: locale.isEnglish, onTap: () => locale.setLang(AppLang.english)),
                  const SizedBox(width: 8),
                  _LangChip(label: 'Roman Urdu', selected: locale.isRomanUrdu, onTap: () => locale.setLang(AppLang.romanUrdu)),
                  const SizedBox(width: 8),
                  _LangChip(label: 'اردو', selected: locale.isUrdu, onTap: () => locale.setLang(AppLang.urdu)),
                ]),
              ]),
            ),
            const SizedBox(height: 24),

            // ── Account Card ──
            _SectionLabel(locale.t3('Account', 'Account', 'اکاؤنٹ')),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border), boxShadow: [AppColors.cardShadow]),
              child: Row(children: [
                if (photoUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.network(photoUrl, width: 54, height: 54, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _AvatarBox(initials: initials),
                    ),
                  )
                else
                  _AvatarBox(initials: initials),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(displayName, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.foreground)),
                  if (isGoogleUser && displayEmail.isNotEmpty)
                    Text(displayEmail, style: GoogleFonts.inter(fontWeight: FontWeight.w400, fontSize: 11.5, color: AppColors.mutedForeground, height: 1.4))
                  else
                    Text(
                      locale.t3('Offline Mode — data only on this device', 'Offline Mode — data sirf is device par', 'آف لائن موڈ — ڈیٹا صرف اس ڈیوائس پر'),
                      style: GoogleFonts.inter(fontWeight: FontWeight.w400, fontSize: 11.5, color: AppColors.mutedForeground, height: 1.4),
                    ),
                ])),
                if (!isGoogleUser)
                  GestureDetector(
                    onTap: _editName,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(10)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.edit_outlined, size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(locale.t3('Edit', 'Edit', 'ترمیم'), style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.primary)),
                      ]),
                    ),
                  ),
              ]),
            ),
            const SizedBox(height: 24),

            // ── Security ──
            _SectionLabel(locale.t3('Security', 'Security', 'سیکیورٹی')),
            _Tile(
              icon: Icons.grid_view_outlined,
              title: locale.t3('Pattern Lock', 'Pattern Lock', 'پیٹرن لاک'),
              subtitle: _patternEnabled
                  ? locale.t3('Enabled — tap to disable', 'Chalu hai — band karne ke liye tap karo', 'چالو ہے — بند کرنے کے لیے ٹیپ کریں')
                  : locale.t3('Disabled — tap to enable', 'Band hai — chalane ke liye tap karo', 'بند ہے — چالو کرنے کے لیے ٹیپ کریں'),
              trailing: Switch(value: _patternEnabled, onChanged: (_) => _togglePattern(), activeColor: AppColors.primary),
            ),
            if (_patternEnabled) _Tile(
              icon: Icons.refresh_outlined,
              title: locale.t3('Change Pattern', 'Pattern Tabdeel Karo', 'پیٹرن تبدیل کریں'),
              subtitle: locale.t3('Set a new unlock pattern', 'Naya unlock pattern banao', 'نیا انلاک پیٹرن بنائیں'),
              onTap: _changePattern,
            ),
            const SizedBox(height: 24),

            // ── Local Backup ──
            _SectionLabel(locale.t3('Local Backup (Device)', 'Local Backup (Device)', 'مقامی بیک اپ (ڈیوائس)')),
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.tint.withOpacity(0.2)),
              ),
              child: Row(children: [
                const Icon(Icons.history, size: 15, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  '${locale.t3("Last backup", "Last backup", "آخری بیک اپ")}: ${_formatBackupDate(_lastBackupDate, locale)}',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
                )),
                if (_backupNeeded)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFEA580C), borderRadius: BorderRadius.circular(6)),
                    child: Text(locale.t3('Required!', 'Zaruri!', 'ضروری!'), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
              ]),
            ),
            _Tile(icon: Icons.upload_outlined, title: locale.t3('Backup to Device', 'Device pe Backup', 'ڈیوائس پر بیک اپ'), subtitle: locale.t3('Download JSON file', 'JSON file download karo', 'JSON فائل ڈاؤن لوڈ کریں'), loading: _loadingBackupLocal, onTap: _backupLocal),
            _Tile(icon: Icons.download_outlined, title: locale.t3('Restore from Device', 'Device se Restore', 'ڈیوائس سے ریسٹور'), subtitle: locale.t3('Import data from JSON file', 'JSON file se data wapas lao', 'JSON فائل سے ڈیٹا واپس لائیں'), loading: _loadingRestoreLocal, onTap: _restoreLocal),
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

class _AvatarBox extends StatelessWidget {
  final String initials;
  const _AvatarBox({required this.initials});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54, height: 54,
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(15)),
      child: Center(child: Text(initials, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.accent))),
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
