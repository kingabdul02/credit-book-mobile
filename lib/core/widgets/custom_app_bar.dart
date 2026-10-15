import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

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
    final shouldShowAvatar = showAvatar ?? !showBackButton;

    return AppBar(
      backgroundColor: backgroundColor ?? Colors.white,
      elevation: 0,
      centerTitle: centerTitle,
      titleSpacing: showBackButton ? 0 : 24,
      automaticallyImplyLeading: showBackButton,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: AppTheme.textDark),
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
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.w800,
                ),
          ),
      actions: [
        if (actions != null) ...actions!,
        if (shouldShowAvatar)
          const Padding(
            padding: EdgeInsets.only(right: 24.0, left: 8.0),
            child: CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
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
