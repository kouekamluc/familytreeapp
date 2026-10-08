import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import '../models/person.dart';
import '../models/relationship.dart';

class FamilyGraphLayout {
  final Map<int, Offset> positions;
  final Map<int, int> generations;
  const FamilyGraphLayout(this.positions, this.generations);
}

/// Couples share a generation irrespective of record order or tier metadata.
/// Child ordering uses actual parents, including each union in a plural family.
FamilyGraphLayout layoutFamilyGraph(
  List<Person> people,
  List<Relationship> relationships, {
  required double cardWidth,
  required double cardHeight,
  double partnerGap = 40,
  double branchGap = 36,
  double generationGap = 84,
  bool orderByParents = true,
}) {
  final byId = {for (final p in people) p.id: p};
  final ids = byId.keys.toList()..sort();
  final links = relationships
      .where(
        (r) => byId.containsKey(r.person1Id) && byId.containsKey(r.person2Id),
      )
      .toList();
  final representatives = {for (final id in ids) id: id};
  int root(int id) {
    if (representatives[id] != id) {
      representatives[id] = root(representatives[id]!);
    }
    return representatives[id]!;
  }

  void join(int a, int b) {
    final ra = root(a), rb = root(b);
    if (ra != rb) representatives[math.max(ra, rb)] = math.min(ra, rb);
  }

  for (final r in links.where((r) => r.isSpouse)) {
    join(r.person1Id, r.person2Id);
  }
  final units = <int, List<int>>{};
  for (final id in ids) {
    units.putIfAbsent(root(id), () => []).add(id);
  }
  final personUnit = {for (final id in ids) id: root(id)};
  final partners = <int, Set<int>>{};
  for (final r in links.where((r) => r.isSpouse)) {
    partners.putIfAbsent(r.person1Id, () => {}).add(r.person2Id);
    partners.putIfAbsent(r.person2Id, () => {}).add(r.person1Id);
  }
  for (final adults in units.values) {
    adults.sort((a, b) {
      final degree = (partners[b]?.length ?? 0).compareTo(
        partners[a]?.length ?? 0,
      );
      return degree != 0 ? degree : a.compareTo(b);
    });
    // Put the shared partner between partners where possible, rather than
    // drawing a line through one spouse's card to reach another spouse.
    if (adults.length > 2) {
      final hub = adults.removeAt(0);
      adults.sort();
      adults.insert(adults.length ~/ 2, hub);
    }
  }
  // Sibling constraints align separate household units without asserting
  // unknown parents or treating siblings as partners.
  final rankParents = {for (final key in units.keys) key: key};
  int rankRoot(int id) {
    if (rankParents[id] != id) rankParents[id] = rankRoot(rankParents[id]!);
    return rankParents[id]!;
  }

  for (final r in links.where((r) => r.isSibling)) {
    final a = rankRoot(personUnit[r.person1Id]!),
        b = rankRoot(personUnit[r.person2Id]!);
    if (a != b) rankParents[math.max(a, b)] = math.min(a, b);
  }
  final rankIds = units.keys.map(rankRoot).toSet();
  final rankEdges = <int, Set<int>>{};
  final incoming = {for (final id in rankIds) id: 0};
  final actualParents = <int, Set<int>>{};
  for (final r in links.where((r) => r.isParent)) {
    actualParents.putIfAbsent(r.person2Id, () => {}).add(r.person1Id);
    final a = rankRoot(personUnit[r.person1Id]!),
        b = rankRoot(personUnit[r.person2Id]!);
    if (a != b && rankEdges.putIfAbsent(a, () => {}).add(b)) {
      incoming[b] = incoming[b]! + 1;
    }
  }
  final ranks = {for (final id in rankIds) id: 0};
  final queue = rankIds.where((id) => incoming[id] == 0).toList()..sort();
  for (var index = 0; index < queue.length; index++) {
    final id = queue[index];
    for (final child in rankEdges[id] ?? <int>{}) {
      ranks[child] = math.max(ranks[child]!, ranks[id]! + 1);
      incoming[child] = incoming[child]! - 1;
      if (incoming[child] == 0) queue.add(child);
    }
  }
  // Invalid contradictory constraints must still terminate and show records.
  final generations = {
    for (final id in ids) id: ranks[rankRoot(personUnit[id]!)]!,
  };
  final rows = <int, List<int>>{};
  for (final unit in units.keys) {
    rows.putIfAbsent(generations[units[unit]!.first]!, () => []).add(unit);
  }
  final levels = rows.keys.toList()..sort();
  final positions = <int, Offset>{};
  double width(int unit) =>
      units[unit]!.length * cardWidth + (units[unit]!.length - 1) * partnerGap;
  double? desired(int unit) {
    final parentIds = units[unit]!
        .expand((id) => actualParents[id] ?? <int>{})
        .toSet();
    final centers = parentIds
        .where(positions.containsKey)
        .map((id) => positions[id]!.dx + cardWidth / 2)
        .toList();
    return centers.isEmpty
        ? null
        : centers.reduce((a, b) => a + b) / centers.length;
  }

  for (final level in levels) {
    final row = rows[level]!;
    row.sort((a, b) {
      if (!orderByParents) return a.compareTo(b);
      final order = (desired(a) ?? double.infinity).compareTo(
        desired(b) ?? double.infinity,
      );
      return order != 0 ? order : a.compareTo(b);
    });
    var x = 310.0;
    for (final unit in row) {
      final target = desired(unit);
      if (target != null) x = math.max(x, target - width(unit) / 2);
      for (final id in units[unit]!) {
        positions[id] = Offset(x, 90 + level * (cardHeight + generationGap));
        x += cardWidth + partnerGap;
      }
      x += branchGap - partnerGap;
    }
    final targets = row.map(desired).whereType<double>().toList();
    if (targets.isNotEmpty) {
      final first = positions[units[row.first]!.first]!.dx;
      final last = positions[units[row.last]!.last]!.dx + cardWidth;
      final shift =
          targets.reduce((a, b) => a + b) / targets.length - (first + last) / 2;
      for (final unit in row) {
        for (final id in units[unit]!) {
          positions[id] = positions[id]! + Offset(shift, 0);
        }
      }
    }
  }
  if (positions.isNotEmpty) {
    final minX = positions.values.map((p) => p.dx).reduce(math.min);
    if (minX < 310) {
      for (final id in ids) {
        positions[id] = positions[id]! + Offset(310 - minX, 0);
      }
    }
  }
  return FamilyGraphLayout(positions, generations);
}
