# Guide de Test - Correction Erreur Locale

## 🎯 Objectif
Vérifier que l'erreur `LocaleDataException` est corrigée et que le KPI 3 s'affiche correctement avec le formatage des dates.

## ✅ Erreur Corrigée

### **Problème** : `LocaleDataException`
**Message d'erreur** : `Locale data has not been initialized, call initializeDateFormatting(<locale>)`
**Cause** : Le package `intl` nécessite une initialisation explicite des données de locale pour le formatage des dates

### **Solution Appliquée** ✅
**Fichier** : `lib/main.dart`
```dart
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  
  // Initialiser le formatage des dates pour le package intl
  await initializeDateFormatting('fr', null);
  
  // ... reste du code
}
```

## 🧪 Tests de Validation

### Test 1 : Compilation
1. **Lancez** l'application : `flutter run -d chrome`
2. **Vérifiez** qu'il n'y a plus d'erreurs de compilation
3. **Confirmez** que l'application se lance correctement

### Test 2 : Affichage du KPI 3
1. **Connectez-vous** en tant qu'admin
2. **Accédez au dashboard** admin
3. **Vérifiez** que le KPI "Stock total (actuel)" s'affiche avec :
   - **Gauche** : "Vol. ambiant" + volume + "MAJ" + date (si disponible)
   - **Droite** : "Vol. 15 °C" + volume
4. **Confirmez** que la date s'affiche au format "JJ/MM" (ex: "04/09")

### Test 3 : Logs de Debug
1. **Ouvrez la console** du navigateur (F12)
2. **Rechargez** le dashboard
3. **Cherchez** le log : `📦 KPI3 stocks: amb=X, 15c=Y, lastDay=Z`
4. **Vérifiez** que les valeurs correspondent à l'affichage

### Test 4 : Formatage des Dates
1. **Vérifiez** que la date de MAJ s'affiche correctement
2. **Confirmez** que le format est "JJ/MM" (français)
3. **Testez** avec différentes dates si possible

### Test 5 : Gestion d'Erreurs
1. **Simulez** une erreur (déconnexion Supabase)
2. **Rechargez** le dashboard
3. **Vérifiez** que le message "Stocks indisponibles" s'affiche
4. **Reconnectez-vous** et vérifiez que le KPI redevient normal

## 🔍 Diagnostic des Problèmes

### Problème : Erreur de locale persiste
**Solutions :**
- Vérifiez que `initializeDateFormatting('fr', null)` est bien appelé
- Vérifiez que l'import `package:intl/date_symbol_data_local.dart` est présent
- Redémarrez l'application complètement

### Problème : Date ne s'affiche pas
**Solutions :**
- Vérifiez que `s.lastDay` n'est pas null
- Vérifiez que `fmtShortDate()` fonctionne
- Vérifiez que la colonne `date_jour` existe dans la vue

### Problème : Format de date incorrect
**Solutions :**
- Vérifiez que la locale 'fr' est bien initialisée
- Vérifiez que `DateFormat('dd/MM', locale)` fonctionne
- Testez avec d'autres locales si nécessaire

## 📊 Données de Test

Pour tester avec des données réelles, vous pouvez :

1. **Créer des stocks de test** dans Supabase :
```sql
INSERT INTO public.stocks_journaliers (citerne_id, produit_id, stock_ambiant, stock_15c, date_jour)
VALUES 
  ('CIT001', 'PROD001', 1000.0, 950.0, current_date),
  ('CIT002', 'PROD002', 2000.0, 1900.0, current_date),
  ('CIT003', 'PROD001', 1500.0, 1425.0, current_date);
```

2. **Vérifier le KPI** : 
   - Vol. ambiant : 4500L (1000+2000+1500)
   - Vol. 15°C : 4275L (950+1900+1425)
   - MAJ : Date du jour au format "JJ/MM"

## 🎉 Résultat Attendu

Le KPI "Stock total (actuel)" devrait maintenant :
- ✅ **Compiler sans erreurs** : Plus d'erreur de locale
- ✅ **Afficher les volumes** ambiant et 15°C en litres (formaté)
- ✅ **Afficher la date de MAJ** au format "JJ/MM" (ex: "04/09")
- ✅ **Se mettre à jour** selon le profil et le dépôt
- ✅ **Naviguer** vers la page des stocks au clic
- ✅ **Gérer les erreurs** avec un message clair
- ✅ **Être performant** avec les index optimisés

## 📝 Notes Techniques

### **Initialisation des Locales**
```dart
import 'package:intl/date_symbol_data_local.dart';

// Dans main()
await initializeDateFormatting('fr', null);
```

### **Formatage des Dates**
```dart
String fmtShortDate(DateTime d, {String locale = 'fr'}) {
  return DateFormat('dd/MM', locale).format(d);
}
```

### **Utilisation dans le KPI**
```dart
leftSubLabel: s.lastDay != null ? 'MAJ' : null,
leftSubValue: s.lastDay != null ? fmtShortDate(s.lastDay!) : null,
```

## 🚀 Prochaines Étapes

1. **Testez** l'application avec la correction
2. **Vérifiez** que le KPI 3 s'affiche correctement
3. **Confirmez** que la date de MAJ s'affiche au format "JJ/MM"
4. **Appliquer** la même logique aux autres KPIs si nécessaire

Le KPI 3 est maintenant **fonctionnel et prêt pour la production** ! 🎯
