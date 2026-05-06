import 'package:chibot/models/available_model.dart' as available_model;
import 'package:chibot/providers/api_key_provider.dart';
import 'package:chibot/providers/chat_model_provider.dart';
import 'package:chibot/providers/image_model_provider.dart';
import 'package:chibot/providers/unified_settings_provider.dart';
import 'package:chibot/providers/video_model_provider.dart';
import 'package:chibot/screens/mobile/mobile_ui.dart';
import 'package:chibot/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MobileModelsPage extends StatefulWidget {
  const MobileModelsPage({super.key});

  @override
  State<MobileModelsPage> createState() => _MobileModelsPageState();
}

class _MobileModelsPageState extends State<MobileModelsPage> {
  @override
  Widget build(BuildContext context) {
    final unifiedSettings = context.watch<UnifiedSettingsProvider>();
    final apiKeys = context.watch<ApiKeyProvider>();
    final chatModel = context.watch<ChatModelProvider>();
    final imageModel = context.watch<ImageModelProvider>();
    final videoModel = context.watch<VideoModelProvider>();

    return DecoratedBox(
      decoration: buildMobileBackgroundDecoration(),
      child: Column(
        children: [
          MobileTopBar(
            leading: MobileIconCircleButton(
              icon: Icons.widgets_outlined,
              onTap: () {},
            ),
            title: 'Models',
            subtitle: 'Active workspace and providers',
            trailing: MobileIconCircleButton(
              icon: Icons.settings_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              children: [
                MobileSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Active Workspace',
                        style: TextStyle(
                          color: MobilePalette.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: MobilePalette.primarySoft,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.smart_toy_rounded,
                              color: MobilePalette.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Creative Studio',
                                  style: TextStyle(
                                    color: MobilePalette.textPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Pro layout for chat, images, and video',
                                  style: TextStyle(
                                    color: MobilePalette.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: MobilePalette.primarySoft,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Pro Plan',
                              style: TextStyle(
                                color: MobilePalette.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          MobilePill(
                            label: 'Chat',
                            selected:
                                unifiedSettings.selectedModelType ==
                                available_model.ModelType.text,
                            onTap:
                                () => unifiedSettings.setSelectedModelType(
                                  available_model.ModelType.text,
                                ),
                          ),
                          MobilePill(
                            label: 'Image',
                            selected:
                                unifiedSettings.selectedModelType ==
                                available_model.ModelType.image,
                            onTap:
                                () => unifiedSettings.setSelectedModelType(
                                  available_model.ModelType.image,
                                ),
                          ),
                          MobilePill(
                            label: 'Video',
                            selected:
                                unifiedSettings.selectedModelType ==
                                available_model.ModelType.video,
                            onTap:
                                () => unifiedSettings.setSelectedModelType(
                                  available_model.ModelType.video,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                MobileSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const MobileSectionLabel(title: 'Chat Model'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children:
                            chatModel.allProviderNames
                                .map(
                                  (provider) => MobilePill(
                                    label: provider,
                                    selected:
                                        provider == chatModel.selectedProvider,
                                    onTap: () async {
                                      await chatModel.setSelectedProvider(
                                        provider,
                                      );
                                      setState(() {});
                                    },
                                  ),
                                )
                                .toList(),
                      ),
                      const SizedBox(height: 14),
                      ...chatModel.availableModels.map(
                        (model) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.forum_outlined,
                            color:
                                model == chatModel.selectedModel
                                    ? MobilePalette.primary
                                    : MobilePalette.textSecondary,
                          ),
                          title: Text(
                            model,
                            style: const TextStyle(
                              color: MobilePalette.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          trailing:
                              model == chatModel.selectedModel
                                  ? const Icon(
                                    Icons.check_circle,
                                    color: MobilePalette.primary,
                                  )
                                  : const Icon(
                                    Icons.circle_outlined,
                                    color: MobilePalette.border,
                                  ),
                          onTap: () => chatModel.setSelectedModel(model),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                MobileSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const MobileSectionLabel(title: 'Image Model'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children:
                            imageModel.allImageProviderNames
                                .map(
                                  (provider) => MobilePill(
                                    label: provider,
                                    selected:
                                        provider ==
                                        imageModel.selectedImageProvider,
                                    onTap: () async {
                                      await imageModel.setSelectedImageProvider(
                                        provider,
                                      );
                                      setState(() {});
                                    },
                                  ),
                                )
                                .toList(),
                      ),
                      const SizedBox(height: 14),
                      ...imageModel.availableImageModels.map(
                        (model) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.image_outlined,
                            color:
                                model == imageModel.selectedImageModel
                                    ? MobilePalette.primary
                                    : MobilePalette.textSecondary,
                          ),
                          title: Text(
                            model,
                            style: const TextStyle(
                              color: MobilePalette.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle:
                              model == imageModel.selectedImageModel &&
                                      imageModel.selectedImageProvider ==
                                          'Black Forest Labs'
                                  ? Text(
                                    'Aspect ${imageModel.bflAspectRatio ?? '1:1'}',
                                    style: const TextStyle(
                                      color: MobilePalette.textSecondary,
                                    ),
                                  )
                                  : null,
                          trailing:
                              model == imageModel.selectedImageModel
                                  ? const Icon(
                                    Icons.check_circle,
                                    color: MobilePalette.primary,
                                  )
                                  : const Icon(
                                    Icons.circle_outlined,
                                    color: MobilePalette.border,
                                  ),
                          onTap: () => imageModel.setSelectedImageModel(model),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                MobileSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const MobileSectionLabel(title: 'Video Model'),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.movie_creation_outlined,
                          color: MobilePalette.secondary,
                        ),
                        title: Text(
                          videoModel.selectedVideoProvider,
                          style: const TextStyle(
                            color: MobilePalette.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          '${videoModel.videoResolution} • ${videoModel.videoDuration} • ${videoModel.videoAspectRatio}',
                          style: const TextStyle(
                            color: MobilePalette.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children:
                            VideoModelProvider.supportedAspectRatios
                                .map(
                                  (ratio) => MobilePill(
                                    label: ratio,
                                    selected:
                                        ratio == videoModel.videoAspectRatio,
                                    onTap:
                                        () => videoModel.setVideoAspectRatio(
                                          ratio,
                                        ),
                                  ),
                                )
                                .toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                MobileSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const MobileSectionLabel(title: 'Providers'),
                      const SizedBox(height: 12),
                      _ProviderStatusTile(
                        title: 'OpenAI',
                        subtitle: _statusText(
                          apiKeys.openaiApiKey,
                          'Connected',
                          'Needs API key',
                        ),
                        connected: _isConfigured(apiKeys.openaiApiKey),
                        usageLabel:
                            chatModel.selectedProvider == 'OpenAI'
                                ? 'Chat active'
                                : imageModel.selectedImageProvider == 'OpenAI'
                                ? 'Image active'
                                : 'Ready',
                      ),
                      const SizedBox(height: 10),
                      _ProviderStatusTile(
                        title: 'Google',
                        subtitle: _statusText(
                          apiKeys.googleApiKey,
                          'Connected',
                          'Needs API key',
                        ),
                        connected: _isConfigured(apiKeys.googleApiKey),
                        usageLabel:
                            chatModel.selectedProvider == 'Google'
                                ? 'Chat active'
                                : imageModel.selectedImageProvider == 'Google'
                                ? 'Image active'
                                : 'Video active',
                      ),
                      const SizedBox(height: 10),
                      _ProviderStatusTile(
                        title: 'Anthropic',
                        subtitle: _statusText(
                          apiKeys.claudeApiKey,
                          'Connected',
                          'Needs API key',
                        ),
                        connected: _isConfigured(apiKeys.claudeApiKey),
                        usageLabel:
                            chatModel.selectedProvider == 'Anthropic'
                                ? 'Chat active'
                                : 'Ready',
                      ),
                      const SizedBox(height: 10),
                      _ProviderStatusTile(
                        title: 'Black Forest Labs',
                        subtitle: _statusText(
                          apiKeys.fluxKontextApiKey,
                          'Connected',
                          'Needs API key',
                        ),
                        connected: _isConfigured(apiKeys.fluxKontextApiKey),
                        usageLabel:
                            imageModel.selectedImageProvider ==
                                    'Black Forest Labs'
                                ? 'Image active'
                                : 'Ready',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static bool _isConfigured(String? key) {
    return key != null && key.trim().isNotEmpty;
  }

  static String _statusText(String? key, String success, String empty) {
    return _isConfigured(key) ? success : empty;
  }
}

class _ProviderStatusTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool connected;
  final String usageLabel;

  const _ProviderStatusTile({
    required this.title,
    required this.subtitle,
    required this.connected,
    required this.usageLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MobilePalette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: MobilePalette.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor:
                connected
                    ? MobilePalette.primarySoft
                    : MobilePalette.surfaceStrong,
            child: Icon(
              connected ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
              size: 18,
              color:
                  connected
                      ? MobilePalette.primary
                      : MobilePalette.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: MobilePalette.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: MobilePalette.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            usageLabel,
            style: TextStyle(
              color:
                  connected
                      ? MobilePalette.primary
                      : MobilePalette.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
