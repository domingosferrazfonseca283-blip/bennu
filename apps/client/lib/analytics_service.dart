import 'dart:convert';

import 'package:http/http.dart' as http;

import 'analytics_models.dart';

class AnalyticsService {
  final String baseUrl;
  const AnalyticsService(this.baseUrl);

  Future<AnalyticsOverview> fetchOverview() async {
    final root = baseUrl.replaceFirst(RegExp(r'/+$'), '');
    final response = await http
        .get(Uri.parse('$root/api/v1/analytics/overview'))
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw Exception('API HTTP ${response.statusCode}');
    }
    return AnalyticsOverview.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }
}
