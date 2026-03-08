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

  /// Sends a 6-digit OTP to the email for password reset.
  Future<void> sendOtp(String email) async {
    debugPrint('[Auth] sendOtp → email=$email');
    await supabase.auth.signInWithOtp(email: email);
    debugPrint('[Auth] sendOtp ✓');
  }

  /// Verifies the OTP, establishes a session, then updates the password.
  Future<void> verifyOtpAndResetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    debugPrint('[Auth] verifyOtp → email=$email');
    await supabase.auth.verifyOTP(
      email: email,
      token: otp,
      type: OtpType.email,
    );
    debugPrint('[Auth] verifyOtp ✓ → updating password');
    await supabase.auth.updateUser(UserAttributes(password: newPassword));
    debugPrint('[Auth] password updated ✓');
  }

  Future<void> signOut() async {
    debugPrint('[Auth] signOut →');
    await supabase.auth.signOut();
    debugPrint('[Auth] signOut ✓');
  }

  User? get currentUser => supabase.auth.currentUser;
}
