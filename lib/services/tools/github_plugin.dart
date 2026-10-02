import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/tool_call.dart';

class GitHubPlugin implements ToolPlugin {
  final String token;
  final http.Client _client;
  final Duration timeout;
  GitHubPlugin(
    this.token, {
    http.Client? client,
    this.timeout = const Duration(seconds: 30),
  }) : _client = client ?? http.Client();
  void dispose() => _client.close();
  static const _string = {'type': 'string'};
  static const _repo = {'owner': _string, 'repo': _string};
  static const _pagination = {
    'page': {'type': 'integer'},
    'per_page': {'type': 'integer', 'maximum': 100},
  };
  static const _number = {
    'number': {'type': 'integer'},
  };
  static const _state = {
    'state': {
      'type': 'string',
      'enum': ['open', 'closed', 'all'],
    },
  };
  @override
  List<ToolDefinition> get tools => [
    const ToolDefinition(
      'github_list_repositories',
      'List authenticated user repositories; explicit pagination.',
      _pagination,
    ),
    const ToolDefinition(
      'github_search_repositories',
      'Search GitHub repositories.',
      {'query': _string, ..._pagination},
      required: ['query'],
    ),
    const ToolDefinition(
      'github_get_repository',
      'Get repository details.',
      _repo,
      required: ['owner', 'repo'],
    ),
    const ToolDefinition(
      'github_read_file',
      'List a directory or read a UTF-8 text file. Omit path for root. ref is a branch or SHA.',
      {..._repo, 'path': _string, 'ref': _string},
      required: ['owner', 'repo'],
    ),
    const ToolDefinition(
      'github_list_issues',
      'List repository issues (excludes pull requests).',
      {..._repo, ..._pagination, ..._state},
      required: ['owner', 'repo'],
    ),
    const ToolDefinition(
      'github_get_issue',
      'Read issue details.',
      {..._repo, ..._number},
      required: ['owner', 'repo', 'number'],
    ),
    const ToolDefinition(
      'github_list_pull_requests',
      'List pull requests.',
      {..._repo, ..._pagination, ..._state},
      required: ['owner', 'repo'],
    ),
    const ToolDefinition(
      'github_get_pull_request',
      'Read pull request details including head and base.',
      {..._repo, ..._number},
      required: ['owner', 'repo', 'number'],
    ),
    const ToolDefinition(
      'github_list_comments',
      'Read ordinary issue or PR comments, not inline review comments.',
      {..._repo, ..._number, ..._pagination},
      required: ['owner', 'repo', 'number'],
    ),
    const ToolDefinition(
      'github_list_branches',
      'List existing branches.',
      {..._repo, ..._pagination},
      required: ['owner', 'repo'],
    ),
    const ToolDefinition(
      'github_create_issue',
      'Create an issue after user confirmation.',
      {..._repo, 'title': _string, 'body': _string},
      required: ['owner', 'repo', 'title', 'body'],
      writes: true,
    ),
    const ToolDefinition(
      'github_create_comment',
      'Post an ordinary issue or PR comment after user confirmation.',
      {..._repo, ..._number, 'body': _string},
      required: ['owner', 'repo', 'number', 'body'],
      writes: true,
    ),
    const ToolDefinition(
      'github_create_pull_request',
      'Create a PR from existing head and base branches after user confirmation. Does not create branches or commits.',
      {
        ..._repo,
        'title': _string,
        'body': _string,
        'head': _string,
        'base': _string,
      },
      required: ['owner', 'repo', 'title', 'body', 'head', 'base'],
      writes: true,
    ),
  ];

  Future<ToolResult> testConnection() => _request('GET', ['user']);

  @override
  Future<ToolResult> execute(
    String name,
    Map<String, dynamic> arguments,
  ) async {
    final matches = tools.where((t) => t.name == name);
    if (matches.isEmpty) {
      return ToolResult.error('unknown_tool', 'Unknown GitHub tool');
    }
    matches.first.validate(arguments);
    final a = arguments;
    for (final key in ['owner', 'repo']) {
      if (a.containsKey(key) &&
          !RegExp(r'^[A-Za-z0-9_.-]+$').hasMatch(a[key] as String)) {
        return ToolResult.error(
          'invalid_arguments',
          'Invalid repository identifier',
        );
      }
      if (a[key] == '.' || a[key] == '..') {
        return ToolResult.error(
          'invalid_arguments',
          'Invalid repository identifier',
        );
      }
    }
    final pagination = <String, String>{
      'page': '${a['page'] ?? 1}',
      'per_page': '${a['per_page'] ?? 20}',
    };
    final root = ['repos', '${a['owner']}', '${a['repo']}'];
    final number = '${a['number']}';
    switch (name) {
      case 'github_list_repositories':
        return _request('GET', ['user', 'repos'], query: pagination);
      case 'github_search_repositories':
        return _request(
          'GET',
          ['search', 'repositories'],
          query: {...pagination, 'q': a['query']},
        );
      case 'github_get_repository':
        return _request('GET', root);
      case 'github_read_file':
        final path =
            (a['path'] as String? ?? '')
                .split('/')
                .where((s) => s.isNotEmpty)
                .toList();
        if (path.any((s) => s == '..' || s == '.')) {
          return ToolResult.error('invalid_arguments', 'Invalid file path');
        }
        return _request(
          'GET',
          [...root, 'contents', ...path],
          query: {if (a['ref'] != null) 'ref': a['ref']},
          file: true,
        );
      case 'github_list_issues':
        return _request(
          'GET',
          [...root, 'issues'],
          query: {...pagination, 'state': a['state'] ?? 'open'},
          issuesOnly: true,
        );
      case 'github_get_issue':
        return _request('GET', [...root, 'issues', number]);
      case 'github_list_pull_requests':
        return _request(
          'GET',
          [...root, 'pulls'],
          query: {...pagination, 'state': a['state'] ?? 'open'},
        );
      case 'github_get_pull_request':
        return _request('GET', [...root, 'pulls', number]);
      case 'github_list_comments':
        return _request('GET', [
          ...root,
          'issues',
          number,
          'comments',
        ], query: pagination);
      case 'github_list_branches':
        return _request('GET', [...root, 'branches'], query: pagination);
      case 'github_create_issue':
        return _request(
          'POST',
          [...root, 'issues'],
          body: {'title': a['title'], 'body': a['body']},
        );
      case 'github_create_comment':
        return _request(
          'POST',
          [...root, 'issues', number, 'comments'],
          body: {'body': a['body']},
        );
      case 'github_create_pull_request':
        return _request(
          'POST',
          [...root, 'pulls'],
          body: {
            for (final k in ['title', 'body', 'head', 'base']) k: a[k],
          },
        );
      default:
        return ToolResult.error('unknown_tool', 'Unknown GitHub tool');
    }
  }

  Future<ToolResult> _request(
    String method,
    List<String> path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
    bool file = false,
    bool issuesOnly = false,
  }) async {
    if (token.trim().isEmpty) {
      return ToolResult.error('authentication', 'GitHub PAT is missing');
    }
    final uri = Uri(
      scheme: 'https',
      host: 'api.github.com',
      pathSegments: path,
      queryParameters: query,
    );
    try {
      final request = http.Request(method, uri)..followRedirects = false;
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
        'Content-Type': 'application/json',
      });
      if (body != null) request.body = jsonEncode(body);
      // Intentionally no automatic retry, especially for non-idempotent writes.
      final response = await (() async =>
              http.Response.fromStream(await _client.send(request)))()
          .timeout(timeout);
      final status = response.statusCode;
      if (status < 200 || status >= 300) {
        final code =
            status == 401
                ? 'authentication'
                : status == 404
                ? 'not_found'
                : (status == 429 ||
                    (status == 403 &&
                        (response.headers['x-ratelimit-remaining'] == '0' ||
                            response.headers.containsKey('retry-after') ||
                            response.body.toLowerCase().contains(
                              'rate limit',
                            ))))
                ? 'rate_limit'
                : status == 403
                ? 'permission'
                : method == 'POST' && status >= 500
                ? 'outcome_unknown'
                : 'github_error';
        return ToolResult({
          'error': code,
          'status': status,
          'message':
              code == 'outcome_unknown'
                  ? 'Write outcome unknown. Check GitHub before trying again.'
                  : 'GitHub request failed; check token, repository access and parameters.',
          if (response.headers['retry-after'] != null)
            'retry_after': response.headers['retry-after'],
        });
      }
      dynamic data = jsonDecode(response.body);
      if (issuesOnly && data is List) {
        data = data.where((i) => i['pull_request'] == null).toList();
      }
      if (file && data is Map && data['type'] == 'file') {
        if (data['encoding'] != 'base64' ||
            data['content'] == null ||
            (data['size'] as num? ?? 0) > 1024 * 1024) {
          return ToolResult.error(
            'unsupported_file',
            'File is too large or is not available as inline text',
          );
        }
        try {
          final content = utf8.decode(
            base64Decode(
              (data['content'] as String).replaceAll(RegExp(r'\s'), ''),
            ),
          );
          if (content.contains('\u0000')) throw const FormatException();
          data = {
            'path': data['path'],
            'sha': data['sha'],
            'html_url': data['html_url'],
            'content': content,
          };
        } on FormatException {
          return ToolResult.error(
            'unsupported_file',
            'Only UTF-8 text files are supported',
          );
        }
      }
      final result = <String, dynamic>{
        'data': data,
        if (query?['page'] != null) 'page': int.parse(query!['page']!),
        if (query?['per_page'] != null)
          'per_page': int.parse(query!['per_page']!),
        if (query?['page'] != null)
          'has_next_page':
              response.headers['link']?.contains('rel="next"') ?? false,
      };
      return boundedResult(result);
    } catch (_) {
      return ToolResult.error(
        method == 'POST' ? 'outcome_unknown' : 'network',
        method == 'POST'
            ? 'Write outcome unknown. Check GitHub before trying again.'
            : 'GitHub network request failed or timed out',
      );
    }
  }

  /// JSON stays valid and the entire encoded result stays below 32 KiB.
  static ToolResult boundedResult(Map<String, dynamic> data) {
    if (utf8.encode(jsonEncode(data)).length <= 32768) return ToolResult(data);
    final source = jsonEncode(data['data']);
    var low = 0;
    var high = source.length;
    Map<String, dynamic> truncated(int n) => {
      ...data,
      'data': null,
      'truncated': true,
      'preview': source.substring(0, n),
      'message':
          'Result truncated to 32 KiB; request a narrower resource or smaller page.',
    };
    while (low < high) {
      final mid = (low + high + 1) ~/ 2;
      if (utf8.encode(jsonEncode(truncated(mid))).length <= 32768) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }
    return ToolResult(truncated(low));
  }
}
