import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatMarkdown extends StatelessWidget {
  const ChatMarkdown({super.key, required this.text, required this.textColor});

  final String text;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseTextStyle = theme.textTheme.bodyLarge?.copyWith(
      color: textColor,
      height: 1.45,
    );

    return MarkdownBody(
      data: text,
      selectable: true,
      softLineBreak: true,
      shrinkWrap: true,
      onTapLink: (text, href, title) async {
        if (href == null || href.isEmpty) {
          return;
        }

        final uri = Uri.tryParse(href);
        if (uri == null) {
          return;
        }

        await launchUrl(uri, mode: LaunchMode.platformDefault);
      },
      styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
        p: baseTextStyle,
        code: theme.textTheme.bodyMedium?.copyWith(
          color: textColor,
          fontFamily: 'monospace',
          backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.45),
        ),
        codeblockDecoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(12),
        ),
        codeblockPadding: const EdgeInsets.all(12),
        blockquote: baseTextStyle?.copyWith(
          color: textColor.withValues(alpha: 0.9),
          fontStyle: FontStyle.italic,
        ),
        blockquoteDecoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(
              color: theme.colorScheme.primary.withValues(alpha: 0.55),
              width: 4,
            ),
          ),
        ),
        blockquotePadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        a: baseTextStyle?.copyWith(
          color: theme.colorScheme.primary,
          decoration: TextDecoration.underline,
        ),
        listBullet: baseTextStyle,
        h1: theme.textTheme.headlineSmall?.copyWith(color: textColor),
        h2: theme.textTheme.titleLarge?.copyWith(color: textColor),
        h3: theme.textTheme.titleMedium?.copyWith(color: textColor),
        h4: theme.textTheme.titleSmall?.copyWith(color: textColor),
        h5: baseTextStyle?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
        h6: baseTextStyle?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
