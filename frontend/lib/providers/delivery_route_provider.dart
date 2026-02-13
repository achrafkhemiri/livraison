import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../data/models/models.dart';
import '../data/services/services.dart';

/// Represents a delivery stop with client info and position
class DeliveryStop {
  final int id;
  final String name;
  final String address;
  final LatLng position;
  final Order order;
  bool isDelivered;
  
  DeliveryStop({
    required this.id,
    required this.name,
    required this.address,
    required this.position,
    required this.order,
    this.isDelivered = false,
  });
}

/// Represents a collection stop at a depot
class CollectionStop {
  final int id; // unique stop ID (orderId * 1000 + stepIndex)
  final int orderId;
  final int stepIndex;
  final String depotName;
  final LatLng position;
  final List<CollectionItem> items;
  final Order order;
  bool isCollected;
  
  CollectionStop({
    required this.id,
    required this.orderId,
    required this.stepIndex,
    required this.depotName,
    required this.position,
    required this.items,
    required this.order,
    this.isCollected = false,
  });
}

/// Represents an item to collect at a depot
class CollectionItem {
  final String name;
  final int quantity;
  
  CollectionItem({required this.name, required this.quantity});
}

/// The active mode in the map: collect from depots or deliver to clients
enum MapMode { collect, deliver }

/// Provider for managing delivery routes and optimization
class DeliveryRouteProvider extends ChangeNotifier {
  final ClientService _clientService = ClientService();
  
  // Current mode
  MapMode _mapMode = MapMode.collect;
  
  // Delivery stops (clients)
  List<DeliveryStop> _stops = [];
  Set<int> _selectedStopIds = {}; // Selected stops for delivery
  
  // Collection stops (depots)
  List<CollectionStop> _collectionStops = [];
  Set<int> _selectedCollectionIds = {}; // Selected collection stops (by orderId)
  List<LatLng> _collectionRoutePoints = [];
  double _collectionDistance = 0;
  double _collectionDuration = 0;
  bool _usedOsrmGeometryCollection = false;
  
  List<LatLng> _routePoints = [];
  LatLng? _startPosition;
  double _totalDistance = 0;
  double _totalDuration = 0;
  bool _isLoading = false;
  bool _isOsrmAvailable = false;
  bool _usedOsrmGeometry = false; // Tracks if OSRM geometry was actually used
  String? _errorMessage;
  int _currentStopIndex = 0;
  
  // Mode
  MapMode get mapMode => _mapMode;
  
  // Delivery getters
  List<DeliveryStop> get stops => _stops;
  Set<int> get selectedStopIds => _selectedStopIds;
  List<DeliveryStop> get selectedStops => _stops.where((s) => _selectedStopIds.contains(s.id)).toList();
  List<LatLng> get routePoints => _routePoints;
  LatLng? get startPosition => _startPosition;
  double get totalDistance => _totalDistance;
  double get totalDuration => _totalDuration;
  bool get isLoading => _isLoading;
  bool get isOsrmAvailable => _isOsrmAvailable;
  bool get usedOsrmGeometry => _usedOsrmGeometry; // Expose the flag
  String? get errorMessage => _errorMessage;
  int get currentStopIndex => _currentStopIndex;
  
  // Collection getters
  List<CollectionStop> get collectionStops => _collectionStops;
  Set<int> get selectedCollectionIds => _selectedCollectionIds;
  List<CollectionStop> get selectedCollectionStops => _collectionStops.where((s) => _selectedCollectionIds.contains(s.orderId)).toList();
  List<LatLng> get collectionRoutePoints => _collectionRoutePoints;
  double get collectionDistance => _collectionDistance;
  double get collectionDuration => _collectionDuration;
  bool get usedOsrmGeometryCollection => _usedOsrmGeometryCollection;
  
  // Formatted collection distance
  String get formattedCollectionDistance {
    if (_collectionDistance >= 1000) {
      return '${(_collectionDistance / 1000).toStringAsFixed(1)} km';
    }
    return '${_collectionDistance.toStringAsFixed(0)} m';
  }
  
  // Formatted collection duration
  String get formattedCollectionDuration {
    final hours = (_collectionDuration / 3600).floor();
    final minutes = ((_collectionDuration % 3600) / 60).floor();
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    }
    return '${minutes} min';
  }

  // Formatted distance
  String get formattedDistance {
    if (_totalDistance >= 1000) {
      return '${(_totalDistance / 1000).toStringAsFixed(1)} km';
    }
    return '${_totalDistance.toStringAsFixed(0)} m';
  }
  
  // Formatted duration
  String get formattedDuration {
    final hours = (_totalDuration / 3600).floor();
    final minutes = ((_totalDuration % 3600) / 60).floor();
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    }
    return '${minutes} min';
  }
  
  // Check OSRM availability
  Future<bool> checkOsrmConnection() async {
    _isOsrmAvailable = await OsrmService.checkConnection();
    notifyListeners();
    return _isOsrmAvailable;
  }
  
  // Set starting position (livreur's current position)
  void setStartPosition(LatLng position) {
    _startPosition = position;
    notifyListeners();
  }
  
  // Initialize stops from orders
  Future<void> initializeFromOrders(List<Order> orders) async {
    _isLoading = true;
    _errorMessage = null;
    _stops = [];
    notifyListeners();

    try {
      for (final order in orders) {
        // First check if order has delivery coordinates directly
        if (order.latitudeLivraison != null && order.longitudeLivraison != null) {
          _stops.add(DeliveryStop(
            id: order.id ?? 0,
            name: order.clientNom ?? 'Client ${order.clientId}',
            address: order.adresseLivraison ?? '',
            position: LatLng(order.latitudeLivraison!, order.longitudeLivraison!),
            order: order,
          ));
        } else if (order.clientId > 0) {
          // Try to fetch client details from API
          try {
            final client = await _clientService.getById(order.clientId);
            if (client.latitude != null && client.longitude != null) {
              _stops.add(DeliveryStop(
                id: order.id ?? 0,
                name: client.nom ?? 'Client ${order.clientId}',
                address: client.adresse ?? '',
                position: LatLng(client.latitude!, client.longitude!),
                order: order,
              ));
            }
          } catch (e) {
            // Client fetch failed, skip this order
            debugPrint('Failed to fetch client ${order.clientId}: $e');
          }
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Add a stop manually
  void addStop(DeliveryStop stop) {
    _stops.add(stop);
    notifyListeners();
  }
  
  // Remove a stop
  void removeStop(int orderId) {
    _stops.removeWhere((s) => s.id == orderId);
    notifyListeners();
  }
  
  // Reorder stops
  void reorderStops(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final stop = _stops.removeAt(oldIndex);
    _stops.insert(newIndex, stop);
    notifyListeners();
  }
  
  // Toggle stop selection
  void toggleStopSelection(int orderId) {
    if (_selectedStopIds.contains(orderId)) {
      _selectedStopIds.remove(orderId);
    } else {
      _selectedStopIds.add(orderId);
    }
    notifyListeners();
  }
  
  // Select all stops
  void selectAllStops() {
    _selectedStopIds = _stops.map((s) => s.id).toSet();
    notifyListeners();
  }
  
  // Deselect all stops
  void deselectAllStops() {
    _selectedStopIds.clear();
    _routePoints.clear();
    _totalDistance = 0;
    _totalDuration = 0;
    notifyListeners();
  }
  
  // Check if stop is selected
  bool isStopSelected(int orderId) => _selectedStopIds.contains(orderId);
  
  // Calculate optimized route using OSRM /trip + 2-opt + or-opt
  Future<void> calculateOptimizedRoute() async {
    // Use only selected stops for route calculation
    final stopsToRoute = selectedStops;
    
    if (_startPosition == null || stopsToRoute.isEmpty) {
      _errorMessage = 'Position de départ ou destinations manquantes (sélectionnez des clients)';
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      // Check OSRM availability
      await checkOsrmConnection();
      
      final allPositions = [_startPosition!, ...stopsToRoute.map((s) => s.position)];
      
      if (_isOsrmAvailable && stopsToRoute.length > 1) {
        // ── Step 1: Try OSRM /trip for initial TSP-optimized order ──
        final tripResult = await OsrmService.getTrip(allPositions);

        // ── Step 2: Get distance matrix for local search improvements ──
        final matrix = await OsrmService.getDistanceMatrix(allPositions);

        if (tripResult != null && matrix != null) {
          // Build initial tour from trip waypoint order
          List<int> tour = List<int>.from(tripResult.waypointOrder);
          // Ensure depot (0) is first
          if (tour.isNotEmpty && tour[0] != 0) {
            tour.remove(0);
            tour.insert(0, 0);
          }
          debugPrint('OSRM /trip initial tour: $tour');

          // ── Step 3: Apply 2-opt improvement ──
          tour = _improve2Opt(tour, matrix);

          // ── Step 4: Apply or-opt improvement ──
          tour = _improveOrOpt(tour, matrix);

          debugPrint('Final optimized tour: $tour');

          // Reorder stops based on final optimized tour
          final optimized = _applyTourOrder(stopsToRoute, tour);
          _reorderSelectedStops(optimized);
        } else if (matrix != null) {
          // /trip failed but we have the matrix: nearest neighbor + 2-opt + or-opt
          debugPrint('OSRM /trip unavailable, using matrix + local search');
          final nnOrder = _optimizeStopsWithMatrix(stopsToRoute, matrix);
          _reorderSelectedStops(nnOrder);

          // Build tour indices from nearest-neighbor order
          List<int> tour = [0, ...List.generate(nnOrder.length, (i) {
            final pos = stopsToRoute.indexOf(nnOrder[i]);
            return pos + 1; // +1 for depot offset
          })];
          tour = _improve2Opt(tour, matrix);
          tour = _improveOrOpt(tour, matrix);
          final optimized = _applyTourOrder(stopsToRoute, tour);
          _reorderSelectedStops(optimized);
        } else {
          // No OSRM matrix available: haversine nearest neighbor only
          final optimized = _optimizeStopsWithHaversine(stopsToRoute);
          _reorderSelectedStops(optimized);
        }
      } else if (stopsToRoute.length == 1) {
        // Only one stop, no optimization needed
      } else {
        // OSRM not available: haversine-based optimization
        final optimized = _optimizeStopsWithHaversine(stopsToRoute);
        _reorderSelectedStops(optimized);
      }
      
      // Calculate route geometry between all optimized points
      await _calculateRoute();
      
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Reorder stops based on optimized list
  void _reorderSelectedStops(List<DeliveryStop> optimized) {
    // Update order of selected stops in the main list
    final optimizedIds = optimized.map((s) => s.id).toList();
    final unselected = _stops.where((s) => !_selectedStopIds.contains(s.id)).toList();
    final reordered = optimized + unselected;
    _stops = reordered;
  }
  
  // Optimize with matrix (for selected stops)
  List<DeliveryStop> _optimizeStopsWithMatrix(List<DeliveryStop> stopsToOptimize, List<List<double>> matrix) {
    final n = stopsToOptimize.length;
    if (n <= 1) return stopsToOptimize;
    
    final visited = List.filled(n, false);
    final optimized = <DeliveryStop>[];
    
    int current = 0; // Start from depot (index 0 in matrix)
    
    for (int i = 0; i < n; i++) {
      double minDistance = double.infinity;
      int nearest = -1;
      
      for (int j = 0; j < n; j++) {
        if (!visited[j]) {
          final distance = matrix[current][j + 1]; // +1 because depot is at index 0
          if (distance < minDistance) {
            minDistance = distance;
            nearest = j;
          }
        }
      }
      
      if (nearest != -1) {
        visited[nearest] = true;
        optimized.add(stopsToOptimize[nearest]);
        current = nearest + 1;
      }
    }
    
    return optimized;
  }
  
  // Optimize with haversine (for selected stops)
  List<DeliveryStop> _optimizeStopsWithHaversine(List<DeliveryStop> stopsToOptimize) {
    final n = stopsToOptimize.length;
    if (n <= 1) return stopsToOptimize;
    
    final visited = List.filled(n, false);
    final optimized = <DeliveryStop>[];
    
    LatLng current = _startPosition!;
    
    for (int i = 0; i < n; i++) {
      double minDistance = double.infinity;
      int nearest = -1;
      
      for (int j = 0; j < n; j++) {
        if (!visited[j]) {
          final distance = OsrmService.haversineDistance(
            current.latitude, current.longitude,
            stopsToOptimize[j].position.latitude, stopsToOptimize[j].position.longitude,
          );
          if (distance < minDistance) {
            minDistance = distance;
            nearest = j;
          }
        }
      }
      
      if (nearest != -1) {
        visited[nearest] = true;
        optimized.add(stopsToOptimize[nearest]);
        current = stopsToOptimize[nearest].position;
      }
    }
    
    return optimized;
  }
  
  // Nearest neighbor algorithm with distance matrix (legacy - kept for reference)
  List<DeliveryStop> _optimizeWithNearestNeighbor(List<List<double>> matrix) {
    final n = _stops.length;
    final visited = List.filled(n, false);
    final optimized = <DeliveryStop>[];
    
    int current = 0; // Start from depot (index 0 in matrix)
    
    for (int i = 0; i < n; i++) {
      double minDistance = double.infinity;
      int nearest = -1;
      
      for (int j = 0; j < n; j++) {
        if (!visited[j]) {
          // Matrix index: current (0 for depot, j+1 for stops) to j+1
          final fromIdx = i == 0 ? 0 : optimized.last.id;
          final distance = matrix[current][j + 1];
          if (distance < minDistance) {
            minDistance = distance;
            nearest = j;
          }
        }
      }
      
      if (nearest != -1) {
        visited[nearest] = true;
        optimized.add(_stops[nearest]);
        current = nearest + 1; // +1 because depot is at index 0
      }
    }
    
    return optimized;
  }
  
  // Fallback optimization using haversine distance
  List<DeliveryStop> _optimizeWithHaversine() {
    final n = _stops.length;
    final visited = List.filled(n, false);
    final optimized = <DeliveryStop>[];
    
    LatLng current = _startPosition!;
    
    for (int i = 0; i < n; i++) {
      double minDistance = double.infinity;
      int nearest = -1;
      
      for (int j = 0; j < n; j++) {
        if (!visited[j]) {
          final distance = OsrmService.haversineDistance(
            current.latitude, current.longitude,
            _stops[j].position.latitude, _stops[j].position.longitude,
          );
          if (distance < minDistance) {
            minDistance = distance;
            nearest = j;
          }
        }
      }
      
      if (nearest != -1) {
        visited[nearest] = true;
        optimized.add(_stops[nearest]);
        current = _stops[nearest].position;
      }
    }
    
    return optimized;
  }
  
  // Calculate the actual route between selected points using OSRM
  Future<void> _calculateRoute() async {
    final stopsToRoute = selectedStops;
    debugPrint('=== Calculate Route ===');
    debugPrint('Start position: $_startPosition');
    debugPrint('Stops to route: ${stopsToRoute.length}');
    debugPrint('OSRM available: $_isOsrmAvailable');
    
    if (_startPosition == null || stopsToRoute.isEmpty) {
      debugPrint('Cannot calculate route: start=$_startPosition, stops=${stopsToRoute.length}');
      return;
    }
    
    _routePoints = [];
    _totalDistance = 0;
    _totalDuration = 0;
    _usedOsrmGeometry = false; // Reset the flag
    
    final waypoints = [_startPosition!, ...stopsToRoute.map((s) => s.position)];
    debugPrint('Waypoints count: ${waypoints.length}');
    for (int i = 0; i < waypoints.length; i++) {
      debugPrint('  Waypoint $i: ${waypoints[i].latitude}, ${waypoints[i].longitude}');
    }
    
    if (_isOsrmAvailable) {
      // Get route from OSRM - this returns the full road geometry
      debugPrint('Calling OSRM getRoute...');
      final route = await OsrmService.getRoute(waypoints);
      debugPrint('OSRM result: ${route != null ? "OK" : "NULL"}');
      
      if (route != null) {
        debugPrint('Route geometry points: ${route.geometry.length}');
        if (route.geometry.length > 2) {
          _routePoints = route.geometry;
          _totalDistance = route.distance * 1000; // km to m
          _totalDuration = route.duration * 60;   // min to sec
          _usedOsrmGeometry = true; // Mark that OSRM geometry is used
          debugPrint('OSRM geometry used: ${route.geometry.length} points, ${route.distance}km, ${route.duration}min');
        } else {
          debugPrint('OSRM returned too few points (${route.geometry.length}), using fallback');
          _routePoints = _interpolateRoute(waypoints);
          _totalDistance = route.distance * 1000; // Still use OSRM distance
          _totalDuration = route.duration * 60;
          debugPrint('Fallback route: ${_routePoints.length} points');
        }
      } else {
        // OSRM failed to return route, use interpolated fallback
        debugPrint('OSRM returned null, using interpolated fallback');
        _routePoints = _interpolateRoute(waypoints);
        _calculateFallbackMetrics(waypoints);
        debugPrint('Fallback route: ${_routePoints.length} points');
      }
    } else {
      // Use interpolated lines between points for smoother display
      debugPrint('OSRM not available, using interpolated fallback');
      _routePoints = _interpolateRoute(waypoints);
      _calculateFallbackMetrics(waypoints);
      debugPrint('Fallback route: ${_routePoints.length} points');
    }
    
    debugPrint('Final route points: ${_routePoints.length}, usedOsrmGeometry: $_usedOsrmGeometry');
    notifyListeners();
  }
  
  // Interpolate route for smoother line (when OSRM not available)
  List<LatLng> _interpolateRoute(List<LatLng> waypoints) {
    final interpolated = <LatLng>[];
    for (int i = 0; i < waypoints.length - 1; i++) {
      final from = waypoints[i];
      final to = waypoints[i + 1];
      // Add intermediate points for smoother curve
      interpolated.add(from);
      // Add some intermediate points
      for (int j = 1; j < 5; j++) {
        final t = j / 5.0;
        interpolated.add(LatLng(
          from.latitude + (to.latitude - from.latitude) * t,
          from.longitude + (to.longitude - from.longitude) * t,
        ));
      }
    }
    if (waypoints.isNotEmpty) {
      interpolated.add(waypoints.last);
    }
    return interpolated;
  }
  
  // Calculate fallback metrics when OSRM not available
  void _calculateFallbackMetrics(List<LatLng> waypoints) {
    _totalDistance = 0;
    for (int i = 0; i < waypoints.length - 1; i++) {
      _totalDistance += OsrmService.haversineDistance(
        waypoints[i].latitude, waypoints[i].longitude,
        waypoints[i + 1].latitude, waypoints[i + 1].longitude,
      ) * 1000; // km to m
    }
    // Estimate duration at 30 km/h average speed
    _totalDuration = (_totalDistance / 1000) / 30 * 3600;
  }
  
  // Mark a stop as delivered
  void markStopAsDelivered(int orderId) {
    final stopIndex = _stops.indexWhere((s) => s.id == orderId);
    if (stopIndex != -1) {
      _stops[stopIndex].isDelivered = true;
      if (_currentStopIndex < _stops.length - 1) {
        _currentStopIndex++;
      }
      notifyListeners();
    }
  }
  
  // Get next stop
  DeliveryStop? get nextStop {
    if (_currentStopIndex < _stops.length) {
      return _stops[_currentStopIndex];
    }
    return null;
  }
  
  // Check if all stops are delivered
  bool get allDelivered => _stops.every((s) => s.isDelivered);
  
  // Get remaining stops count
  int get remainingStopsCount => _stops.where((s) => !s.isDelivered).length;
  
  // Reset route (clears everything)
  void resetRoute() {
    _stops = [];
    _selectedStopIds.clear();
    _routePoints = [];
    _totalDistance = 0;
    _totalDuration = 0;
    _currentStopIndex = 0;
    _errorMessage = null;
    _usedOsrmGeometry = false;
    notifyListeners();
  }
  
  // Clear just the route path (keep stops and selection)
  void clearRoutePath() {
    _routePoints = [];
    _totalDistance = 0;
    _totalDuration = 0;
    _usedOsrmGeometry = false;
    notifyListeners();
  }

  // ====== TSP Local Search Improvements ======

  /// Compute total tour distance from a distance matrix.
  /// [tour] is the ordered list of matrix indices to visit.
  double _tourDistanceFromMatrix(List<int> tour, List<List<double>> matrix) {
    double total = 0;
    for (int i = 0; i < tour.length - 1; i++) {
      total += matrix[tour[i]][tour[i + 1]];
    }
    return total;
  }

  /// 2-opt improvement: iteratively reverse segments to shorten the tour.
  /// [tour] is a list of matrix indices (0 = depot, 1..n = stops).
  /// The first element (depot) is kept fixed.
  List<int> _improve2Opt(List<int> tour, List<List<double>> matrix) {
    if (tour.length < 4) return tour; // Need at least depot + 3 stops
    bool improved = true;
    List<int> best = List.from(tour);
    double bestDist = _tourDistanceFromMatrix(best, matrix);
    int maxIterations = 100; // prevent infinite loops

    while (improved && maxIterations-- > 0) {
      improved = false;
      // Start from 1 to keep depot fixed at position 0
      for (int i = 1; i < best.length - 2; i++) {
        for (int j = i + 1; j < best.length; j++) {
          // Reverse the segment between i and j
          final candidate = List<int>.from(best);
          final segment = candidate.sublist(i, j + 1).reversed.toList();
          candidate.replaceRange(i, j + 1, segment);

          final candidateDist = _tourDistanceFromMatrix(candidate, matrix);
          if (candidateDist < bestDist - 0.0001) {
            best = candidate;
            bestDist = candidateDist;
            improved = true;
          }
        }
      }
    }
    debugPrint('2-opt: distance ${_tourDistanceFromMatrix(tour, matrix).toStringAsFixed(2)} -> ${bestDist.toStringAsFixed(2)} km');
    return best;
  }

  /// Or-opt improvement: relocate a single node or a pair of consecutive nodes
  /// to a better position in the tour.
  /// The first element (depot) is kept fixed.
  List<int> _improveOrOpt(List<int> tour, List<List<double>> matrix) {
    if (tour.length < 4) return tour;
    bool improved = true;
    List<int> best = List.from(tour);
    double bestDist = _tourDistanceFromMatrix(best, matrix);
    int maxIterations = 100;

    while (improved && maxIterations-- > 0) {
      improved = false;
      // Try segment sizes 1 and 2
      for (int segLen = 1; segLen <= 2; segLen++) {
        // Start from 1 to keep depot fixed
        for (int i = 1; i <= best.length - segLen; i++) {
          // Extract the segment
          final segment = best.sublist(i, i + segLen);
          final remaining = [...best.sublist(0, i), ...best.sublist(i + segLen)];

          // Try inserting the segment at every other position (after depot)
          for (int j = 1; j < remaining.length; j++) {
            if (j == i) continue; // Same position
            final candidate = [
              ...remaining.sublist(0, j),
              ...segment,
              ...remaining.sublist(j),
            ];

            final candidateDist = _tourDistanceFromMatrix(candidate, matrix);
            if (candidateDist < bestDist - 0.0001) {
              best = candidate;
              bestDist = candidateDist;
              improved = true;
              break; // Restart outer loop with new best
            }
          }
          if (improved) break;
        }
        if (improved) break;
      }
    }
    debugPrint('Or-opt: distance -> ${bestDist.toStringAsFixed(2)} km');
    return best;
  }

  /// Reorder a list of DeliveryStops based on an optimized tour of matrix indices.
  /// [tour] contains matrix indices where 0 = depot, 1..n = stops[0..n-1].
  List<DeliveryStop> _applyTourOrder(List<DeliveryStop> stops, List<int> tour) {
    // tour[0] is the depot (skip it), tour[1..] are the stop indices (+1 offset)
    return tour.where((idx) => idx > 0).map((idx) => stops[idx - 1]).toList();
  }

  /// Reorder a list of CollectionStops based on an optimized tour of matrix indices.
  List<CollectionStop> _applyCollectionTourOrder(List<CollectionStop> stops, List<int> tour) {
    return tour.where((idx) => idx > 0).map((idx) => stops[idx - 1]).toList();
  }
  
  // Switch map mode
  void setMapMode(MapMode mode) {
    _mapMode = mode;
    notifyListeners();
  }
  
  // Initialize collection stops from orders (depot-based)
  Future<void> initializeCollectionStops(List<Order> orders, OrderService orderService) async {
    _isLoading = true;
    _errorMessage = null;
    _collectionStops = [];
    notifyListeners();
    
    try {
      // Load collection plans in parallel for speed
      final validOrders = orders.where((o) => o.collected != true && o.id != null).toList();
      
      final futures = validOrders.map((order) async {
        try {
          final plan = await orderService.generateCollectionPlan(order.id!);
          return MapEntry(order, plan);
        } catch (e) {
          debugPrint('Failed to generate collection plan for order ${order.id}: \$e');
          return MapEntry(order, null);
        }
      }).toList();
      
      final results = await Future.wait(futures);
      
      for (final entry in results) {
        final order = entry.key;
        final plan = entry.value;
        if (plan != null) {
          final steps = plan['collectionSteps'] as List? ?? [];
          // Create a SEPARATE stop for each depot step (don't merge)
          for (int stepIdx = 0; stepIdx < steps.length; stepIdx++) {
            final step = steps[stepIdx];
            final lat = step['depotLatitude'];
            final lon = step['depotLongitude'];
            if (lat != null && lon != null) {
              final items = (step['items'] as List? ?? []).map((item) => CollectionItem(
                name: item['produitNom'] ?? 'Produit',
                quantity: item['quantite'] ?? 0,
              )).toList();
              
              _collectionStops.add(CollectionStop(
                id: order.id! * 1000 + stepIdx,
                orderId: order.id!,
                stepIndex: stepIdx,
                depotName: step['depotNom'] ?? 'Dépôt ${stepIdx + 1}',
                position: LatLng(
                  (lat as num).toDouble(),
                  (lon as num).toDouble(),
                ),
                items: items,
                order: order,
              ));
            }
          }
        }
      }
      
      // Auto-select all orders
      _selectedCollectionIds = _collectionStops.map((s) => s.orderId).toSet();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Toggle collection stop selection
  void toggleCollectionSelection(int orderId) {
    if (_selectedCollectionIds.contains(orderId)) {
      _selectedCollectionIds.remove(orderId);
    } else {
      _selectedCollectionIds.add(orderId);
    }
    notifyListeners();
  }
  
  // Select all collection stops
  void selectAllCollectionStops() {
    _selectedCollectionIds = _collectionStops.map((s) => s.orderId).toSet();
    notifyListeners();
  }
  
  // Deselect all collection stops
  void deselectAllCollectionStops() {
    _selectedCollectionIds.clear();
    _collectionRoutePoints.clear();
    _collectionDistance = 0;
    _collectionDuration = 0;
    notifyListeners();
  }
  
  // Calculate optimized collection route using OSRM /trip + 2-opt + or-opt
  Future<void> calculateCollectionRoute() async {
    final stopsToRoute = selectedCollectionStops;
    
    if (_startPosition == null || stopsToRoute.isEmpty) {
      _errorMessage = 'Position de départ ou dépôts manquants';
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      await checkOsrmConnection();
      
      final positions = stopsToRoute.map((s) => s.position).toList();
      final allPositions = [_startPosition!, ...positions];
      
      if (_isOsrmAvailable && stopsToRoute.length > 1) {
        // ── Step 1: Try OSRM /trip for initial TSP order ──
        final tripResult = await OsrmService.getTrip(allPositions);

        // ── Step 2: Get distance matrix for 2-opt / or-opt ──
        final matrix = await OsrmService.getDistanceMatrix(allPositions);

        if (tripResult != null && matrix != null) {
          List<int> tour = List<int>.from(tripResult.waypointOrder);
          if (tour.isNotEmpty && tour[0] != 0) {
            tour.remove(0);
            tour.insert(0, 0);
          }
          debugPrint('Collection /trip initial tour: $tour');

          // ── Step 3: 2-opt ──
          tour = _improve2Opt(tour, matrix);
          // ── Step 4: or-opt ──
          tour = _improveOrOpt(tour, matrix);

          debugPrint('Collection final tour: $tour');
          final optimized = _applyCollectionTourOrder(stopsToRoute, tour);
          _reorderCollectionStops(optimized);
        } else if (matrix != null) {
          // /trip unavailable: nearest neighbor + 2-opt + or-opt
          debugPrint('Collection /trip unavailable, using matrix + local search');
          final nnOrder = _optimizeCollectionWithMatrix(stopsToRoute, matrix);

          List<int> tour = [0, ...List.generate(nnOrder.length, (i) {
            final pos = stopsToRoute.indexOf(nnOrder[i]);
            return pos + 1;
          })];
          tour = _improve2Opt(tour, matrix);
          tour = _improveOrOpt(tour, matrix);
          final optimized = _applyCollectionTourOrder(stopsToRoute, tour);
          _reorderCollectionStops(optimized);
        } else {
          final optimized = _optimizeCollectionWithHaversine(stopsToRoute);
          _reorderCollectionStops(optimized);
        }
      } else if (stopsToRoute.length > 1) {
        final optimized = _optimizeCollectionWithHaversine(stopsToRoute);
        _reorderCollectionStops(optimized);
      }
      
      // Calculate route geometry
      await _calculateCollectionRoute();
      
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  void _reorderCollectionStops(List<CollectionStop> optimized) {
    final optimizedIds = optimized.map((s) => s.id).toSet();
    final unselected = _collectionStops.where((s) => !optimizedIds.contains(s.id)).toList();
    _collectionStops = [...optimized, ...unselected];
  }
  
  List<CollectionStop> _optimizeCollectionWithMatrix(List<CollectionStop> stops, List<List<double>> matrix) {
    final n = stops.length;
    if (n <= 1) return stops;
    
    final visited = List.filled(n, false);
    final optimized = <CollectionStop>[];
    int current = 0;
    
    for (int i = 0; i < n; i++) {
      double minDist = double.infinity;
      int nearest = -1;
      
      for (int j = 0; j < n; j++) {
        if (!visited[j]) {
          final distance = matrix[current][j + 1];
          if (distance < minDist) {
            minDist = distance;
            nearest = j;
          }
        }
      }
      
      if (nearest != -1) {
        visited[nearest] = true;
        optimized.add(stops[nearest]);
        current = nearest + 1;
      }
    }
    
    return optimized;
  }
  
  List<CollectionStop> _optimizeCollectionWithHaversine(List<CollectionStop> stops) {
    final n = stops.length;
    if (n <= 1) return stops;
    
    final visited = List.filled(n, false);
    final optimized = <CollectionStop>[];
    LatLng current = _startPosition!;
    
    for (int i = 0; i < n; i++) {
      double minDist = double.infinity;
      int nearest = -1;
      
      for (int j = 0; j < n; j++) {
        if (!visited[j]) {
          final distance = OsrmService.haversineDistance(
            current.latitude, current.longitude,
            stops[j].position.latitude, stops[j].position.longitude,
          );
          if (distance < minDist) {
            minDist = distance;
            nearest = j;
          }
        }
      }
      
      if (nearest != -1) {
        visited[nearest] = true;
        optimized.add(stops[nearest]);
        current = stops[nearest].position;
      }
    }
    
    return optimized;
  }
  
  Future<void> _calculateCollectionRoute() async {
    final stopsToRoute = selectedCollectionStops;
    if (_startPosition == null || stopsToRoute.isEmpty) return;
    
    _collectionRoutePoints = [];
    _collectionDistance = 0;
    _collectionDuration = 0;
    _usedOsrmGeometryCollection = false;
    
    final waypoints = [_startPosition!, ...stopsToRoute.map((s) => s.position)];
    
    if (_isOsrmAvailable) {
      final route = await OsrmService.getRoute(waypoints);
      if (route != null && route.geometry.length > 2) {
        _collectionRoutePoints = route.geometry;
        _collectionDistance = route.distance * 1000;
        _collectionDuration = route.duration * 60;
        _usedOsrmGeometryCollection = true;
      } else {
        _collectionRoutePoints = _interpolateRoute(waypoints);
        if (route != null) {
          _collectionDistance = route.distance * 1000;
          _collectionDuration = route.duration * 60;
        } else {
          _calculateFallbackCollectionMetrics(waypoints);
        }
      }
    } else {
      _collectionRoutePoints = _interpolateRoute(waypoints);
      _calculateFallbackCollectionMetrics(waypoints);
    }
    
    notifyListeners();
  }
  
  void _calculateFallbackCollectionMetrics(List<LatLng> waypoints) {
    _collectionDistance = 0;
    for (int i = 0; i < waypoints.length - 1; i++) {
      _collectionDistance += OsrmService.haversineDistance(
        waypoints[i].latitude, waypoints[i].longitude,
        waypoints[i + 1].latitude, waypoints[i + 1].longitude,
      ) * 1000;
    }
    _collectionDuration = (_collectionDistance / 1000) / 30 * 3600;
  }
  
  // Mark a single collection depot stop as collected
  void markCollectionStopCollected(int stopId) {
    final idx = _collectionStops.indexWhere((s) => s.id == stopId);
    if (idx != -1) {
      _collectionStops[idx].isCollected = true;
      notifyListeners();
    }
  }
  
  // Check if all depot stops of an order are collected
  bool isOrderFullyCollected(int orderId) {
    final orderStops = _collectionStops.where((s) => s.orderId == orderId);
    return orderStops.isNotEmpty && orderStops.every((s) => s.isCollected);
  }
  
  // Clear collection route path
  void clearCollectionRoute() {
    _collectionRoutePoints = [];
    _collectionDistance = 0;
    _collectionDuration = 0;
    _usedOsrmGeometryCollection = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
