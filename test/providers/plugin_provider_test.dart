import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chibot/providers/plugin_provider.dart';
import 'package:chibot/providers/api_key_provider.dart';
import 'package:chibot/models/chat_message.dart';
import 'package:chibot/models/chat_session.dart';
import 'package:chibot/services/chat_session_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'disabled by default; enabled setting and token survive reload and disconnect',
    () async {
      final p = PluginProvider();
      final keys = ApiKeyProvider();
      await p.ready;
      await keys.ready;
      expect(p.githubEnabled, false);
      await p.setGitHubEnabled(true);
      await keys.setGitHubToken(' pat ');
      final restored = PluginProvider();
      final restoredKeys = ApiKeyProvider();
      await restored.ready;
      await restoredKeys.ready;
      expect(restored.githubEnabled, true);
      expect(restoredKeys.githubToken, 'pat');
      expect(restoredKeys.toMap().values, isNot(contains('pat')));
      expect(restoredKeys.toMap().containsKey('github_pat'), false);
      expect(restoredKeys.customProviderApiKeys.containsValue('pat'), false);
      await restored.setGitHubEnabled(false);
      await restoredKeys.setGitHubToken(null);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('github_pat'), false);
    },
  );
  test(
    'late tool updates target the original message and never resurrect deleted sessions',
    () async {
      final store = ChatSessionService();
      await store.saveSession(
        ChatSession.create(
          id: 'one',
          title: 'One',
        ).addMessage(ChatMessage.ai(id: 'reply', text: 'old')),
      );
      await store.saveSession(
        ChatSession.create(
          id: 'two',
          title: 'Two',
        ).addMessage(ChatMessage.ai(id: 'reply2', text: 'other')),
      );
      await Future.wait([
        store.updateToolMetadata('one', 'reply', {
          'toolRecords': [
            {'status': 'completed'},
          ],
        }),
        store.saveSession(ChatSession.create(id: 'three', title: 'Three')),
      ]);
      var sessions = await store.loadSessions();
      expect(sessions.length, 3);
      expect(
        sessions.firstWhere((s) => s.id == 'one').messages.first.metadata,
        isNotNull,
      );
      expect(
        sessions.firstWhere((s) => s.id == 'two').messages.first.metadata,
        isNull,
      );
      await store.deleteSession('one');
      await store.updateToolMetadata('one', 'reply', {'toolRecords': []});
      sessions = await store.loadSessions();
      expect(sessions.any((s) => s.id == 'one'), false);
    },
  );
  test(
    'old messages remain compatible and saved tool operations recover inactive',
    () {
      final old = ChatMessage.user(id: 'a', text: 'hello');
      expect(ChatMessage.fromJson(old.toJson()), old);
      final pending = ChatMessage.ai(
        id: 'b',
        text: '',
        isLoading: true,
        metadata: {
          'toolRecords': [
            {'status': 'awaitingApproval'},
          ],
        },
      );
      expect(ChatMessage.fromJson(pending.toJson()).isLoading, false);
    },
  );
}
