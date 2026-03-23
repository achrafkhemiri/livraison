import '../models/models.dart';
import '../../core/constants/api_constants.dart';
import 'api_service.dart';
import 'package:intl/intl.dart';

class OrderService {
  final ApiService _api = ApiService();

  Future<List<Order>> getAll() async {
    final response = await _api.get(ApiConstants.orders);
    return (response as List).map((e) => Order.fromJson(e)).toList();
  }

  Future<Order> getById(int id) async {
    final response = await _api.get('${ApiConstants.orders}/$id');
    return Order.fromJson(response);
  }

  Future<Order> getByNumero(String numero) async {
    final response = await _api.get('${ApiConstants.orders}/numero/$numero');
    return Order.fromJson(response);
  }

  Future<List<Order>> getByClientId(int clientId) async {
    final response = await _api.get('${ApiConstants.orders}/client/$clientId');
    return (response as List).map((e) => Order.fromJson(e)).toList();
  }

  Future<List<Order>> getByLivreurId(int livreurId) async {
    final response = await _api.get('${ApiConstants.orders}/livreur/$livreurId');
    return (response as List).map((e) => Order.fromJson(e)).toList();
  }

  Future<List<Order>> getPendingOrdersForLivreur(int livreurId) async {
    final response = await _api.get('${ApiConstants.orders}/livreur/$livreurId/pending');
    return (response as List).map((e) => Order.fromJson(e)).toList();
  }

  Future<List<Order>> getByStatus(String status) async {
    final response = await _api.get('${ApiConstants.orders}/status/$status');
    return (response as List).map((e) => Order.fromJson(e)).toList();
  }

  Future<Order> create(Order order) async {
    final response = await _api.post(ApiConstants.orders, order.toJson());
    return Order.fromJson(response);
  }

  Future<Order> update(int id, Order order) async {
    final response = await _api.put('${ApiConstants.orders}/$id', order.toJson());
    return Order.fromJson(response);
  }

  Future<Order> updateStatus(int id, String status, {double? distanceKm}) async {
    String url = '${ApiConstants.orders}/$id/status?status=$status';
    if (distanceKm != null) {
      url += '&distanceKm=$distanceKm';
    }
    final response = await _api.patch(url);
    return Order.fromJson(response);
  }

  Future<Order> assignLivreur(int orderId, int livreurId) async {
    final response = await _api.patch('${ApiConstants.orders}/$orderId/assign/$livreurId');
    return Order.fromJson(response);
  }

  Future<void> delete(int id) async {
    await _api.delete('${ApiConstants.orders}/$id');
  }

  // ===== Map & Collection endpoints =====

  /// Get map data (société, magasins, depots, livreurs markers)
  Future<Map<String, dynamic>> getMapData() async {
    final response = await _api.get(ApiConstants.mapData);
    return response as Map<String, dynamic>;
  }

  /// Get products with stock grouped by depot for the admin's société
  Future<List<Map<String, dynamic>>> getProductsStock() async {
    final response = await _api.get(ApiConstants.productsStock);
    return (response as List).map((e) => e as Map<String, dynamic>).toList();
  }

  /// Generate collection plan for an order
  Future<Map<String, dynamic>> generateCollectionPlan(int orderId) async {
    final response = await _api.post('${ApiConstants.orders}/$orderId/collection-plan', {});
    return response as Map<String, dynamic>;
  }

  /// Generate optimal collection plan for multiple orders (min depots + shortest path)
  Future<Map<String, dynamic>> generateOptimalCollectionPlan(
      List<int> orderIds, {double? livreurLat, double? livreurLon}) async {
    final body = <String, dynamic>{'orderIds': orderIds};
    if (livreurLat != null) body['livreurLat'] = livreurLat;
    if (livreurLon != null) body['livreurLon'] = livreurLon;
    final response = await _api.post('${ApiConstants.orders}/optimal-collection-plan', body);
    return response as Map<String, dynamic>;
  }

  /// Mark order as collected (all items picked up from depots)
  Future<Order> markAsCollected(int orderId) async {
    final response = await _api.patch('${ApiConstants.orders}/$orderId/collected');
    return Order.fromJson(response);
  }

  /// Mark specific items as collected for an order (partial collection)
  Future<Order> markItemsCollected(int orderId, List<Map<String, dynamic>> items) async {
    final response = await _api.postList('${ApiConstants.orders}/$orderId/collected-items', items);
    return Order.fromJson(response);
  }

  // ===== Assignment workflow =====

  /// Accept proposed assignment (livreur)
  Future<Order> acceptAssignment(int orderId) async {
    final response = await _api.patch('${ApiConstants.orders}/$orderId/accept');
    return Order.fromJson(response);
  }

  /// Reject proposed assignment (livreur)
  Future<Order> rejectAssignment(int orderId) async {
    final response = await _api.patch('${ApiConstants.orders}/$orderId/reject');
    return Order.fromJson(response);
  }

  /// Report that client is absent at delivery location (livreur)
  Future<Order> reportClientAbsent(int orderId) async {
    final response = await _api.patch('${ApiConstants.orders}/$orderId/client-absent');
    return Order.fromJson(response);
  }

  /// Get orders proposed to the current livreur
  Future<List<Order>> getProposedOrders() async {
    final response = await _api.get('${ApiConstants.orders}/proposed');
    return (response as List).map((e) => Order.fromJson(e)).toList();
  }

  /// Get recommended livreurs for an order (admin)
  Future<List<Map<String, dynamic>>> recommendLivreurs(int orderId) async {
    final response = await _api.get('${ApiConstants.orders}/$orderId/recommend-livreurs');
    return (response as List).map((e) => e as Map<String, dynamic>).toList();
  }

  /// Search orders with pagination, filtering, and search
  Future<PageResponse<Order>> searchOrders({
    int page = 0,
    int size = 10,
    String? search,
    String? status,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final params = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
    };
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (status != null && status.isNotEmpty && status != 'all') params['status'] = status;
    if (dateFrom != null) params['dateFrom'] = dateFormat.format(dateFrom);
    if (dateTo != null) params['dateTo'] = dateFormat.format(dateTo);

    final queryString = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    final response = await _api.get('${ApiConstants.orders}/search?$queryString');
    return PageResponse.fromJson(response as Map<String, dynamic>, Order.fromJson);
  }
}
