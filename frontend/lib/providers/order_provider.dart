import 'package:flutter/foundation.dart';
import '../data/models/models.dart';
import '../data/services/services.dart';

class OrderProvider extends ChangeNotifier {
  final OrderService _service = OrderService();
  
  List<Order> _orders = [];
  List<Order> _pendingOrders = [];
  List<Order> _myOrders = []; // Orders assigned to current livreur
  Order? _selectedOrder;
  bool _isLoading = false;
  String? _errorMessage;

  // Map data
  Map<String, dynamic>? _mapData;
  List<Map<String, dynamic>> _productsStock = [];
  Map<String, dynamic>? _collectionPlan;
  
  List<Order> get orders => _orders;
  List<Order> get pendingOrders => _pendingOrders;
  List<Order> get myOrders => _myOrders;
  Order? get selectedOrder => _selectedOrder;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get mapData => _mapData;
  List<Map<String, dynamic>> get productsStock => _productsStock;
  Map<String, dynamic>? get collectionPlan => _collectionPlan;
  
  // Statistics
  int get totalOrders => _orders.length;
  int get pendingCount => _orders.where((o) => o.status == 'pending').length;
  int get processingCount => _orders.where((o) => o.status == 'processing').length;
  int get shippedCount => _orders.where((o) => o.status == 'shipped').length;
  int get deliveredCount => _orders.where((o) => o.status == 'delivered').length;
  
  // Load all orders (for Gérant)
  Future<void> loadOrders() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _orders = await _service.getAll();
      _pendingOrders = _orders.where((o) => o.status == 'pending').toList();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Load orders by status
  Future<void> loadOrdersByStatus(String status) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _orders = await _service.getByStatus(status);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Load orders for a specific livreur
  Future<void> loadOrdersForLivreur(int livreurId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _myOrders = await _service.getByLivreurId(livreurId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Load pending orders available for a livreur
  Future<void> loadPendingOrdersForLivreur(int livreurId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _pendingOrders = await _service.getPendingOrdersForLivreur(livreurId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Create new order
  Future<bool> createOrder(Order order) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final created = await _service.create(order);
      if (created != null) {
        _orders.add(created);
        if (created.status == 'pending') {
          _pendingOrders.add(created);
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
  
  // Update order
  Future<bool> updateOrder(int id, Order order) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final updated = await _service.update(id, order);
      if (updated != null) {
        _updateOrderInLists(id, updated);
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
  
  // Update order status
  Future<bool> updateOrderStatus(int id, String status) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final updated = await _service.updateStatus(id, status);
      if (updated != null) {
        _updateOrderInLists(id, updated);
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
  
  // Assign order to livreur
  Future<bool> assignOrderToLivreur(int orderId, int livreurId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final updated = await _service.assignLivreur(orderId, livreurId);
      if (updated != null) {
        _updateOrderInLists(orderId, updated);
        // Also add to myOrders if this is the current livreur
        _myOrders.add(updated);
        // Remove from pending
        _pendingOrders.removeWhere((o) => o.id == orderId);
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
  
  // Accept order (for livreur)
  Future<bool> acceptOrder(int orderId, int livreurId) async {
    return await assignOrderToLivreur(orderId, livreurId);
  }
  
  // Mark order as delivered
  Future<bool> markAsDelivered(int orderId) async {
    return await updateOrderStatus(orderId, 'delivered');
  }
  
  // Mark order as shipped (in transit)
  Future<bool> markAsShipped(int orderId) async {
    return await updateOrderStatus(orderId, 'shipped');
  }
  
  // Delete order
  Future<bool> deleteOrder(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      await _service.delete(id);
      _orders.removeWhere((o) => o.id == id);
      _pendingOrders.removeWhere((o) => o.id == id);
      _myOrders.removeWhere((o) => o.id == id);
      if (_selectedOrder?.id == id) {
        _selectedOrder = null;
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
  
  // Helper to update order in all lists
  void _updateOrderInLists(int id, Order updated) {
    int index = _orders.indexWhere((o) => o.id == id);
    if (index != -1) {
      _orders[index] = updated;
    }
    
    index = _pendingOrders.indexWhere((o) => o.id == id);
    if (index != -1) {
      if (updated.status == 'pending') {
        _pendingOrders[index] = updated;
      } else {
        _pendingOrders.removeAt(index);
      }
    }
    
    index = _myOrders.indexWhere((o) => o.id == id);
    if (index != -1) {
      _myOrders[index] = updated;
    }
    
    if (_selectedOrder?.id == id) {
      _selectedOrder = updated;
    }
  }
  
  void selectOrder(Order? order) {
    _selectedOrder = order;
    notifyListeners();
  }
  
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  // Get orders by client
  List<Order> getOrdersByClient(int clientId) {
    return _orders.where((o) => o.clientId == clientId).toList();
  }
  
  // Get active orders (not delivered or cancelled)
  List<Order> get activeOrders {
    return _myOrders.where((o) => 
      o.status != 'delivered' && o.status != 'cancelled' && o.status != 'done'
    ).toList();
  }

  // Orders to collect (assigned but not yet collected)
  List<Order> get ordersToCollect {
    return _myOrders.where((o) => 
      o.collected != true && o.status != 'delivered' && o.status != 'cancelled' && o.status != 'done'
    ).toList();
  }

  // Orders ready to deliver (collected but not yet delivered)
  List<Order> get ordersToDeliver {
    return _myOrders.where((o) => 
      o.collected == true && o.status != 'delivered' && o.status != 'cancelled' && o.status != 'done'
    ).toList();
  }

  // Load map data (société, magasins, depots, livreurs)
  Future<void> loadMapData() async {
    try {
      _mapData = await _service.getMapData();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Load products with stock by société
  Future<void> loadProductsStock() async {
    try {
      _productsStock = await _service.getProductsStock();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Generate collection plan for an order
  Future<Map<String, dynamic>?> generateCollectionPlan(int orderId) async {
    try {
      _collectionPlan = await _service.generateCollectionPlan(orderId);
      notifyListeners();
      return _collectionPlan;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Mark order as collected
  Future<bool> markAsCollected(int orderId) async {
    try {
      final updated = await _service.markAsCollected(orderId);
      _updateOrderInLists(orderId, updated);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
