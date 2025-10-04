import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:postgrest/postgrest.dart';

import 'package:ml_pp_mvp/features/sorties/data/sortie_service.dart';
import 'package:ml_pp_mvp/features/sorties/providers/sortie_providers.dart';
import 'package:ml_pp_mvp/shared/providers/ref_data_provider.dart';
import 'package:ml_pp_mvp/features/citernes/providers/citerne_providers.dart';
import 'package:ml_pp_mvp/features/stocks_journaliers/providers/stocks_providers.dart';
import 'package:ml_pp_mvp/shared/utils/error_humanizer.dart';
import '../models/citerne_with_stock.dart';
import '../widgets/sortie_form_section.dart';
import '../widgets/modern_choice_chip.dart';
import '../widgets/modern_text_field.dart';
import '../widgets/volume_calculation_card.dart';
import '../widgets/citerne_selection_card.dart';
import 'package:ml_pp_mvp/shared/ui/ui_keys.dart';

enum OwnerType { monaluxe, partenaire }

enum BenefType { client, partenaire }

// Fonctions de formatage
String fmtNum(num? v) => v == null ? '0.0' : v.toDouble().toStringAsFixed(1);
String fmtDate(DateTime? d) => d == null
    ? ''
    : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class SortieFormScreen extends ConsumerStatefulWidget {
  const SortieFormScreen({super.key});
  @override
  ConsumerState<SortieFormScreen> createState() => _SortieFormScreenState();
}

class _SortieFormScreenState extends ConsumerState<SortieFormScreen> {
  OwnerType _owner = OwnerType.monaluxe;
  BenefType _benefType = BenefType.client;

  String? _produitId;
  String? _citerneId;

  String? _clientId;
  String? _partenaireId;

  double? _indexAvant;
  double? _indexApres;
  double _tempC = 15;
  double _densA15 = 0.83;

  String? _note;

  bool _submitting = false;
  DateTime _date = DateTime.now();

  // --- helpers calculs (mêmes principes que réceptions)
  double get _volAmbiant {
    if (_indexAvant == null || _indexApres == null) return 0.0;
    if (_indexApres! <= _indexAvant!) return 0.0;
    return _indexApres! - _indexAvant!;
  }

  // MVP : approximation simple similaire aux réceptions (fallback sur ambiant)
  double get _vol15C {
    final amb = _volAmbiant;
    if (amb == 0) return 0;
    // ajustement très simple (placeholder) : densité proche 0.83 et T ambiante.
    final k = 1 - ((_tempC - 15.0).clamp(-30.0, 30.0) * 0.00065);
    final v15 = amb * k;
    return v15.isFinite && v15 > 0 ? v15 : amb;
  }

  Future<void> _submit() async {
    if (_produitId == null || _citerneId == null) {
      _snack('Choisissez un produit et une citerne', err: true);
      return;
    }
    if (_owner == OwnerType.monaluxe && _clientId == null) {
      _snack('Sélectionnez un client', err: true);
      return;
    }
    if (_owner == OwnerType.partenaire && _partenaireId == null) {
      _snack('Sélectionnez un partenaire', err: true);
      return;
    }
    if (_indexAvant != null && _indexApres != null && _indexApres! <= _indexAvant!) {
      _snack('Index incohérents (après ≤ avant)', err: true);
      return;
    }

    setState(() => _submitting = true);
    try {
      final id = await ref
          .read(sortieServiceProvider)
          .createValidated(
            citerneId: _citerneId!,
            produitId: _produitId!,
            indexAvant: _indexAvant,
            indexApres: _indexApres,
            temperatureCAmb: _tempC,
            densiteA15: _densA15,
            volumeCorrige15C: _vol15C, // DB fallback sinon
            proprietaireType: _owner == OwnerType.monaluxe ? 'MONALUXE' : 'PARTENAIRE',
            clientId: _owner == OwnerType.monaluxe ? _clientId : null,
            partenaireId: _owner == OwnerType.partenaire ? _partenaireId : null,
            dateSortie: _date,
            note: _note?.isNotEmpty == true ? _note : null,
          );

      // invalidate listes si providers existent
      try {
        ref.invalidate(sortiesListProvider);
        ref.invalidate(stocksListProvider);
      } catch (_) {}

      _snack('Sortie enregistrée (#${id.substring(0, 6)})');
      if (mounted) context.pop();
    } on PostgrestException catch (e) {
      _snack(ErrorHumanizer.humanizePostgrest(e), err: true);
    } catch (e) {
      _snack(ErrorHumanizer.humanizeError(e), err: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String m, {bool err = false}) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(m), backgroundColor: err ? Colors.red : Colors.green));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final produitsAsync = ref.watch(produitsListProvider);
    final clientsAsync = ref.watch(clientsListProvider);
    final partsAsync = ref.watch(partenairesListProvider);
    final citernesAsync = _produitId == null
        ? const AsyncValue<List<CiterneWithStockForSortie>>.data([])
        : ref.watch(citernesByProduitWithStockProvider(_produitId!));

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Nouvelle Sortie'),
        backgroundColor: Colors.white,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: OutlinedButton.icon(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _date = date);
                }
              },
              icon: const Icon(Icons.calendar_today, size: 18),
              label: Text(_formatDate(_date)),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.primary,
                side: BorderSide(color: colorScheme.primary.withOpacity(0.3)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, colorScheme.surface.withOpacity(0.5)],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Section Propriété et Bénéficiaire
            SortieFormSection(
              key: UiKeys.sortieSectionBeneficiaire,
              title: 'Propriété et Bénéficiaire',
              subtitle: 'Sélectionnez le type de propriété et le bénéficiaire',
              icon: Icons.account_balance,
              iconColor: colorScheme.primary,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    ModernChoiceChip(
                      label: 'MONALUXE',
                      selected: _owner == OwnerType.monaluxe,
                      icon: Icons.business,
                      onSelected: () => setState(() {
                        _owner = OwnerType.monaluxe;
                        _benefType = BenefType.client;
                        _partenaireId = null;
                      }),
                    ),
                    ModernChoiceChip(
                      label: 'PARTENAIRE',
                      selected: _owner == OwnerType.partenaire,
                      icon: Icons.handshake,
                      onSelected: () => setState(() {
                        _owner = OwnerType.partenaire;
                        _benefType = BenefType.partenaire;
                        _clientId = null;
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Sélection du bénéficiaire
                if (_owner == OwnerType.monaluxe) ...[
                  ModernTextField(
                    label: 'Client',
                    initialValue: _clientId,
                    hint: 'Sélectionner un client',
                    prefixIcon: const Icon(Icons.person),
                    suffixIcon: clientsAsync.when(
                      data: (list) => DropdownButton<String>(
                        value: _clientId,
                        underline: const SizedBox(),
                        items: list
                            .map<DropdownMenuItem<String>>(
                              (c) => DropdownMenuItem(
                                value: c['id'] as String,
                                child: Text(c['nom'] as String),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _clientId = v),
                      ),
                      loading: () => const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      error: (e, _) => Icon(Icons.error, color: colorScheme.error, size: 20),
                    ),
                    onChanged: (value) {
                      // Géré par le dropdown
                    },
                  ),
                ] else ...[
                  ModernTextField(
                    label: 'Partenaire',
                    initialValue: _partenaireId,
                    hint: 'Sélectionner un partenaire',
                    prefixIcon: const Icon(Icons.handshake),
                    suffixIcon: partsAsync.when(
                      data: (list) => DropdownButton<String>(
                        value: _partenaireId,
                        underline: const SizedBox(),
                        items: list
                            .map<DropdownMenuItem<String>>(
                              (p) => DropdownMenuItem(
                                value: p['id'] as String,
                                child: Text(p['nom'] as String),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _partenaireId = v),
                      ),
                      loading: () => const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      error: (e, _) => Icon(Icons.error, color: colorScheme.error, size: 20),
                    ),
                    onChanged: (value) {
                      // Géré par le dropdown
                    },
                  ),
                ],
              ],
            ),

            // Section Produit et Citerne
            SortieFormSection(
              key: UiKeys.sortieSectionProduit,
              title: 'Produit et Citerne',
              subtitle: 'Choisissez le produit et la citerne de sortie',
              icon: Icons.inventory,
              iconColor: colorScheme.secondary,
              children: [
                // Sélection du produit
                Text(
                  'Produit',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                produitsAsync.when(
                  data: (list) => Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: list.map<Widget>((p) {
                      final id = p['id'] as String;
                      final label = '${p['code'] ?? ''} ${p['nom'] ?? ''}'.trim();
                      final sel = _produitId == id;
                      return ModernChoiceChip(
                        label: label,
                        selected: sel,
                        icon: Icons.local_gas_station,
                        onSelected: () => setState(() {
                          _produitId = id;
                          _citerneId = null;
                        }),
                      );
                    }).toList(),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colorScheme.error.withOpacity(0.3)),
                    ),
                    child: Text(
                      'Erreur chargement produits: $e',
                      style: TextStyle(color: colorScheme.error),
                    ),
                  ),
                ),

                if (_produitId != null) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Citerne *',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  citernesAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (e, st) => Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colorScheme.error.withOpacity(0.3)),
                      ),
                      child: Text(
                        'Erreur chargement citernes: $e',
                        style: TextStyle(color: colorScheme.error),
                      ),
                    ),
                    data: (citernes) {
                      if (citernes.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceVariant.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Aucune citerne disponible pour ce produit',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: citernes
                            .map(
                              (c) => CiterneSelectionCard(
                                citerne: c,
                                selected: _citerneId == c.id,
                                onTap: () => setState(() => _citerneId = c.id),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                ],
              ],
            ),

            // Section Mesures et Calculs
            SortieFormSection(
              key: UiKeys.sortieSectionQuantites,
              title: 'Mesures et Calculs',
              subtitle: 'Saisissez les indices et paramètres de calcul',
              icon: Icons.calculate,
              iconColor: colorScheme.tertiary,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ModernTextField(
                        label: 'Index avant *',
                        initialValue: _indexAvant?.toString(),
                        hint: '0.0',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        prefixIcon: const Icon(Icons.trending_down),
                        onChanged: (v) => setState(() => _indexAvant = double.tryParse(v)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ModernTextField(
                        label: 'Index après *',
                        initialValue: _indexApres?.toString(),
                        hint: '0.0',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        prefixIcon: const Icon(Icons.trending_up),
                        onChanged: (v) => setState(() => _indexApres = double.tryParse(v)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ModernTextField(
                        label: 'Température (°C)',
                        initialValue: _tempC.toString(),
                        hint: '15.0',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        prefixIcon: const Icon(Icons.thermostat),
                        onChanged: (v) => setState(() => _tempC = double.tryParse(v) ?? 15),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ModernTextField(
                        label: 'Densité @15°C',
                        initialValue: _densA15.toString(),
                        hint: '0.830',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        prefixIcon: const Icon(Icons.scale),
                        onChanged: (v) => setState(() => _densA15 = double.tryParse(v) ?? 0.83),
                      ),
                    ),
                  ],
                ),

                if (_indexAvant != null && _indexApres != null) ...[
                  const SizedBox(height: 16),
                  VolumeCalculationCard(
                    volumeAmbiant: _volAmbiant,
                    volume15C: _vol15C,
                    temperature: _tempC,
                    densite: _densA15,
                  ),
                ],
              ],
            ),

            // Section Note/Commentaire
            SortieFormSection(
              key: UiKeys.sortieSectionNote,
              title: 'Note/Commentaire',
              subtitle: 'Ajoutez une note ou un commentaire optionnel',
              icon: Icons.note_alt,
              iconColor: colorScheme.tertiary,
              children: [
                ModernTextField(
                  label: 'Note',
                  hint: 'Saisissez un commentaire ou une note...',
                  initialValue: _note,
                  prefixIcon: const Icon(Icons.edit_note),
                  maxLines: 3,
                  onChanged: (value) => setState(() => _note = value),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Bouton d'enregistrement
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: _canSubmit
                    ? LinearGradient(
                        colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.8)],
                      )
                    : null,
                color: _canSubmit ? null : colorScheme.surfaceVariant,
                boxShadow: _canSubmit
                    ? [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: ElevatedButton.icon(
                key: UiKeys.sortieSave,
                onPressed: _canSubmit ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: _canSubmit ? Colors.white : colorScheme.onSurfaceVariant,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: _submitting
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _canSubmit ? Colors.white : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : const Icon(Icons.save_alt),
                label: Text(
                  _submitting ? 'Enregistrement...' : 'Enregistrer la sortie',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  bool get _canSubmit {
    final hasBenef = _owner == OwnerType.monaluxe ? _clientId != null : _partenaireId != null;
    final hasProdCit = _produitId != null && _citerneId != null;
    final idxOk = _indexAvant == null || _indexApres == null || _indexApres! > _indexAvant!;
    return !_submitting && hasBenef && hasProdCit && idxOk;
  }
}
