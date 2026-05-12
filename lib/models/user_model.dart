/// Data model representing an app user and their child's profile.
///
/// Fields map to data collected across the auth flow:
/// - [email]: from RegisterScreen
/// - [childName], [birthday], [disorderType1], [disorderType2]: from AdditionalInfoScreen
class UserModel {
  final String uid;
  final String email;
  final String childName;
  final String birthday;
  final String? disorderType1;
  final String? disorderType2;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.childName,
    required this.birthday,
    this.disorderType1,
    this.disorderType2,
    required this.createdAt,
  });

  /// Converts this model to a Map for Firestore writes.
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'childName': childName,
      'birthday': birthday,
      'disorderType1': disorderType1,
      'disorderType2': disorderType2,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Creates a [UserModel] from a Firestore document map.
  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] as String? ?? '',
      childName: map['childName'] as String? ?? '',
      birthday: map['birthday'] as String? ?? '',
      disorderType1: map['disorderType1'] as String?,
      disorderType2: map['disorderType2'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
    );
  }

  /// Returns a copy with updated fields.
  UserModel copyWith({
    String? childName,
    String? birthday,
    String? disorderType1,
    String? disorderType2,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      childName: childName ?? this.childName,
      birthday: birthday ?? this.birthday,
      disorderType1: disorderType1 ?? this.disorderType1,
      disorderType2: disorderType2 ?? this.disorderType2,
      createdAt: createdAt,
    );
  }
}
