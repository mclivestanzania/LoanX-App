import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents an application user.  A user may be both a borrower and a lender by
/// including multiple roles in the [roles] list.
class AppUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final List<String> roles; // e.g. ['borrower', 'lender']
  final String schoolOrEmployer;
  final String courseOrJob;
  final String address; // free‑form location
  final double? latitude; // optional GPS coordinate
  final double? longitude; // optional GPS coordinate
  final DateTime? dateOfBirth;
  final String? personalId;
  final double rating;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.roles,
    required this.schoolOrEmployer,
    required this.courseOrJob,
    required this.address,
    this.latitude,
    this.longitude,
    this.dateOfBirth,
    this.personalId,
    this.rating = 0.0,
  });

  factory AppUser.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      roles: List<String>.from(data['roles'] ?? ['borrower']),
      schoolOrEmployer: data['schoolOrEmployer'] ?? '',
      courseOrJob: data['courseOrJob'] ?? '',
      address: data['address'] ?? '',
      latitude: (data['latitude'] != null) ? data['latitude'].toDouble() : null,
      longitude: (data['longitude'] != null) ? data['longitude'].toDouble() : null,
      dateOfBirth: data['dateOfBirth'] != null
          ? (data['dateOfBirth'] as Timestamp).toDate()
          : null,
      personalId: data['personalId'],
      rating: (data['rating'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'roles': roles,
      'schoolOrEmployer': schoolOrEmployer,
      'courseOrJob': courseOrJob,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'dateOfBirth': dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'personalId': personalId,
      'rating': rating,
    };
  }
}
