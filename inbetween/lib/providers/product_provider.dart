import 'dart:io';
import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../models/user_model.dart'; // ✅ AJOUTÉ
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

class ProductProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  
  List<ProductModel> _products = [];
  List<ProductModel> _myProducts = [];
  ProductModel? _selectedProduct;
  UserModel? _selectedProductSeller; // ✅ AJOUTÉ
  bool _isLoading = false;
  String? _errorMessage;
  
  List<ProductModel> get products => _products;
  List<ProductModel> get myProducts => _myProducts;
  ProductModel? get selectedProduct => _selectedProduct;
  UserModel? get selectedProductSeller => _selectedProductSeller; // ✅ AJOUTÉ
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  Future<bool> createProduct({
    required String sellerId,
    required String sellerName,
    required String sellerPhone,
    required String title,
    required String description,
    required double price,
    required String category,
    required String condition,
    required List<File> images,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      List<String> imageUrls = [];
      
      String tempId = DateTime.now().millisecondsSinceEpoch.toString();
      
      if (images.isNotEmpty) {
        imageUrls = await _storageService.uploadProductImages(images, tempId);
      }
      
      ProductModel product = ProductModel(
        id: '',
        sellerId: sellerId,
        sellerName: sellerName,
        sellerPhone: sellerPhone,
        title: title,
        description: description,
        price: price,
        category: category,
        condition: condition,
        imageUrls: imageUrls,
        createdAt: DateTime.now(),
      );
      
      await _firestoreService.createProduct(product);
      
      _isLoading = false;
      notifyListeners();
      return true;
      
    } catch (e) {
      _errorMessage = 'Impossible de créer le produit: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  void listenToProducts() {
    _firestoreService.getAvailableProducts().listen((products) {
      _products = products;
      notifyListeners();
    });
  }
  
  void listenToMyProducts(String userId) {
    _firestoreService.getUserProducts(userId).listen((products) {
      _myProducts = products;
      notifyListeners();
    });
  }
  
  Future<void> loadProduct(String productId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _selectedProduct = await _firestoreService.getProductById(productId);
      
      // ✅ NOUVEAU : Charger aussi les infos du vendeur
      if (_selectedProduct != null) {
        _selectedProductSeller = await _firestoreService.getUserById(_selectedProduct!.sellerId);
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> markAsSold(String productId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      await _firestoreService.markProductAsSold(productId);
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
  
  Future<bool> deleteProduct(String productId, List<String> imageUrls) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      if (imageUrls.isNotEmpty) {
        await _storageService.deleteProductImages(imageUrls);
      }
      
      await _firestoreService.deleteProduct(productId);
      
      _myProducts.removeWhere((product) => product.id == productId);
      _products.removeWhere((product) => product.id == productId);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Impossible de supprimer: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  void searchProducts(String query) {
    if (query.isEmpty) {
      listenToProducts();
      return;
    }
    
    _firestoreService.searchProducts(query).listen((products) {
      _products = products;
      notifyListeners();
    });
  }
  
  void filterByCategory(String category) {
    if (category == 'Tout') {
      listenToProducts();
      return;
    }
    
    _firestoreService.getProductsByCategory(category).listen((products) {
      _products = products;
      notifyListeners();
    });
  }
  
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}