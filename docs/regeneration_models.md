# 🔄 Régénération des Modèles Freezed/JSON

## 📋 Vue d'ensemble

Ce document explique comment régénérer les fichiers Freezed/JSON après modification des modèles.

## 🎯 Quand régénérer ?

- ✅ Modification d'un modèle Freezed
- ✅ Ajout/suppression de champs
- ✅ Modification des annotations `@JsonKey`
- ✅ Changement de version de `freezed` ou `json_serializable`
- ✅ Erreurs d'analyse liées aux annotations

## 🛠️ Méthodes de Régénération

### **Méthode 1 : Script Automatisé (Recommandé)**

#### Windows PowerShell :
```powershell
.\scripts\regenerate_models.ps1
```

#### Linux/macOS :
```bash
./scripts/regenerate_models.sh
```

### **Méthode 2 : Commande Manuelle**

```bash
# Nettoyer et régénérer
dart run build_runner build --delete-conflicting-outputs

# Ou en mode watch (développement)
dart run build_runner watch --delete-conflicting-outputs
```

### **Méthode 3 : Nettoyage Complet**

```bash
# Nettoyer tous les fichiers générés
dart run build_runner clean

# Puis régénérer
dart run build_runner build --delete-conflicting-outputs
```

## 📁 Fichiers Générés

Après régénération, les fichiers suivants sont créés :

### **Modèles Freezed**
- `*.freezed.dart` : Classes générées par Freezed
- `*.g.dart` : Code de sérialisation JSON

### **Fichiers Typiques**
```
lib/core/models/
├── profil.dart
├── profil.freezed.dart ✅ (généré)
└── profil.g.dart ✅ (généré)

lib/features/cours_route/models/
├── cours_de_route.dart
├── cours_de_route.freezed.dart ✅ (généré)
└── cours_de_route.g.dart ✅ (généré)

lib/features/receptions/models/
├── reception.dart
├── reception.freezed.dart ✅ (généré)
└── reception.g.dart ✅ (généré)

lib/features/sorties/models/
├── sortie_produit.dart
├── sortie_produit.freezed.dart ✅ (généré)
└── sortie_produit.g.dart ✅ (généré)
```

## ⚠️ Points d'Attention

### **1. Annotations @JsonKey**
```dart
// ✅ Correct
@JsonKey(name: 'user_id') required String userId,

// ❌ Incorrect (ancienne syntaxe)
@JsonKey.new(name: 'user_id') required String userId,
```

### **2. Imports Requis**
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'mon_modele.freezed.dart';
part 'mon_modele.g.dart';
```

### **3. Factory fromJson**
```dart
factory MonModele.fromJson(Map<String, dynamic> json) => 
    _$MonModeleFromJson(json);
```

## 🔍 Vérification

Après régénération, vérifiez :

1. **Analyse statique** :
   ```bash
   flutter analyze --no-fatal-infos
   ```

2. **Compilation** :
   ```bash
   flutter build apk --debug
   ```

3. **Tests** :
   ```bash
   flutter test
   ```

## 🚨 Problèmes Courants

### **Erreur : "invalid_annotation_target"**
- **Cause** : Annotations `@JsonKey` mal placées
- **Solution** : Vérifier que `@JsonKey` est sur les paramètres de la factory

### **Erreur : "undefined_method"**
- **Cause** : Fichiers générés manquants ou obsolètes
- **Solution** : Régénérer avec `build_runner`

### **Erreur : "duplicate_definition"**
- **Cause** : Fichiers générés en conflit
- **Solution** : Utiliser `--delete-conflicting-outputs`

## 📝 Exemple Complet

```dart
// mon_modele.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'mon_modele.freezed.dart';
part 'mon_modele.g.dart';

@freezed
class MonModele with _$MonModele {
  const factory MonModele({
    required String id,
    @JsonKey(name: 'nom_champ') required String nomChamp,
    String? champOptionnel,
    @JsonKey(name: 'date_creation') DateTime? dateCreation,
  }) = _MonModele;

  factory MonModele.fromJson(Map<String, dynamic> json) => 
      _$MonModeleFromJson(json);
}
```

## 🎉 Résultat

Après régénération réussie :
- ✅ Tous les fichiers `.freezed.dart` et `.g.dart` sont créés
- ✅ Les annotations `@JsonKey` sont correctement traitées
- ✅ L'analyse statique ne montre plus d'erreurs liées aux modèles
- ✅ Les tests passent

---

*Document généré le 27 janvier 2025*
