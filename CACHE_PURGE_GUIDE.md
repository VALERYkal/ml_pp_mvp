# 🧹 Guide de purge des caches navigateur

## 🎯 **Objectif**
Éliminer complètement les artefacts d'encodage (RÃ´le, EntrÃ©es, DÃ©pÃ´t) qui persistent dans le cache navigateur après les corrections UTF-8.

## 🔧 **Actions appliquées côté serveur**

### ✅ **Configuration UTF-8**
- **`web/index.html`** : `<meta charset="UTF-8">` confirmé présent
- **Rebuild propre** : `flutter clean` + `flutter pub get` + `flutter run`
- **Service worker** : Régénération forcée (suppression + rebuild)

## 🌐 **Actions requises côté navigateur**

### **Méthode 1 : DevTools (Recommandée)**

1. **Ouvrir DevTools** : `F12` ou `Ctrl+Shift+I`
2. **Onglet Application** :
   - **Service Workers** → Cliquer sur "Unregister" pour tous les workers
   - **Storage** → "Clear storage" → Cocher "All" → "Clear site data"
3. **Fermer l'onglet** et rouvrir en navigation privée
4. **Tester** : `Ctrl+Shift+N` → Aller sur `localhost:XXXXX`

### **Méthode 2 : Cache navigateur complet**

#### **Chrome/Edge**
1. `Ctrl+Shift+Delete`
2. **Période** : "Tout"
3. **Cocher** : "Images et fichiers en cache", "Données de sites"
4. **Effacer les données**

#### **Firefox**
1. `Ctrl+Shift+Delete`
2. **Période** : "Tout"
3. **Cocher** : "Cache", "Données hors connexion"
4. **Effacer maintenant**

### **Méthode 3 : Navigation privée (Test rapide)**
- `Ctrl+Shift+N` (Chrome) ou `Ctrl+Shift+P` (Firefox)
- Aller sur `localhost:XXXXX`
- Tester la connexion et vérifier les accents

## 🧪 **Test de validation**

### **Messages à vérifier**
- ✅ **Login** : "Connexion réussie" (au lieu de "Connexion rÃ©ussie")
- ✅ **Erreur profil** : "Aucun profil trouvé" (au lieu de "Aucun profil trouvÃ©")
- ✅ **Interface** : "Rôle", "Entrées", "Dépôt" (accents corrects)

### **Écrans à tester**
- **Login screen** : Messages d'erreur et de succès
- **Dashboard shell** : Menu "Tableau de bord", "Rôle", "Dépôt"
- **Navigation** : Tous les libellés de menu

## 🔍 **Diagnostic avancé**

### **Si les artefacts persistent**

1. **Vérifier la source** :
   ```bash
   # Dans DevTools → Sources → web/
   # Chercher "RÃ´le" ou "EntrÃ©es"
   # Si trouvé → problème de build
   ```

2. **Log de debug** :
   ```dart
   // Ajouter temporairement dans le code
   debugPrint('SNACK: $_message');
   // Vérifier dans la console si les accents sont corrects
   ```

3. **Test direct** :
   ```dart
   // Ajouter temporairement dans un écran
   Text('Test: Rôle, Entrées, Dépôt')
   // Si correct → problème de cache
   // Si incorrect → problème de build
   ```

## 🚀 **Résultat attendu**

Après purge complète des caches :
- ✅ **Tous les accents** s'affichent correctement
- ✅ **Plus d'artefacts** RÃ´le, EntrÃ©es, DÃ©pÃ´t
- ✅ **Interface propre** avec caractères français corrects

## 📝 **Notes techniques**

- **Service Worker** : Flutter Web utilise un service worker pour le cache
- **Meta charset** : Déjà présent dans `web/index.html`
- **Encodage source** : Tous les fichiers sont maintenant en UTF-8
- **Cache navigateur** : Peut persister même après correction du code

La purge des caches est **essentielle** pour voir les corrections d'encodage ! 🎯