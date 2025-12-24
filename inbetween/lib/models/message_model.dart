class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final bool isRead;
  
  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    this.isRead = false,
  });
  
  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
    return MessageModel(
      id: id,
      chatId: map['chatId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      text: map['text'] ?? '',
      timestamp: map['timestamp']?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'timestamp': timestamp,
      'isRead': isRead,
    };
  }
}