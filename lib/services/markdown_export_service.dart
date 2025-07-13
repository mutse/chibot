import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:intl/intl.dart';
import '../models/chat_session.dart';
import '../models/chat_message.dart';
import '../core/logger.dart';

class MarkdownExportService {
  static String _formatTimestamp(DateTime timestamp) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(timestamp);
  }

  static String _formatMessageSender(MessageSender sender) {
    switch (sender) {
      case MessageSender.user:
        return '**User**';
      case MessageSender.ai:
        return '**Assistant**';
    }
  }

  static String _escapeMarkdown(String text) {
    // Escape special markdown characters to prevent formatting issues
    return text
        .replaceAll('\\', '\\\\')
        .replaceAll('*', '\\*')
        .replaceAll('_', '\\_')
        .replaceAll('[', '\\[')
        .replaceAll(']', '\\]')
        .replaceAll('(', '\\(')
        .replaceAll(')', '\\)')
        .replaceAll('#', '\\#')
        .replaceAll('`', '\\`');
  }

  static String generateMarkdown(ChatSession session) {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('# ${session.title}');
    buffer.writeln();
    
    // Session metadata
    buffer.writeln('**Session Information:**');
    buffer.writeln('- **Session ID:** ${session.id}');
    buffer.writeln('- **Created:** ${_formatTimestamp(session.createdAt)}');
    buffer.writeln('- **Last Updated:** ${_formatTimestamp(session.updatedAt)}');
    
    if (session.providerUsed != null) {
      buffer.writeln('- **Provider:** ${session.providerUsed}');
    }
    
    if (session.modelUsed != null) {
      buffer.writeln('- **Model:** ${session.modelUsed}');
    }
    
    buffer.writeln('- **Messages:** ${session.messageCount}');
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln();
    
    // Messages
    buffer.writeln('## Conversation');
    buffer.writeln();
    
    for (final message in session.messages) {
      // Skip loading messages and error messages without content
      if (message.isLoading || (message.hasError && message.text.isEmpty)) {
        continue;
      }
      
      // Message header with sender and timestamp
      buffer.writeln('### ${_formatMessageSender(message.sender)}');
      buffer.writeln('*${_formatTimestamp(message.timestamp)}*');
      buffer.writeln();
      
      // Message content
      if (message.hasError) {
        buffer.writeln('**Error:** ${message.error}');
      } else if (message.text.isNotEmpty) {
        // Check if the message looks like it already contains markdown
        if (message.text.contains('```') || 
            message.text.contains('**') || 
            message.text.contains('*') && !message.text.contains('\\*')) {
          // Likely already markdown formatted, use as-is
          buffer.writeln(message.text);
        } else {
          // Plain text, escape markdown characters
          buffer.writeln(_escapeMarkdown(message.text));
        }
      }
      
      buffer.writeln();
      buffer.writeln('---');
      buffer.writeln();
    }
    
    // Footer
    buffer.writeln('*Exported from Chibot on ${_formatTimestamp(DateTime.now())}*');
    
    return buffer.toString();
  }

  static Future<void> exportToMarkdown(ChatSession session, BuildContext context) async {
    try {
      final markdownContent = generateMarkdown(session);
      
      if (kIsWeb) {
        throw UnsupportedError('Web platform export is not supported yet');
      } else {
        // Desktop and mobile platforms
        final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        final suggestedName = '${session.title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')}_$timestamp.md';
        
        final FileSaveLocation? result = await getSaveLocation(
          suggestedName: suggestedName,
          acceptedTypeGroups: [
            const XTypeGroup(
              label: 'Markdown files',
              extensions: ['md'],
            ),
          ],
        );
        
        if (result == null) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Export cancelled'),
                duration: Duration(seconds: 2),
              ),
            );
          }
          return;
        }
        
        final file = File(result.path);
        await file.writeAsString(markdownContent, encoding: utf8);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Chat exported to ${result.path}'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
        
        AppLogger.info('Chat session exported to markdown: ${result.path}');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to export chat session to markdown', 
        error: e, stackTrace: stackTrace);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  static Future<void> exportMultipleToMarkdown(List<ChatSession> sessions, BuildContext context) async {
    try {
      if (sessions.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No sessions to export'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      if (kIsWeb) {
        throw UnsupportedError('Web platform export is not supported yet');
      } else {
        final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        final suggestedName = 'chibot_chat_export_$timestamp.md';
        
        final FileSaveLocation? result = await getSaveLocation(
          suggestedName: suggestedName,
          acceptedTypeGroups: [
            const XTypeGroup(
              label: 'Markdown files',
              extensions: ['md'],
            ),
          ],
        );
        
        if (result == null) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Export cancelled'),
                duration: Duration(seconds: 2),
              ),
            );
          }
          return;
        }
        
        final buffer = StringBuffer();
        buffer.writeln('# Chibot Chat Export');
        buffer.writeln();
        buffer.writeln('**Export Information:**');
        buffer.writeln('- **Exported on:** ${_formatTimestamp(DateTime.now())}');
        buffer.writeln('- **Number of sessions:** ${sessions.length}');
        buffer.writeln();
        buffer.writeln('---');
        buffer.writeln();
        
        for (int i = 0; i < sessions.length; i++) {
          final session = sessions[i];
          buffer.writeln('## Session ${i + 1}: ${session.title}');
          buffer.writeln();
          
          // Session metadata
          buffer.writeln('**Session Information:**');
          buffer.writeln('- **Session ID:** ${session.id}');
          buffer.writeln('- **Created:** ${_formatTimestamp(session.createdAt)}');
          buffer.writeln('- **Last Updated:** ${_formatTimestamp(session.updatedAt)}');
          
          if (session.providerUsed != null) {
            buffer.writeln('- **Provider:** ${session.providerUsed}');
          }
          
          if (session.modelUsed != null) {
            buffer.writeln('- **Model:** ${session.modelUsed}');
          }
          
          buffer.writeln('- **Messages:** ${session.messageCount}');
          buffer.writeln();
          
          // Messages
          for (final message in session.messages) {
            // Skip loading messages and error messages without content
            if (message.isLoading || (message.hasError && message.text.isEmpty)) {
              continue;
            }
            
            // Message header with sender and timestamp
            buffer.writeln('### ${_formatMessageSender(message.sender)}');
            buffer.writeln('*${_formatTimestamp(message.timestamp)}*');
            buffer.writeln();
            
            // Message content
            if (message.hasError) {
              buffer.writeln('**Error:** ${message.error}');
            } else if (message.text.isNotEmpty) {
              if (message.text.contains('```') || 
                  message.text.contains('**') || 
                  message.text.contains('*') && !message.text.contains('\\*')) {
                buffer.writeln(message.text);
              } else {
                buffer.writeln(_escapeMarkdown(message.text));
              }
            }
            
            buffer.writeln();
          }
          
          buffer.writeln('---');
          buffer.writeln();
        }
        
        buffer.writeln('*Exported from Chibot on ${_formatTimestamp(DateTime.now())}*');
        
        final file = File(result.path);
        await file.writeAsString(buffer.toString(), encoding: utf8);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${sessions.length} chat sessions exported to ${result.path}'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
        
        AppLogger.info('${sessions.length} chat sessions exported to markdown: ${result.path}');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to export multiple chat sessions to markdown', 
        error: e, stackTrace: stackTrace);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}