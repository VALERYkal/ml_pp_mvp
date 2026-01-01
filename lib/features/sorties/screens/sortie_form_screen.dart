/* ===========================================================
   ML_PP MVP — SortieFormScreen
   Rôle: Écran pour créer une sortie validée avec validation métier stricte.
   =========================================================== */
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:postgrest/postgrest.dart';
import 'package:ml_pp_mvp/shared/ui/toast.dart';
import 'package:ml_pp_mvp/shared/ui/errors.dart';
import 'package:ml_pp_mvp/core/errors/sortie_validation_exception.dart';
import 'package:ml_pp_mvp/core/errors/sortie_service_exception.dart';
import 'package:ml_pp_mvp/shared/referentiels/referentiels.dart' as refs;
import 'package:ml_pp_mvp/shared/utils/volume_calc.dart';
import 'package:ml_pp_mvp/features/sorties/providers/sortie_providers.dart'
    show
        sortieServiceProvider,
        sortiesListProvider,
        clientsListProvider,
        partenairesListProvider;
import 'package:ml_pp_mvp/features/sorties/data/sortie_service.dart';
import 'package:ml_pp_mvp/features/sorties/providers/sorties_table_provider.dart';
import 'package:ml_pp_mvp/features/sorties/kpi/sorties_kpi_provider.dart';
import 'package:ml_pp_mvp/features/profil/providers/profil_provider.dart';
import 'package:ml_pp_mvp/shared/refresh/refresh_helpers.dart';

enum OwnerType { monaluxe, partenaire }

class SortieFormScreen extends ConsumerStatefulWidget {
  /// Optionnel : permet d'injecter un SortieService spécifique (tests).
  final SortieService? debugSortieService;

  const SortieFormScreen({super.key, this.debugSortieService});

  @override
  ConsumerState<SortieFormScreen> createState() => _SortieFormScreenState();
}

class _SortieFormScreenState extends ConsumerState<SortieFormScreen> {
  bool busy = false;

  final _formKey = GlobalKey<FormState>();

  String proprietaireType = 'MONALUXE';
  OwnerType _owner = OwnerType.monaluxe;
  String? partenaireId;
  String? clientId;

  String? _selectedProduitId;
  String? _selectedCiterneId;
  DateTime _selectedDate = DateTime.now();

  final ctrlAvant = TextEditingController();
  final ctrlApres = TextEditingController();
  final ctrlTemp = TextEditingController(text: '15');
  final ctrlDens = TextEditingController(text: '0.83');
  final ctrlChauffeur = TextEditingController();
  final ctrlPlaqueCamion = TextEditingController();
  final ctrlPlaqueRemorque = TextEditingController();
  final ctrlTransporteur = TextEditingController();
  final ctrlNote = TextEditingController();

  @override
  void dispose() {
    ctrlAvant.dispose();
    ctrlApres.dispose();
    ctrlTemp.dispose();
    ctrlDens.dispose();
    ctrlChauffeur.dispose();
    ctrlPlaqueCamion.dispose();
    ctrlPlaqueRemorque.dispose();
    ctrlTransporteur.dispose();
    ctrlNote.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _owner = (proprietaireType == 'PARTENAIRE')
        ? OwnerType.partenaire
        : OwnerType.monaluxe;
  }

  void _onOwnerChange(OwnerType val) {
    setState(() {
      _owner = val;
      proprietaireType = (val == OwnerType.monaluxe)
          ? 'MONALUXE'
          : 'PARTENAIRE';
      _selectedCiterneId = null;
      if (_owner == OwnerType.partenaire) {
        clientId = null;
      } else {
        partenaireId = null;
      }
    });
  }

  double? _num(String s) => double.tryParse(
    s.replaceAll(RegExp(r'[^\d\-,\.]'), '').replaceAll(',', '.'),
  );
  bool get isMonaluxe => proprietaireType == 'MONALUXE';
  bool get isPartenaire => proprietaireType == 'PARTENAIRE';

  /// Helper pour récupérer le nom de la citerne depuis son ID
  /// Utilise un fallback simple avec l'ID tronqué pour le log de diagnostic
  String _getCiterneNom(String? citerneId) {
    if (citerneId == null) {
      return 'N/A';
    }
    // Fallback simple : utiliser l'ID tronqué (suffisant pour le log de diagnostic)
    return citerneId.length > 8 ? '${citerneId.substring(0, 8)}...' : citerneId;
  }

  /// Méthode publique pour les tests d'intégration.
  /// Permet d'appeler directement la soumission sans passer par le bouton UI.
  @visibleForTesting
  Future<void> submitSortieForTesting() async {
    return _submitSortie();
  }

  Future<void> _submitSortie() async {
    // Validation FormState
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validations minimales UI (champs non-TextFormField)
    if (_selectedProduitId == null) {
      showAppToast(
        context,
        'Sélectionnez un produit.',
        type: ToastType.warning,
      );
      return;
    }
    if (_selectedCiterneId == null) {
      showAppToast(
        context,
        'Sélectionnez une citerne.',
        type: ToastType.warning,
      );
      return;
    }
    if (isMonaluxe && (clientId == null || clientId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choisissez un client pour une sortie MONALUXE'),
        ),
      );
      return;
    }
    if (isPartenaire && (partenaireId == null || partenaireId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choisissez un partenaire pour une sortie PARTENAIRE'),
        ),
      );
      return;
    }

    final avant = _num(ctrlAvant.text) ?? 0;
    final apres = _num(ctrlApres.text) ?? 0;
    if (apres <= avant) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indices incohérents (après ≤ avant)')),
      );
      return;
    }

    // 🚨 PROD-LOCK: Validation UI température/densité OBLIGATOIRES - DO NOT MODIFY
    // RÈGLE MÉTIER : Température et densité sont OBLIGATOIRES pour calculer volume 15°C.
    // Cette validation UI doit correspondre à la validation service (sortie_service.dart).
    // Si cette validation est modifiée, mettre à jour:
    // - Tests E2E (si applicable)
    // - Validation service (sortie_service.dart)
    // - Documentation métier

    // Validation UI : température et densité obligatoires
    final temp = _num(ctrlTemp.text);
    final dens = _num(ctrlDens.text);
    if (temp == null || temp <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La température ambiante (°C) est obligatoire et doit être > 0',
          ),
        ),
      );
      return;
    }
    if (dens == null || dens <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La densité à 15°C est obligatoire et doit être > 0'),
        ),
      );
      return;
    }
    // Validation densité dans intervalle raisonnable
    if (dens < 0.7 || dens > 1.1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La densité à 15°C doit être entre 0.7 et 1.1'),
        ),
      );
      return;
    }

    final volAmb = computeVolumeAmbiant(avant, apres);
    // temp et dens sont garantis non-null et > 0 par validation ci-dessus
    final vol15 = calcV15(
      volumeObserveL: volAmb,
      temperatureC: temp,
      densiteA15: dens,
    );

    // Construire le payload pour logging détaillé (debug uniquement)
    final payloadMap = <String, dynamic>{
      'citerne_id': _selectedCiterneId!,
      'produit_id': _selectedProduitId!,
      'client_id': _owner == OwnerType.monaluxe ? clientId : null,
      'partenaire_id': _owner == OwnerType.partenaire ? partenaireId : null,
      'index_avant': avant,
      'index_apres': apres,
      'volume_ambiant': volAmb,
      'volume_corrige_15c': vol15,
      'temperature_ambiante_c': temp,
      'densite_a_15': dens,
      'proprietaire_type': _owner == OwnerType.monaluxe
          ? 'MONALUXE'
          : 'PARTENAIRE',
      'statut': 'validee',
      if (_selectedDate != null)
        'date_sortie': _selectedDate!.toUtc().toIso8601String(),
      if (ctrlChauffeur.text.trim().isNotEmpty)
        'chauffeur_nom': ctrlChauffeur.text.trim(),
      if (ctrlPlaqueCamion.text.trim().isNotEmpty)
        'plaque_camion': ctrlPlaqueCamion.text.trim(),
      if (ctrlPlaqueRemorque.text.trim().isNotEmpty)
        'plaque_remorque': ctrlPlaqueRemorque.text.trim(),
      if (ctrlTransporteur.text.trim().isNotEmpty)
        'transporteur': ctrlTransporteur.text.trim(),
      if (ctrlNote.text.trim().isNotEmpty) 'note': ctrlNote.text.trim(),
    };

    if (kDebugMode) {
      debugPrint('[SORTIE][PAYLOAD] $payloadMap');
    }

    setState(() => busy = true);
    try {
      // En PROD : on utilise le provider.
      // En TEST : on peut injecter un SortieService custom (spy).
      final SortieService sortieService =
          widget.debugSortieService ?? ref.read(sortieServiceProvider);

      await sortieService.createValidated(
        citerneId: _selectedCiterneId!,
        produitId: _selectedProduitId!,
        indexAvant: avant,
        indexApres: apres,
        temperatureCAmb: temp, // Non-null garanti par validation UI
        densiteA15: dens, // Non-null garanti par validation UI
        volumeCorrige15C: vol15,
        proprietaireType: _owner == OwnerType.monaluxe
            ? 'MONALUXE'
            : 'PARTENAIRE',
        clientId: _owner == OwnerType.monaluxe ? clientId : null,
        partenaireId: _owner == OwnerType.partenaire ? partenaireId : null,
        chauffeurNom: ctrlChauffeur.text.isEmpty
            ? null
            : ctrlChauffeur.text.trim(),
        plaqueCamion: ctrlPlaqueCamion.text.isEmpty
            ? null
            : ctrlPlaqueCamion.text.trim(),
        plaqueRemorque: ctrlPlaqueRemorque.text.isEmpty
            ? null
            : ctrlPlaqueRemorque.text.trim(),
        transporteur: ctrlTransporteur.text.isEmpty
            ? null
            : ctrlTransporteur.text.trim(),
        note: ctrlNote.text.isEmpty ? null : ctrlNote.text.trim(),
        dateSortie: _selectedDate,
      );
      // Invalidation KPI après enregistrement réussi
      final profil = ref.read(profilProvider).valueOrNull;
      final depotId = profil?.depotId;
      invalidateDashboardKpisAfterStockMovement(ref, depotId: depotId);
      debugPrint(
        '🔄 KPI Refresh: invalidate dashboard KPI/Stocks after sortie validated',
      );

      if (mounted) {
        // Toast utilisateur simple
        showAppToast(
          context,
          'Sortie enregistrée avec succès.',
          type: ToastType.success,
        );

        // Log console détaillé pour diagnostic
        final citerneNom = _getCiterneNom(_selectedCiterneId);
        debugPrint(
          '[SORTIE] Succès • Volume: ${vol15.toStringAsFixed(2)} L • Citerne: $citerneNom',
        );

        // Invalidate impacted providers
        try {
          ref.invalidate(sortiesListProvider);
          ref.invalidate(sortiesTableProvider);
          ref.invalidate(sortiesKpiTodayProvider);
        } catch (_) {}
        context.go('/sorties');
      }
    } on SortieValidationException catch (e) {
      // Erreur métier : afficher un message clair avec le champ concerné
      debugPrint(
        '[SortieForm] SortieValidationException: ${e.message} (field: ${e.field})',
      );
      if (mounted) {
        final message = e.field != null
            ? '${e.message}\n(Champ: ${e.field})'
            : e.message;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } on SortieServiceException catch (e) {
      // Erreur SQL/DB du trigger
      if (kDebugMode) {
        debugPrint(
          '[SORTIE][ERROR] code=${e.code} message=${e.message} details=${e.details ?? 'N/A'} hint=${e.hint ?? 'N/A'}',
        );
      }
      if (mounted) {
        final errorMessage = e.message.toLowerCase();
        final isStockInsufficient =
            errorMessage.contains('stock insuffisant') ||
            errorMessage.contains('stock disponible') ||
            errorMessage.contains('capacité de sécurité') ||
            errorMessage.contains('insuffisant') ||
            errorMessage.contains('dépasserait');

        if (isStockInsufficient) {
          // Message métier lisible
          showAppToast(
            context,
            'Stock insuffisant dans la citerne.\n'
            'Veuillez ajuster le volume ou choisir une autre citerne.',
            type: ToastType.error,
            duration: const Duration(seconds: 5),
          );
        } else {
          // Autres erreurs : message générique
          showAppToast(
            context,
            'Une erreur est survenue. Veuillez réessayer.',
            type: ToastType.error,
          );
        }

        // Log détaillé pour diagnostic (console uniquement)
        debugPrint('[SORTIE] Erreur détaillée: ${e.message}');
      }
    } on PostgrestException catch (e, st) {
      debugPrint(
        '[SortieForm] PostgrestException: ${e.message} (code=${e.code}, hint=${e.hint}, details=${e.details})',
      );
      debugPrint('[SortieForm] stack=\n$st');
      if (mounted) {
        showAppToast(context, humanizePostgrest(e), type: ToastType.error);
      }
    } catch (e, st) {
      debugPrint('[SortieForm] UnknownError: $e');
      debugPrint('[SortieForm] stack=\n$st');
      if (mounted) {
        showAppToast(
          context,
          'Erreur technique lors de l\'enregistrement de la sortie. Veuillez réessayer.',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final avant = _num(ctrlAvant.text) ?? 0;
    final apres = _num(ctrlApres.text) ?? 0;
    final temp = _num(ctrlTemp.text);
    final dens = _num(ctrlDens.text);
    final volAmb = computeVolumeAmbiant(avant, apres);

    // Récupérer le code produit pour le calcul
    String produitCode = 'ESS'; // fallback
    if (_selectedProduitId != null) {
      ref
          .watch(refs.produitsRefProvider)
          .maybeWhen(
            data: (prods) {
              try {
                final prod = prods.firstWhere(
                  (p) => p.id == _selectedProduitId,
                );
                produitCode = prod.code.isNotEmpty ? prod.code : 'ESS';
              } catch (_) {
                // Produit non trouvé, utiliser le premier disponible ou fallback
                if (prods.isNotEmpty) {
                  produitCode = prods.first.code.isNotEmpty
                      ? prods.first.code
                      : 'ESS';
                }
              }
            },
            orElse: () {},
          );
    }

    // Calcul du volume 15°C : si température et densité sont présents, calculer, sinon afficher volume ambiant
    final vol15 = (temp != null && temp > 0 && dens != null && dens > 0)
        ? calcV15(volumeObserveL: volAmb, temperatureC: temp, densiteA15: dens)
        : volAmb;
    final isWide = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle Sortie')),
      body: busy
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Contexte
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Contexte'),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 12,
                            children: [
                              ChoiceChip(
                                label: const Text('MONALUXE'),
                                selected: _owner == OwnerType.monaluxe,
                                onSelected: (_) =>
                                    _onOwnerChange(OwnerType.monaluxe),
                              ),
                              ChoiceChip(
                                label: const Text('PARTENAIRE'),
                                selected: _owner == OwnerType.partenaire,
                                onSelected: (_) =>
                                    _onOwnerChange(OwnerType.partenaire),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_owner == OwnerType.monaluxe) ...[
                            const Text('Client *'),
                            const SizedBox(height: 8),
                            ref
                                .watch(clientsListProvider)
                                .when(
                                  data: (list) => DropdownButton<String>(
                                    isExpanded: true,
                                    value: clientId,
                                    hint: const Text('Sélectionner un client'),
                                    items: list
                                        .map<DropdownMenuItem<String>>(
                                          (c) => DropdownMenuItem(
                                            value: c['id'] as String,
                                            child: Text(c['nom'] as String),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (v) =>
                                        setState(() => clientId = v),
                                  ),
                                  loading: () =>
                                      const LinearProgressIndicator(),
                                  error: (e, _) => Text(
                                    'Erreur clients: $e',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                    ),
                                  ),
                                ),
                          ],
                          if (_owner == OwnerType.partenaire) ...[
                            const Text('Partenaire *'),
                            const SizedBox(height: 8),
                            ref
                                .watch(partenairesListProvider)
                                .when(
                                  data: (list) => DropdownButton<String>(
                                    isExpanded: true,
                                    value: partenaireId,
                                    hint: const Text(
                                      'Sélectionner un partenaire',
                                    ),
                                    items: list
                                        .map<DropdownMenuItem<String>>(
                                          (p) => DropdownMenuItem(
                                            value: p['id'] as String,
                                            child: Text(p['nom'] as String),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (v) =>
                                        setState(() => partenaireId = v),
                                  ),
                                  loading: () =>
                                      const LinearProgressIndicator(),
                                  error: (e, _) => Text(
                                    'Erreur partenaires: $e',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                    ),
                                  ),
                                ),
                          ],
                          const SizedBox(height: 12),
                          // Date de sortie
                          const Text('Date de sortie *'),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime.now().subtract(
                                  const Duration(days: 30),
                                ),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 30),
                                ),
                              );
                              if (picked != null) {
                                setState(() => _selectedDate = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Date de sortie',
                                suffixIcon: Icon(Icons.calendar_today),
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildProduitCiterneCard(ref, produitCode, volAmb),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Mesures
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildMesuresCard(volAmb, vol15, temp, dens),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: _buildLogistiqueCard()),
                      ],
                    )
                  else ...[
                    _buildMesuresCard(volAmb, vol15, temp, dens),
                    const SizedBox(height: 12),
                    _buildLogistiqueCard(),
                  ],
                  const SizedBox(height: 76),
                ],
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton.icon(
            icon: busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check),
            label: const Text('Enregistrer la sortie'),
            onPressed:
                (_canSubmit &&
                    !busy &&
                    _formKey.currentState?.validate() == true)
                ? _submitSortie
                : null,
          ),
        ),
      ),
    );
  }

  // 🚨 PROD-LOCK: Logique validation soumission - DO NOT MODIFY
  // Le bouton "Enregistrer la sortie" est actif si et seulement si:
  // - Produit sélectionné (_selectedProduitId != null)
  // - Citerne sélectionnée (_selectedCiterneId != null)
  // - Propriétaire valide (MONALUXE avec clientId ou PARTENAIRE avec partenaireId)
  // - Index avant >= 0
  // - Index après > index avant
  // - Température non-null et > 0 (OBLIGATOIRE)
  // - Densité non-null et > 0 (OBLIGATOIRE)
  // Si cette logique est modifiée, mettre à jour:
  // - Tests E2E (si applicable)
  // - Validation service (sortie_service.dart)
  bool get _canSubmit {
    final avant = _num(ctrlAvant.text) ?? -1;
    final apres = _num(ctrlApres.text) ?? -1;
    final temp = _num(ctrlTemp.text);
    final dens = _num(ctrlDens.text);
    final okOwner = isMonaluxe
        ? (clientId != null && clientId!.isNotEmpty)
        : (partenaireId != null && partenaireId!.isNotEmpty);
    return _selectedProduitId != null &&
        _selectedCiterneId != null &&
        okOwner &&
        avant >= 0 &&
        apres > avant &&
        temp != null &&
        temp > 0 && // Température obligatoire et > 0
        dens != null &&
        dens > 0; // Densité obligatoire et > 0
  }

  Widget _buildProduitCiterneCard(
    WidgetRef ref,
    String effProdCode,
    double volAmb,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Produit & Citerne'),
        const SizedBox(height: 8),
        _ProduitChips(
          selectedId: _selectedProduitId,
          enabled: true,
          onSelected: (pid) {
            setState(() {
              _selectedProduitId = pid;
              _selectedCiterneId =
                  null; // reset citerne au changement de produit
            });
          },
        ),
        const SizedBox(height: 8),
        ref
            .watch(refs.citernesActivesProvider)
            .when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Erreur citernes: $e'),
              data: (list) {
                // Filtrer par produit
                final pid = _selectedProduitId;
                final filtered = (pid == null)
                    ? <refs.CiterneRef>[]
                    : list.where((c) => c.produitId == pid).toList();
                // Pré-sélection automatique si une seule citerne
                if (filtered.length == 1 && _selectedCiterneId == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted)
                      setState(() => _selectedCiterneId = filtered.first.id);
                  });
                }
                if (filtered.isEmpty) {
                  return const Text(
                    'Aucune citerne active disponible pour ce produit',
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Citerne *'),
                    const SizedBox(height: 4),
                    for (final c in filtered)
                      RadioListTile<String>(
                        dense: true,
                        value: c.id,
                        groupValue: _selectedCiterneId,
                        onChanged: (v) =>
                            setState(() => _selectedCiterneId = v),
                        title: Text(
                          '${c.nom.isNotEmpty ? c.nom : c.id.substring(0, 8)}',
                        ),
                        subtitle: Text(
                          'Capacité ${c.capaciteTotale.toStringAsFixed(0)} L | Sécurité ${c.capaciteSecurite.toStringAsFixed(0)} L',
                        ),
                      ),
                  ],
                );
              },
            ),
      ],
    );
  }

  // 🚨 PROD-LOCK: Structure formulaire Mesures & Calculs - DO NOT MODIFY
  // Le formulaire DOIT contenir exactement 4 TextField obligatoires:
  // 1. Index avant (ctrlAvant)
  // 2. Index après (ctrlApres)
  // 3. Température (°C) (ctrlTemp)
  // 4. Densité @15°C (ctrlDens)
  // Si cette structure est modifiée, mettre à jour:
  // - Tests E2E (si applicable)
  // - Documentation UI
  Widget _buildMesuresCard(
    double volAmb,
    double vol15,
    double? temp,
    double? dens,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mesures & Calculs'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: ctrlAvant,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Index avant *',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'L\'index avant est obligatoire';
                      }
                      final num = _num(value);
                      if (num == null || num < 0) {
                        return 'L\'index avant doit être un nombre positif';
                      }
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: ctrlApres,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Index après *',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'L\'index après est obligatoire';
                      }
                      final num = _num(value);
                      if (num == null || num < 0) {
                        return 'L\'index après doit être un nombre positif';
                      }
                      final avant = _num(ctrlAvant.text) ?? 0;
                      if (num <= avant) {
                        return 'L\'index après doit être supérieur à l\'index avant';
                      }
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: ctrlTemp,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Température (°C) *',
                      helperText: 'Obligatoire pour calcul volume 15°C',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'La température est obligatoire';
                      }
                      final num = _num(value);
                      if (num == null || num <= 0) {
                        return 'La température doit être un nombre positif';
                      }
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: ctrlDens,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Densité @15°C *',
                      helperText:
                          'Obligatoire pour calcul volume 15°C (0.7 - 1.1)',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'La densité est obligatoire';
                      }
                      final num = _num(value);
                      if (num == null || num <= 0) {
                        return 'La densité doit être un nombre positif';
                      }
                      if (num < 0.7 || num > 1.1) {
                        return 'La densité doit être entre 0.7 et 1.1';
                      }
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('• Volume ambiant = ${volAmb.toStringAsFixed(2)} L'),
            if (temp != null && temp > 0 && dens != null && dens > 0)
              Text('• Volume corrigé 15°C ≈ ${vol15.toStringAsFixed(2)} L')
            else
              Text(
                '• Volume corrigé 15°C : Saisissez température et densité',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogistiqueCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Logistique'),
            const SizedBox(height: 8),
            TextField(
              controller: ctrlChauffeur,
              decoration: const InputDecoration(
                labelText: 'Chauffeur (optionnel)',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: ctrlPlaqueCamion,
                    decoration: const InputDecoration(
                      labelText: 'Plaque camion (optionnel)',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: ctrlPlaqueRemorque,
                    decoration: const InputDecoration(
                      labelText: 'Plaque remorque (optionnel)',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: ctrlTransporteur,
              decoration: const InputDecoration(
                labelText: 'Transporteur (optionnel)',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: ctrlNote,
              decoration: const InputDecoration(labelText: 'Note (optionnel)'),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProduitChips extends ConsumerWidget {
  final String? selectedId;
  final bool enabled;
  final ValueChanged<String> onSelected;

  const _ProduitChips({
    required this.selectedId,
    required this.enabled,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final produitsAsync = ref.watch(refs.produitsRefProvider);
    return produitsAsync.when(
      loading: () => const LinearProgressIndicator(minHeight: 2),
      error: (e, _) => Text('Erreur chargement produits: $e'),
      data: (prods) {
        final actifs = prods.toList()
          ..sort((a, b) {
            final sa = (a.code.isNotEmpty ? a.code : a.nom);
            final sb = (b.code.isNotEmpty ? b.code : b.nom);
            return sa.compareTo(sb);
          });
        if (actifs.isEmpty) {
          return const Text('Aucun produit disponible');
        }
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in actifs)
              ChoiceChip(
                label: Text('${p.code.trim()} · ${p.nom}'),
                selected: p.id == selectedId,
                onSelected: !enabled
                    ? null
                    : (sel) {
                        if (sel) {
                          onSelected(p.id);
                        }
                      },
              ),
          ],
        );
      },
    );
  }
}
