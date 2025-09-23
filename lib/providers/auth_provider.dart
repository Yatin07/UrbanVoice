import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart';
import '../services/firebase_auth_service.dart';

export '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  CivicUser? _user;
  bool _initialized = false;
  bool _loading = false;
  String? _error;
  StreamSubscription<User?>? _authSubscription;

  CivicUser? get user => _user;
  bool get initialized => _initialized;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> initialize() async {
    _authSubscription = FirebaseAuthService.authStateChanges.listen(_onAuthStateChanged);
    _initialized = true;
    notifyListeners();
  }

  void _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser != null) {
      // User is signed in, get CivicUser data from Firestore
      try {
        // We'll get user data through the service's public methods
        _user = await _getCurrentCivicUser(firebaseUser.uid);
      } catch (e) {
        _error = 'Failed to load user data';
      }
    } else {
      // User is signed out
      _user = null;
    }
    notifyListeners();
  }

  Future<CivicUser?> _getCurrentCivicUser(String uid) async {
    try {
      return await FirebaseAuthService.getUserFromFirestore(uid);
    } catch (e) {
      return null;
    }
  }

  // Email authentication

  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    String? phone,
    UserRole role = UserRole.citizen,
  }) async {
    return _handleAuthOperation(() async {
      final user = await FirebaseAuthService.signUpWithEmail(
        email: email,
        password: password,
        name: name,
        phone: phone,
        role: role,
      );
      if (user != null) {
        _user = user;
        return true;
      }
      return false;
    });
  }

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return _handleAuthOperation(() async {
      final user = await FirebaseAuthService.signInWithEmail(email, password);
      if (user != null) {
        _user = user;
        return true;
      }
      return false;
    });
  }

  // Google authentication
  Future<bool> signInWithGoogle() async {
    return _handleAuthOperation(() async {
      final user = await FirebaseAuthService.signInWithGoogle();
      if (user != null) {
        _user = user;
        return true;
      }
      return false;
    });
  }

  // Phone authentication
  String? _verificationId;
  
  Future<bool> sendPhoneVerification(String phoneNumber) async {
    _loading = true;
    _error = null;
    notifyListeners();

    final completer = Completer<bool>();

    try {
      await FirebaseAuthService.sendPhoneVerification(
        phoneNumber: phoneNumber,
        onCodeSent: (verificationId) {
          _verificationId = verificationId;
          _loading = false;
          notifyListeners();
          completer.complete(true);
        },
        onError: (error) {
          _error = error;
          _loading = false;
          notifyListeners();
          completer.complete(false);
        },
        onAutoVerified: (user) {
          _user = user;
          _loading = false;
          notifyListeners();
          completer.complete(true);
        },
      );
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      completer.complete(false);
    }

    return completer.future;
  }

  Future<bool> verifyPhoneOTP({
    required String otp,
    String? name,
    String? email,
  }) async {
    if (_verificationId == null) {
      _error = 'No verification ID found. Please request OTP again.';
      notifyListeners();
      return false;
    }

    return _handleAuthOperation(() async {
      final user = await FirebaseAuthService.verifyPhoneOTP(
        verificationId: _verificationId!,
        otp: otp,
        name: name,
        email: email,
      );
      if (user != null) {
        _user = user;
        _verificationId = null;
        return true;
      }
      return false;
    });
  }

  // Password reset
  Future<bool> resetPassword(String email) async {
    return _handleAuthOperation(() async {
      await FirebaseAuthService.resetPassword(email);
      return true;
    });
  }

  // Update user profile
  Future<bool> updateUserProfile(CivicUser updatedUser) async {
    return _handleAuthOperation(() async {
      await FirebaseAuthService.updateUserProfile(updatedUser);
      _user = updatedUser;
      return true;
    });
  }

  // Logout
  Future<void> logout() async {
    _loading = true;
    notifyListeners();
    
    try {
      await FirebaseAuthService.signOut();
      _user = null;
      _verificationId = null;
      _error = null;
    } catch (e) {
      _error = 'Failed to sign out';
    }
    
    _loading = false;
    notifyListeners();
  }

  // Helper method to handle authentication operations
  Future<bool> _handleAuthOperation(Future<bool> Function() operation) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await operation();
      _loading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Sign out method
  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      _user = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to sign out: $e';
      notifyListeners();
    }
  }

  // Demo login method for hackathon testing
  void setUser(CivicUser demoUser) {
    _user = demoUser;
    _initialized = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
