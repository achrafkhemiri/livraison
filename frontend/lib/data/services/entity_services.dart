import '../models/models.dart';
import '../../core/constants/api_constants.dart';
import 'api_service.dart';

class SocieteService {
  final ApiService _api = ApiService();

  Future<List<Societe>> getAll() async {
    final response = await _api.get(ApiConstants.societes);
    return (response as List).map((e) => Societe.fromJson(e)).toList();
  }

  Future<Societe> getById(int id) async {
    final response = await _api.get('${ApiConstants.societes}/$id');
    return Societe.fromJson(response);
  }

  Future<Societe> create(Societe societe) async {
    final response = await _api.post(ApiConstants.societes, societe.toJson());
    return Societe.fromJson(response);
  }

  Future<Societe> update(int id, Societe societe) async {
    final response = await _api.put('${ApiConstants.societes}/$id', societe.toJson());
    return Societe.fromJson(response);
  }

  Future<void> delete(int id) async {
    await _api.delete('${ApiConstants.societes}/$id');
  }
}

class MagasinService {
  final ApiService _api = ApiService();

  Future<List<Magasin>> getAll() async {
    final response = await _api.get(ApiConstants.magasins);
    return (response as List).map((e) => Magasin.fromJson(e)).toList();
  }

  Future<Magasin> getById(int id) async {
    final response = await _api.get('${ApiConstants.magasins}/$id');
    return Magasin.fromJson(response);
  }

  Future<List<Magasin>> getBySocieteId(int societeId) async {
    final response = await _api.get('${ApiConstants.magasins}/societe/$societeId');
    return (response as List).map((e) => Magasin.fromJson(e)).toList();
  }

  Future<Magasin> create(Magasin magasin) async {
    final response = await _api.post(ApiConstants.magasins, magasin.toJson());
    return Magasin.fromJson(response);
  }

  Future<Magasin> update(int id, Magasin magasin) async {
    final response = await _api.put('${ApiConstants.magasins}/$id', magasin.toJson());
    return Magasin.fromJson(response);
  }

  Future<void> delete(int id) async {
    await _api.delete('${ApiConstants.magasins}/$id');
  }
}

class DepotService {
  final ApiService _api = ApiService();

  Future<List<Depot>> getAll() async {
    final response = await _api.get(ApiConstants.depots);
    return (response as List).map((e) => Depot.fromJson(e)).toList();
  }

  Future<List<Depot>> getWithStocks() async {
    final response = await _api.get('${ApiConstants.depots}/with-stocks');
    return (response as List).map((e) => Depot.fromJson(e)).toList();
  }

  Future<Depot> getById(int id) async {
    final response = await _api.get('${ApiConstants.depots}/$id');
    return Depot.fromJson(response);
  }

  Future<List<Depot>> getByMagasinId(int magasinId) async {
    final response = await _api.get('${ApiConstants.depots}/magasin/$magasinId');
    return (response as List).map((e) => Depot.fromJson(e)).toList();
  }

  Future<Depot> create(Depot depot) async {
    final response = await _api.post(ApiConstants.depots, depot.toJson());
    return Depot.fromJson(response);
  }

  Future<Depot> update(int id, Depot depot) async {
    final response = await _api.put('${ApiConstants.depots}/$id', depot.toJson());
    return Depot.fromJson(response);
  }

  Future<void> delete(int id) async {
    await _api.delete('${ApiConstants.depots}/$id');
  }
}
