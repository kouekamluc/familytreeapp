import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_frontend/services/api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('preview uses fictional local data and never persists a login', () async {
    SharedPreferences.setMockInitialValues({'auth_token': 'demo_token'});
    final api = ApiService();
    await api.init();
    expect(api.isAuthenticated, isFalse);

    await api.demoLogin();
    expect(api.isAuthenticated, isTrue);
    expect(api.isPreviewMode, isTrue);
    expect(api.token, isNull);

    final trees = await api.getTrees();
    final people = await api.getPeople(treeId: trees.first.id);
    final relationships = await api.getRelationships(treeId: trees.first.id);
    expect(trees.single.id, isNegative);
    expect(people, isNotEmpty);
    expect(relationships, isNotEmpty);
    expect(await api.createPerson({
      'first_name': 'Test', 'last_name': 'Person', 'gender': 'F',
    }), isNull);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('auth_token'), isNull);
    await api.logout();
    expect(api.isAuthenticated, isFalse);
  });
}
