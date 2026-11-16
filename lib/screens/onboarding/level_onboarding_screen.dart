import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/database_service.dart';
import '../../services/theme_service.dart';
import '../home/home_screen.dart';

class LevelOnboardingScreen extends StatefulWidget {
  const LevelOnboardingScreen({super.key});

  @override
  State<LevelOnboardingScreen> createState() => _LevelOnboardingScreenState();
}

class _LevelOnboardingScreenState extends State<LevelOnboardingScreen> {
  String _selectedLevel = 'N2';

  static const List<Map<String, dynamic>> _jlptLevels = [
    {
      'level': 'N5',
      'title': 'Beginner',
      'desc': 'Basic Japanese, Hiragana/Katakana & daily greetings',
      'color': Color(0xFF10B981),
      'badge': 'Starter',
    },
    {
      'level': 'N4',
      'title': 'Elementary',
      'desc': 'Fundamental grammar, everyday conversations & essential vocab',
      'color': Color(0xFF06B6D4),
      'badge': 'Elementary',
    },
    {
      'level': 'N3',
      'title': 'Intermediate',
      'desc': 'Bridge to fluency, natural nuances & diverse collocations',
      'color': Color(0xFF6366F1),
      'badge': 'Intermediate',
    },
    {
      'level': 'N2',
      'title': 'Pre-Advanced',
      'desc': 'Business & academic Japanese, sophisticated grammar & kanji',
      'color': Color(0xFF8B5CF6),
      'badge': 'Recommended',
    },
    {
      'level': 'N1',
      'title': 'Advanced',
      'desc': 'Native-level depth, complex expressions & rare kanji compounds',
      'color': Color(0xFFEC4899),
      'badge': 'Mastery',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeService>(context);
    final isDark = theme.isDarkMode;

    final bgColor = isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? Colors.white70 : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              // App Branding Header
              Center(
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.school_rounded, color: Colors.white, size: 30),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'LangNova',
                textAlign: TextAlign.center,
                style: GoogleFonts.fredoka(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Japanese Language • Grammar, Vocab & Kanji',
                textAlign: TextAlign.center,
                style: GoogleFonts.fredoka(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6366F1),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Choose your target JLPT level to personalize your lessons',
                textAlign: TextAlign.center,
                style: GoogleFonts.fredoka(
                  fontSize: 13,
                  color: subtextColor,
                ),
              ),
              const SizedBox(height: 18),

              // Level Cards
              Expanded(
                child: ListView.builder(
                  itemCount: _jlptLevels.length,
                  itemBuilder: (context, index) {
                    final item = _jlptLevels[index];
                    final level = item['level'] as String;
                    final isSelected = _selectedLevel == level;
                    final color = item['color'] as Color;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => setState(() => _selectedLevel = level),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withValues(alpha: isDark ? 0.2 : 0.08)
                                : cardColor,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isSelected ? color : (isDark ? Colors.white12 : Colors.grey.shade200),
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected
                                    ? color.withValues(alpha: 0.15)
                                    : Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                                blurRadius: isSelected ? 10 : 4,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isSelected ? color : color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  level,
                                  style: GoogleFonts.fredoka(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : color,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          item['title'],
                                          style: GoogleFonts.fredoka(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: color.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            item['badge'],
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: color,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      item['desc'],
                                      style: GoogleFonts.fredoka(
                                        fontSize: 12,
                                        color: subtextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                color: isSelected ? color : subtextColor.withValues(alpha: 0.4),
                                size: 24,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Continue Button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () async {
                    final db = Provider.of<DatabaseService>(context, listen: false);
                    await db.setSelectedLevel(_selectedLevel);
                    if (!context.mounted) return;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Start Learning $_selectedLevel',
                        style: GoogleFonts.fredoka(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }
}

