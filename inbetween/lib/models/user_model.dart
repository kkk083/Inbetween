class UserModel {
  final String id;
  final String name;
  final String email;
  final String phoneNumber; 
  final String? university; // Optionnel
  final String? profilePicUrl;
  final DateTime createdAt;
  
  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber, 
    this.university,
    this.profilePicUrl,
    required this.createdAt,
  });
  
  // Convertir depuis Firestore (Map -> Object)
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      university: map['university'],
      profilePicUrl: map['profilePicUrl'],
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
    );
  }
  
  // Convertir vers Firestore (Object -> Map)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber, 
      'university': university,
      'profilePicUrl': profilePicUrl,
      'createdAt': createdAt,
    };
  }
}