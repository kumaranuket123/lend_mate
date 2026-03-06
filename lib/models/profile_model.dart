class ProfileModel {
  final String  id;
  final String  name;
  final String? email;
  final String? phone;
  final String? upiId;
  final String? avatarUrl;
  final double  totalBorrowed;
  final double  totalLent;

  const ProfileModel({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.upiId,
    this.avatarUrl,
    this.totalBorrowed = 0,
    this.totalLent = 0,
  });

  factory ProfileModel.fromMap(Map<String, dynamic> m) => ProfileModel(
        id:            m['id'] as String,
        name:          m['name'] as String,
        email:         m['email'] as String?,
        phone:         m['phone'] as String?,
        upiId:         m['upi_id'] as String?,
        avatarUrl:     m['avatar_url'] as String?,
        totalBorrowed: (m['total_borrowed'] as num?)?.toDouble() ?? 0,
        totalLent:     (m['total_lent'] as num?)?.toDouble() ?? 0,
      );

  ProfileModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? upiId,
    String? avatarUrl,
  }) =>
      ProfileModel(
        id:            id,
        name:          name ?? this.name,
        email:         email ?? this.email,
        phone:         phone ?? this.phone,
        upiId:         upiId ?? this.upiId,
        avatarUrl:     avatarUrl ?? this.avatarUrl,
        totalBorrowed: totalBorrowed,
        totalLent:     totalLent,
      );
}
