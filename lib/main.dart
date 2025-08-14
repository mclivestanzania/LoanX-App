import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'models/user_model.dart';
import 'providers/user_provider.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/geo_service.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/loan_request_screen.dart';
import 'screens/loan_match_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/rating_screen.dart';
import 'screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const LoanXApp());
}

class LoanXApp extends StatelessWidget {
  const LoanXApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final firestoreService = FirestoreService();
    final geoService = GeoService();
    return MultiProvider(
      providers: [
        Provider<AuthService>.value(value: authService),
        Provider<FirestoreService>.value(value: firestoreService),
        Provider<GeoService>.value(value: geoService),
        ChangeNotifierProvider<UserProvider>(
          create: (_) => UserProvider(authService),
        ),
      ],
      child: MaterialApp(
        title: 'LoanX',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => const _RootRouter(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/loanRequest': (context) => const LoanRequestScreen(),
          '/loanMatch': (context) => const LoanMatchScreen(),
          '/chat': (context) => const ChatScreen(),
          '/rating': (context) => const RatingScreen(),
          '/profile': (context) => const ProfileScreen(),
        },
      ),
    );
  }
}

/// A widget that decides which screen to display based on authentication state.
class _RootRouter extends StatelessWidget {
  const _RootRouter();

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    if (userProvider.isAuthenticated) {
      return const DashboardScreen();
    } else {
      return const LoginScreen();
    }
  }
}
