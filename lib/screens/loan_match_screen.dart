import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/loan_model.dart';
import '../providers/user_provider.dart';
import '../services/firestore_service.dart';

/// Screen showing pending loan requests near the lender.  Lenders can accept
/// a loan which assigns themselves as the lender and changes the status to
/// approved.
class LoanMatchScreen extends StatefulWidget {
  const LoanMatchScreen({super.key});

  @override
  State<LoanMatchScreen> createState() => _LoanMatchScreenState();
}

class _LoanMatchScreenState extends State<LoanMatchScreen> {
  static const _radiusKm = 10.0; // search radius
  Stream<List<Loan>>? _loanStream;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = context.read<UserProvider>().user;
    final firestore = context.read<FirestoreService>();
    if (user != null && user.latitude != null && user.longitude != null) {
      _loanStream = firestore.pendingLoansNear(
        user.latitude!,
        user.longitude!,
        _radiusKm,
      );
    } else {
      _error = 'Location information unavailable. Cannot fetch nearby requests.';
    }
    _loading = false;
  }

  Future<void> _acceptLoan(Loan loan) async {
    final user = context.read<UserProvider>().user;
    if (user == null) return;
    final firestore = context.read<FirestoreService>();
    await firestore.acceptLoan(loanId: loan.id, lenderId: user.id);
    // Optionally show a success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Loan accepted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Loan Requests Nearby')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : StreamBuilder<List<Loan>>(
                  stream: _loanStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final loans = snapshot.data ?? [];
                    if (loans.isEmpty) {
                      return const Center(child: Text('No pending loans nearby'));
                    }
                    return ListView.builder(
                      itemCount: loans.length,
                      itemBuilder: (context, index) {
                        final loan = loans[index];
                        return Card(
                          child: ListTile(
                            title: Text('TZS ${loan.amount.toStringAsFixed(0)}'),
                            subtitle: Text('Purpose: ${loan.purpose}\nDuration: ${loan.duration}\nAddress: ${loan.address}'),
                            trailing: ElevatedButton(
                              onPressed: () => _acceptLoan(loan),
                              child: const Text('Accept'),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
