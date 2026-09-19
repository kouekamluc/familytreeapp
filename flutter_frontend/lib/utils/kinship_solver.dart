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

    // 1. Spouses
    final spousesOfA = spouseMap[personAId] ?? [];
    if (spousesOfA.contains(personBId)) {
      return KinshipResult(
        title: 'Spousal Union',
        relationship: bGender == 'F' ? 'Wife' : 'Husband',
        summary: '$bName is the spouse of $aName',
        description: 'Connected in holy matrimony and lineage partnership.',
        culturalHonorific: 'Alliance Sacrée & Rameau Familial',
        generationDifference: 0,
        path: [personA, personB],
      );
    }

    // 2. Direct Parent / Child
    final parentsOfA = parentMap[personAId] ?? [];
    if (parentsOfA.contains(personBId)) {
      return KinshipResult(
        title: bGender == 'M' ? 'Father' : 'Mother',
        relationship: bGender == 'M' ? 'Father (Papa)' : 'Mother (Mama)',
        summary: '$bName is the ${bGender == 'M' ? 'father' : 'mother'} of $aName',
        description: 'Direct biological elder (1 generation above).',
        culturalHonorific: bGender == 'M' ? 'Papa / Pilier de la Lignée' : 'Maman / Source Sacrée',
        generationDifference: 1,
        path: [personA, personB],
      );
    }

    final childrenOfA = childrenMap[personAId] ?? [];
    if (childrenOfA.contains(personBId)) {
      return KinshipResult(
        title: bGender == 'M' ? 'Son' : 'Daughter',
        relationship: bGender == 'M' ? 'Son' : 'Daughter',
        summary: '$bName is the ${bGender == 'M' ? 'son' : 'daughter'} of $aName',
        description: 'Direct biological descendant (1 generation below).',
        culturalHonorific: 'Enfant de la Dynastie',
        generationDifference: -1,
        path: [personA, personB],
      );
    }

    // 3. Siblings (Full or Half)
    final parentsOfB = parentMap[personBId] ?? [];
    final sharedParents = parentsOfA.where((pId) => parentsOfB.contains(pId)).toList();
    if (sharedParents.isNotEmpty) {
      final isFull = sharedParents.length >= 2;
      final sharedNames = sharedParents.map((id) => peopleMap[id]?.firstName ?? 'Elder').join(' & ');
      return KinshipResult(
        title: bGender == 'F' ? 'Sister' : 'Brother',
        relationship: bGender == 'F' ? 'Sister (Sœur)' : 'Brother (Frère)',
        summary: '$bName and $aName are ${bGender == 'F' ? 'sisters' : 'brothers'} sharing parents',
        description: '$isFull sibling sharing the royal bloodline of $sharedNames.',
        culturalHonorific: 'Frère / Sœur de Sang (Même Arbre)',
        generationDifference: 0,
        path: [personA, if (sharedParents.isNotEmpty && peopleMap[sharedParents.first] != null) peopleMap[sharedParents.first]!, personB],
      );
    }

    // 4. Grandparent / Grandchild
    for (final parentId in parentsOfA) {
      final grandParents = parentMap[parentId] ?? [];
      if (grandParents.contains(personBId)) {
        final parent = peopleMap[parentId];
        final side = (parent != null && parent.isFemale) ? 'Maternal' : 'Paternal';
        final title = bGender == 'M' ? '$side Grandfather' : '$side Grandmother';
        return KinshipResult(
          title: title,
          relationship: title,
          summary: '$bName is the $title of $aName',
          description: 'Grandparent 2 generations above through ${parent?.firstName ?? 'parent'}.',
          culturalHonorific: bGender == 'M' ? 'Grand-Père / Patriarche Ancien' : 'Grand-Mère / Reine-Mère',
          generationDifference: 2,
          path: [personA, if (parent != null) parent, personB],
        );
      }
    }

    for (final parentId in parentsOfB) {
      final grandParents = parentMap[parentId] ?? [];
      if (grandParents.contains(personAId)) {
        final parent = peopleMap[parentId];
        final title = bGender == 'M' ? 'Grandson' : 'Granddaughter';
        return KinshipResult(
          title: title,
          relationship: title,
          summary: '$bName is the $title of $aName',
          description: 'Grandchild 2 generations below through ${parent?.firstName ?? 'child'}.',
          culturalHonorific: 'Petit-Fils / Petite-Fille de la Lignée',
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
          final title = bGender == 'M' ? 'Great-Grandfather' : 'Great-Grandmother';
          return KinshipResult(
            title: title,
            relationship: title,
            summary: '$bName is the $title of $aName',
            description: 'Venerated ancestral root 3 generations above.',
            culturalHonorific: 'Arrière-Grand-Parent / Ancêtre Vénéré',
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
          final title = bGender == 'M' ? 'Great-Grandson' : 'Great-Granddaughter';
          return KinshipResult(
            title: title,
            relationship: title,
            summary: '$bName is the $title of $aName',
            description: 'Descendant 3 generations below.',
            culturalHonorific: 'Arrière-Petit-Enfant de la Lignée',
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

    // 6. Aunt / Uncle & Niece / Nephew
    for (final parentId in parentsOfA) {
      final parentsOfMyParent = parentMap[parentId] ?? [];
      final auntsUncles = parentsOfB.where((pId) => parentsOfMyParent.contains(pId)).toList();
      if (auntsUncles.isNotEmpty && personBId != parentId) {
        final parent = peopleMap[parentId];
        final side = (parent != null && parent.isFemale) ? 'Maternal' : 'Paternal';
        final title = bGender == 'M' ? '$side Uncle' : '$side Aunt';
        return KinshipResult(
          title: title,
          relationship: title,
          summary: '$bName is the $title of $aName',
          description: 'Sibling of $aName\'s ${parent != null && parent.isFemale ? 'mother' : 'father'} (${parent?.firstName ?? ''}).',
          culturalHonorific: bGender == 'M' ? 'Oncle / Frère de mon Père' : 'Tante / Sœur de la Maison',
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
        final title = bGender == 'M' ? 'Nephew' : 'Niece';
        return KinshipResult(
          title: title,
          relationship: title,
          summary: '$bName is the $title of $aName',
          description: 'Child of $aName\'s sibling (${parent?.firstName ?? ''}).',
          culturalHonorific: 'Neveu / Nièce du Rameau',
          generationDifference: -1,
          path: [personA, if (parent != null) parent, personB],
        );
      }
    }

    // 7. First Cousins
    for (final parentA in parentsOfA) {
      final gParentsA = parentMap[parentA] ?? [];
      for (final parentB in parentsOfB) {
        final gParentsB = parentMap[parentB] ?? [];
        final commonGPs = gParentsA.where((gp) => gParentsB.contains(gp)).toList();
        if (commonGPs.isNotEmpty && parentA != parentB) {
          final title = bGender == 'F' ? 'First Cousin (Cousine)' : 'First Cousin (Cousin)';
          final commonNames = commonGPs.map((id) => peopleMap[id]?.firstName ?? 'Grandparent').join(' & ');
          return KinshipResult(
            title: 'First Cousins',
            relationship: title,
            summary: '$aName and $bName are First Cousins',
            description: 'Share grandparents $commonNames through siblings ${peopleMap[parentA]?.firstName ?? ''} and ${peopleMap[parentB]?.firstName ?? ''}.',
            culturalHonorific: 'Cousin(e) Germain(e) du Même Sang',
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

    // 8. In-Laws (spouse of sibling)
    final firstParentOfA = parentsOfA.isNotEmpty ? parentsOfA.first : null;
    if (firstParentOfA != null) {
      final siblingsOfA = childrenMap[firstParentOfA] ?? [];
      for (final siblingId in siblingsOfA) {
        if (siblingId != personAId && (spouseMap[siblingId] ?? []).contains(personBId)) {
          final title = bGender == 'M' ? 'Brother-in-law' : 'Sister-in-law';
          return KinshipResult(
            title: title,
            relationship: title,
            summary: '$bName is the $title of $aName',
            description: 'Married to $aName\'s sibling (${peopleMap[siblingId]?.firstName ?? ''}).',
            culturalHonorific: 'Allié(e) par Mariage',
            generationDifference: 0,
            path: [personA, if (peopleMap[siblingId] != null) peopleMap[siblingId]!, personB],
          );
        }
      }
    }

    // 9. General BFS Shortest Path
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
