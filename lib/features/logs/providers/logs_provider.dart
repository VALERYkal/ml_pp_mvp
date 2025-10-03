import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Modèle pour un filtre de logs
class LogsFilter {
  final String period;
  final String? module;
  final String? utilisateur;

  const LogsFilter({this.period = '30d', this.module, this.utilisateur});

  LogsFilter copyWith({String? period, String? module, String? utilisateur}) {
    return LogsFilter(
      period: period ?? this.period,
      module: module ?? this.module,
      utilisateur: utilisateur ?? this.utilisateur,
    );
  }
}

/// Modèle pour un log d'activité
class LogActivite {
  final String id;
  final String module;
  final String action;
  final String niveau;
  final String utilisateur;
  final DateTime createdAt;
  final Map<String, dynamic> details;

  const LogActivite({
    required this.id,
    required this.module,
    required this.action,
    required this.niveau,
    required this.utilisateur,
    required this.createdAt,
    required this.details,
  });

  String get createdAtFmt {
    return '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
  }
}

/// Provider pour le filtre des logs
final logsFilterProvider = StateProvider<LogsFilter>(
  (ref) => const LogsFilter(),
);

/// Provider pour les logs filtrés
final logsProvider = FutureProvider.family<List<LogActivite>, LogsFilter>((
  ref,
  filter,
) async {
  // Simuler un délai de chargement
  await Future.delayed(const Duration(milliseconds: 400));

  // Simuler des données de logs
  final now = DateTime.now();
  return [
    LogActivite(
      id: '1',
      module: 'Réceptions',
      action: 'Nouvelle réception validée',
      niveau: 'INFO',
      utilisateur: 'admin@ml.pp',
      createdAt: now.subtract(const Duration(hours: 2)),
      details: {'volume': 25000, 'produit': 'Essence 95'},
    ),
    LogActivite(
      id: '2',
      module: 'Sorties',
      action: 'Sortie produit enregistrée',
      niveau: 'INFO',
      utilisateur: 'gerant@ml.pp',
      createdAt: now.subtract(const Duration(hours: 4)),
      details: {'volume': 15000, 'produit': 'Gasoil'},
    ),
    LogActivite(
      id: '3',
      module: 'Citernes',
      action: 'Citerne sous seuil détectée',
      niveau: 'WARNING',
      utilisateur: 'system',
      createdAt: now.subtract(const Duration(hours: 6)),
      details: {'citerne': 'A1', 'seuil': 10000, 'stock': 8000},
    ),
    LogActivite(
      id: '4',
      module: 'Système',
      action: 'Sauvegarde automatique',
      niveau: 'INFO',
      utilisateur: 'system',
      createdAt: now.subtract(const Duration(hours: 8)),
      details: {'type': 'backup', 'size': '2.5GB'},
    ),
    LogActivite(
      id: '5',
      module: 'Authentification',
      action: 'Connexion utilisateur',
      niveau: 'INFO',
      utilisateur: 'directeur@ml.pp',
      createdAt: now.subtract(const Duration(hours: 10)),
      details: {'ip': '192.168.1.100'},
    ),
  ];
});
