// 📌 Module : Cours de Route - Lots fournisseur
// 🧭 V1 : création d'un lot (manifeste) avant les CDR camion par camion

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ml_pp_mvp/features/lots/models/fournisseur_lot.dart';
import 'package:ml_pp_mvp/features/lots/lot_user_message_from_error.dart';
import 'package:ml_pp_mvp/features/lots/providers/fournisseur_lot_providers.dart';
import 'package:ml_pp_mvp/shared/providers/ref_data_provider.dart';
import 'package:ml_pp_mvp/shared/ui/toast.dart';
import 'package:ml_pp_mvp/shared/ui/dialogs.dart';

class FournisseurLotFormScreen extends ConsumerStatefulWidget {
  const FournisseurLotFormScreen({super.key});

  @override
  ConsumerState<FournisseurLotFormScreen> createState() =>
      _FournisseurLotFormScreenState();
}

class _FournisseurLotFormScreenState
    extends ConsumerState<FournisseurLotFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _referenceController = TextEditingController();
  final _noteController = TextEditingController();
  final _dateLotDisplayController = TextEditingController();

  String? selectedFournisseurId;
  String? selectedProduitId;
  DateTime? dateLot;
  bool isSaving = false;
  bool _dirty = false;

  String _formatDateLot(DateTime? d) {
    if (d == null) return '';
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    dateLot = DateTime.now();
    _dateLotDisplayController.text = _formatDateLot(dateLot);
  }

  @override
  void dispose() {
    _referenceController.dispose();
    _noteController.dispose();
    _dateLotDisplayController.dispose();
    super.dispose();
  }

  String? _emptyToNull(String? s) =>
      (s?.trim().isEmpty ?? true) ? null : s!.trim();

  Future<void> _submit() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) {
      if (mounted) {
        showAppToast(
          context,
          'Veuillez corriger les champs en rouge.',
          type: ToastType.error,
        );
      }
      return;
    }

    setState(() => isSaving = true);

    try {
      final lot = FournisseurLot(
        id: '',
        fournisseurId: selectedFournisseurId!,
        produitId: selectedProduitId!,
        reference: _referenceController.text.trim(),
        dateLot: dateLot,
        note: _emptyToNull(_noteController.text),
        statut: StatutFournisseurLot.ouvert,
      );

      final created = await ref.read(fournisseurLotServiceProvider).create(lot);

      ref.invalidate(fournisseurLotsProvider);

      if (!mounted) return;
      showAppToast(
        context,
        'Lot fournisseur créé avec succès',
        type: ToastType.success,
      );
      context.pop(created);
    } on PostgrestException catch (e) {
      if (mounted) {
        showAppToast(context, mapLotUserMessage(e), type: ToastType.error);
      }
    } catch (e) {
      if (mounted) {
        showAppToast(context, mapLotUserMessage(e), type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Widget _buildForm(RefDataCache refData) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Informations de base',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: selectedFournisseurId,
            decoration: const InputDecoration(
              labelText: 'Fournisseur *',
              border: OutlineInputBorder(),
            ),
            items: refData.fournisseurs.entries
                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: (v) {
              setState(() {
                selectedFournisseurId = v;
                _dirty = true;
              });
            },
            validator: (v) => v == null ? 'Fournisseur requis' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: selectedProduitId,
            decoration: const InputDecoration(
              labelText: 'Produit *',
              border: OutlineInputBorder(),
            ),
            items: refData.produits.entries
                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: (v) {
              setState(() {
                selectedProduitId = v;
                _dirty = true;
              });
            },
            validator: (v) => v == null ? 'Produit requis' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _referenceController,
            decoration: const InputDecoration(
              labelText: 'Référence fournisseur *',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.next,
            onChanged: (_) => _dirty = true,
            validator: (v) =>
                v?.trim().isEmpty ?? true ? 'Référence requise' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            readOnly: true,
            controller: _dateLotDisplayController,
            decoration: const InputDecoration(
              labelText: 'Date du lot',
              border: OutlineInputBorder(),
            ),
            onTap: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: dateLot ?? now,
                firstDate: DateTime(now.year - 2),
                lastDate: DateTime(now.year + 2),
              );
              if (picked != null) {
                setState(() {
                  dateLot = picked;
                  _dateLotDisplayController.text = _formatDateLot(picked);
                  _dirty = true;
                });
              }
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Note',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'Note',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: 4,
            textInputAction: TextInputAction.newline,
            onChanged: (_) => _dirty = true,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: isSaving ? null : _submit,
            icon: isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(isSaving ? 'Enregistrement...' : 'Enregistrer'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final refDataAsync = ref.watch(refDataProvider);

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await confirmAction(
          context,
          title: 'Annuler les modifications ?',
          message: 'Les changements non enregistrés seront perdus.',
          confirmLabel: 'Quitter',
        );
        if (!context.mounted) return;
        if (shouldPop) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Nouveau lot fournisseur'),
        ),
        body: refDataAsync.when(
          data: _buildForm,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(e.toString(), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(refDataProvider),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
