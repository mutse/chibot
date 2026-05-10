import 'package:chibot/constants/app_constants.dart';
import 'package:chibot/l10n/app_localizations.dart';
import 'package:chibot/screens/mobile/mobile_ui.dart';
import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: MobilePalette.background,
      body: DecoratedBox(
        decoration: buildMobileBackgroundDecoration(),
        child: SafeArea(
          child: Column(
            children: [
              MobileTopBar(
                leading: MobileIconCircleButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => Navigator.of(context).pop(),
                ),
                title: localizations.about,
                subtitle: localizations.appDesc,
                trailing: MobileIconCircleButton(
                  icon: Icons.share_outlined,
                  onTap: () {
                    // TODO: Implement share functionality
                  },
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
                  child: Column(
                    children: [
                      _buildAppInfoSection(context),
                      const SizedBox(height: 14),
                      _buildFeaturesSection(context),
                      const SizedBox(height: 14),
                      _buildSupportedModelsSection(context),
                      const SizedBox(height: 14),
                      _buildHelpSupportSection(context),
                      const SizedBox(height: 14),
                      _buildLegalSection(context),
                      const SizedBox(height: 14),
                      _buildDevelopmentInfoSection(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppInfoSection(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return MobileSurface(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [MobilePalette.primary, Color(0xFF3D9186)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: MobilePalette.shadow,
                  blurRadius: 24,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/images/logo.png',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            localizations.appName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: MobilePalette.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            localizations.appDesc,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: MobilePalette.textSecondary,
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              _buildMetaChip(
                icon: Icons.verified_outlined,
                label: 'v${AppConstants.appVersion}',
              ),
              _buildMetaChip(
                icon: Icons.event_outlined,
                label: localizations.releaseDate,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return _buildSectionShell(
      title: localizations.features,
      child: Column(
        children: [
          _buildFeatureCard(
            icon: Icons.chat_bubble_outline_rounded,
            title: localizations.featureSmartChat,
            description: localizations.featureSmartDesc,
            accent: MobilePalette.primary,
            tint: MobilePalette.primarySoft,
          ),
          const SizedBox(height: 12),
          _buildFeatureCard(
            icon: Icons.image_outlined,
            title: localizations.featureImageGen,
            description: localizations.featureImageGenDesc,
            accent: MobilePalette.secondary,
            tint: const Color(0xFFFFEEE7),
          ),
          const SizedBox(height: 12),
          _buildFeatureCard(
            icon: Icons.tune_rounded,
            title: localizations.featureFlexible,
            description: localizations.featureFlexibleDesc,
            accent: const Color(0xFF2F6D95),
            tint: const Color(0xFFEAF3FA),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportedModelsSection(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final models = [
      (
        name: 'OpenAI GPT-4',
        type: localizations.textChat,
        color: const Color(0xFF2F6D95),
        icon: Icons.psychology_alt_outlined,
      ),
      (
        name: 'Anthropic Claude',
        type: localizations.textChat,
        color: MobilePalette.primary,
        icon: Icons.eco_outlined,
      ),
      (
        name: 'Google Gemini',
        type: localizations.textChat,
        color: const Color(0xFFB36A1D),
        icon: Icons.auto_awesome_outlined,
      ),
      (
        name: 'DALL-E 3',
        type: localizations.textImage,
        color: MobilePalette.secondary,
        icon: Icons.image_search_outlined,
      ),
    ];

    return _buildSectionShell(
      title: localizations.supportModels,
      child: Column(
        children:
            models
                .map(
                  (model) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildModelTile(
                      icon: model.icon,
                      name: model.name,
                      type: model.type,
                      color: model.color,
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }

  Widget _buildHelpSupportSection(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final helpItems = [
      (
        icon: Icons.help_outline_rounded,
        title: localizations.usageHelp,
        color: MobilePalette.primary,
      ),
      (
        icon: Icons.menu_book_outlined,
        title: localizations.userManual,
        color: const Color(0xFF2F6D95),
      ),
      (
        icon: Icons.bug_report_outlined,
        title: localizations.problemFeedback,
        color: MobilePalette.secondary,
      ),
      (
        icon: Icons.alternate_email_rounded,
        title: localizations.contact,
        color: const Color(0xFFB36A1D),
      ),
    ];

    return _buildSectionShell(
      title: localizations.helpSupport,
      child: Column(
        children:
            helpItems
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildListTile(
                      icon: item.icon,
                      title: item.title,
                      color: item.color,
                      onTap: () {
                        // TODO: Implement navigation to help pages
                      },
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }

  Widget _buildLegalSection(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final legalItems = [
      (icon: Icons.security_outlined, title: localizations.privacyPolicy),
      (icon: Icons.description_outlined, title: localizations.termsService),
      (icon: Icons.gavel_outlined, title: localizations.disclaimer),
    ];

    return _buildSectionShell(
      title: localizations.legalInfo,
      child: Column(
        children:
            legalItems
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildListTile(
                      icon: item.icon,
                      title: item.title,
                      color: MobilePalette.textSecondary,
                      onTap: () {
                        // TODO: Implement navigation to legal pages
                      },
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }

  Widget _buildDevelopmentInfoSection(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return MobileSurface(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          const Icon(
            Icons.favorite_outline_rounded,
            color: MobilePalette.secondary,
            size: 22,
          ),
          const SizedBox(height: 10),
          Text(
            localizations.copyright,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: MobilePalette.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            localizations.vision,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: MobilePalette.textSecondary,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionShell({required String title, required Widget child}) {
    return MobileSurface(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: MobilePalette.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildMetaChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: MobilePalette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MobilePalette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: MobilePalette.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: MobilePalette.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
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
    required Color accent,
    required Color tint,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MobilePalette.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
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
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: MobilePalette.textSecondary,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelTile({
    required IconData icon,
    required String name,
    required String type,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MobilePalette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: MobilePalette.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: MobilePalette.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: MobilePalette.surfaceStrong,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: MobilePalette.border),
            ),
            child: Text(
              type,
              style: const TextStyle(
                color: MobilePalette.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
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
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: MobilePalette.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: MobilePalette.border),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: MobilePalette.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: MobilePalette.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
