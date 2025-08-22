# ML_PP MVP — Tests d’intégration (Réceptions)

Ces tests couvrent le flux client "création de brouillon → validation" sans réseau, via:
- ReceptionService_v2 (service testable)
- FakeDbPort (simule la base & la RPC validate_reception)

## Pourquoi des Fakes ?
- Garantie de non-régression côté UI/service sans dépendre de la connectivité.
- Possibilité de simuler des erreurs serveur (capacité, compatibilité, cours non 'arrivé', etc.).

## Lancer les tests

```bash
flutter test test/integration/reception_flow_test.dart
```

Notes:
- Le build passe sans modifier l’app existante.
- Les tests d’intégration s’exécutent localement, sans réseau.
- Happy path vert ; chaque cas d’erreur renvoie un message explicite.
- Le code de test contient des en-têtes et des commentaires pédagogiques.
- Aucune nouvelle dépendance ajoutée.


