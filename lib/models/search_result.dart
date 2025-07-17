class SearchResult {
  final List<SearchItem> items;
  final SearchQuery query;
  final DateTime timestamp;
  final int totalResults;
  final String? searchType;

  SearchResult({
    required this.items,
    required this.query,
    required this.timestamp,
    required this.totalResults,
    this.searchType,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List? ?? [])
        .map((item) => SearchItem.fromJson(item as Map<String, dynamic>))
        .toList();
    
    // Fix: handle totalResults as int or String
    dynamic totalResultsRaw = json['searchInformation']?['totalResults'];
    int totalResults;
    if (totalResultsRaw is int) {
      totalResults = totalResultsRaw;
    } else if (totalResultsRaw is String) {
      totalResults = int.tryParse(totalResultsRaw) ?? 0;
    } else {
      totalResults = 0;
    }

    return SearchResult(
      items: items,
      query: SearchQuery.fromJson(json['queries']?['request']?[0] ?? {}),
      timestamp: DateTime.now(),
      totalResults: totalResults,
      searchType: json['searchType'],
    );
  }

  Map<String, dynamic> toJson() => {
    'items': items.map((item) => item.toJson()).toList(),
    'queries': {
      'request': [query.toJson()],
    },
    'searchInformation': {
      'totalResults': totalResults.toString(),
    },
    'searchType': searchType,
  };
}

class SearchItem {
  final String title;
  final String snippet;
  final String link;
  final String? imageUrl;
  final String? displayLink;
  final String? formattedUrl;

  SearchItem({
    required this.title,
    required this.snippet,
    required this.link,
    this.imageUrl,
    this.displayLink,
    this.formattedUrl,
  });

  factory SearchItem.fromJson(Map<String, dynamic> json) {
    return SearchItem(
      title: json['title'] ?? '',
      snippet: json['snippet'] ?? '',
      link: json['link'] ?? '',
      imageUrl: json['pagemap']?['cse_image']?[0]?['src'] ?? 
                json['pagemap']?['metatags']?[0]?['og:image'],
      displayLink: json['displayLink'],
      formattedUrl: json['formattedUrl'],
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'snippet': snippet,
    'link': link,
    'displayLink': displayLink,
    'formattedUrl': formattedUrl,
    'pagemap': {
      'cse_image': imageUrl != null ? [{'src': imageUrl}] : null,
    },
  };
}

class SearchQuery {
  final String query;
  final String searchType;
  final int count;
  final String? language;
  final String? region;
  final int startIndex;

  SearchQuery({
    required this.query,
    this.searchType = 'web',
    this.count = 10,
    this.language,
    this.region,
    this.startIndex = 1,
  });

  factory SearchQuery.fromJson(Map<String, dynamic> json) {
    // Fix: handle count and startIndex as int or String
    dynamic countRaw = json['count'];
    int count;
    if (countRaw is int) {
      count = countRaw;
    } else if (countRaw is String) {
      count = int.tryParse(countRaw) ?? 10;
    } else {
      count = 10;
    }
    dynamic startIndexRaw = json['startIndex'];
    int startIndex;
    if (startIndexRaw is int) {
      startIndex = startIndexRaw;
    } else if (startIndexRaw is String) {
      startIndex = int.tryParse(startIndexRaw) ?? 1;
    } else {
      startIndex = 1;
    }
    return SearchQuery(
      query: json['searchTerms'] ?? '',
      searchType: json['searchType'] ?? 'web',
      count: count,
      language: json['language'],
      region: json['region'],
      startIndex: startIndex,
    );
  }

  Map<String, dynamic> toJson() => {
    'searchTerms': query,
    'searchType': searchType,
    'count': count.toString(),
    'language': language,
    'region': region,
    'startIndex': startIndex.toString(),
  };
}

enum SearchProvider {
  googleCustomSearch,
  programmableSearch,
  webScraping,
}