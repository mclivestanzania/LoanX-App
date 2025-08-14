import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';

import '../models/loan_model.dart';
import '../providers/user_provider.dart';
import '../services/firestore_service.dart';

/// Screen that allows a user to rate the counterparty after a loan is repaid.
/// Displays a rating bar and submits the rating to Firestore.
class RatingScreen extends StatefulWidget {
  const RatingScreen({super.key});

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  double _rating = 3.0;
  bool _submitting = false;
  String? _error;

  Future<void> _submitRating(Loan loan) async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    final user = context.read<UserProvider>().user;
    if (user == null) return;
    final toUserId = user.id == loan.borrowerId ? loan.lenderId : loan.borrowerId;
    if (toUserId == null) {
      setState(() {
        _error = 'Cannot submit rating: lender not assigned';
        _submitting = false;
      });
      return;
    }
    final firestore = context.read<FirestoreService>();
    try {
      await firestore.submitRating(
        fromUserId: user.id,
        toUserId: toUserId,
        loanId: loan.id,
        stars: _rating,
      );
      // navigate back to dashboard after rating
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loan = ModalRoute.of(context)!.settings.arguments as Loan;
    return Scaffold(
      appBar: AppBar(title: const Text('Rate Counterparty')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Please rate your counterparty:'),
            const SizedBox(height: 16),
            RatingBar.builder(
              initialRating: _rating,
              minRating: 1,
              maxRating: 5,
              allowHalfRating: true,
              itemBuilder: (context, _) => const Icon(
                Icons.star,
                color: Colors.amber,
              ),
              onRatingUpdate: (value) {
                setState(() {
                  _rating = value;
                });
              },
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ElevatedButton(
              onPressed: _submitting ? null : () => _submitRating(loan),
              child: _submitting
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit Rating'),
            ),
          ],
        ),
      ),
    );
  }
}
