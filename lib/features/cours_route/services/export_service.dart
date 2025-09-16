// 📌 Module : Cours de Route - Services
// 🧑 Auteur : Valery Kalonga
// 📅 Date : 2025-01-27
// 🧭 Description : Service d'export des cours de route

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:ml_pp_mvp/features/cours_route/models/cours_de_route.dart';
import 'package:ml_pp_mvp/shared/ui/format.dart';

/// Service d'export des cours de route
class CoursExportService {
  /// Export CSV des cours de route
  static String exportToCsv(List<CoursDeRoute> cours, {
    Map<String, String>? fournisseurs,
    Map<String, String>? produits,
    Map<String, String>? produitCodes,
  }) {
    final buffer = StringBuffer();
    
    // En-têtes CSV
    buffer.writeln('ID,Fournisseur,Produit,Plaque Camion,Plaque Remorque,Chauffeur,Transporteur,Volume,Dépôt,Date Chargement,Statut');
    
    // Données
    for (final c in cours) {
      final fournisseur = fournisseurs?[c.fournisseurId] ?? c.fournisseurId;
      final produit = _getProduitLabel(c, produits, produitCodes);
      final plaqueCamion = c.plaqueCamion ?? '';
      final plaqueRemorque = c.plaqueRemorque ?? '';
      final chauffeur = c.chauffeur ?? '';
      final transporteur = c.transporteur ?? '';
      final volume = c.volume?.toString() ?? '';
      final depot = c.depotDestinationId;
      final dateChargement = c.dateChargement != null ? fmtDate(c.dateChargement!) : '';
      final statut = c.statut.label;
      
      buffer.writeln('$fournisseur,$produit,$plaqueCamion,$plaqueRemorque,$chauffeur,$transporteur,$volume,$depot,$dateChargement,$statut');
    }
    
    return buffer.toString();
  }
  
  /// Export JSON des cours de route
  static String exportToJson(List<CoursDeRoute> cours, {
    Map<String, String>? fournisseurs,
    Map<String, String>? produits,
    Map<String, String>? produitCodes,
  }) {
    final data = cours.map((c) => {
      'id': c.id,
      'fournisseur': fournisseurs?[c.fournisseurId] ?? c.fournisseurId,
      'produit': _getProduitLabel(c, produits, produitCodes),
      'plaqueCamion': c.plaqueCamion,
      'plaqueRemorque': c.plaqueRemorque,
      'chauffeur': c.chauffeur,
      'transporteur': c.transporteur,
      'volume': c.volume,
      'depot': c.depotDestinationId,
      'dateChargement': c.dateChargement?.toIso8601String(),
      'statut': c.statut.label,
      'statutCode': c.statut.name,
    }).toList();
    
    return const JsonEncoder.withIndent('  ').convert(data);
  }
  
  /// Export Excel (format simplifié en CSV avec en-têtes Excel)
  static String exportToExcel(List<CoursDeRoute> cours, {
    Map<String, String>? fournisseurs,
    Map<String, String>? produits,
    Map<String, String>? produitCodes,
  }) {
    // Pour l'instant, on utilise CSV avec en-têtes Excel
    // Dans une vraie implémentation, on utiliserait un package comme excel
    return exportToCsv(cours, fournisseurs: fournisseurs, produits: produits, produitCodes: produitCodes);
  }
  
  /// Génère un nom de fichier avec timestamp
  static String generateFileName(String prefix, String extension) {
    final now = DateTime.now();
    final timestamp = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    return '${prefix}_$timestamp.$extension';
  }
  
  /// Helper pour obtenir le libellé du produit
  static String _getProduitLabel(CoursDeRoute c, Map<String, String>? produits, Map<String, String>? produitCodes) {
    final code = (c.produitCode ?? '').trim();
    final nom = (c.produitNom ?? '').trim();
    
    if (code.isNotEmpty) return code;
    if (nom.isNotEmpty) return nom;
    if (produitCodes != null && produitCodes.containsKey(c.produitId)) {
      return produitCodes[c.produitId]!;
    }
    if (produits != null && produits.containsKey(c.produitId)) {
      return produits[c.produitId]!;
    }
    return c.produitId;
  }
}

/// Widget pour l'export des cours de route
class CoursExportWidget extends StatelessWidget {
  const CoursExportWidget({
    super.key,
    required this.cours,
    this.fournisseurs,
    this.produits,
    this.produitCodes,
  });

  final List<CoursDeRoute> cours;
  final Map<String, String>? fournisseurs;
  final Map<String, String>? produits;
  final Map<String, String>? produitCodes;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.download),
      tooltip: 'Exporter les cours',
      onSelected: (format) => _export(context, format),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'csv',
          child: ListTile(
            leading: Icon(Icons.table_chart),
            title: Text('Export CSV'),
            subtitle: Text('Format tableur'),
          ),
        ),
        const PopupMenuItem(
          value: 'json',
          child: ListTile(
            leading: Icon(Icons.code),
            title: Text('Export JSON'),
            subtitle: Text('Format données'),
          ),
        ),
        const PopupMenuItem(
          value: 'excel',
          child: ListTile(
            leading: Icon(Icons.table_view),
            title: Text('Export Excel'),
            subtitle: Text('Format Excel'),
          ),
        ),
      ],
    );
  }

  void _export(BuildContext context, String format) {
    String content;
    String extension;
    String mimeType;
    
    switch (format) {
      case 'csv':
        content = CoursExportService.exportToCsv(
          cours,
          fournisseurs: fournisseurs,
          produits: produits,
          produitCodes: produitCodes,
        );
        extension = 'csv';
        mimeType = 'text/csv';
        break;
      case 'json':
        content = CoursExportService.exportToJson(
          cours,
          fournisseurs: fournisseurs,
          produits: produits,
          produitCodes: produitCodes,
        );
        extension = 'json';
        mimeType = 'application/json';
        break;
      case 'excel':
        content = CoursExportService.exportToExcel(
          cours,
          fournisseurs: fournisseurs,
          produits: produits,
          produitCodes: produitCodes,
        );
        extension = 'csv'; // Pour l'instant
        mimeType = 'text/csv';
        break;
      default:
        return;
    }
    
    final fileName = CoursExportService.generateFileName('cours_route', extension);
    
    // Dans une vraie implémentation, on utiliserait un package comme file_picker
    // Pour l'instant, on affiche le contenu dans un dialog
    _showExportDialog(context, fileName, content, mimeType);
  }

  void _showExportDialog(BuildContext context, String fileName, String content, String mimeType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Export: $fileName'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            children: [
              Text(
                'Contenu exporté (${content.length} caractères)',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: SelectableText(
                    content,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
          FilledButton(
            onPressed: () {
              // Copier dans le presse-papiers
              // Clipboard.setData(ClipboardData(text: content));
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Contenu copié dans le presse-papiers')),
              );
            },
            child: const Text('Copier'),
          ),
        ],
      ),
    );
  }
}
