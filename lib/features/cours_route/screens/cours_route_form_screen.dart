// 📌 Module : Cours de Route - Screens
// 🧑 Auteur : Valery Kalonga
// 📅 Date : 2025-01-27
// 🧭 Description : Écran de formulaire pour créer ou modifier un cours de route

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ml_pp_mvp/features/cours_route/models/cours_de_route.dart';
import 'package:ml_pp_mvp/features/cours_route/providers/cours_route_providers.dart';
import 'package:ml_pp_mvp/features/cours_route/providers/cours_filters_provider.dart';
import 'package:ml_pp_mvp/shared/providers/ref_data_provider.dart';
import 'package:ml_pp_mvp/features/kpi/providers/cours_kpi_provider.dart';
import 'package:ml_pp_mvp/features/cours_route/utils/cours_route_constants.dart';
import 'package:ml_pp_mvp/shared/ui/toast.dart';
import 'package:ml_pp_mvp/shared/ui/dialogs.dart';

/// Écran de formulaire pour créer ou modifier un cours de route
///
/// Affiche un formulaire complet avec :
/// - Gestion des états asynchrones (loading, error, data)
/// - Validation des champs requis
/// - Protection dirty state
/// - Navigation vers la liste après création
///
/// Architecture :
/// - Utilise AsyncValue.when() pour gérer les états
/// - Validation immédiate avec autovalidateMode
/// - Protection contre perte de données avec WillPopScope
class CoursRouteFormScreen extends ConsumerStatefulWidget {
  const CoursRouteFormScreen({super.key, this.coursId});

  final String? coursId;

  @override
  ConsumerState<CoursRouteFormScreen> createState() =>
      _CoursRouteFormScreenState();
}

class _CoursRouteFormScreenState extends ConsumerState<CoursRouteFormScreen> {
  // Contrôleurs de formulaire
  final _formKey = GlobalKey<FormState>();
  final _plaqueController = TextEditingController();
  final _plaqueRemorqueController = TextEditingController();
  final _chauffeurController = TextEditingController();
  final _transporteurController = TextEditingController();
  final _volumeController = TextEditingController();
  final _noteController = TextEditingController();

  // Variables d'état
  String? selectedFournisseurId;
  String? selectedProduitId;
  String? depotDestinationId;
  String departPays = '';
  DateTime? dateChargement;
  bool isSaving = false;
  bool _dirty = false; // Protection contre perte de données
  CoursDeRoute? _initialCours; // Cours chargé en mode édition

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  @override
  void dispose() {
    _plaqueController.dispose();
    _plaqueRemorqueController.dispose();
    _chauffeurController.dispose();
    _transporteurController.dispose();
    _volumeController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final refDataAsync = ref.watch(refDataProvider);

    return PopScope(
      canPop: !_dirty,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await confirmAction(
          context,
          title: 'Annuler les modifications ?',
          message: 'Les changements non enregistrés seront perdus.',
          confirmLabel: 'Quitter',
        );
        if (shouldPop && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.coursId == null ? 'Nouveau cours' : 'Modifier le cours',
          ),
        ),
        body: refDataAsync.when(
          data: (refData) => _buildForm(refData),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Erreur lors du chargement des référentiels',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  e.toString(),
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
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
    );
  }

  /// Initialise le formulaire avec les valeurs par défaut
  void _initializeForm() {
    // Définir le produit par défaut (AGO)
    selectedProduitId = CoursRouteConstants.produitAgoId;

    // Date de chargement par défaut (aujourd'hui)
    dateChargement = DateTime.now();

    // Charger les données existantes si en mode édition
    if (widget.coursId != null) {
      _loadExistingCours();
    }
  }

  /// Construit le formulaire
  Widget _buildForm(RefDataCache refData) {
    // Initialiser le dépôt par défaut si pas encore fait
    if (depotDestinationId == null && refData.depots.isNotEmpty) {
      depotDestinationId = refData.depots.keys.first;
    }

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section Informations de base
          _buildSectionHeader('Informations de base'),

          // Fournisseur - Dropdown
          _buildFournisseurDropdown(refData),
          const SizedBox(height: 16),

          // Produit - Toggle ESS/AGO
          _buildProduitToggle(),
          const SizedBox(height: 16),

          // Dépôt destination - Lecture seule
          _buildDepotField(refData),
          const SizedBox(height: 16),

          // Pays de départ - Autocomplete
          _buildPaysAutocomplete(),
          const SizedBox(height: 16),

          // Date de chargement - DatePicker
          _buildDatePicker(),
          const SizedBox(height: 16),

          // Section Transport
          _buildSectionHeader('Transport'),

          // Plaque camion
          TextFormField(
            controller: _plaqueController,
            decoration: const InputDecoration(
              labelText: 'Plaque camion *',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.next,
            onChanged: (_) => _dirty = true,
            validator: (value) =>
                value?.trim().isEmpty == true ? 'Plaque camion requise' : null,
          ),
          const SizedBox(height: 16),

          // Plaque remorque (optionnel)
          TextFormField(
            controller: _plaqueRemorqueController,
            decoration: const InputDecoration(
              labelText: 'Plaque remorque',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.next,
            onChanged: (_) => _dirty = true,
          ),
          const SizedBox(height: 16),

          // Chauffeur
          TextFormField(
            controller: _chauffeurController,
            decoration: const InputDecoration(
              labelText: 'Chauffeur *',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.next,
            onChanged: (_) => _dirty = true,
            validator: (value) =>
                value?.trim().isEmpty == true ? 'Chauffeur requis' : null,
          ),
          const SizedBox(height: 16),

          // Transporteur (optionnel)
          TextFormField(
            controller: _transporteurController,
            decoration: const InputDecoration(
              labelText: 'Transporteur',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.next,
            onChanged: (_) => _dirty = true,
          ),
          const SizedBox(height: 16),

          // Volume
          TextFormField(
            controller: _volumeController,
            decoration: const InputDecoration(
              labelText: 'Volume (L) *',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            onChanged: (_) => _dirty = true,
            validator: (value) {
              if (value?.trim().isEmpty == true) return 'Volume requis';
              final parsed = double.tryParse(value!.replaceAll(',', '.'));
              if (parsed == null || parsed <= 0) return 'Volume invalide';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Note (optionnel)
          TextFormField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'Note',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            textInputAction: TextInputAction.done,
            onChanged: (_) => _dirty = true,
          ),
          const SizedBox(height: 16),

          // Statut (lecture seule)
          _buildStatutField(),
          const SizedBox(height: 32),

          // Bouton de soumission
          _buildSubmitButton(),
        ],
      ),
    );
  }

  /// Charge les données du cours existant si en mode édition
  Future<void> _loadExistingCours() async {
    if (widget.coursId == null) return;

    try {
      // Utiliser le service directement pour récupérer le cours
      final service = ref.read(coursDeRouteServiceProvider);
      final cours = await service.getById(widget.coursId!);

      if (cours != null) {
        setState(() {
          _initialCours = cours; // Stocker le cours initial
          selectedFournisseurId = cours.fournisseurId;
          selectedProduitId = cours.produitId;
          depotDestinationId = cours.depotDestinationId;
          _plaqueController.text = cours.plaqueCamion ?? '';
          _plaqueRemorqueController.text = cours.plaqueRemorque ?? '';
          _chauffeurController.text = cours.chauffeur ?? '';
          _transporteurController.text = cours.transporteur ?? '';
          _volumeController.text = cours.volume?.toString() ?? '';
          departPays = cours.pays ?? '';
          _noteController.text = cours.note ?? '';
          dateChargement = cours.dateChargement;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement cours: $e');
    }
  }

  /// Construit l'en-tête de section
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  /// Construit le dropdown fournisseur
  Widget _buildFournisseurDropdown(RefDataCache refData) {
    return DropdownButtonFormField<String>(
      value: selectedFournisseurId,
      decoration: const InputDecoration(
        labelText: 'Fournisseur *',
        border: OutlineInputBorder(),
      ),
      items: refData.fournisseurs.entries
          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
          .toList(),
      onChanged: (value) {
        setState(() {
          selectedFournisseurId = value;
          _dirty = true;
        });
      },
      validator: (value) => value == null ? 'Fournisseur requis' : null,
    );
  }

  /// Construit le toggle produit ESS/AGO (responsive)
  Widget _buildProduitToggle() {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Produit *',
        border: OutlineInputBorder(),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 600;

          if (isWide) {
            // Desktop/Tablet : côte à côte
            return Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Essence'),
                    value: CoursRouteConstants.produitEssId,
                    groupValue: selectedProduitId,
                    onChanged: (value) {
                      setState(() {
                        selectedProduitId = value;
                        _dirty = true;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Gasoil / AGO'),
                    value: CoursRouteConstants.produitAgoId,
                    groupValue: selectedProduitId,
                    onChanged: (value) {
                      setState(() {
                        selectedProduitId = value;
                        _dirty = true;
                      });
                    },
                  ),
                ),
              ],
            );
          } else {
            // Mobile : empilés verticalement
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  title: const Text('Essence'),
                  value: CoursRouteConstants.produitEssId,
                  groupValue: selectedProduitId,
                  onChanged: (value) {
                    setState(() {
                      selectedProduitId = value;
                      _dirty = true;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Gasoil / AGO'),
                  value: CoursRouteConstants.produitAgoId,
                  groupValue: selectedProduitId,
                  onChanged: (value) {
                    setState(() {
                      selectedProduitId = value;
                      _dirty = true;
                    });
                  },
                ),
              ],
            );
          }
        },
      ),
    );
  }

  /// Construit le champ dépôt (lecture seule)
  Widget _buildDepotField(RefDataCache refData) {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Dépôt destination',
        border: OutlineInputBorder(),
      ),
      child: Text(
        refData.depots[depotDestinationId] ?? CoursRouteConstants.depotDefault,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }

  /// Construit l'autocomplete pays
  Widget _buildPaysAutocomplete() {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return CoursRouteConstants.paysSuggestions;
        }
        return CoursRouteConstants.paysSuggestions
            .where(
              (pays) => pays.toLowerCase().contains(
                textEditingValue.text.toLowerCase(),
              ),
            )
            .toList();
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: const InputDecoration(
            labelText: 'Pays de départ *',
            border: OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.next,
          onChanged: (value) {
            setState(() {
              departPays = value;
              _dirty = true;
            });
          },
          validator: (value) =>
              value?.trim().isEmpty == true ? 'Pays requis' : null,
        );
      },
      onSelected: (String selection) {
        setState(() {
          departPays = selection;
          _dirty = true;
        });
      },
    );
  }

  /// Construit le date picker
  Widget _buildDatePicker() {
    final dateText = dateChargement != null
        ? '${dateChargement!.year}-${dateChargement!.month.toString().padLeft(2, '0')}-${dateChargement!.day.toString().padLeft(2, '0')}'
        : '';

    return TextFormField(
      readOnly: true,
      controller: TextEditingController(text: dateText),
      decoration: const InputDecoration(
        labelText: 'Date de chargement *',
        border: OutlineInputBorder(),
      ),
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: dateChargement ?? now,
          firstDate: DateTime(now.year - 1),
          lastDate: DateTime(now.year + 1),
        );
        if (picked != null) {
          setState(() {
            dateChargement = picked;
            _dirty = true;
          });
        }
      },
      validator: (value) => value?.isEmpty == true ? 'Date requise' : null,
    );
  }

  /// Construit le champ statut (lecture seule)
  Widget _buildStatutField() {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Statut',
        border: OutlineInputBorder(),
      ),
      child: Text(StatutCours.chargement.name.toUpperCase()),
    );
  }

  /// Construit le bouton de soumission
  Widget _buildSubmitButton() {
    final refDataAsync = ref.watch(refDataProvider);

    return ElevatedButton.icon(
      icon: isSaving
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.save),
      label: Text(isSaving ? 'Enregistrement...' : 'Enregistrer'),
      onPressed: (isSaving || refDataAsync.isLoading) ? null : _submitForm,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
      ),
    );
  }

  /// Soumet le formulaire
  Future<void> _submitForm() async {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      if (mounted) {
        showAppToast(
          context,
          'Veuillez corriger les champs en rouge avant de continuer.',
          type: ToastType.error,
        );
      }
      return;
    }

    setState(() => isSaving = true);

    try {
      final isEditing = widget.coursId != null;
      // Helpers
      double parseVolume(String s) => double.parse(s.replaceAll(',', '.'));
      String? emptyToNull(String? s) => (s?.trim().isEmpty ?? true) ? null : s;

      final cours = CoursDeRoute(
        id: isEditing
            ? widget.coursId!
            : '', // ID existant en édition, vide en création
        fournisseurId: selectedFournisseurId!,
        depotDestinationId: depotDestinationId!,
        produitId: selectedProduitId!,
        plaqueCamion: _plaqueController.text.trim(),
        plaqueRemorque: emptyToNull(_plaqueRemorqueController.text),
        chauffeur: _chauffeurController.text.trim(),
        transporteur: emptyToNull(_transporteurController.text),
        pays: departPays.trim(),
        dateChargement: dateChargement!,
        volume: parseVolume(_volumeController.text),
        statut: isEditing
            ? (_initialCours?.statut ?? StatutCours.chargement)
            : StatutCours.chargement, // Préserver le statut en édition
        note: emptyToNull(_noteController.text),
      );

      final service = ref.read(coursDeRouteServiceProvider);

      if (isEditing) {
        await service.update(cours);
        if (!mounted) return;
        showAppToast(
          context,
          'Cours mis à jour avec succès',
          type: ToastType.success,
        );
      } else {
        await service.create(cours);
        if (!mounted) return;
        showAppToast(
          context,
          'Cours créé avec succès',
          type: ToastType.success,
        );
      }

      // ► Invalider les providers de liste & filtres pour rafraîchir immédiatement
      ref.invalidate(coursDeRouteListProvider);
      ref.invalidate(coursDeRouteActifsProvider);
      ref.invalidate(filteredCoursProvider);

      // ► Invalider les providers KPI du dashboard pour mise à jour immédiate
      ref.invalidate(coursKpiProvider);

      context.go('/cours');
    } on PostgrestException catch (e) {
      if (!mounted) return;
      showAppToast(
        context,
        'Erreur Supabase: ${e.message}',
        type: ToastType.error,
      );
    } catch (e) {
      if (!mounted) return;
      showAppToast(context, 'Erreur: $e', type: ToastType.error);
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }
}
