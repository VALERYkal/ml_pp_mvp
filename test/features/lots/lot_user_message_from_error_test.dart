import 'package:flutter_test/flutter_test.dart';
import 'package:ml_pp_mvp/features/lots/lot_user_message_from_error.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('mapLotUserMessage', () {
    test('lot non ouvert (rattacher, message complet toléré)', () {
      expect(
        mapLotUserMessage(
          Exception(
            "Impossible de rattacher un CDR à un lot qui n'est pas ouvert (statut du lot : cloture).",
          ),
        ),
        "Ce lot n'est plus modifiable.",
      );
    });

    test('lot non ouvert (détacher)', () {
      expect(
        mapLotUserMessage(
          Exception(
            "Impossible de détacher un CDR d'un lot qui n'est pas ouvert (statut du lot : facture).",
          ),
        ),
        "Ce lot n'est plus modifiable.",
      );
    });

    test('lot non ouvert (retirer)', () {
      expect(
        mapLotUserMessage(
          Exception(
            "Impossible de retirer un CDR d'un lot qui n'est pas ouvert (statut du lot : cloture).",
          ),
        ),
        "Ce lot n'est plus modifiable.",
      );
    });

    test('fournisseur incompatible', () {
      expect(
        mapLotUserMessage(
          Exception(
            'Impossible de rattacher : le fournisseur du CDR ne correspond pas à celui du lot.',
          ),
        ),
        'Ce camion ne peut pas être ajouté à ce lot car le fournisseur ne correspond pas.',
      );
    });

    test('produit incompatible', () {
      expect(
        mapLotUserMessage(
          Exception(
            'Impossible de rattacher : le produit du CDR ne correspond pas à celui du lot.',
          ),
        ),
        'Ce camion ne peut pas être ajouté à ce lot car le produit ne correspond pas.',
      );
    });

    test('CDR déchargé — liaison', () {
      expect(
        mapLotUserMessage(
          Exception(
            'Impossible de modifier le rattachement au lot pour un CDR au statut DECHARGE.',
          ),
        ),
        'Ce cours de route est déjà déchargé et ne peut plus être modifié.',
      );
    });

    test('transition de statut lot invalide', () {
      expect(
        mapLotUserMessage(
          Exception('Transition de statut lot invalide : cloture → ouvert'),
        ),
        "Cette action n'est pas autorisée pour le statut actuel du lot.",
      );
    });

    test('statut lot invalide', () {
      expect(
        mapLotUserMessage(Exception('Statut lot invalide : archive')),
        'Le statut du lot est invalide.',
      );
    });

    test('erreur inconnue → fallback', () {
      expect(
        mapLotUserMessage(Exception('constraint xyz violated')),
        kLotModuleGenericUserError,
      );
    });

    test('PostgrestException — message dans details', () {
      final e = PostgrestException(
        message: '',
        code: 'P0001',
        details: 'Impossible de rattacher : le produit du CDR ne correspond pas à celui du lot.',
        hint: null,
      );
      expect(
        mapLotUserMessage(e),
        'Ce camion ne peut pas être ajouté à ce lot car le produit ne correspond pas.',
      );
    });
  });

  group('extractLotBackendErrorText', () {
    test('Exception préfixe', () {
      expect(
        extractLotBackendErrorText(Exception('hello')),
        'hello',
      );
    });
  });
}
