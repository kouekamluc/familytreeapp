import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_frontend/services/api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('registration uses the mounted authentication route', () async {
    SharedPreferences.setMockInitialValues({
      'custom_server_host_url': 'https://family.example/api',
    });
    final api = ApiService();
    await api.init();
    await http.runWithClient(
      () async {
        expect(
          await api.register(
            username: 'new',
            email: 'new@example.com',
            password: 'test-password',
          ),
          isFalse,
        );
      },
      () => MockClient((request) async {
        expect(
          request.url.toString(),
          'https://family.example/api/auth/register/',
        );
        expect(jsonDecode(request.body)['password2'], 'test-password');
        return http.Response('{"username":["Already exists"]}', 400);
      }),
    );
  });

  test('import sends credentials, file and explicit destination', () async {
    SharedPreferences.setMockInitialValues({
      'session_v2_${base64Url.encode(utf8.encode('https://family.example/api'))}_token':
          'test-token',
      'custom_server_host_url': 'https://family.example/api',
    });
    final api = ApiService();
    await api.init();
    await http.runWithClient(
      () async {
        expect(
          await api.importTreeData({
            'people': [],
            'relationships': [],
          }, treeId: 42),
          isTrue,
        );
      },
      () => MockClient((request) async {
        expect(request.url.path, '/api/data/import/');
        expect(request.headers['authorization'], 'Bearer test-token');
        expect(
          request.headers['content-type'],
          startsWith('multipart/form-data'),
        );
        expect(request.body, contains('name="tree_id"'));
        expect(request.body, contains('42'));
        expect(request.body, contains('filename="family-tree.json"'));
        expect(
          request.body,
          contains(jsonEncode({'people': [], 'relationships': []})),
        );
        return http.Response('{}', 201);
      }),
    );
  });
}
