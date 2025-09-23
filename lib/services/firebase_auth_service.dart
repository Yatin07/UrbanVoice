import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class FirebaseAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user stream
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current Firebase user
  static User? get currentUser => _auth.currentUser;

  // Sign in with email and password
  static Future<CivicUser?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null) {
        final civicUser = await getUserFromFirestore(credential.user!.uid);
        if (civicUser != null) {
          await _updateLastLogin(civicUser.id);
        }
        return civicUser;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign up with email and password
  static Future<CivicUser?> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    String? phone,
    UserRole role = UserRole.citizen,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await credential.user!.updateDisplayName(name);
        
        final civicUser = CivicUser(
          id: credential.user!.uid,
          name: name,
          email: email,
          phone: phone,
          role: role,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );

        await _saveUserToFirestore(civicUser);
        return civicUser;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in with Google
  static Future<CivicUser?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        // Check if user exists in Firestore
        CivicUser? civicUser = await getUserFromFirestore(userCredential.user!.uid);
        
        if (civicUser == null) {
          // Create new user in Firestore
          civicUser = CivicUser(
            id: userCredential.user!.uid,
            name: userCredential.user!.displayName ?? 'Google User',
            email: userCredential.user!.email ?? '',
            phone: userCredential.user!.phoneNumber,
            role: UserRole.citizen,
            createdAt: DateTime.now(),
            lastLoginAt: DateTime.now(),
          );
          await _saveUserToFirestore(civicUser);
        } else {
          await _updateLastLogin(civicUser.id);
        }
        
        return civicUser;
      }
      return null;
    } catch (e) {
      throw Exception('Google sign-in failed: ${e.toString()}');
    }
  }

  // Send phone verification code
  static Future<void> sendPhoneVerification({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
    required Function(CivicUser user) onAutoVerified,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification (Android only)
          final userCredential = await _auth.signInWithCredential(credential);
          if (userCredential.user != null) {
            CivicUser? civicUser = await getUserFromFirestore(userCredential.user!.uid);
            
            if (civicUser == null) {
              civicUser = CivicUser(
                id: userCredential.user!.uid,
                name: 'Phone User',
                email: '', // Will need to be updated later
                phone: phoneNumber,
                role: UserRole.citizen,
                createdAt: DateTime.now(),
                lastLoginAt: DateTime.now(),
              );
              await _saveUserToFirestore(civicUser);
            } else {
              await _updateLastLogin(civicUser.id);
            }
            
            onAutoVerified(civicUser);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(_handleAuthException(e));
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Handle timeout
        },
      );
    } catch (e) {
      onError('Phone verification failed: ${e.toString()}');
    }
  }

  // Verify phone OTP
  static Future<CivicUser?> verifyPhoneOTP({
    required String verificationId,
    required String otp,
    String? name,
    String? email,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        CivicUser? civicUser = await getUserFromFirestore(userCredential.user!.uid);
        
        if (civicUser == null) {
          civicUser = CivicUser(
            id: userCredential.user!.uid,
            name: name ?? 'Phone User',
            email: email ?? '',
            phone: userCredential.user!.phoneNumber,
            role: UserRole.citizen,
            createdAt: DateTime.now(),
            lastLoginAt: DateTime.now(),
          );
          await _saveUserToFirestore(civicUser);
        } else {
          await _updateLastLogin(civicUser.id);
        }
        
        return civicUser;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign out
  static Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  // Reset password
  static Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Update user profile
  static Future<void> updateUserProfile(CivicUser user) async {
    await _saveUserToFirestore(user);
  }

  // Get user from Firestore
  static Future<CivicUser?> getUserFromFirestore(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return CivicUser.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Save user to Firestore
  static Future<void> _saveUserToFirestore(CivicUser user) async {
    await _firestore.collection('users').doc(user.id).set(user.toMap());
  }

  // Update last login time
  static Future<void> _updateLastLogin(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'lastLoginAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Handle Firebase Auth exceptions
  static String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'invalid-phone-number':
        return 'Invalid phone number format.';
      case 'invalid-verification-code':
        return 'Invalid verification code.';
      case 'invalid-verification-id':
        return 'Invalid verification ID.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}
