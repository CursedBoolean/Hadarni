import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Controller handling all Firebase Auth and user profile operations.
///
/// Uses [ChangeNotifier] so UI can react to [isLoading], [errorMessage],
/// and [userProfile] changes via Provider.
class AuthController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  String? _errorMessage;
  UserModel? _userProfile;

  // ── Getters ──────────────────────────────────────────────

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get user => _auth.currentUser;
  UserModel? get userProfile => _userProfile;

  /// Stream of auth state changes (used by the auth gate).
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Sign Up ──────────────────────────────────────────────

  /// Creates a new user account with [email] and [password].
  /// Returns `true` on success, `false` on failure (check [errorMessage]).
  Future<bool> signUp(String email, String password) async {
    _setLoading(true);
    _clearError();
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_mapAuthError(e.code));
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('حدث خطأ غير متوقع. حاول مرة أخرى.');
      _setLoading(false);
      return false;
    }
  }

  // ── Log In ───────────────────────────────────────────────

  /// Signs in with [email] and [password].
  /// Returns `true` on success, `false` on failure.
  Future<bool> logIn(String email, String password) async {
    _setLoading(true);
    _clearError();
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      // Fetch user profile after login
      await fetchUserProfile();
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_mapAuthError(e.code));
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('حدث خطأ غير متوقع. حاول مرة أخرى.');
      _setLoading(false);
      return false;
    }
  }

  // ── Log Out ──────────────────────────────────────────────

  /// Signs the current user out and clears local profile data.
  Future<void> logOut() async {
    await _auth.signOut();
    _userProfile = null;
    notifyListeners();
  }

  // ── User Profile ─────────────────────────────────────────

  /// Saves the user profile document to Firestore at `users/{uid}`.
  Future<bool> saveUserProfile(UserModel profile) async {
    _setLoading(true);
    _clearError();
    try {
      await _firestore
          .collection('users')
          .doc(profile.uid)
          .set(profile.toMap());
      _userProfile = profile;
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('فشل حفظ البيانات. حاول مرة أخرى.');
      _setLoading(false);
      return false;
    }
  }

  /// Fetches the current user's profile from Firestore.
  Future<void> fetchUserProfile() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      final doc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      if (doc.exists && doc.data() != null) {
        _userProfile = UserModel.fromMap(doc.data()!, currentUser.uid);
        notifyListeners();
      }
    } catch (_) {
      // Profile may not exist yet (e.g. just signed up, hasn't filled info)
    }
  }

  // ── Helpers ──────────────────────────────────────────────

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  /// Maps Firebase Auth error codes to user-friendly Arabic messages.
  String _mapAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'البريد الإلكتروني مستخدم بالفعل.';
      case 'invalid-email':
        return 'البريد الإلكتروني غير صالح.';
      case 'weak-password':
        return 'كلمة المرور ضعيفة جداً. استخدم 6 أحرف على الأقل.';
      case 'user-not-found':
        return 'لا يوجد حساب بهذا البريد الإلكتروني.';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة.';
      case 'invalid-credential':
        return 'بيانات الدخول غير صحيحة.';
      case 'too-many-requests':
        return 'محاولات كثيرة. حاول لاحقاً.';
      case 'network-request-failed':
        return 'تحقق من اتصالك بالإنترنت.';
      default:
        return 'حدث خطأ. حاول مرة أخرى.';
    }
  }
}
