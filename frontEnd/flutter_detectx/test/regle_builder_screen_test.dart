import 'package:flutter_test/flutter_test.dart';
import 'package:flowdetectx/screens/metier/regle_builder_screen.dart';

void main() {
  test('construit un payload de soumission avec les conditions', () {
    final payload = construirePayloadPourSoumission(
      nom: 'Suspicion de fraude',
      description: 'Détection d’un mouvement suspect',
      criticite: 'CRITIQUE',
      contenuDrl: 'rule "Suspicion"',
      conditions: ['montant > 100000', 'type == "VIREMENT"'],
    );

    expect(payload['nom'], 'Suspicion de fraude');
    expect(payload['description'], 'Détection d’un mouvement suspect');
    expect(payload['criticite'], 'CRITIQUE');
    expect(payload['contenuDrl'], 'rule "Suspicion"');
    expect(payload['conditions'], 'montant > 100000; type == "VIREMENT"');
  });
}
