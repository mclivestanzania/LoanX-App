import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/loan_model.dart';
import '../models/message_model.dart';
import '../models/rating_model.dart';

/// Provides high‑level Firestore operations for loans, messages and ratings.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  /// Create a new loan request.  Initially [lenderId] is null and
  /// status is `pending`.
  Future<Loan> createLoan({
    required String borrowerId,
    required double amount,
    required String duration,
    required String purpose,
    required String address,
    double? latitude,
    double? longitude,
  }) async {
    final docRef = _db.collection('loans').doc();
    final loan = Loan(
      id: docRef.id,
      borrowerId: borrowerId,
      lenderId: null,
      amount: amount,
      duration: duration,
      purpose: purpose,
      status: 'pending',
      address: address,
      createdAt: DateTime.now(),
    );
    final data = loan.toMap();
    // add geolocation if provided
    if (latitude != null && longitude != null) {
      data['latitude'] = latitude;
      data['longitude'] = longitude;
    }
    await docRef.set(data);
    return loan;
  }

  /// Stream of pending loans near a specific location.  This method uses a
  /// simple bounding box filter since Firestore does not support geo queries
  /// natively.  In production you may use the GeoFire library.
  Stream<List<Loan>> pendingLoansNear(double latitude, double longitude, double radiusKm) {
    // Compute bounding box approximations.  1 degree of latitude is approx 111km.
    final delta = radiusKm / 111.0;
    final minLat = latitude - delta;
    final maxLat = latitude + delta;
    final minLon = longitude - delta;
    final maxLon = longitude + delta;
    return _db
        .collection('loans')
        .where('status', isEqualTo: 'pending')
        .where('latitude', isGreaterThan: minLat)
        .where('latitude', isLessThan: maxLat)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.where((doc) {
        final data = doc.data();
        final lat = data['latitude'];
        final lon = data['longitude'];
        return lat != null && lon != null && lon >= minLon && lon <= maxLon;
      }).map((doc) => Loan.fromDocument(doc)).toList();
    });
  }

  /// Assign a lender to a loan and update its status to `approved`.  A
  /// corresponding transaction record would normally be created via a
  /// Cloud Function.  The lenderId is recorded on the loan document.
  Future<void> acceptLoan({required String loanId, required String lenderId}) async {
    await _db.collection('loans').doc(loanId).update({
      'lenderId': lenderId,
      'status': 'approved',
    });
  }

  /// Record a repayment on a loan.  The [amountPaid] is added to the
  /// existing `amountPaid` field.  When the total paid reaches the loan amount,
  /// status is set to `repaid` and rating flow can begin.
  Future<void> recordRepayment({required String loanId, required double amountPaid}) async {
    final loanRef = _db.collection('loans').doc(loanId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(loanRef);
      final data = snap.data() as Map<String, dynamic>;
      final newPaid = (data['amountPaid'] ?? 0).toDouble() + amountPaid;
      tx.update(loanRef, {
        'amountPaid': newPaid,
        if (newPaid >= (data['amount'] ?? 0).toDouble()) 'status': 'repaid',
      });
    });
  }

  /// Send a chat message associated with a loan.  Messages are stored in
  /// `loans/{loanId}/messages` subcollection.
  Future<void> sendMessage({
    required String loanId,
    required String senderId,
    required String text,
  }) async {
    final msgRef = _db.collection('loans').doc(loanId).collection('messages').doc();
    final message = ChatMessage(
      id: msgRef.id,
      loanId: loanId,
      senderId: senderId,
      text: text,
      timestamp: DateTime.now(),
    );
    await msgRef.set(message.toMap());
  }

  /// Stream of chat messages for a given loan ordered by timestamp.  Returns
  /// updates in real time.
  Stream<List<ChatMessage>> messagesStream(String loanId) {
    return _db
        .collection('loans')
        .doc(loanId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromDocument(doc, loanId))
            .toList());
  }

  /// Submit a rating from one user to another after a loan is repaid.  A rating
  /// document is created and the receiver's average rating is updated.
  Future<void> submitRating({
    required String fromUserId,
    required String toUserId,
    required String loanId,
    required double stars,
  }) async {
    final ratingRef = _db.collection('ratings').doc();
    final rating = Rating(
      id: ratingRef.id,
      fromUserId: fromUserId,
      toUserId: toUserId,
      loanId: loanId,
      stars: stars,
    );
    await ratingRef.set(rating.toMap());
    // Update the receiver's average rating.  Compute the new average by reading
    // all ratings for this user.  In production you might maintain an
    // aggregate in a Cloud Function.
    final userRef = _db.collection('users').doc(toUserId);
    final ratingsSnap = await _db
        .collection('ratings')
        .where('toUserId', isEqualTo: toUserId)
        .get();
    if (ratingsSnap.docs.isNotEmpty) {
      final total = ratingsSnap.docs
          .map((doc) => (doc.data()['stars'] ?? 0).toDouble())
          .reduce((a, b) => a + b);
      final avg = total / ratingsSnap.docs.length;
      await userRef.update({'rating': avg});
    }
  }
}
