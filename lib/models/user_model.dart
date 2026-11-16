class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String photoUrl;
  final int points;
  final int masteredCount;
  final String targetLevel;
  final bool isPremium;
  final DateTime? premiumExpiry;
  final String subscriptionType;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    this.points = 0,
    this.masteredCount = 0,
    this.targetLevel = 'N3',
    this.isPremium = false,
    this.premiumExpiry,
    this.subscriptionType = 'none',
  });

  bool get isAdmin => email.trim().toLowerCase() == 'hariswarsamasi@gmail.com';

  bool get hasActivePremium {
    if (!isPremium) return false;
    if (premiumExpiry != null && premiumExpiry!.isBefore(DateTime.now())) {
      return false;
    }
    return true;
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      uid: id,
      email: map['email']?.toString() ?? '',
      displayName: map['displayName']?.toString() ?? 'Learner',
      photoUrl: map['photoUrl']?.toString() ?? '',
      points: map['points'] is int ? map['points'] : int.tryParse(map['points']?.toString() ?? '0') ?? 0,
      masteredCount: map['masteredCount'] is int ? map['masteredCount'] : int.tryParse(map['masteredCount']?.toString() ?? '0') ?? 0,
      targetLevel: map['targetLevel']?.toString() ?? 'N3',
      isPremium: map['isPremium'] == true,
      premiumExpiry: map['premiumExpiry'] != null ? DateTime.tryParse(map['premiumExpiry'].toString()) : null,
      subscriptionType: map['subscriptionType']?.toString() ?? 'none',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'points': points,
      'masteredCount': masteredCount,
      'targetLevel': targetLevel,
      'isPremium': isPremium,
      'premiumExpiry': premiumExpiry?.toIso8601String(),
      'subscriptionType': subscriptionType,
    };
  }

  UserModel copyWith({
    String? displayName,
    String? photoUrl,
    int? points,
    int? masteredCount,
    String? targetLevel,
    bool? isPremium,
    DateTime? premiumExpiry,
    String? subscriptionType,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      points: points ?? this.points,
      masteredCount: masteredCount ?? this.masteredCount,
      targetLevel: targetLevel ?? this.targetLevel,
      isPremium: isPremium ?? this.isPremium,
      premiumExpiry: premiumExpiry ?? this.premiumExpiry,
      subscriptionType: subscriptionType ?? this.subscriptionType,
    );
  }
}
