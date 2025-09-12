# 🧹 Outils de purge de cache Web

## 🎯 **Objectif**
Éliminer définitivement les artefacts d'encodage (RÃ´le, EntrÃ©es, DÃ©pÃ´t) qui persistent dans le cache navigateur et les service workers Flutter Web.

## 🛠️ **Outils créés**

### **1. Route de purge automatique**
- **URL** : `http://localhost:XXXX/#/dev/cache-reset`
- **Fonction** : Purge complète des caches et service workers
- **Usage** : Bouton "Purger cache & service workers puis recharger"

### **2. Fonction de purge programmatique**
- **Fichier** : `lib/dev/web_cache_tools.dart`
- **Fonction** : `clearWebServiceWorkersAndCachesAndReload()`
- **Actions** :
  1. Désenregistre tous les service workers
  2. Vide toutes les caches (CacheStorage)
  3. Recharge la page (hard reload)

## 🚀 **Utilisation**

### **Méthode 1 : Interface graphique (Recommandée)**
1. **Lancer l'application** : `flutter run -d chrome`
2. **Aller sur** : `http://localhost:XXXX/#/dev/cache-reset`
3. **Cliquer** : "Purger cache & service workers puis recharger"
4. **Attendre** : La page se recharge automatiquement
5. **Tester** : Se reconnecter et vérifier les accents

### **Méthode 2 : DevTools manuel**
1. **Ouvrir DevTools** : `F12`
2. **Application** → **Service Workers** → "Unregister"
3. **Application** → **Storage** → "Clear storage" → "Clear site data"
4. **Recharger** : `Ctrl+F5`

## 🧪 **Test de validation**

### **Messages à vérifier après purge**
- ✅ **Login** : "Connexion réussie" (au lieu de "Connexion rÃ©ussie")
- ✅ **Erreur profil** : "Aucun profil trouvé" (au lieu de "Aucun profil trouvÃ©")
- ✅ **Interface** : "Rôle", "Entrées", "Dépôt" (accents corrects)
- ✅ **Menus** : "Réceptions", "Sorties", "Stocks journaliers"

### **Écrans à tester**
- **Login screen** : Messages d'erreur et de succès
- **Dashboard shell** : Menu "Tableau de bord", "Rôle", "Dépôt"
- **Navigation** : Tous les libellés de menu

## 🔧 **Détails techniques**

### **Ce que fait la purge**
```dart
// 1. Désenregistre tous les service workers
final regs = await sw.getRegistrations();
for (final r in regs) {
  await r.unregister();
}

// 2. Vide toutes les caches
final keys = await caches.keys();
for (final k in keys) {
  await caches.delete(k);
}

// 3. Recharge la page
html.window.location.reload();
```

### **Pourquoi c'est nécessaire**
- **Service Workers** : Flutter Web utilise des service workers pour le cache
- **CacheStorage** : Les bundles minifiés corrompus restent en cache
- **Hard reload** : Force le téléchargement des nouveaux bundles UTF-8

## 📁 **Fichiers créés**

- **`lib/dev/web_cache_tools.dart`** : Fonction de purge
- **`lib/dev/clear_cache_screen.dart`** : Interface de purge
- **Route ajoutée** : `/dev/cache-reset` dans `app_router.dart`

## 🎯 **Résultat attendu**

Après utilisation des outils de purge :
- ✅ **Tous les accents** s'affichent correctement
- ✅ **Plus d'artefacts** RÃ´le, EntrÃ©es, DÃ©pÃ´t
- ✅ **Interface propre** avec caractères français corrects
- ✅ **Cache propre** pour les futures sessions

## 🚨 **Important**

- **Utiliser uniquement en développement** : Ces outils sont pour le debug
- **Une seule fois suffit** : Après purge, les nouveaux bundles UTF-8 sont en cache
- **En production** : Les bundles sont générés en UTF-8 dès le build

Les outils de purge garantissent une interface propre avec tous les accents français corrects ! 🇫🇷