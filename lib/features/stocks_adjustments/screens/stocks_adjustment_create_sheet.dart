// 📌 Module : Stocks Adjustments - Create Sheet
// 🧑 Auteur : Valery Kalonga
// 📅 Date : 2026-01-01
// 🧭 Description : BottomSheet Material 3 pour créer un ajustement de stock industriel complet

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ml_pp_mvp/features/stocks_adjustments/providers/stocks_adjustments_providers.dart';
import 'package:ml_pp_mvp/core/errors/stocks_adjustments_exception.dart';
import 'package:ml_pp_mvp/shared/ui/toast.dart';
import 'package:ml_pp_mvp/shared/utils/volume_calc.dart';

/// Type de correction d'ajustement
enum AdjustmentType {
  volume,
  temperature,
  densite,
  mixte,
}

extension AdjustmentTypeX on AdjustmentType {
  String get label {
    switch (this) {
      case AdjustmentType.volume:
        return 'Volume';
      case AdjustmentType.temperature:
        return 'Température';
      case AdjustmentType.densite:
        return 'Densité';
      case AdjustmentType.mixte:
        return 'Mixte';
    }
  }

  String get prefix {
    switch (this) {
      case AdjustmentType.volume:
        return '[VOLUME]';
      case AdjustmentType.temperature:
        return '[TEMP]';
      case AdjustmentType.densite:
        return '[DENSITE]';
      case AdjustmentType.mixte:
        return '[MIXTE]';
    }
  }
}

/// Données du mouvement (réception ou sortie)
class MovementData {
  final double volumeAmbiant;
  final double? temperatureC;
  final double? densiteA15;
  final double? volumeCorrige15c;

  MovementData({
    required this.volumeAmbiant,
    this.temperatureC,
    this.densiteA15,
    this.volumeCorrige15c,
  });
}

/// BottomSheet réutilisable pour créer un ajustement de stock
class StocksAdjustmentCreateSheet extends ConsumerStatefulWidget {
  final String mouvementType;
  final String mouvementId;
  final VoidCallback? onSuccess;

  const StocksAdjustmentCreateSheet({
    super.key,
    required this.mouvementType,
    required this.mouvementId,
    this.onSuccess,
  });

  /// Helper pour afficher le BottomSheet
  static Future<void> show(
    BuildContext context, {
    required String mouvementType,
    required String mouvementId,
    VoidCallback? onSuccess,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => StocksAdjustmentCreateSheet(
        mouvementType: mouvementType,
        mouvementId: mouvementId,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  ConsumerState<StocksAdjustmentCreateSheet> createState() =>
      _StocksAdjustmentCreateSheetState();
}

class _StocksAdjustmentCreateSheetState
    extends ConsumerState<StocksAdjustmentCreateSheet> {
  final _formKey = GlobalKey<FormState>();
  final _correctionAmbianteController = TextEditingController();
  final _nouvelleTemperatureController = TextEditingController();
  final _nouvelleDensiteController = TextEditingController();
  final _reasonController = TextEditingController();

  AdjustmentType _selectedType = AdjustmentType.volume;
  bool _isLoading = false;
  bool _isLoadingMovement = true;
  MovementData? _movementData;

  @override
  void initState() {
    super.initState();
    _loadMovementData();
  }

  @override
  void dispose() {
    _correctionAmbianteController.dispose();
    _nouvelleTemperatureController.dispose();
    _nouvelleDensiteController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  /// Charge les données du mouvement depuis la DB
  Future<void> _loadMovementData() async {
    try {
      final client = Supabase.instance.client;
      final tableName = widget.mouvementType == 'RECEPTION'
          ? 'receptions'
          : 'sorties_produit';

      final res = await client
          .from(tableName)
          .select(
            'volume_ambiant, temperature_ambiante_c, densite_a_15, volume_corrige_15c',
          )
          .eq('id', widget.mouvementId)
          .maybeSingle();

      if (res != null) {
        final data = res as Map<String, dynamic>;
        setState(() {
          _movementData = MovementData(
            volumeAmbiant: (data['volume_ambiant'] as num?)?.toDouble() ?? 0.0,
            temperatureC:
                (data['temperature_ambiante_c'] as num?)?.toDouble(),
            densiteA15: (data['densite_a_15'] as num?)?.toDouble(),
            volumeCorrige15c:
                (data['volume_corrige_15c'] as num?)?.toDouble(),
          );
          _isLoadingMovement = false;
        });
      } else {
        setState(() {
          _isLoadingMovement = false;
        });
        if (mounted) {
          showAppToast(
            context,
            'Mouvement introuvable',
            type: ToastType.error,
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoadingMovement = false;
      });
      if (mounted) {
        showAppToast(
          context,
          'Erreur lors du chargement des données du mouvement',
          type: ToastType.error,
        );
      }
    }
  }

  /// Parse un string en double (gère virgules et points)
  double? _parseDouble(String s) {
    if (s.trim().isEmpty) return null;
    return double.tryParse(
      s.replaceAll(RegExp(r'[^\d\-,\.]'), '').replaceAll(',', '.'),
    );
  }

  /// Calcule les deltas selon le type de correction
  ({double deltaAmbiant, double delta15c}) _calculateDeltas() {
    final movement = _movementData;
    if (movement == null) {
      return (deltaAmbiant: 0.0, delta15c: 0.0);
    }

    switch (_selectedType) {
      case AdjustmentType.volume:
        // Volume : correction ambiante obligatoire, recalcul 15°C
        final correctionAmbiante =
            _parseDouble(_correctionAmbianteController.text) ?? 0.0;
        final nouvelleTemp = movement.temperatureC ?? 15.0;
        final nouvelleDens = movement.densiteA15 ?? 0.8;
        final nouveauVolumeAmbiant = movement.volumeAmbiant + correctionAmbiante;
        final nouveauVolume15c = calcV15(
          volumeObserveL: nouveauVolumeAmbiant,
          temperatureC: nouvelleTemp,
          densiteA15: nouvelleDens,
        );
        final ancienVolume15c = movement.volumeCorrige15c ??
            calcV15(
              volumeObserveL: movement.volumeAmbiant,
              temperatureC: nouvelleTemp,
              densiteA15: nouvelleDens,
            );
        return (
          deltaAmbiant: correctionAmbiante,
          delta15c: nouveauVolume15c - ancienVolume15c,
        );

      case AdjustmentType.temperature:
        // Température : nouvelle température obligatoire, recalcul 15°C
        final nouvelleTemp =
            _parseDouble(_nouvelleTemperatureController.text);
        if (nouvelleTemp == null || nouvelleTemp <= 0) {
          return (deltaAmbiant: 0.0, delta15c: 0.0);
        }
        final nouvelleDens = movement.densiteA15 ?? 0.8;
        final nouveauVolume15c = calcV15(
          volumeObserveL: movement.volumeAmbiant,
          temperatureC: nouvelleTemp,
          densiteA15: nouvelleDens,
        );
        final ancienVolume15c = movement.volumeCorrige15c ??
            calcV15(
              volumeObserveL: movement.volumeAmbiant,
              temperatureC: movement.temperatureC ?? 15.0,
              densiteA15: nouvelleDens,
            );
        return (
          deltaAmbiant: 0.0,
          delta15c: nouveauVolume15c - ancienVolume15c,
        );

      case AdjustmentType.densite:
        // Densité : nouvelle densité obligatoire, recalcul 15°C
        final nouvelleDens = _parseDouble(_nouvelleDensiteController.text);
        if (nouvelleDens == null || nouvelleDens <= 0) {
          return (deltaAmbiant: 0.0, delta15c: 0.0);
        }
        final nouvelleTemp = movement.temperatureC ?? 15.0;
        final nouveauVolume15c = calcV15(
          volumeObserveL: movement.volumeAmbiant,
          temperatureC: nouvelleTemp,
          densiteA15: nouvelleDens,
        );
        final ancienVolume15c = movement.volumeCorrige15c ??
            calcV15(
              volumeObserveL: movement.volumeAmbiant,
              temperatureC: nouvelleTemp,
              densiteA15: movement.densiteA15 ?? 0.8,
            );
        return (
          deltaAmbiant: 0.0,
          delta15c: nouveauVolume15c - ancienVolume15c,
        );

      case AdjustmentType.mixte:
        // Mixte : correction ambiante + nouvelle température + nouvelle densité
        final correctionAmbiante =
            _parseDouble(_correctionAmbianteController.text) ?? 0.0;
        final nouvelleTemp =
            _parseDouble(_nouvelleTemperatureController.text);
        final nouvelleDens = _parseDouble(_nouvelleDensiteController.text);
        if (nouvelleTemp == null ||
            nouvelleTemp <= 0 ||
            nouvelleDens == null ||
            nouvelleDens <= 0) {
          return (deltaAmbiant: 0.0, delta15c: 0.0);
        }
        final nouveauVolumeAmbiant = movement.volumeAmbiant + correctionAmbiante;
        final nouveauVolume15c = calcV15(
          volumeObserveL: nouveauVolumeAmbiant,
          temperatureC: nouvelleTemp,
          densiteA15: nouvelleDens,
        );
        final ancienVolume15c = movement.volumeCorrige15c ??
            calcV15(
              volumeObserveL: movement.volumeAmbiant,
              temperatureC: movement.temperatureC ?? 15.0,
              densiteA15: movement.densiteA15 ?? 0.8,
            );
        return (
          deltaAmbiant: correctionAmbiante,
          delta15c: nouveauVolume15c - ancienVolume15c,
        );
    }
  }

  /// Soumet le formulaire
  Future<void> _submitForm() async {
    // Protection double-submit
    if (_isLoading) return;

    // Validation du formulaire
    if (!(_formKey.currentState?.validate() ?? false)) {
      showAppToast(
        context,
        'Veuillez corriger les erreurs dans le formulaire.',
        type: ToastType.error,
      );
      return;
    }

    // Calculer les deltas
    final deltas = _calculateDeltas();

    // Validation : impact non nul
    if (deltas.deltaAmbiant == 0.0 && deltas.delta15c == 0.0) {
      showAppToast(
        context,
        'L\'ajustement n\'a aucun impact. Vérifiez vos valeurs.',
        type: ToastType.error,
      );
      return;
    }

    // Préfixer la raison
    final reason = '${_selectedType.prefix} ${_reasonController.text.trim()}';

    setState(() => _isLoading = true);

    try {
      final service = ref.read(stocksAdjustmentsServiceProvider);
      await service.createAdjustment(
        mouvementType: widget.mouvementType,
        mouvementId: widget.mouvementId,
        deltaAmbiant: deltas.deltaAmbiant,
        delta15c: deltas.delta15c,
        reason: reason,
      );

      if (!mounted) return;

      // Fermer le BottomSheet
      Navigator.pop(context);

      // Afficher toast succès
      showAppToast(
        context,
        'Ajustement créé avec succès',
        type: ToastType.success,
      );

      // Appeler callback si fourni
      widget.onSuccess?.call();
    } on StocksAdjustmentsException catch (e) {
      if (!mounted) return;
      showAppToast(
        context,
        e.message,
        type: ToastType.error,
        duration: const Duration(seconds: 5),
      );
    } catch (e) {
      if (!mounted) return;
      showAppToast(
        context,
        'Erreur lors de la création de l\'ajustement.',
        type: ToastType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Tronque un ID pour affichage
  String _truncateId(String id) {
    if (id.length <= 12) return id;
    return '${id.substring(0, 8)}...';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Titre
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Créer un ajustement de stock',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    tooltip: 'Fermer',
                  ),
                ],
              ),
            ),
            // Formulaire
            Flexible(
              child: _isLoadingMovement
                  ? const Center(child: CircularProgressIndicator())
                  : _movementData == null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 48,
                                  color: theme.colorScheme.error,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Impossible de charger les données du mouvement',
                                  style: theme.textTheme.titleMedium,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                FilledButton.icon(
                                  onPressed: _loadMovementData,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Réessayer'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Mouvement Type (read-only)
                                TextFormField(
                                  initialValue: widget.mouvementType,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    labelText: 'Type de mouvement',
                                    border: const OutlineInputBorder(),
                                    filled: true,
                                    fillColor: theme
                                        .colorScheme.surfaceContainerHighest,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Mouvement ID (read-only)
                                TextFormField(
                                  initialValue: _truncateId(widget.mouvementId),
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    labelText: 'ID du mouvement',
                                    border: const OutlineInputBorder(),
                                    filled: true,
                                    fillColor: theme
                                        .colorScheme.surfaceContainerHighest,
                                    helperText:
                                        'ID complet: ${widget.mouvementId}',
                                  ),
                                ),
                                const SizedBox(height: 24),
                                // Sélecteur de type de correction
                                Text(
                                  'Type de correction *',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SegmentedButton<AdjustmentType>(
                                  segments: AdjustmentType.values
                                      .map((type) => ButtonSegment<AdjustmentType>(
                                            value: type,
                                            label: Text(type.label),
                                          ))
                                      .toList(),
                                  selected: {_selectedType},
                                  onSelectionChanged: (Set<AdjustmentType> newSelection) {
                                    setState(() {
                                      _selectedType = newSelection.first;
                                      // Réinitialiser les champs
                                      _correctionAmbianteController.clear();
                                      _nouvelleTemperatureController.clear();
                                      _nouvelleDensiteController.clear();
                                    });
                                  },
                                ),
                                const SizedBox(height: 24),
                                // Affichage dynamique selon le type
                                ..._buildDynamicFields(theme),
                                const SizedBox(height: 16),
                                // Raison
                                TextFormField(
                                  controller: _reasonController,
                                  decoration: InputDecoration(
                                    labelText: 'Raison *',
                                    helperText:
                                        'Minimum 10 caractères (sera préfixé automatiquement)',
                                    border: const OutlineInputBorder(),
                                  ),
                                  maxLines: 4,
                                  textInputAction: TextInputAction.newline,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'La raison est obligatoire';
                                    }
                                    if (value.trim().length < 10) {
                                      return 'La raison doit contenir au moins 10 caractères';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),
                                // Aperçu des impacts calculés
                                if (_shouldShowPreview())
                                  _buildPreviewCard(theme),
                                const SizedBox(height: 24),
                                // Bouton Enregistrer
                                FilledButton.icon(
                                  onPressed: _isLoading ? null : _submitForm,
                                  icon: _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.check),
                                  label: Text(
                                      _isLoading ? 'Enregistrement...' : 'Enregistrer'),
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit les champs dynamiques selon le type
  List<Widget> _buildDynamicFields(ThemeData theme) {
    final movement = _movementData!;
    final fields = <Widget>[];

    switch (_selectedType) {
      case AdjustmentType.volume:
        // Volume : correction ambiante obligatoire
        fields.addAll([
          TextFormField(
            controller: _correctionAmbianteController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            decoration: InputDecoration(
              labelText: 'Correction ambiante (L) *',
              helperText: 'Valeur positive ou négative, différente de 0',
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'La correction ambiante est obligatoire';
              }
              final parsed = _parseDouble(value);
              if (parsed == null) {
                return 'Valeur numérique invalide';
              }
              if (parsed == 0) {
                return 'La correction ambiante doit être différente de 0';
              }
              return null;
            },
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          // Température (lecture seule)
          TextFormField(
            initialValue: movement.temperatureC?.toStringAsFixed(2) ?? 'N/A',
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Température actuelle (°C)',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 16),
          // Densité (lecture seule)
          TextFormField(
            initialValue: movement.densiteA15?.toStringAsFixed(4) ?? 'N/A',
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Densité actuelle @15°C',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
        ]);
        break;

      case AdjustmentType.temperature:
        // Température : nouvelle température obligatoire
        fields.addAll([
          TextFormField(
            controller: _nouvelleTemperatureController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: InputDecoration(
              labelText: 'Nouvelle température (°C) *',
              helperText:
                  'Valeur > 0 (actuelle: ${movement.temperatureC?.toStringAsFixed(2) ?? 'N/A'})',
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'La nouvelle température est obligatoire';
              }
              final parsed = _parseDouble(value);
              if (parsed == null) {
                return 'Valeur numérique invalide';
              }
              if (parsed <= 0) {
                return 'La température doit être supérieure à 0';
              }
              return null;
            },
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          // Volume (lecture seule)
          TextFormField(
            initialValue: movement.volumeAmbiant.toStringAsFixed(2),
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Volume ambiant actuel (L)',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 16),
          // Densité (lecture seule)
          TextFormField(
            initialValue: movement.densiteA15?.toStringAsFixed(4) ?? 'N/A',
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Densité actuelle @15°C',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
        ]);
        break;

      case AdjustmentType.densite:
        // Densité : nouvelle densité obligatoire
        fields.addAll([
          TextFormField(
            controller: _nouvelleDensiteController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: InputDecoration(
              labelText: 'Nouvelle densité @15°C *',
              helperText:
                  'Valeur entre 0.7 et 1.1 (actuelle: ${movement.densiteA15?.toStringAsFixed(4) ?? 'N/A'})',
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'La nouvelle densité est obligatoire';
              }
              final parsed = _parseDouble(value);
              if (parsed == null) {
                return 'Valeur numérique invalide';
              }
              if (parsed <= 0) {
                return 'La densité doit être supérieure à 0';
              }
              if (parsed < 0.7 || parsed > 1.1) {
                return 'La densité doit être entre 0.7 et 1.1';
              }
              return null;
            },
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          // Volume (lecture seule)
          TextFormField(
            initialValue: movement.volumeAmbiant.toStringAsFixed(2),
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Volume ambiant actuel (L)',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 16),
          // Température (lecture seule)
          TextFormField(
            initialValue: movement.temperatureC?.toStringAsFixed(2) ?? 'N/A',
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Température actuelle (°C)',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
        ]);
        break;

      case AdjustmentType.mixte:
        // Mixte : tous les champs obligatoires
        fields.addAll([
          TextFormField(
            controller: _correctionAmbianteController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            decoration: InputDecoration(
              labelText: 'Correction ambiante (L) *',
              helperText: 'Valeur positive ou négative, différente de 0',
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'La correction ambiante est obligatoire';
              }
              final parsed = _parseDouble(value);
              if (parsed == null) {
                return 'Valeur numérique invalide';
              }
              if (parsed == 0) {
                return 'La correction ambiante doit être différente de 0';
              }
              return null;
            },
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nouvelleTemperatureController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: InputDecoration(
              labelText: 'Nouvelle température (°C) *',
              helperText:
                  'Valeur > 0 (actuelle: ${movement.temperatureC?.toStringAsFixed(2) ?? 'N/A'})',
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'La nouvelle température est obligatoire';
              }
              final parsed = _parseDouble(value);
              if (parsed == null) {
                return 'Valeur numérique invalide';
              }
              if (parsed <= 0) {
                return 'La température doit être supérieure à 0';
              }
              return null;
            },
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nouvelleDensiteController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: InputDecoration(
              labelText: 'Nouvelle densité @15°C *',
              helperText:
                  'Valeur entre 0.7 et 1.1 (actuelle: ${movement.densiteA15?.toStringAsFixed(4) ?? 'N/A'})',
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'La nouvelle densité est obligatoire';
              }
              final parsed = _parseDouble(value);
              if (parsed == null) {
                return 'Valeur numérique invalide';
              }
              if (parsed <= 0) {
                return 'La densité doit être supérieure à 0';
              }
              if (parsed < 0.7 || parsed > 1.1) {
                return 'La densité doit être entre 0.7 et 1.1';
              }
              return null;
            },
            onChanged: (_) => setState(() {}),
          ),
        ]);
        break;
    }

    return fields;
  }

  /// Détermine si l'aperçu doit être affiché
  bool _shouldShowPreview() {
    if (_movementData == null) return false;

    switch (_selectedType) {
      case AdjustmentType.volume:
        return _correctionAmbianteController.text.trim().isNotEmpty;
      case AdjustmentType.temperature:
        return _nouvelleTemperatureController.text.trim().isNotEmpty;
      case AdjustmentType.densite:
        return _nouvelleDensiteController.text.trim().isNotEmpty;
      case AdjustmentType.mixte:
        return _correctionAmbianteController.text.trim().isNotEmpty &&
            _nouvelleTemperatureController.text.trim().isNotEmpty &&
            _nouvelleDensiteController.text.trim().isNotEmpty;
    }
  }

  /// Construit la carte d'aperçu des impacts
  Widget _buildPreviewCard(ThemeData theme) {
    final deltas = _calculateDeltas();
    final hasImpact = deltas.deltaAmbiant != 0.0 || deltas.delta15c != 0.0;

    return Card(
      color: hasImpact
          ? theme.colorScheme.surfaceContainerHighest
          : theme.colorScheme.errorContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aperçu des impacts',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delta ambiant',
                        style: theme.textTheme.labelSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${deltas.deltaAmbiant.toStringAsFixed(2)} L',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: deltas.deltaAmbiant == 0.0
                              ? theme.colorScheme.error
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delta 15°C',
                        style: theme.textTheme.labelSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${deltas.delta15c.toStringAsFixed(2)} L',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: deltas.delta15c == 0.0
                              ? theme.colorScheme.error
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (!hasImpact) ...[
              const SizedBox(height: 8),
              Text(
                '⚠️ Aucun impact détecté. Vérifiez vos valeurs.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
