## Intégration hybride des variables d'environnement (dart-define + .env)

### Objet
- Mettre en place un chargement robuste des variables Supabase pour corriger l'erreur d'authentification en dev ("email ou mot de passe incorrect") due à des clés non injectées.

### Contexte du bug
- `SupabaseConfig` lisait `SUPABASE_URL` et `SUPABASE_ANON_KEY` via `String.fromEnvironment` uniquement.
- En l'absence de `--dart-define`, ces valeurs étaient vides → `signInWithPassword` renvoyait "invalid login credentials".

### Diagnostic
- L'app compilée avec `flutter run` sans `--dart-define` n'avait pas d'URL/KEY valides.
- Les messages SnackBar affichaient "email ou mot de passe incorrect" alors que les identifiants étaient bons.

### Changements apportés
- `lib/main.dart`:
  - Chargement `.env` via `flutter_dotenv`.
  - Priorité à `--dart-define` (CI/Prod), repli sur `.env` en local.
  - Suppression de la dépendance à `SupabaseConfig`.

```dart
// Extrait clé
await dotenv.load(fileName: ".env");
final url = const String.fromEnvironment('SUPABASE_URL').isNotEmpty
    ? const String.fromEnvironment('SUPABASE_URL')
    : (dotenv.env['SUPABASE_URL'] ?? '');
final key = const String.fromEnvironment('SUPABASE_ANON_KEY').isNotEmpty
    ? const String.fromEnvironment('SUPABASE_ANON_KEY')
    : (dotenv.env['SUPABASE_ANON_KEY'] ?? '');
await Supabase.initialize(url: url, anonKey: key);
```

- `pubspec.yaml`:
  - Ajout `flutter_dotenv: ^5.1.0`.
  - Déclaration de l'asset `.env`.

- Suppression du fichier devenu obsolète:
  - `lib/core/services/supabase_config.dart`.

### Procédure de lancement en dev
- Recommandé (JSON):
  - `flutter run -d chrome --dart-define-from-file=env/dev.json`
- Fallback `.env`:
  - `flutter run -d chrome`

Exemple `env/dev.json`:
```json
{
  "SUPABASE_URL": "https://xxxxx.supabase.co",
  "SUPABASE_ANON_KEY": "xxxxxxxx"
}
```

### Sécurité (prod)
- Utiliser exclusivement `--dart-define`.
- Ne pas embarquer de `.env` sensible dans les builds de production.

### Vérifications conseillées
- Ajouter temporairement dans `main.dart`:
  - `debugPrint('URL set? \'${supabaseUrl.isNotEmpty}\'');`
  - `debugPrint('KEY set? \'${supabaseAnonKey.isNotEmpty}\'');`
- Contrôler dans l'onglet Network que les requêtes ciblent bien `https://xxxxx.supabase.co`.

### Impact
- Correction du problème "invalid login credentials" causé par l'injection manquante des variables d'environnement.
- Stratégie unifiée pour dev/CI/Prod, plus simple à opérer et sécurisée pour la prod.


