import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../core/constants/api_constants.dart';

class OsrmService {
  static String get osrmUrl => ApiConstants.osrmUrl;
  
  /// Check OSRM connection using a test route (OSRM has no /health endpoint)
  static Future<bool> checkConnection() async {
    try {
      // OSRM doesn't have /health endpoint, use a simple route request instead
      final response = await http.get(
        Uri.parse('$osrmUrl/route/v1/driving/10.76,34.74;10.77,34.75?overview=false'),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      print('OSRM connection check failed: $e');
      return false;
    }
  }

  /// Get distance and duration between two points
  static Future<Map<String, double>?> getDistance(
    double lat1, double lon1,
    double lat2, double lon2,
  ) async {
    try {
      final url = '$osrmUrl/route/v1/driving/$lon1,$lat1;$lon2,$lat2?overview=false';
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 'Ok' && data['routes'] != null && data['routes'].isNotEmpty) {
          return {
            'distance': (data['routes'][0]['distance'] as num).toDouble() / 1000, // km
            'duration': (data['routes'][0]['duration'] as num).toDouble() / 60,   // minutes
          };
        }
      }
    } catch (e) {
      print('OSRM distance error: $e');
    }
    return null;
  }

  /// Get full route with geometry
  static Future<OsrmRoute?> getRoute(List<LatLng> points) async {
    if (points.length < 2) {
      print('OSRM getRoute: Not enough points (${points.length})');
      return null;
    }
    
    try {
      // OSRM expects coordinates in format: lon,lat;lon,lat;...
      final coordinates = points.map((p) => '${p.longitude},${p.latitude}').join(';');
      final url = '$osrmUrl/route/v1/driving/$coordinates?overview=full&geometries=polyline&steps=false';
      
      print('=== OSRM Route Request ===');
      print('OSRM URL: $osrmUrl');
      print('Points count: ${points.length}');
      print('Coordinates: $coordinates');
      print('Full URL: $url');
      
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 30));
      
      print('Response status: ${response.statusCode}');
      print('Response length: ${response.body.length} chars');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Response code: ${data['code']}');
        
        if (data['code'] == 'Ok' && data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry'] as String?;
          final distance = (route['distance'] as num).toDouble();
          final duration = (route['duration'] as num).toDouble();
          
          print('Route distance: ${distance}m, duration: ${duration}s');
          print('Geometry present: ${geometry != null}, length: ${geometry?.length ?? 0}');
          
          if (geometry != null && geometry.isNotEmpty) {
            final decodedPoints = _decodePolyline(geometry);
            print('Decoded ${decodedPoints.length} points from geometry');
            
            if (decodedPoints.length > 2) {
              print('First point: ${decodedPoints.first.latitude}, ${decodedPoints.first.longitude}');
              print('Last point: ${decodedPoints.last.latitude}, ${decodedPoints.last.longitude}');
            }
            
            if (decodedPoints.isNotEmpty) {
              return OsrmRoute(
                distance: distance / 1000,
                duration: duration / 60,
                geometry: decodedPoints,
              );
            } else {
              print('ERROR: Decoded 0 points from geometry!');
            }
          } else {
            print('ERROR: OSRM returned empty geometry string');
          }
        } else {
          print('ERROR: OSRM response code: ${data['code']}');
        }
      } else {
        print('ERROR: HTTP status ${response.statusCode}');
      }
    } catch (e, stack) {
      print('OSRM route error: $e');
      print('Stack: $stack');
    }
    return null;
  }

  /// Calculate distance matrix between all points
  static Future<List<List<double>>?> getDistanceMatrix(List<LatLng> points) async {
    if (points.length < 2) return null;
    
    try {
      final coordinates = points.map((p) => '${p.longitude},${p.latitude}').join(';');
      final url = '$osrmUrl/table/v1/driving/$coordinates?annotations=distance,duration';
      
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 60));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 'Ok') {
          final distances = data['distances'] as List;
          return distances.map<List<double>>((row) {
            return (row as List).map<double>((val) => (val as num).toDouble() / 1000).toList();
          }).toList();
        }
      }
    } catch (e) {
      print('OSRM matrix error: $e');
    }
    return null;
  }

  /// Decode polyline geometry (Google Polyline Algorithm)
  /// Uses proper zigzag decoding for Dart (64-bit integers)
  static List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int lat = 0;
    int lng = 0;
    int pointCount = 0;
    int invalidCount = 0;

    while (index < encoded.length) {
      // Decode latitude delta
      int shift = 0;
      int result = 0;
      int b;
      
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20 && index < encoded.length);
      
      // Zigzag decode - mask to 32-bit for JavaScript compatibility
      int dlat;
      if ((result & 1) != 0) {
        dlat = ~(result >> 1);
        // Mask to 32-bit to match JavaScript behavior
        dlat = dlat.toSigned(32);
      } else {
        dlat = result >> 1;
      }
      lat += dlat;

      // Decode longitude delta
      shift = 0;
      result = 0;
      
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20 && index < encoded.length);
      
      // Zigzag decode - mask to 32-bit for JavaScript compatibility
      int dlng;
      if ((result & 1) != 0) {
        dlng = ~(result >> 1);
        dlng = dlng.toSigned(32);
      } else {
        dlng = result >> 1;
      }
      lng += dlng;

      // Convert from integer representation to decimal degrees
      double latitude = lat / 1e5;
      double longitude = lng / 1e5;
      
      pointCount++;
      
      // Debug first few points and any invalid ones
      if (pointCount <= 3) {
        print('Point $pointCount: dlat=$dlat, dlng=$dlng -> lat=$lat, lng=$lng -> $latitude, $longitude');
      }
      
      // Validate and add point
      if (latitude >= -90 && latitude <= 90 && 
          longitude >= -180 && longitude <= 180) {
        points.add(LatLng(latitude, longitude));
      } else {
        invalidCount++;
        if (invalidCount <= 3) {
          print('INVALID point $pointCount: lat=$latitude, lng=$longitude (raw: lat=$lat, lng=$lng)');
        }
      }
    }
    
    print('Polyline decoded: ${points.length} valid points');
    if (points.isNotEmpty) {
      print('  Start: ${points.first.latitude}, ${points.first.longitude}');
      print('  End: ${points.last.latitude}, ${points.last.longitude}');
    }

    return points;
  }

  /// Get optimized trip (TSP) using OSRM /trip endpoint
  /// Returns the optimized waypoint order, distance, duration, and geometry
  /// source=first means the trip starts from the first coordinate (driver position)
  /// roundtrip=false means the trip does NOT return to origin
  static Future<OsrmTripResult?> getTrip(List<LatLng> points) async {
    if (points.length < 3) {
      // Need at least origin + 2 stops for optimization to matter
      return null;
    }

    try {
      final coordinates = points.map((p) => '${p.longitude},${p.latitude}').join(';');
      final url =
          '$osrmUrl/trip/v1/driving/$coordinates?source=first&roundtrip=false&geometries=polyline&overview=full';

      print('=== OSRM Trip Request ===');
      print('Points count: ${points.length}');
      print('Full URL: $url');

      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 'Ok') {
          // Extract optimized waypoint order from response
          final waypoints = data['waypoints'] as List?;
          if (waypoints != null && waypoints.isNotEmpty) {
            final waypointIndices = waypoints
                .map<int>((wp) => (wp['waypoint_index'] as num).toInt())
                .toList();

            // Extract trip geometry and metrics
            final trips = data['trips'] as List?;
            double totalDistance = 0;
            double totalDuration = 0;
            List<LatLng> geometry = [];

            if (trips != null && trips.isNotEmpty) {
              final trip = trips[0];
              totalDistance = (trip['distance'] as num).toDouble() / 1000; // km
              totalDuration = (trip['duration'] as num).toDouble() / 60; // min
              final geomStr = trip['geometry'] as String?;
              if (geomStr != null && geomStr.isNotEmpty) {
                geometry = _decodePolyline(geomStr);
              }
            }

            print('Trip optimized order: $waypointIndices');
            print('Trip distance: ${totalDistance}km, duration: ${totalDuration}min');

            return OsrmTripResult(
              waypointOrder: waypointIndices,
              distance: totalDistance,
              duration: totalDuration,
              geometry: geometry,
            );
          }
        } else {
          print('OSRM trip error code: ${data['code']}');
        }
      } else {
        print('OSRM trip HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('OSRM trip error: $e');
    }
    return null;
  }

  /// Haversine distance fallback
  static double haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0; // Earth radius in km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  static double _toRadians(double degree) => degree * pi / 180;
}

class OsrmRoute {
  final double distance; // km
  final double duration; // minutes
  final List<LatLng> geometry;

  OsrmRoute({
    required this.distance,
    required this.duration,
    required this.geometry,
  });
}

/// Result from OSRM /trip endpoint (TSP-optimized order)
class OsrmTripResult {
  final List<int> waypointOrder; // optimized indices (0 = origin, 1..n = stops)
  final double distance; // km
  final double duration; // minutes
  final List<LatLng> geometry;

  OsrmTripResult({
    required this.waypointOrder,
    required this.distance,
    required this.duration,
    required this.geometry,
  });
}
