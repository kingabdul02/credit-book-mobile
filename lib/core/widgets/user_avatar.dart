import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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

  /// Normalizes any avatar URL returned from the server or local storage:
  /// - Handles local device file paths
  /// - Rewrites /storage/avatars/ paths to /api/v1/avatars/ to bypass server 403 symlink restrictions
  /// - Replaces localhost / 127.0.0.1 with the configured API host
  /// - Upgrades plain HTTP to HTTPS to comply with Android network security policies
  static String? resolveUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return null;
    final trimmed = rawUrl.trim();

    // Check if it's a valid local file on the device
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      final file = File(trimmed);
      if (file.existsSync()) {
        return trimmed;
      }
    }

    // Determine the base origin from dotenv API_BASE_URL (safe if dotenv not initialized in unit tests)
    String? apiBase;
    try {
      if (dotenv.isInitialized) {
        apiBase = dotenv.env['API_BASE_URL'];
      }
    } catch (_) {
      apiBase = null;
    }
    apiBase ??= 'https://creditbook.smartapps.com.ng/api/v1';

    final apiUri = Uri.tryParse(apiBase);
    final origin = (apiUri != null && apiUri.hasScheme && apiUri.hasAuthority)
        ? '${apiUri.scheme}://${apiUri.authority}'
        : 'https://creditbook.smartapps.com.ng';

    var path = trimmed;

    // Replace localhost or 127.0.0.1 with remote API origin
    if (path.contains('://localhost') || path.contains('://127.0.0.1')) {
      final parsed = Uri.tryParse(path);
      if (parsed != null) {
        path = parsed.path + (parsed.hasQuery ? '?${parsed.query}' : '');
      }
    }

    // If it's a relative path starting with / or storage/
    if (path.startsWith('/')) {
      path = '$origin$path';
    } else if (path.startsWith('storage/')) {
      path = '$origin/$path';
    } else if (!path.startsWith('http://') && !path.startsWith('https://')) {
      path = '$origin/$path';
    }

    // Upgrade http to https for creditbook domains to avoid Android cleartext blocking
    if (path.startsWith('http://') && path.contains('creditbook.smartapps.com.ng')) {
      path = path.replaceFirst('http://', 'https://');
    }

    // If path points to /storage/avatars/, redirect to /api/v1/avatars/ to bypass LiteSpeed 403 Forbidden
    if (path.contains('/storage/avatars/')) {
      final filename = path.split('/storage/avatars/').last;
      path = '$origin/api/v1/avatars/$filename';
    }

    return path;
  }

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
    final resolved = resolveUrl(avatarUrl);

    if (resolved == null || resolved.isEmpty) {
      return _buildDefaultIcon(bgColor);
    }

    // Check if it is a local file
    if (!resolved.startsWith('http://') && !resolved.startsWith('https://')) {
      final file = File(resolved);
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
        resolved,
        key: ValueKey(resolved),
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
