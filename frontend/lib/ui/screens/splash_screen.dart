import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../core/constants/responsive.dart';
import '../../providers/providers.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.8, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Wait for animation and auth check
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    await authProvider.initialize();

    if (!mounted) return;

    // Navigate based on auth status
    if (authProvider.isAuthenticated) {
      // Initialize FCM push notifications after successful auth
      final notificationProvider = context.read<NotificationProvider>();
      await notificationProvider.initializeFcm();
      notificationProvider.startPolling();

      if (authProvider.isGerant) {
        Navigator.of(context).pushReplacementNamed('/gerant/dashboard');
      } else if (authProvider.isLivreur) {
        Navigator.of(context).pushReplacementNamed('/livreur/home');
      } else {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary,
              AppColors.primaryDark,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated logo
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: r.avatarSize(120),
                  height: r.avatarSize(120),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: r.scale(20),
                        spreadRadius: r.scale(5),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.local_shipping_rounded,
                    size: r.iconSize(60),
                    color: AppColors.primary,
                  ),
                ),
              ),
              r.verticalSpace(32),
              
              // App name
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Text(
                      'Smart Delivery',
                      style: AppStyles.headingLargeR(r).copyWith(
                        color: Colors.white,
                        fontSize: r.fontSize(32),
                        letterSpacing: 2,
                      ),
                    ),
                    r.verticalSpace(8),
                    Text(
                      'Optimisation de livraison OSRM',
                      style: AppStyles.bodyMediumR(r).copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              r.verticalSpace(48),
              
              // Loading indicator
              FadeTransition(
                opacity: _fadeAnimation,
                child: SizedBox(
                  width: r.scale(30),
                  height: r.scale(30),
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: r.scale(3),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
