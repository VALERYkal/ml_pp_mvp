import 'package:flutter/widgets.dart';

/// Clés UI stables pour tests & sélecteurs.
/// ⚠️ Ne pas renommer les valeurs string pour éviter les régressions.
@immutable
class UiKeys {
  const UiKeys._();

  // Actions
  static const Key sortieSave = Key('sortie.save');
  static const Key sortieSubmit = Key('sortie.submit');

  // Sections
  static const Key sortieSectionInfos         = Key('sortie.section.infos');         // "Informations générales"
  static const Key sortieSectionBeneficiaire  = Key('sortie.section.beneficiaire');  // "Bénéficiaire"
  static const Key sortieSectionProduit       = Key('sortie.section.produit');
  static const Key sortieSectionQuantites     = Key('sortie.section.quantites');
  static const Key sortieSectionTransport     = Key('sortie.section.transport');
  static const Key sortieSectionRecap         = Key('sortie.section.recap');
  static const Key sortieSectionNote          = Key('sortie.section.note');

  // Inputs (form fields)
  static const Key inputClient         = Key('sortie.input.client');
  static const Key inputPartenaire     = Key('sortie.input.partenaire');
  static const Key inputBeneficiaire   = Key('sortie.input.beneficiaireNom');
  static const Key inputProduit        = Key('sortie.input.produit');
  static const Key inputCiterne        = Key('sortie.input.citerne');
  static const Key inputIndexAvant     = Key('sortie.input.indexAvant');
  static const Key inputIndexApres     = Key('sortie.input.indexApres');
  static const Key inputTemperature    = Key('sortie.input.temperature');
  static const Key inputDensite        = Key('sortie.input.densite');
  static const Key inputVolumeV15      = Key('sortie.input.volumeV15');
  static const Key inputDate           = Key('sortie.input.date');
  static const Key inputNote           = Key('sortie.input.note');
  static const Key inputChauffeur      = Key('sortie.input.chauffeur');
  static const Key inputPlaqueCamion   = Key('sortie.input.plaqueCamion');
  static const Key inputTransporteur   = Key('sortie.input.transporteur');

  // Selectors / lists
  static const Key selectorProduit     = Key('sortie.selector.produit');
  static const Key selectorClient      = Key('sortie.selector.client');
  static const Key selectorPartenaire  = Key('sortie.selector.partenaire');
  static const Key selectorCiterne     = Key('sortie.selector.citerne');

  // Feedback / états
  static const Key errorBanner         = Key('sortie.feedback.error');
  static const Key successBanner       = Key('sortie.feedback.success');
  static const Key loadingIndicator    = Key('sortie.loading');
}