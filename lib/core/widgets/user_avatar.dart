import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final double radius;
  final VoidCallback? onTap;
  final bool showBorder;
  final Color? borderColor;
  final Color? backgroundColor;
  final IconData defaultIcon;
  final bool isLoading;

  const UserAvatar({
    super.key,
    this.avatarUrl,
    this.radius = 20,
    this.onTap,
    this.showBorder = false,
    this.borderColor,
    this.backgroundColor,
    this.defaultIcon = Icons.person_rounded,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBg = backgroundColor ?? AppTheme.primaryColor.withValues(alpha: 0.12);
    final effectiveBorder = borderColor ?? AppTheme.primaryColor;

    Widget avatarContent = _buildContent(context, effectiveBg);

    if (showBorder) {
      avatarContent = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: effectiveBorder, width: 2),
        ),
        child: avatarContent,
      );
    }

    if (isLoading) {
      avatarContent = Stack(
        alignment: Alignment.center,
        children: [
          avatarContent,
          Container(
            width: radius * 2,
            height: radius * 2,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SizedBox(
                width: radius * 0.8,
                height: radius * 0.8,
                child: const CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: avatarContent,
      );
    }

    return avatarContent;
  }

  Widget _buildContent(BuildContext context, Color bgColor) {
    final url = avatarUrl?.trim();

    if (url == null || url.isEmpty) {
      return _buildDefaultIcon(bgColor);
    }

    // Check if it is a local file
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      final file = File(url);
      if (file.existsSync()) {
        return ClipOval(
          child: Image.file(
            file,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildDefaultIcon(bgColor),
          ),
        );
      }
      return _buildDefaultIcon(bgColor);
    }

    // Network image with error and loading fallback
    return ClipOval(
      child: Image.network(
        url,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: radius * 2,
            height: radius * 2,
            color: bgColor,
            child: Center(
              child: SizedBox(
                width: radius * 0.6,
                height: radius * 0.6,
                child: const CircularProgressIndicator(
                  strokeWidth: 1.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _buildDefaultIcon(bgColor),
      ),
    );
  }

  Widget _buildDefaultIcon(Color bgColor) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          defaultIcon,
          color: AppTheme.primaryColor,
          size: radius * 1.1,
        ),
      ),
    );
  }
}
