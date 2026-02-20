/// Modèle immuable pour une alerte intégrité (source: public.system_alerts).
/// Compatible v_integrity_checks (detected_at) et system_alerts (last_detected_at).
class IntegrityCheck {
  final String id;
  final String checkCode;
  final String severity;
  final String entityType;
  final String entityId;
  final String message;
  final Map<String, dynamic> payload;
  final String status;
  final DateTime detectedAt;
  final DateTime? acknowledgedAt;
  final DateTime? resolvedAt;

  const IntegrityCheck({
    required this.id,
    required this.checkCode,
    required this.severity,
    required this.entityType,
    required this.entityId,
    required this.message,
    required this.payload,
    required this.status,
    required this.detectedAt,
    this.acknowledgedAt,
    this.resolvedAt,
  });

  factory IntegrityCheck.fromMap(Map<String, dynamic> map) {
    final detectedRaw =
        map['last_detected_at'] ?? map['detected_at'];
    DateTime parsedDetected;
    if (detectedRaw == null) {
      parsedDetected = DateTime.now();
    } else if (detectedRaw is DateTime) {
      parsedDetected = detectedRaw;
    } else if (detectedRaw is String) {
      parsedDetected = DateTime.parse(detectedRaw);
    } else {
      parsedDetected = DateTime.now();
    }

    DateTime? parsedAck;
    final ackRaw = map['acknowledged_at'];
    if (ackRaw != null) {
      parsedAck = ackRaw is DateTime
          ? ackRaw
          : ackRaw is String
              ? DateTime.tryParse(ackRaw)
              : null;
    }

    DateTime? parsedResolved;
    final resRaw = map['resolved_at'];
    if (resRaw != null) {
      parsedResolved = resRaw is DateTime
          ? resRaw
          : resRaw is String
              ? DateTime.tryParse(resRaw)
              : null;
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
      id: map['id']?.toString() ?? '',
      checkCode: map['check_code'] as String? ?? '',
      severity: (map['severity'] as String? ?? '').toUpperCase(),
      entityType: map['entity_type'] as String? ?? '',
      entityId: map['entity_id']?.toString() ?? '',
      message: map['message'] as String? ?? '',
      payload: payloadMap,
      status: (map['status'] as String? ?? 'OPEN').toUpperCase(),
      detectedAt: parsedDetected,
      acknowledgedAt: parsedAck,
      resolvedAt: parsedResolved,
    );
  }

  bool get isOpen => status.toUpperCase() == 'OPEN';
  bool get isAck => status.toUpperCase() == 'ACK';
  bool get isResolved => status.toUpperCase() == 'RESOLVED';

  bool get canAck => isOpen;
  bool get canResolve => isOpen || isAck;

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
