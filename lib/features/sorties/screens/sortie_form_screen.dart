import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sortie_produit.dart';
import '../data/sortie_input.dart';
import '../providers/sortie_providers.dart';

class SortieFormScreen extends ConsumerStatefulWidget {
  const SortieFormScreen({super.key});

  @override
  ConsumerState<SortieFormScreen> createState() => _SortieFormScreenState();
}

class _SortieFormScreenState extends ConsumerState<SortieFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _produitId;
  String? _citerneId;
  String? _clientId;
  String? _partenaireId;
  double _indexAvant = 0;
  double _indexApres = 0;
  double? _tempC;
  double? _densite15;
  String? _chauffeur;
  String? _plaqueCamion;
  String? _plaqueRemorque;
  String? _transporteur;
  String? _note;

  @override
  Widget build(BuildContext context) {
    final produits = ref.watch(produitsListProvider);
    final partenaires = ref.watch(partenairesListProvider);
    final clients = ref.watch(clientsListProvider);
    final citernes = _produitId == null
        ? null
        : ref.watch(citernesByProduitProvider(_produitId!));

    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle sortie')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              produits.when(
                data: (items) => DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Produit'),
                  value: _produitId,
                  items: items
                      .map((e) => DropdownMenuItem(
                            value: e['id'],
                            child: Text(e['nom'] ?? ''),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _produitId = v),
                  validator: (v) => v == null ? 'Choisir un produit' : null,
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Erreur chargement produits'),
              ),
              const SizedBox(height: 12),
              if (_produitId != null)
                citernes!.when(
                  data: (items) => DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Citerne'),
                    value: _citerneId,
                    items: items
                        .map((e) => DropdownMenuItem(
                              value: e['id'],
                              child: Text(e['nom'] ?? ''),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _citerneId = v),
                    validator: (v) => v == null ? 'Choisir une citerne' : null,
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const Text('Erreur chargement citernes'),
                )
              else
                const Text('Sélectionnez d’abord un produit'),
              const SizedBox(height: 12),
              clients.when(
                data: (items) => DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Client (optionnel)'),
                  value: _clientId,
                  items: items
                      .map((e) => DropdownMenuItem(
                            value: e['id'],
                            child: Text(e['nom'] ?? ''),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _clientId = v),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Erreur chargement clients'),
              ),
              const SizedBox(height: 12),
              partenaires.when(
                data: (items) => DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Partenaire (optionnel)'),
                  value: _partenaireId,
                  items: items
                      .map((e) => DropdownMenuItem(
                            value: e['id'],
                            child: Text(e['nom'] ?? ''),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _partenaireId = v),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Erreur chargement partenaires'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Index avant'),
                keyboardType: TextInputType.number,
                onChanged: (v) => _indexAvant = double.tryParse(v) ?? 0,
                validator: (v) => (double.tryParse(v ?? '') ?? -1) < 0 ? '>= 0' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Index après'),
                keyboardType: TextInputType.number,
                onChanged: (v) => _indexApres = double.tryParse(v) ?? 0,
                validator: (v) => (double.tryParse(v ?? '') ?? -1) < 0 ? '>= 0' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Température (°C) (optionnel)'),
                keyboardType: TextInputType.number,
                onChanged: (v) => _tempC = double.tryParse(v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Densité à 15°C (optionnel)'),
                keyboardType: TextInputType.number,
                onChanged: (v) => _densite15 = double.tryParse(v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Chauffeur (optionnel)'),
                onChanged: (v) => _chauffeur = v.trim(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Plaque camion (optionnel)'),
                onChanged: (v) => _plaqueCamion = v.trim(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Plaque remorque (optionnel)'),
                onChanged: (v) => _plaqueRemorque = v.trim(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Transporteur (optionnel)'),
                onChanged: (v) => _transporteur = v.trim(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Note (optionnel)'),
                maxLines: 2,
                onChanged: (v) => _note = v,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                key: const Key('sortie_submit'),
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;
                  if (_produitId == null || _citerneId == null) return;
                  if (_clientId == null && _partenaireId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Client ou Partenaire requis')),
                    );
                    return;
                  }

                  try {
                    final input = SortieInput(
                      citerneId: _citerneId!,
                      produitId: _produitId!,
                      clientId: _clientId,
                      partenaireId: _partenaireId,
                      proprietaireType: 'MONALUXE', // Par défaut
                      indexAvant: _indexAvant,
                      indexApres: _indexApres,
                      temperatureC: _tempC,
                      densiteA15: _densite15,
                      note: _note,
                      dateSortie: DateTime.now(),
                      chauffeurNom: _chauffeur,
                      plaqueCamion: _plaqueCamion,
                      plaqueRemorque: _plaqueRemorque,
                      transporteur: _transporteur,
                    );
                    await ref.read(sortieDraftServiceProvider).createDraft(input);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Brouillon sortie créé')),
                      );
                      Navigator.of(context).pop();
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erreur: $e')),
                      );
                    }
                  }
                },
                child: const Text('Enregistrer'),
              )
            ],
          ),
        ),
      ),
    );
  }
}


