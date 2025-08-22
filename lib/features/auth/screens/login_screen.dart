// 📌 Module : Auth Feature - Login Screen
// 🧑 Auteur : Valery Kalonga
// 📅 Date : 2025-08-07
// 🗃️ Source SQL : Table `auth.users` + `public.profils`
// 🧭 Description : Écran de connexion avec gestion des rôles et redirection

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/user_role.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../profil/providers/profil_provider.dart';

/// Écran de connexion avec formulaire et gestion des rôles
/// 
/// Fonctionnalités :
/// - Formulaire de connexion (email + mot de passe)
/// - Validation des champs
/// - Gestion des erreurs Supabase
/// - Affichage du chargement
/// - Redirection selon le rôle utilisateur
/// - Design Material 3 responsive
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // Clé pour la validation du formulaire
  final _formKey = GlobalKey<FormState>();
  
  // Contrôleurs pour les champs de texte
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // État de chargement
  bool _isLoading = false;
  
  // État pour afficher/masquer le mot de passe
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Valide le format de l'email
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email requis';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Format d\'email invalide';
    }
    return null;
  }

  /// Valide le mot de passe
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Mot de passe requis';
    }
    return null;
  }

  /// Soumet le formulaire si valide
  void _submitIfValid() {
    if (_formKey.currentState?.validate() ?? false) {
      _handleLogin();
    }
  }

  /// Affiche un message d'erreur
  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Affiche un message de succès
  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// Gère la connexion de l'utilisateur
  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Récupération du service d'authentification
      final authService = ref.read(authServiceProvider);
      
      // Tentative de connexion
      await authService.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );

      // Récupération du profil utilisateur
      final profilAsync = await ref.read(profilProvider.future);
      
      if (profilAsync == null) {
        // Pas de profil trouvé
        _showError('Aucun profil trouvé pour cet utilisateur');
        return;
      }

      // Succès de connexion
      _showSuccess('Connexion réussie');
      
      // Redirection selon le rôle
      if (mounted) {
        _redirectToDashboard(profilAsync.role);
      }

    } on AuthException catch (e) {
      // Gestion des erreurs d'authentification
      _showError(_mapAuthError(e.message));
    } on PostgrestException catch (e) {
      // Gestion des erreurs Supabase (policies / RLS / schéma)
      _showError(_mapPostgrestError(e.message));
    } catch (e) {
      // Gestion des erreurs inattendues
      _showError('Erreur inattendue. Réessaie.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Redirige vers le dashboard approprié selon le rôle
  void _redirectToDashboard(UserRole role) {
    final route = UserRoleX.roleToHome(role);
    context.go(route);
  }

  /// Erreurs d'authentification (AuthException)
  String _mapAuthError(String? message) {
    final s = (message ?? '').toLowerCase();
    if (s.contains('invalid')) return 'Identifiants invalides';
    if (s.contains('email not confirmed')) return 'Email non confirmé';
    if (s.contains('network')) return 'Problème réseau';
    if (s.contains('too many requests')) return 'Trop de tentatives. Réessayez plus tard.';
    return 'Impossible de se connecter';
  }

  /// Erreurs base de données (PostgrestException)
  String _mapPostgrestError(String? message) {
    final m = message?.toLowerCase() ?? '';
    if (m.contains('permission denied')) {
      return 'Accès au profil refusé (policies RLS). Contactez l\'administrateur.';
    }
    if (m.contains('invalid input syntax for type uuid')) {
      return 'Profil introuvable ou identifiant utilisateur invalide.';
    }
    if (m.isEmpty) {
      return 'Erreur de connexion à la base. Réessayez.';
    }
    return 'Erreur de connexion à la base: $message';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar avec titre
      appBar: AppBar(
        title: const Text('Connexion ML_PP MVP'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        centerTitle: true,
      ),
      
      // Corps de l'écran
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo et titre
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Image.asset(
                        'lib/shared/assets/images/logo.png',
                        height: 120,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Bienvenue',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Connectez-vous à votre compte',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Champ email
                  TextFormField(
                    key: const Key('email'),
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'votre.email@exemple.com',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                      helperText: 'Entrez votre adresse email',
                    ),
                    validator: _validateEmail,
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 16),

                  // Champ mot de passe
                  TextFormField(
                    key: const Key('password'),
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submitIfValid(),
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      hintText: 'Votre mot de passe',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: const OutlineInputBorder(),
                      helperText: 'Appuyez sur Entrée pour vous connecter',
                    ),
                    validator: _validatePassword,
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 24),

                  // Bouton de connexion
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      key: const Key('login_button'),
                      onPressed: _isLoading ? null : _submitIfValid,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Se connecter',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Message d'aide
                  Text(
                    'Utilisez vos identifiants fournis par votre administrateur',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
