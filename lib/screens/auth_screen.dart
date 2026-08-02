import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/app_fonts.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLoading = false;
  bool _isGuestLoading = false;

  bool get _isBusy => _isLoading || _isGuestLoading;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      await context.read<AuthProvider>().signInWithGoogle();
    } catch (error) {
      if (!mounted) return;
      final message = error.toString();
      if (!message.contains('cancelled') && !message.contains('canceled')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('sign_in_error'.tr()),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGuestSignIn() async {
    setState(() => _isGuestLoading = true);
    try {
      await context.read<AuthProvider>().continueAsGuest();
    } finally {
      if (mounted) setState(() => _isGuestLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const violet = Color(0xFF8B5CF6);
    const cyan = Color(0xFF22D3EE);
    final background =
        isDark ? const Color(0xFF080A12) : const Color(0xFFF2F5FA);
    final surface = isDark
        ? const Color(0xFF141824).withValues(alpha: 0.92)
        : Colors.white.withValues(alpha: 0.94);
    final primaryText =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827);
    final secondaryText =
        isDark ? const Color(0xFFA8B0C2) : const Color(0xFF64748B);
    final border =
        isDark ? Colors.white.withValues(alpha: 0.10) : const Color(0xFFCBD5E1);

    return Scaffold(
      backgroundColor: background,
      body: Stack(
        children: [
          Positioned(
            top: -120,
            right: -100,
            child: _AmbientGlow(color: violet, size: 330),
          ),
          Positioned(
            bottom: -130,
            left: -120,
            child: _AmbientGlow(color: cyan, size: 360),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 44,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const _BrandMark(),
                            const SizedBox(height: 24),
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Pomodoro ',
                                    style: TextStyle(color: primaryText),
                                  ),
                                  const TextSpan(
                                    text: 'Elite',
                                    style: TextStyle(color: cyan),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                              style: AppFonts.poppins(
                                context: context,
                                fontSize: 34,
                                height: 1.1,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1.2,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'focus_grow_achieve'.tr(),
                              textAlign: TextAlign.center,
                              style: AppFonts.poppins(
                                context: context,
                                color: secondaryText,
                                fontSize: 14,
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 34),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: surface,
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(color: border),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: isDark ? 0.30 : 0.09,
                                    ),
                                    blurRadius: 34,
                                    offset: const Offset(0, 18),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    height: 58,
                                    child: FilledButton(
                                      onPressed:
                                          _isBusy ? null : _handleGoogleSignIn,
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        disabledBackgroundColor: Colors.white
                                            .withValues(alpha: 0.65),
                                        foregroundColor:
                                            const Color(0xFF171A22),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(18),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.2,
                                                color: Color(0xFF2563EB),
                                              ),
                                            )
                                          : Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Image.asset(
                                                  'assets/icons/google.png',
                                                  width: 23,
                                                  height: 23,
                                                ),
                                                const SizedBox(width: 12),
                                                Flexible(
                                                  child: Text(
                                                    'continue_with_google'.tr(),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.fade,
                                                    softWrap: false,
                                                    style: AppFonts.poppins(
                                                      context: context,
                                                      color: const Color(
                                                        0xFF171A22,
                                                      ),
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(child: Divider(color: border)),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                          ),
                                          child: Text(
                                            'or'.tr(),
                                            style: AppFonts.poppins(
                                              context: context,
                                              color: secondaryText,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        Expanded(child: Divider(color: border)),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: OutlinedButton.icon(
                                      onPressed:
                                          _isBusy ? null : _handleGuestSignIn,
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: primaryText,
                                        disabledForegroundColor: secondaryText
                                            .withValues(alpha: 0.5),
                                        side: BorderSide(color: border),
                                        backgroundColor: primaryText.withValues(
                                          alpha: isDark ? 0.045 : 0.025,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(18),
                                        ),
                                      ),
                                      icon: _isGuestLoading
                                          ? SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: secondaryText,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.person_outline_rounded,
                                              size: 21,
                                            ),
                                      label: Text(
                                        'continue_as_guest'.tr(),
                                        style: AppFonts.poppins(
                                          context: context,
                                          color: _isBusy
                                              ? secondaryText.withValues(
                                                  alpha: 0.5)
                                              : primaryText,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 22),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: cyan.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: cyan.withValues(alpha: 0.18),
                                ),
                              ),
                              child: Text(
                                'v3.3.1',
                                style: AppFonts.poppins(
                                  context: context,
                                  color: secondaryText,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 86,
      height: 86,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFA78BFA), Color(0xFF7C3AED), Color(0xFF22D3EE)],
        ),
        borderRadius: BorderRadius.circular(27),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.34),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: const Icon(
        Icons.timer_rounded,
        color: Colors.white,
        size: 43,
      ),
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.22),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
