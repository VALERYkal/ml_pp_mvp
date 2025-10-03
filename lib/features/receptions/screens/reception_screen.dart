/* ===========================================================
   ML_PP MVP — ReceptionScreen (Stepper)
   Rôle: écran 3 étapes pour créer un brouillon de réception
   puis, si autorisé, lancer la validation (RPC).
   Étapes:
   (1) Source/Propriété  (Monaluxe/Partenaire + partenaire/cours)
   (2) Mesures & Citerne (citerne active, produit ESS/AGO, indices, T, densité)
   (3) Finalisation       (Enregistrer brouillon / Valider RPC)
   =========================================================== */
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ml_pp_mvp/shared/referentiels/referentiels.dart' as refs;
import 'package:ml_pp_mvp/shared/utils/volume_calc.dart';
import 'package:ml_pp_mvp/features/receptions/data/reception_input.dart';
import 'package:ml_pp_mvp/features/receptions/data/reception_service_v2.dart';

class ReceptionScreen extends ConsumerStatefulWidget {
  const ReceptionScreen({super.key});
  @override
  ConsumerState<ReceptionScreen> createState() => _ReceptionScreenState();
}

class _ReceptionScreenState extends ConsumerState<ReceptionScreen> {
  // ÉTAT FORMULAIRE
  String proprietaireType = 'MONALUXE';
  String? partenaireId;
  String? coursDeRouteId;

  String? citerneId;
  String produitCode = 'ESS'; // toggle ESS/AGO
  final ctrlAvant = TextEditingController();
  final ctrlApres = TextEditingController();
  final ctrlTemp = TextEditingController();
  final ctrlDens = TextEditingController();
  final ctrlNote = TextEditingController();
  DateTime? dateReception;

  int currentStep = 0;
  bool loading = false;

  @override
  void dispose() {
    ctrlAvant.dispose();
    ctrlApres.dispose();
    ctrlTemp.dispose();
    ctrlDens.dispose();
    ctrlNote.dispose();
    super.dispose();
  }

  // Helper local pour parser proprement les nombres (gère virgules/espaces NBSP)
  double? _num(String s) => double.tryParse(
    s.replaceAll(RegExp(r'[^\d\-,\.]'), '').replaceAll(',', '.'),
  );

  Future<void> _enregistrerBrouillon() async {
    setState(() => loading = true);
    try {
      final repo = ref.read(refs.referentielsRepoProvider);
      final service = ReceptionService(Supabase.instance.client, repo);

      final input = ReceptionInput(
        proprietaireType: proprietaireType,
        partenaireId: proprietaireType == 'PARTENAIRE' ? partenaireId : null,
        citerneId: citerneId!,
        produitCode: produitCode,
        // Patch mineur — parsing robuste
        indexAvant: _num(ctrlAvant.text),
        indexApres: _num(ctrlApres.text),
        temperatureC: _num(ctrlTemp.text),
        densiteA15: _num(ctrlDens.text),
        dateReception: dateReception ?? DateTime.now(),
        coursDeRouteId: (proprietaireType == 'MONALUXE')
            ? coursDeRouteId
            : null,
        note: ctrlNote.text.isEmpty ? null : ctrlNote.text.trim(),
      );

      final id = await service.createDraft(input);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Brouillon créé (#$id)')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // Déprécié dans cette UI minimale; la validation se fait depuis la fiche détaillée
  void _validerReception(String receptionId) {}

  @override
  Widget build(BuildContext context) {
    // final produitsAsync = ref.watch(refs.produitsRefProvider);
    // final citernesAsync = ref.watch(refs.citernesActivesProvider);

    final avant = double.tryParse(ctrlAvant.text.replaceAll(',', '.'));
    final apres = double.tryParse(ctrlApres.text.replaceAll(',', '.'));
    final temp = double.tryParse(ctrlTemp.text.replaceAll(',', '.'));
    final dens = double.tryParse(ctrlDens.text.replaceAll(',', '.'));
    final volAmb = computeVolumeAmbiant(avant, apres);
    final vol15 = calcV15(
      volumeObserveL: volAmb,
      temperatureC: temp ?? 15.0,
      densiteA15: dens ?? 0.83,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Réception produit')),
      body: (loading)
          ? const Center(child: CircularProgressIndicator())
          : Stepper(
              currentStep: currentStep,
              onStepContinue: () {
                if (currentStep < 2) setState(() => currentStep++);
              },
              onStepCancel: () {
                if (currentStep > 0) setState(() => currentStep--);
              },
              steps: [
                Step(
                  title: const Text('Source & Propriété'),
                  isActive: currentStep >= 0,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Propriétaire'),
                      Row(
                        children: [
                          Radio<String>(
                            value: 'MONALUXE',
                            groupValue: proprietaireType,
                            onChanged: (v) =>
                                setState(() => proprietaireType = v!),
                          ),
                          const Text('Monaluxe'),
                          const SizedBox(width: 16),
                          Radio<String>(
                            value: 'PARTENAIRE',
                            groupValue: proprietaireType,
                            onChanged: (v) =>
                                setState(() => proprietaireType = v!),
                          ),
                          const Text('Partenaire'),
                        ],
                      ),
                      if (proprietaireType == 'PARTENAIRE')
                        TextField(
                          decoration: const InputDecoration(
                            labelText:
                                'Partenaire ID (Autocomplete réel à brancher)',
                          ),
                          onChanged: (v) =>
                              partenaireId = v.trim().isEmpty ? null : v.trim(),
                        ),
                      if (proprietaireType == 'MONALUXE')
                        TextField(
                          decoration: const InputDecoration(
                            labelText:
                                'Cours de route ID (filtrer sur "arrivé")',
                          ),
                          onChanged: (v) => coursDeRouteId = v.trim().isEmpty
                              ? null
                              : v.trim(),
                        ),
                    ],
                  ),
                ),
                Step(
                  title: const Text('Mesures & Citerne'),
                  isActive: currentStep >= 1,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Citerne active (Autocomplete minimal)
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Citerne ID (active)',
                        ),
                        onChanged: (v) =>
                            citerneId = v.trim().isEmpty ? null : v.trim(),
                      ),
                      const SizedBox(height: 8),
                      // Produit toggle ESS/AGO
                      const Text('Produit'),
                      Row(
                        children: [
                          ChoiceChip(
                            label: const Text('ESS'),
                            selected: produitCode == 'ESS',
                            onSelected: (_) =>
                                setState(() => produitCode = 'ESS'),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('AGO'),
                            selected: produitCode == 'AGO',
                            onSelected: (_) =>
                                setState(() => produitCode = 'AGO'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: ctrlAvant,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Index avant',
                        ),
                      ),
                      TextField(
                        controller: ctrlApres,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Index après',
                        ),
                      ),
                      TextField(
                        controller: ctrlTemp,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Température (°C)',
                        ),
                      ),
                      TextField(
                        controller: ctrlDens,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Densité @15°C',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Preview volume ambiant: ${volAmb.toStringAsFixed(2)}',
                      ),
                      Text('Preview volume 15°C: ${vol15.toStringAsFixed(2)}'),
                    ],
                  ),
                ),
                Step(
                  title: const Text('Finalisation'),
                  isActive: currentStep >= 2,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: ctrlNote,
                        decoration: const InputDecoration(
                          labelText: 'Note (optionnel)',
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.save),
                            label: const Text('Enregistrer (brouillon)'),
                            onPressed: (citerneId == null)
                                ? null
                                : () => _enregistrerBrouillon(),
                          ),
                          const SizedBox(width: 12),
                          // NOTE: Si vous avez un provider de rôle, vous pouvez le lire ici
                          // et masquer le bouton Valider si non autorisé.
                          ElevatedButton.icon(
                            icon: const Icon(Icons.verified),
                            label: const Text('Valider (RPC)'),
                            onPressed: () async {
                              // Ici, on suppose que vous avez l'ID après création.
                              // Dans une vraie intégration, ce bouton se trouve sur l’écran de détail d’une réception.
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Renseignez d’abord le brouillon, puis validez depuis la fiche.',
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
