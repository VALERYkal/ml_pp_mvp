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



import 'package:ml_pp_mvp/shared/referentiels/role_provider.dart';
import 'package:ml_pp_mvp/shared/utils/volume_calc.dart';
import 'package:ml_pp_mvp/shared/referentiels/referentiels.dart' as refs;
import 'package:ml_pp_mvp/features/citernes/providers/citerne_providers.dart';
import 'package:ml_pp_mvp/features/stocks_journaliers/providers/stocks_providers.dart';

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

  // Helper pour calculer le volume 15°C
  double? _calc15c(double volumeAmbiant, double densite, double temperature) {
    if (volumeAmbiant <= 0 || densite <= 0) return null;
    return calcV15(
      volumeObserveL: volumeAmbiant,
      temperatureC: temperature,
      densiteA15: densite,
    );
  }

  // Helper pour nettoyer les chaînes
  String? _nz(String s) => s.trim().isEmpty ? null : s.trim();

  bool _busy = false;
  bool _navigated = false;

  Future<void> _onValidate() async {
    if (_busy) return;
    setState(() => _busy = true);

    // 1) Défocus AVANT tout (empêche l'assert InputDecorator)
    FocusScope.of(context).unfocus();

    try {
      // 2) Validations locales (ids, index_avant < index_apres, etc.)
      if (citerneId == null || produitId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choisis la citerne et le produit')));
        return;
      }
      
      final avant = _num(ctrlAvant.text);
      final apres = _num(ctrlApres.text);
      if (!(apres > avant && avant >= 0)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Indices invalides')));
        return;
      }

      final isPartenaire = proprietaireType == 'PARTENAIRE';
      final payload = {
        'citerne_id': citerneId,
        'produit_id': produitId,
        'client_id': isPartenaire ? null : clientId,
        'partenaire_id': isPartenaire ? partenaireId : null,
        'proprietaire_type': proprietaireType, // 'MONALUXE' | 'PARTENAIRE'
        'index_avant': avant,
        'index_apres': apres,
        'volume_corrige_15c': _num(ctrlDens.text) != 0 && _num(ctrlTemp.text) != 0
            ? _calc15c(apres - avant, _num(ctrlDens.text), _num(ctrlTemp.text))
            : null,
        'temperature_ambiant_c': _num(ctrlTemp.text) != 0 ? _num(ctrlTemp.text) : null,
        'densite_a15': _num(ctrlDens.text) != 0 ? _num(ctrlDens.text) : null,
        'note': _nz(ctrlNote.text)?.isEmpty == true ? null : _nz(ctrlNote.text),
        'date_sortie': DateTime.now().toIso8601String(),
        'chauffeur_nom': _nz(ctrlChauffeur.text),
        'plaque_camion': _nz(ctrlPlaqueCamion.text),
        'plaque_remorque': _nz(ctrlPlaqueRemorque.text),
        'transporteur': _nz(ctrlTransporteur.text),
        'statut': 'validee',
      };

      // 3) UN SEUL insert (+ select().single() pour éviter 204 No Content)
      await Supabase.instance.client
          .from('sorties_produit')
          .insert(payload)
          .select('*')
          .single();

      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sortie validée')),
      );

      // 4) Invalidation des providers (stocks/citernes/listes)
      ref.invalidate(stocksListProvider);
      ref.invalidate(citernesWithStockProvider);

      // 5) Navigation après un court délai et en fin de frame
      if (!_navigated) {
        _navigated = true;
        await Future<void>.delayed(const Duration(milliseconds: 200));
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.of(context).pop(); // retour liste
        });
      }
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message.isNotEmpty ? e.message : 'Erreur Supabase')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
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
      body: _busy
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // -------------------------------
                          //  Colle ICI ton Stepper existant
                          //  (uniquement la partie Stepper(...))
                          // -------------------------------
                          Stepper(
                            currentStep: step,
                            type: StepperType.vertical,
                            physics: const ClampingScrollPhysics(),
                            onStepCancel: () {
                              setState(() {
                                step = (step > 0) ? step - 1 : 0;
                              });
                            },
                            onStepContinue: () {
                              setState(() {
                                step = (step < 2) ? step + 1 : 2;
                              });
                            },
                            // On neutralise les boutons intégrés du Stepper
                            controlsBuilder: (context, details) =>
                                const SizedBox.shrink(),
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
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Client ID (optionnel)',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) => clientId = v.trim().isEmpty ? null : v.trim(),
                      ),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Partenaire ID (optionnel)',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) => partenaireId = v.trim().isEmpty ? null : v.trim(),
                      ),
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
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Produit ID',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) => produitId = v.trim().isEmpty ? null : v.trim(),
                      ),
                      const SizedBox(height: 8),
                      citernesAsync.when(
                        data: (items) {
                          final filtered = (produitId == null)
                              ? <refs.CiterneRef>[]
                              : items.where((e) => e.produitId == produitId).toList();

                          return DropdownButtonFormField<String>(
                            key: const Key('citerneDropdown'),
                            decoration: const InputDecoration(
                              labelText: 'Citerne *',
                              border: OutlineInputBorder(),
                            ),
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
                                              Flexible(fit: FlexFit.tight, child: TextField(
                        controller: ctrlAvant,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Index avant *',
                          border: OutlineInputBorder(),
                        ),
                      )),
                      const SizedBox(width: 12),
                      Flexible(fit: FlexFit.tight, child: TextField(
                        controller: ctrlApres,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Index après *',
                          border: OutlineInputBorder(),
                        ),
                      )),
                      ]),
                      Row(children: [
                                              Flexible(fit: FlexFit.tight, child: TextField(
                        controller: ctrlTemp,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Température (°C)',
                          border: OutlineInputBorder(),
                        ),
                      )),
                      const SizedBox(width: 12),
                      Flexible(fit: FlexFit.tight, child: TextField(
                        controller: ctrlDens,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Densité @15°C',
                          border: OutlineInputBorder(),
                        ),
                      )),
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
                          OutlinedButton(
                            onPressed: _busy ? null : () => setState(() => step = 0), 
                            child: const Text('‹ Précédent')
                          ),
                          ElevatedButton(
                            onPressed: _busy ? null : _onValidate, 
                            child: const Text('Enregistrer')
                          ),
                          ElevatedButton(
                            onPressed: _busy ? null : () => setState(() => step = 2), 
                            child: const Text('Suivant >')
                          ),
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
                    TextField(
                      controller: ctrlChauffeur,
                      decoration: const InputDecoration(
                        labelText: 'Nom du chauffeur *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    TextField(
                      controller: ctrlPlaqueCamion,
                      decoration: const InputDecoration(
                        labelText: 'Plaque camion *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    TextField(
                      controller: ctrlPlaqueRemorque,
                      decoration: const InputDecoration(
                        labelText: 'Plaque remorque (optionnel)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    TextField(
                      controller: ctrlTransporteur,
                      decoration: const InputDecoration(
                        labelText: 'Transporteur *',
                        border: OutlineInputBorder(),
                      ),
                    ),
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
                        ElevatedButton.icon(
                          onPressed: _busy ? null : _onValidate, 
                          icon: const Icon(Icons.save), 
                          label: const Text('Enregistrer')
                        ),
                        roleAsync.when(
                          loading: () => const SizedBox.shrink(),
                          error: (e, _) => Text('Rôle: $e'),
                          data: (role) => (role != null && ['admin', 'directeur', 'gerant'].contains(role.toLowerCase()))
                              ? ElevatedButton.icon(
                                  onPressed: _busy ? null : _onValidate, 
                                  icon: const Icon(Icons.verified), 
                                  label: const Text('Valider')
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // (Optionnel) bouton global si tu en veux un ici.
            // SafeArea(
            //   top: false,
            //   child: ElevatedButton.icon(
            //     onPressed: _busy ? null : _onValidate,
            //     icon: const Icon(Icons.verified),
            //     label: const Text('Valider'),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}


