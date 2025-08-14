import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

/// A simple provider that holds the currently authenticated user's profile
/// and notifies listeners when it changes.  Use [AuthService] to listen
/// to authentication state changes and update the user accordingly.
class UserProvider extends ChangeNotifier {
  final AuthService _authService;
  AppUser? _user;

  UserProvider(this._authService) {
    // Listen to auth state and update the user profile accordingly.
    _authService.currentUserProfile.listen((profile) {
      _user = profile;
      notifyListeners();
    });
  }

  AppUser? get user => _user;

  bool get isAuthenticated => _user != null;
}
