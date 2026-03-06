import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase_client.dart';

class AuthRepository {
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    debugPrint('[Auth] signUp → email=$email');
    final res = await supabase.auth.signUp(
      email: email,
      password: password,
      data: {'name': name, 'phone': phone},
    );
    debugPrint('[Auth] signUp ✓ uid=${res.user?.id}');
    // Profile is auto-created via DB trigger
    return res;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    debugPrint('[Auth] signIn → email=$email');
    final res = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    debugPrint('[Auth] signIn ✓ uid=${res.user?.id}');
    return res;
  }

  Future<void> signOut() async {
    debugPrint('[Auth] signOut →');
    await supabase.auth.signOut();
    debugPrint('[Auth] signOut ✓');
  }

  User? get currentUser => supabase.auth.currentUser;
}
