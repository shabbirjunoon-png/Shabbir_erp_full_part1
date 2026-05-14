import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../services/firebase_auth_service.dart';
import '../services/locale_service.dart';
import '../widgets/app_header.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLogin;
  const LoginScreen({super.key, required this.onLogin});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loadingGoogle = false;
  bool _loadingOffline = false;
  String? _error;

  Future<void> _loginWithGoogle() async {
    setState(() { _loadingGoogle = true; _error = null; });
    try {
      final result = await FirebaseAuthService.instance.signInWithGoogle();
      if (result != null && mounted) {
        widget.onLogin();
      } else if (mounted) {
        setState(() { _loadingGoogle = false; });
      }
    } catch (e) {
      if (mounted) {
        final locale = context.read<LocaleService>();
        setState(() {
          _error = locale.t3(
            'Google login failed. Please try again.',
            'Google login mein masla aaya. Dobara try karo.',
            'گوگل لاگ ان ناکام۔ دوبارہ کوشش کریں۔',
          );
          _loadingGoogle = false;
        });
      }
    }
  }

  Future<void> _loginOffline() async {
    setState(() { _loadingOffline = true; _error = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('offline_logged_in', true);
      if (mounted) widget.onLogin();
    } catch (e) {
      if (mounted) {
        final locale = context.read<LocaleService>();
        setState(() {
          _error = locale.t3(
            'Something went wrong, please try again.',
            'Kuch masla aaya, dobara try karo.',
            'کچھ مسئلہ آیا، دوبارہ کوشش کریں۔',
          );
          _loadingOffline = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final anyLoading = _loadingGoogle || _loadingOffline;
    final locale = context.watch<LocaleService>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height
                  - MediaQuery.of(context).padding.top
                  - MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),

                const ShabbirLogo(
                  size: 80,
                  bgColor: AppColors.primary,
                  textColor: AppColors.accent,
                  badgeColor: AppColors.accent,
                ),
                const SizedBox(height: 28),

                Text(
                  'Shabbir Ledger',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 34,
                    letterSpacing: -1.0,
                    color: AppColors.foreground,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  locale.t3(
                    'Business accounting, straight and simple.',
                    'Business accounting, seedha aur simple.',
                    'کاروباری حساب، سیدھا اور آسان۔',
                  ),
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: AppColors.mutedForeground,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 52),

                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.destructive.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.destructive.withOpacity(0.3)),
                    ),
                    child: Row(children: [
                      Icon(Icons.error_outline, size: 18, color: AppColors.destructive),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _error!,
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.destructive, height: 1.4),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 20),
                ],

                _SocialButton(
                  loading: _loadingGoogle,
                  disabled: anyLoading,
                  onPressed: _loginWithGoogle,
                  iconWidget: _GoogleIcon(),
                  label: locale.t3('Sign in with Google', 'Google se Login Karo', 'گوگل سے لاگ ان کریں'),
                  bgColor: Colors.white,
                  fgColor: const Color(0xFF3C4043),
                  borderColor: const Color(0xFFDADCE0),
                ),
                const SizedBox(height: 32),

                Row(children: [
                  Expanded(child: Divider(color: AppColors.border, thickness: 1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      locale.t3('Or', 'Ya phir', 'یا پھر'),
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.mutedForeground),
                    ),
                  ),
                  Expanded(child: Divider(color: AppColors.border, thickness: 1)),
                ]),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: anyLoading ? null : _loginOffline,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.foreground,
                      side: BorderSide(color: AppColors.border, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _loadingOffline
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_outline, size: 18, color: AppColors.mutedForeground),
                              const SizedBox(width: 8),
                              Text(
                                locale.t3('Continue without account', 'Bina Account ke Jari Raho', 'بنا اکاؤنٹ کے جاری رہیں'),
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                  color: AppColors.mutedForeground,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 28),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.cloud_done_outlined, size: 18, color: AppColors.accent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          locale.t3(
                            'Sign in with Google to keep your account secure. Without an account, data is saved only on this device.',
                            'Google se login karo to account secure rahega. Bina account ke sirf is device pe save hoga.',
                            'گوگل سے لاگ ان کریں تا کہ اکاؤنٹ محفوظ رہے۔ بنا اکاؤنٹ کے صرف اس ڈیوائس پر۔',
                          ),
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.mutedForeground, height: 1.6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final bool loading;
  final bool disabled;
  final VoidCallback onPressed;
  final Widget iconWidget;
  final String label;
  final Color bgColor;
  final Color fgColor;
  final Color borderColor;

  const _SocialButton({
    required this.loading,
    required this.disabled,
    required this.onPressed,
    required this.iconWidget,
    required this.label,
    required this.bgColor,
    required this.fgColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: disabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          disabledBackgroundColor: bgColor.withOpacity(0.55),
          elevation: 0,
          side: BorderSide(color: borderColor, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          shadowColor: Colors.transparent,
        ),
        child: loading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: fgColor),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  iconWidget,
                  const SizedBox(width: 12),
                  Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15, color: fgColor)),
                ],
              ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    final colors = [
      const Color(0xFF4285F4),
      const Color(0xFF34A853),
      const Color(0xFFFBBC05),
      const Color(0xFFEA4335),
    ];
    final starts = [0.0, 90.0, 180.0, 270.0];

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.22;

    for (int i = 0; i < 4; i++) {
      paint.color = colors[i];
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.74),
        _deg(starts[i] + 5),
        _deg(80),
        false,
        paint,
      );
    }

    final gapPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(cx, cy - size.height * 0.12, r * 0.82, size.height * 0.24),
      gapPaint,
    );
  }

  double _deg(double d) => d * 3.14159265 / 180;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
