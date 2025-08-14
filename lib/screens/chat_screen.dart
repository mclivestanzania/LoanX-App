import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/loan_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart';
import '../services/firestore_service.dart';

/// Chat screen associated with a specific loan.  Displays messages in real
/// time and allows either party to send new messages.  Borrowers can
/// record repayments and both parties can view the repayment progress.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late Loan loan;
  late Stream<List<ChatMessage>> _messagesStream;
  final _messageController = TextEditingController();
  bool _repayLoading = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loan = ModalRoute.of(context)!.settings.arguments as Loan;
    final firestoreService = context.read<FirestoreService>();
    _messagesStream = firestoreService.messagesStream(loan.id);
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    final user = context.read<UserProvider>().user;
    if (user == null) return;
    final firestoreService = context.read<FirestoreService>();
    await firestoreService.sendMessage(
      loanId: loan.id,
      senderId: user.id,
      text: text,
    );
    _messageController.clear();
  }

  Future<void> _repay() async {
    // Borrower repays a fixed installment (10% of amount).  In real app this
    // would involve payment processing.  This button is only available to
    // borrowers when the loan is approved and not fully repaid.
    setState(() {
      _repayLoading = true;
    });
    final installment = loan.amount * 0.1;
    final firestoreService = context.read<FirestoreService>();
    await firestoreService.recordRepayment(loanId: loan.id, amountPaid: installment);
    setState(() {
      _repayLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final isBorrower = user?.id == loan.borrowerId;
    final progress = loan.amount > 0 ? loan.amountPaid / loan.amount : 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Loan Chat')),
      body: Column(
        children: [
          // Loan details and progress
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Amount: TZS ${loan.amount.toStringAsFixed(0)}'),
                Text('Purpose: ${loan.purpose}'),
                Text('Status: ${loan.status}'),
                if (loan.status != 'pending')
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      LinearProgressIndicator(value: progress),
                      Text('Repayment: ${(progress * 100).toStringAsFixed(0)}%'),
                      if (isBorrower && loan.status == 'approved')
                        ElevatedButton(
                          onPressed: _repayLoading ? null : _repay,
                          child: _repayLoading
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Pay Installment'),
                        ),
                    ],
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Messages list
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data ?? [];
                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == user?.id;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue[200] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(msg.text),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Input
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Enter a message',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
