import '../models/models.dart';
import '../../core/constants/api_constants.dart';
import 'api_service.dart';

class ProduitService {
  final ApiService _api = ApiService();

  Future<List<Produit>> getAll() async {
    final response = await _api.get(ApiConstants.produits);
    return (response as List).map((e) => Produit.fromJson(e)).toList();
  }

  Future<Produit> getById(int id) async {
    final response = await _api.get('${ApiConstants.produits}/$id');
    return Produit.fromJson(response);
  }

  Future<Produit> create(Produit produit) async {
    final response = await _api.post(ApiConstants.produits, produit.toJson());
    return Produit.fromJson(response);
  }

  Future<Produit> update(int id, Produit produit) async {
    final response = await _api.put('${ApiConstants.produits}/$id', produit.toJson());
    return Produit.fromJson(response);
  }

  Future<void> delete(int id) async {
    await _api.delete('${ApiConstants.produits}/$id');
  }
}

class StockService {
  final ApiService _api = ApiService();

  Future<List<Stock>> getAll() async {
    final response = await _api.get(ApiConstants.stocks);
    return (response as List).map((e) => Stock.fromJson(e)).toList();
  }

  Future<Stock> getById(int id) async {
    final response = await _api.get('${ApiConstants.stocks}/$id');
    return Stock.fromJson(response);
  }

  Future<List<Stock>> getByDepotId(int depotId) async {
    final response = await _api.get('${ApiConstants.stocks}/depot/$depotId');
    return (response as List).map((e) => Stock.fromJson(e)).toList();
  }

  Future<Stock> create(Stock stock) async {
    final response = await _api.post(ApiConstants.stocks, stock.toJson());
    return Stock.fromJson(response);
  }

  Future<Stock> update(int id, Stock stock) async {
    final response = await _api.put('${ApiConstants.stocks}/$id', stock.toJson());
    return Stock.fromJson(response);
  }

  Future<void> delete(int id) async {
    await _api.delete('${ApiConstants.stocks}/$id');
  }
}

class ClientService {
  final ApiService _api = ApiService();

  Future<List<Client>> getAll() async {
    final response = await _api.get(ApiConstants.clients);
    return (response as List).map((e) => Client.fromJson(e)).toList();
  }

  Future<Client> getById(int id) async {
    final response = await _api.get('${ApiConstants.clients}/$id');
    return Client.fromJson(response);
  }

  Future<Client> create(Client client) async {
    final response = await _api.post(ApiConstants.clients, client.toJson());
    return Client.fromJson(response);
  }

  Future<Client> update(int id, Client client) async {
    final response = await _api.put('${ApiConstants.clients}/$id', client.toJson());
    return Client.fromJson(response);
  }

  Future<void> delete(int id) async {
    await _api.delete('${ApiConstants.clients}/$id');
  }
}

class UtilisateurService {
  final ApiService _api = ApiService();

  Future<List<User>> getAll() async {
    final response = await _api.get(ApiConstants.utilisateurs);
    return (response as List).map((e) => User.fromJson(e)).toList();
  }

  Future<List<User>> getLivreurs() async {
    final response = await _api.get('${ApiConstants.utilisateurs}/livreurs');
    return (response as List).map((e) => User.fromJson(e)).toList();
  }

  Future<User> getById(int id) async {
    final response = await _api.get('${ApiConstants.utilisateurs}/$id');
    return User.fromJson(response);
  }

  Future<User> create(Map<String, dynamic> userData) async {
    final response = await _api.post(ApiConstants.utilisateurs, userData);
    return User.fromJson(response);
  }

  Future<User> update(int id, Map<String, dynamic> userData) async {
    final response = await _api.put('${ApiConstants.utilisateurs}/$id', userData);
    return User.fromJson(response);
  }

  Future<User> updatePosition(int id, double latitude, double longitude) async {
    final response = await _api.patch(
      '${ApiConstants.utilisateurs}/$id/position?latitude=$latitude&longitude=$longitude',
    );
    return User.fromJson(response);
  }

  Future<void> delete(int id) async {
    await _api.delete('${ApiConstants.utilisateurs}/$id');
  }
}
