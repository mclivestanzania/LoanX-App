import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a loan between a borrower and a lender.
class Loan {
  final String id;
  final String borrowerId;
  final String? lenderId;
  final double amount;
  final String duration; // e.g. '3 months'
  final String purpose;
  final String status; // pending, approved, repaid
  final String address; // textual address for location
  final DateTime createdAt;
  final double amountPaid;

  Loan({
    required this.id,
    required this.borrowerId,
    required this.lenderId,
    required this.amount,
    required this.duration,
    required this.purpose,
    required this.status,
    required this.address,
    required this.createdAt,
    this.amountPaid = 0,
  });

  factory Loan.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Loan(
      id: doc.id,
      borrowerId: data['borrowerId'] ?? '',
      lenderId: data['lenderId'],
      amount: (data['amount'] ?? 0).toDouble(),
      duration: data['duration'] ?? '',
      purpose: data['purpose'] ?? '',
      status: data['status'] ?? 'pending',
      address: data['address'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      amountPaid: (data['amountPaid'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'borrowerId': borrowerId,
      'lenderId': lenderId,
      'amount': amount,
      'duration': duration,
      'purpose': purpose,
      'status': status,
      'address': address,
      'createdAt': Timestamp.fromDate(createdAt),
      'amountPaid': amountPaid,
    };
  }
}
