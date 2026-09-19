class Person {
  final int id;
  final int? familyTreeId;
  final String firstName;
  final String lastName;
  final String gender; // 'M', 'F', 'O'
  final String? dateOfBirth;
  final String? dateOfDeath;
  final String? birthPlace;
  final String? currentLocation;
  final String? traditionalName;
  final String? villageOfOrigin;
  final String? clanTotem;
  final int generationTier;
  final String? biography;
  final bool isLiving;
  final String? profilePicture;
  final List<dynamic>? parentsRaw;
  final List<dynamic>? childrenRaw;
  final List<dynamic>? spousesRaw;
  final List<dynamic>? siblingsRaw;

  Person({
    required this.id,
    this.familyTreeId,
    required this.firstName,
    required this.lastName,
    required this.gender,
    this.dateOfBirth,
    this.dateOfDeath,
    this.birthPlace,
    this.currentLocation,
    this.traditionalName,
    this.villageOfOrigin,
    this.clanTotem,
    this.generationTier = 1,
    this.biography,
    this.isLiving = true,
    this.profilePicture,
    this.parentsRaw,
    this.childrenRaw,
    this.spousesRaw,
    this.siblingsRaw,
  });

  String get fullName {
    final name = '$firstName $lastName'.trim();
    return name.isNotEmpty ? name : 'Unnamed Member';
  }

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final l = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$f$l'.isEmpty ? '?' : '$f$l';
  }

  bool get isMale => gender.toUpperCase() == 'M' || gender.toLowerCase() == 'male';
  bool get isFemale => gender.toUpperCase() == 'F' || gender.toLowerCase() == 'female';

  String get genderLabel {
    if (isFemale) return 'Female';
    if (isMale) return 'Male';
    return 'Other';
  }

  String get birthYear {
    if (dateOfBirth == null || dateOfBirth!.isEmpty) return '';
    try {
      return DateTime.parse(dateOfBirth!).year.toString();
    } catch (_) {
      return dateOfBirth!.split('-').first;
    }
  }

  String get deathYear {
    if (dateOfDeath == null || dateOfDeath!.isEmpty) return '';
    try {
      return DateTime.parse(dateOfDeath!).year.toString();
    } catch (_) {
      return dateOfDeath!.split('-').first;
    }
  }

  String get lifespanText {
    if (!isLiving && deathYear.isNotEmpty) {
      return '${birthYear.isNotEmpty ? birthYear : '?'} - $deathYear';
    }
    if (birthYear.isNotEmpty) {
      return 'b. $birthYear';
    }
    return '';
  }

  bool get isAncestor => !isLiving || generationTier >= 3;

  factory Person.fromJson(Map<String, dynamic> json) {
    int parsedId = 0;
    if (json['id'] is int) {
      parsedId = json['id'];
    } else if (json['id'] != null) {
      parsedId = int.tryParse(json['id'].toString()) ?? 0;
    }

    int? treeId;
    if (json['family_tree'] is int) {
      treeId = json['family_tree'];
    } else if (json['family_tree'] is Map) {
      treeId = json['family_tree']['id'];
    }

    int tier = 1;
    if (json['generation_tier'] != null) {
      tier = int.tryParse(json['generation_tier'].toString()) ?? 1;
    } else if (json['generationTier'] != null) {
      tier = int.tryParse(json['generationTier'].toString()) ?? 1;
    }

    String g = (json['gender'] ?? 'M').toString().toUpperCase();
    if (g.startsWith('F')) {
      g = 'F';
    } else if (g.startsWith('M')) {
      g = 'M';
    } else {
      g = 'O';
    }

    bool living = true;
    if (json['is_living'] != null) {
      living = json['is_living'] == true || json['is_living'] == 'true' || json['is_living'] == 1;
    } else if (json['date_of_death'] != null || json['deathDate'] != null) {
      living = false;
    }

    return Person(
      id: parsedId,
      familyTreeId: treeId,
      firstName: json['first_name'] ?? json['firstName'] ?? '',
      lastName: json['last_name'] ?? json['lastName'] ?? '',
      gender: g,
      dateOfBirth: json['date_of_birth'] ?? json['birthDate'],
      dateOfDeath: json['date_of_death'] ?? json['deathDate'],
      birthPlace: json['birth_place'] ?? json['birthPlace'],
      currentLocation: json['current_location'] ?? json['currentLocation'],
      traditionalName: json['traditional_name'] ?? json['traditionalName'],
      villageOfOrigin: json['village_of_origin'] ?? json['villageOfOrigin'] ?? json['village'],
      clanTotem: json['clan_totem'] ?? json['clanTotem'] ?? json['totem'],
      generationTier: tier,
      biography: json['biography'] ?? '',
      isLiving: living,
      profilePicture: json['profile_picture'] ?? json['avatar'],
      parentsRaw: json['parents'] is List ? json['parents'] : null,
      childrenRaw: json['children'] is List ? json['children'] : null,
      spousesRaw: json['spouses'] is List ? json['spouses'] : null,
      siblingsRaw: json['siblings'] is List ? json['siblings'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (familyTreeId != null) 'family_tree': familyTreeId,
      'first_name': firstName,
      'last_name': lastName,
      'gender': gender,
      'date_of_birth': dateOfBirth,
      'date_of_death': dateOfDeath,
      'birth_place': birthPlace,
      'current_location': currentLocation,
      'traditional_name': traditionalName,
      'village_of_origin': villageOfOrigin,
      'clan_totem': clanTotem,
      'generation_tier': generationTier,
      'biography': biography,
      'is_living': isLiving,
      'profile_picture': profilePicture,
    };
  }

  Person copyWith({
    int? id,
    int? familyTreeId,
    String? firstName,
    String? lastName,
    String? gender,
    String? dateOfBirth,
    String? dateOfDeath,
    String? birthPlace,
    String? currentLocation,
    String? traditionalName,
    String? villageOfOrigin,
    String? clanTotem,
    int? generationTier,
    String? biography,
    bool? isLiving,
    String? profilePicture,
  }) {
    return Person(
      id: id ?? this.id,
      familyTreeId: familyTreeId ?? this.familyTreeId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      dateOfDeath: dateOfDeath ?? this.dateOfDeath,
      birthPlace: birthPlace ?? this.birthPlace,
      currentLocation: currentLocation ?? this.currentLocation,
      traditionalName: traditionalName ?? this.traditionalName,
      villageOfOrigin: villageOfOrigin ?? this.villageOfOrigin,
      clanTotem: clanTotem ?? this.clanTotem,
      generationTier: generationTier ?? this.generationTier,
      biography: biography ?? this.biography,
      isLiving: isLiving ?? this.isLiving,
      profilePicture: profilePicture ?? this.profilePicture,
    );
  }
}
