/// Feature flags centralisés.
/// OFF par défaut pour garantir zéro impact PROD.
class FeatureFlags {
  final bool useAstm53b15c;

  const FeatureFlags({
    required this.useAstm53b15c,
  });

  /// Source unique: dart-define.
  /// Activation contrôlée via:
  /// --dart-define=USE_ASTM53B_15C=true
  static const FeatureFlags fromEnvironment = FeatureFlags(
    useAstm53b15c: bool.fromEnvironment(
      'USE_ASTM53B_15C',
      defaultValue: false,
    ),
  );
}
