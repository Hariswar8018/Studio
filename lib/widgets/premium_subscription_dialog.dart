import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/iap_service.dart';
import '../services/analytics_service.dart';
import '../services/theme_service.dart';

class PremiumSubscriptionDialog extends StatefulWidget {
  const PremiumSubscriptionDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const PremiumSubscriptionDialog(),
    );
  }

  @override
  State<PremiumSubscriptionDialog> createState() => _PremiumSubscriptionDialogState();
}

class _PremiumSubscriptionDialogState extends State<PremiumSubscriptionDialog> {
  // 0: Monthly, 1: Yearly (Default / Best Value)
  int _selectedPlan = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final analytics = Provider.of<AnalyticsService>(context, listen: false);
        analytics.logPaywallViewed(source: 'premium_dialog');
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final iap = Provider.of<IapService>(context);
    final theme = Provider.of<ThemeService>(context);
    final isDark = theme.isDarkMode;

    final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? Colors.white70 : const Color(0xFF64748B);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: bgColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with Crown Icon
            Center(
              child: Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.star_rounded, color: Colors.white, size: 38),
              ),
            ),
            const SizedBox(height: 18),

            Text(
              'LangNova Premium',
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Master Japanese with 100% unlocked content & zero ads',
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(
                fontSize: 13,
                color: subtextColor,
              ),
            ),
            const SizedBox(height: 20),

            // Benefits
            _buildFeatureRow(
              icon: Icons.lock_open_rounded,
              color: const Color(0xFFF59E0B),
              title: 'Unlock 100% of All Lessons',
              subtitle: 'Full access to all 60% locked Grammar, Vocab, and Kanji lessons',
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _buildFeatureRow(
              icon: Icons.block_rounded,
              color: const Color(0xFFEF4444),
              title: '100% Ad-Free Experience',
              subtitle: 'Zero interstitial or native ads anywhere across the entire app',
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _buildFeatureRow(
              icon: Icons.draw_rounded,
              color: const Color(0xFF8B5CF6),
              title: 'Interactive Kanji Drawing & SRS',
              subtitle: 'Stroke order animations, canvas drawing & discrimination reviews',
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _buildFeatureRow(
              icon: Icons.insights_rounded,
              color: const Color(0xFF10B981),
              title: 'Full Metrics & Analytics',
              subtitle: 'Track your JLPT N5–N1 mastery breakdowns and progress curves',
              isDark: isDark,
            ),
            const SizedBox(height: 22),

            if (iap.isPremium) ...[
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF10B981), width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Premium Active!',
                      style: GoogleFonts.fredoka(
                        color: const Color(0xFF10B981),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close', style: GoogleFonts.fredoka(color: subtextColor)),
              ),
            ] else ...[
              // Plan Selector Cards: Monthly vs Yearly
              Row(
                children: [
                  // Monthly Card
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => setState(() => _selectedPlan = 0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                        decoration: BoxDecoration(
                          color: _selectedPlan == 0
                              ? const Color(0xFF6366F1).withValues(alpha: 0.12)
                              : (isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _selectedPlan == 0 ? const Color(0xFF6366F1) : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Monthly',
                              style: GoogleFonts.fredoka(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              iap.monthlyPriceString,
                              style: GoogleFonts.fredoka(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF6366F1),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Billed monthly',
                              style: GoogleFonts.fredoka(fontSize: 10, color: subtextColor),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Yearly Card (Best Value)
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => setState(() => _selectedPlan = 1),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                            decoration: BoxDecoration(
                              color: _selectedPlan == 1
                                  ? const Color(0xFFF59E0B).withValues(alpha: 0.12)
                                  : (isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _selectedPlan == 1 ? const Color(0xFFF59E0B) : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Yearly',
                                  style: GoogleFonts.fredoka(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  iap.yearlyPriceString,
                                  style: GoogleFonts.fredoka(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFF59E0B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Save over 35%',
                                  style: GoogleFonts.fredoka(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: -9,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                                ),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Text(
                                'BEST VALUE',
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Subscribe CTA Button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedPlan == 1 ? const Color(0xFFF59E0B) : const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: iap.isLoading
                      ? null
                      : () async {
                          final planName = _selectedPlan == 1 ? 'yearly' : 'monthly';
                          try {
                            final analytics = Provider.of<AnalyticsService>(context, listen: false);
                            analytics.logEvent('subscription_checkout_started', parameters: {'plan': planName});
                          } catch (_) {}
                          try {
                            if (_selectedPlan == 1) {
                              await iap.buyYearlySubscription();
                            } else {
                              await iap.buyMonthlySubscription();
                            }
                            if (context.mounted && iap.isPremium) {
                              try {
                                final analytics = Provider.of<AnalyticsService>(context, listen: false);
                                analytics.logSubscriptionPurchased(planId: planName);
                              } catch (_) {}
                              Navigator.pop(context);
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('$e')),
                              );
                            }
                          }
                        },
                  child: iap.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Subscribe for ${_selectedPlan == 1 ? iap.yearlyPriceString : iap.monthlyPriceString}',
                          style: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 10),

              // Restore / Cancel
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Not Now', style: GoogleFonts.fredoka(color: subtextColor, fontSize: 13)),
                  ),
                  TextButton(
                    onPressed: () async {
                      await iap.restorePurchases();
                    },
                    child: Text(
                      'Restore Purchases',
                      style: GoogleFonts.fredoka(
                        color: const Color(0xFF6366F1),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.fredoka(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.fredoka(
                  fontSize: 11,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
