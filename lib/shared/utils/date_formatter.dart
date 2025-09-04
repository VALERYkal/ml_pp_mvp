// 📌 Module : Shared Utils
// 🧭 Description : Utilitaires de formatage des dates

/// Utilitaires pour le formatage des dates
class DateFormatter {
  /// Formate une date en format YYYY-MM-DD
  /// 
  /// [date] : Date à formater (peut être String, DateTime, ou null)
  /// 
  /// Retourne :
  /// - `String` : Date formatée en YYYY-MM-DD
  /// - `'—'` : Si la date est null ou invalide
  static String formatDate(dynamic date) {
    if (date == null) return '—';
    
    try {
      final dt = DateTime.tryParse(date.toString());
      if (dt == null) return '—';
      
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return '—';
    }
  }

  /// Formate une date avec heure en format YYYY-MM-DD HH:MM
  /// 
  /// [date] : Date à formater
  /// 
  /// Retourne :
  /// - `String` : Date et heure formatées
  /// - `'—'` : Si la date est null ou invalide
  static String formatDateTime(dynamic date) {
    if (date == null) return '—';
    
    try {
      final dt = DateTime.tryParse(date.toString());
      if (dt == null) return '—';
      
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
             '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '—';
    }
  }

  /// Formate une date relative (ex: "il y a 2 jours")
  /// 
  /// [date] : Date à formater
  /// 
  /// Retourne :
  /// - `String` : Date relative
  /// - `'—'` : Si la date est null ou invalide
  static String formatRelativeDate(dynamic date) {
    if (date == null) return '—';
    
    try {
      final dt = DateTime.tryParse(date.toString());
      if (dt == null) return '—';
      
      final now = DateTime.now();
      final difference = now.difference(dt);
      
      if (difference.inDays > 0) {
        return 'il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
      } else if (difference.inHours > 0) {
        return 'il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
      } else if (difference.inMinutes > 0) {
        return 'il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
      } else {
        return 'à l\'instant';
      }
    } catch (e) {
      return '—';
    }
  }
}
