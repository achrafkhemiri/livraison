import 'package:flutter/foundation.dart';
import '../data/models/models.dart';
import '../data/services/services.dart';

class MagasinProvider extends ChangeNotifier {
  final MagasinService _service = MagasinService();
  
  List<Magasin> _magasins = [];
  Magasin? _selectedMagasin;
  bool _isLoading = false;
  String? _errorMessage;
  
  List<Magasin> get magasins => _magasins;
  Magasin? get selectedMagasin => _selectedMagasin;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  Future<void> loadMagasins() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _magasins = await _service.getAll();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> loadMagasinsBySociete(int societeId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _magasins = await _service.getBySocieteId(societeId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<Magasin?> getMagasin(int id) async {
    try {
      return await _service.getById(id);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }
  
  Future<bool> createMagasin(Magasin magasin) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final created = await _service.create(magasin);
      if (created != null) {
        _magasins.add(created);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> updateMagasin(int id, Magasin magasin) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final updated = await _service.update(id, magasin);
      if (updated != null) {
        final index = _magasins.indexWhere((m) => m.id == id);
        if (index != -1) {
          _magasins[index] = updated;
        }
        if (_selectedMagasin?.id == id) {
          _selectedMagasin = updated;
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> deleteMagasin(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      await _service.delete(id);
      _magasins.removeWhere((m) => m.id == id);
      if (_selectedMagasin?.id == id) {
        _selectedMagasin = null;
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
  
  void selectMagasin(Magasin? magasin) {
    _selectedMagasin = magasin;
    notifyListeners();
  }
  
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
