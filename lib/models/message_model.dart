import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a chat message associated with a loan.  Messages are grouped by
/// loanId and stored in a subcollection `messages` under each loan document.
class ChatMessage {
  final String id;
  final String loanId;
  final String senderId;
  final String text;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.loanId,
    required this.senderId,
    required this.text,
    required this.timestamp,
  });

  factory ChatMessage.fromDocument(DocumentSnapshot doc, String loanId) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      loanId: loanId,
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
