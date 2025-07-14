import 'package:flutter/material.dart';
import 'package:chibot/l10n/app_localizations.dart';
import 'package:chibot/constants/app_constants.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          localizations.about,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.black54, size: 20),
            onPressed: () {
              // TODO: Implement share functionality
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // App Info Section
            _buildAppInfoSection(context),

            // Features Section
            _buildFeaturesSection(context),

            // Supported Features Section
            // _buildSupportedFeaturesSection(context),

            // Supported Models Section
            _buildSupportedModelsSection(context),

            // Help & Support Section
            _buildHelpSupportSection(context),

            // Legal Information Section
            _buildLegalSection(context),

            // Development Info Section
            _buildDevelopmentInfoSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfoSection(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // App Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/logo.png',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // App Name
          Text(
            localizations.appName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),

          // App Description
          Text(
            localizations.appDesc,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 12),

          // Version Info
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'v${AppConstants.appVersion}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(width: 16),
              const Text(
                '•',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(width: 16),
              Text(
                localizations.releaseDate,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.features,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          // Feature Cards
          _buildFeatureCard(
            icon: Icons.chat_bubble_outline,
            title: localizations.featureSmartChat,
            description: localizations.featureSmartDesc,
            gradient: const LinearGradient(
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          const SizedBox(height: 12),

          _buildFeatureCard(
            icon: Icons.image,
            title: localizations.featureImageGen,
            description: localizations.featureImageGenDesc,
            gradient: const LinearGradient(
              colors: [Color(0xFFF093FB), Color(0xFFF5576C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          const SizedBox(height: 12),

          _buildFeatureCard(
            icon: Icons.settings,
            title: localizations.featureFlexible,
            description: localizations.featureFlexibleDesc,
            gradient: const LinearGradient(
              colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Gradient gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportedFeaturesSection(BuildContext context) {
    final features = [
      '文字对话',
      '文生图',
      '历史记录',
      '多模型支持',
      '自定义配置',
      '离线缓存',
      '跨平台同步',
      '数据导出',
    ];

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '支持的功能',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
            ),
            itemCount: features.length,
            itemBuilder: (context, index) {
              return Row(
                children: [
                  const Icon(Icons.check, color: Colors.green, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    features[index],
                    style: const TextStyle(fontSize: 11, color: Colors.black87),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSupportedModelsSection(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final models = [
      {
        'name': 'OpenAI GPT-4',
        'type': localizations.textChat,
        'color': const Color(0xFF2563EB),
        'icon': Icons.psychology,
      },
      {
        'name': 'Anthropic Claude',
        'type': localizations.textChat,
        'color': const Color(0xFF059669),
        'icon': Icons.eco,
      },
      {
        'name': 'Google Gemini',
        'type': localizations.textChat,
        'color': const Color(0xFFD97706),
        'icon': Icons.diamond,
      },
      {
        'name': 'DALL-E 3',
        'type': localizations.textImage,
        'color': const Color(0xFF7C3AED),
        'icon': Icons.image,
      },
    ];

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.supportModels,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          ...models.map(
            (model) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: model['color'] as Color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      model['icon'] as IconData,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      model['name'] as String,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Text(
                    model['type'] as String,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSupportSection(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final helpItems = [
      {
        'icon': Icons.help_outline,
        'title': localizations.usageHelp,
        'color': const Color(0xFF2563EB),
      },
      {
        'icon': Icons.book,
        'title': localizations.userManual,
        'color': const Color(0xFF059669),
      },
      {
        'icon': Icons.bug_report,
        'title': localizations.problemFeedback,
        'color': const Color(0xFFD97706),
      },
      {
        'icon': Icons.email,
        'title': localizations.contact,
        'color': const Color(0xFF7C3AED),
      },
    ];

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.helpSupport,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          ...helpItems.map(
            (item) => _buildListTile(
              icon: item['icon'] as IconData,
              title: item['title'] as String,
              color: item['color'] as Color,
              onTap: () {
                // TODO: Implement navigation to help pages
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalSection(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final legalItems = [
      {'icon': Icons.security, 'title': localizations.privacyPolicy},
      {'icon': Icons.description, 'title': localizations.termsService},
      {'icon': Icons.gavel, 'title': localizations.disclaimer},
    ];

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.legalInfo,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          ...legalItems.map(
            (item) => _buildListTile(
              icon: item['icon'] as IconData,
              title: item['title'] as String,
              color: Colors.grey,
              onTap: () {
                // TODO: Implement navigation to legal pages
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDevelopmentInfoSection(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 1),
      child: Column(
        children: [
          Text(
            localizations.copyright,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            localizations.vision,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
