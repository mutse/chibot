part of '../mobile_chat_page.dart';

/// composer.dart - MobileChatPageState 的拆分方法（extension 形式，与主文件同一 library，可访问私有成员）
extension _ComposerExt on MobileChatPageState {
  Widget _buildComposer() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: MobileSurface(
            padding: const EdgeInsets.all(12),
            radius: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _textController,
                  focusNode: _composerFocus,
                  maxLines: 5,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: const InputDecoration(
                    hintText: '输入你的想法，或提出一个问题…',
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.fromLTRB(8, 10, 8, 16),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: widget.onOpenImages,
                      icon: const Icon(Icons.image_outlined),
                      tooltip: '创作图片',
                    ),
                    IconButton(
                      onPressed: widget.onOpenVideo,
                      icon: const Icon(Icons.smart_display_outlined),
                      tooltip: '创作视频',
                    ),
                    IconButton(
                      onPressed:
                          () => setState(
                            () => _enableWebSearch = !_enableWebSearch,
                          ),
                      isSelected: _enableWebSearch,
                      style: IconButton.styleFrom(
                        backgroundColor:
                            _enableWebSearch
                                ? MobilePalette.primarySoft
                                : Colors.transparent,
                        foregroundColor:
                            _enableWebSearch
                                ? MobilePalette.primary
                                : MobilePalette.textSecondary,
                      ),
                      icon: const Icon(Icons.public_rounded),
                      tooltip: _enableWebSearch ? '关闭网页搜索' : '开启网页搜索',
                    ),
                    const Spacer(),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _textController,
                      builder:
                          (context, value, child) => IconButton.filled(
                            tooltip:
                                _isLoading
                                    ? AppLocalizations.of(context)!.stopToolRun
                                    : '发送消息',
                            onPressed:
                                _isLoading
                                    ? stopGeneration
                                    : value.text.trim().isNotEmpty
                                    ? _sendMessage
                                    : null,
                            icon:
                                _isLoading
                                    ? const Icon(Icons.stop_rounded)
                                    : const Icon(Icons.arrow_upward_rounded),
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
