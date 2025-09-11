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

enum OwnerType { monaluxe, partenaire }
enum BenefType { client, partenaire }

// Fonctions de formatage
String fmtNum(num? v) => v == null ? '0.0' : v.toDouble().toStringAsFixed(1);
String fmtDate(DateTime? d) => d == null ? '' : '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

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
    final k = 1 - ( (_tempC - 15.0).clamp(-30.0, 30.0) * 0.00065 );
    final v15 = amb * k;
    return v15.isFinite && v15 > 0 ? v15 : amb;
  }

  Future<void> _submit() async {
    if (_produitId == null || _citerneId == null) {
      _snack('Choisissez un produit et une citerne', err: true);
      return;
    }
    if (_owner == OwnerType.monaluxe && _clientId == null) {
      _snack('Sélectionnez un client', err: true); return;
    }
    if (_owner == OwnerType.partenaire && _partenaireId == null) {
      _snack('Sélectionnez un partenaire', err: true); return;
    }
    if (_indexAvant != null && _indexApres != null && _indexApres! <= _indexAvant!) {
      _snack('Index incohérents (après ≤ avant)', err: true); return;
    }

    setState(() => _submitting = true);
    try {
      final id = await ref.read(sortieServiceProvider).createValidated(
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

  void _snack(String m, {bool err=false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: err ? Colors.red : Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final produitsAsync = ref.watch(produitsListProvider); // comme réceptions
    final clientsAsync  = ref.watch(clientsListProvider);
    final partsAsync    = ref.watch(partenairesListProvider);
    final citernesAsync = _produitId == null
        ? const AsyncValue<List<CiterneWithStockForSortie>>.data([])
        : ref.watch(citernesByProduitWithStockProvider(_produitId!));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle Sortie'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: InputDatePickerFormField(
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              initialDate: _date,
              onDateSubmitted: (d) => setState(() => _date = d),
              onDateSaved: (d) => setState(() => _date = d),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- Propriété (chips) + Bénéficiaire
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Propriété', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, children: [
                    ChoiceChip(
                      label: const Text('MONALUXE'),
                      selected: _owner == OwnerType.monaluxe,
                      onSelected: (_) => setState(() {
                        _owner = OwnerType.monaluxe;
                        _benefType = BenefType.client;
                        _partenaireId = null;
                      }),
                    ),
                    ChoiceChip(
                      label: const Text('PARTENAIRE'),
                      selected: _owner == OwnerType.partenaire,
                      onSelected: (_) => setState(() {
                        _owner = OwnerType.partenaire;
                        _benefType = BenefType.partenaire;
                        _clientId = null;
                      }),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  const Text('Bénéficiaire', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (_owner == OwnerType.monaluxe) ...[
                    const Text('Client'),
                    clientsAsync.when(
                      data: (list) => DropdownButton<String>(
                        isExpanded: true,
                        value: _clientId,
                        hint: const Text('Sélectionner un client'),
                        items: list.map<DropdownMenuItem<String>>((c) =>
                          DropdownMenuItem(value: c['id'] as String, child: Text(c['nom'] as String))
                        ).toList(),
                        onChanged: (v) => setState(() => _clientId = v),
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text('Erreur clients: $e', style: const TextStyle(color: Colors.red)),
                    ),
                  ] else ...[
                    const Text('Partenaire'),
                    partsAsync.when(
                      data: (list) => DropdownButton<String>(
                        isExpanded: true,
                        value: _partenaireId,
                        hint: const Text('Sélectionner un partenaire'),
                        items: list.map<DropdownMenuItem<String>>((p) =>
                          DropdownMenuItem(value: p['id'] as String, child: Text(p['nom'] as String))
                        ).toList(),
                        onChanged: (v) => setState(() => _partenaireId = v),
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text('Erreur partenaires: $e', style: const TextStyle(color: Colors.red)),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // --- Produit & Citerne (miroir réceptions)
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Produit & Citerne', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  produitsAsync.when(
                    data: (list) {
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: list.map<Widget>((p) {
                          final id = p['id'] as String;
                          final label = '${p['code'] ?? ''} ${p['nom'] ?? ''}'.trim();
                          final sel = _produitId == id;
                          return ChoiceChip(
                            label: Text(label),
                            selected: sel,
                            onSelected: (_) => setState(() {
                              _produitId = id;
                              _citerneId = null;
                            }),
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('Erreur produits: $e', style: const TextStyle(color: Colors.red)),
                  ),
                  const SizedBox(height: 12),
                  const Text('Citerne *'),
                  const SizedBox(height: 8),
                  citernesAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, st) => Text('Erreur chargement citernes: $e'),
                    data: (citernes) {
                      if (citernes.isEmpty) {
                        return const Text('Aucune citerne pour ce produit');
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...citernes.map((c) {
                            final amb = fmtNum(c.stockAmbiant);
                            final s15 = fmtNum(c.stock15c);
                            final d   = fmtDate(c.date);
                            return RadioListTile<String>(
                              value: c.id,
                              groupValue: _citerneId,
                              onChanged: (v) => setState(() => _citerneId = v),
                              title: Text(c.nom),
                              subtitle: Text('Stock: $amb L • $s15 L (15°C)${d.isEmpty ? "" : " — au $d"}'),
                              dense: true,
                            );
                          }),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // --- Mesures & Calculs (miroir réceptions)
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Mesures & Calculs', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  Row(children: [
                    Expanded(
                      child: _numField(
                        label: 'Index avant *',
                        initial: _indexAvant?.toString(),
                        onChanged: (v) => setState(() => _indexAvant = double.tryParse(v)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _numField(
                        label: 'Index après *',
                        initial: _indexApres?.toString(),
                        onChanged: (v) => setState(() => _indexApres = double.tryParse(v)),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 8),

                  Row(children: [
                    Expanded(
                      child: _numField(
                        label: 'Température (°C)',
                        initial: _tempC.toString(),
                        onChanged: (v) => setState(() => _tempC = double.tryParse(v) ?? 15),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _numField(
                        label: 'Densité @15°C',
                        initial: _densA15.toString(),
                        onChanged: (v) => setState(() => _densA15 = double.tryParse(v) ?? 0.83),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Text('• Volume ambiant = ${_volAmbiant.toStringAsFixed(2)} L'),
                  Text('• Volume corrigé 15°C ≈ ${_vol15C.toStringAsFixed(2)} L'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // --- CTA
          SafeArea(
            top: false,
            child: ElevatedButton.icon(
              onPressed: _canSubmit ? _submit : null,
              icon: const Icon(Icons.save),
              label: const Text('Enregistrer la sortie'),
            ),
          ),
        ],
      ),
    );
  }

  bool get _canSubmit {
    final hasBenef = _owner == OwnerType.monaluxe ? _clientId != null : _partenaireId != null;
    final hasProdCit = _produitId != null && _citerneId != null;
    final idxOk = _indexAvant == null || _indexApres == null || _indexApres! > _indexAvant!;
    return !_submitting && hasBenef && hasProdCit && idxOk;
  }

  Widget _numField({required String label, String? initial, required ValueChanged<String> onChanged}) {
    return TextFormField(
      initialValue: initial,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      onChanged: onChanged,
    );
  }
}