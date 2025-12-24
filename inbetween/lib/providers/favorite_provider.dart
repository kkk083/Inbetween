import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/product_model.dart';

class FavoriteProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  
  List<String> _favoriteIds = [];
  List<ProductModel> _favoriteProducts = [];
  bool _isLoading = false;
  
  List<String> get favoriteIds => _favoriteIds;
  List<ProductModel> get favoriteProducts => _favoriteProducts;
  bool get isLoading => _isLoading;
  
  void listenToFavorites(String userId) {
    _firestoreService.getUserFavoriteIds(userId).listen((ids) {
      _favoriteIds = ids;
      notifyListeners();
    });
  }
  
  void listenToFavoriteProducts(String userId) {
    _firestoreService.getUserFavoriteProducts(userId).listen((products) {
      _favoriteProducts = products;
      notifyListeners();
    });
  }
  
  bool isFavorite(String productId) {
    return _favoriteIds.contains(productId);
  }
  
  Future<void> toggleFavorite(String userId, String productId) async {
    try {
      if (isFavorite(productId)) {
        await _firestoreService.removeFavorite(userId, productId);
      } else {
        await _firestoreService.addFavorite(userId, productId);
      }
    } catch (e) {
      print('Erreur toggle favorite: $e');
    }
  }
}