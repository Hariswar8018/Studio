import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/analytics_service.dart';
import '../auth/login_screen.dart';
import '../home/home_screen.dart';

class JlptLevelSelectionScreen extends StatefulWidget {
  const JlptLevelSelectionScreen({super.key});

  @override
  State<JlptLevelSelectionScreen> createState() => _JlptLevelSelectionScreenState();
}

class _JlptLevelSelectionScreenState extends State<JlptLevelSelectionScreen> {
  final List<JlptLevelInfo> _levels = const [
    JlptLevelInfo(
      level: 'N1',
      title: 'JLPT N1',
      subtitle: 'Advanced Level • Complex expressions & native mastery',
      badgeColor: Color(0xFFEF4444),
    ),
    JlptLevelInfo(
      level: 'N2',
      title: 'JLPT N2',
      subtitle: 'Pre-Advanced • Business & everyday sophisticated Japanese',
      badgeColor: Color(0xFFF59E0B),
    ),
    JlptLevelInfo(
      level: 'N3',
      title: 'JLPT N3',
      subtitle: 'Intermediate • Natural speed conversation & solid grammar',
      badgeColor: Color(0xFF10B981),
    ),
    JlptLevelInfo(
      level: 'N4',
      title: 'JLPT N4',
      subtitle: 'Elementary • Basic daily topics & fundamental patterns',
      badgeColor: Color(0xFF4087E1),
    ),
    JlptLevelInfo(
      level: 'N5',
      title: 'JLPT N5',
      subtitle: 'Beginner Level • Core foundations, hiragana/katakana & basics',
      badgeColor: Color(0xFF8B5CF6),
    ),
  ];

  String _selectedLevel = 'N2';

  Future<void> _selectLevelAndComplete(String level) async {
    setState(() {
      _selectedLevel = level;
    });

    final db = Provider.of<DatabaseService>(context, listen: false);
    final analytics = Provider.of<AnalyticsService>(context, listen: false);
    final auth = Provider.of<AuthService>(context, listen: false);
    await db.setSelectedLevel(level);
    await db.setOnboardingCompleted(true);

    try {
      analytics.logLevelSelected(level: level);
      analytics.logEvent('onboarding_level_selected', parameters: {'level': level});
    } catch (_) {}

    if (mounted) {
      final nextWidget = auth.currentUser != null ? const HomeScreen() : const LoginScreen();
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => nextWidget,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: Text(
          'Select JLPT Target Level',
          style: GoogleFonts.fredoka(
            color: const Color(0xFF0F172A),
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Choose Your Target Level',
                style: GoogleFonts.fredoka(
                  color: const Color(0xFF0F172A),
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Select the official JLPT exam level you are preparing to master:',
                style: GoogleFonts.fredoka(
                  color: const Color(0xFF64748B),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: ListView.builder(
                  itemCount: _levels.length,
                  itemBuilder: (context, index) {
                    final item = _levels[index];
                    final isSelected = _selectedLevel == item.level;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF4087E1) : const Color(0xFFE2E8F0),
                          width: isSelected ? 2.0 : 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: ListTile(
                        onTap: () => _selectLevelAndComplete(item.level),
                        contentPadding: const EdgeInsets.all(12),
                        leading: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: item.badgeColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: item.badgeColor.withValues(alpha: 0.35), width: 1.5),
                          ),
                          child: Center(
                            child: Text(
                              item.level,
                              style: TextStyle(
                                color: item.badgeColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: item.badgeColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item.level,
                                style: TextStyle(
                                  color: item.badgeColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            item.subtitle,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                            ),
                          ),
                        ),
                        trailing: Icon(
                          isSelected ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
                          color: isSelected ? const Color(0xFF4087E1) : const Color(0xFF94A3B8),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class JlptLevelInfo {
  final String level;
  final String title;
  final String subtitle;
  final Color badgeColor;

  const JlptLevelInfo({
    required this.level,
    required this.title,
    required this.subtitle,
    required this.badgeColor,
  });
}

