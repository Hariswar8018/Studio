import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'database_service.dart';

class AuthService extends ChangeNotifier {
  final bool useFirebase;
  final DatabaseService databaseService;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  UserModel? _currentUser;
  bool _isLoading = false;

  static const String adminEmail = 'hariswarsamasi@gmail.com';

  AuthService({required this.useFirebase, required this.databaseService}) {
    _initAuth();
  }

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  bool get isAdmin {
    if (_currentUser == null) return false;
    return _currentUser!.email.trim().toLowerCase() == adminEmail.toLowerCase();
  }

  Future<void> _initAuth() async {
    _isLoading = true;
    notifyListeners();

    if (useFirebase) {
      try {
        await _googleSignIn.initialize();
      } catch (e) {
        debugPrint('GoogleSignIn initialization info: $e');
      }

      _auth.authStateChanges().listen((User? firebaseUser) async {
        if (firebaseUser != null) {
          _currentUser = await databaseService.getUser(firebaseUser.uid);
          if (_currentUser == null) {
            _currentUser = UserModel(
              uid: firebaseUser.uid,
              email: firebaseUser.email ?? '',
              displayName: firebaseUser.displayName ?? 'Grammar Learner',
              photoUrl: firebaseUser.photoURL ?? '',
              targetLevel: 'N3',
            );
            await databaseService.saveUser(_currentUser!);
          }
        } else {
          _currentUser = null;
        }
        _isLoading = false;
        notifyListeners();
      });
    } else {
      // Local / Offline session check
      final prefs = await SharedPreferences.getInstance();
      final savedUid = prefs.getString('grammar_user_uid');
      if (savedUid != null) {
        _currentUser = await databaseService.getUser(savedUid);
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  // Email Sign Up
  Future<String?> signUpWithEmail(String email, String password, String name) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (useFirebase) {
        UserCredential credential = await _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        if (credential.user != null) {
          await credential.user!.updateDisplayName(name.trim());
          _currentUser = UserModel(
            uid: credential.user!.uid,
            email: email.trim(),
            displayName: name.trim(),
            photoUrl: '',
            targetLevel: 'N3',
          );
          await databaseService.saveUser(_currentUser!);
        }
      } else {
        final uid = 'local_user_${DateTime.now().millisecondsSinceEpoch}';
        _currentUser = UserModel(
          uid: uid,
          email: email.trim(),
          displayName: name.trim().isEmpty ? 'Grammar Learner' : name.trim(),
          photoUrl: '',
          targetLevel: 'N3',
        );
        await databaseService.saveUser(_currentUser!);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('grammar_user_uid', uid);
      }
      return null;
    } catch (e) {
      return _cleanAuthError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Email Sign In
  Future<String?> signInWithEmail(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final cleanEmail = email.trim().toLowerCase();
      if (useFirebase) {
        await _auth.signInWithEmailAndPassword(
          email: cleanEmail,
          password: password,
        );
      } else {
        final prefs = await SharedPreferences.getInstance();
        String uid = 'local_user_${cleanEmail.hashCode.abs()}';
        if (cleanEmail == adminEmail.toLowerCase()) {
          uid = 'admin_haris';
        }

        _currentUser = await databaseService.getUser(uid);
        if (_currentUser == null) {
          _currentUser = UserModel(
            uid: uid,
            email: cleanEmail,
            displayName: cleanEmail == adminEmail.toLowerCase() ? 'Admin Haris' : 'Grammar Learner',
            photoUrl: '',
            targetLevel: 'N3',
          );
          await databaseService.saveUser(_currentUser!);
        }
        await prefs.setString('grammar_user_uid', uid);
      }
      return null;
    } catch (e) {
      return _cleanAuthError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Password Reset / Forgot Password
  Future<String?> sendPasswordResetEmail(String email) async {
    _isLoading = true;
    notifyListeners();
    try {
      final cleanEmail = email.trim().toLowerCase();
      if (useFirebase) {
        await _auth.sendPasswordResetEmail(email: cleanEmail);
      } else {
        await Future.delayed(const Duration(milliseconds: 500));
      }
      return null;
    } catch (e) {
      return _cleanAuthError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Google Sign In
  Future<String?> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (useFirebase) {
        final googleUser = await _googleSignIn.authenticate();
        final googleAuth = googleUser.authentication;
        final googleAuthorization = await googleUser.authorizationClient.authorizeScopes([
          'email',
          'profile',
          'openid',
        ]);
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuthorization.accessToken,
          idToken: googleAuth.idToken,
        );
        await _auth.signInWithCredential(credential);
      } else {
        return await signInWithEmail(adminEmail, 'demo_pass');
      }
      return null;
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      return _cleanAuthError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Twitter / X Sign In
  Future<String?> signInWithTwitter() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (useFirebase) {
        final twitterProvider = OAuthProvider('twitter.com');
        final UserCredential credential = await _auth.signInWithProvider(twitterProvider);
        if (credential.user != null) {
          _currentUser = await databaseService.getUser(credential.user!.uid);
          if (_currentUser == null) {
            _currentUser = UserModel(
              uid: credential.user!.uid,
              email: credential.user!.email ?? '',
              displayName: credential.user!.displayName ?? 'Grammar Learner',
              photoUrl: credential.user!.photoURL ?? '',
              targetLevel: 'N3',
            );
            await databaseService.saveUser(_currentUser!);
          }
        }
      } else {
        final uid = 'x_user_demo';
        _currentUser = UserModel(
          uid: uid,
          email: 'x_learner@x.com',
          displayName: 'X Learner',
          photoUrl: '',
          targetLevel: 'N3',
        );
        await databaseService.saveUser(_currentUser!);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('grammar_user_uid', uid);
      }
      return null;
    } catch (e) {
      debugPrint('Twitter/X Sign-In error: $e');
      return _cleanAuthError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update Premium Subscription Status
  Future<void> setPremiumStatus(bool isPremium, String type, DateTime expiry) async {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(
      isPremium: isPremium,
      subscriptionType: type,
      premiumExpiry: expiry,
    );
    await databaseService.saveUser(_currentUser!);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('grammar_is_premium', isPremium);
    await prefs.setString('grammar_subscription_type', type);
    await prefs.setString('grammar_premium_expiry', expiry.toIso8601String());
    notifyListeners();
  }

  // Sign Out
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    try {
      if (useFirebase) {
        await _auth.signOut();
        try {
          await _googleSignIn.signOut();
        } catch (_) {}
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('grammar_user_uid');
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _cleanAuthError(dynamic error) {
    if (error == null) return 'An unknown error occurred.';
    final str = error.toString().toLowerCase();
    if (str.contains('user-not-found')) return 'No user found with this email.';
    if (str.contains('wrong-password')) return 'Incorrect password.';
    if (str.contains('email-already-in-use')) return 'This email is already in use.';
    if (str.contains('invalid-email')) return 'Please provide a valid email address.';
    if (str.contains('weak-password')) return 'Password must be at least 6 characters.';
    if (str.contains('cancel') || str.contains('sign_in_canceled') || str.contains('12501')) {
      return 'Sign-in cancelled.';
    }
    if (error is FirebaseAuthException && error.message != null) {
      return error.message!;
    }
    return error.toString();
  }
}

