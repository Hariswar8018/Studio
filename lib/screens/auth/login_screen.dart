import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/theme_service.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _showEmailForm = false;
  bool _isSignUp = false;
  bool _obscurePassword = true;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _showErrorDialog(String title, String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.fredoka(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.fredoka(
            color: isDark ? Colors.white70 : const Color(0xFF475569),
            fontSize: 13,
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'OK',
              style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String title, String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.mark_email_read_rounded, color: Color(0xFF10B981), size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.fredoka(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.fredoka(
            color: isDark ? Colors.white70 : const Color(0xFF475569),
            fontSize: 13,
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Done',
              style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleGoogleAuth() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final err = await auth.signInWithGoogle();

    if (!mounted) return;
    if (err != null) {
      if (!err.toLowerCase().contains('cancel')) {
        _showErrorDialog('Google Sign-In', err);
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  Future<void> _handleTwitterAuth() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final err = await auth.signInWithTwitter();

    if (!mounted) return;
    if (err != null) {
      if (!err.toLowerCase().contains('cancel')) {
        _showErrorDialog('X Sign-In', err);
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  Future<void> _handleEmailSubmit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      _showErrorDialog('Validation', 'Please enter a valid email address.');
      return;
    }
    if (password.length < 6) {
      _showErrorDialog('Validation', 'Password must be at least 6 characters.');
      return;
    }
    if (_isSignUp && name.isEmpty) {
      _showErrorDialog('Validation', 'Please enter your name.');
      return;
    }

    final auth = Provider.of<AuthService>(context, listen: false);
    final String? err = _isSignUp
        ? await auth.signUpWithEmail(email, password, name)
        : await auth.signInWithEmail(email, password);

    if (!mounted) return;
    if (err != null) {
      _showErrorDialog(_isSignUp ? 'Sign Up Failed' : 'Sign In Failed', err);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resetController = TextEditingController(text: email);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.lock_reset_rounded, color: Color(0xFF6366F1), size: 24),
            const SizedBox(width: 8),
            Text(
              'Reset Password',
              style: GoogleFonts.fredoka(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your registered email address and we will send you a password reset link.',
              style: GoogleFonts.fredoka(
                color: isDark ? Colors.white70 : const Color(0xFF475569),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: resetController,
              keyboardType: TextInputType.emailAddress,
              style: GoogleFonts.fredoka(color: isDark ? Colors.white : const Color(0xFF0F172A)),
              decoration: InputDecoration(
                hintText: 'user@example.com',
                hintStyle: GoogleFonts.fredoka(color: isDark ? Colors.white38 : Colors.grey),
                prefixIcon: const Icon(Icons.email_outlined, size: 20),
                filled: true,
                fillColor: isDark ? Colors.black26 : const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.fredoka(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final targetEmail = resetController.text.trim();
              if (targetEmail.isEmpty || !targetEmail.contains('@')) {
                return;
              }
              Navigator.pop(ctx);
              final auth = Provider.of<AuthService>(context, listen: false);
              final err = await auth.sendPasswordResetEmail(targetEmail);
              if (!mounted) return;
              if (err != null) {
                _showErrorDialog('Reset Password', err);
              } else {
                _showSuccessDialog('Reset Link Sent', 'A password reset email has been sent to $targetEmail. Please check your inbox.');
              }
            },
            child: Text('Send Link', style: GoogleFonts.fredoka(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final theme = Provider.of<ThemeService>(context);
    final isDark = theme.isDarkMode;

    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? Colors.white60 : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Icon / Logo
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'assets/image.png',
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title & Tagline
                  Text(
                    'JLPT Grammar Studio',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.fredoka(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Master Japanese grammar discrimination & spaced repetition',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.fredoka(
                      fontSize: 13,
                      color: subtextColor,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Auth Card with Google, X & Email
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _showEmailForm
                              ? (_isSignUp ? 'Create an account' : 'Welcome back')
                              : 'Sign in to continue',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.fredoka(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your study progress and SRS schedules will sync to your account',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.fredoka(
                            fontSize: 12,
                            color: subtextColor,
                          ),
                        ),
                        const SizedBox(height: 24),

                        if (auth.isLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Color(0xFF6366F1),
                              ),
                            ),
                          )
                        else ...[
                          // Continue with Google Button
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              side: BorderSide(
                                color: isDark ? Colors.white24 : Colors.grey.shade300,
                                width: 1.2,
                              ),
                              backgroundColor: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            onPressed: _handleGoogleAuth,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.network(
                                  'https://cdn1.iconfinder.com/data/icons/google-s-logo/150/Google_Icons-09-512.png',
                                  width: 22,
                                  height: 22,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.g_mobiledata_rounded, size: 28, color: Colors.blue),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Continue with Google',
                                  style: GoogleFonts.fredoka(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Continue with X Button
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              backgroundColor: isDark ? Colors.black : const Color(0xFF0F1419),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            onPressed: _handleTwitterAuth,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  alignment: Alignment.center,
                                  child: const Text(
                                    '𝕏',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Continue with 𝕏',
                                  style: GoogleFonts.fredoka(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Continue with Email Button (Toggles Email Form)
                          if (!_showEmailForm) ...[
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                side: BorderSide(
                                  color: const Color(0xFF6366F1).withValues(alpha: 0.5),
                                  width: 1.2,
                                ),
                                backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.08),
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                              ),
                              icon: const Icon(Icons.email_outlined, color: Color(0xFF6366F1), size: 20),
                              label: Text(
                                'Continue with Email',
                                style: GoogleFonts.fredoka(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF6366F1),
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  _showEmailForm = true;
                                  _isSignUp = false;
                                });
                              },
                            ),
                          ] else ...[
                            // Divider
                            Row(
                              children: [
                                Expanded(child: Divider(color: isDark ? Colors.white12 : Colors.grey.shade300)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  child: Text(
                                    _isSignUp ? 'SIGN UP WITH EMAIL' : 'SIGN IN WITH EMAIL',
                                    style: GoogleFonts.fredoka(fontSize: 11, color: subtextColor, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Expanded(child: Divider(color: isDark ? Colors.white12 : Colors.grey.shade300)),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Name field (if Sign Up)
                            if (_isSignUp) ...[
                              TextField(
                                controller: _nameController,
                                style: GoogleFonts.fredoka(color: textColor, fontSize: 14),
                                decoration: InputDecoration(
                                  labelText: 'Full Name',
                                  labelStyle: GoogleFonts.fredoka(color: subtextColor, fontSize: 13),
                                  prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                                  filled: true,
                                  fillColor: isDark ? Colors.black26 : const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],

                            // Email field
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: GoogleFonts.fredoka(color: textColor, fontSize: 14),
                              decoration: InputDecoration(
                                labelText: 'Email Address',
                                labelStyle: GoogleFonts.fredoka(color: subtextColor, fontSize: 13),
                                prefixIcon: const Icon(Icons.email_outlined, size: 20),
                                filled: true,
                                fillColor: isDark ? Colors.black26 : const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Password field
                            TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: GoogleFonts.fredoka(color: textColor, fontSize: 14),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                labelStyle: GoogleFonts.fredoka(color: subtextColor, fontSize: 13),
                                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    size: 18,
                                    color: subtextColor,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                                filled: true,
                                fillColor: isDark ? Colors.black26 : const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              ),
                            ),

                            // Forgot Password link (when signing in)
                            if (!_isSignUp) ...[
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: _handleForgotPassword,
                                  child: Text(
                                    'Forgot password?',
                                    style: GoogleFonts.fredoka(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF6366F1),
                                    ),
                                  ),
                                ),
                              ),
                            ] else
                              const SizedBox(height: 8),

                            const SizedBox(height: 12),

                            // Submit Button
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(50),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                backgroundColor: const Color(0xFF6366F1),
                                foregroundColor: Colors.white,
                                elevation: 0,
                              ),
                              onPressed: _handleEmailSubmit,
                              child: Text(
                                _isSignUp ? 'Create Account' : 'Sign In',
                                style: GoogleFonts.fredoka(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Switch between Sign In and Sign Up
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _isSignUp ? 'Already have an account?' : 'Don\'t have an account?',
                                  style: GoogleFonts.fredoka(fontSize: 12, color: subtextColor),
                                ),
                                TextButton(
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: () {
                                    setState(() => _isSignUp = !_isSignUp);
                                  },
                                  child: Text(
                                    _isSignUp ? 'Sign In' : 'Sign Up',
                                    style: GoogleFonts.fredoka(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF6366F1),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // Hide Email Form Button
                            Center(
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () => setState(() => _showEmailForm = false),
                                child: Text(
                                  '← Back to other login options',
                                  style: GoogleFonts.fredoka(fontSize: 11, color: subtextColor),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),

                  
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
