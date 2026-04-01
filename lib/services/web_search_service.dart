import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/search_result.dart';

class WebSearchService {
  final String apiKey;
  WebSearchService({required this.apiKey});

  Future<Map<String, dynamic>> _fetchSearchResponse(String query) async {
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

    if (response.statusCode != 200) {
      throw Exception(
        'Tavily API error: ${response.statusCode} ${response.body}',
      );
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Executes a Tavily web search and returns normalized search results.
  Future<SearchResult> searchWebResult(String query) async {
    final data = await _fetchSearchResponse(query);
    return parseSearchResult(query, data);
  }

  /// Returns a summary string from Tavily web search for the given query.
  Future<String> searchWeb(String query) async {
    final data = await _fetchSearchResponse(query);
    return summarizeResponse(query, data);
  }

  static String summarizeResponse(String query, Map<String, dynamic> data) {
    final answer = data['answer']?.toString().trim();
    if (answer != null && answer.isNotEmpty) {
      return answer;
    }

    final result = parseSearchResult(query, data);
    if (result.items.isEmpty) {
      return 'No relevant web search results found.';
    }

    return result.items
        .map((item) => '${item.title}: ${item.snippet}')
        .join('\n');
  }

  static SearchResult parseSearchResult(
    String query,
    Map<String, dynamic> data,
  ) {
    final rawItems = data['results'] as List? ?? const [];
    final items =
        rawItems
            .whereType<Map>()
            .map(
              (item) => SearchItem(
                title: item['title']?.toString() ?? '',
                snippet:
                    item['content']?.toString() ??
                    item['snippet']?.toString() ??
                    '',
                link: item['url']?.toString() ?? item['link']?.toString() ?? '',
              ),
            )
            .toList();

    return SearchResult(
      items: items,
      query: SearchQuery(query: query),
      timestamp: DateTime.now(),
      totalResults: items.length,
      searchType: 'web',
    );
  }
}
