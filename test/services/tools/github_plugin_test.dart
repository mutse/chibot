import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:chibot/services/tools/github_plugin.dart';

void main() {
  test(
    'fixed host, encoded file paths and refs, authorization header only',
    () async {
      final plugin = GitHubPlugin(
        'secret',
        client: MockClient((r) async {
          expect(r.url.host, 'api.github.com');
          expect(r.url.pathSegments, [
            'repos',
            'o',
            'r',
            'contents',
            'a b',
            '文.txt',
          ]);
          expect(r.url.queryParameters['ref'], 'feature/a');
          expect(r.headers['Authorization'], 'Bearer secret');
          expect(r.followRedirects, false);
          expect(r.body, isEmpty);
          return http.Response(
            jsonEncode({
              'type': 'file',
              'encoding': 'base64',
              'content': base64Encode(utf8.encode('Hello 中文')),
              'size': 12,
            }),
            200,
          );
        }),
      );
      final result = await plugin.execute('github_read_file', {
        'owner': 'o',
        'repo': 'r',
        'path': 'a b/文.txt',
        'ref': 'feature/a',
      });
      expect(result.data['data']['content'], 'Hello 中文');
      expect(result.content, isNot(contains('secret')));
    },
  );
  test('default and explicit pagination with next-page indicator', () async {
    var count = 0;
    final plugin = GitHubPlugin(
      'pat',
      client: MockClient((r) async {
        expect(r.url.queryParameters['page'], count == 0 ? '1' : '3');
        expect(r.url.queryParameters['per_page'], count == 0 ? '20' : '5');
        count++;
        return http.Response(
          '[]',
          200,
          headers: {
            'link': '<https://api.github.com/user/repos?page=4>; rel="next"',
          },
        );
      }),
    );
    expect(
      (await plugin.execute(
        'github_list_repositories',
        {},
      )).data['has_next_page'],
      true,
    );
    await plugin.execute('github_list_repositories', {
      'page': 3,
      'per_page': 5,
    });
    expect(count, 2);
  });
  test('all declared tools build the expected endpoint and body', () async {
    http.Request? request;
    final plugin = GitHubPlugin(
      'pat',
      client: MockClient((r) async {
        request = r;
        return http.Response('{}', 200);
      }),
    );
    for (final tool in plugin.tools) {
      final args = <String, dynamic>{};
      for (final k in tool.required) {
        args[k] = k == 'number' ? 1 : 'value';
      }
      final result = await plugin.execute(tool.name, args);
      expect(result.data['error'], isNull, reason: tool.name);
      expect(request!.method, tool.writes ? 'POST' : 'GET');
      expect(request!.url.host, 'api.github.com');
      if (tool.writes) {
        final body = jsonDecode(request!.body) as Map;
        expect(body.containsKey('owner'), false);
        expect(body['body'], 'value');
        if (tool.name == 'github_create_pull_request') {
          expect(request!.url.path, '/repos/value/value/pulls');
          expect(body['head'], 'value');
          expect(body['base'], 'value');
        }
      }
    }
  });
  test('write timeout is unknown and never automatically retried', () async {
    var count = 0;
    final plugin = GitHubPlugin(
      'pat',
      client: MockClient((r) async {
        count++;
        throw TimeoutException('private details');
      }),
    );
    final result = await plugin.execute('github_create_issue', {
      'owner': 'o',
      'repo': 'r',
      'title': 't',
      'body': 'b',
    });
    expect(result.data['error'], 'outcome_unknown');
    expect(result.content, isNot(contains('private details')));
    expect(count, 1);
  });
  test(
    'classifies authentication, permission, missing resource and rate limits',
    () async {
      for (final entry
          in {
            401: 'authentication',
            403: 'permission',
            404: 'not_found',
            429: 'rate_limit',
            500: 'github_error',
          }.entries) {
        final plugin = GitHubPlugin(
          'pat',
          client: MockClient((_) async => http.Response('secret', entry.key)),
        );
        final result = await plugin.execute('github_get_repository', {
          'owner': 'o',
          'repo': 'r',
        });
        expect(result.data['error'], entry.value);
        expect(result.content, isNot(contains('secret')));
      }
    },
  );
  test(
    'redirects and path traversal cannot send credentials to another host',
    () async {
      var calls = 0;
      final plugin = GitHubPlugin(
        'pat',
        client: MockClient((r) async {
          calls++;
          expect(r.followRedirects, false);
          return http.Response(
            '',
            302,
            headers: {'location': 'https://evil.test'},
          );
        }),
      );
      expect(
        (await plugin.execute('github_read_file', {
          'owner': 'o',
          'repo': 'r',
          'path': '../secrets',
        })).data['error'],
        'invalid_arguments',
      );
      expect(calls, 0);
      expect(
        (await plugin.execute('github_get_repository', {
          'owner': 'o',
          'repo': 'r',
        })).data['error'],
        'github_error',
      );
      expect(calls, 1);
    },
  );
  test(
    'truncation remains valid JSON and at most 32 KiB including metadata',
    () {
      final result = GitHubPlugin.boundedResult({
        'data': {'body': List.filled(20000, '中文"\\').join()},
        'page': 2,
        'has_next_page': true,
      });
      expect(utf8.encode(result.content).length, lessThanOrEqualTo(32768));
      expect(jsonDecode(result.content)['truncated'], true);
      expect(result.data['page'], 2);
      expect(result.data['has_next_page'], true);
    },
  );
  test('binary files and excessive pagination are rejected', () async {
    final plugin = GitHubPlugin(
      'pat',
      client: MockClient(
        (r) async => http.Response(
          jsonEncode({
            'type': 'file',
            'encoding': 'base64',
            'content': base64Encode([0, 1, 255]),
          }),
          200,
        ),
      ),
    );
    expect(
      (await plugin.execute('github_read_file', {
        'owner': 'o',
        'repo': 'r',
      })).data['error'],
      'unsupported_file',
    );
    await expectLater(
      plugin.execute('github_list_repositories', {'per_page': 101}),
      throwsFormatException,
    );
  });
}
