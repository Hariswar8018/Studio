import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/analytics_service.dart';
import '../../services/iap_service.dart';
import '../../services/theme_service.dart';
import '../../services/tts_service.dart';
import '../../widgets/app_native_ad_widget.dart';
import '../../widgets/app_recommend_widget.dart';
import '../../widgets/premium_subscription_dialog.dart';
import '../admin/admin_upload_screen.dart';
import '../auth/login_screen.dart';
import '../progress/grammar_metrics_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final theme = Provider.of<ThemeService>(context);
    final tts = Provider.of<TtsService>(context);
    final db = Provider.of<DatabaseService>(context);
    final isDark = theme.isDarkMode;
    final iap = Provider.of<IapService>(context);

    final bgColor = isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? Colors.white70 : const Color(0xFF64748B);

    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: bgColor,
      bottomNavigationBar: const AppNativeAdWidget(
        compact: true,
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings & Profile',
          style: GoogleFonts.fredoka(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFF6366F1),
                  child: Text(
                    user != null && user.displayName.isNotEmpty
                        ? user.displayName[0].toUpperCase()
                        : 'U',
                    style: GoogleFonts.fredoka(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ?? 'Learner',
                        style: GoogleFonts.fredoka(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.email ?? 'No email',
                        style: GoogleFonts.fredoka(
                          fontSize: 13,
                          color: subtextColor,
                        ),
                      ),
                      
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Subscription & Analytics Section
          Text(
            'Membership & Analytics',
            style: GoogleFonts.fredoka(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: subtextColor,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 22),
                  ),
                  title: Text(
                    'Monthly Premium',
                    style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, color: textColor),
                  ),
                  subtitle: Text(
                    iap.isPremium
                        ? 'Active • All ads removed'
                        : 'Subscribe for ${iap.monthlyPriceString} to remove all ads',
                    style: GoogleFonts.fredoka(
                      fontSize: 12,
                      color: iap.isPremium ? const Color(0xFF10B981) : subtextColor,
                      fontWeight: iap.isPremium ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  onTap: () => PremiumSubscriptionDialog.show(context),
                ),
                Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey.shade100),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.insights_rounded, color: Color(0xFF6366F1), size: 22),
                  ),
                  title: Text(
                    'Full Metrics & Analytics',
                    style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, color: textColor),
                  ),
                  subtitle: Text(
                    'Mastery breakdown across Grammar, Vocabulary & Kanji',
                    style: GoogleFonts.fredoka(fontSize: 12, color: subtextColor),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const GrammarMetricsScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Appearance Section
          Text(
            'Appearance',
            style: GoogleFonts.fredoka(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: subtextColor,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
            ),
            child: SwitchListTile(
              secondary: Icon(
                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: const Color(0xFF6366F1),
              ),
              title: Text('Dark Mode', style: GoogleFonts.fredoka(color: textColor, fontWeight: FontWeight.bold)),
              subtitle: Text(
                isDark ? 'Dark theme enabled' : 'Light theme enabled',
                style: GoogleFonts.fredoka(fontSize: 12, color: subtextColor),
              ),
              value: isDark,
              onChanged: (val) => theme.toggleTheme(),
            ),
          ),
          const SizedBox(height: 20),

          // Audio & Speech Synthesizer Section
          Text(
            'Japanese Speech Synthesizer',
            style: GoogleFonts.fredoka(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: subtextColor,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 2-Way Engine Selector: Local TTS vs Azure TTS
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      // Local TTS Option
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => tts.setEngine(TtsEngine.local),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: !tts.isAzure
                                  ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: !tts.isAzure
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.phone_android_rounded,
                                  size: 16,
                                  color: !tts.isAzure ? const Color(0xFF6366F1) : subtextColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Local TTS',
                                  style: GoogleFonts.fredoka(
                                    fontSize: 13,
                                    fontWeight: !tts.isAzure ? FontWeight.bold : FontWeight.w600,
                                    color: !tts.isAzure ? textColor : subtextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),

                      // Azure TTS Option
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => tts.setEngine(TtsEngine.azure),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: tts.isAzure
                                  ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: tts.isAzure
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.cloud_rounded,
                                  size: 16,
                                  color: tts.isAzure ? const Color(0xFF6366F1) : subtextColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'LangNova TTS',
                                  style: GoogleFonts.fredoka(
                                    fontSize: 13,
                                    fontWeight: tts.isAzure ? FontWeight.bold : FontWeight.w600,
                                    color: tts.isAzure ? textColor : subtextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Engine details & Test Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        tts.isAzure
                            ? 'Engine: LangNova TTS ( Online )'
                            : 'Engine: Device TTS (Offline)',
                        style: GoogleFonts.fredoka(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.volume_up_rounded, size: 16),
                      label: Text('Test Audio', style: GoogleFonts.fredoka(fontSize: 12)),
                      onPressed: () => tts.speakJapanese('日本語の文法を練習しましょう！'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Speed Slider (For both engines!)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Speech Speed',
                      style: GoogleFonts.fredoka(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${tts.speechRate.toStringAsFixed(1)}x',
                        style: GoogleFonts.fredoka(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF6366F1),
                        ),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: tts.speechRate,
                  min: 0.5,
                  max: 1.5,
                  divisions: 10,
                  activeColor: const Color(0xFF6366F1),
                  onChanged: (v) => tts.setSpeechRate(v),
                ),

                // If Local TTS is selected, user can edit local TTS settings: voice and pitch!
                if (!tts.isAzure) ...[
                  const Divider(height: 20),
                  Text(
                    'Local Voice & Pitch Settings',
                    style: GoogleFonts.fredoka(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Installed Japanese Voices on Device
                  if (tts.localJapaneseVoices.isNotEmpty) ...[
                    DropdownButtonFormField<String>(
                      initialValue: tts.selectedLocalVoice.isNotEmpty &&
                              tts.localJapaneseVoices.any((v) => v['name'] == tts.selectedLocalVoice)
                          ? tts.selectedLocalVoice
                          : (tts.localJapaneseVoices.first['name']),
                      decoration: InputDecoration(
                        labelText: 'Installed Japanese Voice',
                        labelStyle: GoogleFonts.fredoka(fontSize: 12, color: subtextColor),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: tts.localJapaneseVoices.map((v) {
                        final name = v['name'] ?? '';
                        return DropdownMenuItem<String>(
                          value: name,
                          child: Text(
                            name,
                            style: GoogleFonts.fredoka(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) tts.setLocalVoice(v);
                      },
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Pitch Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Voice Pitch',
                        style: GoogleFonts.fredoka(fontSize: 12, color: subtextColor),
                      ),
                      Text(
                        '${tts.pitch.toStringAsFixed(1)}x',
                        style: GoogleFonts.fredoka(fontSize: 11, color: subtextColor),
                      ),
                    ],
                  ),
                  Slider(
                    value: tts.pitch,
                    min: 0.7,
                    max: 1.3,
                    divisions: 6,
                    activeColor: const Color(0xFF10B981),
                    onChanged: (v) => tts.setPitch(v),
                  ),
                ],
              ],
            ),
          ),
          // Admin Management Section (if admin)
          if (auth.isAdmin) ...[
            const SizedBox(height: 20),
            Text(
              'Admin Studio',
              style: GoogleFonts.fredoka(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFFEF4444), size: 22),
                ),
                title: Text(
                  'Admin JSON Studio & File Upload',
                  style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, color: textColor),
                ),
                subtitle: Text(
                  'Upload JSON files directly for Grammar, Kanji & Vocab, or edit live schema',
                  style: GoogleFonts.fredoka(fontSize: 12, color: subtextColor),
                ),
                trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminUploadScreen()),
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Recommended Companion Listening App
          AppRecommendWidget(isDark: isDark),

          const SizedBox(height: 20),

          // Database & Progress
          Text(
            'Data & Spaced Repetition',
            style: GoogleFonts.fredoka(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: subtextColor,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.sync_rounded, color: Color(0xFF10B981)),
                  title: Text('Reload Remote Topics', style: GoogleFonts.fredoka(color: textColor, fontWeight: FontWeight.bold)),
                  subtitle: Text('Sync from Firestore', style: GoogleFonts.fredoka(fontSize: 12, color: subtextColor)),
                  onTap: () async {
                    await db.loadTopics();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Topics reloaded (${db.topics.length} loaded)')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Log Out Button
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                side: const BorderSide(color: Color(0xFFEF4444)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: Text('Sign Out', style: GoogleFonts.fredoka(fontWeight: FontWeight.bold)),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text('Sign Out', style: GoogleFonts.fredoka(fontWeight: FontWeight.bold)),
                    content: Text('Are you sure you want to sign out?', style: GoogleFonts.fredoka()),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );

                if (!context.mounted) return;
                if (confirm == true) {
                  try {
                    final analytics = Provider.of<AnalyticsService>(context, listen: false);
                    analytics.logEvent('logout');
                    analytics.setUserId(null);
                  } catch (_) {}
                  await auth.signOut();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (r) => false,
                    );
                  }
                }
              },
            ),
          ),
          const SizedBox(height: 24),

          // App Info & Logo Card
          Center(
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/image.png',
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'JLPT Language Studio',
                  style: GoogleFonts.fredoka(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Text(
                  'Version 1.0.0 (Build 1)',
                  style: GoogleFonts.fredoka(
                    fontSize: 12,
                    color: subtextColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}


