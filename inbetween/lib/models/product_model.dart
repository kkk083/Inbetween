class ProductModel {
  final String id;
  final String sellerId; // ID du vendeur
  final String sellerName; // Nom du vendeur (pour affichage rapide)
  final String title;
  final String description;
  final double price;
  final String category;
  final String condition;
  final List<String> imageUrls; // Plusieurs images possibles
  final bool isAvailable; // Produit encore dispo ou vendu
  final DateTime createdAt;
  
  ProductModel({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.condition,
    required this.imageUrls,
    this.isAvailable = true,
    required this.createdAt,
  });
  
  factory ProductModel.fromMap(Map<String, dynamic> map, String id) {
    return ProductModel(
      id: id,
      sellerId: map['sellerId'] ?? '',
      sellerName: map['sellerName'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      category: map['category'] ?? '',
      condition: map['condition'] ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      isAvailable: map['isAvailable'] ?? true,
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'sellerId': sellerId,
      'sellerName': sellerName,
      'title': title,
      'description': description,
      'price': price,
      'category': category,
      'condition': condition,
      'imageUrls': imageUrls,
      'isAvailable': isAvailable,
      'createdAt': createdAt,
    };
  }
}