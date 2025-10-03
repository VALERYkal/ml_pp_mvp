/* ===========================================================
   ML_PP MVP — Modern Reception Form Provider
   Rôle: Provider Riverpod pour gérer l'état du formulaire moderne
   avec validation en temps réel et gestion d'erreurs élégante
   =========================================================== */
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/modern_reception_validation_service.dart';
import '../data/reception_service.dart';
import '../models/reception.dart';
import '../../cours_route/models/cours_de_route.dart';

/// État du formulaire de réception moderne
class ModernReceptionFormState {
  final int currentStep;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final String? successMessage;

  // Données du formulaire
  final String? ownerType;
  final String? coursDeRouteId;
  final String? partenaireId;
  final String? produitId;
  final String? citerneId;
  final double? indexAvant;
  final double? indexApres;
  final double? temperature;
  final double? densite;
  final String? note;

  // État de validation
  final Map<String, FieldValidationResult> fieldValidations;
  final ValidationResult? globalValidation;

  // Données de référence
  final List<CoursDeRoute> availableCours;
  final List<Map<String, dynamic>> availableProducts;
  final List<Map<String, dynamic>> availableTanks;
  final List<Map<String, dynamic>> availablePartenaires;

  // Cours sélectionné
  final CoursDeRoute? selectedCours;

  const ModernReceptionFormState({
    this.currentStep = 0,
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.successMessage,
    this.ownerType = 'MONALUXE',
    this.coursDeRouteId,
    this.partenaireId,
    this.produitId,
    this.citerneId,
    this.indexAvant,
    this.indexApres,
    this.temperature = 15.0,
    this.densite = 0.83,
    this.note,
    this.fieldValidations = const {},
    this.globalValidation,
    this.availableCours = const [],
    this.availableProducts = const [],
    this.availableTanks = const [],
    this.availablePartenaires = const [],
    this.selectedCours,
  });

  ModernReceptionFormState copyWith({
    int? currentStep,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    String? successMessage,
    String? ownerType,
    String? coursDeRouteId,
    String? partenaireId,
    String? produitId,
    String? citerneId,
    double? indexAvant,
    double? indexApres,
    double? temperature,
    double? densite,
    String? note,
    Map<String, FieldValidationResult>? fieldValidations,
    ValidationResult? globalValidation,
    List<CoursDeRoute>? availableCours,
    List<Map<String, dynamic>>? availableProducts,
    List<Map<String, dynamic>>? availableTanks,
    List<Map<String, dynamic>>? availablePartenaires,
    CoursDeRoute? selectedCours,
  }) {
    return ModernReceptionFormState(
      currentStep: currentStep ?? this.currentStep,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage ?? this.errorMessage,
      successMessage: successMessage ?? this.successMessage,
      ownerType: ownerType ?? this.ownerType,
      coursDeRouteId: coursDeRouteId ?? this.coursDeRouteId,
      partenaireId: partenaireId ?? this.partenaireId,
      produitId: produitId ?? this.produitId,
      citerneId: citerneId ?? this.citerneId,
      indexAvant: indexAvant ?? this.indexAvant,
      indexApres: indexApres ?? this.indexApres,
      temperature: temperature ?? this.temperature,
      densite: densite ?? this.densite,
      note: note ?? this.note,
      fieldValidations: fieldValidations ?? this.fieldValidations,
      globalValidation: globalValidation ?? this.globalValidation,
      availableCours: availableCours ?? this.availableCours,
      availableProducts: availableProducts ?? this.availableProducts,
      availableTanks: availableTanks ?? this.availableTanks,
      availablePartenaires: availablePartenaires ?? this.availablePartenaires,
      selectedCours: selectedCours ?? this.selectedCours,
    );
  }

  /// Vérifie si l'étape actuelle est valide
  bool isStepValid(int step) {
    switch (step) {
      case 0: // Propriétaire et source
        if (ownerType == 'MONALUXE') {
          return coursDeRouteId != null && coursDeRouteId!.isNotEmpty;
        } else {
          return partenaireId != null && partenaireId!.isNotEmpty;
        }
      case 1: // Produit et citerne
        return produitId != null &&
            produitId!.isNotEmpty &&
            citerneId != null &&
            citerneId!.isNotEmpty;
      case 2: // Mesures
        return indexAvant != null &&
            indexApres != null &&
            temperature != null &&
            densite != null &&
            indexApres! > indexAvant!;
      default:
        return false;
    }
  }

  /// Vérifie si le formulaire complet est valide
  bool get isFormValid {
    return isStepValid(0) && isStepValid(1) && isStepValid(2);
  }

  /// Retourne le cours sélectionné
  CoursDeRoute? get coursSelectionne {
    if (coursDeRouteId == null) return null;
    return availableCours.firstWhere(
      (c) => c.id == coursDeRouteId,
      orElse: () => selectedCours!,
    );
  }

  /// Retourne le produit sélectionné
  Map<String, dynamic>? get produitSelectionne {
    if (produitId == null) return null;
    return availableProducts.firstWhere(
      (p) => p['id'] == produitId,
      orElse: () => {},
    );
  }

  /// Retourne la citerne sélectionnée
  Map<String, dynamic>? get citerneSelectionnee {
    if (citerneId == null) return null;
    return availableTanks.firstWhere(
      (t) => t['id'] == citerneId,
      orElse: () => {},
    );
  }

  /// Retourne le partenaire sélectionné
  Map<String, dynamic>? get partenaireSelectionne {
    if (partenaireId == null) return null;
    return availablePartenaires.firstWhere(
      (p) => p['id'] == partenaireId,
      orElse: () => {},
    );
  }

  /// Calcule le volume brut
  double get volumeBrut {
    if (indexAvant == null || indexApres == null) return 0.0;
    return indexApres! - indexAvant!;
  }

  /// Calcule le volume à 15°C (approximation MVP)
  double get volume15c {
    return volumeBrut * 0.98; // Approximation MVP
  }
}

/// Notifier pour gérer l'état du formulaire moderne
class ModernReceptionFormNotifier
    extends StateNotifier<ModernReceptionFormState> {
  ModernReceptionFormNotifier() : super(const ModernReceptionFormState());

  /// Charge les données initiales
  Future<void> loadInitialData({String? coursDeRouteId}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Charger les cours de route disponibles
      final coursData = await Supabase.instance.client
          .from('cours_de_route')
          .select('*')
          .eq('statut', 'arrive')
          .order('created_at', ascending: false);

      final cours = coursData
          .map((data) => CoursDeRoute.fromMap(data))
          .toList();

      // Charger les produits disponibles
      final produitsData = await Supabase.instance.client
          .from('produits')
          .select('*')
          .eq('actif', true)
          .order('libelle');

      // Charger les citernes disponibles
      final citernesData = await Supabase.instance.client
          .from('citernes')
          .select('*, stocks_journaliers(stock_15c, capacity)')
          .eq('actif', true)
          .order('libelle');

      // Charger les partenaires disponibles
      final partenairesData = await Supabase.instance.client
          .from('partenaires')
          .select('*')
          .eq('actif', true)
          .order('nom');

      // Si un cours de route est fourni, le charger
      CoursDeRoute? selectedCours;
      if (coursDeRouteId != null && coursDeRouteId.isNotEmpty) {
        try {
          final coursData = await Supabase.instance.client
              .from('cours_de_route')
              .select('*')
              .eq('id', coursDeRouteId)
              .maybeSingle();

          if (coursData != null) {
            selectedCours = CoursDeRoute.fromMap(coursData);
          }
        } catch (e) {
          // Ignorer l'erreur si le cours n'existe pas
        }
      }

      state = state.copyWith(
        isLoading: false,
        availableCours: cours,
        availableProducts: produitsData,
        availableTanks: citernesData,
        availablePartenaires: partenairesData,
        coursDeRouteId: coursDeRouteId,
        selectedCours: selectedCours,
        produitId: selectedCours?.produitId,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Erreur lors du chargement des données: ${e.toString()}',
      );
    }
  }

  /// Met à jour le type de propriétaire
  void updateOwnerType(String ownerType) {
    state = state.copyWith(
      ownerType: ownerType,
      coursDeRouteId: ownerType == 'MONALUXE' ? state.coursDeRouteId : null,
      partenaireId: ownerType == 'PARTENAIRE' ? state.partenaireId : null,
      produitId: ownerType == 'MONALUXE'
          ? state.selectedCours?.produitId
          : null,
      citerneId: null,
      fieldValidations: {},
    );
  }

  /// Met à jour le cours de route sélectionné
  void updateCoursDeRoute(String? coursId) {
    final cours = state.availableCours.firstWhere(
      (c) => c.id == coursId,
      orElse: () => state.selectedCours!,
    );

    state = state.copyWith(
      coursDeRouteId: coursId,
      selectedCours: cours,
      produitId: cours.produitId,
      citerneId: null,
      fieldValidations: {},
    );
  }

  /// Met à jour le partenaire sélectionné
  void updatePartenaire(String? partenaireId) {
    state = state.copyWith(
      partenaireId: partenaireId,
      citerneId: null,
      fieldValidations: {},
    );
  }

  /// Met à jour le produit sélectionné
  void updateProduit(String? produitId) {
    state = state.copyWith(
      produitId: produitId,
      citerneId: null,
      fieldValidations: {},
    );
  }

  /// Met à jour la citerne sélectionnée
  void updateCiterne(String? citerneId) {
    state = state.copyWith(citerneId: citerneId, fieldValidations: {});
  }

  /// Met à jour un champ de mesure
  void updateMeasurementField(String field, double? value) {
    Map<String, FieldValidationResult> newValidations = Map.from(
      state.fieldValidations,
    );

    // Valider le champ
    final validation = ModernReceptionValidationService.validateField(
      fieldName: field,
      value: value,
    );
    newValidations[field] = validation;

    // Mettre à jour l'état
    switch (field) {
      case 'indexAvant':
        state = state.copyWith(
          indexAvant: value,
          fieldValidations: newValidations,
        );
        break;
      case 'indexApres':
        state = state.copyWith(
          indexApres: value,
          fieldValidations: newValidations,
        );
        break;
      case 'temperature':
        state = state.copyWith(
          temperature: value,
          fieldValidations: newValidations,
        );
        break;
      case 'densite':
        state = state.copyWith(
          densite: value,
          fieldValidations: newValidations,
        );
        break;
    }

    // Valider la cohérence globale si nécessaire
    if (field == 'indexAvant' || field == 'indexApres') {
      _validateGlobalConsistency();
    }
  }

  /// Valide la cohérence globale des indices
  void _validateGlobalConsistency() {
    if (state.indexAvant != null && state.indexApres != null) {
      Map<String, FieldValidationResult> newValidations = Map.from(
        state.fieldValidations,
      );

      if (state.indexApres! <= state.indexAvant!) {
        newValidations['indexApres'] = FieldValidationResult(
          isValid: false,
          message: 'L\'index après doit être supérieur à l\'index avant',
          type: ValidationType.error,
        );
      } else {
        final volumeBrut = state.indexApres! - state.indexAvant!;
        if (volumeBrut > 50000) {
          newValidations['volumeBrut'] = FieldValidationResult(
            isValid: true,
            message: 'Volume brut élevé (${volumeBrut.toStringAsFixed(0)} L)',
            type: ValidationType.warning,
          );
        }
      }

      state = state.copyWith(fieldValidations: newValidations);
    }
  }

  /// Met à jour la note
  void updateNote(String? note) {
    state = state.copyWith(note: note);
  }

  /// Passe à l'étape suivante
  void nextStep() {
    if (state.currentStep < 2 && state.isStepValid(state.currentStep)) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  /// Retourne à l'étape précédente
  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  /// Valide le formulaire complet
  ValidationResult validateForm() {
    final validation = ModernReceptionValidationService.validateReceptionData(
      ownerType: state.ownerType,
      coursDeRouteId: state.coursDeRouteId,
      partenaireId: state.partenaireId,
      produitId: state.produitId,
      citerneId: state.citerneId,
      indexAvant: state.indexAvant,
      indexApres: state.indexApres,
      temperature: state.temperature,
      densite: state.densite,
    );

    state = state.copyWith(globalValidation: validation);
    return validation;
  }

  /// Soumet la réception
  Future<String?> submitReception() async {
    final validation = validateForm();
    if (!validation.isValid) {
      state = state.copyWith(errorMessage: validation.primaryErrorMessage);
      return null;
    }

    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      final receptionService = ReceptionService.withClient(
        Supabase.instance.client,
        refRepo: ref.read(refs.referentielsRepoProvider),
      );

      final id = await receptionService.createValidated(
        coursDeRouteId: state.ownerType == 'MONALUXE'
            ? state.coursDeRouteId
            : null,
        citerneId: state.citerneId!,
        produitId: state.produitId!,
        indexAvant: state.indexAvant!,
        indexApres: state.indexApres!,
        temperatureCAmb: state.temperature,
        densiteA15: state.densite,
        volumeCorrige15C: state.volume15c,
        proprietaireType: state.ownerType!,
        partenaireId: state.ownerType == 'PARTENAIRE'
            ? state.partenaireId
            : null,
        dateReception: DateTime.now(),
        note: state.note,
      );

      state = state.copyWith(
        isSubmitting: false,
        successMessage: 'Réception enregistrée avec succès',
      );

      return id;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Erreur lors de l\'enregistrement: ${e.toString()}',
      );
      return null;
    }
  }

  /// Réinitialise le formulaire
  void resetForm() {
    state = const ModernReceptionFormState();
  }

  /// Efface les messages
  void clearMessages() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }
}

/// Provider pour l'état du formulaire moderne
final modernReceptionFormProvider =
    StateNotifierProvider<
      ModernReceptionFormNotifier,
      ModernReceptionFormState
    >((ref) {
      return ModernReceptionFormNotifier();
    });

/// Provider pour charger les données initiales
final modernReceptionFormDataProvider = FutureProvider<void>((ref) async {
  final notifier = ref.read(modernReceptionFormProvider.notifier);
  await notifier.loadInitialData();
});

/// Provider pour valider le formulaire
final modernReceptionFormValidationProvider = Provider<ValidationResult>((ref) {
  final state = ref.watch(modernReceptionFormProvider);
  return ModernReceptionValidationService.validateReceptionData(
    ownerType: state.ownerType,
    coursDeRouteId: state.coursDeRouteId,
    partenaireId: state.partenaireId,
    produitId: state.produitId,
    citerneId: state.citerneId,
    indexAvant: state.indexAvant,
    indexApres: state.indexApres,
    temperature: state.temperature,
    densite: state.densite,
  );
});
