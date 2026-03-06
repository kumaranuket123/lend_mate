import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase_client.dart';
import '../../../models/loan_model.dart';
import '../../../models/profile_model.dart';

class HomeRepository {
  final _uid = supabase.auth.currentUser!.id;

  Future<ProfileModel> getProfile() async {
    debugPrint('[Home] getProfile →');
    final data = await supabase
        .from('profiles')
        .select()
        .eq('id', _uid)
        .single();
    debugPrint('[Home] getProfile ✓');
    return ProfileModel.fromMap(data);
  }

  Future<List<LoanModel>> getLentLoans() async {
    debugPrint('[Home] getLentLoans →');
    final data = await supabase
        .from('loans')
        .select('''
          *,
          borrower:profiles!borrower_id(name)
        ''')
        .eq('lender_id', _uid)
        .order('created_at', ascending: false);

    final loans = (data as List).map((m) {
      m['borrower_name'] = m['borrower']?['name'];
      return LoanModel.fromMap(m);
    }).toList();
    debugPrint('[Home] getLentLoans ✓ count=${loans.length}');
    return loans;
  }

  Future<List<LoanModel>> getBorrowedLoans() async {
    debugPrint('[Home] getBorrowedLoans →');
    final data = await supabase
        .from('loans')
        .select('''
          *,
          lender:profiles!lender_id(name)
        ''')
        .eq('borrower_id', _uid)
        .order('created_at', ascending: false);

    final loans = (data as List).map((m) {
      m['lender_name'] = m['lender']?['name'];
      return LoanModel.fromMap(m);
    }).toList();
    debugPrint('[Home] getBorrowedLoans ✓ count=${loans.length}');
    return loans;
  }
}
