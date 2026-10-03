import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flowdetectx/providers/auth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('initialize restores the saved session', () async {
    SharedPreferences.setMockInitialValues({
      'auth_token': 'token-123',
      'auth_user_id': 42,
      'auth_first_name': 'Jane',
      'auth_last_name': 'Doe',
      'auth_email': 'jane@example.com',
      'auth_identifiant': 'jdoe',
      'auth_role': 'VALIDATEUR',
    });

    final provider = AuthProvider();
    await provider.initialize();

    expect(provider.isAuthentifie, isTrue);
    expect(provider.token, 'token-123');
    expect(provider.id, 42);
    expect(provider.role, RoleUtilisateur.validateur);
    expect(provider.nom, 'Doe');
    expect(provider.prenom, 'Jane');
  });
}
