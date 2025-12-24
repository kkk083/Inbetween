import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();
  
  Future<String> uploadProfilePicture(File imageFile, String userId) async {
    try {
      String fileName = 'profile_$userId.jpg';
      Reference ref = _storage.ref().child('profile_pictures/$fileName');
      
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
      
    } catch (e) {
      throw 'Impossible de télécharger la photo de profil. Réessaie.';
    }
  }
  
  // ✅ OPTIMISÉ : Upload en PARALLÈLE au lieu de séquentiel
  Future<List<String>> uploadProductImages(List<File> imageFiles, String productId) async {
    try {
      // ✅ Upload TOUTES les images en même temps avec Future.wait
      List<Future<String>> uploadFutures = imageFiles.asMap().entries.map((entry) {
        int index = entry.key;
        File imageFile = entry.value;
        
        return _uploadSingleImage(imageFile, productId, index);
      }).toList();
      
      // ✅ Attend que TOUTES les uploads soient terminées
      List<String> downloadUrls = await Future.wait(uploadFutures);
      
      return downloadUrls;
      
    } catch (e) {
      throw 'Impossible de télécharger les photos du produit. Réessaie.';
    }
  }
  
  // ✅ NOUVEAU : Méthode privée pour uploader UNE image
  Future<String> _uploadSingleImage(File imageFile, String productId, int index) async {
    String uniqueId = _uuid.v4();
    String fileName = 'product_${productId}_${index}_$uniqueId.jpg';
    Reference ref = _storage.ref().child('product_images/$fileName');
    
    UploadTask uploadTask = ref.putFile(imageFile);
    TaskSnapshot snapshot = await uploadTask;
    
    String downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }
  
  Future<void> deleteImage(String imageUrl) async {
    try {
      Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      print('Erreur suppression image: $e');
    }
  }
  
  // ✅ OPTIMISÉ : Suppression en parallèle aussi
  Future<void> deleteProductImages(List<String> imageUrls) async {
    try {
      await Future.wait(
        imageUrls.map((url) => deleteImage(url))
      );
    } catch (e) {
      print('Erreur suppression images: $e');
    }
  }
}