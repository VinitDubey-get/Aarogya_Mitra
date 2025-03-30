import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Get current user
  User? get currentUser => _auth.currentUser;
  
  // Authentication stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // Sign in with email and password
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password
      );
      return result.user;
    } catch (e) {
      print('Sign in error: $e');
      rethrow;
    }
  }
  
  // Register with email and password
  Future<User?> registerWithEmailAndPassword(
      String email, String password, String name, String userType) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password
      );
      
      User? user = result.user;
      
      // Update display name
      if (user != null) {
        await user.updateDisplayName(name);
        
        // Store user data in Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': name,
          'email': email,
          'userType': userType,
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        // Create specialized record (doctor or patient)
        if (userType == 'doctor') {
          await _firestore.collection('doctors').doc(user.uid).set({
            'userId': user.uid,
            'name': name,
            'email': email,
            'createdAt': FieldValue.serverTimestamp(),
            'isAvailable': true,
          });
        } else if (userType == 'patient') {
          await _firestore.collection('patients').doc(user.uid).set({
            'userId': user.uid,
            'name': name,
            'email': email,
            'createdAt': FieldValue.serverTimestamp(),
          });
          await _firestore.collection('consultations').doc(user.uid).set({
            'patientId': user.uid,
            'name': name,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
      
      return user;
    } catch (e) {
      print('Register error: $e');
      rethrow;
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
  
  // Get user type (doctor or patient)
  Future<String?> getUserType() async {
    if (currentUser == null) return null;
    
    try {
      final doc = await _firestore.collection('users').doc(currentUser!.uid).get();
      return doc.data()?['userType'];
    } catch (e) {
      print('Error getting user type: $e');
      return null;
    }
  }
}