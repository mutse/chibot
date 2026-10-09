import 'package:flutter/material.dart';

import '../mobile_ui.dart';

/// 设置页通用 glass 风格小组件
///
/// 从 SettingsScreen 提取的纯展示型组件：所有样式参数与原 `_buildGlass*`
/// 方法保持一致，调用时只需把 `_buildXxx(` 换成对应的组件名。

/// 玻璃拟态卡片容器
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 22.0,
  });

  @override
  Widget build(BuildContext context) {
    return MobileSurface(
      margin: margin ?? const EdgeInsets.only(bottom: 16.0),
      padding: padding ?? const EdgeInsets.all(16.0),
      radius: borderRadius,
      child: child,
    );
  }
}

InputDecoration _glassFieldDecoration({
  String? hintText,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: const TextStyle(
      color: MobilePalette.textSecondary,
      fontSize: 14,
    ),
    filled: true,
    fillColor: MobilePalette.surface,
    suffixIcon: suffixIcon,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: MobilePalette.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: MobilePalette.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: MobilePalette.primary, width: 1.5),
    ),
  );
}

/// 玻璃拟态文本输入框
class GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final VoidCallback? onClear;

  const GlassTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: MobilePalette.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      decoration: _glassFieldDecoration(
        hintText: hintText,
        suffixIcon:
            onClear != null
                ? IconButton(
                  icon: const Icon(
                    Icons.clear_rounded,
                    color: MobilePalette.textSecondary,
                  ),
                  onPressed: onClear,
                )
                : null,
      ),
    );
  }
}

/// 可选中的胶囊标签
class GlassChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  const GlassChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return MobilePill(
      label: label,
      selected: selected,
      onTap: () => onSelected(!selected),
    );
  }
}

/// 玻璃拟态下拉选择框
class GlassDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? hintText;

  const GlassDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: onChanged,
      isExpanded: true,
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: MobilePalette.textSecondary,
      ),
      style: const TextStyle(
        color: MobilePalette.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      dropdownColor: MobilePalette.surfaceStrong,
      decoration: _glassFieldDecoration(hintText: hintText),
    );
  }
}

/// 玻璃拟态主按钮
class GlassButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData icon;
  final Color? backgroundColor;

  const GlassButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.icon,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: backgroundColor ?? MobilePalette.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}

const TextStyle _sectionTitleStyle = TextStyle(
  fontSize: 15,
  fontWeight: FontWeight.w700,
  color: MobilePalette.textPrimary,
);

/// 分区标题
class SettingsSectionTitle extends StatelessWidget {
  final String title;

  const SettingsSectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: _sectionTitleStyle);
  }
}

/// 标题 + 输入框的标准字段分区
class SimpleFieldSection extends StatelessWidget {
  final String title;
  final Widget field;
  final String? helperText;
  final double spacingBeforeField;

  const SimpleFieldSection({
    super.key,
    required this.title,
    required this.field,
    this.helperText,
    this.spacingBeforeField = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionTitle(title),
        if (helperText != null) ...[
          const SizedBox(height: 4),
          Text(
            helperText!,
            style: const TextStyle(
              fontSize: 12,
              color: MobilePalette.textSecondary,
            ),
          ),
        ],
        SizedBox(height: spacingBeforeField),
        field,
      ],
    );
  }
}

/// 行内小圆形操作按钮
class InlineActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  const InlineActionButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return MobileIconCircleButton(icon: icon, onTap: onTap, tooltip: tooltip);
  }
}

/// 带删除按钮的模型列表行
class ModelListTile extends StatelessWidget {
  final String title;
  final VoidCallback onDelete;

  const ModelListTile({super.key, required this.title, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: MobilePalette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: MobilePalette.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: MobilePalette.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Color(0xFFD95C45),
            ),
            tooltip: '删除',
          ),
        ],
      ),
    );
  }
}

/// 标题 + 开关的行
class SettingsSwitchRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsSwitchRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: MobilePalette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: MobilePalette.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: MobilePalette.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      color: MobilePalette.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            activeThumbColor: Colors.white,
            activeTrackColor: MobilePalette.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
