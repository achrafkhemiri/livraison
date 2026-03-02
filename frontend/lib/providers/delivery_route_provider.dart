import 'dart:async';
import 'dart:convert';
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

/// Represents a collection stop at a depot (merged across orders)
class CollectionStop {
  final int id; // depotId
  final int depotId;
  final String depotName;
  final LatLng position;
  final List<CollectionItem> items; // items across ALL orders for this depot
  final List<int> orderIds; // orders served at this depot
  final List<Order> orders; // order objects
  bool isCollected;
  
  CollectionStop({
    required this.id,
    required this.depotId,
    required this.depotName,
    required this.position,
    required this.items,
    required this.orderIds,
    required this.orders,
    this.isCollected = false,
  });
}

/// Represents an item to collect at a depot
class CollectionItem {
  final String name;
  final int quantity;
  final int orderId; // which order this item belongs to
  
  CollectionItem({required this.name, required this.quantity, required this.orderId});
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
  Set<int> _lastComputedOrderIds = {}; // OrderIds used in the last plan computation
  List<Order> _allAvailableOrders = []; // All uncollected orders available for selection
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
  
  // ====== Live Tracking State ======
  bool _isLiveTracking = false;
  bool _isRecalculating = false;
  bool _followDriver = true;
  LatLng? _driverPosition;
  double _remainingDistance = 0; // meters
  double _remainingDuration = 0; // seconds
  double _nextStopDistance = 0;  // meters to next stop
  double _nextStopDuration = 0;  // seconds to next stop
  int _nextStopIndex = -1;       // Index of next undelivered stop
  DateTime? _lastRecalculation;
  Timer? _recalcDebounce;
  DateTime? _lastOsrmDistanceUpdate; // Cooldown for lightweight OSRM distance calls
  double _lastRouteSpeedKmh = 30.0;  // Average speed from last OSRM calc (km/h)
  int _driverPolylineIndex = 0;      // Last known index on polyline (for snap search optimization)
  static const double _arrivalThreshold = 80.0;  // meters to auto-detect arrival
  static const double _deviationThreshold = 150.0; // meters off-route to trigger recalc
  static const int _recalcCooldownSeconds = 25;    // min seconds between recalcs
  static const int _osrmDistanceCooldownSeconds = 15; // min seconds between OSRM distance updates
  
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
  List<CollectionStop> get selectedCollectionStops => _collectionStops.where((s) => s.orderIds.any((oid) => _selectedCollectionIds.contains(oid))).toList();
  List<LatLng> get collectionRoutePoints => _collectionRoutePoints;
  List<Order> get allAvailableOrders => _allAvailableOrders;
  /// True when the user changed their order selection since the last plan computation
  bool get needsRecomputation {
    if (_allAvailableOrders.isEmpty) return false;
    if (_selectedCollectionIds.length != _lastComputedOrderIds.length) return true;
    return !_selectedCollectionIds.containsAll(_lastComputedOrderIds);
  }
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
  
  // ====== Live Tracking Getters ======
  bool get isLiveTracking => _isLiveTracking;
  bool get isRecalculating => _isRecalculating;
  bool get followDriver => _followDriver;
  LatLng? get driverPosition => _driverPosition;
  double get remainingDistance => _remainingDistance;
  double get remainingDuration => _remainingDuration;
  double get nextStopDistance => _nextStopDistance;
  double get nextStopDuration => _nextStopDuration;
  int get nextStopIndex => _nextStopIndex;
  
  /// Formatted remaining distance
  String get formattedRemainingDistance {
    if (_remainingDistance >= 1000) {
      return '${(_remainingDistance / 1000).toStringAsFixed(1)} km';
    }
    return '${_remainingDistance.toStringAsFixed(0)} m';
  }
  
  /// Formatted remaining duration  
  String get formattedRemainingDuration {
    final hours = (_remainingDuration / 3600).floor();
    final minutes = ((_remainingDuration % 3600) / 60).floor();
    if (hours > 0) return '${hours}h ${minutes}min';
    return '${minutes} min';
  }
  
  /// Formatted next stop distance
  String get formattedNextStopDistance {
    if (_nextStopDistance >= 1000) {
      return '${(_nextStopDistance / 1000).toStringAsFixed(1)} km';
    }
    return '${_nextStopDistance.toStringAsFixed(0)} m';
  }
  
  /// Formatted next stop ETA
  String get formattedNextStopEta {
    final minutes = (_nextStopDuration / 60).ceil();
    if (minutes >= 60) {
      return '${(minutes / 60).floor()}h ${minutes % 60}min';
    }
    return '$minutes min';
  }
  
  /// Get the next undelivered stop info
  DeliveryStop? get nextUndeliveredStop {
    final selected = selectedStops;
    for (int i = 0; i < selected.length; i++) {
      if (!selected[i].isDelivered) return selected[i];
    }
    return null;
  }
  
  /// Get the next uncollected collection stop
  CollectionStop? get nextUnCollectedStop {
    final selected = selectedCollectionStops;
    for (final stop in selected) {
      if (!stop.isCollected) return stop;
    }
    return null;
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
    _resetLiveTrackingState();
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
  
  // Initialize collection stops from orders — uses optimal merged collection plan
  // Respects existing manual collection plans set by admin.
  Future<void> initializeCollectionStops(List<Order> orders, OrderService orderService, {double? livreurLat, double? livreurLon}) async {
    _isLoading = true;
    _errorMessage = null;
    _collectionStops = [];
    notifyListeners();
    
    try {
      final validOrders = orders.where((o) => o.collected != true && o.id != null).toList();
      _allAvailableOrders = validOrders;
      
      if (validOrders.isEmpty) {
        _lastComputedOrderIds = {};
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Separate orders with existing manual plans vs those needing generation
      final ordersWithPlan = validOrders.where((o) => o.collectionPlan != null && o.collectionPlan!.isNotEmpty).toList();
      final ordersWithoutPlan = validOrders.where((o) => o.collectionPlan == null || o.collectionPlan!.isEmpty).toList();

      // 1) Parse existing manual plans
      for (final order in ordersWithPlan) {
        _parseExistingCollectionPlan(order, validOrders);
      }

      // 2) Generate optimal plan for orders without existing plans
      if (ordersWithoutPlan.isNotEmpty) {
        final autoOrderIds = ordersWithoutPlan.map((o) => o.id!).toList();
        final plan = await orderService.generateOptimalCollectionPlan(
          autoOrderIds, livreurLat: livreurLat, livreurLon: livreurLon,
        );
        _parseMergedSteps(plan, validOrders);
      }

      // 3) Merge stops from same depot (manual + auto might overlap)
      _mergeCollectionStopsByDepot();
      
      // Auto-select all orders & track what we computed for
      _selectedCollectionIds = _collectionStops.expand((s) => s.orderIds).toSet();
      _lastComputedOrderIds = Set.from(_selectedCollectionIds);
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error initializing collection stops: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Recompute the collection plan for the currently selected orders only.
  /// Call this when the user changes their order selection and clicks "Recalculer".
  /// Respects existing manual plans.
  Future<void> recomputeCollectionPlan(OrderService orderService, {double? livreurLat, double? livreurLon}) async {
    final selectedOrderIds = _selectedCollectionIds
        .where((oid) => _allAvailableOrders.any((o) => o.id == oid))
        .toList();
    
    if (selectedOrderIds.isEmpty) {
      _collectionStops = [];
      _lastComputedOrderIds = {};
      _collectionRoutePoints = [];
      _collectionDistance = 0;
      _collectionDuration = 0;
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _collectionStops = [];
      
      final selectedOrders = _allAvailableOrders.where((o) => selectedOrderIds.contains(o.id)).toList();
      final ordersWithPlan = selectedOrders.where((o) => o.collectionPlan != null && o.collectionPlan!.isNotEmpty).toList();
      final ordersWithoutPlan = selectedOrders.where((o) => o.collectionPlan == null || o.collectionPlan!.isEmpty).toList();

      // 1) Parse existing manual plans
      for (final order in ordersWithPlan) {
        _parseExistingCollectionPlan(order, _allAvailableOrders);
      }

      // 2) Generate optimal plan for orders needing auto generation
      if (ordersWithoutPlan.isNotEmpty) {
        final autoIds = ordersWithoutPlan.map((o) => o.id!).toList();
        final plan = await orderService.generateOptimalCollectionPlan(
          autoIds, livreurLat: livreurLat, livreurLon: livreurLon,
        );
        _parseMergedSteps(plan, _allAvailableOrders);
      }

      // 3) Merge stops from same depot
      _mergeCollectionStopsByDepot();
      _lastComputedOrderIds = Set.from(selectedOrderIds);
      
      // Clear route since depots changed
      _collectionRoutePoints = [];
      _collectionDistance = 0;
      _collectionDuration = 0;
      _usedOsrmGeometryCollection = false;
      
      debugPrint('Recomputed: ${_collectionStops.length} depots for ${selectedOrderIds.length} orders (${ordersWithPlan.length} manual, ${ordersWithoutPlan.length} auto)');
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error recomputing collection plan: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Parse mergedSteps from the backend response into CollectionStop objects
  void _parseMergedSteps(Map<String, dynamic> plan, List<Order> availableOrders) {
    final mergedSteps = plan['mergedSteps'] as List? ?? [];
    debugPrint('Optimal collection plan: ${mergedSteps.length} depots');

    for (final step in mergedSteps) {
      final lat = step['depotLatitude'];
      final lon = step['depotLongitude'];
      if (lat == null || lon == null) continue;

      final depotId = (step['depotId'] as num).toInt();
      final stepOrderIds = (step['orderIds'] as List? ?? [])
          .map((e) => (e as num).toInt()).toList();

      final items = (step['items'] as List? ?? []).map((item) => CollectionItem(
        name: item['produitNom'] ?? 'Produit',
        quantity: (item['quantite'] as num?)?.toInt() ?? 0,
        orderId: (item['orderId'] as num?)?.toInt() ?? 0,
      )).toList();

      // Resolve order objects for this depot
      final stepOrders = stepOrderIds
          .map((oid) => availableOrders.where((o) => o.id == oid).firstOrNull)
          .whereType<Order>()
          .toList();

      _collectionStops.add(CollectionStop(
        id: depotId,
        depotId: depotId,
        depotName: step['depotNom'] ?? 'Dépôt',
        position: LatLng(
          (lat as num).toDouble(),
          (lon as num).toDouble(),
        ),
        items: items,
        orderIds: stepOrderIds,
        orders: stepOrders,
      ));
    }
  }

  /// Parse an order's existing collectionPlan JSON into CollectionStop objects.
  /// Used for orders where the admin manually set the collection plan.
  void _parseExistingCollectionPlan(Order order, List<Order> availableOrders) {
    try {
      final List<dynamic> steps = jsonDecode(order.collectionPlan!);
      debugPrint('Parsing manual plan for order #${order.id}: ${steps.length} steps');

      for (final step in steps) {
        final lat = step['depotLatitude'];
        final lon = step['depotLongitude'];
        if (lat == null || lon == null) continue;

        final depotId = (step['depotId'] as num).toInt();

        final items = (step['items'] as List? ?? []).map((item) => CollectionItem(
          name: item['produitNom'] ?? 'Produit',
          quantity: (item['quantite'] as num?)?.toInt() ?? 0,
          orderId: order.id ?? 0,
        )).toList();

        _collectionStops.add(CollectionStop(
          id: depotId,
          depotId: depotId,
          depotName: step['depotNom'] ?? 'Dépôt',
          position: LatLng(
            (lat as num).toDouble(),
            (lon as num).toDouble(),
          ),
          items: items,
          orderIds: [order.id!],
          orders: [order],
        ));
      }
    } catch (e) {
      debugPrint('Error parsing manual collection plan for order #${order.id}: $e');
    }
  }

  /// Merge collection stops that target the same depot (e.g. manual + auto).
  void _mergeCollectionStopsByDepot() {
    if (_collectionStops.length <= 1) return;

    final Map<int, CollectionStop> merged = {};
    for (final stop in _collectionStops) {
      if (merged.containsKey(stop.depotId)) {
        final existing = merged[stop.depotId]!;
        // Combine items
        final combinedItems = [...existing.items, ...stop.items];
        // Combine order IDs (deduplicate)
        final combinedOrderIds = {...existing.orderIds, ...stop.orderIds}.toList();
        // Combine order objects (deduplicate by id)
        final seenIds = <int>{};
        final combinedOrders = <Order>[];
        for (final o in [...existing.orders, ...stop.orders]) {
          if (o.id != null && seenIds.add(o.id!)) combinedOrders.add(o);
        }
        merged[stop.depotId] = CollectionStop(
          id: existing.id,
          depotId: existing.depotId,
          depotName: existing.depotName,
          position: existing.position,
          items: combinedItems,
          orderIds: combinedOrderIds,
          orders: combinedOrders,
          isCollected: existing.isCollected,
        );
      } else {
        merged[stop.depotId] = stop;
      }
    }
    _collectionStops = merged.values.toList();
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
    _selectedCollectionIds = _collectionStops.expand((s) => s.orderIds).toSet();
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
  
  // Check if all depot stops containing an order are collected
  bool isOrderFullyCollected(int orderId) {
    final orderStops = _collectionStops.where((s) => s.orderIds.contains(orderId));
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

  // ====================================================================
  // ============= LIVE TRACKING & DYNAMIC ROUTE RECALCULATION ==========
  // ====================================================================

  /// Start live tracking mode
  void startLiveTracking() {
    _isLiveTracking = true;
    _followDriver = true;
    _updateNextStopIndex();
    notifyListeners();
    debugPrint('🔴 Live tracking STARTED');
  }

  /// Stop live tracking mode
  void stopLiveTracking() {
    _isLiveTracking = false;
    _isRecalculating = false;
    _followDriver = false;
    _recalcDebounce?.cancel();
    _recalcDebounce = null;
    notifyListeners();
    debugPrint('⏹️ Live tracking STOPPED');
  }

  /// Toggle follow driver mode (camera follows driver)
  void toggleFollowDriver() {
    _followDriver = !_followDriver;
    notifyListeners();
  }

  /// Main entry point: called when GPS position changes
  /// This method handles all live tracking logic:
  /// 1. Updates driver position
  /// 2. Checks proximity to next stop
  /// 3. Triggers route recalculation if needed
  Future<void> updateDriverPosition(LatLng position) async {
    _driverPosition = position;
    
    if (!_isLiveTracking) {
      notifyListeners();
      return;
    }

    // Update start position for route calculations
    _startPosition = position;

    final isCollectMode = _mapMode == MapMode.collect;

    // Check if driver is near next stop (auto-arrival detection)
    _checkProximityToNextStop(position, isCollectMode);

    // Update distances to next stop — OSRM when cooldown allows, haversine otherwise
    await _updateDistanceToNextStop(position, isCollectMode);

    // Check if we need to recalculate the route
    final shouldRecalc = _shouldRecalculateRoute(position);
    
    notifyListeners();

    if (shouldRecalc) {
      _recalcDebounce?.cancel();
      _recalcDebounce = Timer(const Duration(seconds: 2), () {
        _recalculateFromCurrentPosition(position, isCollectMode);
      });
    }
  }

  /// Check if driver is close enough to the next stop to mark arrival
  void _checkProximityToNextStop(LatLng driverPos, bool isCollectMode) {
    if (isCollectMode) {
      final nextStop = nextUnCollectedStop;
      if (nextStop == null) return;
      
      final distance = OsrmService.haversineDistance(
        driverPos.latitude, driverPos.longitude,
        nextStop.position.latitude, nextStop.position.longitude,
      ) * 1000; // km to m
      
      if (distance < _arrivalThreshold) {
        debugPrint('📍 Arrived at collection stop: ${nextStop.depotName} (${distance.toStringAsFixed(0)}m)');
        // Don't auto-mark as collected, just notify - the driver confirms manually
      }
    } else {
      final nextStop = nextUndeliveredStop;
      if (nextStop == null) return;
      
      final distance = OsrmService.haversineDistance(
        driverPos.latitude, driverPos.longitude,
        nextStop.position.latitude, nextStop.position.longitude,
      ) * 1000;
      
      if (distance < _arrivalThreshold) {
        debugPrint('📍 Arrived near delivery stop: ${nextStop.name} (${distance.toStringAsFixed(0)}m)');
      }
    }
  }

  /// Update real-time distance to the next stop using 3-layer precision:
  /// Layer 1: Snap-to-route polyline (instant, ~95-98% accurate, 0 network cost)
  /// Layer 2: OSRM getDistance (every 15s, ~99% accurate, 1 lightweight call)
  /// Layer 3: Haversine fallback (if no polyline available)
  Future<void> _updateDistanceToNextStop(LatLng driverPos, bool isCollectMode) async {
    // Determine next stop position
    LatLng? nextStopPos;
    if (isCollectMode) {
      final nextStop = nextUnCollectedStop;
      if (nextStop == null) {
        _nextStopDistance = 0;
        _nextStopDuration = 0;
        _updateNextStopIndex();
        return;
      }
      nextStopPos = nextStop.position;
    } else {
      final nextStop = nextUndeliveredStop;
      if (nextStop == null) {
        _nextStopDistance = 0;
        _nextStopDuration = 0;
        _updateNextStopIndex();
        return;
      }
      nextStopPos = nextStop.position;
    }

    // ── Layer 1: Snap-to-route polyline distance (primary) ──
    final routePoints = isCollectMode ? _collectionRoutePoints : _routePoints;
    final polylineDist = _distanceAlongPolyline(driverPos, nextStopPos, routePoints);

    if (polylineDist != null) {
      _nextStopDistance = polylineDist;
      // ETA from average route speed (calibrated by last OSRM calc)
      _nextStopDuration = (polylineDist / 1000) / _lastRouteSpeedKmh * 3600;
    } else {
      // ── Layer 3: Haversine fallback (no polyline available) ──
      final haversineDist = OsrmService.haversineDistance(
        driverPos.latitude, driverPos.longitude,
        nextStopPos.latitude, nextStopPos.longitude,
      ) * 1000;
      _nextStopDistance = haversineDist;
      _nextStopDuration = (haversineDist / 1000) / _lastRouteSpeedKmh * 3600;
    }

    // ── Layer 2: OSRM precision calibration (rate-limited) ──
    final canCallOsrm = _isOsrmAvailable && (
      _lastOsrmDistanceUpdate == null ||
      DateTime.now().difference(_lastOsrmDistanceUpdate!).inSeconds >= _osrmDistanceCooldownSeconds
    );

    if (canCallOsrm) {
      try {
        final result = await OsrmService.getDistance(
          driverPos.latitude, driverPos.longitude,
          nextStopPos.latitude, nextStopPos.longitude,
        );
        if (result != null) {
          final osrmDist = result['distance']! * 1000;  // km → m
          final osrmDur = result['duration']! * 60;     // min → s
          _nextStopDistance = osrmDist;
          _nextStopDuration = osrmDur;
          _lastOsrmDistanceUpdate = DateTime.now();
          // Calibrate speed for polyline ETA calculations
          if (osrmDist > 100) {
            _lastRouteSpeedKmh = (osrmDist / 1000) / (osrmDur / 3600);
            _lastRouteSpeedKmh = _lastRouteSpeedKmh.clamp(5.0, 120.0);
          }
          debugPrint('📏 OSRM calibration: ${(osrmDist/1000).toStringAsFixed(2)}km, ETA: ${(osrmDur/60).toStringAsFixed(0)}min, speed: ${_lastRouteSpeedKmh.toStringAsFixed(0)}km/h');
        }
      } catch (e) {
        debugPrint('⚠️ OSRM distance call failed, using polyline/haversine: $e');
      }
    }

    // Also update remaining total distance along polyline
    _updateRemainingDistanceFromPolyline(driverPos, isCollectMode);

    _updateNextStopIndex();
  }

  /// Calculate distance from driver to a target along the route polyline.
  /// Snaps the driver to the nearest polyline segment, then sums segment
  /// distances from the snap point to the polyline point nearest the target.
  /// Returns null if polyline is empty or too short.
  double? _distanceAlongPolyline(LatLng driver, LatLng target, List<LatLng> polyline) {
    if (polyline.length < 2) return null;

    // 1. Find nearest segment to driver (search around last known index for speed)
    final snapResult = _snapToPolyline(driver, polyline);
    if (snapResult == null) return null;
    final driverSegIdx = snapResult.segmentIndex;
    final driverSnapPoint = snapResult.snappedPoint;

    // 2. Find nearest segment to target (search from driver forward)
    final targetSnap = _snapToPolyline(target, polyline, searchFrom: driverSegIdx);
    if (targetSnap == null) return null;
    final targetSegIdx = targetSnap.segmentIndex;
    final targetSnapPoint = targetSnap.snappedPoint;

    // 3. Sum distances along polyline from driver snap → target snap
    double totalDist = 0;

    if (driverSegIdx == targetSegIdx) {
      // Same segment: just distance between the two snap points
      totalDist = _haversineM(driverSnapPoint, targetSnapPoint);
    } else {
      // Distance from driver snap to end of its segment
      totalDist += _haversineM(driverSnapPoint, polyline[driverSegIdx + 1]);
      // Sum complete segments in between
      for (int i = driverSegIdx + 1; i < targetSegIdx; i++) {
        totalDist += _haversineM(polyline[i], polyline[i + 1]);
      }
      // Distance from start of target segment to target snap
      totalDist += _haversineM(polyline[targetSegIdx], targetSnapPoint);
    }

    // Cache driver's polyline index for next search optimization
    _driverPolylineIndex = driverSegIdx;

    return totalDist;
  }

  /// Snap a point to the nearest segment on the polyline.
  /// Returns the segment index and the projected (snapped) point.
  /// Optionally searches from [searchFrom] index for performance.
  _SnapResult? _snapToPolyline(LatLng point, List<LatLng> polyline, {int searchFrom = 0}) {
    if (polyline.length < 2) return null;

    double bestDist = double.infinity;
    int bestIdx = 0;
    LatLng bestPoint = polyline[0];

    // Search window: from searchFrom, check up to 80 segments forward,
    // and a small backward window for edge cases
    final start = (searchFrom - 5).clamp(0, polyline.length - 2);
    final end = (searchFrom + 80).clamp(0, polyline.length - 1);

    for (int i = start; i < end; i++) {
      final projected = _projectOntoSegment(point, polyline[i], polyline[i + 1]);
      final dist = _haversineM(point, projected);
      if (dist < bestDist) {
        bestDist = dist;
        bestIdx = i;
        bestPoint = projected;
      }
    }

    // If best distance is too far (>500m), the point is likely off-route
    if (bestDist > 500) return null;

    return _SnapResult(segmentIndex: bestIdx, snappedPoint: bestPoint, distance: bestDist);
  }

  /// Project a point onto a line segment, returning the closest point on the segment.
  LatLng _projectOntoSegment(LatLng point, LatLng segA, LatLng segB) {
    // Use flat-earth approximation (accurate enough for short segments <1km)
    final dx = segB.longitude - segA.longitude;
    final dy = segB.latitude - segA.latitude;
    final lenSq = dx * dx + dy * dy;

    if (lenSq < 1e-12) return segA; // Degenerate segment

    // t = projection parameter [0,1]
    final t = ((point.longitude - segA.longitude) * dx +
               (point.latitude - segA.latitude) * dy) / lenSq;
    final clamped = t.clamp(0.0, 1.0);

    return LatLng(
      segA.latitude + clamped * dy,
      segA.longitude + clamped * dx,
    );
  }

  /// Haversine distance in meters between two LatLng points
  double _haversineM(LatLng a, LatLng b) {
    return OsrmService.haversineDistance(
      a.latitude, a.longitude, b.latitude, b.longitude,
    ) * 1000;
  }

  /// Update _remainingDistance/_remainingDuration by summing polyline from driver to end
  void _updateRemainingDistanceFromPolyline(LatLng driverPos, bool isCollectMode) {
    final routePoints = isCollectMode ? _collectionRoutePoints : _routePoints;
    if (routePoints.length < 2) return;

    final snap = _snapToPolyline(driverPos, routePoints, searchFrom: _driverPolylineIndex);
    if (snap == null) return;

    double dist = 0;
    // Distance from snap point to end of its segment
    dist += _haversineM(snap.snappedPoint, routePoints[snap.segmentIndex + 1]);
    // Sum all remaining segments
    for (int i = snap.segmentIndex + 1; i < routePoints.length - 1; i++) {
      dist += _haversineM(routePoints[i], routePoints[i + 1]);
    }

    _remainingDistance = dist;
    _remainingDuration = (dist / 1000) / _lastRouteSpeedKmh * 3600;
  }

  /// Find the index of the next undelivered/uncollected stop
  void _updateNextStopIndex() {
    if (_mapMode == MapMode.collect) {
      final selected = selectedCollectionStops;
      for (int i = 0; i < selected.length; i++) {
        if (!selected[i].isCollected) {
          _nextStopIndex = i;
          return;
        }
      }
    } else {
      final selected = selectedStops;
      for (int i = 0; i < selected.length; i++) {
        if (!selected[i].isDelivered) {
          _nextStopIndex = i;
          return;
        }
      }
    }
    _nextStopIndex = -1;
  }

  /// Determine if route recalculation is needed
  bool _shouldRecalculateRoute(LatLng driverPos) {
    // Don't recalculate if no route exists
    final hasRoute = _mapMode == MapMode.collect 
        ? _collectionRoutePoints.isNotEmpty 
        : _routePoints.isNotEmpty;
    if (!hasRoute) return false;

    // Already recalculating
    if (_isRecalculating) return false;

    // Respect cooldown
    if (_lastRecalculation != null) {
      final elapsed = DateTime.now().difference(_lastRecalculation!).inSeconds;
      if (elapsed < _recalcCooldownSeconds) return false;
    }

    // Check if driver deviated from planned route
    final routePoints = _mapMode == MapMode.collect 
        ? _collectionRoutePoints 
        : _routePoints;
    final deviation = _minDistanceToRoute(driverPos, routePoints);
    
    if (deviation > _deviationThreshold) {
      debugPrint('🔄 Route deviation detected: ${deviation.toStringAsFixed(0)}m (threshold: ${_deviationThreshold}m)');
      return true;
    }

    return false;
  }

  /// Calculate minimum distance from a point to the route polyline
  double _minDistanceToRoute(LatLng point, List<LatLng> route) {
    if (route.isEmpty) return double.infinity;
    
    double minDist = double.infinity;
    // Only check nearby segments for performance (within first 50 segments)
    final checkLimit = route.length < 50 ? route.length - 1 : 50;
    
    for (int i = 0; i < checkLimit; i++) {
      final dist = _pointToSegmentDistance(
        point, route[i], route[i + 1],
      );
      if (dist < minDist) minDist = dist;
    }
    return minDist;
  }

  /// Distance from a point to a line segment (in meters)
  double _pointToSegmentDistance(LatLng point, LatLng segA, LatLng segB) {
    // Project point onto segment using haversine approximation
    final dAP = OsrmService.haversineDistance(
      segA.latitude, segA.longitude, point.latitude, point.longitude,
    ) * 1000;
    final dBP = OsrmService.haversineDistance(
      segB.latitude, segB.longitude, point.latitude, point.longitude,
    ) * 1000;
    final dAB = OsrmService.haversineDistance(
      segA.latitude, segA.longitude, segB.latitude, segB.longitude,
    ) * 1000;
    
    if (dAB < 1) return dAP; // Degenerate segment
    
    // Use cosine rule to find perpendicular distance
    final cosAngle = (dAP * dAP + dAB * dAB - dBP * dBP) / (2 * dAP * dAB);
    
    if (cosAngle < 0) return dAP; // Point is before segment start
    if (cosAngle > 1) return dBP; // Point is after segment end
    
    // Check if projection falls within segment
    final projDist = dAP * cosAngle;
    if (projDist > dAB) return dBP;
    
    // Perpendicular distance
    final perpDist = dAP * (1 - cosAngle * cosAngle).abs().clamp(0.0, 1.0);
    // Use sqrt for actual distance
    return dAP * (1 - cosAngle * cosAngle).abs().clamp(0.0, double.infinity);
  }

  /// Recalculate route from current driver position through remaining stops
  /// This is a lightweight recalculation - just gets new OSRM route geometry
  /// without re-running the full TSP optimization
  Future<void> _recalculateFromCurrentPosition(LatLng currentPos, bool isCollectMode) async {
    if (_isRecalculating) return;
    
    _isRecalculating = true;
    notifyListeners();
    
    try {
      debugPrint('🔄 Recalculating route from current position...');
      
      if (isCollectMode) {
        await _recalculateCollectionRoute(currentPos);
      } else {
        await _recalculateDeliveryRoute(currentPos);
      }
      
      _lastRecalculation = DateTime.now();
      debugPrint('✅ Route recalculation complete');
    } catch (e) {
      debugPrint('❌ Route recalculation failed: $e');
    } finally {
      _isRecalculating = false;
      notifyListeners();
    }
  }

  /// Recalculate delivery route from current position through remaining stops
  Future<void> _recalculateDeliveryRoute(LatLng currentPos) async {
    final remainingStops = selectedStops.where((s) => !s.isDelivered).toList();
    if (remainingStops.isEmpty) {
      _routePoints = [];
      _remainingDistance = 0;
      _remainingDuration = 0;
      return;
    }

    final waypoints = [currentPos, ...remainingStops.map((s) => s.position)];
    
    if (_isOsrmAvailable) {
      final route = await OsrmService.getRoute(waypoints);
      if (route != null && route.geometry.length > 2) {
        _routePoints = route.geometry;
        _remainingDistance = route.distance * 1000;
        _remainingDuration = route.duration * 60;
        _totalDistance = _remainingDistance;
        _totalDuration = _remainingDuration;
        _usedOsrmGeometry = true;
        _driverPolylineIndex = 0; // Reset snap index after new polyline
        
        // Calibrate speed from OSRM route data
        if (route.distance > 0.1 && route.duration > 0.1) {
          _lastRouteSpeedKmh = (route.distance / (route.duration / 60)).clamp(5.0, 120.0);
        }
        
        // Update next stop metrics from OSRM if available
        if (remainingStops.isNotEmpty) {
          final nextWaypoints = [currentPos, remainingStops.first.position];
          final nextRoute = await OsrmService.getRoute(nextWaypoints);
          if (nextRoute != null) {
            _nextStopDistance = nextRoute.distance * 1000;
            _nextStopDuration = nextRoute.duration * 60;
          }
        }
        
        debugPrint('📍 Recalculated: ${_routePoints.length} points, ${(_remainingDistance/1000).toStringAsFixed(1)}km, ${(_remainingDuration/60).toStringAsFixed(0)}min');
      } else {
        // OSRM failed, use interpolation
        _routePoints = _interpolateRoute(waypoints);
        _calculateFallbackMetrics(waypoints);
        _remainingDistance = _totalDistance;
        _remainingDuration = _totalDuration;
      }
    } else {
      _routePoints = _interpolateRoute(waypoints);
      _calculateFallbackMetrics(waypoints);
      _remainingDistance = _totalDistance;
      _remainingDuration = _totalDuration;
    }
  }

  /// Recalculate collection route from current position through remaining stops
  Future<void> _recalculateCollectionRoute(LatLng currentPos) async {
    final remainingStops = selectedCollectionStops.where((s) => !s.isCollected).toList();
    if (remainingStops.isEmpty) {
      _collectionRoutePoints = [];
      _remainingDistance = 0;
      _remainingDuration = 0;
      return;
    }

    final waypoints = [currentPos, ...remainingStops.map((s) => s.position)];
    
    if (_isOsrmAvailable) {
      final route = await OsrmService.getRoute(waypoints);
      if (route != null && route.geometry.length > 2) {
        _collectionRoutePoints = route.geometry;
        _remainingDistance = route.distance * 1000;
        _remainingDuration = route.duration * 60;
        _collectionDistance = _remainingDistance;
        _collectionDuration = _remainingDuration;
        _usedOsrmGeometryCollection = true;
        _driverPolylineIndex = 0; // Reset snap index after new polyline
        
        // Calibrate speed from OSRM route data
        if (route.distance > 0.1 && route.duration > 0.1) {
          _lastRouteSpeedKmh = (route.distance / (route.duration / 60)).clamp(5.0, 120.0);
        }
        
        if (remainingStops.isNotEmpty) {
          final nextWaypoints = [currentPos, remainingStops.first.position];
          final nextRoute = await OsrmService.getRoute(nextWaypoints);
          if (nextRoute != null) {
            _nextStopDistance = nextRoute.distance * 1000;
            _nextStopDuration = nextRoute.duration * 60;
          }
        }
        
        debugPrint('📍 Collection recalculated: ${_collectionRoutePoints.length} points, ${(_remainingDistance/1000).toStringAsFixed(1)}km');
      } else {
        _collectionRoutePoints = _interpolateRoute(waypoints);
        _calculateFallbackCollectionMetrics(waypoints);
        _remainingDistance = _collectionDistance;
        _remainingDuration = _collectionDuration;
      }
    } else {
      _collectionRoutePoints = _interpolateRoute(waypoints);
      _calculateFallbackCollectionMetrics(waypoints);
      _remainingDistance = _collectionDistance;
      _remainingDuration = _collectionDuration;
    }
  }

  /// Force recalculation now (user-triggered refresh)
  Future<void> forceRecalculate() async {
    if (_driverPosition == null || !_isLiveTracking) return;
    _lastRecalculation = null; // Reset cooldown
    final isCollectMode = _mapMode == MapMode.collect;
    await _recalculateFromCurrentPosition(_driverPosition!, isCollectMode);
  }

  /// Reset live tracking state
  void _resetLiveTrackingState() {
    _isLiveTracking = false;
    _isRecalculating = false;
    _followDriver = false;
    _driverPosition = null;
    _remainingDistance = 0;
    _remainingDuration = 0;
    _nextStopDistance = 0;
    _nextStopDuration = 0;
    _nextStopIndex = -1;
    _lastRecalculation = null;
    _lastOsrmDistanceUpdate = null;
    _lastRouteSpeedKmh = 30.0;
    _driverPolylineIndex = 0;
    _recalcDebounce?.cancel();
    _recalcDebounce = null;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _recalcDebounce?.cancel();
    super.dispose();
  }
}

/// Helper class for polyline snap results
class _SnapResult {
  final int segmentIndex;
  final LatLng snappedPoint;
  final double distance; // meters from original point to snapped point

  const _SnapResult({
    required this.segmentIndex,
    required this.snappedPoint,
    required this.distance,
  });
}
