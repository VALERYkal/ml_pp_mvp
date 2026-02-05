# CHECKPOINT — GO-LIVE FRONTEND (Firebase Hosting & HTTPS)

**Projet** : ML_PP MVP (Monaluxe Petrol Platform)  
**Date** : 2026-02-02 (Africa/Kinshasa)  
**Statut** : ✅ **LIVE — Propagation certificat en cours**

---

## 1. Résumé

- Flutter Web SPA déployé sur Firebase Hosting
- Domaine canonique : `https://monaluxe.app` (HTTPS actif côté edge)
- Redirection `www` → apex configurée et fonctionnelle (HTTP 301)
- GoRouter compatible (refresh + deep links OK)
- DNS propagé et validé par tests réels (`curl -I`)
- Certificat Firebase en cours de propagation (statut console non final)
- Aucune action bloquante identifiée

---

## 2. État actuel

| Élément | Statut | Preuve |
|---------|--------|--------|
| Firebase Hosting | ✅ Actif | Site accessible `https://monaluxe.app` |
| HTTPS apex (`monaluxe.app`) | ✅ Actif côté edge | `curl -I https://monaluxe.app` → HTTP/2 200 |
| HTTPS www (`www.monaluxe.app`) | ✅ Actif côté edge | `curl -I https://www.monaluxe.app` → HTTP/2 301 |
| Redirection www → apex | ✅ OK | Header `Location: https://monaluxe.app/` confirmé |
| SPA routing (GoRouter) | ✅ OK | Refresh sur route interne fonctionne |
| Deep links | ✅ OK | Accès direct à `/login`, `/dashboard`, etc. |
| Firebase Console UI | ⚠️ Info | Peut afficher "nécessite une configuration" — **n'affecte pas le HTTPS réel** |
| Certificat Firebase | 🟡 Propagation | Délai normal (jusqu'à 24h), HTTPS déjà fonctionnel |

---

## 2.1 Clarifications importantes

### Le clic sur le lien Firebase ouvre l'app dans un nouvel onglet
- **Comportement observé** : Le lien dans la console Firebase ouvre `https://monaluxe.app` dans un nouvel onglet
- **Interprétation** : L'application est accessible et fonctionnelle
- **Aucune anomalie** : Comportement attendu

### L'absence de "check vert" console ≠ absence de HTTPS réel
- **Fait** : La console Firebase peut afficher un statut "nécessite une configuration" pendant la propagation DNS
- **Fait** : `curl -I https://monaluxe.app` confirme HTTPS actif côté edge
- **Conclusion** : Le statut console est un indicateur visuel, pas une preuve technique
- **Preuve technique** : Les tests `curl` confirment le HTTPS fonctionnel

---

## 3. Configuration

### Firebase Hosting

| Paramètre | Valeur |
|-----------|--------|
| Projet Firebase | `ml-pp-mvp-web` |
| Site par défaut | `ml-pp-mvp-web.web.app` |
| Domaine custom (apex) | `monaluxe.app` |
| Domaine custom (www) | `www.monaluxe.app` (redirige vers apex) |

### DNS (Namecheap)

| Type | Host | Valeur |
|------|------|--------|
| A | `@` | `199.36.158.100` |
| TXT | `@` | `hosting-site=ml-pp-mvp-web` |
| CNAME | `www` | `ml-pp-mvp-web.web.app` |

> Note : Ne pas modifier ces enregistrements sauf si Firebase demande explicitement une mise à jour.

---

## 4. Tests exécutés

- [x] `curl -I https://monaluxe.app` → HTTP/2 200
- [x] `curl -I https://www.monaluxe.app` → HTTP/2 301 + `Location: https://monaluxe.app/`
- [x] Accès navigateur `https://monaluxe.app` → page chargée
- [x] Accès navigateur `https://www.monaluxe.app` → redirection automatique vers apex
- [x] Refresh sur route interne (`/login`, `/dashboard`) → page chargée (pas de 404)
- [x] Deep link direct (`https://monaluxe.app/cours`) → page chargée

---

## 5. Procédure de reprise

Si quelqu'un reprend ce projet demain :

1. **Vérifier l'accès** : `curl -I https://monaluxe.app` doit retourner HTTP/2 200
2. **Vérifier la redirection** : `curl -I https://www.monaluxe.app` doit retourner HTTP/2 301 vers apex
3. **En cas de problème SSL** :
   - Vérifier Firebase Console → Hosting → Domaines personnalisés
   - Attendre propagation DNS (jusqu'à 24h)
   - Ne pas modifier les enregistrements DNS sauf demande explicite Firebase
4. **Déployer une mise à jour** :
   ```bash
   flutter build web --release \
     --dart-define=SUPABASE_URL=xxx \
     --dart-define=SUPABASE_ANON_KEY=xxx
   firebase deploy --only hosting
   ```
5. **Rollback** : Firebase Console → Hosting → Historique des releases → Restaurer

---

## 6. Décision

### Aucun rollback
- L'application est accessible et fonctionnelle
- HTTPS confirmé par tests techniques (`curl -I`)
- Aucune raison de revenir en arrière

### Aucune action corrective
- Le statut console Firebase est un indicateur visuel
- La propagation DNS/certificat est un délai normal (jusqu'à 24h)
- Aucune intervention requise

### Attente passive de finalisation du certificat
- Firebase génère le certificat Let's Encrypt automatiquement
- La propagation complète peut prendre jusqu'à 24h
- Aucune action manuelle nécessaire

---

## 7. Règle de reprise

**Ne pas rouvrir ce point sauf si HTTPS échoue réellement.**

Conditions de réouverture (si et seulement si) :
- `curl -I https://monaluxe.app` retourne une erreur SSL
- L'application n'est plus accessible via HTTPS
- Erreur explicite dans les logs Firebase Hosting

Hors scope de réouverture :
- Statut console Firebase "nécessite une configuration" (attendu)
- Délai de propagation DNS (normal)
- Absence de "check vert" dans la console (indicateur visuel)

---

## 8. Incident Safari — écran blanc après déploiement

### Symptôme

- **Date** : 2026-02-05 (après déploiement PROD)
- **Navigateur** : Safari (macOS/iOS)
- **Comportement** : Écran blanc après chargement de l'application
- **Navigateurs non affectés** : Chrome OK, Firefox OK

### Cause identifiée

**Service Worker Flutter cache ancien build** :

- Le Service Worker Flutter (PWA) avait mis en cache une version antérieure du build
- Après déploiement d'un nouveau build, Safari tentait de charger l'ancien cache via le Service Worker
- Résultat : écran blanc (build incompatible avec le cache)

### Résolution appliquée

1. **Purge données site** : Safari → Développeur → Vider les caches → Données de site
2. **Unregister Service Worker** : Console développeur → Application → Service Workers → Unregister
3. **Hard refresh** : `Cmd + Shift + R` (ou `Ctrl + Shift + R`)

**Résultat** : ✅ Application fonctionnelle sur Safari après purge

### Statut

- ✅ **Résolu** : Incident isolé, résolu par purge cache utilisateur
- ✅ **Validation** : Safari normal OK après résolution
- ✅ **Impact** : Aucun impact sur Chrome ou autres navigateurs

### Recommandation post-PROD

**Envisager désactivation PWA Flutter pour back-office MVP** :

- Le Service Worker Flutter (PWA) peut causer des problèmes de cache après déploiement
- Pour un back-office MVP, la fonctionnalité PWA (offline, installable) n'est pas critique
- **Note** : Recommandation uniquement — aucune implémentation requise immédiatement
- **Décision future** : À évaluer selon les besoins métier (offline requis ou non)

---

## 9. Validation finale exécutée (J0 PROD — 2026-02-05)

### Build Flutter Web

- **Commande** : `flutter build web --release` avec `--dart-define SUPABASE_URL` + `--dart-define SUPABASE_ANON_KEY`
- **Statut** : ✅ Build réussi
- **Configuration** : Variables d'environnement injectées via `--dart-define`

### Déploiement Firebase Hosting

- **Commande** : `firebase deploy --only hosting`
- **Statut** : ✅ Déploiement réussi
- **Plateforme** : Firebase Hosting (projet `ml-pp-mvp-web`)

### Domaine custom validé

- **Domaine** : `https://monaluxe.app`
- **Statut** : ✅ Actif et accessible
- **HTTPS** : ✅ Certificat actif (validé via `curl -I`)
- **Redirection** : ✅ `www.monaluxe.app` → `monaluxe.app` (HTTP 301)

### Incident Safari résolu

- **Symptôme** : Écran blanc après déploiement (Safari uniquement)
- **Cause** : Service Worker Flutter cache ancien build
- **Résolution** : Purge données site, unregister SW, hard refresh
- **Statut** : ✅ Résolu — Safari fonctionnel

### URL de référence PROD

- **Frontend Web** : `https://monaluxe.app`
- **Environnement** : PROD (actif depuis 2026-02-05)
- **Accès** : Public (authentification requise pour usage métier)

---

## 10. Non-objectifs / Post-PROD

Liste des éléments hors périmètre de ce checkpoint (à traiter ultérieurement si nécessaire) :

- Monitoring avancé (Sentry, Analytics)
- CI/CD automatisé (GitHub Actions → Firebase)
- Environnement staging Firebase séparé
- Cache headers personnalisés
- Optimisation bundle size
- PWA manifest / Service Worker avancé (voir recommandation section 8)

---

**Document créé le** : 2026-02-02  
**Mise à jour** : 2026-02-05  
**Auteur** : Session Cursor  
**Statut** : ✅ Checkpoint validé — Propagation certificat en cours — Incident Safari résolu
