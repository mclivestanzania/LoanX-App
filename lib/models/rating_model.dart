import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a rating given by one user to another after a loan is repaid.
class Rating {
  final String id;
  final String fromUserId;
  final String toUserId;
  final String loanId;
  final double stars;

  Rating({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.loanId,
    required this.stars,
  });

  factory Rating.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Rating(
      id: doc.id,
      fromUserId: data['fromUserId'] ?? '',
      toUserId: data['toUserId'] ?? '',
      loanId: data['loanId'] ?? '',
      stars: (data['stars'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'loanId': loanId,
      'stars': stars,
    };
  }
}
