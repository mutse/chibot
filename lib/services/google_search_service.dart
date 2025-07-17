import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'base_api_service.dart';
import '../models/search_result.dart';

class GoogleSearchService extends BaseApiService {
  static const String _baseUrl = 'https://www.googleapis.com/customsearch/v1';
  static const String _userAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36';
  
  final SearchProvider provider;
  final String searchEngineId;

  GoogleSearchService({
    required String apiKey,
    required this.searchEngineId,
    this.provider = SearchProvider.googleCustomSearch,
    Duration timeout = const Duration(seconds: 10),
    int maxRetries = 3,
  }) : super(
    baseUrl: _baseUrl,
    apiKey: apiKey,
    timeout: timeout,
    maxRetries: maxRetries,
  );

  @override
  String get providerName => provider.toString();

  @override
  Map<String, String> getHeaders() {
    return {
      'User-Agent': _userAgent,
      'Accept': 'application/json',
    };
  }

  @override
  void validateResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Request failed: ${response.statusCode} ${response.reasonPhrase}');
    }
  }

  Future<SearchResult> search(
    String query, {
    int count = 10,
    String? language,
    String? region,
    int startIndex = 1,
  }) async {
    return await _performSearch(
      query: query,
      searchType: 'web',
      count: count,
      language: language,
      region: region,
      startIndex: startIndex,
    );
  }

  Future<SearchResult> searchImages(
    String query, {
    int count = 10,
    String? language,
    String? region,
    int startIndex = 1,
  }) async {
    return await _performSearch(
      query: query,
      searchType: 'image',
      count: count,
      language: language,
      region: region,
      startIndex: startIndex,
    );
  }

  Future<SearchResult> _performSearch({
    required String query,
    required String searchType,
    required int count,
    String? language,
    String? region,
    required int startIndex,
  }) async {
    if (provider == SearchProvider.googleCustomSearch) {
      return await _searchWithCustomSearchAPI(
        query: query,
        searchType: searchType,
        count: count,
        language: language,
        region: region,
        startIndex: startIndex,
      );
    } else if (provider == SearchProvider.programmableSearch) {
      return await _searchWithProgrammableSearch(
        query: query,
        searchType: searchType,
        count: count,
        language: language,
        region: region,
        startIndex: startIndex,
      );
    } else {
      throw UnsupportedError('Search provider not supported: $provider');
    }
  }

  Future<SearchResult> _searchWithCustomSearchAPI({
    required String query,
    required String searchType,
    required int count,
    String? language,
    String? region,
    required int startIndex,
  }) async {
    try {
      final params = {
        'key': apiKey,
        'cx': searchEngineId,
        'q': query,
        'num': count.clamp(1, 10).toString(),
        'start': startIndex.toString(),
        'lr': language != null ? 'lang_$language' : null,
        'cr': region != null ? 'country$region' : null,
        'searchType': searchType == 'image' ? 'image' : null,
        'fields': 'items(title,link,snippet,displayLink,formattedUrl,pagemap),searchInformation(totalResults),queries',
      }..removeWhere((key, value) => value == null);

      final uri = Uri.parse(_baseUrl).replace(queryParameters: params);
      
      final response = await http.get(
        uri,
        headers: {
          'User-Agent': _userAgent,
          'Accept': 'application/json',
        },
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return SearchResult.fromJson(data);
      } else if (response.statusCode == 403) {
        throw Exception('API key is invalid or quota exceeded');
      } else if (response.statusCode == 429) {
        throw Exception('Rate limit exceeded');
      } else {
        throw Exception('Search failed: ${response.statusCode} ${response.reasonPhrase}');
      }
    } on SocketException catch (e) {
      throw Exception('Network error: ${e.message}');
    } on FormatException catch (e) {
      throw Exception('Invalid response format: ${e.message}');
    } catch (e) {
      throw Exception('Search error: ${e.toString()}');
    }
  }

  Future<SearchResult> _searchWithProgrammableSearch({
    required String query,
    required String searchType,
    required int count,
    String? language,
    String? region,
    required int startIndex,
  }) async {
    try {
      final params = {
        'q': query,
        'num': count.clamp(1, 10).toString(),
        'start': startIndex.toString(),
        'lr': language,
        'cr': region,
        'safe': 'active',
        'fields': 'items(title,link,snippet,displayLink,formattedUrl,pagemap),searchInformation(totalResults),queries',
      }..removeWhere((key, value) => value == null);

      final uri = Uri.parse('https://cse.google.com/cse').replace(queryParameters: params);
      
      final response = await http.get(
        uri,
        headers: {
          'User-Agent': _userAgent,
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        },
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final data = _parseProgrammableSearchResponse(response.body);
        return SearchResult.fromJson(data);
      } else {
        throw Exception('Search failed: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Search error: ${e.toString()}');
    }
  }

  Map<String, dynamic> _parseProgrammableSearchResponse(String html) {
    final searchResults = <SearchItem>[];
    
    final regex = RegExp(
      r'"title":"([^"]*)","link":"([^"]*)","snippet":"([^"]*)"',
      caseSensitive: false,
      multiLine: true,
    );
    
    final matches = regex.allMatches(html);
    for (final match in matches) {
      if (match.groupCount >= 3) {
        searchResults.add(SearchItem(
          title: _unescapeJsonString(match.group(1) ?? ''),
          link: _unescapeJsonString(match.group(2) ?? ''),
          snippet: _unescapeJsonString(match.group(3) ?? ''),
        ));
      }
    }
    
    return {
      'items': searchResults.map((item) => item.toJson()).toList(),
      'searchInformation': {
        'totalResults': searchResults.length.toString(),
      },
      'queries': {
        'request': [{'count': '10'}],
      },
    };
  }

  String _unescapeJsonString(String input) {
    return input
      .replaceAll(r'\u003c', '<')
      .replaceAll(r'\u003e', '>')
      .replaceAll(r'\u0026', '&')
      .replaceAll(r'\n', '\n')
      .replaceAll(r'\t', '\t')
      .replaceAll(r'\\', '\\')
      .replaceAll(r'\/', '/')
      .replaceAll(r'\"', '"')
      .replaceAll("'", "'");
  }

  Future<bool> validateConfiguration() async {
    try {
      if (apiKey.isEmpty || searchEngineId.isEmpty) {
        return false;
      }
      
      final result = await search('test', count: 1);
      return result.items.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  String getSearchUrl(String query, {String searchType = 'web'}) {
    if (provider == SearchProvider.googleCustomSearch) {
      return 'https://www.google.com/search?q=${Uri.encodeComponent(query)}';
    } else {
      return 'https://cse.google.com/cse?q=${Uri.encodeComponent(query)}';
    }
  }
}