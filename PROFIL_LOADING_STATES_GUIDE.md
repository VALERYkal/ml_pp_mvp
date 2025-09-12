# 🔄 Guide des états de chargement du profil

## 🎯 **Objectif**
Gérer proprement les états de chargement du profil utilisateur avec get-or-create automatique, sans afficher d'erreurs prématurées.

## 🛠️ **Composants disponibles**

### **1. ProfilLoadingWidget**
Widget helper pour gérer automatiquement les états de chargement du profil.

```dart
ProfilLoadingWidget(
  builder: (profil) => YourContentWidget(profil: profil),
  loadingWidget: CustomLoadingWidget(), // optionnel
  errorWidget: (error, stackTrace) => CustomErrorWidget(), // optionnel
  noProfilWidget: CustomNoProfilWidget(), // optionnel
)
```

### **2. Providers mis à jour**
- **`currentProfilProvider`** : AsyncNotifier avec get-or-create automatique
- **`userRoleProvider`** : Nullable, pas de fallback prématuré
- **`hasProfilProvider`** : Bool basé sur l'état du profil
- **`userProfilProvider`** : Profil nullable pour compatibilité

## 🚀 **Utilisation recommandée**

### **Méthode 1 : ProfilLoadingWidget (Recommandée)**
```dart
ProfilLoadingWidget(
  builder: (profil) => DashboardContent(profil: profil),
)
```

### **Méthode 2 : Gestion manuelle avec maybeWhen**
```dart
final profilAsync = ref.watch(currentProfilProvider);

return profilAsync.when(
  data: (profil) => profil == null 
      ? const NoProfilWidget() 
      : ContentWidget(profil: profil),
  loading: () => const LoadingWidget(),
  error: (error, stackTrace) => ErrorWidget(error: error),
);
```

### **Méthode 3 : Utilisation des providers dérivés**
```dart
// Pour le rôle (nullable)
final role = ref.watch(userRoleProvider);
final safeRole = role ?? UserRole.lecture;

// Pour vérifier l'existence du profil
final hasProfil = ref.watch(hasProfilProvider);

// Pour le profil (nullable)
final profil = ref.watch(userProfilProvider);
```

## 🔄 **Flux de chargement**

### **1. Connexion utilisateur**
1. **Auth réussi** → `currentProfilProvider` se déclenche
2. **Chargement** → `AsyncLoading` affiché
3. **Récupération** → Tente `getByCurrentUser()`
4. **Si null** → Crée automatiquement avec `getOrCreateByCurrentUser()`
5. **Succès** → `AsyncData<Profil>` avec profil créé/trouvé

### **2. États possibles**
- **`AsyncLoading`** : Récupération/création en cours
- **`AsyncData<Profil>`** : Profil disponible
- **`AsyncData<null>`** : Utilisateur non connecté
- **`AsyncError`** : Erreur de récupération/création

## 🎨 **Widgets par défaut**

### **Chargement**
```dart
Center(
  child: Column(
    children: [
      CircularProgressIndicator(),
      Text('Chargement du profil...'),
    ],
  ),
)
```

### **Erreur**
```dart
Center(
  child: Column(
    children: [
      Icon(Icons.error_outline, color: Colors.red),
      Text('Erreur lors du chargement du profil'),
      Text(error.toString()),
    ],
  ),
)
```

### **Aucun profil**
```dart
Center(
  child: Column(
    children: [
      Icon(Icons.person_off, color: Colors.grey),
      Text('Aucun profil trouvé'),
    ],
  ),
)
```

## 🔧 **Configuration**

### **Rôle par défaut lors de la création**
Dans `CurrentProfilNotifier.build()` :
```dart
final created = await svc.getOrCreateByCurrentUser(
  defaultRole: 'lecture', // ← Modifier ici
  email: email,
);
```

### **Logs de débogage**
Les logs suivants apparaissent dans la console :
- `✅ ProfilProvider: Profil trouvé - role: ${existing.role}`
- `✅ ProfilProvider: Profil créé - role: ${created.role}`

## 🚨 **Points d'attention**

### **❌ À éviter**
- Vérifier le profil dans le login screen (supprimé)
- Fallback prématuré vers un rôle par défaut
- Affichage d'erreurs avant la création automatique

### **✅ Bonnes pratiques**
- Utiliser `ProfilLoadingWidget` pour l'UI
- Laisser le router gérer la redirection
- Gérer les états `AsyncLoading`, `AsyncData`, `AsyncError`
- Utiliser `userRoleProvider` (nullable) pour la navigation

## 🎯 **Résultat attendu**

Après implémentation :
- ✅ **Plus d'erreur** "Aucun profil trouvé" prématurée
- ✅ **Création automatique** du profil si inexistant
- ✅ **États de chargement** clairs pour l'utilisateur
- ✅ **Redirection fluide** vers le dashboard approprié
- ✅ **Logs informatifs** pour le débogage

Le système gère maintenant automatiquement la création des profils avec des états de chargement appropriés ! 🎉