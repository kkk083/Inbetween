import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  FirebaseFirestore get firestore => _firestore;
  
  // PRODUCTS
  
  Future<String> createProduct(ProductModel product) async {
    try {
      DocumentReference docRef = await _firestore
          .collection('products')
          .add(product.toMap());
      
      return docRef.id;
    } catch (e) {
      throw 'Impossible de créer le produit. Vérifie ta connexion.';
    }
  }
  
  Stream<List<ProductModel>> getAvailableProducts() {
    return _firestore
        .collection('products')
        .where('isAvailable', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }
  
  Stream<List<ProductModel>> getUserProducts(String userId) {
    return _firestore
        .collection('products')
        .where('sellerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }
  
  Future<ProductModel?> getProductById(String productId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('products')
          .doc(productId)
          .get();
      
      if (doc.exists) {
        return ProductModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw 'Impossible de charger ce produit.';
    }
  }
  
  Future<void> markProductAsSold(String productId) async {
    try {
      await _firestore
          .collection('products')
          .doc(productId)
          .update({'isAvailable': false});
    } catch (e) {
      throw 'Impossible de mettre à jour le produit.';
    }
  }
  
  Future<void> deleteProduct(String productId) async {
    try {
      await _firestore.collection('products').doc(productId).delete();
    } catch (e) {
      throw 'Impossible de supprimer le produit.';
    }
  }
  
  Future<void> updateProduct(String productId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('products').doc(productId).update(data);
    } catch (e) {
      throw 'Impossible de mettre à jour le produit.';
    }
  }
  
  Stream<List<ProductModel>> searchProducts(String query) {
    String queryLower = query.toLowerCase();
    return _firestore
        .collection('products')
        .where('isAvailable', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
          .where((product) => 
              product.title.toLowerCase().contains(queryLower) ||
              product.description.toLowerCase().contains(queryLower))
          .toList();
    });
  }
  
  Stream<List<ProductModel>> getProductsByCategory(String category) {
    return _firestore
        .collection('products')
        .where('isAvailable', isEqualTo: true)
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }
  
  // USERS
  
  Future<UserModel?> getUserById(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();
      
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw 'Impossible de charger les informations de l\'utilisateur.';
    }
  }
  
  // CHAT
  
  Future<String> getOrCreateChat({
    required String currentUserId,
    required String otherUserId,
    required String productId,
    required String productTitle,
    required Map<String, String> participantNames,
  }) async {
    try {
      QuerySnapshot existingChats = await _firestore
          .collection('chats')
          .where('participantIds', arrayContains: currentUserId)
          .where('productId', isEqualTo: productId)
          .get();
      
      for (var doc in existingChats.docs) {
        List<String> participants = List<String>.from(doc['participantIds']);
        if (participants.contains(otherUserId)) {
          return doc.id;
        }
      }
      
      ChatModel newChat = ChatModel(
        id: '',
        participantIds: [currentUserId, otherUserId],
        participantNames: participantNames,
        lastMessage: 'Conversation créée',
        lastMessageTime: DateTime.now(),
        productId: productId,
        productTitle: productTitle,
      );
      
      DocumentReference chatRef = await _firestore
          .collection('chats')
          .add(newChat.toMap());
      
      return chatRef.id;
      
    } catch (e) {
      throw 'Impossible de créer la conversation.';
    }
  }
  
  Stream<List<ChatModel>> getUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participantIds', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }
  
  Future<void> sendMessage(MessageModel message) async {
    try {
      await _firestore
          .collection('chats')
          .doc(message.chatId)
          .collection('messages')
          .add(message.toMap());
      
      await _firestore.collection('chats').doc(message.chatId).update({
        'lastMessage': message.text,
        'lastMessageTime': message.timestamp,
      });
      
    } catch (e) {
      throw 'Impossible d\'envoyer le message.';
    }
  }
  
  Stream<List<MessageModel>> getChatMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // FAVORITES
  Future<void> addFavorite(String userId, String productId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(productId)
          .set({
        'userId': userId,
        'productId': productId,
        'addedAt': DateTime.now(),
      });
    } catch (e) {
      throw 'Impossible d\'ajouter aux favoris.';
    }
  }

  Future<void> removeFavorite(String userId, String productId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(productId)
          .delete();
    } catch (e) {
      throw 'Impossible de retirer des favoris.';
    }
  }

  Stream<List<String>> getUserFavoriteIds(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.id).toList();
    });
  }

  Stream<List<ProductModel>> getUserFavoriteProducts(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      List<ProductModel> favoriteProducts = [];
      
      for (var doc in snapshot.docs) {
        String productId = doc.id;
        DocumentSnapshot productDoc = await _firestore
            .collection('products')
            .doc(productId)
            .get();
        
        if (productDoc.exists) {
          favoriteProducts.add(
            ProductModel.fromMap(productDoc.data() as Map<String, dynamic>, productDoc.id)
          );
        }
      }
      
      return favoriteProducts;
    });
  }

  Future<bool> isFavorite(String userId, String productId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(productId)
          .get();
      
      return doc.exists;
    } catch (e) {
      return false;
    }
  }
}