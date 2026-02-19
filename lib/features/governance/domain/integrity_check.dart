/// Modèle immuable pour un check d'intégrité (source: public.v_integrity_checks).
class IntegrityCheck {
  final String checkCode;
  final String severity;
  final String entityType;
  final String entityId;
  final String message;
  final Map<String, dynamic> payload;
  final DateTime detectedAt;

  const IntegrityCheck({
    required this.checkCode,
    required this.severity,
    required this.entityType,
    required this.entityId,
    required this.message,
    required this.payload,
    required this.detectedAt,
  });

  factory IntegrityCheck.fromMap(Map<String, dynamic> map) {
    final detectedAtRaw = map['detected_at'];
    DateTime parsedDetectedAt;
    if (detectedAtRaw == null) {
      parsedDetectedAt = DateTime.now();
    } else if (detectedAtRaw is DateTime) {
      parsedDetectedAt = detectedAtRaw;
    } else if (detectedAtRaw is String) {
      parsedDetectedAt = DateTime.parse(detectedAtRaw);
    } else {
      parsedDetectedAt = DateTime.now();
    }

    final payloadRaw = map['payload'];
    final payloadMap = payloadRaw is Map<String, dynamic>
        ? Map<String, dynamic>.from(payloadRaw)
        : payloadRaw is Map
            ? Map<String, dynamic>.from(
                payloadRaw.map(
                  (k, v) => MapEntry(k.toString(), v),
                ),
              )
            : <String, dynamic>{};

    return IntegrityCheck(
      checkCode: map['check_code'] as String? ?? '',
      severity: (map['severity'] as String? ?? '').toUpperCase(),
      entityType: map['entity_type'] as String? ?? '',
      entityId: map['entity_id']?.toString() ?? '',
      message: map['message'] as String? ?? '',
      payload: payloadMap,
      detectedAt: parsedDetectedAt,
    );
  }

  bool get isCritical => severity.toUpperCase() == 'CRITICAL';
  bool get isWarn => severity.toUpperCase() == 'WARN';

  /// Rang métier pour le tri : CRITICAL=1, WARN=2, autre=3.
  static int severityRank(String s) {
    final upper = s.toUpperCase();
    return switch (upper) {
      'CRITICAL' => 1,
      'WARN' => 2,
      _ => 3,
    };
  }
}
