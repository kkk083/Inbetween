class ChatModel {
  final String id;
  final List<String> participantIds; // [userId1, userId2]
  final Map<String, String> participantNames; // {userId1: "John", userId2: "Jane"}
  final String lastMessage;
  final DateTime lastMessageTime;
  final String productId; // Le produit concerné par la discussion
  final String productTitle;
  
  ChatModel({
    required this.id,
    required this.participantIds,
    required this.participantNames,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.productId,
    required this.productTitle,
  });
  
  factory ChatModel.fromMap(Map<String, dynamic> map, String id) {
    return ChatModel(
      id: id,
      participantIds: List<String>.from(map['participantIds'] ?? []),
      participantNames: Map<String, String>.from(map['participantNames'] ?? {}),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime: map['lastMessageTime']?.toDate() ?? DateTime.now(),
      productId: map['productId'] ?? '',
      productTitle: map['productTitle'] ?? '',
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'participantIds': participantIds,
      'participantNames': participantNames,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime,
      'productId': productId,
      'productTitle': productTitle,
    };
  }
}