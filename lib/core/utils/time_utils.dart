import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class TimeUtils {
  static Future<void> init() async {
    await initializeDateFormatting('tr_TR', null);
  }

  /// 1) Tarihi “d MMM yyyy” formatında döndürür
  static String formatDate(DateTime date) {
    return DateFormat('d MMM yyyy', 'tr_TR').format(date);
  }

  /// 2) "kaç dakika önce" hesaplama
  static String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);

    if (diff.inSeconds < 60) return "${diff.inSeconds} saniye önce";
    if (diff.inMinutes < 60) return "${diff.inMinutes} dakika önce";
    if (diff.inHours < 24) return "${diff.inHours} saat önce";
    return "${diff.inDays} gün önce";
  }
}
