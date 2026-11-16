import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'jlpt_level_selection_screen.dart';

class AppInfoOnboardingScreen extends StatefulWidget {
  const AppInfoOnboardingScreen({super.key});

  @override
  State<AppInfoOnboardingScreen> createState() => _AppInfoOnboardingScreenState();
}

class _AppInfoOnboardingScreenState extends State<AppInfoOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingSlideData> _slides = const [
    OnboardingSlideData(
      imageAsset: 'assets/onboarding1.png',
      title: 'Score 55+ in JLPT Language Section',
      subtitle:
          'Pass your JLPT exam with confidence! Master Japanese grammar, vocabulary, and kanji with high-scoring precision and exam readiness.',
    ),
    OnboardingSlideData(
      imageAsset: 'assets/onboarding2.png',
      title: 'Other Apps Lack Context Learning',
      subtitle:
          'Most apps teach words in isolation with only 1 sentence of practice, leaving you unprepared for real JLPT test contexts.',
    ),
    OnboardingSlideData(
      imageAsset: 'assets/onboarding3.png',
      title: 'Context Learning & 5+ Practice Sentences',
      subtitle:
          'Learn every word and grammar pattern in rich authentic context with 5+ sentences, and reinforce difficult words with Spaced Repetition.',
    ),
    OnboardingSlideData(
      imageAsset: 'assets/onboarding4.png',
      title: 'Upgrade Your Learning Experience',
      subtitle:
          'Enjoy studio neural audio voice, interactive Kanji stroke orders, live furigana toggles, and targeted weak-point drills.',
    ),
  ];

  void _goToNext() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    } else {
      _navigateToLevelSelection();
    }
  }

  void _navigateToLevelSelection() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const JlptLevelSelectionScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        // Top Left App Logo with slow subtle wiggle
        leading: Padding(
          padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
          child: SlowWiggleWidget(
            amplitude: 2.0,
            rotationDegrees: 1.0,
            durationSeconds: 5,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/app_logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.school_rounded,
                    color: Color(0xFF6366F1),
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ),
        actions: [
          // SKIP Button (Custom Pink #FC4F6B)
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 8),
            child: TextButton(
              onPressed: _navigateToLevelSelection,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFFC4F6B),
                backgroundColor: const Color(0xFFFFF1F2),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Color(0xFFFC4F6B), width: 1.5),
                ),
              ),
              child: const Text(
                'SKIP',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Carousel PageView with Image Asset rendering for each slide
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 12.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Wiggling Picture Holder
                        SlowWiggleWidget(
                          amplitude: 2.5,
                          rotationDegrees: 1.3,
                          durationSeconds: 6,
                          child: SizedBox(
                            width: 280,
                            height: 280,
                            child: Image.asset(
                              slide.imageAsset,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  Image.asset(
                                'assets/app_logo.png',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.image_rounded,
                                        size: 64,
                                        color: Color(0xFFCBD5E1),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        slide.imageAsset,
                                        style: const TextStyle(
                                          color: Color(0xFF94A3B8),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Title
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.fredoka(
                            color: const Color(0xFF0F172A),
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Subtitle Description
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            slide.subtitle,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.fredoka(
                              color: const Color(0xFF475569),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom controls bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Dot Indicators
                  Row(
                    children: List.generate(
                      _slides.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 6),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? const Color(0xFF4087E1)
                              : const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  // Next / Choose Level Button
                  ElevatedButton(
                    onPressed: _goToNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4087E1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentPage == _slides.length - 1
                              ? 'Choose Target Level'
                              : 'Next',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A lightweight widget that continuously wiggles its child with a very slow, tiny radius float motion.
class SlowWiggleWidget extends StatefulWidget {
  final Widget child;
  final double amplitude;
  final double rotationDegrees;
  final int durationSeconds;

  const SlowWiggleWidget({
    super.key,
    required this.child,
    this.amplitude = 3.5,
    this.rotationDegrees = 1.4,
    this.durationSeconds = 4,
  });

  @override
  State<SlowWiggleWidget> createState() => _SlowWiggleWidgetState();
}

class _SlowWiggleWidgetState extends State<SlowWiggleWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.durationSeconds),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value * 2 * math.pi;
        final offsetX = math.sin(progress) * widget.amplitude;
        final offsetY = math.cos(progress * 1.5) * widget.amplitude;
        final rotation = math.sin(progress) * (widget.rotationDegrees * math.pi / 180);

        return Transform.translate(
          offset: Offset(offsetX, offsetY),
          child: Transform.rotate(
            angle: rotation,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

class OnboardingSlideData {
  final String imageAsset;
  final String title;
  final String subtitle;

  const OnboardingSlideData({
    required this.imageAsset,
    required this.title,
    required this.subtitle,
  });
}
