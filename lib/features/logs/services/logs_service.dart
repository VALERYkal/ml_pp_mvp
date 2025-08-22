import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/logs_provider.dart';

/// Service pour les logs
class LogsService {
  /// Export CSV des logs
  Future<String> exportCsv(LogsFilter filter) async {
    // Simuler un délai d'export
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Simuler des données d'export
    final now = DateTime.now();
    final csv = StringBuffer();
    csv.writeln('Date,Module,Action,Niveau,Utilisateur,Details');
    
    // Générer quelques lignes d'exemple
    for (int i = 0; i < 10; i++) {
      final date = now.subtract(Duration(hours: i * 2));
      final dateStr = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      
      csv.writeln('$dateStr,Réceptions,Nouvelle réception,INFO,admin@ml.pp,"volume: 25000, produit: Essence 95"');
    }
    
    return csv.toString();
  }
}

/// Provider pour le service des logs
final logsServiceProvider = Provider<LogsService>((ref) => LogsService());
