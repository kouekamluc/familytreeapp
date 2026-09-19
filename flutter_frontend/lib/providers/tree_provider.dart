import 'package:flutter/material.dart';
import '../models/family_tree.dart';
import '../models/person.dart';
import '../models/relationship.dart';
import '../services/api_service.dart';

enum TreeOrientation { vertical, horizontal }

class TreeProvider extends ChangeNotifier {
  final ApiService _apiService;

  List<FamilyTree> _trees = [];
  FamilyTree? _selectedTree;
  List<Person> _people = [];
  List<Relationship> _relationships = [];
  Person? _selectedPerson;

  TreeOrientation _orientation = TreeOrientation.vertical;
  int? _generationFilter;
  String _searchQuery = '';
  String _peopleFilterTab = 'all'; // 'all', 'living', 'ancestors'
  bool _isLoading = false;
  String? _errorMessage;

  TreeProvider(this._apiService);

  List<FamilyTree> get trees => _trees;
  FamilyTree? get selectedTree => _selectedTree;
  List<Person> get people => _people;
  List<Relationship> get relationships => _relationships;
  Person? get selectedPerson => _selectedPerson;
  TreeOrientation get orientation => _orientation;
  int? get generationFilter => _generationFilter;
  String get searchQuery => _searchQuery;
  String get peopleFilterTab => _peopleFilterTab;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // --- FILTERS & SELECTION ---

  void selectPerson(Person? person) {
    _selectedPerson = person;
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
        final villageMatch = (p.villageOfOrigin ?? '').toLowerCase().contains(q);
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
      if (r.isParent && parentIds.contains(r.person1Id) && r.person2Id != personId) {
        siblingIds.add(r.person2Id);
      }
    }
    return _people.where((p) => siblingIds.contains(p.id)).toList();
  }

  // --- DATA SYNC ---

  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final treesList = await _apiService.getTrees();
      _trees = treesList;
      if (_trees.isNotEmpty && _selectedTree == null) {
        _selectedTree = _trees.first;
      }

      final peopleList = await _apiService.getPeople(treeId: _selectedTree?.id);
      final relsList = await _apiService.getRelationships(treeId: _selectedTree?.id);

      _people = peopleList;
      _relationships = relsList;

      if (_selectedPerson != null) {
        _selectedPerson = _people.firstWhere(
          (p) => p.id == _selectedPerson!.id,
          orElse: () => _people.isNotEmpty ? _people.first : _selectedPerson!,
        );
      } else if (_people.isNotEmpty) {
        _selectedPerson = _people.first;
      }
    } catch (e) {
      _errorMessage = 'Failed to load ancestry data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
        _relationships.removeWhere((r) => r.person1Id == id || r.person2Id == id);
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
}
