import 'package:flutter/foundation.dart';
import '../data/models/models.dart';
import '../data/services/services.dart';

class DepotProvider extends ChangeNotifier {
  final DepotService _service = DepotService();
  
  List<Depot> _depots = [];
  Depot? _selectedDepot;
  bool _isLoading = false;
  String? _errorMessage;
  
  List<Depot> get depots => _depots;
  Depot? get selectedDepot => _selectedDepot;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  Future<void> loadDepots() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _depots = await _service.getAll();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> loadDepotsWithStocks() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _depots = await _service.getWithStocks();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> loadDepotsByMagasin(int magasinId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _depots = await _service.getByMagasinId(magasinId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<Depot?> getDepot(int id) async {
    try {
      return await _service.getById(id);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }
  
  Future<bool> createDepot(Depot depot) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final created = await _service.create(depot);
      if (created != null) {
        _depots.add(created);
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
  
  Future<bool> updateDepot(int id, Depot depot) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final updated = await _service.update(id, depot);
      if (updated != null) {
        final index = _depots.indexWhere((d) => d.id == id);
        if (index != -1) {
          _depots[index] = updated;
        }
        if (_selectedDepot?.id == id) {
          _selectedDepot = updated;
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
  
  Future<bool> deleteDepot(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      await _service.delete(id);
      _depots.removeWhere((d) => d.id == id);
      if (_selectedDepot?.id == id) {
        _selectedDepot = null;
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
  
  void selectDepot(Depot? depot) {
    _selectedDepot = depot;
    notifyListeners();
  }
  
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
