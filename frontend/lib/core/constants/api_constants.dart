import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  // IP locale de votre ordinateur (mettez à jour si votre IP change)
  // Actuellement la machine a l'IP 192.168.100.53 — remplacez si nécessaire 192.168.1.16.
  static const String _localIp = '192.168.1.19';

  static String get _host {
    if (kIsWeb) return 'localhost';
    // For a physical Android device on the same Wi‑Fi, use the host machine LAN IP.
    // If you use an Android emulator, set the host to 10.0.2.2 manually or
    // run with a dart-define to override this value.
    return _localIp;
  }

  static String get baseUrl => kIsWeb ? 'http://localhost:8080/api' : 'http://$_host:8080/api';

  static String get osrmUrl => kIsWeb ? 'http://localhost:5000' : 'http://$_host:5000';
  
  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String me = '/auth/me';
  static const String changePassword = '/auth/password';
  
  // Societe endpoints
  static const String societes = '/societes';
  
  // Magasin endpoints
  static const String magasins = '/magasins';
  
  // Depot endpoints
  static const String depots = '/depots';
  
  // Produit endpoints
  static const String produits = '/produits';
  
  // Stock endpoints
  static const String stocks = '/stocks';
  
  // Client/User endpoints (consommateurs de l'app consumer)
  static const String clients = '/users';
  
  // Order endpoints
  static const String orders = '/orders';
  
  // Utilisateur endpoints
  static const String utilisateurs = '/utilisateurs';
  
  // TVA endpoints
  static const String tva = '/tva';
  
  // Map & stock endpoints
  static const String mapData = '/map-data';
  static const String productsStock = '/products-stock';

  // Notification endpoints
  static const String notifications = '/notifications';

  // FCM endpoints
  static const String fcmToken = '/fcm/token';
}
