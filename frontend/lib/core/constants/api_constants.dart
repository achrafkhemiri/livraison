import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  // IP locale de votre ordinateur (changer si nécessaire)
  static const String _localIp = '192.168.100.53';
  
  // Use localhost for web, local IP for physical phone
  static String get baseUrl => kIsWeb 
      ? 'http://localhost:8080/api' 
      : 'http://$_localIp:8080/api';
  
  static String get osrmUrl => kIsWeb 
      ? 'http://localhost:5000' 
      : 'http://$_localIp:5000';
  
  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  
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
}
