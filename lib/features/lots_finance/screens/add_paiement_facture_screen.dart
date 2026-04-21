// 📌 Ajout paiement facture lot — insert `fournisseur_paiement_lot_min` uniquement.
// 🧭 Aucun recalcul solde / statut paiement : la vue `v_fournisseur_facture_lot` porte la lecture après invalidation.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/features/lots_finance/models/fournisseur_finance_lot_models.dart';
import 'package:ml_pp_mvp/features/lots_finance/providers/fournisseur_finance_lot_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _modesPaiement = <String>[
  'VIREMENT',
  'PRÉLÈVEMENT',
  'CHÈQUE',
  'CARTE',
  'AUTRE',
];

class AddPaiementFactureScreen extends ConsumerStatefulWidget {
  const AddPaiementFactureScreen({
    super.key,
    required this.factureId,
  });

  final String factureId;

  @override
  ConsumerState<AddPaiementFactureScreen> createState() =>
      _AddPaiementFactureScreenState();
}

class _AddPaiementFactureScreenState extends ConsumerState<AddPaiementFactureScreen> {
  final _formKey = GlobalKey<FormState>();
  final _montantController = TextEditingController();
  final _referenceController = TextEditingController();
  final _noteController = TextEditingController();

  DateTime _datePaiement = DateTime.now();
  String _modePaiement = _modesPaiement.first;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _montantController.dispose();
    _referenceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _datePaiement,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _datePaiement = picked);
    }
  }

  String _messageErreur(Object e) {
    final blob = e is PostgrestException
        ? '${e.message} ${e.details ?? ''} ${e.hint ?? ''}'.toLowerCase()
        : '$e'.toLowerCase();
    if (blob.contains('overpay')) {
      return 'Le paiement dépasse le solde restant';
    }
    return 'Erreur lors de l’enregistrement du paiement.';
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final montant = double.tryParse(_montantController.text.trim());
    if (montant == null || montant <= 0) {
      setState(() {
        _errorMessage = 'Le montant doit être supérieur à 0.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final dateOnly = DateTime(
        _datePaiement.year,
        _datePaiement.month,
        _datePaiement.day,
      );
      final input = CreateFournisseurPaiementLotInput(
        fournisseurFactureId: widget.factureId,
        datePaiement: dateOnly,
        montantPayeUsd: montant,
        modePaiement: _modePaiement.trim(),
        referencePaiement: _referenceController.text.trim(),
        note: _noteController.text.trim(),
      );

      await ref.read(createFournisseurPaiementLotProvider(input).future);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paiement enregistré')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _messageErreur(e);
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un paiement'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _montantController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Montant',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (value) {
                    final parsed = double.tryParse((value ?? '').trim());
                    if (parsed == null || parsed <= 0) {
                      return 'Montant invalide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'date_paiement',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_datePaiement.year}-${_datePaiement.month.toString().padLeft(2, '0')}-${_datePaiement.day.toString().padLeft(2, '0')}',
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: _isSubmitting ? null : _pickDate,
                        icon: const Icon(Icons.calendar_today_outlined, size: 20),
                        label: const Text('Choisir'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'mode_paiement',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _modePaiement,
                      items: _modesPaiement
                          .map(
                            (m) => DropdownMenuItem(value: m, child: Text(m)),
                          )
                          .toList(),
                      onChanged: _isSubmitting
                          ? null
                          : (v) {
                              if (v != null) {
                                setState(() => _modePaiement = v);
                              }
                            },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _referenceController,
                  decoration: const InputDecoration(
                    labelText: 'reference_paiement',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _noteController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'note',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_isSubmitting ? 'Enregistrement...' : 'Enregistrer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
