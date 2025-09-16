// 📌 Module : Cours de Route - Utils
// 🧑 Auteur : Valery Kalonga
// 📅 Date : 2025-09-15
// 🧭 Description : Raccourcis clavier pour le module cours de route

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget wrapper pour gérer les raccourcis clavier dans le module cours de route
class CoursRouteKeyboardShortcuts extends StatelessWidget {
  final Widget child;
  final VoidCallback? onNew;
  final VoidCallback? onRefresh;
  final VoidCallback? onSearch;
  final VoidCallback? onEscape;

  const CoursRouteKeyboardShortcuts({
    super.key,
    required this.child,
    this.onNew,
    this.onRefresh,
    this.onSearch,
    this.onEscape,
  });

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        // Ctrl+N : Nouveau cours
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN): const _NewCoursIntent(),
        
        // Ctrl+R : Rafraîchir
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyR): const _RefreshIntent(),
        
        // Ctrl+F : Focus recherche
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF): const _SearchIntent(),
        
        // Escape : Fermer modales/annuler
        LogicalKeySet(LogicalKeyboardKey.escape): const _EscapeIntent(),
        
        // F5 : Rafraîchir (alternative)
        LogicalKeySet(LogicalKeyboardKey.f5): const _RefreshIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _NewCoursIntent: _NewCoursAction(onNew),
          _RefreshIntent: _RefreshAction(onRefresh),
          _SearchIntent: _SearchAction(onSearch),
          _EscapeIntent: _EscapeAction(onEscape),
        },
        child: child,
      ),
    );
  }
}

/// Intents pour les raccourcis clavier
class _NewCoursIntent extends Intent {
  const _NewCoursIntent();
}

class _RefreshIntent extends Intent {
  const _RefreshIntent();
}

class _SearchIntent extends Intent {
  const _SearchIntent();
}

class _EscapeIntent extends Intent {
  const _EscapeIntent();
}

/// Actions pour les raccourcis clavier
class _NewCoursAction extends Action<_NewCoursIntent> {
  final VoidCallback? callback;

  _NewCoursAction(this.callback);

  @override
  Object? invoke(_NewCoursIntent intent) {
    callback?.call();
    return null;
  }
}

class _RefreshAction extends Action<_RefreshIntent> {
  final VoidCallback? callback;

  _RefreshAction(this.callback);

  @override
  Object? invoke(_RefreshIntent intent) {
    callback?.call();
    return null;
  }
}

class _SearchAction extends Action<_SearchIntent> {
  final VoidCallback? callback;

  _SearchAction(this.callback);

  @override
  Object? invoke(_SearchIntent intent) {
    callback?.call();
    return null;
  }
}

class _EscapeAction extends Action<_EscapeIntent> {
  final VoidCallback? callback;

  _EscapeAction(this.callback);

  @override
  Object? invoke(_EscapeIntent intent) {
    callback?.call();
    return null;
  }
}

/// Mixin pour faciliter l'utilisation des raccourcis dans les widgets
mixin CoursRouteKeyboardShortcutsMixin<T extends StatefulWidget> on State<T> {
  /// Focus node pour la recherche
  final FocusNode searchFocusNode = FocusNode();

  @override
  void dispose() {
    searchFocusNode.dispose();
    super.dispose();
  }

  /// Méthodes à override dans les classes qui utilisent ce mixin
  void onNewCours() {}
  void onRefresh() {}
  void onSearch() {
    // Focus par défaut sur le champ de recherche
    searchFocusNode.requestFocus();
  }
  void onEscape() {
    // Défocus par défaut
    FocusScope.of(context).unfocus();
  }

  /// Widget wrapper avec les raccourcis
  Widget buildWithShortcuts(Widget child) {
    return CoursRouteKeyboardShortcuts(
      onNew: onNewCours,
      onRefresh: onRefresh,
      onSearch: onSearch,
      onEscape: onEscape,
      child: child,
    );
  }
}

/// Widget d'aide pour afficher les raccourcis disponibles
class KeyboardShortcutsHelp extends StatelessWidget {
  const KeyboardShortcutsHelp({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Raccourcis clavier',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildShortcut('Ctrl+N', 'Nouveau cours'),
            _buildShortcut('Ctrl+R', 'Rafraîchir'),
            _buildShortcut('Ctrl+F', 'Rechercher'),
            _buildShortcut('F5', 'Rafraîchir'),
            _buildShortcut('Escape', 'Annuler/Fermer'),
          ],
        ),
      ),
    );
  }

  Widget _buildShortcut(String keys, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: Text(
              keys,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(description)),
        ],
      ),
    );
  }
}

/// Bouton d'aide pour les raccourcis
class KeyboardShortcutsHelpButton extends StatelessWidget {
  const KeyboardShortcutsHelpButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.keyboard),
      tooltip: 'Raccourcis clavier',
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Raccourcis clavier'),
            content: const KeyboardShortcutsHelp(),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fermer'),
              ),
            ],
          ),
        );
      },
    );
  }
}
