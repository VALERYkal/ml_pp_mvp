// 📌 Module : Finance fournisseur lot — Création facture (C1)
// 🧭 Insert `fournisseur_facture_lot_min` uniquement ; lecture post-insert via vue.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/features/lots/models/fournisseur_lot.dart';
import 'package:ml_pp_mvp/features/lots_finance/models/fournisseur_finance_lot_models.dart';
import 'package:ml_pp_mvp/features/lots_finance/providers/fournisseur_finance_lot_providers.dart';
import 'package:ml_pp_mvp/shared/ui/format.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

String _messageErreurCreationFacture(PostgrestException e) {
  final code = e.code?.toString().trim();
  if (code == '23505') {
    final blob =
        '${e.message} ${e.details ?? ''} ${e.hint ?? ''}'.toLowerCase();
    if (blob.contains('fournisseur_lot_id') ||
        blob.contains('one_facture_per_lot') ||
        blob.contains('idx_fournisseur_facture_lot_min_one_facture_per_lot')) {
      return 'Ce lot a déjà une facture fournisseur.';
    }
  }
  if (e.message.trim().isNotEmpty) return e.message.trim();
  return 'Erreur lors de la création de la facture.';
}

/// Bottom sheet : création d’une facture fournisseur lot (payload minimal DB).
class FournisseurFactureLotFormSheet extends ConsumerStatefulWidget {
  const FournisseurFactureLotFormSheet({super.key});

  @override
  ConsumerState<FournisseurFactureLotFormSheet> createState() =>
      _FournisseurFactureLotFormSheetState();
}

class _FournisseurFactureLotFormSheetState
    extends ConsumerState<FournisseurFactureLotFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _invoiceController = TextEditingController();
  final _dealRefController = TextEditingController();
  final _quantiteController = TextEditingController();
  final _prixController = TextEditingController();

  DateTime _dateFacture = DateTime.now();
  DateTime? _dateEcheance;
  String? _selectedLotId;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _invoiceController.dispose();
    _dealRefController.dispose();
    _quantiteController.dispose();
    _prixController.dispose();
    super.dispose();
  }

  Future<void> _pickDateFacture() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateFacture,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _dateFacture = picked);
    }
  }

  Future<void> _pickDateEcheance() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateEcheance ?? _dateFacture,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _dateEcheance = picked);
    }
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final lotId = _selectedLotId?.trim();
    if (lotId == null || lotId.isEmpty) {
      setState(() => _errorMessage = 'Veuillez sélectionner un lot fournisseur.');
      return;
    }

    final qty = double.tryParse(_quantiteController.text.trim());
    if (qty == null || qty <= 0) {
      setState(() => _errorMessage = 'La quantité facturée doit être supérieure à 0.');
      return;
    }

    final prix = double.tryParse(_prixController.text.trim());
    if (prix == null || prix <= 0) {
      setState(() => _errorMessage = 'Le prix unitaire doit être supérieur à 0.');
      return;
    }

    final dealTrim = _dealRefController.text.trim();
    final input = CreateFournisseurFactureLotInput(
      fournisseurLotId: lotId,
      invoiceNo: _invoiceController.text.trim(),
      dealReference: dealTrim.isEmpty ? null : dealTrim,
      dateFacture: DateTime(_dateFacture.year, _dateFacture.month, _dateFacture.day),
      dateEcheance: _dateEcheance == null
          ? null
          : DateTime(
              _dateEcheance!.year,
              _dateEcheance!.month,
              _dateEcheance!.day,
            ),
      quantiteFacturee20c: qty,
      prixUnitaireUsd: prix,
    );

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ref.read(createFournisseurFactureLotProvider(input).future);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(true);
    } on PostgrestException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _messageErreurCreationFacture(e);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Erreur lors de la création de la facture.';
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lotsAsync = ref.watch(fournisseurLotsFacturablesProvider);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: lotsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => Text(
            'Impossible de charger les lots : $e',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          data: (lots) {
            if (lots.isEmpty) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Nouvelle facture lot',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Aucun lot disponible pour facturation.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tous les lots ont déjà une facture, ou aucun lot n’existe encore.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Fermer'),
                  ),
                ],
              );
            }

            return SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Nouvelle facture lot',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedLotId,
                      decoration: const InputDecoration(
                        labelText: 'Lot fournisseur *',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: lots
                          .map(
                            (l) => DropdownMenuItem<String>(
                              value: l.id,
                              child: Text(
                                '${l.reference} · ${l.fournisseurNom ?? '—'} · ${l.statut.label}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedLotId = v),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Lot obligatoire';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _invoiceController,
                      decoration: const InputDecoration(
                        labelText: 'Numéro de facture *',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      textCapitalization: TextCapitalization.characters,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Numéro de facture obligatoire';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _dealRefController,
                      decoration: const InputDecoration(
                        labelText: 'Deal / référence (optionnel)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Date facture *'),
                      subtitle: Text(fmtDate(_dateFacture)),
                      trailing: IconButton(
                        icon: const Icon(Icons.calendar_today_outlined),
                        onPressed: _pickDateFacture,
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Date d’échéance (optionnel)'),
                      subtitle: Text(fmtDate(_dateEcheance)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_dateEcheance != null)
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => setState(() => _dateEcheance = null),
                            ),
                          IconButton(
                            icon: const Icon(Icons.calendar_today_outlined),
                            onPressed: _pickDateEcheance,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _quantiteController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Quantité facturée 20 °C (L) *',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (value) {
                        final parsed = double.tryParse((value ?? '').trim());
                        if (parsed == null || parsed <= 0) {
                          return 'Quantité > 0 requise';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _prixController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Prix unitaire USD *',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (value) {
                        final parsed = double.tryParse((value ?? '').trim());
                        if (parsed == null || parsed <= 0) {
                          return 'Prix > 0 requis';
                        }
                        return null;
                      },
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: _isSubmitting ? null : _submit,
                      icon: _isSubmitting
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add_chart_outlined),
                      label: Text(
                        _isSubmitting ? 'Création...' : 'Créer la facture',
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
