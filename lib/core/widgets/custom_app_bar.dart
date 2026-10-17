import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import 'user_avatar.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBack;
  final bool? showAvatar;
  final Color? backgroundColor;
  final bool centerTitle;

  const CustomAppBar({
    super.key,
    required this.title,
    this.titleWidget,
    this.actions,
    this.showBackButton = true,
    this.onBack,
    this.showAvatar,
    this.backgroundColor,
    this.centerTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark ? AppTheme.darkBackground : Colors.white;
    final defaultTextColor = isDark ? AppTheme.darkTextPrimary : AppTheme.textDark;

    final shouldShowAvatar = showAvatar ?? false;
    final authState = shouldShowAvatar ? context.watch<AuthBloc>().state : null;
    final user = authState is AuthSuccess ? authState.user : null;

    return AppBar(
      backgroundColor: backgroundColor ?? defaultBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: centerTitle,
      titleSpacing: showBackButton ? 0 : 24,
      automaticallyImplyLeading: showBackButton,
      leading: showBackButton
          ? IconButton(
              icon: Icon(Icons.arrow_back, color: defaultTextColor),
              onPressed: onBack ?? () {
                if (context.canPop()) {
                  context.pop();
                }
              },
            )
          : null,
      title: titleWidget ??
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: defaultTextColor,
                  fontWeight: FontWeight.w800,
                ),
          ),
      actions: [
        if (actions != null) ...actions!,
        if (shouldShowAvatar)
          Padding(
            padding: const EdgeInsets.only(right: 24.0, left: 8.0),
            child: UserAvatar(
              avatarUrl: user?.avatarUrl,
              radius: 16,
              onTap: () => context.push('/profile'),
            ),
          )
        else if (actions != null && actions!.isNotEmpty)
          const SizedBox(width: 12),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
