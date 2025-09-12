# 🔧 Guide de résolution des problèmes

## Problème 1 : "Aucun profil trouvé" après connexion

### Symptômes
- Connexion réussie (✅ AuthService: Connexion réussie)
- Message "⚠️ ProfilProvider: Aucun profil trouvé pour l'utilisateur connecté"
- Redirection vers écran d'erreur

### Cause
L'utilisateur existe dans `auth.users` mais n'a pas de profil dans `public.profils`.

### Solution
1. **Exécuter le script SQL** dans Supabase SQL Editor :

   **Pour l'utilisateur directeur (dir@ml.pp)** :
   ```sql
   INSERT INTO public.profils (user_id, role, depot_id, nom, prenom, email, telephone, created_at, updated_at)
   VALUES (
     'a25fe6ec-be09-428a-a276-27e650320d4e', -- ID de l'utilisateur directeur
     'directeur',
     'depot-001',
     'Directeur',
     'Test',
     'dir@ml.pp',
     '+243123456789',
     NOW(),
     NOW()
   )
   ON CONFLICT (user_id) DO UPDATE SET role = EXCLUDED.role;
   ```

   **Pour l'utilisateur admin (admin@ml.pp)** :
   ```sql
   INSERT INTO public.profils (user_id, role, depot_id, nom, prenom, email, telephone, created_at, updated_at)
   VALUES (
     'd96de149-8732-475f-a9d2-9f5b3466c4fb', -- ID de l'utilisateur admin
     'admin',
     'depot-001',
     'Admin',
     'Système',
     'admin@ml.pp',
     '+243123456789',
     NOW(),
     NOW()
   )
   ON CONFLICT (user_id) DO UPDATE SET role = EXCLUDED.role;
   ```

2. **Vérifier les politiques RLS** sur la table `profils` :
   ```sql
   SELECT policyname, cmd, qual FROM pg_policies WHERE tablename = 'profils';
   ```

## Problème 2 : Erreur "relation public.logs does not exist"

### Symptômes
- Erreur PostgrestException avec code 42P01
- Message "relation 'public.logs' does not exist"

### Cause
Le dashboard admin essaie d'accéder à une table `logs` qui n'existe pas.

### Solution temporaire
✅ **Déjà corrigé** - Le dashboard admin a été modifié pour ne plus charger les logs automatiquement.

### Solution définitive
1. **Créer la table logs** dans Supabase SQL Editor :
   ```sql
   CREATE TABLE IF NOT EXISTS public.log_actions (
     id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
     created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
     module TEXT NOT NULL,
     action TEXT NOT NULL,
     niveau TEXT NOT NULL CHECK (niveau IN ('INFO', 'WARNING', 'CRITICAL')),
     user_id UUID REFERENCES auth.users(id),
     details JSONB DEFAULT '{}'::jsonb
   );
   
   ALTER TABLE public.log_actions ENABLE ROW LEVEL SECURITY;
   ```

2. **Créer les politiques RLS** :
   ```sql
   CREATE POLICY "Users can insert their own logs" ON public.log_actions
     FOR INSERT WITH CHECK (auth.uid() = user_id OR user_id IS NULL);
   
   CREATE POLICY "Staff can read logs" ON public.log_actions
     FOR SELECT USING (
       EXISTS (
         SELECT 1 FROM public.profils 
         WHERE user_id = auth.uid() 
         AND role IN ('admin', 'directeur')
       )
     );
   ```

## Problème 3 : Redirection vers "lecture" au lieu du bon rôle

### Symptômes
- Connexion réussie mais redirection vers `/dashboard/lecture`
- Mauvais dashboard affiché

### Cause
Le provider `userRoleProvider` fallback vers "lecture" pendant le chargement.

### Solution
✅ **Déjà corrigé** - Le provider retourne maintenant `null` pendant le chargement et utilise `/splash` pour l'attente.

## Scripts de diagnostic

### Vérifier l'état de la base de données
```sql
-- Utilisateur et profil
SELECT 
  u.id, u.email, u.last_sign_in_at,
  p.role, p.depot_id, p.nom, p.prenom
FROM auth.users u
LEFT JOIN public.profils p ON u.id = p.user_id
WHERE u.email = 'dir@ml.pp';

-- Tables existantes
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- Politiques RLS
SELECT tablename, policyname, cmd FROM pg_policies 
WHERE tablename IN ('profils', 'log_actions');
```

## Prochaines étapes

1. **Exécuter le script de création de profil** dans Supabase
2. **Tester la connexion** avec l'utilisateur directeur
3. **Vérifier la redirection** vers `/dashboard/directeur`
4. **Créer la table logs** si nécessaire pour le dashboard admin

## Statut actuel

### ✅ Problèmes résolus
- **Connexion admin** : L'utilisateur `admin@ml.pp` se connecte avec succès
- **Profil récupéré** : ✅ ProfilService: Profil récupéré avec succès - Role: admin
- **Redirection** : L'application redirige correctement vers `/dashboard/admin`
- **Erreurs de compilation** : Corrigées (références à `filter` supprimées)

### 🔄 En cours
- **Test de connexion directeur** : Vérifier si `dir@ml.pp` fonctionne après création du profil
- **Dashboard admin** : Section logs temporairement désactivée

### 📋 Actions requises
1. **Créer le profil directeur** dans Supabase (script fourni)
2. **Tester la connexion** avec les deux utilisateurs
3. **Optionnel** : Créer la table `log_actions` pour réactiver les logs

## Fichiers modifiés

- ✅ `lib/features/dashboard/screens/dashboard_admin_screen.dart` - Logs temporairement désactivés
- ✅ `lib/features/profil/providers/profil_provider.dart` - Rôle nullable
- ✅ `lib/shared/navigation/app_router.dart` - Redirection corrigée
- ✅ `lib/features/splash/splash_screen.dart` - Écran d'attente ajouté