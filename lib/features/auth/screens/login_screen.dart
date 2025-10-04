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
import '../../../shared/providers/auth_service_provider.dart';
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

  // --- Palette douce locale (évite de toucher au thème global)
  static const Color _primary = Color(0xFF0E6377); // bleu canard bouton
  static const Color _primaryDark = Color(0xFF0A4C5A);
  static const Color _fieldFill = Color(0xFFF6F8FA); // fond champs
  static const Color _fieldStroke = Color(0xFFE1E7EC); // bord champs
  static const Color _hint = Color(0xFF8A98A5);

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

  // Snackbars cosmétiques (succès / erreur)
  void _showNiceSnack(BuildContext context, {required String message, required bool success}) {
    final bg = success ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final icon = success ? Icons.check_circle_rounded : Icons.error_rounded;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: bg,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  /// Affiche un message d'erreur
  void _showError(String message) {
    if (mounted) {
      _showNiceSnack(context, message: message, success: false);
    }
  }

  /// Affiche un message de succès
  void _showSuccess(String message) {
    if (mounted) {
      _showNiceSnack(context, message: message, success: true);
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
      await authService.signIn(_emailController.text.trim(), _passwordController.text);

      // Succès de connexion
      _showSuccess('Connexion réussie');

      // La redirection sera gérée par le router
      // qui attendra que le profil soit créé/récupéré
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
    final theme = Theme.of(context);
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
                  // --- Logo avec ombre douce (garde ton asset)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(color: Color(0x1A000000), blurRadius: 18, offset: Offset(0, 8)),
                        ],
                      ),
                      child: SizedBox(
                        height: 96,
                        child: Image.asset(
                          'lib/shared/assets/images/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Bienvenue',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: .2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Connectez-vous à votre compte',
                    style: theme.textTheme.bodyLarge?.copyWith(color: _hint),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Champ email
                  TextFormField(
                    key: const Key('email'),
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'votre.email@exemple.com',
                      prefixIcon: const Icon(Icons.mail_rounded, color: _hint),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: _fieldStroke),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: _fieldStroke),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: _primary),
                      ),
                      filled: true,
                      fillColor: _fieldFill,
                      hintStyle: TextStyle(color: _hint),
                      labelStyle: TextStyle(color: _hint),
                      // helperText: 'Entrez votre adresse email',
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
                      prefixIcon: const Icon(Icons.lock_rounded, color: _hint),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                          color: _hint,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: _fieldStroke),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: _fieldStroke),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: _primary),
                      ),
                      filled: true,
                      fillColor: _fieldFill,
                      hintStyle: TextStyle(color: _hint),
                      labelStyle: TextStyle(color: _hint),
                      // helperText: 'Appuyez sur Entrée pour vous connecter'.
                    ),
                    validator: _validatePassword,
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 24),

                  // --- Bouton principal
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      key: const Key('login_button'),
                      onPressed: _isLoading ? null : _submitIfValid,
                      style:
                          ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            foregroundColor: Colors.white,
                            elevation: 1.5,
                            shape: const StadiumBorder(),
                          ).copyWith(
                            overlayColor: MaterialStateProperty.all(_primaryDark.withOpacity(.12)),
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
                    style: theme.textTheme.bodySmall?.copyWith(color: _hint),
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
