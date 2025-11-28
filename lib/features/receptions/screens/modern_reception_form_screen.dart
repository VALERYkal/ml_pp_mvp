/* ===========================================================
   ML_PP MVP — ModernReceptionFormScreen
   Rôle: Écran moderne avec design Material 3 et animations fluides
   pour créer une réception avec une UX/UI professionnelle
   =========================================================== */
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ml_pp_mvp/shared/ui/toast.dart';
import 'package:ml_pp_mvp/shared/ui/errors.dart';
import 'package:postgrest/postgrest.dart';

import 'package:ml_pp_mvp/shared/referentiels/referentiels.dart' as refs;
import 'package:ml_pp_mvp/shared/providers/ref_data_provider.dart' as rfd;
import 'package:ml_pp_mvp/shared/referentiels/role_provider.dart';
import 'package:ml_pp_mvp/shared/utils/volume_calc.dart';
import 'package:ml_pp_mvp/features/receptions/data/reception_input.dart';
import 'package:ml_pp_mvp/features/receptions/data/reception_service.dart';
import 'package:ml_pp_mvp/features/receptions/widgets/cours_arrive_selector.dart';
import 'package:ml_pp_mvp/features/receptions/data/citerne_info_provider.dart';
import 'package:ml_pp_mvp/features/receptions/providers/receptions_list_provider.dart' show receptionsListProvider, receptionsPageProvider, receptionsPageSizeProvider;
import 'package:ml_pp_mvp/features/receptions/providers/receptions_table_provider.dart';
import 'package:ml_pp_mvp/features/cours_route/providers/cours_route_providers.dart' show coursDeRouteListProvider, coursDeRouteActifsProvider, coursDeRouteArrivesProvider;
import 'package:ml_pp_mvp/features/citernes/providers/citerne_providers.dart' show citernesWithStockProvider;
import 'package:ml_pp_mvp/features/stocks_journaliers/providers/stocks_providers.dart' show stocksListProvider;
import 'package:ml_pp_mvp/features/receptions/widgets/partenaire_autocomplete.dart';
import 'package:ml_pp_mvp/features/cours_route/models/cours_de_route.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum OwnerType { monaluxe, partenaire }

class ModernReceptionFormScreen extends ConsumerStatefulWidget {
  final String? coursDeRouteId;
  const ModernReceptionFormScreen({super.key, this.coursDeRouteId});
  
  @override
  ConsumerState<ModernReceptionFormScreen> createState() => _ModernReceptionFormScreenState();
}

class _ModernReceptionFormScreenState extends ConsumerState<ModernReceptionFormScreen>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _progressController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _progressAnimation;
  
  // Form state
  int currentStep = 0;
  bool isLoading = false;
  bool isSubmitting = false;
  
  // Owner selection
  OwnerType _owner = OwnerType.monaluxe;
  String? partenaireId;
  String? selectedCoursId;
  String? produitCodeFromCours;
  String? produitIdFromCours;
  CoursDeRoute? _selectedCours;
  String? get _selectedCoursId => _selectedCours?.id;
  String? _produitId;
  
  // Product and tank selection
  String? _selectedProduitId;
  String? _selectedCiterneId;
  
  // Form controllers
  final ctrlAvant = TextEditingController();
  final ctrlApres = TextEditingController();
  final ctrlTemp = TextEditingController(text: '15');
  final ctrlDens = TextEditingController(text: '0.83');
  final ctrlNote = TextEditingController();
  
  // Form keys for validation
  final _formKey = GlobalKey<FormState>();
  final _stepKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
  ];
  
  // Validation state
  final Map<String, bool> _validationState = {};
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadInitialData();
  }
  
  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0.3, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
    
    // Start animations
    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
    _progressController.forward();
  }
  
  void _loadInitialData() {
    if (widget.coursDeRouteId != null && widget.coursDeRouteId!.isNotEmpty) {
      _loadCoursFromRoute(widget.coursDeRouteId!);
    }
  }
  
  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _progressController.dispose();
    ctrlAvant.dispose();
    ctrlApres.dispose();
    ctrlTemp.dispose();
    ctrlDens.dispose();
    ctrlNote.dispose();
    super.dispose();
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
          _selectedProduitId = c.produitId;
          produitCodeFromCours = c.produitCode;
          if (produitCodeFromCours != null) {
            // Update validation state
            _validationState['cours'] = true;
          }
          _selectedCiterneId = null;
        });
      }
    } catch (_) {}
  }
  
  void _onOwnerChange(OwnerType val) {
    setState(() {
      _owner = val;
      _selectedCiterneId = null;
      _validationState.clear();
      
      if (_owner == OwnerType.partenaire) {
        _selectedCours = null;
        selectedCoursId = null;
        _selectedProduitId = null;
      } else {
        partenaireId = null;
        _selectedProduitId = _selectedCours?.produitId;
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
        // Update validation state
        _validationState['cours'] = true;
      }
      _selectedProduitId = c.produitId;
      _selectedCiterneId = null;
      partenaireId = null;
    });
  }
  
  void _unlinkCours() {
    setState(() {
      _selectedCours = null;
      selectedCoursId = null;
      _selectedCiterneId = null;
      _selectedProduitId = (_owner == OwnerType.monaluxe) ? null : _selectedProduitId;
      _validationState.remove('cours');
    });
  }
  
  double? _num(String s) => double.tryParse(s.replaceAll(RegExp(r'[^\d\-,\.]'), '').replaceAll(',', '.'));
  bool get isMonaluxe => _owner == OwnerType.monaluxe;
  bool get isPartenaire => _owner == OwnerType.partenaire;
  
  bool canValidate(String role) {
    return ['admin', 'directeur', 'gerant'].contains(role.toLowerCase());
  }
  
  void _nextStep() {
    if (currentStep < 2) {
      setState(() {
        currentStep++;
      });
      _animateStepTransition();
    }
  }
  
  void _previousStep() {
    if (currentStep > 0) {
      setState(() {
        currentStep--;
      });
      _animateStepTransition();
    }
  }
  
  void _animateStepTransition() {
    _slideController.reset();
    _slideController.forward();
  }
  
  Future<void> _submitReception() async {
    if (!_validateForm()) return;
    
    setState(() => isSubmitting = true);
    
    try {
      final avant = _num(ctrlAvant.text) ?? 0;
      final apres = _num(ctrlApres.text) ?? 0;
      final temp = _num(ctrlTemp.text);
      final dens = _num(ctrlDens.text);
      final volAmb = computeVolumeAmbiant(avant, apres);
      final vol15 = calcV15(volumeObserveL: volAmb, temperatureC: temp ?? 15.0, densiteA15: dens ?? 0.83);
      
      final id = await ref.read(receptionServiceProvider).createValidated(
        coursDeRouteId: isMonaluxe ? (_selectedCoursId ?? widget.coursDeRouteId) : null,
        citerneId: _selectedCiterneId!,
        produitId: _selectedProduitId!,
        indexAvant: avant,
        indexApres: apres,
        temperatureCAmb: temp,
        densiteA15: dens,
        volumeCorrige15C: vol15,
        proprietaireType: isMonaluxe ? 'MONALUXE' : 'PARTENAIRE',
        partenaireId: isPartenaire ? partenaireId : null,
        dateReception: DateTime.now(),
        note: ctrlNote.text.isEmpty ? null : ctrlNote.text.trim(),
      );
      
      if (mounted) {
        // Success animation
        _scaleController.forward();
        
        // Show success message
        showAppToast(
          context, 
          'Réception enregistrée avec succès', 
          type: ToastType.success,
        );
        
        // Invalidate providers
        _invalidateProviders();
        
        // Navigate back
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) context.go('/receptions');
        });
      }
    } on PostgrestException catch (e, st) {
      debugPrint('[ModernReceptionForm] PostgrestException: ${e.message}');
      if (mounted) {
        showAppToast(context, humanizePostgrest(e), type: ToastType.error);
      }
    } catch (e, st) {
      debugPrint('[ModernReceptionForm] UnknownError: $e');
      if (mounted) {
        showAppToast(context, 'Erreur inattendue: ${e.toString()}', type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }
  
  bool _validateForm() {
    // Validate current step
    if (!_stepKeys[currentStep].currentState!.validate()) {
      return false;
    }
    
    // Additional business logic validation
    if (_selectedProduitId == null) {
      showAppToast(context, 'Sélectionnez un produit.', type: ToastType.warning);
      return false;
    }
    if (_selectedCiterneId == null) {
      showAppToast(context, 'Sélectionnez une citerne.', type: ToastType.warning);
      return false;
    }
    if (isMonaluxe && (selectedCoursId ?? widget.coursDeRouteId) == null) {
      showAppToast(context, 'Choisissez un cours "arrivé"', type: ToastType.warning);
      return false;
    }
    if (isPartenaire && (partenaireId == null || partenaireId!.isEmpty)) {
      showAppToast(context, 'Choisissez un partenaire', type: ToastType.warning);
      return false;
    }
    
    final avant = _num(ctrlAvant.text) ?? 0;
    final apres = _num(ctrlApres.text) ?? 0;
    if (apres <= avant) {
      showAppToast(context, 'Indices incohérents (après ≤ avant)', type: ToastType.warning);
      return false;
    }
    
    return true;
  }
  
  void _invalidateProviders() {
    try {
      ref.invalidate(receptionsListProvider);
      ref.invalidate(receptionsTableProvider);
      ref.invalidate(coursDeRouteListProvider);
      ref.invalidate(coursDeRouteActifsProvider);
      ref.invalidate(coursDeRouteArrivesProvider);
      ref.invalidate(citernesWithStockProvider);
      ref.invalidate(stocksListProvider);
    } catch (_) {}
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (currentStep + 1) / 3;
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _buildAppBar(theme),
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  _buildProgressIndicator(theme, progress),
                  Expanded(
                    child: _buildStepContent(theme),
                  ),
                  _buildNavigationButtons(theme),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        onPressed: () => context.go('/receptions'),
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: theme.colorScheme.onSurface,
        ),
      ),
      title: Text(
        'Nouvelle réception',
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurface,
        ),
      ),
      centerTitle: false,
      actions: [
        if (isSubmitting)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildProgressIndicator(ThemeData theme, double progress) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Étape ${currentStep + 1} sur 3',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).toInt()}%',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return LinearProgressIndicator(
                value: progress * _progressAnimation.value,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                minHeight: 8,
              );
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildStepContent(ThemeData theme) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _getStepWidget(theme),
    );
  }
  
  Widget _getStepWidget(ThemeData theme) {
    switch (currentStep) {
      case 0:
        return _buildStep1(theme);
      case 1:
        return _buildStep2(theme);
      case 2:
        return _buildStep3(theme);
      default:
        return _buildStep1(theme);
    }
  }
  
  Widget _buildStep1(ThemeData theme) {
    return SingleChildScrollView(
      key: const ValueKey('step1'),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _stepKeys[0],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader(
              theme,
              'Propriétaire et source',
              'Sélectionnez le propriétaire et la source de la réception',
              Icons.business_rounded,
              Colors.blue,
            ),
            const SizedBox(height: 24),
            _buildOwnerSelection(theme),
            const SizedBox(height: 24),
            if (isMonaluxe) _buildCoursSelection(theme),
            if (isPartenaire) _buildPartenaireSelection(theme),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStep2(ThemeData theme) {
    return SingleChildScrollView(
      key: const ValueKey('step2'),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _stepKeys[1],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader(
              theme,
              'Produit et citerne',
              'Sélectionnez le produit et la citerne de destination',
              Icons.inventory_2_rounded,
              Colors.green,
            ),
            const SizedBox(height: 24),
            _buildProductSelection(theme),
            const SizedBox(height: 24),
            _buildTankSelection(theme),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStep3(ThemeData theme) {
    return SingleChildScrollView(
      key: const ValueKey('step3'),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _stepKeys[2],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepHeader(
              theme,
              'Mesures et finalisation',
              'Saisissez les mesures et finalisez la réception',
              Icons.science_rounded,
              Colors.orange,
            ),
            const SizedBox(height: 24),
            _buildMeasurementsForm(theme),
            const SizedBox(height: 24),
            _buildSummaryCard(theme),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStepHeader(ThemeData theme, String title, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildOwnerSelection(ThemeData theme) {
    return _buildModernCard(
      theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Type de propriétaire',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildOwnerOption(
                  theme,
                  'Monaluxe',
                  'Réception interne',
                  Icons.business_rounded,
                  OwnerType.monaluxe,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildOwnerOption(
                  theme,
                  'Partenaire',
                  'Réception externe',
                  Icons.handshake_rounded,
                  OwnerType.partenaire,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildOwnerOption(ThemeData theme, String title, String subtitle, IconData icon, OwnerType type) {
    final isSelected = _owner == type;
    final color = isSelected ? theme.colorScheme.primary : theme.colorScheme.outline;
    
    return GestureDetector(
      onTap: () => _onOwnerChange(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? theme.colorScheme.primaryContainer.withOpacity(0.3)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ] : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCoursSelection(ThemeData theme) {
    return _buildModernCard(
      theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_shipping_rounded,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Cours de route',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CoursArriveSelector(
            onSelected: _onCoursSelected,
            selectedCours: _selectedCours,
            onUnlink: _unlinkCours,
          ),
        ],
      ),
    );
  }
  
  Widget _buildPartenaireSelection(ThemeData theme) {
    return _buildModernCard(
      theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.handshake_rounded,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Partenaire',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          PartenaireAutocomplete(
            onSelected: (id) {
              setState(() {
                partenaireId = id;
                _validationState['partenaire'] = id != null && id.isNotEmpty;
              });
            },
            selectedPartenaireId: partenaireId,
          ),
        ],
      ),
    );
  }
  
  Widget _buildProductSelection(ThemeData theme) {
    return _buildModernCard(
      theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_gas_station_rounded,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Produit',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Product selection logic here
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.3),
              ),
            ),
            child: Text(
              'Sélection du produit (à implémenter)',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTankSelection(ThemeData theme) {
    return _buildModernCard(
      theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.storage_rounded,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Citerne',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Tank selection logic here
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.3),
              ),
            ),
            child: Text(
              'Sélection de la citerne (à implémenter)',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMeasurementsForm(ThemeData theme) {
    return _buildModernCard(
      theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.science_rounded,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Mesures',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildModernTextField(
                  theme,
                  controller: ctrlAvant,
                  label: 'Index avant',
                  icon: Icons.remove_rounded,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Index avant requis';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildModernTextField(
                  theme,
                  controller: ctrlApres,
                  label: 'Index après',
                  icon: Icons.add_rounded,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Index après requis';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildModernTextField(
                  theme,
                  controller: ctrlTemp,
                  label: 'Température (°C)',
                  icon: Icons.thermostat_rounded,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Température requise';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildModernTextField(
                  theme,
                  controller: ctrlDens,
                  label: 'Densité à 15°C',
                  icon: Icons.scale_rounded,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Densité requise';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildModernTextField(
            theme,
            controller: ctrlNote,
            label: 'Note (optionnelle)',
            icon: Icons.note_rounded,
            maxLines: 3,
          ),
        ],
      ),
    );
  }
  
  Widget _buildSummaryCard(ThemeData theme) {
    return _buildModernCard(
      theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.summarize_rounded,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Résumé',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryItem(theme, 'Propriétaire', isMonaluxe ? 'Monaluxe' : 'Partenaire'),
          _buildSummaryItem(theme, 'Produit', 'ESS (à implémenter)'),
          _buildSummaryItem(theme, 'Citerne', 'Citerne A (à implémenter)'),
          _buildSummaryItem(theme, 'Volume brut', '${_num(ctrlApres.text) ?? 0 - _num(ctrlAvant.text) ?? 0} L'),
        ],
      ),
    );
  }
  
  Widget _buildSummaryItem(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildModernTextField(
    ThemeData theme, {
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.error,
          ),
        ),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest,
      ),
    );
  }
  
  Widget _buildModernCard(ThemeData theme, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
  
  Widget _buildNavigationButtons(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('Précédent'),
              ),
            ),
          if (currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: currentStep == 0 ? 1 : 1,
            child: ElevatedButton(
              onPressed: currentStep < 2 ? _nextStep : _submitReception,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
              child: isSubmitting
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.onPrimary),
                      ),
                    )
                  : Text(
                      currentStep < 2 ? 'Suivant' : 'Enregistrer',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
