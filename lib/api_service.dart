import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static String baseUrl =
      'https://script.google.com/macros/s/AKfycbz7Va0uQdA5KJwIObSEX5Hbt0Ff9fTYgQm8GmyBhy7bS3ioyd72jPXkrPae-4Uirfbw/exec';

  static String sheetId =
      '1dEVzYCCZPvOCuq45EYXMkkFiKpmcfFkGm7m8jXtwM00';

  static Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    baseUrl = prefs.getString('apps_script_url') ?? baseUrl;
    sheetId = prefs.getString('google_sheet_id') ??
        '1dEVzYCCZPvOCuq45EYXMkkFiKpmcfFkGm7m8jXtwM00';
  }

  static Future<void> saveSettings({required String url, required String id}) async {
    final prefs = await SharedPreferences.getInstance();
    baseUrl = url.trim();
    sheetId = id.trim();
    await prefs.setString('apps_script_url', baseUrl);
    await prefs.setString('google_sheet_id', sheetId);
  }

  /// Apps Script answers a POST to /exec with a 302 redirect to
  /// script.googleusercontent.com. Dart's http.post does not follow
  /// redirects for POST, so we follow them manually with a GET.
  static Future<http.Response> _postFollowingRedirects(
      String url, String body) async {
    final client = http.Client();
    try {
      final req = http.Request('POST', Uri.parse(url))
        ..followRedirects = false
        ..headers['Content-Type'] = 'text/plain;charset=utf-8'
        ..body = body;

      var streamed = await client.send(req).timeout(const Duration(seconds: 60));
      var response = await http.Response.fromStream(streamed);

      var hops = 0;
      while ((response.statusCode == 301 ||
              response.statusCode == 302 ||
              response.statusCode == 303 ||
              response.statusCode == 307 ||
              response.statusCode == 308) &&
          hops < 5) {
        final location = response.headers['location'];
        if (location == null || location.isEmpty) break;
        response = await client
            .get(Uri.parse(location))
            .timeout(const Duration(seconds: 60));
        hops++;
      }
      return response;
    } finally {
      client.close();
    }
  }

  static Future<Map<String, dynamic>> request(
    Map<String, dynamic> data, {
    bool includeSheet = true,
  }) async {
    if (baseUrl.contains('PASTE_YOUR')) {
      throw Exception('Please set the Google Apps Script Web App URL in Settings.');
    }

    final payload = Map<String, dynamic>.from(data);
    if (includeSheet && sheetId.trim().isNotEmpty) {
      payload['sheetId'] = sheetId.trim();
    }

    final response = await _postFollowingRedirects(baseUrl, jsonEncode(payload));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('[build 2] Server error: HTTP ${response.statusCode} from ${response.request?.url.host}');
    }

    final result = jsonDecode(response.body);
    if (result is! Map<String, dynamic>) {
      throw Exception('Invalid server response.');
    }
    if (result['success'] == false) {
      throw Exception(result['error']?.toString() ?? result['message']?.toString() ?? 'Request failed.');
    }
    return result;
  }

  static Future<Map<String, dynamic>> validateSheet(String value) {
    return request({'action': 'validateSheet', 'sheetUrl': value}, includeSheet: false);
  }

  static Future<Map<String, dynamic>> getConfig() => request({'action': 'getConfig'});

  static Future<Map<String, dynamic>> saveShelves(List<String> shelves) =>
      request({'action': 'saveShelves', 'shelves': shelves});

  static Future<Map<String, dynamic>> getNextStockNumber() =>
      request({'action': 'getNextStockNumber'});

  static Future<Map<String, dynamic>> checkStockNumber(String stockNumber) =>
      request({'action': 'checkStockNumber', 'stockNumber': stockNumber});

  static Future<Map<String, dynamic>> checkBarcode(String barcode) =>
      request({'action': 'checkBarcode', 'barcode': barcode});

  static Future<Map<String, dynamic>> getBookMetadata(String isbn) =>
      request({'action': 'getBookMetadata', 'isbn': isbn}, includeSheet: false);

  static Future<Map<String, dynamic>> generateCallNumber({
    required String category,
    required String author,
    required String title,
  }) => request({
        'action': 'generateCallNumber',
        'category': category,
        'author': author,
        'title': title,
      });

  static Future<Map<String, dynamic>> addBook(Map<String, dynamic> book) =>
      request({'action': 'addBook', 'book': book});

  static Future<Map<String, dynamic>> searchBooks(String query) =>
      request({'action': 'searchBooks', 'query': query});

  static Future<Map<String, dynamic>> updateBook(Map<String, dynamic> book) =>
      request({'action': 'updateBook', 'stockNumber': book['Stock Number'], 'book': book});
}
