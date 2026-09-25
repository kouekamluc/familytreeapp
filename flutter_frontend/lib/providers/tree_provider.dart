import 'package:flutter/material.dart';
import '../models/family_tree.dart';
import '../models/person.dart';
import '../models/relationship.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';

enum TreeOrientation { vertical, horizontal }

enum TreeScope { extendedDynasty, immediateFamily }

class TreeProvider extends ChangeNotifier {
  final ApiService _apiService;

  List<FamilyTree> _trees = [];
  FamilyTree? _selectedTree;
  List<Person> _people = [];
  List<Relationship> _relationships = [];
  Person? _selectedPerson;

  TreeOrientation _orientation = TreeOrientation.vertical;
  TreeScope _treeScope = TreeScope.extendedDynasty;
  int? _focusPersonId;

  int? _generationFilter;
  String _searchQuery = '';
  String _peopleFilterTab = 'all'; // 'all', 'living', 'ancestors'
  bool _isLoading = false;
  String? _errorMessage;
  bool _isOfflineMode = false;
  int _loadVersion = 0;

  TreeProvider(this._apiService);

  List<FamilyTree> get trees => _trees;
  FamilyTree? get selectedTree => _selectedTree;
  List<Person> get people => _people;
  List<Relationship> get relationships => _relationships;
  Person? get selectedPerson => _selectedPerson;
  TreeOrientation get orientation => _orientation;
  TreeScope get treeScope => _treeScope;
  int? get focusPersonId => _focusPersonId;
  int? get generationFilter => _generationFilter;
  String get searchQuery => _searchQuery;
  String get peopleFilterTab => _peopleFilterTab;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isOfflineMode => _isOfflineMode;

  Person? get focusPerson {
    if (_focusPersonId != null) {
      final match = _people.where((p) => p.id == _focusPersonId).toList();
      if (match.isNotEmpty) return match.first;
    }
    if (_selectedPerson != null) return _selectedPerson;
    final living = _people.where((p) => p.isLiving).toList();
    if (living.isNotEmpty) return living.first;
    return _people.isNotEmpty ? _people.first : null;
  }

  void setTreeScope(TreeScope scope) {
    _treeScope = scope;
    notifyListeners();
  }

  void setFocusPersonId(int? id) {
    _focusPersonId = id;
    notifyListeners();
  }

  void selectPerson(Person? person) {
    _selectedPerson = person;
    if (person != null) {
      _focusPersonId = person.id;
    }
    notifyListeners();
  }

  void toggleOrientation() {
    _orientation = _orientation == TreeOrientation.vertical
        ? TreeOrientation.horizontal
        : TreeOrientation.vertical;
    notifyListeners();
  }

  void setGenerationFilter(int? tier) {
    _generationFilter = tier;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setPeopleFilterTab(String tab) {
    _peopleFilterTab = tab;
    notifyListeners();
  }

  List<Person> get filteredPeople {
    return _people.where((p) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final nameMatch = p.fullName.toLowerCase().contains(q);
        final tradMatch = (p.traditionalName ?? '').toLowerCase().contains(q);
        final villageMatch = (p.villageOfOrigin ?? '').toLowerCase().contains(
          q,
        );
        final totemMatch = (p.clanTotem ?? '').toLowerCase().contains(q);
        if (!nameMatch && !tradMatch && !villageMatch && !totemMatch) {
          return false;
        }
      }

      if (_peopleFilterTab == 'living') {
        if (!p.isLiving) return false;
      } else if (_peopleFilterTab == 'ancestors') {
        if (!p.isAncestor) return false;
      }

      if (_generationFilter != null) {
        if (p.generationTier != _generationFilter) return false;
      }

      return true;
    }).toList();
  }

  // --- IMMEDIATE KINSHIP CIRCLE HELPERS ---

  List<Person> getParentsOf(int personId) {
    final parentIds = _relationships
        .where((r) => r.person2Id == personId && r.isParent)
        .map((r) => r.person1Id)
        .toSet();
    return _people.where((p) => parentIds.contains(p.id)).toList();
  }

  List<Person> getChildrenOf(int personId) {
    final childIds = _relationships
        .where((r) => r.person1Id == personId && r.isParent)
        .map((r) => r.person2Id)
        .toSet();
    return _people.where((p) => childIds.contains(p.id)).toList();
  }

  List<Person> getSpousesOf(int personId) {
    final spouseIds = <int>{};
    for (var r in _relationships) {
      if (r.isSpouse) {
        if (r.person1Id == personId) spouseIds.add(r.person2Id);
        if (r.person2Id == personId) spouseIds.add(r.person1Id);
      }
    }
    return _people.where((p) => spouseIds.contains(p.id)).toList();
  }

  List<Person> getSiblingsOf(int personId) {
    final parents = getParentsOf(personId);
    if (parents.isEmpty) return [];
    final parentIds = parents.map((p) => p.id).toSet();

    final siblingIds = <int>{};
    for (var r in _relationships) {
      if (r.isParent &&
          parentIds.contains(r.person1Id) &&
          r.person2Id != personId) {
        siblingIds.add(r.person2Id);
      }
    }
    return _people.where((p) => siblingIds.contains(p.id)).toList();
  }

  /// Returns people to render in the Tree View based on treeScope and generation filter
  List<Person> get activeTreePeople {
    List<Person> baseList;
    if (_treeScope == TreeScope.extendedDynasty) {
      baseList = _people;
    } else {
      final focus = focusPerson;
      if (focus == null) {
        baseList = _people;
      } else {
        final immediateIds = <int>{focus.id};
        for (final s in getSpousesOf(focus.id)) {
          immediateIds.add(s.id);
        }
        for (final c in getChildrenOf(focus.id)) {
          immediateIds.add(c.id);
        }
        for (final p in getParentsOf(focus.id)) {
          immediateIds.add(p.id);
        }
        for (final s in getSiblingsOf(focus.id)) {
          immediateIds.add(s.id);
        }
        final scoped = _people
            .where((p) => immediateIds.contains(p.id))
            .toList();
        baseList = scoped.isNotEmpty ? scoped : _people;
      }
    }

    if (_generationFilter != null) {
      return baseList
          .where((p) => p.generationTier == _generationFilter)
          .toList();
    }
    return baseList;
  }

  // --- DATA SYNC ---

  Future<void> loadData({int? targetTreeId, int? targetPersonId}) async {
    final version = ++_loadVersion;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final local = LocalStorageService();

    // 1. Immediately hydrate from local phone cache so app works instantly offline
    if (_trees.isEmpty) {
      try {
        final cachedTrees = await local.getCachedTrees();
        if (cachedTrees.isNotEmpty && version == _loadVersion) {
          _trees = cachedTrees;
          final targetId = targetTreeId ?? await local.getLastActiveTreeId();
          _selectedTree = _trees.firstWhere(
            (t) => t.id == targetId,
            orElse: () => _trees.first,
          );
          final cachedPeople = await local.getCachedPeople(_selectedTree!.id);
          final cachedRels = await local.getCachedRelationships(_selectedTree!.id);
          if (cachedPeople.isNotEmpty) {
            _people = cachedPeople;
            _relationships = cachedRels;
            final lastPid = targetPersonId ?? await local.getLastActivePersonId();
            if (lastPid != null) {
              final match = _people.where((p) => p.id == lastPid).toList();
              if (match.isNotEmpty) {
                _selectedPerson = match.first;
                _focusPersonId = match.first.id;
              }
            }
            _isOfflineMode = true;
            notifyListeners();
          }
        }
      } catch (e) {
        debugPrint('Error loading offline phone cache: $e');
      }
    }

    try {
      final previousTreeId = _selectedTree?.id;
      final previousPersonId = _selectedPerson?.id;
      final treesList = await _apiService.getTrees();
      if (version != _loadVersion) return;
      _trees = treesList;

      if (_trees.isEmpty) {
        _selectedTree = null;
        _people = [];
        _relationships = [];
        _selectedPerson = null;
        _focusPersonId = null;
      } else if (targetTreeId != null) {
        final matched = _trees.where((t) => t.id == targetTreeId).toList();
        if (matched.isNotEmpty) {
          _selectedTree = matched.first;
        } else {
          _selectedTree = _trees.first;
        }
      } else if (_selectedTree == null ||
          !_trees.any((t) => t.id == _selectedTree!.id)) {
        _selectedTree = _trees.first;
      }

      if (_selectedTree == null) return;
      local.saveLastActiveTreeId(_selectedTree!.id);

      final peopleList = await _apiService.getPeople(treeId: _selectedTree!.id);
      if (version != _loadVersion) return;
      final relsList = await _apiService.getRelationships(
        treeId: _selectedTree!.id,
      );
      if (version != _loadVersion) return;

      _people = peopleList;
      _relationships = relsList;
      _isOfflineMode = false;
      _errorMessage = null;

      if (targetPersonId != null) {
        final invitedPerson = _people
            .where((p) => p.id == targetPersonId)
            .toList();
        if (invitedPerson.isNotEmpty) {
          _selectedPerson = invitedPerson.first;
          _focusPersonId = targetPersonId;
          local.saveLastActivePersonId(targetPersonId);
        }
      } else if (previousTreeId == _selectedTree?.id && previousPersonId != null) {
        final matches = _people.where((p) => p.id == previousPersonId);
        if (matches.isNotEmpty) {
          _selectedPerson = matches.first;
        }
      }
    } catch (e) {
      if (version == _loadVersion) {
        // If we already have people in memory (from phone local cache), KEEP THEM!
        if (_people.isNotEmpty) {
          _isOfflineMode = true;
          _errorMessage = null; // Do not block the UI with an error screen
          debugPrint('Network unavailable - running in offline mode with ${_people.length} local records');
        } else {
          _errorMessage = 'Mode hors-ligne : Aucune archive locale trouvée. Connectez-vous au serveur ou utilisez le mode Découverte.';
        }
      }
    } finally {
      if (version == _loadVersion) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void selectTree(FamilyTree tree) {
    if (_selectedTree?.id == tree.id) return;
    _selectedTree = tree;
    _selectedPerson = null;
    _focusPersonId = null;
    loadData(targetTreeId: tree.id);
  }

  Future<bool> addPerson(Map<String, dynamic> data) async {
    try {
      if (_selectedTree != null) {
        data['family_tree'] = _selectedTree!.id;
      }
      final newPerson = await _apiService.createPerson(data);
      if (newPerson != null) {
        _people.add(newPerson);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error adding person: $e');
    }
    return false;
  }

  Future<bool> updatePerson(int id, Map<String, dynamic> data) async {
    try {
      final updated = await _apiService.updatePerson(id, data);
      if (updated != null) {
        final idx = _people.indexWhere((p) => p.id == id);
        if (idx != -1) {
          _people[idx] = updated;
        }
        if (_selectedPerson?.id == id) {
          _selectedPerson = updated;
        }
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error updating person: $e');
    }
    return false;
  }

  Future<bool> deletePerson(int id) async {
    try {
      final success = await _apiService.deletePerson(id);
      if (success) {
        _people.removeWhere((p) => p.id == id);
        _relationships.removeWhere(
          (r) => r.person1Id == id || r.person2Id == id,
        );
        if (_selectedPerson?.id == id) {
          _selectedPerson = _people.isNotEmpty ? _people.first : null;
        }
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting person: $e');
    }
    return false;
  }

  Future<bool> addRelationship(int p1Id, int p2Id, String type) async {
    try {
      final rel = await _apiService.createRelationship(p1Id, p2Id, type);
      if (rel != null) {
        _relationships.add(rel);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error adding relationship: $e');
    }
    return false;
  }

  Future<bool> deleteRelationship(int id) async {
    try {
      final success = await _apiService.deleteRelationship(id);
      if (success) {
        _relationships.removeWhere((r) => r.id == id);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting relationship: $e');
      return false;
    }
  }

  void clearData() {
    _loadVersion++;
    _trees = [];
    _selectedTree = null;
    _people = [];
    _relationships = [];
    _selectedPerson = null;
    notifyListeners();
  }

  Future<Person?> createRelative({
    required int sourcePersonId,
    required String role, // 'parent', 'child', 'spouse'
    required Map<String, dynamic> personData,
  }) async {
    try {
      if (_selectedTree != null) {
        personData['family_tree'] = _selectedTree!.id;
      }
      final newPerson = await _apiService.createPerson(personData);
      if (newPerson != null) {
        _people.add(newPerson);

        int p1Id;
        int p2Id;
        String relType;

        if (role == 'parent' || role == 'father' || role == 'mother') {
          p1Id = newPerson.id;
          p2Id = sourcePersonId;
          relType = 'PARENT';
        } else if (role == 'child') {
          p1Id = sourcePersonId;
          p2Id = newPerson.id;
          relType = 'PARENT';
        } else {
          p1Id = sourcePersonId;
          p2Id = newPerson.id;
          relType = 'SPOUSE';
        }

        await addRelationship(p1Id, p2Id, relType);
        notifyListeners();
        return newPerson;
      }
    } catch (e) {
      debugPrint('Error creating relative: $e');
    }
    return null;
  }

  Future<bool> linkExistingRelative({
    required int sourcePersonId,
    required int targetPersonId,
    required String role,
  }) async {
    int p1Id;
    int p2Id;
    String relType;

    if (role == 'parent' || role == 'father' || role == 'mother') {
      p1Id = targetPersonId;
      p2Id = sourcePersonId;
      relType = 'PARENT';
    } else if (role == 'child') {
      p1Id = sourcePersonId;
      p2Id = targetPersonId;
      relType = 'PARENT';
    } else {
      p1Id = sourcePersonId;
      p2Id = targetPersonId;
      relType = 'SPOUSE';
    }

    return await addRelationship(p1Id, p2Id, relType);
  }
}
