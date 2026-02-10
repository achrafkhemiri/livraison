import 'package:flutter/foundation.dart';
import '../data/models/models.dart';
import '../data/services/services.dart';

class SocieteProvider extends ChangeNotifier {
  final SocieteService _service = SocieteService();
  
  List<Societe> _societes = [];
  Societe? _selectedSociete;
  bool _isLoading = false;
  String? _errorMessage;
  
  List<Societe> get societes => _societes;
  Societe? get selectedSociete => _selectedSociete;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  Future<void> loadSocietes() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _societes = await _service.getAll();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<Societe?> getSociete(int id) async {
    try {
      return await _service.getById(id);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }
  
  Future<bool> createSociete(Societe societe) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final created = await _service.create(societe);
      if (created != null) {
        _societes.add(created);
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
  
  Future<bool> updateSociete(int id, Societe societe) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final updated = await _service.update(id, societe);
      if (updated != null) {
        final index = _societes.indexWhere((s) => s.id == id);
        if (index != -1) {
          _societes[index] = updated;
        }
        if (_selectedSociete?.id == id) {
          _selectedSociete = updated;
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
  
  Future<bool> deleteSociete(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      await _service.delete(id);
      _societes.removeWhere((s) => s.id == id);
      if (_selectedSociete?.id == id) {
        _selectedSociete = null;
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
  
  void selectSociete(Societe? societe) {
    _selectedSociete = societe;
    notifyListeners();
  }
  
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
