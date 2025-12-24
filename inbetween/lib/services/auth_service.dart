import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? get currentUser => _auth.currentUser;
  
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
    String? university,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      UserModel newUser = UserModel(
        id: userCredential.user!.uid,
        name: name,
        email: email,
        phoneNumber: phoneNumber,
        university: university,
        createdAt: DateTime.now(),
      );
      
      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(newUser.toMap());
      
      return newUser;
      
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Une erreur est survenue lors de l\'inscription';
    }
  }
  
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();
      
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      
      return null;
      
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Une erreur est survenue lors de la connexion';
    }
  }
  
  Future<void> signOut() async {
    await _auth.signOut();
  }
  
  Future<UserModel?> getCurrentUserData() async {
    try {
      if (currentUser == null) return null;
      
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      
      return null;
    } catch (e) {
      throw 'Impossible de récupérer les données utilisateur';
    }
  }
  
  Future<void> updateProfile({
    String? name,
    String? phoneNumber,
    String? university,
    String? profilePicUrl,
  }) async {
    try {
      if (currentUser == null) throw 'Aucun utilisateur connecté';
      
      Map<String, dynamic> updates = {};
      if (name != null) updates['name'] = name;
      if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
      if (university != null) updates['university'] = university;
      if (profilePicUrl != null) updates['profilePicUrl'] = profilePicUrl;
      
      await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .update(updates);
      
    } catch (e) {
      throw 'Impossible de mettre à jour le profil';
    }
  }
  
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé par un autre compte';
      case 'invalid-email':
        return 'L\'adresse email n\'est pas valide';
      case 'weak-password':
        return 'Le mot de passe doit contenir au moins 6 caractères';
      case 'user-not-found':
        return 'Aucun compte trouvé avec cet email';
      case 'wrong-password':
        return 'Mot de passe incorrect';
      case 'invalid-credential':
        return 'Email ou mot de passe incorrect';
      case 'network-request-failed':
        return 'Erreur de connexion. Vérifie ta connexion internet';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessaie plus tard';
      case 'operation-not-allowed':
        return 'Cette opération n\'est pas autorisée';
      default:
        return 'Une erreur est survenue. Réessaie plus tard';
    }
  }
}