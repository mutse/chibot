import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../models/chat_message.dart';

class ToolCallRecords extends StatelessWidget {
  final ChatMessage message;
  const ToolCallRecords({super.key, required this.message});
  @override
  Widget build(BuildContext context) {
    final records = message.metadata?['toolRecords'];
    if (records is! List || records.isEmpty) return const SizedBox.shrink();
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final record in records.whereType<Map>())
          Builder(
            builder: (context) {
              final status = record['status'];
              final interrupted =
                  !message.isLoading &&
                  (status == 'running' || status == 'awaitingApproval');
              final label =
                  interrupted
                      ? (record['writes'] == true && status == 'running'
                          ? l.toolOutcomeUnknown
                          : l.toolInterrupted)
                      : switch (status) {
                        'running' => l.toolRunning,
                        'awaitingApproval' => l.toolAwaitingApproval,
                        'completed' => l.toolCompleted,
                        'cancelled' => l.toolCancelled,
                        'rejected' => l.toolRejected,
                        'outcome_unknown' => l.toolOutcomeUnknown,
                        _ => l.toolFailure,
                      };
              final result = record['result'];
              final data = result is Map ? result['data'] : null;
              final url =
                  data is Map
                      ? Uri.tryParse(data['html_url']?.toString() ?? '')
                      : null;
              return ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(
                  '${record['name']} · $label',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                children: [
                  if (record['arguments'] != null)
                    SelectableText(
                      const JsonEncoder.withIndent(
                        '  ',
                      ).convert(record['arguments']),
                    ),
                  if (result != null)
                    SelectableText(
                      const JsonEncoder.withIndent('  ').convert(result),
                    ),
                  if (url?.scheme == 'https' && url?.host == 'github.com')
                    TextButton(
                      onPressed: () => launchUrl(url!),
                      child: Text(l.openGitHub),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}
