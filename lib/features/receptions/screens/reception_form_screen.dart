/* ===========================================================
   ML_PP MVP — ReceptionFormScreen (Stepper)
   Rôle: Écran 3 étapes pour créer un brouillon puis (si rôle)
   lancer la validation via RPC. Écran canonique du MVP.
   =========================================================== */
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ml_pp_mvp/shared/ui/toast.dart';
import 'package:ml_pp_mvp/shared/ui/errors.dart';
import 'package:ml_pp_mvp/core/errors/reception_validation_exception.dart';
import 'package:ml_pp_mvp/core/errors/reception_insert_exception.dart';

import 'package:ml_pp_mvp/shared/referentiels/referentiels.dart' as refs;
import 'package:ml_pp_mvp/shared/providers/ref_data_provider.dart' as rfd;
import 'package:ml_pp_mvp/shared/referentiels/role_provider.dart';
import 'package:ml_pp_mvp/shared/utils/volume_calc.dart';
import 'package:ml_pp_mvp/shared/utils/citerne_sorting.dart';
import 'package:ml_pp_mvp/features/receptions/data/reception_input.dart';
import 'package:ml_pp_mvp/features/receptions/data/reception_service.dart'
    show ReceptionService, receptionServiceProvider;
import 'package:ml_pp_mvp/features/receptions/widgets/cours_arrive_selector.dart';
import 'package:ml_pp_mvp/features/receptions/data/citerne_info_provider.dart';
import 'package:ml_pp_mvp/features/receptions/providers/receptions_list_provider.dart'
    show
        receptionsListProvider,
        receptionsPageProvider,
        receptionsPageSizeProvider;
import 'package:ml_pp_mvp/features/receptions/providers/receptions_table_provider.dart';
import 'package:ml_pp_mvp/shared/refresh/refresh_helpers.dart';
import 'package:ml_pp_mvp/features/cours_route/providers/cours_route_providers.dart'
    show
        coursDeRouteListProvider,
        coursDeRouteActifsProvider,
        coursDeRouteArrivesProvider;
import 'package:ml_pp_mvp/features/citernes/providers/citerne_providers.dart'
    show citernesWithStockProvider;
import 'package:ml_pp_mvp/features/receptions/widgets/partenaire_autocomplete.dart';
import 'package:ml_pp_mvp/features/cours_route/models/cours_de_route.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum OwnerType { monaluxe, partenaire }

class ReceptionFormScreen extends ConsumerStatefulWidget {
  final String? coursDeRouteId; // optionnel via route
  const ReceptionFormScreen({super.key, this.coursDeRouteId});
  @override
  ConsumerState<ReceptionFormScreen> createState() =>
      _ReceptionFormScreenState();
}

class _ReceptionFormScreenState extends ConsumerState<ReceptionFormScreen> {
  int step = 0;
  bool busy = false;

  String proprietaireType = 'MONALUXE';
  OwnerType _owner = OwnerType.monaluxe;
  String? partenaireId;
  String? selectedCoursId;
  String? produitCodeFromCours;
  String? produitIdFromCours; // pour payload
  CoursDeRoute? _selectedCours;
  String? get _selectedCoursId => _selectedCours?.id;
  String? _produitId;

  // Nouveau: état unifié produit/citerne
  String? _selectedProduitId;
  String? _selectedCiterneId;

  String? citerneId;
  String produitCode = 'ESS';
  final ctrlAvant = TextEditingController();
  final ctrlApres = TextEditingController();
  final ctrlTemp = TextEditingController(text: '15');
  final ctrlDens = TextEditingController(text: '0.83');
  final ctrlNote = TextEditingController();

  // plus de brouillon en MVP

  @override
  void dispose() {
    ctrlAvant.dispose();
    ctrlApres.dispose();
    ctrlTemp.dispose();
    ctrlDens.dispose();
    ctrlNote.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _owner = (proprietaireType == 'PARTENAIRE')
        ? OwnerType.partenaire
        : OwnerType.monaluxe;
    if (widget.coursDeRouteId != null && widget.coursDeRouteId!.isNotEmpty) {
      _loadCoursFromRoute(widget.coursDeRouteId!);
    }
  }

  Future<void> _loadCoursFromRoute(String id) async {
    try {
      final data = await Supabase.instance.client
          .from('cours_de_route')
          .select('*')
          .eq('id', id)
          .maybeSingle();
      if (data != null && mounted) {
        final c = CoursDeRoute.fromMap(Map<String, dynamic>.from(data));
        setState(() {
          _selectedCours = c;
          selectedCoursId = c.id;
          produitIdFromCours = c.produitId;
          _produitId = c.produitId;
          _selectedProduitId = c.produitId; // 🔐 verrou produit via CDR
          produitCodeFromCours = c.produitCode;
          if (produitCodeFromCours != null) {
            produitCode = produitCodeFromCours!;
          }
          _selectedCiterneId = null; // reset citerne
        });
      }
    } catch (_) {}
  }

  void _onOwnerChange(OwnerType val) {
    setState(() {
      _owner = val;
      proprietaireType = (val == OwnerType.monaluxe)
          ? 'MONALUXE'
          : 'PARTENAIRE';
      _selectedCiterneId = null;
      if (_owner == OwnerType.partenaire) {
        _selectedCours = null;
        selectedCoursId = null;
        _selectedProduitId = null; // en Partenaire, l'opérateur choisit
      } else {
        partenaireId = null;
        _selectedProduitId = _selectedCours?.produitId; // en Monaluxe, via CDR
      }
    });
  }

  void _onCoursSelected(CoursDeRoute c) {
    setState(() {
      _selectedCours = c;
      selectedCoursId = c.id;
      _produitId = c.produitId;
      produitIdFromCours = c.produitId;
      produitCodeFromCours = c.produitCode;
      if (produitCodeFromCours != null) {
        produitCode = produitCodeFromCours!;
      }
      _selectedProduitId = c.produitId; // 🔐 verrou produit
      _selectedCiterneId = null; // reset citerne
      partenaireId = null; // inactif en contexte CDR
    });
  }

  void _unlinkCours() {
    setState(() {
      _selectedCours = null;
      selectedCoursId = null;
      _selectedCiterneId = null;
      _selectedProduitId = (_owner == OwnerType.monaluxe)
          ? null
          : _selectedProduitId;
    });
  }

  double? _num(String s) => double.tryParse(
    s.replaceAll(RegExp(r'[^\d\-,\.]'), '').replaceAll(',', '.'),
  );
  bool get isMonaluxe => proprietaireType == 'MONALUXE';
  bool get isPartenaire => proprietaireType == 'PARTENAIRE';

  /// Vérifie si le rôle permet la validation
  bool canValidate(String role) {
    return ['admin', 'directeur', 'gerant'].contains(role.toLowerCase());
  }

  Future<void> _submitReception() async {
    // R-UX2 : Protection anti double-clic
    if (busy) return;

    // R-UX1 : Vérification globale - feedback clair si formulaire invalide
    if (_selectedProduitId == null ||
        _selectedCiterneId == null ||
        (isMonaluxe && (selectedCoursId ?? widget.coursDeRouteId) == null) ||
        (isPartenaire && (partenaireId == null || partenaireId!.isEmpty))) {
      showAppToast(
        context,
        'Veuillez corriger les champs en rouge avant de continuer.',
        type: ToastType.error,
      );
      return;
    }

    // validations minimales UI (messages individuels pour guider l'utilisateur)
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
    if (isMonaluxe && (selectedCoursId ?? widget.coursDeRouteId) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choisissez un cours "arrivé"')),
      );
      return;
    }
    if (isPartenaire && (partenaireId == null || partenaireId!.isEmpty)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Choisissez un partenaire')));
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
    // Cette validation UI doit correspondre à la validation service (reception_service.dart).
    // Si cette validation est modifiée, mettre à jour:
    // - Tests E2E (reception_flow_e2e_test.dart - vérifie 4 TextField obligatoires)
    // - Validation service (reception_service.dart)
    // - Documentation métier

    // Validation UI : température et densité obligatoires
    final temp = _num(ctrlTemp.text);
    final dens = _num(ctrlDens.text);
    if (temp == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La température ambiante (°C) est obligatoire'),
        ),
      );
      return;
    }
    if (dens == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La densité à 15°C est obligatoire')),
      );
      return;
    }
    final volAmb = computeVolumeAmbiant(avant, apres);
    // temp et dens sont garantis non-null par validation ci-dessus
    final vol15 = calcV15(
      volumeObserveL: volAmb,
      temperatureC: temp,
      densiteA15: dens,
    );

    setState(() => busy = true);
    try {
      await ref
          .read(receptionServiceProvider)
          .createValidated(
            coursDeRouteId: _owner == OwnerType.monaluxe
                ? (_selectedCoursId ?? widget.coursDeRouteId)
                : null,
            citerneId: _selectedCiterneId!,
            produitId: _selectedProduitId!, // ✅ source de vérité
            indexAvant: avant,
            indexApres: apres,
            temperatureCAmb: temp!, // Non-null garanti par validation UI
            densiteA15: dens!, // Non-null garanti par validation UI
            volumeCorrige15C: vol15,
            proprietaireType: _owner == OwnerType.monaluxe
                ? 'MONALUXE'
                : 'PARTENAIRE',
            partenaireId: _owner == OwnerType.partenaire ? partenaireId : null,
            dateReception: DateTime.now(),
            note: ctrlNote.text.isEmpty ? null : ctrlNote.text.trim(),
          );

      if (mounted) {
        // Toast utilisateur simple
        showAppToast(
          context,
          'Réception enregistrée avec succès.',
          type: ToastType.success,
        );
        // Invalidation KPI dashboard après réception validée
        invalidateDashboardKpisAfterStockMovement(ref);
        debugPrint(
          '🔄 KPI Refresh: invalidate dashboard KPI/Stocks after reception validated',
        );
        // Invalidate impacted providers (best-effort)
        try {
          ref.invalidate(receptionsListProvider);
          ref.invalidate(receptionsTableProvider);
        } catch (_) {}
        try {
          ref.invalidate(coursDeRouteListProvider);
          ref.invalidate(coursDeRouteActifsProvider);
          ref.invalidate(coursDeRouteArrivesProvider);
        } catch (_) {}
        try {
          ref.invalidate(citernesWithStockProvider);
        } catch (_) {}
        // Test-safe: certains widget tests montent l'écran sans MaterialApp.router
        final router = GoRouter.maybeOf(context);
        if (router != null) {
          router.go('/receptions');
        }
      }
    } on ReceptionValidationException catch (e) {
      // Erreur métier : afficher un message clair avec le champ concerné
      debugPrint(
        '[ReceptionForm] ReceptionValidationException: ${e.message} (field: ${e.field})',
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
    } on ReceptionInsertException catch (e) {
      // Erreur d'insertion Postgres mappée en message utilisateur
      debugPrint(
        '[ReceptionForm] ReceptionInsertException: ${e.toLogString()}',
      );
      if (mounted) {
        showAppToast(
          context,
          e.userMessage,
          type: ToastType.error,
          duration: const Duration(seconds: 5),
        );
      }
    } on PostgrestException catch (e, st) {
      // Fallback pour les PostgrestException non mappées
      debugPrint(
        '[ReceptionForm] PostgrestException: ${e.message} (code=${e.code}, hint=${e.hint}, details=${e.details})',
      );
      debugPrint('[ReceptionForm] stack=\n$st');
      if (mounted) {
        showAppToast(context, humanizePostgrest(e), type: ToastType.error);
      }
    } catch (e, st) {
      final error = e.toString();

      // Log détaillé pour diagnostic (console uniquement)
      debugPrint('[RECEPTION] Erreur détaillée: $error');
      debugPrint('[RECEPTION] Stack: $st');

      if (mounted) {
        // R-UX3 : Messages métier lisibles pour l'opérateur
        if (error.contains('receptions_check_produit_citerne')) {
          showAppToast(
            context,
            'Produit incompatible avec la citerne sélectionnée.\n'
            'Vérifiez que la citerne contient bien ce produit.',
            type: ToastType.error,
            duration: const Duration(seconds: 5),
          );
        } else if (error.contains('CDR_NON_ARRIVE') ||
            (error.contains('cours de route') && error.contains('ARRIVE'))) {
          showAppToast(
            context,
            'Ce cours de route n\'est pas encore en statut ARRIVE.\n'
            'Vous ne pouvez pas le décharger pour l\'instant.',
            type: ToastType.error,
            duration: const Duration(seconds: 5),
          );
        } else {
          // Message générique pour les autres erreurs
          showAppToast(
            context,
            'Une erreur est survenue. Veuillez réessayer.',
            type: ToastType.error,
          );
        }
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  // plus de validation séparée en MVP

  @override
  Widget build(BuildContext context) {
    final avant = _num(ctrlAvant.text) ?? 0;
    final apres = _num(ctrlApres.text) ?? 0;
    final temp = _num(ctrlTemp.text);
    final dens = _num(ctrlDens.text);
    final volAmb = computeVolumeAmbiant(avant, apres);
    final effProdCode = isMonaluxe
        ? (produitCodeFromCours ?? produitCode)
        : produitCode;
    // Calcul du volume 15°C : si température et densité sont présents, calculer, sinon afficher volume ambiant
    final vol15 = (temp != null && dens != null)
        ? calcV15(volumeObserveL: volAmb, temperatureC: temp, densiteA15: dens)
        : volAmb;
    final isWide = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle Réception')),
      body: busy
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _HeaderCoursHeader(
                  cours: _selectedCours,
                  fallbackId: widget.coursDeRouteId,
                  onUnlink:
                      (_owner == OwnerType.monaluxe && _selectedCours != null)
                      ? _unlinkCours
                      : null,
                ),
                const SizedBox(height: 12),
                // Propriété
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Propriété'),
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
                        if (_owner == OwnerType.partenaire) ...[
                          const SizedBox(height: 8),
                          PartenaireAutocomplete(
                            onSelected: (p) =>
                                setState(() => partenaireId = p.id),
                          ),
                        ],
                        if (_owner == OwnerType.monaluxe) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Sélectionner un CDR « Arrivé » (si non pré-rempli)',
                          ),
                          _CoursArriveSelector(
                            enabled: true,
                            onSelected: (item) {
                              _loadCoursFromRoute(item.id);
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Produit & Citerne + Mesures
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildProduitCiterneCard(
                          ref,
                          effProdCode,
                          volAmb,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMesuresCard(volAmb, vol15, temp, dens),
                      ),
                    ],
                  )
                else ...[
                  _buildProduitCiterneCard(ref, effProdCode, volAmb),
                  const SizedBox(height: 12),
                  _buildMesuresCard(volAmb, vol15, temp, dens),
                ],
                const SizedBox(height: 12),
                // Récap & Note
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Récapitulatif'),
                        Text('• Propriétaire : $proprietaireType'),
                        Text('• Citerne : ${_selectedCiterneId ?? '-'}'),
                        Text(
                          '• Index : ${ctrlAvant.text} → ${ctrlApres.text} (Δ = ${volAmb.toStringAsFixed(2)} L)',
                        ),
                        Text(
                          '• Temp/Dens : ${ctrlTemp.text} °C / ${ctrlDens.text}  →  V15 ≈ ${vol15.toStringAsFixed(2)} L',
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: ctrlNote,
                          decoration: const InputDecoration(
                            labelText: 'Note (optionnel)',
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 76),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton.icon(
            key: const Key('reception_submit_btn'),
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
            label: const Text('Enregistrer la réception'),
            onPressed: (_canSubmit && !busy) ? _submitReception : null,
          ),
        ),
      ),
    );
  }

  // 🚨 PROD-LOCK: Logique validation soumission - DO NOT MODIFY
  // Le bouton "Enregistrer la réception" est actif si et seulement si:
  // - Produit sélectionné (_selectedProduitId != null)
  // - Citerne sélectionnée (_selectedCiterneId != null)
  // - Propriétaire valide (MONALUXE ou PARTENAIRE avec partenaireId)
  // - Index avant >= 0
  // - Index après > index avant
  // - Température non-null (OBLIGATOIRE)
  // - Densité non-null (OBLIGATOIRE)
  // Si cette logique est modifiée, mettre à jour:
  // - Tests E2E (reception_flow_e2e_test.dart)
  // - Validation service (reception_service.dart)
  bool get _canSubmit {
    final avant = _num(ctrlAvant.text) ?? -1;
    final apres = _num(ctrlApres.text) ?? -1;
    final temp = _num(ctrlTemp.text);
    final dens = _num(ctrlDens.text);
    final okOwner = proprietaireType == 'MONALUXE'
        ? true
        : (partenaireId != null && partenaireId!.isNotEmpty);
    return _selectedProduitId != null &&
        _selectedCiterneId != null &&
        okOwner &&
        avant >= 0 &&
        apres > avant &&
        temp != null && // Température obligatoire
        dens != null; // Densité obligatoire
  }

  Widget _buildProduitCiterneCard(
    WidgetRef ref,
    String effProdCode,
    double volAmb,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Produit & Citerne'),
            const SizedBox(height: 8),
            KeyedSubtree(
              key: const Key('reception_produit_chips'),
              child: _ProduitChips(
                selectedId: _selectedProduitId,
                enabled:
                    _owner == OwnerType.partenaire, // Monaluxe => chip disabled
                onSelected: (pid) {
                  setState(() {
                    _selectedProduitId = pid;
                    _selectedCiterneId =
                        null; // reset citerne au changement de produit
                  });
                },
              ),
            ),
            const SizedBox(height: 8),
            ref
                .watch(refs.citernesActivesProvider)
                .when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Erreur citernes: $e'),
                  data: (list) {
                    // 1) Déterminer le produit pour filtrer les citernes
                    final pid = _selectedProduitId ?? _selectedCours?.produitId;
                    // 2) Filtrer
                    final filtered = (pid == null)
                        ? <refs.CiterneRef>[]
                        : list.where((c) => c.produitId == pid).toList();
                    // 2.5) Trier par numéro de citerne (TANK1, TANK2, ...)
                    final sortedCiternes = sortCiternesForReception(filtered);
                    // 3) Auto-select citerne when only one choice
                    // Pré-sélection automatique si une seule citerne disponible et aucune sélection manuelle existante
                    if (sortedCiternes.length == 1 && _selectedCiterneId == null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && _selectedCiterneId == null) {
                          setState(
                            () => _selectedCiterneId = sortedCiternes.first.id,
                          );
                        }
                      });
                    }
                    if (sortedCiternes.isEmpty) {
                      return const Text(
                        'Aucune citerne active disponible pour ce produit',
                      );
                    }
                    return KeyedSubtree(
                      key: const Key('reception_citerne_selector'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Citerne *'),
                          const SizedBox(height: 4),
                          for (final c in sortedCiternes)
                            RadioListTile<String>(
                              dense: true,
                              value: c.id,
                              groupValue: _selectedCiterneId,
                              onChanged: (v) =>
                                  setState(() => _selectedCiterneId = v),
                              title: Text(
                                '${c.nom.isNotEmpty ? c.nom : _shorten(c.id, 8)}',
                              ),
                              subtitle: Text(
                                'Capacité ${c.capaciteTotale.toStringAsFixed(0)} L | Sécurité ${c.capaciteSecurite.toStringAsFixed(0)} L',
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
            if (_selectedCiterneId != null) const SizedBox(height: 8),
            if (_selectedCiterneId != null)
              Builder(
                builder: (_) {
                  final pid = _selectedProduitId ?? _selectedCours?.produitId;
                  if (pid == null || pid.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return ref
                      .watch(
                        citerneQuickInfoProvider((
                          citerneId: _selectedCiterneId!,
                          produitId: pid,
                        )),
                      )
                      .maybeWhen(
                        data: (info) => info == null
                            ? const Text('Citerne inactive ou incompatible')
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Stock estimé: ${info.stockEstime.toStringAsFixed(0)} L',
                                  ),
                                  Text(
                                    'Dispo estimée après réception: ${(info.disponible - volAmb).toStringAsFixed(0)} L',
                                  ),
                                ],
                              ),
                        orElse: () => const SizedBox.shrink(),
                      );
                },
              ),
          ],
        ),
      ),
    );
  }

  // 🚨 PROD-LOCK: Structure formulaire Mesures & Calculs - DO NOT MODIFY
  // Le formulaire DOIT contenir exactement 4 TextField obligatoires:
  // 1. Index avant (ctrlAvant)
  // 2. Index après (ctrlApres)
  // 3. Température (°C) (ctrlTemp)
  // 4. Densité @15°C (ctrlDens)
  // Si cette structure est modifiée, mettre à jour:
  // - Tests E2E (reception_flow_e2e_test.dart - cherche 4 TextField)
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
                  child: TextField(
                    controller: ctrlAvant,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Index avant *',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: ctrlApres,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Index après *',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: ctrlTemp,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Température (°C) *',
                      helperText: 'Obligatoire pour calcul volume 15°C',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: ctrlDens,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Densité @15°C *',
                      helperText: 'Obligatoire pour calcul volume 15°C',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('• Volume ambiant = ${volAmb.toStringAsFixed(2)} L'),
            if (temp != null && dens != null)
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
}

// --- Mini widget header : affiche le contexte CDR + la date du jour ---
class _HeaderCoursChip extends StatelessWidget {
  final CoursDeRoute? cours;
  final String? fallbackId;
  const _HeaderCoursChip({super.key, this.cours, this.fallbackId});

  @override
  Widget build(BuildContext context) {
    // Date affichée en YYYY-MM-DD sans dépendre d'intl
    final dateStr = DateTime.now().toIso8601String().substring(0, 10);

    final chip = (cours != null)
        ? Chip(
            avatar: const Icon(Icons.local_shipping, size: 16),
            label: Text('CDR #${_shorten(cours!.id, 8)}'),
          )
        : (fallbackId != null && fallbackId!.isNotEmpty)
        ? Chip(
            avatar: const Icon(Icons.local_shipping, size: 16),
            label: Text('CDR #${_shorten(fallbackId!, 8)}'),
          )
        : const SizedBox.shrink();

    final detail = (cours != null)
        ? Text(
            '${_fmtDate(cours!.dateChargement)} • ${cours!.pays ?? "—"}'
            '  —  Fournisseur: ${cours!.fournisseurId.isNotEmpty ? _shorten(cours!.fournisseurId, 6) : "—"}'
            '  · Prod: ${(cours!.produitCode ?? "")} ${(cours!.produitNom ?? "")}'
            '  · Vol: ${_fmtVol(cours!.volume)}'
            '  · Camion: ${cours!.plaqueCamion ?? "—"}'
            '${(cours!.plaqueRemorque ?? "").isNotEmpty ? " / ${cours!.plaqueRemorque}" : ""}'
            '  · Transp: ${cours!.transporteur ?? "—"}',
          )
        : const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            chip,
            Chip(
              avatar: const Icon(Icons.event, size: 16),
              label: Text(dateStr),
            ),
          ],
        ),
        const SizedBox(height: 8),
        detail,
      ],
    );
  }
}

String _fmtVol(num? v) => v == null ? '—' : '${v.toStringAsFixed(0)} L';
String _fmtDate(DateTime? d) =>
    d == null ? '—' : d.toIso8601String().substring(0, 10);
String _shorten(String value, int maxLength) {
  if (value.isEmpty) {
    return value;
  }
  if (value.length <= maxLength) {
    return value;
  }
  return value.substring(0, maxLength);
}

// --- Nouveau header complet avec bouton Dissocier ---
class _HeaderCoursHeader extends ConsumerWidget {
  final CoursDeRoute? cours;
  final String? fallbackId;
  final VoidCallback? onUnlink;
  const _HeaderCoursHeader({
    super.key,
    this.cours,
    this.fallbackId,
    this.onUnlink,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateStr = DateTime.now().toIso8601String().substring(0, 10);

    String fournisseurNom = '—';
    String prodCode = cours?.produitCode ?? '';
    String prodNom = cours?.produitNom ?? '';

    if (cours != null) {
      ref
          .watch(rfd.refDataProvider)
          .maybeWhen(
            data: (cache) {
              // fournisseur nom
              fournisseurNom = rfd.resolveName(
                cache,
                cours!.fournisseurId,
                'fournisseur',
              );
              // produit: si code/nom manquent, tente via cache produits
              if (prodCode.isEmpty || prodNom.isEmpty) {
                final name = rfd.resolveName(
                  cache,
                  cours!.produitId,
                  'produit',
                );
                // derive code from produitCodes if possible
                final code = cache.produitCodes[cours!.produitId];
                if (prodCode.isEmpty && code != null && code.isNotEmpty) {
                  prodCode = code;
                }
                if (prodNom.isEmpty && name.isNotEmpty) {
                  prodNom = name;
                }
              }
            },
            orElse: () {},
          );
    }

    final chip = (cours != null)
        ? Chip(
            avatar: const Icon(Icons.local_shipping, size: 16),
            label: Text('CDR #${_shorten(cours!.id, 8)}'),
          )
        : (fallbackId != null && fallbackId!.isNotEmpty)
        ? Chip(
            avatar: const Icon(Icons.local_shipping, size: 16),
            label: Text('CDR #${_shorten(fallbackId!, 8)}'),
          )
        : const SizedBox.shrink();

    final detail = (cours != null)
        ? Text(
            '${_fmtDate(cours!.dateChargement)} • ${cours!.pays ?? "—"}'
            '  —  Fournisseur: $fournisseurNom'
            '  · Prod: $prodCode $prodNom'
            '  · Vol: ${_fmtVol(cours!.volume)}'
            '  · Camion: ${cours!.plaqueCamion ?? "—"}'
            '${(cours!.plaqueRemorque ?? "").isNotEmpty ? " / ${cours!.plaqueRemorque}" : ""}'
            '  · Transp: ${cours!.transporteur ?? "—"}',
          )
        : const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            chip,
            const Spacer(),
            Chip(
              avatar: const Icon(Icons.event, size: 16),
              label: Text(dateStr),
            ),
            if (onUnlink != null) ...[
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: onUnlink,
                icon: const Icon(Icons.link_off),
                label: const Text('Dissocier'),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        detail,
      ],
    );
  }
}

// Sélecteur simple basé sur le provider des CDR ARRIVE
class _CoursArriveSelector extends ConsumerWidget {
  final bool enabled;
  final ValueChanged<CoursDeRoute> onSelected;
  const _CoursArriveSelector({
    super.key,
    required this.enabled,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!enabled) {
      return const Opacity(
        opacity: .6,
        child: Text('Sélection CDR désactivée (Propriété = PARTENAIRE)'),
      );
    }

    final asyncCdR = ref.watch(coursDeRouteArrivesProvider);
    final fournisseurs = ref.watch(rfd.refDataProvider);

    // lookups id -> libellés produits via cache détaillé
    String fournisseurNameOf(String? id) {
      if (id == null || id.isEmpty) {
        return '—';
      }
      return fournisseurs.maybeWhen(
        data: (cache) => rfd.resolveName(cache, id, 'fournisseur'),
        orElse: () => '—',
      );
    }

    String produitCodeOf(String? id) {
      if (id == null || id.isEmpty) {
        return '';
      }
      return fournisseurs.maybeWhen(
        data: (cache) => cache.produitCodes[id] ?? '',
        orElse: () => '',
      );
    }

    String produitNomOf(String? id) {
      if (id == null || id.isEmpty) {
        return '';
      }
      return fournisseurs.maybeWhen(
        data: (cache) => rfd.resolveName(cache, id, 'produit'),
        orElse: () => '',
      );
    }

    String _fmtDate(DateTime? d) =>
        d == null ? '—' : d.toIso8601String().substring(0, 10);
    String _shorten(String value, int maxLength) {
      if (value.isEmpty) {
        return value;
      }
      if (value.length <= maxLength) {
        return value;
      }
      return value.substring(0, maxLength);
    }

    String titleOf(CoursDeRoute c) =>
        '#${_shorten(c.id, 8)} · ${_fmtDate(c.dateChargement)} · ${c.plaqueCamion ?? "---"}';
    String subtitleOf(CoursDeRoute c) {
      final fournisseurNom = fournisseurNameOf(c.fournisseurId);
      final code = c.produitCode?.isNotEmpty == true
          ? c.produitCode!
          : produitCodeOf(c.produitId);
      final nom = c.produitNom?.isNotEmpty == true
          ? c.produitNom!
          : produitNomOf(c.produitId);
      final rem = (c.plaqueRemorque ?? '').isNotEmpty
          ? ' / ${c.plaqueRemorque}'
          : '';
      final vol = c.volume == null ? '—' : '${c.volume!.toStringAsFixed(0)} L';
      final chf = (c.chauffeurNom ?? c.chauffeur ?? '').isNotEmpty
          ? ' · Chauff: ${(c.chauffeurNom ?? c.chauffeur)!}'
          : '';
      return '${c.pays ?? "—"} — Fournisseur: $fournisseurNom · Prod: $code $nom · '
          'Vol: $vol · Camion: ${c.plaqueCamion ?? "—"}$rem · Transp: ${c.transporteur ?? "—"}$chf';
    }

    return asyncCdR.when(
      loading: () => const LinearProgressIndicator(minHeight: 2),
      error: (e, _) => Text('Erreur chargement CDR: $e'),
      data: (items) {
        if (items.isEmpty) {
          return const Text('Aucun CDR au statut ARRIVE');
        }
        return DropdownButtonFormField<CoursDeRoute>(
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Sélectionner un CDR (ARRIVE)',
          ),
          items: items
              .map(
                (c) => DropdownMenuItem(
                  value: c,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titleOf(c),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitleOf(c),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          selectedItemBuilder: (ctx) => items
              .map(
                (c) => Text(
                  subtitleOf(c),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              )
              .toList(),
          onChanged: (c) => c != null ? onSelected(c) : null,
        );
      },
    );
  }
}

class _ProduitChips extends ConsumerWidget {
  final String? selectedId;
  final bool enabled;
  final ValueChanged<String> onSelected;

  const _ProduitChips({
    super.key,
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
