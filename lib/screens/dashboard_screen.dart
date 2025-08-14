import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/loan_model.dart';
import '../providers/user_provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Dashboard that displays options based on the user's roles and a summary of
/// their active loans.  Borrowers can create loan requests, lenders can
/// browse pending loans.  A common list shows loans the user is involved in.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Stream<List<Loan>> _myLoansStream;

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final user = userProvider.user;
    if (user != null) {
      _myLoansStream = FirebaseFirestore.instance
          .collection('loans')
          .where('borrowerId', isEqualTo: user.id)
          .snapshots()
          .asyncMap((snapshot) async {
        final borrowerLoans = snapshot.docs.map((d) => Loan.fromDocument(d)).toList();
        // fetch lender loans as well
        final lenderSnap = await FirebaseFirestore.instance
            .collection('loans')
            .where('lenderId', isEqualTo: user.id)
            .get();
        final lenderLoans = lenderSnap.docs.map((d) => Loan.fromDocument(d)).toList();
        return [...borrowerLoans, ...lenderLoans];
      });
    } else {
      _myLoansStream = const Stream.empty();
    }
  }

  void _logout() async {
    await context.read<AuthService>().logout();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Welcome, ${user.name}',
              style: Theme.of(context).textTheme.headline6,
            ),
            const SizedBox(height: 16),
            // Role-specific actions
            if (user.roles.contains('borrower'))
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/loanRequest');
                },
                child: const Text('Request a Loan'),
              ),
            if (user.roles.contains('lender'))
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/loanMatch');
                },
                child: const Text('View Loan Requests Nearby'),
              ),
            const SizedBox(height: 24),
            Text(
              'My Loans',
              style: Theme.of(context).textTheme.subtitle1,
            ),
            const SizedBox(height: 8),
            StreamBuilder<List<Loan>>(
              stream: _myLoansStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final loans = snapshot.data ?? [];
                if (loans.isEmpty) {
                  return const Text('No active loans');
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: loans.length,
                  itemBuilder: (context, index) {
                    final loan = loans[index];
                    return Card(
                      child: ListTile(
                        title: Text('Amount: ${loan.amount}'),
                        subtitle: Text('Status: ${loan.status}'),
                        trailing: const Icon(Icons.arrow_forward),
                        onTap: () {
                          // navigate to chat/repay or details page
                          Navigator.pushNamed(
                            context,
                            '/chat',
                            arguments: loan,
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
