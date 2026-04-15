import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Stream of auth-state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Current signed-in user (nullable)
  User? get currentUser => _auth.currentUser;

  /// Sign up with email + password, then create Firestore user document
  Future<UserCredential> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Update Firebase Auth display name
    await cred.user?.updateDisplayName(name);

    // Create user document in Firestore
    await _db.collection('users').doc(cred.user!.uid).set({
      'uid': cred.user!.uid,
      'name': name,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
      'farm': {
        'totalCrops': 0,
        'totalAreaHectares': 0,
        'sustainabilityScore': 0,
      },
    });

    return cred;
  }

  /// Sign in with email + password
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Send a password-reset email
  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  /// Sign out
  Future<void> signOut() => _auth.signOut();
}
