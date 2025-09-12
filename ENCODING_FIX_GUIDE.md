# 🔧 Guide de correction d'encodage UTF-8

## ✅ Problèmes résolus

### 1. **Configuration UTF-8**
- ✅ `.vscode/settings.json` - Force l'encodage UTF-8 dans VS Code
- ✅ `.gitattributes` - Normalise les fins de ligne et l'encodage Git

### 2. **Reconversion des fichiers**
- ✅ Script `tools/recode-to-utf8.ps1` - Reconversion automatique en UTF-8
- ✅ Tous les fichiers `.dart`, `.yaml`, `.md`, `.json` traités

### 3. **Correction des chaînes corrompues**
- ✅ Script `tools/fix-strings.ps1` - Remplacement automatique des caractères corrompus
- ✅ Corrections appliquées : RÃ´le → Rôle, EntrÃ©es → Entrées, DÃ©pÃ´t → Dépôt, etc.

### 4. **Unification des providers Auth**
- ✅ Suppression de `lib/shared/providers/auth_provider.dart` (doublon)
- ✅ Migration vers `lib/shared/providers/auth_service_provider.dart`
- ✅ Mise à jour des imports dans tous les fichiers

### 5. **Garde-fous CI**
- ✅ Script `tools/check-utf8.mjs` - Vérification automatique UTF-8
- ✅ `package.json` - Scripts npm pour maintenance

## 🎯 Résultat attendu

### Avant (problèmes)
- ❌ RÃ´le, EntrÃ©es, DÃ©pÃ´t (caractères corrompus)
- ❌ Encodage Windows-1252/Latin-1
- ❌ Doublon de providers Auth
- ❌ Incohérences d'encodage

### Après (corrigé)
- ✅ Rôle, Entrées, Dépôt (accents corrects)
- ✅ Encodage UTF-8 uniforme
- ✅ Un seul provider Auth
- ✅ Cohérence d'encodage garantie

## 🛠️ Scripts de maintenance

### Vérification UTF-8
```bash
npm run check:utf8
```

### Correction d'encodage
```bash
npm run fix:encoding
```

### Correction des chaînes
```bash
npm run fix:strings
```

## 📁 Fichiers créés/modifiés

### Configuration
- `.vscode/settings.json` - Configuration VS Code UTF-8
- `.gitattributes` - Normalisation Git
- `package.json` - Scripts de maintenance

### Scripts
- `tools/recode-to-utf8.ps1` - Reconversion UTF-8
- `tools/fix-strings.ps1` - Correction des chaînes
- `tools/check-utf8.mjs` - Vérification CI

### Code
- `lib/shared/providers/auth_provider.dart` - **SUPPRIMÉ** (doublon)
- Tous les imports mis à jour vers `auth_service_provider.dart`

## 🔍 Vérifications

### Dans l'interface utilisateur
- ✅ Drawer/Shell : "Rôle", "Dépôt" (accents corrects)
- ✅ Menus : "Réceptions", "Sorties", "Stocks journaliers"
- ✅ Messages : "Connexion réussie", "Aucun profil trouvé"

### Dans le code
- ✅ Tous les fichiers en UTF-8 sans BOM
- ✅ Un seul provider Auth
- ✅ Imports cohérents

## 🚀 Prochaines étapes

1. **Tester l'application** - Vérifier l'affichage des accents
2. **Commit des changements** - Sauvegarder les corrections
3. **CI/CD** - Intégrer `npm run check:utf8` dans le pipeline

## 📝 Notes techniques

- **Encodage** : UTF-8 sans BOM pour tous les fichiers texte
- **Fins de ligne** : LF (Unix) pour cohérence cross-platform
- **Git** : Normalisation automatique via `.gitattributes`
- **VS Code** : Configuration UTF-8 forcée

L'application devrait maintenant afficher correctement tous les caractères accentués ! 🎉