import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/constants/responsive.dart';
import '../../../providers/providers.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      // Initialize FCM push notifications after successful login
      final notificationProvider = context.read<NotificationProvider>();
      await notificationProvider.initializeFcm();
      notificationProvider.startPolling();

      if (!mounted) return;

      // Navigation will be handled by the router based on role
      if (authProvider.isGerant) {
        Navigator.of(context).pushReplacementNamed('/gerant/dashboard');
      } else if (authProvider.isLivreur) {
        Navigator.of(context).pushReplacementNamed('/livreur/home');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Échec de connexion'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.primaryLight,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: r.paddingAll(24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: r.maxContentWidth),
                    child: Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(r.radius(20)),
                      ),
                      child: Padding(
                        padding: r.paddingAll(32),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Logo / Icon
                              Container(
                                width: r.avatarSize(80),
                                height: r.avatarSize(80),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.local_shipping_rounded,
                                  size: r.iconSize(40),
                                  color: AppColors.primary,
                                ),
                              ),
                              r.verticalSpace(24),
                              
                              // Title
                              Text(
                                'Smart Delivery',
                                style: AppStyles.headingLargeR(r).copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                              r.verticalSpace(8),
                              Text(
                                'Connectez-vous à votre compte',
                                style: AppStyles.bodyMediumR(r).copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              r.verticalSpace(32),
                              
                              // Username field
                              TextFormField(
                                controller: _usernameController,
                                style: TextStyle(fontSize: r.fontSize(14)),
                                decoration: AppStyles.inputDecorationR(
                                  label: 'Nom d\'utilisateur',
                                  hint: 'Entrez votre nom d\'utilisateur',
                                  prefixIcon: Icons.person_outline,
                                  r: r,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Veuillez entrer votre nom d\'utilisateur';
                                  }
                                  return null;
                                },
                                textInputAction: TextInputAction.next,
                              ),
                              r.verticalSpace(16),
                              
                              // Password field
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                style: TextStyle(fontSize: r.fontSize(14)),
                                decoration: AppStyles.inputDecorationR(
                                  label: 'Mot de passe',
                                  hint: 'Entrez votre mot de passe',
                                  prefixIcon: Icons.lock_outline,
                                  r: r,
                                ).copyWith(
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: AppColors.textSecondary,
                                      size: r.iconSize(22),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Veuillez entrer votre mot de passe';
                                  }
                                  return null;
                                },
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _handleLogin(),
                              ),
                              r.verticalSpace(24),
                              
                              // Login button
                              Consumer<AuthProvider>(
                                builder: (context, auth, _) {
                                  return SizedBox(
                                    width: double.infinity,
                                    height: r.buttonHeight,
                                    child: ElevatedButton(
                                      onPressed: auth.isLoading ? null : _handleLogin,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(r.radius(12)),
                                        ),
                                        elevation: 2,
                                      ),
                                      child: auth.isLoading
                                          ? SizedBox(
                                              width: r.scale(24),
                                              height: r.scale(24),
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: r.scale(2),
                                              ),
                                            )
                                          : Text(
                                              'Se connecter',
                                              style: AppStyles.bodyLargeR(r).copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                    ),
                                  );
                                },
                              ),
                              r.verticalSpace(16),
                              
                              // Forgot password
                              TextButton(
                                onPressed: () {
                                  // TODO: Implement forgot password
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Contactez l\'administrateur pour réinitialiser votre mot de passe'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                child: Text(
                                  'Mot de passe oublié ?',
                                  style: AppStyles.bodySmallR(r).copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
