class FavoriteModel {
  final String id;
  final String userId;
  final String productId;
  final DateTime addedAt;
  
  FavoriteModel({
    required this.id,
    required this.userId,
    required this.productId,
    required this.addedAt,
  });
  
  factory FavoriteModel.fromMap(Map<String, dynamic> map, String id) {
    return FavoriteModel(
      id: id,
      userId: map['userId'] ?? '',
      productId: map['productId'] ?? '',
      addedAt: map['addedAt']?.toDate() ?? DateTime.now(),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'productId': productId,
      'addedAt': addedAt,
    };
  }
}