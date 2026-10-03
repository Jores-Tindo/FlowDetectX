import 'package:flutter_test/flutter_test.dart';
import 'package:flowdetectx/screens/metier/metier_alertes_screen.dart';

void main() {
  test('fusionne les alertes de la simulation et de l’historique sans doublons',
      () {
    final simulationAlertes = [
      {'id': 1, 'regleNom': 'Suspicion de fraude', 'type': 'VIREMENT'},
    ];
    final historiqueAlertes = [
      {'id': 2, 'regleNom': 'Montant inhabituel', 'type': 'RETRAIT'},
      {'id': 1, 'regleNom': 'Suspicion de fraude', 'type': 'VIREMENT'},
    ];

    final result = MetierAlertesScreen.fusionnerAlertes(
      simulationAlertes,
      historiqueAlertes,
    );

    expect(result.length, 2);
    expect(result[0]['regleNom'], 'Suspicion de fraude');
    expect(result[1]['regleNom'], 'Montant inhabituel');
  });
}
