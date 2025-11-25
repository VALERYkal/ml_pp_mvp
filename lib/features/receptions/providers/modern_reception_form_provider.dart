/* ===========================================================
   ML_PP MVP  Modern Reception Form Provider
   Rôle: Provider Riverpod pour gérer l'état du formulaire moderne
   API: Notifier (Riverpod 2.x/3.x compatible)
   =========================================================== */
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// État du formulaire de réception moderne
class ModernReceptionFormState {
  const ModernReceptionFormState();

  /// Factory pour l'état initial
  factory ModernReceptionFormState.initial() =>
      const ModernReceptionFormState();

  /// CopyWith minimal pour compatibilité
  ModernReceptionFormState copyWith() => this;
}

/// Notifier pour gérer l'état du formulaire moderne
/// Utilise l'API Notifier moderne (pas StateNotifier)
class ModernReceptionFormNotifier extends Notifier<ModernReceptionFormState> {
  @override
  ModernReceptionFormState build() => ModernReceptionFormState.initial();

  /// Réinitialise l'état du formulaire
  void reset() => state = ModernReceptionFormState.initial();
}

/// Provider pour l'état du formulaire moderne
final modernReceptionFormProvider =
    NotifierProvider<ModernReceptionFormNotifier, ModernReceptionFormState>(
      ModernReceptionFormNotifier.new,
    );

