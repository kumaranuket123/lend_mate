import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase_client.dart';
import '../../../models/profile_model.dart';

class ProfileRepository {
  final _uid = supabase.auth.currentUser!.id;

  Future<ProfileModel> fetchProfile() async {
    debugPrint('[Profile] fetchProfile →');
    final data = await supabase
        .from('profiles')
        .select()
        .eq('id', _uid)
        .single();
    final email = supabase.auth.currentUser?.email;
    debugPrint('[Profile] fetchProfile ✓');
    return ProfileModel.fromMap({...data, if (email != null) 'email': email});
  }

  Future<ProfileModel> updateName(String name) async {
    debugPrint('[Profile] updateName → name=$name');
    final data = await supabase
        .from('profiles')
        .update({'name': name})
        .eq('id', _uid)
        .select()
        .single();
    debugPrint('[Profile] updateName ✓');
    return ProfileModel.fromMap(data);
  }

  Future<String> uploadAvatar(File file) async {
    final ext  = file.path.split('.').last;
    final path = 'avatars/$_uid.$ext';
    debugPrint('[Profile] uploadAvatar → path=$path');
    await supabase.storage
        .from('avatars')
        .upload(path, file, fileOptions: const FileOptions(upsert: true));

    final url = supabase.storage.from('avatars').getPublicUrl(path);
    await supabase
        .from('profiles')
        .update({'avatar_url': url})
        .eq('id', _uid);
    debugPrint('[Profile] uploadAvatar ✓ url=$url');
    return url;
  }

  Future<Map<String, dynamic>> fetchStats() async {
    debugPrint('[Profile] fetchStats →');
    final loans = await supabase
        .from('loans')
        .select('amount, lender_id, status')
        .or('lender_id.eq.$_uid,borrower_id.eq.$_uid');

    double totalLent    = 0;
    double totalBorr    = 0;
    int    activeLoans  = 0;
    int    closedLoans  = 0;

    for (final l in loans as List) {
      final amt = (l['amount'] as num).toDouble();
      if (l['lender_id'] == _uid) {
        totalLent += amt;
      } else {
        totalBorr += amt;
      }
      if (l['status'] == 'active') {
        activeLoans++;
      } else if (l['status'] == 'closed') {
        closedLoans++;
      }
    }

    debugPrint('[Profile] fetchStats ✓ active=$activeLoans closed=$closedLoans');
    return {
      'totalLent':   totalLent,
      'totalBorr':   totalBorr,
      'activeLoans': activeLoans,
      'closedLoans': closedLoans,
      'totalLoans':  (loans as List).length,
    };
  }

  Future<void> signOut() async {
    debugPrint('[Profile] signOut →');
    await supabase.auth.signOut();
    debugPrint('[Profile] signOut ✓');
  }
}
