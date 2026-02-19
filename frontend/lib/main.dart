import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// Core
import 'core/constants/app_colors.dart';
import 'core/constants/app_styles.dart';

// Providers
import 'providers/providers.dart';

// Models
import 'data/models/models.dart';

// Screens
import 'ui/screens/splash_screen.dart';
import 'ui/screens/auth/login_screen.dart';
import 'ui/screens/gerant/gerant_dashboard.dart';
import 'ui/screens/gerant/magasin_list_screen.dart';
import 'ui/screens/gerant/depot_list_screen.dart';
import 'ui/screens/gerant/livreur_list_screen.dart';
import 'ui/screens/gerant/order_list_screen.dart';
import 'ui/screens/gerant/admin_map_screen.dart';
import 'ui/screens/livreur/livreur_home_screen.dart';
import 'ui/screens/livreur/delivery_map_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  runApp(const SmartDeliveryApp());
}

class SmartDeliveryApp extends StatelessWidget {
  const SmartDeliveryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SocieteProvider()),
        ChangeNotifierProvider(create: (_) => MagasinProvider()),
        ChangeNotifierProvider(create: (_) => DepotProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => LivreurProvider()),
        ChangeNotifierProvider(create: (_) => DeliveryRouteProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        title: 'Smart Delivery',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        initialRoute: '/',
        routes: _buildRoutes(),
        onGenerateRoute: _generateRoute,
      ),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        error: AppColors.error,
        surface: AppColors.surface,
        surfaceContainerHighest: AppColors.background,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: AppStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        hintStyle: AppStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Map<String, WidgetBuilder> _buildRoutes() {
    return {
      '/': (context) => const SplashScreen(),
      '/login': (context) => const LoginScreen(),
      
      // Gérant routes
      '/gerant/dashboard': (context) => const GerantDashboard(),
      '/gerant/societes': (context) => const SocieteListScreen(),
      '/gerant/magasins': (context) => const MagasinListScreen(),
      '/gerant/depots': (context) => const DepotListScreen(),
      '/gerant/livreurs': (context) => const LivreurListScreen(),
      '/gerant/orders': (context) => const OrderListScreen(),
      '/gerant/map': (context) => const AdminMapScreen(),
      
      // Livreur routes
      '/livreur/home': (context) => const LivreurHomeScreen(),
      '/livreur/map': (context) => const DeliveryMapScreen(),
    };
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    // Handle routes with arguments
    return null;
  }
}

// Societe List Screen
class SocieteListScreen extends StatefulWidget {
  const SocieteListScreen({super.key});

  @override
  State<SocieteListScreen> createState() => _SocieteListScreenState();
}

class _SocieteListScreenState extends State<SocieteListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SocieteProvider>().loadSocietes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text('Sociétés', style: AppStyles.headingMedium.copyWith(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<SocieteProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (provider.societes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.business_outlined, size: 64, color: AppColors.textSecondary.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text('Aucune société', style: AppStyles.bodyLarge.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            );
          }
          
          return RefreshIndicator(
            onRefresh: () => provider.loadSocietes(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.societes.length,
              itemBuilder: (context, index) {
                final societe = provider.societes[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.business, color: AppColors.primary),
                    ),
                    title: Text(
                      societe.raisonSociale,
                      style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                    ),
                    subtitle: societe.adresse != null 
                        ? Text(societe.adresse!, style: AppStyles.bodySmall.copyWith(color: AppColors.textSecondary))
                        : null,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pushNamed(context, '/gerant/magasins', arguments: societe.id);
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context) async {
    final nomController = TextEditingController();
    final adresseController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvelle société'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomController,
              decoration: AppStyles.inputDecoration(label: 'Nom *', prefixIcon: Icons.business),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: adresseController,
              decoration: AppStyles.inputDecoration(label: 'Adresse', prefixIcon: Icons.location_on),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nomController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Le nom est obligatoire'), backgroundColor: AppColors.error),
                );
                return;
              }

              final provider = context.read<SocieteProvider>();
              final societe = Societe(
                raisonSociale: nomController.text,
                adresse: adresseController.text.isEmpty ? null : adresseController.text,
              );

              final success = await provider.createSociete(societe);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Société créée' : 'Erreur'),
                    backgroundColor: success ? AppColors.success : AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Créer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
