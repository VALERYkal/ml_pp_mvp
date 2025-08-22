// 📌 Module : Core Models
// 🧑 Auteur : Valery Kalonga
// 📅 Date : 2025-08-07
// 🗃️ Source SQL : Table `public.profils` (contrainte role_check)
// 🧭 Description : Enum des rôles utilisateur autorisés dans l'application

/// Enum des rôles utilisateur autorisés dans ML_PP MVP
/// 
/// Définit tous les rôles possibles pour un utilisateur de l'application.
/// Ces valeurs correspondent à la contrainte `role_check` de la table `profils`.
/// 
/// Utilisé pour :
/// - Le typage du champ `role` dans le modèle `Profil`
/// - La validation des permissions dans l'application
/// - L'affichage conditionnel des fonctionnalités par rôle
enum UserRole {
  /// Administrateur - Accès complet à toutes les fonctionnalités
  /// Peut créer, modifier, supprimer tous les éléments
  admin('admin'),
  
  /// Directeur - Accès aux fonctionnalités de direction
  /// Peut valider les réceptions et sorties, voir les rapports
  directeur('directeur'),
  
  /// Gerant - Accès aux fonctionnalités de gestion
  /// Peut gérer les stocks et les mouvements
  gerant('gerant'),
  
  /// Operateur - Accès aux fonctionnalités opérationnelles
  /// Peut créer des cours de route et des réceptions
  operateur('operateur'),
  
  /// PCA (Personne Chargée d'Affaires) - Accès limité
  /// Peut consulter les informations de base
  pca('pca'),
  
  /// Lecture seule - Accès en consultation uniquement
  /// Ne peut que visualiser les données
  lecture('lecture');

  /// Valeur stockée en base de données
  final String value;
  
  /// Constructeur avec la valeur de la base
  const UserRole(this.value);
  
  /// Convertit une chaîne en UserRole
  /// 
  /// [value] : La valeur de la base de données
  /// 
  /// Retourne :
  /// - `UserRole` : L'enum correspondant
  /// - `null` : Si la valeur n'est pas reconnue
  /// 
  /// Utilisé pour la désérialisation depuis Supabase
  static UserRole? fromString(String? value) {
    if (value == null) return null;
    
    for (final role in UserRole.values) {
      if (role.value == value) return role;
    }
    return null;
  }
  
  /// Convertit l'enum en chaîne pour la base de données
  /// 
  /// Retourne la valeur à stocker en base
  String toJson() => value;
  
  /// Vérifie si le rôle a des permissions d'administration
  /// 
  /// Retourne `true` pour admin, directeur, gérant
  bool get isAdmin => this == UserRole.admin;
  
  /// Vérifie si le rôle a des permissions de direction
  /// 
  /// Retourne `true` pour admin, directeur
  bool get isDirector => this == UserRole.admin || this == UserRole.directeur;
  
  /// Vérifie si le rôle a des permissions de gestion
  /// 
  /// Retourne `true` pour admin, directeur, gerant
  bool get isManager => this == UserRole.admin || this == UserRole.directeur || this == UserRole.gerant;
  
  /// Vérifie si le rôle peut créer des mouvements
  /// 
  /// Retourne `true` pour admin, directeur, gerant, operateur
  bool get canCreateMovements => this == UserRole.admin || 
                                this == UserRole.directeur || 
                                this == UserRole.gerant || 
                                this == UserRole.operateur;
  
  /// Vérifie si le rôle peut valider des mouvements
  /// 
  /// Retourne `true` pour admin, directeur, gerant
  bool get canValidateMovements => this == UserRole.admin || 
                                  this == UserRole.directeur || 
                                  this == UserRole.gerant;
  
  /// Vérifie si le rôle a un accès en lecture seule
  /// 
  /// Retourne `true` pour pca, lecture
  bool get isReadOnly => this == UserRole.pca || this == UserRole.lecture;
  
  @override
  String toString() => value;
}

/// Extension pour UserRole avec parsing robuste
extension UserRoleX on UserRole {
  /// Valeur normalisée sans accents
  String get value => switch (this) {
    UserRole.admin => 'admin',
    UserRole.directeur => 'directeur',
    UserRole.gerant => 'gerant',
    UserRole.operateur => 'operateur',
    UserRole.lecture => 'lecture',
    UserRole.pca => 'pca',
  };

  /// Normalise une chaîne en supprimant accents et casse
  static String _normalize(String s) {
    final lower = s.trim().toLowerCase();
    return lower
      .replaceAll(RegExp(r'[éèêë]'), 'e')
      .replaceAll(RegExp(r'[àáâä]'), 'a')
      .replaceAll(RegExp(r'[îïí]'), 'i')
      .replaceAll(RegExp(r'[ôöó]'), 'o')
      .replaceAll(RegExp(r'[ûüú]'), 'u')
      .replaceAll('ç', 'c');
  }

  /// Parse une chaîne en UserRole avec normalisation
  static UserRole? parse(String? raw) {
    if (raw == null) return null;
    final s = _normalize(raw);
    switch (s) {
      case 'admin': return UserRole.admin;
      case 'directeur': return UserRole.directeur;
      case 'gerant': return UserRole.gerant;        // « gérant » normalisé
      case 'operateur': return UserRole.operateur;  // « opérateur » normalisé
      case 'lecture': return UserRole.lecture;
      case 'pca': return UserRole.pca;
      default: return null;
    }
  }

  /// Parse avec fallback sécurisé
  static UserRole fromStringOrDefault(String? raw, {UserRole fallback = UserRole.lecture}) {
    return parse(raw) ?? fallback; // ⛔️ plus de fallback admin
  }

  /// Mappe un rôle vers sa route de dashboard
  static String roleToHome(UserRole r) => switch (r) {
    UserRole.admin => '/dashboard/admin',
    UserRole.directeur => '/dashboard/directeur',
    UserRole.gerant => '/dashboard/gerant',
    UserRole.operateur => '/dashboard/operateur',
    UserRole.lecture => '/dashboard/lecture',
    UserRole.pca => '/dashboard/pca',
  };
}
