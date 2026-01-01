class StocksAdjustmentsException implements Exception {
  final String message;
  
  StocksAdjustmentsException(this.message);
  
  @override
  String toString() => message;
}

