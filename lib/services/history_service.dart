import 'package:shared_preferences/shared_preferences.dart';
import '../models/threat_report.dart';

class HistoryService {
  static const String _key = 'traceback_investigation_history';

  static Future<List<ThreatReport>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_key) ?? [];
    return rawList.map((item) {
      try {
        return ThreatReport.fromJson(item);
      } catch (_) {
        return null;
      }
    }).whereType<ThreatReport>().toList();
  }

  static Future<void> saveReport(ThreatReport report) async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_key) ?? [];
    rawList.insert(0, report.toJson());

    // Keep the most recent 50 reports locally
    if (rawList.length > 50) {
      rawList.removeRange(50, rawList.length);
    }
    await prefs.setStringList(_key, rawList);
  }

  static Future<void> deleteReport(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_key) ?? [];
    rawList.removeWhere((item) {
      try {
        return ThreatReport.fromJson(item).id == id;
      } catch (_) {
        return false;
      }
    });
    await prefs.setStringList(_key, rawList);
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
