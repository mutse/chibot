import 'dart:convert';
import 'package:http/http.dart' as http;

class WebSearchService {
  final String apiKey;
  WebSearchService({required this.apiKey});

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
        'Tavily API error:  {response.statusCode}  {response.body}',
      );
    }
  }
}
