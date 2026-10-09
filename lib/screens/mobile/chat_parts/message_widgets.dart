part of '../mobile_chat_page.dart';

/// message_widgets.dart - MobileChatPageState 的拆分方法（extension 形式，与主文件同一 library，可访问私有成员）
extension _MessageWidgetsExt on MobileChatPageState {
  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.sender == MessageSender.user;
    final bubbleColor =
        isUser ? MobilePalette.primary : MobilePalette.surfaceStrong;
    final textColor = isUser ? Colors.white : MobilePalette.textPrimary;

    Widget child;
    if (message.isLoading && message.text.isEmpty) {
      child = const SizedBox(
        width: 72,
        child: SpinKitThreeBounce(color: MobilePalette.primary, size: 16),
      );
    } else {
      child = ChatMarkdown(text: message.text, textColor: textColor);
    }

    child = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [ToolCallRecords(message: message), child],
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Align(
            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isUser ? 20 : 10),
                  topRight: Radius.circular(isUser ? 10 : 20),
                  bottomLeft: const Radius.circular(20),
                  bottomRight: const Radius.circular(20),
                ),
                border: isUser ? null : Border.all(color: MobilePalette.border),
              ),
              child: child,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatMobileClock(message.timestamp),
            style: const TextStyle(
              color: MobilePalette.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - 48).clamp(0, double.infinity),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: MobilePalette.primarySoft,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: MobilePalette.primary,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '让想法，从这里开始',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.8,
                        color: MobilePalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '一起探索问题、整理思路，或创造下一份作品。',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: MobilePalette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        _suggestion(
                          Icons.edit_note_rounded,
                          '帮我写作',
                          '请帮我写一段内容，主题是：',
                        ),
                        _suggestion(
                          Icons.lightbulb_outline_rounded,
                          '激发灵感',
                          '请和我一起头脑风暴，方向是：',
                        ),
                        _suggestion(Icons.code_rounded, '解决问题', '请帮我分析这个问题：'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
