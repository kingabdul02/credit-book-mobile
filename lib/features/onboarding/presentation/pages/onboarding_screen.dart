import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPageData> _pages = [
    OnboardingPageData(
      title: 'Track Every Penny',
      subtitle: 'Effortlessly log who owes you and who you owe in seconds.',
      icon: Icons.account_balance_wallet_rounded,
    ),
    OnboardingPageData(
      title: 'Offline First',
      subtitle: 'No internet? No problem. CreditBook works entirely offline and syncs when you\'re back.',
      icon: Icons.wifi_off_rounded,
    ),
    OnboardingPageData(
      title: 'Fast & Frictionless',
      subtitle: 'Record debts in just 3 taps. The fastest ledger you\'ll ever use.',
      icon: Icons.bolt_rounded,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() async {
    if (_currentPage == _pages.length - 1) {
      // Finish onboarding
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_first_launch', false);
      if (mounted) {
        context.go('/auth');
      }
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.onBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxHeight < 500;

            final pageView = PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                return _buildPage(_pages[index]);
              },
            );

            Widget content = Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('is_first_launch', false);
                      if (context.mounted) {
                        context.go('/auth');
                      }
                    },
                    child: Text(
                      'Skip',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textDark.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                
                if (isSmallScreen)
                  SizedBox(height: 400, child: pageView)
                else
                  Expanded(child: pageView),
                  
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: List.generate(
                          _pages.length,
                          (index) => _buildDot(index),
                        ),
                      ),
                      GestureDetector(
                        onTap: _onNext,
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            color: AppTheme.textDark,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _currentPage == _pages.length - 1 
                                ? Icons.check 
                                : Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ).animate(target: _currentPage == _pages.length - 1 ? 1 : 0)
                          .scale(duration: 300.ms, begin: const Offset(1, 1), end: const Offset(1.1, 1.1))
                          .shimmer(delay: 500.ms),
                      ),
                    ],
                  ),
                ),
              ],
            );

            if (isSmallScreen) {
              return SingleChildScrollView(child: content);
            }
            return content;
          },
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    bool isActive = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(right: 8),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive ? AppTheme.textDark : AppTheme.textMuted.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildPage(OnboardingPageData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppTheme.textMuted.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.textMuted.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    data.icon,
                    size: 80,
                    color: AppTheme.textDark,
                  ),
                )
                .animate()
                .scale(duration: 600.ms, curve: Curves.easeOutBack)
                .fadeIn(duration: 600.ms),
                
                const SizedBox(height: 48),
                
                Text(
                  data.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w800,
                  ),
                )
                .animate()
                .slideY(begin: 0.2, end: 0, duration: 500.ms, curve: Curves.easeOut)
                .fadeIn(duration: 500.ms),
                
                const SizedBox(height: 16),
                
                Text(
                  data.subtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textDark.withValues(alpha: 0.7),
                    height: 1.5,
                  ),
                )
                .animate(delay: 100.ms)
                .slideY(begin: 0.2, end: 0, duration: 500.ms, curve: Curves.easeOut)
                .fadeIn(duration: 500.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OnboardingPageData {
  final String title;
  final String subtitle;
  final IconData icon;

  OnboardingPageData({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}
