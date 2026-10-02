import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/chat_message.dart';
import '../models/tool_call.dart';
import '../providers/api_key_provider.dart';
import '../providers/plugin_provider.dart';
import '../repositories/interfaces.dart';
import '../services/chat_session_service.dart';
import '../services/tools/github_plugin.dart';
import '../services/tools/tool_orchestrator.dart';

/// Per-request bridge shared by both chat UIs. No tokens are stored in metadata.
class ToolChatRun {
  final ToolCancellation cancellation = ToolCancellation();
  final BuildContext context;
  final String sessionId;
  final String messageId;
  final void Function(Map<String, dynamic>) onMetadata;
  Map<String, dynamic>? metadata;
  final GitHubPlugin Function(String)? createPlugin;
  bool usedTools = false;
  bool finished = false;
  ToolChatRun({
    this.createPlugin,
    required this.context,
    required this.sessionId,
    required this.messageId,
    required this.onMetadata,
  });
  void cancel() => cancellation.cancel();

  Future<void> _update(Map<String, dynamic> value) async {
    metadata = value;
    onMetadata(value);
    // Update only this message in the original session; never recreate a deleted
    // session or replace newer turns after navigation.
    await ChatSessionService().updateToolMetadata(sessionId, messageId, value);
  }

  Future<bool> _confirm(ToolCall call, Map<String, dynamic> args) async {
    if (cancellation.isCancelled || !context.mounted) return false;
    final navigator = Navigator.of(context, rootNavigator: true);
    final l = AppLocalizations.of(context)!;
    final route = DialogRoute<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(l.confirmToolWrite),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(call.name),
                  const SizedBox(height: 12),
                  // Plain selectable text: repository content cannot render approval controls.
                  SelectableText(
                    const JsonEncoder.withIndent('  ').convert(args),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l.rejectTool),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l.approveTool),
              ),
            ],
          ),
    );
    unawaited(
      cancellation.whenCancelled.then((_) {
        if (route.isActive) navigator.removeRoute(route, false);
      }),
    );
    return await navigator.push(route) ?? false;
  }

  Stream<String> generate({
    required ChatService service,
    required String prompt,
    required List<ChatMessage> history,
    required String model,
  }) async* {
    final plugins = context.read<PluginProvider?>();
    final keys = context.read<ApiKeyProvider>();
    final l = AppLocalizations.of(context)!;
    final enabled = plugins?.githubEnabled ?? false;
    try {
      if (!enabled || service is! ToolChatService) {
        await for (final text in service.generateResponse(
          prompt: prompt,
          context: history,
          model: model,
        )) {
          if (cancellation.isCancelled) return;
          yield text;
        }
        return;
      }
      usedTools = true;
      final token = keys.githubToken;
      if (token == null || token.isEmpty) {
        yield l.githubMissingToken;
        return;
      }
      final plugin = createPlugin?.call(token) ?? GitHubPlugin(token);
      void checkEnabled() {
        if (plugins?.githubEnabled != true || keys.githubToken != token) {
          cancel();
        }
      }

      plugins!.addListener(checkEnabled);
      keys.addListener(checkEnabled);
      try {
        final orchestrator = ToolOrchestrator(
          registry: ToolRegistry([plugin]),
          cancellation: cancellation,
          confirm: _confirm,
          onUpdate: _update,
        );
        await for (final text in orchestrator.run(
          service: service as ToolChatService,
          model: model,
          history: history,
          prompt: prompt,
        )) {
          yield text;
        }
      } catch (_) {
        if (!cancellation.isCancelled) yield '\n${l.toolChatFailed}';
      } finally {
        plugins.removeListener(checkEnabled);
        keys.removeListener(checkEnabled);
        plugin.dispose();
      }
    } finally {
      finished = true;
    }
  }
}
