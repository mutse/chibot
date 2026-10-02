import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chibot/l10n/app_localizations.dart';
import 'package:chibot/models/chat_message.dart';
import 'package:chibot/models/tool_call.dart';
import 'package:chibot/providers/api_key_provider.dart';
import 'package:chibot/providers/plugin_provider.dart';
import 'package:chibot/repositories/interfaces.dart';
import 'package:chibot/services/tools/github_plugin.dart';
import 'package:chibot/widgets/github_plugin_settings.dart';
import 'package:chibot/widgets/tool_chat_run.dart';
import 'package:chibot/widgets/tool_call_records.dart';

class ToolModel implements ChatService, ToolChatService {
  var turn = 0;
  @override
  Stream<ToolModelEvent> generateToolTurn({
    required List<Map<String, dynamic>> messages,
    required List<ToolDefinition> tools,
    required String model,
  }) async* {
    if (turn++ == 0) {
      yield const ToolModelEvent.calls([
        ToolCall(
          'id',
          'github_create_issue',
          '{"owner":"octo","repo":"repo","title":"Exact title","body":"Full proposed body"}',
        ),
      ]);
    } else {
      yield const ToolModelEvent.text('Done');
    }
  }

  @override
  Stream<String> generateResponse({
    required String prompt,
    required List<ChatMessage> context,
    required String model,
    Map<String, dynamic>? parameters,
  }) => Stream.value('Plain');
  @override
  Future<String> generateTitle(List<ChatMessage> messages) async => 'Title';
  @override
  String get providerName => 'Fake';
  @override
  List<String> get supportedModels => ['fake'];
  @override
  Future<bool> isConfigured() async => true;
  @override
  Future<void> validateConfiguration() async {}
}

void main() {
  late ApiKeyProvider keys;
  late PluginProvider plugins;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    keys = ApiKeyProvider();
    plugins = PluginProvider();
    await keys.ready;
    await plugins.ready;
  });
  Widget host(Widget child) => MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: keys),
      ChangeNotifierProvider.value(value: plugins),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );

  testWidgets(
    'connect, show account, enable and disconnect clear saved credentials',
    (tester) async {
      await tester.pumpWidget(
        host(
          GitHubPluginSettings(
            createPlugin:
                (token) => GitHubPlugin(
                  token,
                  client: MockClient((r) async {
                    expect(r.url.path, '/user');
                    expect(r.headers['Authorization'], 'Bearer test-pat');
                    return http.Response('{"login":"octocat"}', 200);
                  }),
                ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'test-pat');
      await tester.runAsync(() async {
        await tester.tap(find.text('Save and test connection'));
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });
      await tester.pumpAndSettle();
      expect(find.text('octocat'), findsOneWidget);
      expect(keys.githubToken, 'test-pat');
      await tester.runAsync(() async {
        await tester.tap(find.byType(Switch));
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });
      await tester.pumpAndSettle();
      expect(plugins.githubEnabled, true);
      await tester.runAsync(() async {
        await tester.tap(find.text('Disconnect'));
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });
      await tester.pumpAndSettle();
      expect(keys.githubToken, isNull);
      expect(plugins.githubEnabled, false);
      expect(find.text('Not connected'), findsOneWidget);
    },
  );
  for (final action in ['approve', 'reject', 'cancel']) {
    testWidgets(
      '$action a write: exact preview, only explicit approval sends HTTP',
      (tester) async {
        await tester.runAsync(() async {
          await keys.setGitHubToken('pat');
          await plugins.setGitHubEnabled(true);
        });
        var requests = 0;
        ToolChatRun? run;
        Future<List<String>>? result;
        await tester.pumpWidget(
          host(
            Builder(
              builder:
                  (context) => TextButton(
                    onPressed: () {
                      run = ToolChatRun(
                        context: context,
                        sessionId: 'session',
                        messageId: 'message',
                        onMetadata: (_) {},
                        createPlugin:
                            (token) => GitHubPlugin(
                              token,
                              client: MockClient((r) async {
                                requests++;
                                return http.Response(
                                  '{"html_url":"https://github.com/octo/repo/issues/1"}',
                                  201,
                                );
                              }),
                            ),
                      );
                      result =
                          run!
                              .generate(
                                service: ToolModel(),
                                prompt: 'create',
                                history: [],
                                model: 'fake',
                              )
                              .toList();
                    },
                    child: const Text('Start'),
                  ),
            ),
          ),
        );
        await tester.runAsync(() async {
          await tester.tap(find.text('Start'));
          await Future<void>.delayed(const Duration(milliseconds: 20));
        });
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 20));
        });
        await tester.pumpAndSettle();
        expect(find.text('Confirm GitHub write'), findsOneWidget);
        expect(find.textContaining('Full proposed body'), findsOneWidget);
        expect(find.textContaining('Exact title'), findsOneWidget);
        expect(requests, 0);
        if (action == 'cancel') {
          run!.cancel();
        } else {
          await tester.tap(
            find.text(
              action == 'approve' ? 'Approve this operation' : 'Reject',
            ),
          );
        }
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 20));
        });
        await tester.pumpAndSettle();
        await tester.runAsync(() async => await result);
        expect(requests, action == 'approve' ? 1 : 0);
        expect(find.text('Confirm GitHub write'), findsNothing);
      },
    );
  }
  testWidgets(
    'historical records show unknown outcome and never offer approval',
    (tester) async {
      await tester.pumpWidget(
        host(
          ToolCallRecords(
            message: ChatMessage.ai(
              id: 'a',
              text: '',
              metadata: {
                'toolRecords': [
                  {
                    'name': 'github_create_issue',
                    'status': 'running',
                    'writes': true,
                  },
                ],
              },
            ),
          ),
        ),
      );
      expect(find.textContaining('Outcome unknown'), findsOneWidget);
      expect(find.text('Approve this operation'), findsNothing);
    },
  );
  testWidgets('disabled plugin uses plain chat without GitHub calls', (
    tester,
  ) async {
    Future<List<String>>? result;
    await tester.pumpWidget(
      host(
        Builder(
          builder:
              (context) => TextButton(
                onPressed: () {
                  result =
                      ToolChatRun(
                            context: context,
                            sessionId: 's',
                            messageId: 'm',
                            onMetadata: (_) {},
                          )
                          .generate(
                            service: ToolModel(),
                            prompt: 'hi',
                            history: [],
                            model: 'fake',
                          )
                          .toList();
                },
                child: const Text('Start'),
              ),
        ),
      ),
    );
    await tester.runAsync(() async {
      await tester.tap(find.text('Start'));
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await tester.pumpAndSettle();
    expect(await tester.runAsync(() async => await result), ['Plain']);
  });
}
