import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../data/models/models.dart';
import '../data/services/services.dart';

class LivreurProvider extends ChangeNotifier {
  final UtilisateurService _service = UtilisateurService();
  
  List<User> _livreurs = [];
  User? _currentLivreur;
  LatLng? _currentPosition;
  bool _isLoading = false;
  bool _isTrackingPosition = false;
  String? _errorMessage;
  
  List<User> get livreurs => _livreurs;
  User? get currentLivreur => _currentLivreur;
  LatLng? get currentPosition => _currentPosition;
  bool get isLoading => _isLoading;
  bool get isTrackingPosition => _isTrackingPosition;
  String? get errorMessage => _errorMessage;
  
  // Load all livreurs (for Gérant)
  Future<void> loadLivreurs() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _livreurs = await _service.getLivreurs();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Get livreur by id
  Future<User?> getLivreur(int id) async {
    try {
      return await _service.getById(id);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }
  
  // Create new livreur
  Future<bool> createLivreur(User livreur) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      // Ensure role is livreur
      final livreurData = {
        'nom': livreur.nom,
        'prenom': livreur.prenom,
        'email': livreur.email,
        'role': 'LIVREUR',
        'telephone': livreur.telephone,
        'latitude': livreur.latitude,
        'longitude': livreur.longitude,
      };
      
      final created = await _service.create(livreurData);
      _livreurs.add(created);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Update livreur
  Future<bool> updateLivreur(int id, User livreur) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final updated = await _service.update(id, livreur.toJson());
      final index = _livreurs.indexWhere((l) => l.id == id);
      if (index != -1) {
        _livreurs[index] = updated;
      }
      if (_currentLivreur?.id == id) {
        _currentLivreur = updated;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Delete livreur
  Future<bool> deleteLivreur(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      await _service.delete(id);
      _livreurs.removeWhere((l) => l.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Set current livreur (for livreur app)
  void setCurrentLivreur(User livreur) {
    _currentLivreur = livreur;
    notifyListeners();
  }
  
  // Update current position
  Future<bool> updatePosition(LatLng position) async {
    _currentPosition = position;
    notifyListeners();
    
    if (_currentLivreur?.id != null) {
      try {
        await _service.updatePosition(
          _currentLivreur!.id!,
          position.latitude,
          position.longitude,
        );
        return true;
      } catch (e) {
        _errorMessage = e.toString();
        return false;
      }
    }
    return false;
  }
  
  // Start position tracking
  Future<bool> startPositionTracking() async {
    try {
      // Check permissions
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _errorMessage = 'Les services de localisation sont désactivés.';
        notifyListeners();
        return false;
      }
      
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _errorMessage = 'Permission de localisation refusée.';
          notifyListeners();
          return false;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        _errorMessage = 'Permission de localisation définitivement refusée.';
        notifyListeners();
        return false;
      }
      
      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      _currentPosition = LatLng(position.latitude, position.longitude);
      _isTrackingPosition = true;
      notifyListeners();
      
      // Update on server
      await updatePosition(_currentPosition!);
      
      // Start listening for position updates
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Update every 10 meters
        ),
      ).listen((Position position) {
        _currentPosition = LatLng(position.latitude, position.longitude);
        notifyListeners();
        updatePosition(_currentPosition!);
      });
      
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isTrackingPosition = false;
      notifyListeners();
      return false;
    }
  }
  
  // Stop position tracking
  void stopPositionTracking() {
    _isTrackingPosition = false;
    notifyListeners();
  }
  
  // Get current position once
  Future<LatLng?> getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }
      
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        return null;
      }
      
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      _currentPosition = LatLng(position.latitude, position.longitude);
      notifyListeners();
      return _currentPosition;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    }
  }
  
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
