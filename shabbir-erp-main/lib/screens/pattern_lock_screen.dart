import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../services/security_service.dart';
import '../widgets/app_header.dart';
import '../widgets/pattern_input.dart';

enum PatternLockMode { set, verify, change }

class PatternLockScreen extends StatefulWidget {
  final PatternLockMode mode;
  final VoidCallback onSuccess;
  final VoidCallback? onCancel;

  const PatternLockScreen(
      {super.key,
      required this.mode,
      required this.onSuccess,
      this.onCancel});

  @override
  State<PatternLockScreen> createState() => _PatternLockScreenState();
}

class _PatternLockScreenState extends State<PatternLockScreen> {
  String? _firstPattern;
  String _statusText = '';
  bool _error = false;
  bool _loading = false;
  int _attempts = 0;

  @override
  void initState() {
    super.initState();
    _statusText = _initialStatus();
  }

  String _initialStatus() {
    switch (widget.mode) {
      case PatternLockMode.set:
        return 'Draw a new pattern (minimum 4 dots)';
      case PatternLockMode.verify:
        return 'Draw your pattern to unlock';
      case PatternLockMode.change:
        return 'Draw your current pattern first';
    }
  }

  Future<void> _onPatternComplete(String pattern) async {
    if (_loading) return;
    setState(() => _loading = true);

    if (widget.mode == PatternLockMode.verify) {
      final ok = await SecurityService.instance.verifyPattern(pattern);
      if (ok) {
        setState(() => _loading = false);
        widget.onSuccess();
      } else {
        _attempts++;
        setState(() {
          _error = true;
          _loading = false;
          _statusText = 'Incorrect pattern. Try again ($_attempts/5)';
        });
        await Future.delayed(const Duration(milliseconds: 700));
        if (mounted) {
          setState(() {
            _error = false;
            _statusText = 'Draw your pattern to unlock';
          });
        }
      }
      return;
    }

    if (widget.mode == PatternLockMode.change &&
        (_firstPattern == null || _firstPattern == '__pending__')) {
      if (_firstPattern != '__pending__') {
        final ok = await SecurityService.instance.verifyPattern(pattern);
        if (!ok) {
          setState(() {
            _error = true;
            _loading = false;
            _statusText = 'Incorrect current pattern';
          });
          await Future.delayed(const Duration(milliseconds: 700));
          if (mounted) {
            setState(() {
              _error = false;
              _statusText = 'Draw your current pattern first';
            });
          }
          return;
        }
        setState(() {
          _firstPattern = '__pending__';
          _loading = false;
          _statusText = 'Now draw your new pattern';
        });
        return;
      }
    }

    if (_firstPattern == null || _firstPattern == '__pending__') {
      setState(() {
        _firstPattern = pattern;
        _loading = false;
        _statusText = 'Draw the same pattern again to confirm';
      });
      return;
    }

    if (_firstPattern == pattern) {
      await SecurityService.instance.setPattern(pattern);
      setState(() => _loading = false);
      widget.onSuccess();
    } else {
      setState(() {
        _firstPattern = null;
        _error = true;
        _loading = false;
        _statusText = "Patterns don't match. Try again.";
      });
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        setState(() {
          _error = false;
          _statusText = _initialStatus();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const SizedBox(height: 32),
              ShabbirLogo(
                size: 64,
                bgColor: AppColors.accent,
                textColor: AppColors.primary,
                badgeColor: AppColors.primary,
              ),
              const SizedBox(height: 14),
              Text('Shabbir ERP',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                      color: Colors.white)),
              const SizedBox(height: 4),
              Text(
                'Powered by Shabbir Ahmed',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w400,
                    fontSize: 11,
                    color: Colors.white38),
              ),
              const SizedBox(height: 6),
              Text(
                widget.mode == PatternLockMode.verify
                    ? 'Secure Access'
                    : widget.mode == PatternLockMode.set
                        ? 'Set Pattern Lock'
                        : 'Change Pattern',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    color: Colors.white60),
              ),
              const SizedBox(height: 32),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: _error
                      ? AppColors.destructive.withOpacity(0.25)
                      : Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: _error
                          ? AppColors.destructive.withOpacity(0.5)
                          : Colors.transparent),
                ),
                child: Text(
                  _statusText,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: _error
                          ? const Color(0xFFFCA5A5)
                          : Colors.white70),
                ),
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _loading
                    ? const CircularProgressIndicator(color: AppColors.accent)
                    : PatternInput(
                        key: ValueKey('${_firstPattern}_$_error'),
                        onComplete: _onPatternComplete,
                        activeColor:
                            _error ? AppColors.destructive : AppColors.accent,
                      ),
              ),
              const Spacer(),
              if (widget.onCancel != null)
                TextButton(
                  onPressed: widget.onCancel,
                  child: Text('Cancel',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.white54)),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
