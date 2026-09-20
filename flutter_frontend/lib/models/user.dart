class User {
  final int id;
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? profilePicture;
  final String? primaryHeritageKey;
  final bool isStaff;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    this.profilePicture,
    this.primaryHeritageKey,
    this.isStaff = false,
  });

  String get displayName {
    final full = '${firstName ?? ''} ${lastName ?? ''}'.trim();
    return full.isNotEmpty ? full : username;
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? json['firstName'],
      lastName: json['last_name'] ?? json['lastName'],
      profilePicture: json['profile_picture'] ?? json['avatar'],
      primaryHeritageKey: json['primary_heritage_key'],
      isStaff: json['is_staff'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'profile_picture': profilePicture,
      'primary_heritage_key': primaryHeritageKey,
      'is_staff': isStaff,
    };
  }
}
