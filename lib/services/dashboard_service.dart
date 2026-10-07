import 'package:firebase_auth/firebase_auth.dart';

import '../auth/auth_service.dart';
import '../models/dashboard_profile.dart';

class DashboardService {
  DashboardService({
    FirebaseAuth? firebaseAuth,
    AuthService? authService,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _authService = authService ?? AuthService();

  final FirebaseAuth _firebaseAuth;
  final AuthService _authService;

  DashboardProfile? get currentProfile {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    return DashboardProfile(
      displayName: user.displayName,
      email: user.email,
      photoUrl: user.photoURL,
    );
  }

  Future<void> signOut() => _authService.signOut();
}
