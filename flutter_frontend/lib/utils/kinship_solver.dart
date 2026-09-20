import '../models/person.dart';
import '../models/relationship.dart';

class KinshipResult {
  final String title;
  final String relationship;
  final String summary;
  final String description;
  final String culturalHonorific;
  final int generationDifference;
  final List<Person> path;

  KinshipResult({
    required this.title,
    required this.relationship,
    required this.summary,
    required this.description,
    required this.culturalHonorific,
    required this.generationDifference,
    required this.path,
  });
}

class KinshipSolver {
  static KinshipResult? calculateKinship({
    required int personAId,
    required int personBId,
    required List<Person> people,
    required List<Relationship> relationships,
  }) {
    if (personAId == 0 || personBId == 0) return null;

    final peopleMap = {for (var p in people) p.id: p};
    final personA = peopleMap[personAId];
    final personB = peopleMap[personBId];

    if (personA == null || personB == null) return null;

    if (personAId == personBId) {
      return KinshipResult(
        title: 'Same Person',
        relationship: 'Self',
        summary: '${personA.fullName} is viewing their own profile.',
        description: 'Viewing current person profile.',
        culturalHonorific: 'Le Pilier',
        generationDifference: 0,
        path: [personA],
      );
    }

    final parentMap = <int, List<int>>{}; // childId -> [parentId]
    final childrenMap = <int, List<int>>{}; // parentId -> [childId]
    final spouseMap = <int, List<int>>{}; // personId -> [spouseId]
    final graph = <int, List<Map<String, dynamic>>>{}; // id -> [{ targetId, type }]

    for (var r in relationships) {
      final p1 = r.person1Id;
      final p2 = r.person2Id;
      final type = r.relationshipType.toUpperCase();

      graph.putIfAbsent(p1, () => []);
      graph.putIfAbsent(p2, () => []);

      if (type == 'PARENT') {
        parentMap.putIfAbsent(p2, () => []).add(p1);
        childrenMap.putIfAbsent(p1, () => []).add(p2);

        graph[p1]!.add({'targetId': p2, 'type': 'child'});
        graph[p2]!.add({'targetId': p1, 'type': 'parent'});
      } else if (type == 'SPOUSE') {
        spouseMap.putIfAbsent(p1, () => []).add(p2);
        spouseMap.putIfAbsent(p2, () => []).add(p1);

        graph[p1]!.add({'targetId': p2, 'type': 'spouse'});
        graph[p2]!.add({'targetId': p1, 'type': 'spouse'});
      }
    }

    final bGender = personB.isFemale ? 'F' : 'M';
    final aName = personA.fullName;
    final bName = personB.fullName;

    // 1. Spouses (Alliance Coutumière)
    final spousesOfA = spouseMap[personAId] ?? [];
    if (spousesOfA.contains(personBId)) {
      return KinshipResult(
        title: 'Alliance Coutumière & Mariage',
        relationship: bGender == 'F' ? 'Épouse / Partenaire' : 'Époux / Partenaire',
        summary: '$bName est ${bGender == 'F' ? "l'épouse" : "l'époux"} de $aName',
        description: 'Alliance sacrée scellée par la tradition coutumière et la dot unissant les concessions.',
        culturalHonorific: bGender == 'F' ? 'Épouse de la Concession (Alliance Sacrée)' : 'Époux & Protecteur de l\'Alliance',
        generationDifference: 0,
        path: [personA, personB],
      );
    }

    // 1b. Co-Wives (Co-Épouses dans la polygamie coutumière)
    final sharedSpouses = spousesOfA.where((s) => (spouseMap[personBId] ?? []).contains(s)).toList();
    if (sharedSpouses.isNotEmpty && personAId != personBId) {
      final commonSpouse = peopleMap[sharedSpouses.first];
      final spouseName = commonSpouse?.fullName ?? 'l\'Époux';
      return KinshipResult(
        title: 'Co-Épouse (Polygamie Coutumière)',
        relationship: 'Co-Épouse de Concession',
        summary: '$bName et $aName sont co-épouses unies à $spouseName',
        description: 'Mères et épouses alliées au sein de la grande chefferie et concession.',
        culturalHonorific: 'Co-Épouse / Mère de Concession Partagée',
        generationDifference: 0,
        path: [personA, if (commonSpouse != null) commonSpouse, personB],
      );
    }

    // 2. Direct Parent / Child
    final parentsOfA = parentMap[personAId] ?? [];
    final parentsOfB = parentMap[personBId] ?? [];
    if (parentsOfA.contains(personBId)) {
      return KinshipResult(
        title: bGender == 'M' ? 'Père (Papa)' : 'Mère (Mama)',
        relationship: bGender == 'M' ? 'Père (Papa)' : 'Mère (Mama)',
        summary: '$bName est le ${bGender == 'M' ? 'père' : 'la mère'} de $aName',
        description: 'Ascendant biologique direct et autorité de la lignée.',
        culturalHonorific: bGender == 'M' ? 'Papa / Pilier de la Chefferie' : 'Mama / Source Sacrée de Vie',
        generationDifference: 1,
        path: [personA, personB],
      );
    }

    final childrenOfA = childrenMap[personAId] ?? [];
    if (childrenOfA.contains(personBId)) {
      return KinshipResult(
        title: bGender == 'M' ? 'Fils' : 'Fille',
        relationship: bGender == 'M' ? 'Fils (Enfant de la Lignée)' : 'Fille (Enfant de la Lignée)',
        summary: '$bName est le ${bGender == 'M' ? 'fils' : 'la fille'} de $aName',
        description: 'Descendant direct et héritier des traditions ancestrales.',
        culturalHonorific: bGender == 'M' ? 'Fils / Prince de la Lignée' : 'Fille / Princesse de la Lignée',
        generationDifference: -1,
        path: [personA, personB],
      );
    }

    // 2b. Co-Mother (Petite Maman) & Customary Child (Enfant de Concession)
    for (final pId in parentsOfA) {
      final pSpouses = spouseMap[pId] ?? [];
      if (pSpouses.contains(personBId) && !parentsOfA.contains(personBId)) {
        final parent = peopleMap[pId];
        return KinshipResult(
          title: bGender == 'F' ? 'Petite Maman (Co-Mère)' : 'Beau-Père Coutumier',
          relationship: bGender == 'F' ? 'Petite Maman (Deuxième Mère)' : 'Beau-Père de Concession',
          summary: '$bName est l\'épouse du père de $aName (${parent?.fullName ?? ''})',
          description: 'Mère coutumière et gardienne respectée au sein de la concession familiale.',
          culturalHonorific: 'Petite Maman / Co-Mère de Concession',
          generationDifference: 1,
          path: [personA, if (parent != null) parent, personB],
        );
      }
    }

    for (final pId in parentsOfB) {
      final pSpouses = spouseMap[pId] ?? [];
      if (pSpouses.contains(personAId) && !parentsOfB.contains(personAId)) {
        final parent = peopleMap[pId];
        return KinshipResult(
          title: 'Enfant de la Concession',
          relationship: bGender == 'M' ? 'Fils Coutumier' : 'Fille Coutumière',
          summary: '$bName est l\'enfant de la concession conjugale (${parent?.fullName ?? ''})',
          description: 'Enfant élevé dans la chefferie au sein du cercle familial coutumier.',
          culturalHonorific: 'Enfant de la Concession (Fils/Fille Coutumier)',
          generationDifference: -1,
          path: [personA, if (parent != null) parent, personB],
        );
      }
    }

    // 3. Siblings (Germains, Consanguins, Utérins)
    final sharedParents = parentsOfA.where((pId) => parentsOfB.contains(pId)).toList();
    if (sharedParents.isNotEmpty) {
      final sharedMales = sharedParents.where((id) => peopleMap[id]?.isMale == true).toList();
      final sharedFemales = sharedParents.where((id) => peopleMap[id]?.isFemale == true).toList();

      String siblingType;
      String culturalHonorific;
      String desc;

      if (sharedMales.isNotEmpty && sharedFemales.isNotEmpty) {
        siblingType = bGender == 'F' ? 'Sœur Germaine' : 'Frère Germain';
        culturalHonorific = 'Frère/Sœur Germain(e) — Même Père, Même Mère';
        final fName = peopleMap[sharedMales.first]?.firstName ?? 'Père';
        final mName = peopleMap[sharedFemales.first]?.firstName ?? 'Mère';
        desc = 'Partageant à la fois le sang du père ($fName) et le ventre de la mère ($mName).';
      } else if (sharedMales.isNotEmpty) {
        siblingType = bGender == 'F' ? 'Sœur Consanguine' : 'Frère Consanguin';
        culturalHonorific = 'Frère/Sœur Consanguin(e) — Même Père, Concessions Différentes';
        final fName = peopleMap[sharedMales.first]?.firstName ?? 'Père';
        desc = 'Issus du même père ($fName), nés de concessions ou foyers différents.';
      } else {
        siblingType = bGender == 'F' ? 'Sœur Utérine' : 'Frère Utérin';
        culturalHonorific = 'Frère/Sœur Utérin(e) — Même Ventre (Lien Sacré Maa)';
        final mName = peopleMap[sharedFemales.first]?.firstName ?? 'Mère';
        desc = 'Issus du même ventre maternel ($mName), lien sacré et indissoluble de la tradition Grassfields.';
      }

      return KinshipResult(
        title: siblingType,
        relationship: siblingType,
        summary: '$bName est le/la $siblingType de $aName',
        description: desc,
        culturalHonorific: culturalHonorific,
        generationDifference: 0,
        path: [personA, peopleMap[sharedParents.first]!, personB],
      );
    }

    // 4. Grandparent / Grandchild
    for (final parentId in parentsOfA) {
      final grandParents = parentMap[parentId] ?? [];
      if (grandParents.contains(personBId)) {
        final parent = peopleMap[parentId];
        final side = (parent != null && parent.isFemale) ? 'Maternel(le)' : 'Paternel(le)';
        final title = bGender == 'M' ? 'Grand-Père $side' : 'Grand-Mère $side';
        return KinshipResult(
          title: title,
          relationship: title,
          summary: '$bName est le/la $title de $aName',
          description: 'Ancêtre direct à 2 générations au-dessus via ${parent?.fullName ?? 'parent'}.',
          culturalHonorific: bGender == 'M' ? 'Grand-Père / Patriarche Ancien' : 'Grand-Mère / Reine-Mère Sacrée',
          generationDifference: 2,
          path: [personA, if (parent != null) parent, personB],
        );
      }
    }

    for (final parentId in parentsOfB) {
      final grandParents = parentMap[parentId] ?? [];
      if (grandParents.contains(personAId)) {
        final parent = peopleMap[parentId];
        final title = bGender == 'M' ? 'Petit-Fils' : 'Petite-Fille';
        return KinshipResult(
          title: title,
          relationship: title,
          summary: '$bName est le/la $title de $aName',
          description: 'Descendant à 2 générations en dessous via ${parent?.fullName ?? 'enfant'}.',
          culturalHonorific: 'Petit-Fils / Petite-Fille de la Concession',
          generationDifference: -2,
          path: [personA, if (parent != null) parent, personB],
        );
      }
    }

    // 5. Great-Grandparent / Great-Grandchild
    for (final parentId in parentsOfA) {
      final grandParents = parentMap[parentId] ?? [];
      for (final gpId in grandParents) {
        final greatGPs = parentMap[gpId] ?? [];
        if (greatGPs.contains(personBId)) {
          final title = bGender == 'M' ? 'Arrière-Grand-Père' : 'Arrière-Grand-Mère';
          return KinshipResult(
            title: title,
            relationship: title,
            summary: '$bName est le/la $title de $aName',
            description: 'Racine ancestrale vénérée 3 générations au-dessus.',
            culturalHonorific: 'Arrière-Grand-Parent / Ancêtre Fondateur',
            generationDifference: 3,
            path: [
              personA,
              if (peopleMap[parentId] != null) peopleMap[parentId]!,
              if (peopleMap[gpId] != null) peopleMap[gpId]!,
              personB,
            ],
          );
        }
      }
    }

    for (final parentId in parentsOfB) {
      final grandParents = parentMap[parentId] ?? [];
      for (final gpId in grandParents) {
        final greatGPs = parentMap[gpId] ?? [];
        if (greatGPs.contains(personAId)) {
          final title = bGender == 'M' ? 'Arrière-Petit-Fils' : 'Arrière-Petite-Fille';
          return KinshipResult(
            title: title,
            relationship: title,
            summary: '$bName est le/la $title de $aName',
            description: 'Descendant 3 générations en dessous.',
            culturalHonorific: 'Arrière-Petit-Enfant de la Dynastie',
            generationDifference: -3,
            path: [
              personA,
              if (peopleMap[gpId] != null) peopleMap[gpId]!,
              if (peopleMap[parentId] != null) peopleMap[parentId]!,
              personB,
            ],
          );
        }
      }
    }

    // 6. Aunt / Uncle & Niece / Nephew (Grassfields Customary Honorifics)
    for (final parentId in parentsOfA) {
      final parentsOfMyParent = parentMap[parentId] ?? [];
      final auntsUncles = parentsOfB.where((pId) => parentsOfMyParent.contains(pId)).toList();
      if (auntsUncles.isNotEmpty && personBId != parentId) {
        final parent = peopleMap[parentId];
        final isMaternal = (parent != null && parent.isFemale);
        final pName = parent?.firstName ?? '';

        String title;
        String culturalHonorific;
        String desc;

        if (isMaternal) {
          if (bGender == 'M') {
            title = 'Oncle Maternel (Wamba / Menfo)';
            culturalHonorific = 'Wamba — Source de Bénédiction Ancestrale & Protecteur Coutumier';
            desc = 'Frère de la mère ($pName), détenteur des droits sacrés de bénédiction (Kouh-gan).';
          } else {
            title = 'Tante Maternelle (Petite Maman)';
            culturalHonorific = 'Petite Maman / Douceur du Foyer Maternel';
            desc = 'Sœur de la mère ($pName), deuxième mère nourricière.';
          }
        } else {
          if (bGender == 'M') {
            title = 'Oncle Paternel (Petit Papa)';
            culturalHonorific = 'Petit Papa / Pilier de la Chefferie Paternelle';
            desc = 'Frère du père ($pName), co-père respecté de la concession.';
          } else {
            title = 'Tante Paternelle (Mafo Coutumière)';
            culturalHonorific = 'Mafo / Dignitaire de la Lignée Paternelle';
            desc = 'Sœur du père ($pName), femme-père et reine de la lignée.';
          }
        }

        return KinshipResult(
          title: title,
          relationship: title,
          summary: '$bName est le/la $title de $aName',
          description: desc,
          culturalHonorific: culturalHonorific,
          generationDifference: 1,
          path: [personA, if (parent != null) parent, personB],
        );
      }
    }

    for (final parentId in parentsOfB) {
      final parentsOfBParent = parentMap[parentId] ?? [];
      final sharedWithA = parentsOfA.where((pId) => parentsOfBParent.contains(pId)).toList();
      if (sharedWithA.isNotEmpty && personAId != parentId) {
        final parent = peopleMap[parentId];
        final isAunt = personA.isFemale;
        String title;
        String culturalHonorific;
        String desc;

        if (isAunt) {
          title = bGender == 'M' ? 'Neveu Utérin (Wô-Maa)' : 'Nièce Utérine (Wô-Maa)';
          culturalHonorific = 'Neveu/Nièce Utérin(e) — Enfant Sacré de ma Sœur';
          desc = 'Enfant de la sœur (${parent?.firstName ?? ''}), lien de maternité sacrée.';
        } else {
          title = bGender == 'M' ? 'Neveu (Enfant du Frère)' : 'Nièce (Enfant du Frère)';
          culturalHonorific = 'Descendant de la Concession Fraternelle';
          desc = 'Enfant du frère (${parent?.firstName ?? ''}), perpétuant le rameau paternel.';
        }

        return KinshipResult(
          title: title,
          relationship: title,
          summary: '$bName est le/la $title de $aName',
          description: desc,
          culturalHonorific: culturalHonorific,
          generationDifference: -1,
          path: [personA, if (parent != null) parent, personB],
        );
      }
    }

    // 7. Customary In-Laws (Beaux-Parents & Gendres/Belles-Filles)
    for (final spId in spousesOfA) {
      final spParents = parentMap[spId] ?? [];
      if (spParents.contains(personBId)) {
        final sp = peopleMap[spId];
        final title = bGender == 'M' ? 'Beau-Père Coutumier' : 'Belle-Mère Coutumière';
        return KinshipResult(
          title: title,
          relationship: title,
          summary: '$bName est le/la $title de $aName',
          description: 'Parent de l\'époux/épouse (${sp?.fullName ?? ''}) — Alliance d\'honneur et de dot.',
          culturalHonorific: bGender == 'M' ? 'Beau-Père / Grand Allié de la Dot' : 'Belle-Mère / Reine de l\'Alliance',
          generationDifference: 1,
          path: [personA, if (sp != null) sp, personB],
        );
      }
    }

    for (final cId in childrenOfA) {
      final cSpouses = spouseMap[cId] ?? [];
      if (cSpouses.contains(personBId)) {
        final c = peopleMap[cId];
        final title = bGender == 'M' ? 'Gendre (Beau-Fils)' : 'Belle-Fille (Épouse du Foyer)';
        return KinshipResult(
          title: title,
          relationship: title,
          summary: '$bName est le/la $title de $aName',
          description: 'Conjoint(e) de l\'enfant (${c?.fullName ?? ''}) accueilli(e) dans la famille par dot et alliance.',
          culturalHonorific: bGender == 'M' ? 'Gendre / Donateur de la Dot' : 'Belle-Fille / Fleur de la Concession',
          generationDifference: -1,
          path: [personA, if (c != null) c, personB],
        );
      }
    }

    // 8. In-Laws (Beau-Frère / Belle-Sœur via fratrie)
    for (final pId in parentsOfA) {
      final sibs = childrenMap[pId] ?? [];
      for (final sId in sibs) {
        if (sId != personAId && (spouseMap[sId] ?? []).contains(personBId)) {
          final title = bGender == 'M' ? 'Beau-Frère' : 'Belle-Sœur';
          return KinshipResult(
            title: title,
            relationship: title,
            summary: '$bName est le/la $title de $aName',
            description: 'Conjoint(e) du frère/de la sœur (${peopleMap[sId]?.firstName ?? ''}).',
            culturalHonorific: 'Allié(e) Précieux(se) par Alliance Coutumière',
            generationDifference: 0,
            path: [personA, if (peopleMap[sId] != null) peopleMap[sId]!, personB],
          );
        }
      }
    }

    // 9. First Cousins (Cousins Germains par Alliance et Lignée)
    for (final parentA in parentsOfA) {
      final gParentsA = parentMap[parentA] ?? [];
      for (final parentB in parentsOfB) {
        final gParentsB = parentMap[parentB] ?? [];
        final commonGPs = gParentsA.where((gp) => gParentsB.contains(gp)).toList();
        if (commonGPs.isNotEmpty && parentA != parentB) {
          final title = bGender == 'F' ? 'Cousine Germaine' : 'Cousin Germain';
          final commonNames = commonGPs.map((id) => peopleMap[id]?.firstName ?? 'Ancêtre').join(' & ');
          final pAName = peopleMap[parentA]?.firstName ?? '';
          final pBName = peopleMap[parentB]?.firstName ?? '';
          return KinshipResult(
            title: 'Cousins Germains',
            relationship: title,
            summary: '$aName et $bName sont cousins germains',
            description: 'Partagent les grands-parents $commonNames via les fratries de $pAName et $pBName.',
            culturalHonorific: 'Cousin(e) Germain(e) de la Grande Concession',
            generationDifference: 0,
            path: [
              personA,
              if (peopleMap[parentA] != null) peopleMap[parentA]!,
              if (peopleMap[commonGPs.first] != null) peopleMap[commonGPs.first]!,
              if (peopleMap[parentB] != null) peopleMap[parentB]!,
              personB,
            ],
          );
        }
      }
    }

    // 10. General BFS Shortest Path
    final queue = <Map<String, dynamic>>[
      {'id': personAId, 'path': <Person>[personA]}
    ];
    final visited = <int>{personAId};

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      final int currId = current['id'];
      final List<Person> currPath = List<Person>.from(current['path']);

      if (currId == personBId) {
        final stepCount = currPath.length - 1;
        return KinshipResult(
          title: 'Extended Kin',
          relationship: 'Extended Kin',
          summary: '$aName and $bName are connected via a $stepCount-step bloodline path',
          description: 'Connected along the royal lineage tree.',
          culturalHonorific: 'Parent de la Grande Famille Royale',
          generationDifference: stepCount,
          path: currPath,
        );
      }

      final neighbors = graph[currId] ?? [];
      for (final n in neighbors) {
        final targetId = n['targetId'] as int;
        if (!visited.contains(targetId)) {
          visited.add(targetId);
          final nextPerson = peopleMap[targetId];
          if (nextPerson != null) {
            queue.add({
              'id': targetId,
              'path': [...currPath, nextPerson],
            });
          }
        }
      }
    }

    return KinshipResult(
      title: 'Unlinked Branches',
      relationship: 'Unlinked',
      summary: 'No direct kinship link recorded between $aName and $bName yet.',
      description: 'Add a connecting parent, spouse, or child to unite their branches.',
      culturalHonorific: 'Membres du Même Royaume',
      generationDifference: 0,
      path: [personA, personB],
    );
  }
}
