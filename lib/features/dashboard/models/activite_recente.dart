/// Modèle pour représenter une activité récente
class ActiviteRecente {
  final String id;
  final DateTime createdAt;
  final String module;
  final String action;
  final String niveau;
  final String? userId;
  final Map<String, dynamic>? details;

  const ActiviteRecente({
    required this.id,
    required this.createdAt,
    required this.module,
    required this.action,
    required this.niveau,
    this.userId,
    this.details,
  });

  factory ActiviteRecente.fromMap(Map<String, dynamic> map) {
    return ActiviteRecente(
      id: map['id']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
      module: map['module']?.toString() ?? '',
      action: map['action']?.toString() ?? '',
      niveau: map['niveau']?.toString() ?? '',
      userId: map['user_id']?.toString(),
      details: map['details'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'module': module,
      'action': action,
      'niveau': niveau,
      'user_id': userId,
      'details': details,
    };
  }

  /// Formatage de la date de création
  String get createdAtFmt {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inMinutes < 1) {
      return 'À l\'instant';
    } else if (diff.inMinutes < 60) {
      return 'Il y a ${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      return 'Il y a ${diff.inHours}h';
    } else if (diff.inDays < 7) {
      return 'Il y a ${diff.inDays} jour${diff.inDays > 1 ? 's' : ''}';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  /// Nom d'utilisateur formaté (pour l'instant, retourne l'ID)
  String? get userName {
    if (userId == null) return null;
    // Pour l'instant, on retourne l'ID. Plus tard, on pourra faire une jointure
    // avec la table users pour récupérer le nom réel
    return 'User $userId';
  }
}

