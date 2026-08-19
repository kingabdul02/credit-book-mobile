import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    // Artificial delay for splash screen animation
    await Future.delayed(const Duration(milliseconds: 2500));
    
    final prefs = await SharedPreferences.getInstance();
    final bool isFirstLaunch = prefs.getBool('is_first_launch') ?? true;

    if (!mounted) return;

    if (isFirstLaunch) {
      context.go('/onboarding');
    } else {
      context.go('/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.onBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.textMuted.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                size: 80,
                color: AppTheme.textDark,
              ),
            )
            .animate()
            .scale(duration: 600.ms, curve: Curves.easeOutBack)
            .shimmer(delay: 600.ms, duration: 1500.ms, color: Colors.black12),
            
            const SizedBox(height: 32),
            
            Text(
              'CreditBook',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: AppTheme.textDark,
                fontWeight: FontWeight.w900,
              ),
            )
            .animate()
            .fadeIn(delay: 300.ms, duration: 600.ms)
            .slideY(begin: 0.5, end: 0, curve: Curves.easeOut),
          ],
        ),
      ),
    );
  }
}
