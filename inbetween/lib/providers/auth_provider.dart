import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  
  // Initialiser le provider (vérifier si user déjà connecté)
  Future<void> initializeAuth() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _currentUser = await _authService.getCurrentUserData();
    } catch (e) {
      _errorMessage = e.toString();
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  // 📝 INSCRIPTION
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
    String? university,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _currentUser = await _authService.signUp(
        email: email,
        password: password,
        name: name,
        phoneNumber: phoneNumber,
        university: university,
      );
      
      _isLoading = false;
      notifyListeners();
      return true;
      
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // 🔐 CONNEXION
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _currentUser = await _authService.signIn(
        email: email,
        password: password,
      );
      
      _isLoading = false;
      notifyListeners();
      return true;
      
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // 🚪 DÉCONNEXION
  Future<void> signOut() async {
    await _authService.signOut();
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }
  
  // 🔄 METTRE À JOUR LE PROFIL
  Future<bool> updateProfile({
    String? name,
    String? phoneNumber,
    String? university,
    String? profilePicUrl,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      await _authService.updateProfile(
        name: name,
        phoneNumber: phoneNumber,
        university: university,
        profilePicUrl: profilePicUrl,
      );
      
      // Recharger les données du user
      _currentUser = await _authService.getCurrentUserData();
      
      _isLoading = false;
      notifyListeners();
      return true;
      
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Effacer les erreurs
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}