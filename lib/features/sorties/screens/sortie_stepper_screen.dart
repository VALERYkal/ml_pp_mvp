/* ===========================================================
   ML_PP — SortieStepperScreen (additif)
   Étapes:
   1) Bénéficiaire & propriété
   2) Mesures & citerne (filtrée par produit)
   3) Résumé & validation
   Note: Implémentation minimale, s'appuie sur SortieService pour createDraft/validate.
   =========================================================== */
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ml_pp_mvp/features/sorties/data/sortie_input.dart';
import 'package:ml_pp_mvp/features/sorties/data/sortie_draft_service.dart';
import 'package:ml_pp_mvp/features/sorties/data/sortie_service.dart';
import 'package:ml_pp_mvp/shared/referentiels/role_provider.dart';
import 'package:ml_pp_mvp/shared/utils/volume_calc.dart';
import 'package:ml_pp_mvp/shared/referentiels/referentiels.dart' as refs;

class SortieStepperScreen extends ConsumerStatefulWidget {
  const SortieStepperScreen({super.key});
  @override
  ConsumerState<SortieStepperScreen> createState() => _SortieStepperScreenState();
}

class _SortieStepperScreenState extends ConsumerState<SortieStepperScreen> {
  int step = 0;
  bool busy = false;

  // Étape 1
  String proprietaireType = 'MONALUXE';
  String? clientId;
  String? partenaireId;

  // Étape 2
  String? produitId;
  String? citerneId;
  final ctrlAvant = TextEditingController();
  final ctrlApres = TextEditingController();
  final ctrlTemp = TextEditingController(text: '15');
  final ctrlDens = TextEditingController(text: '0.83');
  final ctrlNote = TextEditingController();
  
  // Étape 3 - Transport
  final ctrlChauffeur = TextEditingController();
  final ctrlPlaqueCamion = TextEditingController();
  final ctrlPlaqueRemorque = TextEditingController();
  final ctrlTransporteur = TextEditingController();

  String? lastDraftId;

  @override
  void initState() {
    super.initState();
    _wirePreview();
  }

  @override
  void dispose() {
    ctrlAvant.dispose(); ctrlApres.dispose(); ctrlTemp.dispose(); ctrlDens.dispose(); ctrlNote.dispose();
    ctrlChauffeur.dispose(); ctrlPlaqueCamion.dispose(); ctrlPlaqueRemorque.dispose(); ctrlTransporteur.dispose();
    super.dispose();
  }

  void _wirePreview() {
    for (final c in [ctrlAvant, ctrlApres, ctrlTemp, ctrlDens]) {
      c.addListener(() => mounted ? setState(() {}) : null);
    }
  }

  double _num(String s) => double.tryParse(s.replaceAll(',', '.')) ?? 0.0;

  double get _volumeAmbiantPrev {
    final avant = _num(ctrlAvant.text);
    final apres = _num(ctrlApres.text);
    final v = apres - avant;
    return v.isFinite && v > 0 ? v : 0.0;
  }

  double get _volume15Prev => calcV15(
    volumeObserveL: _volumeAmbiantPrev,
    temperatureC: _num(ctrlTemp.text),
    densiteA15: _num(ctrlDens.text),
  );

  Future<void> _saveDraft() async {
    if (produitId == null || citerneId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Produit et citerne requis')));
      return;
    }
    if ((clientId == null || clientId!.isEmpty) && (partenaireId == null || partenaireId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bénéficiaire requis (client ou partenaire)')));
      return;
    }
    if (ctrlChauffeur.text.isEmpty || ctrlPlaqueCamion.text.isEmpty || ctrlTransporteur.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chauffeur, plaque camion et transporteur sont requis')));
      return;
    }
    final avant = _num(ctrlAvant.text);
    final apres = _num(ctrlApres.text);
    if (!(apres > avant && avant >= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Indices invalides')));
      return;
    }

    setState(() => busy = true);
    try {
      final input = SortieInput(
        citerneId: citerneId!,
        produitId: produitId!,
        clientId: clientId,
        partenaireId: partenaireId,
        proprietaireType: proprietaireType,
        indexAvant: avant,
        indexApres: apres,
        temperatureC: _num(ctrlTemp.text),
        densiteA15: _num(ctrlDens.text),
        note: ctrlNote.text.isEmpty ? null : ctrlNote.text.trim(),
        dateSortie: DateTime.now(),
        chauffeurNom: ctrlChauffeur.text.trim(),
        plaqueCamion: ctrlPlaqueCamion.text.trim(),
        plaqueRemorque: ctrlPlaqueRemorque.text.isEmpty ? null : ctrlPlaqueRemorque.text.trim(),
        transporteur: ctrlTransporteur.text.trim(),
      );
      final id = await SortieDraftService(Supabase.instance.client).createDraft(input);
      setState(() => lastDraftId = id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Brouillon sortie créé (#$id)')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _validate() async {
    final id = lastDraftId;
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Créez d’abord un brouillon')));
      return;
    }
    setState(() => busy = true);
    try {
      final service = SortieService(Supabase.instance.client);
      await service.validate(sortieId: id, canValidate: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sortie validée ✅')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Validation impossible: $e')));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleAsync = ref.watch(userRoleProvider);
    final citernesAsync = ref.watch(refs.citernesActivesProvider);
    final avant = _num(ctrlAvant.text);
    final apres = _num(ctrlApres.text);
    final temp = _num(ctrlTemp.text);
    final dens = _num(ctrlDens.text);
    final volAmb = computeVolumeAmbiant(avant, apres);
    final vol15 = calcV15(volumeObserveL: volAmb, temperatureC: temp, densiteA15: dens);
    return Scaffold(
      appBar: AppBar(title: const Text('Sorties / Nouvelle sortie')),
      body: busy
          ? const Center(child: CircularProgressIndicator())
          : Stepper(
              currentStep: step,
              onStepCancel: () => setState(() => step = (step > 0) ? step - 1 : 0),
              onStepContinue: () => setState(() => step = (step < 2) ? step + 1 : 2),
              controlsBuilder: (ctx, details) => const SizedBox.shrink(),
              steps: [
                Step(
                  title: const Text('[ Step 1/3 ]  Bénéficiaire & propriété'),
                  isActive: step >= 0,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Propriétaire'),
                      Row(children: [
                        Radio<String>(value: 'MONALUXE', groupValue: proprietaireType, onChanged: (v) => setState(() => proprietaireType = v!)),
                        const Text('Monaluxe'),
                        const SizedBox(width: 16),
                        Radio<String>(value: 'PARTENAIRE', groupValue: proprietaireType, onChanged: (v) => setState(() => proprietaireType = v!)),
                        const Text('Partenaire'),
                      ]),
                      TextField(decoration: const InputDecoration(labelText: 'Client ID (optionnel)'), onChanged: (v) => clientId = v.trim().isEmpty ? null : v.trim()),
                      TextField(decoration: const InputDecoration(labelText: 'Partenaire ID (optionnel)'), onChanged: (v) => partenaireId = v.trim().isEmpty ? null : v.trim()),
                      Align(alignment: Alignment.centerRight, child: ElevatedButton(onPressed: () => setState(() => step = 1), child: const Text('Suivant >'))),
                    ],
                  ),
                ),
                Step(
                  title: const Text('[ Step 2/3 ]  Mesures & Citerne'),
                  isActive: step >= 1,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(decoration: const InputDecoration(labelText: 'Produit ID'), onChanged: (v) => produitId = v.trim().isEmpty ? null : v.trim()),
                      const SizedBox(height: 8),
                      citernesAsync.when(
                        data: (items) {
                          final filtered = (produitId == null)
                              ? <refs.CiterneRef>[]
                              : items.where((e) => e.produitId == produitId).toList();

                          return DropdownButtonFormField<String>(
                            key: const Key('citerneDropdown'),
                            decoration: const InputDecoration(labelText: 'Citerne *'),
                            value: citerneId,
                            items: filtered
                                .map((e) => DropdownMenuItem(
                                      value: e.id,
                                      child: Text(e.nom),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() => citerneId = v),
                            validator: (v) => v == null ? 'Choisir une citerne' : null,
                          );
                        },
                        loading: () => const CircularProgressIndicator(),
                        error: (e, _) => Text('Erreur chargement citernes: $e'),
                      ),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: TextField(controller: ctrlAvant, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Index avant *'))),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: ctrlApres, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Index après *'))),
                      ]),
                      Row(children: [
                        Expanded(child: TextField(controller: ctrlTemp, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Température (°C)'))),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: ctrlDens, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Densité @15°C'))),
                      ]),
                      const SizedBox(height: 8),
                      Text(
                        'Prévisualisation : ${_volumeAmbiantPrev.toStringAsFixed(2)} L (ambiant)',
                        key: const Key('previewAmb'),
                      ),
                      Text(
                        '≈ ${_volume15Prev.toStringAsFixed(2)} L @15°C',
                        key: const Key('previewV15'),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        alignment: WrapAlignment.end,
                        runAlignment: WrapAlignment.end,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton(onPressed: () => setState(() => step = 0), child: const Text('‹ Précédent')),
                          ElevatedButton(onPressed: _saveDraft, child: const Text('Enregistrer brouillon')),
                          ElevatedButton(onPressed: () => setState(() => step = 2), child: const Text('Suivant >')),
                        ],
                      ),
                    ],
                  ),
                ),
                Step(
                  title: const Text('[ Step 3/3 ]  Transport & Validation'),
                  isActive: step >= 2,
                  content: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Informations de transport *'),
                    TextField(controller: ctrlChauffeur, decoration: const InputDecoration(labelText: 'Nom du chauffeur *')),
                    TextField(controller: ctrlPlaqueCamion, decoration: const InputDecoration(labelText: 'Plaque camion *')),
                    TextField(controller: ctrlPlaqueRemorque, decoration: const InputDecoration(labelText: 'Plaque remorque (optionnel)')),
                    TextField(controller: ctrlTransporteur, decoration: const InputDecoration(labelText: 'Transporteur *')),
                    const SizedBox(height: 16),
                    const Text('Récapitulatif'),
                    Text('• Propriétaire: $proprietaireType'),
                    Text('• Bénéficiaire: client=${clientId ?? '-'} / partenaire=${partenaireId ?? '-'}'),
                    Text('• Produit: ${produitId ?? '-'}  |  Citerne: ${citerneId ?? '-'}'),
                    Text('• Index: ${ctrlAvant.text} → ${ctrlApres.text}  (Δ = ${volAmb.toStringAsFixed(2)} L)'),
                    Text('• Volume 15°C ≈ ${vol15.toStringAsFixed(2)} L'),
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.end,
                      runAlignment: WrapAlignment.end,
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(onPressed: _saveDraft, icon: const Icon(Icons.save), label: const Text('Enregistrer brouillon')),
                        roleAsync.when(
                          loading: () => const SizedBox.shrink(),
                          error: (e, _) => Text('Rôle: $e'),
                          data: (role) => (role != null && ['admin', 'directeur', 'gerant'].contains(role.toLowerCase()))
                              ? ElevatedButton.icon(onPressed: _validate, icon: const Icon(Icons.verified), label: const Text('Valider'))
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ]),
                ),
              ],
            ),
    );
  }
}


