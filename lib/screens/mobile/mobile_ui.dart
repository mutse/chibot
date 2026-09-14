import 'package:flutter/material.dart';

class MobilePalette {
  static const Color background = Color(0xFFF5F7F8);
  static const Color surface = Color(0xFFF6F8F9);
  static const Color surfaceStrong = Color(0xFFFFFFFF);
  static const Color primary = Color(0xFF0F6B69);
  static const Color primarySoft = Color(0xFFE1F0EE);
  static const Color secondary = Color(0xFFEF6248);
  static const Color textPrimary = Color(0xFF132B3B);
  static const Color textSecondary = Color(0xFF66727C);
  static const Color border = Color(0xFFE3E9EA);
  static const Color shadow = Color(0x0812202F);
}

BoxDecoration buildMobileBackgroundDecoration() {
  return const BoxDecoration(color: MobilePalette.background);
}

class MobileSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final Color? color;

  const MobileSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.radius = 16,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? MobilePalette.surfaceStrong.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: MobilePalette.border),
        boxShadow: const [
          BoxShadow(
            color: MobilePalette.shadow,
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class MobilePill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  const MobilePill({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = selected
        ? MobilePalette.primarySoft
        : MobilePalette.surface;
    final borderColor = selected ? MobilePalette.primary : MobilePalette.border;
    final textColor = selected
        ? MobilePalette.primary
        : MobilePalette.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class MobilePrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color? color;

  const MobilePrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: color ?? MobilePalette.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}

class MobileSectionLabel extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const MobileSectionLabel({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: MobilePalette.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: MobilePalette.primary,
              padding: EdgeInsets.zero,
              minimumSize: const Size(44, 44),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel!,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

class MobileTopBar extends StatelessWidget {
  final Widget leading;
  final String title;
  final Widget? trailing;
  final String? subtitle;

  const MobileTopBar({
    super.key,
    required this.leading,
    required this.title,
    this.trailing,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: MobilePalette.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      color: MobilePalette.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class MobileIconCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const MobileIconCircleButton({
    super.key,
    required this.icon,
    this.onTap,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final label = switch (icon) {
      Icons.menu_rounded => '打开菜单',
      Icons.edit_note_rounded => '新建对话',
      Icons.view_list_rounded => '查看会话',
      Icons.history_toggle_off_rounded => '查看历史',
      Icons.refresh_rounded => '刷新',
      Icons.arrow_back_ios_new_rounded => '查看会话',
      Icons.tune_rounded => '模型设置',
      _ => null,
    };
    return IconButton(
      tooltip: label,
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      style: IconButton.styleFrom(
        minimumSize: const Size(44, 44),
        backgroundColor: backgroundColor ?? MobilePalette.surfaceStrong,
        foregroundColor: foregroundColor ?? MobilePalette.textPrimary,
        side: const BorderSide(color: MobilePalette.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

String formatMobileDate(DateTime dateTime) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(dateTime.year, dateTime.month, dateTime.day);
  final difference = today.difference(target).inDays;

  if (difference == 0) {
    return '今天';
  }
  if (difference == 1) {
    return '昨天';
  }
  return '${dateTime.year}/${dateTime.month}/${dateTime.day}';
}

String formatMobileClock(DateTime dateTime) {
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
