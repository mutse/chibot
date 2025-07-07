import 'dart:convert';
import 'package:http/http.dart' as http;

class WebSearchService {
  final String apiKey;
  final String? bingApiKey;
  WebSearchService({required this.apiKey, this.bingApiKey});

  /// Returns a summary string from Tavily web search for the given query.
  Future<String> searchWeb(String query) async {
    final url = Uri.parse('https://api.tavily.com/search');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };
    final body = jsonEncode({
      'query': query,
      'search_depth': 'advanced',
      'include_answer': true,
      'include_raw_content': false,
      'include_images': false,
      'max_results': 3,
    });
    final response = await http.post(url, headers: headers, body: body);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['answer'] != null && data['answer'].toString().isNotEmpty) {
        return data['answer'];
      } else if (data['results'] != null &&
          data['results'] is List &&
          data['results'].isNotEmpty) {
        // Fallback: concatenate titles and snippets
        return (data['results'] as List)
            .map((item) => item['title'] + ': ' + (item['content'] ?? ''))
            .join('\n');
      } else {
        return 'No relevant web search results found.';
      }
    } else {
      throw Exception(
        'Tavily API error: ${response.statusCode} ${response.body}',
      );
    }
  }

  /// Returns a summary string from Bing Web Search API for the given query.
  Future<String> searchBing(String query) async {
    if (bingApiKey == null || bingApiKey!.isEmpty) {
      throw Exception('Bing API Key is not set.');
    }
    final url = Uri.parse(
      'https://api.bing.microsoft.com/v7.0/search?q=${Uri.encodeComponent(query)}',
    );
    final headers = {'Ocp-Apim-Subscription-Key': bingApiKey!};
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['webPages'] != null &&
          data['webPages']['value'] is List &&
          data['webPages']['value'].isNotEmpty) {
        // Concatenate top 3 results
        final results = (data['webPages']['value'] as List)
            .take(3)
            .map((item) {
              final title = item['name'] ?? '';
              final snippet = item['snippet'] ?? '';
              return '$title: $snippet';
            })
            .join('\n');
        return results;
      } else {
        return 'No relevant Bing search results found.';
      }
    } else {
      throw Exception(
        'Bing API error: \\${response.statusCode} \\${response.body}',
      );
    }
  }
}
