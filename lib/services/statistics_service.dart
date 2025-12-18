import 'dart:convert';
import 'package:flutter/services.dart';

class StatisticsService {
  Future<Map<String, dynamic>> loadStatistics() async {
    final jsonString =
        await rootBundle.loadString('data/dashboard_summary.json');
    return jsonDecode(jsonString);
  }
}
