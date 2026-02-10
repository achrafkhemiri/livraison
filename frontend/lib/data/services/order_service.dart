import '../models/models.dart';
import '../../core/constants/api_constants.dart';
import 'api_service.dart';

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

  Future<Order> updateStatus(int id, String status) async {
    final response = await _api.patch('${ApiConstants.orders}/$id/status?status=$status');
    return Order.fromJson(response);
  }

  Future<Order> assignLivreur(int orderId, int livreurId) async {
    final response = await _api.patch('${ApiConstants.orders}/$orderId/assign/$livreurId');
    return Order.fromJson(response);
  }

  Future<void> delete(int id) async {
    await _api.delete('${ApiConstants.orders}/$id');
  }
}
