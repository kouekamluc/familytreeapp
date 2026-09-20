import '../models/person.dart';
import '../models/relationship.dart';

class FamilyKinshipSummary {
  final String lineageRole; // e.g., "Great-Grandfather", "Father", "Great-Granddaughter"
  final String culturalRole; // e.g., "Patriarch 👑", "Royal Matron", "4th-Gen Princess"
  final Person? father;
  final Person? mother;
  final List<Person> spouses;
  final List<Person> sons;
  final List<Person> daughters;
  final List<Person> brothers;
  final List<Person> sisters;

  FamilyKinshipSummary({
    required this.lineageRole,
    required this.culturalRole,
    this.father,
    this.mother,
    required this.spouses,
    required this.sons,
    required this.daughters,
    required this.brothers,
    required this.sisters,
  });

  List<Person> get allChildren => [...sons, ...daughters];
  List<Person> get allSiblings => [...brothers, ...sisters];
}

class GenealogyHelper {
  static FamilyKinshipSummary getKinshipSummary(
    Person person,
    List<Person> allPeople,
    List<Relationship> relationships,
  ) {
    final peopleMap = {for (var p in allPeople) p.id: p};

    // Find Parents
    final parentIds = relationships
        .where((r) => r.person2Id == person.id && r.isParent)
        .map((r) => r.person1Id)
        .toList();

    Person? father;
    Person? mother;
    for (final pid in parentIds) {
      final p = peopleMap[pid];
      if (p != null) {
        if (p.isMale && father == null) {
          father = p;
        } else if (p.isFemale && mother == null) {
          mother = p;
        } else {
          father ??= p;
        }
      }
    }

    // Find Spouses
    final spouseIds = <int>{};
    for (final r in relationships) {
      if (r.isSpouse) {
        if (r.person1Id == person.id) spouseIds.add(r.person2Id);
        if (r.person2Id == person.id) spouseIds.add(r.person1Id);
      }
    }
    final spouses = spouseIds.map((id) => peopleMap[id]).whereType<Person>().toList();

    // Find Children
    final childIds = relationships
        .where((r) => r.person1Id == person.id && r.isParent)
        .map((r) => r.person2Id)
        .toList();
    final sons = <Person>[];
    final daughters = <Person>[];
    for (final cid in childIds) {
      final c = peopleMap[cid];
      if (c != null) {
        if (c.isMale) {
          sons.add(c);
        } else {
          daughters.add(c);
        }
      }
    }

    // Find Siblings
    final brothers = <Person>[];
    final sisters = <Person>[];
    if (parentIds.isNotEmpty) {
      final siblingIds = relationships
          .where((r) => r.isParent && parentIds.contains(r.person1Id) && r.person2Id != person.id)
          .map((r) => r.person2Id)
          .toSet();

      for (final sid in siblingIds) {
        final s = peopleMap[sid];
        if (s != null) {
          if (s.isMale) {
            brothers.add(s);
          } else {
            sisters.add(s);
          }
        }
      }
    }

    // Calculate Lineage Role & Cultural Role
    String lineageRole;
    String culturalRole;

    final isMale = person.isMale;
    final tier = person.generationTier;
    final hasChildren = sons.isNotEmpty || daughters.isNotEmpty;

    final trad = (person.traditionalName ?? '').toLowerCase();
    if (person.traditionalName != null && person.traditionalName!.trim().isNotEmpty) {
      culturalRole = person.traditionalName!.trim();
      if (!culturalRole.contains('👑') && !culturalRole.contains('🌱')) {
        if (tier == 1) {
          culturalRole = '$culturalRole 👑';
        } else if (tier >= 4) {
          culturalRole = '$culturalRole 🌱';
        }
      }
    } else if (trad.contains('fo') || trad.contains('chef')) {
      culturalRole = 'Fo (Chef Supérieur) 👑';
    } else if (trad.contains('mafo')) {
      culturalRole = 'Mafo (Reine Mère) 👑';
    } else if (trad.contains('tadji')) {
      culturalRole = 'Tadji (Notable Successeur)';
    } else if (trad.contains('wamba') || trad.contains('wambo')) {
      culturalRole = 'Wamba (Grand Dignitaire)';
    } else if (trad.contains('mefe') || trad.contains('magne')) {
      culturalRole = 'Mefe / Magne (Reine de Concession)';
    } else if (trad.contains('nji') || trad.contains('soh')) {
      culturalRole = 'Prince / Notable de Concession';
    } else if (tier == 1) {
      culturalRole = isMale ? 'Patriarche Fondateur 👑' : 'Matriarche Fondatrice 👑';
    } else if (tier == 2) {
      culturalRole = isMale
          ? (hasChildren ? 'Pilier de la Chefferie' : 'Dignitaire de Concession')
          : (hasChildren ? 'Mère Gardienne du Foyer' : 'Gardienne Coutumière');
    } else if (tier == 3) {
      culturalRole = isMale
          ? (hasChildren ? 'Prince de la Lignée' : 'Jeune Prince Héritier')
          : (hasChildren ? 'Princesse de la Lignée' : 'Jeune Princesse Héritière');
    } else if (tier >= 4) {
      culturalRole = isMale ? 'Prince 4ème Génération 🌱' : 'Princesse 4ème Génération 🌱';
    } else {
      culturalRole = 'Membre de la Grande Concession';
    }

    if (tier == 1) {
      lineageRole = isMale ? 'Arrière-Grand-Père / Patriarche' : 'Arrière-Grand-Mère / Matriarche';
    } else if (tier == 2) {
      lineageRole = isMale ? (hasChildren ? 'Père' : 'Oncle de la Dynastie') : (hasChildren ? 'Mère' : 'Tante de la Dynastie');
    } else if (tier == 3) {
      lineageRole = isMale ? (hasChildren ? 'Père / Petit-Fils' : 'Fils / Petit-Fils') : (hasChildren ? 'Mère / Petite-Fille' : 'Fille / Petite-Fille');
    } else if (tier >= 4) {
      lineageRole = isMale ? 'Arrière-Petit-Fils' : 'Arrière-Petite-Fille';
    } else {
      lineageRole = 'Membre de la Famille';
    }

    return FamilyKinshipSummary(
      lineageRole: lineageRole,
      culturalRole: culturalRole,
      father: father,
      mother: mother,
      spouses: spouses,
      sons: sons,
      daughters: daughters,
      brothers: brothers,
      sisters: sisters,
    );
  }
}
