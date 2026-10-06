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

  final Set<String> _pendingWrites = {};
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

  late String _identity;
  TreeProvider(this._apiService) {
    _identity = _apiService.identity;
    _apiService.addListener(_identityChanged);
  }
  void _identityChanged() {
    if (_identity != _apiService.identity) {
      _identity = _apiService.identity;
      clearData();
    }
  }

  @override
  void dispose() {
    _apiService.removeListener(_identityChanged);
    super.dispose();
  }

  String? get lastSaveError => _apiService.lastError;
  bool get lastRevisionConflict => _apiService.lastRevisionConflict;
  bool get canReportSelectedTree =>
      _apiService.isAuthenticated &&
      !_apiService.isPreviewMode &&
      !_isOfflineMode &&
      _selectedTree != null;
  String get contextKey => '${_apiService.identity}:${_selectedTree?.id}';
  bool get canEditSelectedTree =>
      !_apiService.isPreviewMode &&
      !_isOfflineMode &&
      !_isLoading &&
      _selectedTree != null &&
      (_selectedTree!.canEdit ||
          _selectedTree!.owner == _apiService.currentUser?.username);
  bool get canManageSelectedTree =>
      canEditSelectedTree &&
      (_selectedTree!.canManage ||
          _selectedTree!.owner == _apiService.currentUser?.username);

  Future<void> _cacheSnapshot() async {
    final scope = _apiService.cacheScope;
    final current = _selectedTree;
    if (current == null) return;
    final tree = current.withPeopleCount(_people.length);
    _selectedTree = tree;
    _trees = _trees.map((t) => t.id == tree.id ? tree : t).toList();
    if (scope == null) return;
    final local = LocalStorageService();
    await local.cacheSnapshot(
      List.of(_trees),
      tree.id,
      List.of(_people),
      List.of(_relationships),
      accountScope: scope,
    );
    await local.saveLastActiveTreeId(tree.id, accountScope: scope);
  }

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
    final parentIds = getParentsOf(personId).map((p) => p.id).toSet();
    final siblingIds = <int>{};
    for (final r in _relationships) {
      if (r.isParent &&
          parentIds.contains(r.person1Id) &&
          r.person2Id != personId) {
        siblingIds.add(r.person2Id);
      }
      if (r.isSibling && r.person1Id == personId) siblingIds.add(r.person2Id);
      if (r.isSibling && r.person2Id == personId) siblingIds.add(r.person1Id);
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
    final identity = _apiService.identity;
    final scope = _apiService.cacheScope;
    bool active() =>
        version == _loadVersion && identity == _apiService.identity;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    final local = LocalStorageService();
    try {
      if (_trees.isEmpty && scope != null) {
        final trees = await local.getCachedTrees(accountScope: scope);
        final savedId =
            targetTreeId ??
            await local.getLastActiveTreeId(accountScope: scope);
        if (!active()) return;
        if (trees.isNotEmpty) {
          final tree = trees.firstWhere(
            (t) => t.id == savedId,
            orElse: () => trees.first,
          );
          final people = await local.getCachedPeople(
            tree.id,
            accountScope: scope,
          );
          final relations = await local.getCachedRelationships(
            tree.id,
            accountScope: scope,
          );
          if (!active()) return;
          _trees = trees;
          _selectedTree = tree;
          _people = people;
          _relationships = relations;
          _isOfflineMode = true;
          notifyListeners();
        }
      }
      final trees = await _apiService.getTrees();
      if (!active()) return;
      _trees = trees;
      if (_selectedTree != null &&
          !trees.any((t) => t.id == _selectedTree!.id)) {
        _selectedTree = null;
        _people = [];
        _relationships = [];
        _selectedPerson = null;
        _focusPersonId = null;
        _isOfflineMode = false;
      }
      // A successful access check is authoritative even if graph loading fails.
      if (scope != null) await local.cacheTrees(trees, accountScope: scope);
      if (!active()) return;
      if (trees.isEmpty) {
        _trees = [];
        _selectedTree = null;
        _people = [];
        _relationships = [];
        _selectedPerson = null;
        _focusPersonId = null;
        _isOfflineMode = false;
        if (scope != null) await local.cacheTrees([], accountScope: scope);
        return;
      }
      final desired = targetTreeId ?? _selectedTree?.id;
      final tree = trees.firstWhere(
        (t) => t.id == desired,
        orElse: () => trees.first,
      );
      final people = await _apiService.getPeople(treeId: tree.id);
      final relationships = await _apiService.getRelationships(treeId: tree.id);
      if (!active()) return;
      final selectedId = targetPersonId ?? _selectedPerson?.id;
      _trees = trees;
      _selectedTree = tree;
      _people = people;
      _relationships = relationships;
      final matches = people.where((p) => p.id == selectedId);
      _selectedPerson = matches.isEmpty ? null : matches.first;
      _focusPersonId = _selectedPerson?.id;
      _isOfflineMode = false;
      await _cacheSnapshot();
    } catch (e) {
      if (active()) {
        _isOfflineMode = _selectedTree != null;
        _errorMessage = _selectedTree == null
            ? 'Unable to load this tree. Check the connection and sign in again if needed.'
            : 'Offline: showing the last saved snapshot of ${_selectedTree!.name}.';
      }
    } finally {
      if (active()) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void selectTree(FamilyTree tree) {
    if (_selectedTree?.id == tree.id) return;
    _selectedTree = null;
    _people = [];
    _relationships = [];
    _selectedPerson = null;
    _focusPersonId = null;
    _generationFilter = null;
    _searchQuery = '';
    _peopleFilterTab = 'all';
    _isOfflineMode = false;
    loadData(targetTreeId: tree.id);
  }

  Future<bool> addPerson(Map<String, dynamic> data) async {
    if (!_pendingWrites.add('addPerson')) return false;
    final version = _loadVersion;
    try {
      if (_selectedTree != null) {
        data['family_tree'] = _selectedTree!.id;
      }
      final newPerson = await _apiService.createPerson(data);
      if (version != _loadVersion) return false;
      if (newPerson != null) {
        _people.add(newPerson);
        await _cacheSnapshot();
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error adding person: $e');
    } finally {
      _pendingWrites.remove('addPerson');
    }
    return false;
  }

  Future<bool> updatePerson(int id, Map<String, dynamic> data) async {
    if (!_pendingWrites.add('updatePerson')) return false;
    final version = _loadVersion;
    try {
      final updated = await _apiService.updatePerson(id, data);
      if (version != _loadVersion) return false;
      if (updated != null) {
        final idx = _people.indexWhere((p) => p.id == id);
        if (idx != -1) {
          _people[idx] = updated;
        }
        if (_selectedPerson?.id == id) {
          _selectedPerson = updated;
        }
        await _cacheSnapshot();
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error updating person: $e');
    } finally {
      _pendingWrites.remove('updatePerson');
    }
    return false;
  }

  Future<bool> uploadPortrait(int id, List<int> bytes, String filename) async {
    final version = _loadVersion;
    final updated = await _apiService.uploadPersonPhoto(id, bytes, filename);
    if (updated == null || version != _loadVersion) return false;
    final index = _people.indexWhere((p) => p.id == id);
    if (index >= 0) _people[index] = updated;
    if (_selectedPerson?.id == id) _selectedPerson = updated;
    await _cacheSnapshot();
    notifyListeners();
    return true;
  }

  Future<bool> deletePerson(int id) async {
    if (!_pendingWrites.add('deletePerson')) return false;
    final version = _loadVersion;
    try {
      final success = await _apiService.deletePerson(id);
      if (version != _loadVersion) return false;
      if (success) {
        _people.removeWhere((p) => p.id == id);
        _relationships.removeWhere(
          (r) => r.person1Id == id || r.person2Id == id,
        );
        if (_selectedPerson?.id == id) {
          _selectedPerson = _people.isNotEmpty ? _people.first : null;
        }
        if (_focusPersonId == id) _focusPersonId = null;
        await _cacheSnapshot();
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting person: $e');
    } finally {
      _pendingWrites.remove('deletePerson');
    }
    return false;
  }

  Future<bool> addRelationship(
    int p1Id,
    int p2Id,
    String type, {
    Map<String, dynamic>? details,
  }) async {
    if (!_pendingWrites.add('addRelationship')) return false;
    final version = _loadVersion;
    try {
      final rel = await _apiService.createRelationship(
        p1Id,
        p2Id,
        type,
        details: details,
      );
      if (version != _loadVersion) return false;
      if (rel != null) {
        if (!_relationships.any((r) => r.id == rel.id)) _relationships.add(rel);
        await _cacheSnapshot();
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error adding relationship: $e');
    } finally {
      _pendingWrites.remove('addRelationship');
    }
    return false;
  }

  Future<bool> deleteRelationship(int id) async {
    if (!_pendingWrites.add('deleteRelationship')) return false;
    final version = _loadVersion;
    try {
      final success = await _apiService.deleteRelationship(id);
      if (version != _loadVersion) return false;
      if (success) {
        _relationships.removeWhere((r) => r.id == id);
        await _cacheSnapshot();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting relationship: $e');
      return false;
    } finally {
      _pendingWrites.remove('deleteRelationship');
    }
  }

  Future<bool> updateRelationship(int id, Map<String, dynamic> data) async {
    if (!_pendingWrites.add('updateRelationship')) return false;
    final version = _loadVersion;
    try {
      final updated = await _apiService.updateRelationship(id, data);
      if (updated == null || version != _loadVersion) return false;
      final index = _relationships.indexWhere((r) => r.id == id);
      if (index < 0) return false;
      _relationships[index] = updated;
      await _cacheSnapshot();
      notifyListeners();
      return true;
    } finally {
      _pendingWrites.remove('updateRelationship');
    }
  }

  Future<bool> updateTree(int id, Map<String, dynamic> data) async {
    if (!_pendingWrites.add('updateTree')) return false;
    final version = _loadVersion;
    try {
      final updated = await _apiService.updateTree(id, data);
      if (updated == null || version != _loadVersion) return false;
      final index = _trees.indexWhere((t) => t.id == id);
      if (index < 0) return false;
      _trees[index] = updated;
      if (_selectedTree?.id == id) _selectedTree = updated;
      await _cacheSnapshot();
      notifyListeners();
      return true;
    } finally {
      _pendingWrites.remove('updateTree');
    }
  }

  Future<bool> deleteTree(int id) async {
    if (!_pendingWrites.add('deleteTree')) return false;
    final version = _loadVersion;
    try {
      if (!await _apiService.deleteTree(id) || version != _loadVersion) {
        return false;
      }
      _trees.removeWhere((t) => t.id == id);
      if (_selectedTree?.id == id) {
        _selectedTree = null;
        _people = [];
        _relationships = [];
        _selectedPerson = null;
        _focusPersonId = null;
        _searchQuery = '';
        _generationFilter = null;
        _peopleFilterTab = 'all';
      }
      // Invalidate the deleted graph before attempting a network reload.
      final scope = _apiService.cacheScope;
      if (scope != null) {
        await LocalStorageService().cacheTrees(_trees, accountScope: scope);
      }
      await loadData();
      return true;
    } finally {
      _pendingWrites.remove('deleteTree');
    }
  }

  void clearData() {
    _loadVersion++;
    _trees = [];
    _selectedTree = null;
    _people = [];
    _relationships = [];
    _selectedPerson = null;
    _focusPersonId = null;
    _generationFilter = null;
    _searchQuery = "";
    _peopleFilterTab = "all";
    _isLoading = false;
    _isOfflineMode = false;
    _errorMessage = null;
    notifyListeners();
  }

  Future<FamilyTree?> createTree(String name, String description) async {
    final version = _loadVersion;
    try {
      final tree = await _apiService.createTree(name, description);
      if (version != _loadVersion) return null;
      if (tree != null) {
        _trees.add(tree);
        _selectedTree = tree;
        _people = [];
        _relationships = [];
        _selectedPerson = null;
        _focusPersonId = null;
        await loadData(targetTreeId: tree.id);
        notifyListeners();
        return tree;
      }
    } catch (e) {
      debugPrint('Error creating tree in provider: $e');
    }
    return null;
  }

  Future<Person?> createRelative({
    required int sourcePersonId,
    required String role, // 'parent', 'child', 'spouse', 'sibling'
    required Map<String, dynamic> personData,
    int? existingPersonId,
    int? coParentId,
    String? relationshipNotes,
    String? relationshipType,
  }) async {
    final version = _loadVersion;
    try {
      final result = await _apiService.createRelative(
        sourcePersonId,
        role,
        personData,
        existingPersonId: existingPersonId,
        coParentId: coParentId,
        relationshipNotes: relationshipNotes,
        relationshipType: relationshipType,
      );
      if (result == null || version != _loadVersion) return null;
      final person = Person.fromJson(result['person']);
      final relationship = Relationship.fromJson(result['relationship']);
      if (!_people.any((p) => p.id == person.id)) _people.add(person);
      if (!_relationships.any((r) => r.id == relationship.id)) {
        _relationships.add(relationship);
      }
      for (final data in (result['additional_relationships'] as List? ?? [])) {
        final link = Relationship.fromJson(data);
        if (!_relationships.any((r) => r.id == link.id)) {
          _relationships.add(link);
        }
      }
      await _cacheSnapshot();
      notifyListeners();
      return person;
    } catch (e) {
      debugPrint('Error creating relative: $e');
      return null;
    }
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
      relType = ['sibling', 'brother', 'sister'].contains(role)
          ? 'SIBLING'
          : 'SPOUSE';
    }

    return await addRelationship(p1Id, p2Id, relType);
  }
}
