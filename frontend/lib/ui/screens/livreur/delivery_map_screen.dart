import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../data/models/models.dart';
import '../../../providers/providers.dart';

class DeliveryMapScreen extends StatefulWidget {
  final List<Order>? orders;
  final int? orderId;
  
  const DeliveryMapScreen({super.key, this.orders, this.orderId});

  @override
  State<DeliveryMapScreen> createState() => _DeliveryMapScreenState();
}

class _DeliveryMapScreenState extends State<DeliveryMapScreen> {
  final MapController _mapController = MapController();
  bool _isOptimizing = false;
  double _optimizationProgress = 0;
  String _optimizationStatus = '';
  bool _showSidebar = true;
  
  // Default center: Sfax, Tunisia (near OSRM data)
  static const LatLng _defaultCenter = LatLng(34.74, 10.76);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeMap();
      }
    });
  }

  Future<void> _initializeMap() async {
    if (!mounted) return;
    
    final routeProvider = context.read<DeliveryRouteProvider>();
    final livreurProvider = context.read<LivreurProvider>();
    final orderProvider = context.read<OrderProvider>();
    
    // Check OSRM connection
    await routeProvider.checkOsrmConnection();
    if (!mounted) return;
    
    // Start GPS tracking for real-time position updates
    await livreurProvider.startPositionTracking();
    if (!mounted) return;
    
    // Get current position
    final position = livreurProvider.currentPosition ?? await livreurProvider.getCurrentPosition();
    if (!mounted) return;
    
    if (position != null) {
      routeProvider.setStartPosition(position);
      _mapController.move(position, 13);
      debugPrint('GPS Position: ${position.latitude}, ${position.longitude}');
    } else {
      // Use default center if no position
      routeProvider.setStartPosition(_defaultCenter);
      _mapController.move(_defaultCenter, 12);
      debugPrint('Using default position - GPS not available');
    }
    
    // Get orders from arguments or use active orders
    final args = ModalRoute.of(context)?.settings.arguments;
    List<Order>? orders;
    
    if (args is Map) {
      orders = args['orders'] as List<Order>?;
      if (args['orderId'] != null) {
        final orderId = args['orderId'] as int;
        final order = orderProvider.myOrders.firstWhere(
          (o) => o.id == orderId,
          orElse: () => orderProvider.orders.firstWhere(
            (o) => o.id == orderId,
            orElse: () => Order(id: orderId, clientId: 0),
          ),
        );
        orders = [order];
      }
    }
    
    orders ??= widget.orders ?? orderProvider.activeOrders;
    
    if (orders.isNotEmpty && mounted) {
      await routeProvider.initializeFromOrders(orders);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar (collapsible)
          if (_showSidebar) _buildSidebar(),
          
          // Map area
          Expanded(
            child: Stack(
              children: [
                // Map
                _buildMap(),
                
                // Top controls
                _buildTopControls(),
                
                // Optimization loading overlay
                if (_isOptimizing) _buildOptimizationOverlay(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Consumer<DeliveryRouteProvider>(
      builder: (context, provider, _) {
        return Container(
          width: 320,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1a237e),
                Color(0xFF0d47a1),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(2, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              _buildSidebarHeader(provider),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      // Livreur position section
                      _buildLivreurSection(),
                      const SizedBox(height: 12),
                      
                      // Stops list section
                      _buildStopsSection(provider),
                      const SizedBox(height: 12),
                      
                      // Optimization section
                      _buildOptimizationSection(provider),
                      
                      // Results section
                      if (provider.routePoints.isNotEmpty)
                        _buildResultsSection(provider),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSidebarHeader(DeliveryRouteProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🚚', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text(
                'Smart Delivery',
                style: AppStyles.headingMedium.copyWith(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Plus Court Chemin - OSRM',
            style: AppStyles.bodySmall.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          
          // OSRM Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: provider.isOsrmAvailable 
                        ? const Color(0xFF00e676) 
                        : const Color(0xFFff5252),
                    boxShadow: [
                      BoxShadow(
                        color: (provider.isOsrmAvailable 
                            ? const Color(0xFF00e676) 
                            : const Color(0xFFff5252)).withOpacity(0.5),
                        blurRadius: 5,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  provider.isOsrmAvailable ? 'OSRM Connecté ✓' : 'Mode Hors-ligne',
                  style: AppStyles.caption.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLivreurSection() {
    return Consumer<LivreurProvider>(
      builder: (context, livreurProvider, _) {
        final pos = livreurProvider.currentPosition;
        return _buildSection(
          icon: Icons.local_shipping,
          title: 'Livreur (Départ)',
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildInfoField(
                      'Latitude',
                      pos?.latitude.toStringAsFixed(6) ?? '--',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoField(
                      'Longitude',
                      pos?.longitude.toStringAsFixed(6) ?? '--',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildButton(
                      icon: Icons.my_location,
                      label: 'Ma position',
                      onPressed: () async {
                        final provider = context.read<LivreurProvider>();
                        final position = await provider.getCurrentPosition();
                        if (position != null && mounted) {
                          context.read<DeliveryRouteProvider>().setStartPosition(position);
                          _mapController.move(position, 14);
                        }
                      },
                      isPrimary: false,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildButton(
                      icon: Icons.center_focus_strong,
                      label: 'Centrer',
                      onPressed: () {
                        if (pos != null) {
                          _mapController.move(pos, 14);
                        }
                      },
                      isPrimary: false,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStopsSection(DeliveryRouteProvider provider) {
    final selectedCount = provider.selectedStopIds.length;
    return _buildSection(
      icon: Icons.location_on,
      title: 'Clients (${provider.stops.length})',
      child: Column(
        children: [
          // Selection controls
          if (provider.stops.isNotEmpty) ...[
            Row(
              children: [
                Text(
                  'Sélectionnés: $selectedCount',
                  style: AppStyles.caption.copyWith(color: Colors.white70),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => provider.selectAllStops(),
                  icon: const Icon(Icons.check_box, color: Colors.white70, size: 16),
                  label: Text('Tout', style: AppStyles.caption.copyWith(color: Colors.white70)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => provider.deselectAllStops(),
                  icon: const Icon(Icons.check_box_outline_blank, color: Colors.white70, size: 16),
                  label: Text('Aucun', style: AppStyles.caption.copyWith(color: Colors.white70)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          if (provider.stops.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Aucune livraison à effectuer',
                style: AppStyles.bodySmall.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            )
          else
            ...provider.stops.asMap().entries.map((entry) {
              final index = entry.key;
              final stop = entry.value;
              return _buildStopItem(index, stop, provider);
            }),
        ],
      ),
    );
  }

  Widget _buildStopItem(int index, DeliveryStop stop, DeliveryRouteProvider provider) {
    final isCurrentStop = index == provider.currentStopIndex;
    final isDelivered = stop.isDelivered;
    final isSelected = provider.isStopSelected(stop.id);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDelivered 
            ? const Color(0xFF00c853).withOpacity(0.3)
            : isSelected
                ? const Color(0xFF1B998B).withOpacity(0.3)
                : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: isSelected && !isDelivered
            ? Border.all(color: const Color(0xFF1B998B), width: 2)
            : isCurrentStop && !isDelivered
            ? Border.all(color: Colors.orange, width: 2)
            : null,
      ),
      child: InkWell(
        onTap: () {
          // Toggle selection on tap
          provider.toggleStopSelection(stop.id);
        },
        onDoubleTap: () {
          _mapController.move(stop.position, 15);
          _showStopDetails(stop);
        },
        child: Row(
          children: [
            // Selection checkbox
            Checkbox(
              value: isSelected,
              onChanged: (_) => provider.toggleStopSelection(stop.id),
              activeColor: const Color(0xFF00c853),
              checkColor: Colors.white,
              side: const BorderSide(color: Colors.white54, width: 1.5),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isDelivered 
                    ? const Color(0xFF00c853)
                    : isSelected 
                        ? const Color(0xFF1B998B)
                        : Colors.white54,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isDelivered
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: isSelected || isDelivered ? Colors.white : const Color(0xFF1a237e),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stop.name,
                    style: AppStyles.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'CMD #${stop.order.id}',
                    style: AppStyles.caption.copyWith(color: Colors.white60),
                  ),
                ],
              ),
            ),
            if (isSelected && !isDelivered)
              IconButton(
                icon: const Icon(Icons.check_circle_outline, color: Colors.white70, size: 20),
                onPressed: () => _markDelivered(stop),
                tooltip: 'Marquer livré',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptimizationSection(DeliveryRouteProvider provider) {
    return _buildSection(
      icon: Icons.route,
      title: 'Optimisation',
      child: Column(
        children: [
          _buildButton(
            icon: Icons.auto_fix_high,
            label: 'Calculer le trajet optimal',
            onPressed: provider.selectedStops.isEmpty ? null : _optimizeRoute,
            isPrimary: true,
          ),
          if (provider.selectedStops.isEmpty && provider.stops.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Sélectionnez au moins un client',
                style: AppStyles.caption.copyWith(color: Colors.orange),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 8),
          _buildButton(
            icon: Icons.delete_sweep,
            label: 'Effacer la route',
            onPressed: provider.routePoints.isEmpty ? null : () {
              provider.resetRoute();
            },
            isPrimary: false,
            isDanger: true,
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection(DeliveryRouteProvider provider) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00c853), Color(0xFF00e676)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📊 Résultats',
            style: AppStyles.bodyMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildResultRow('Distance', provider.formattedDistance),
          _buildResultRow('Temps estimé', provider.formattedDuration),
          _buildResultRow('Arrêts', '${provider.stops.length}'),
          _buildResultRow('Livrées', '${provider.stops.where((s) => s.isDelivered).length}'),
          _buildResultRow('Routing', provider.usedOsrmGeometry ? 'OSRM ✓' : (provider.isOsrmAvailable ? 'Fallback' : 'Haversine')),
          _buildResultRow('Points', '${provider.routePoints.length}'),
          
          const SizedBox(height: 12),
          
          // Route order
          Text(
            'Ordre des stops:',
            style: AppStyles.caption.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          ...provider.stops.asMap().entries.map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${e.key + 1}',
                        style: const TextStyle(
                          color: Color(0xFF1a237e),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      e.value.name,
                      style: AppStyles.caption.copyWith(color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (e.value.isDelivered)
                    const Icon(Icons.check, color: Colors.white, size: 16),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppStyles.bodySmall.copyWith(color: Colors.white70)),
          Text(value, style: AppStyles.bodySmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSection({required IconData icon, required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoField(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppStyles.caption.copyWith(color: Colors.grey[600])),
          const SizedBox(height: 2),
          Text(value, style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
    bool isPrimary = false,
    bool isDanger = false,
  }) {
    final Color bgColor;
    if (isDanger) {
      bgColor = const Color(0xFFf44336);
    } else if (isPrimary) {
      bgColor = const Color(0xFF00c853);
    } else {
      bgColor = Colors.white.withOpacity(0.2);
    }
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontSize: 13)),
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildMap() {
    return Consumer3<DeliveryRouteProvider, LivreurProvider, OrderProvider>(
      builder: (context, routeProvider, livreurProvider, orderProvider, _) {
        return FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: livreurProvider.currentPosition ?? _defaultCenter,
            initialZoom: 12,
          ),
          children: [
            // Tile layer (OpenStreetMap)
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.smartdelivery',
            ),
            
            // Route polyline
            if (routeProvider.routePoints.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: routeProvider.routePoints,
                    strokeWidth: 5,
                    // Green for OSRM real road geometry, Orange for fallback straight lines
                    color: routeProvider.usedOsrmGeometry 
                        ? const Color(0xFF00C853) // Green for OSRM
                        : const Color(0xFFFF6D00), // Orange for fallback
                  ),
                ],
              ),
            
            // Markers
            MarkerLayer(
              markers: [
                // Current position marker (livreur)
                if (livreurProvider.currentPosition != null)
                  Marker(
                    point: livreurProvider.currentPosition!,
                    width: 55,
                    height: 55,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196f3),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text('🚚', style: TextStyle(fontSize: 24)),
                      ),
                    ),
                  ),
                
                // Delivery stop markers - ONLY show selected stops on map
                ...routeProvider.selectedStops.asMap().entries.map((entry) {
                  final index = entry.key;
                  final stop = entry.value;
                  final isOptimized = routeProvider.routePoints.isNotEmpty;
                  
                  return Marker(
                    point: stop.position,
                    width: 40,
                    height: 50,
                    child: GestureDetector(
                      onTap: () => _showStopDetails(stop),
                      child: Column(
                        children: [
                          Container(
                            width: 35,
                            height: 35,
                            decoration: BoxDecoration(
                              gradient: stop.isDelivered
                                  ? const LinearGradient(colors: [Color(0xFF00c853), Color(0xFF00e676)])
                                  : isOptimized
                                      ? const LinearGradient(colors: [Color(0xFF1B998B), Color(0xFF00c853)])
                                      : null,
                              color: stop.isDelivered || isOptimized 
                                  ? null 
                                  : const Color(0xFF1B998B),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Center(
                              child: stop.isDelivered
                                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                                  : Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildTopControls() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Toggle sidebar button
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8),
                ],
              ),
              child: IconButton(
                icon: Icon(_showSidebar ? Icons.menu_open : Icons.menu),
                onPressed: () => setState(() => _showSidebar = !_showSidebar),
              ),
            ),
            const SizedBox(width: 8),
            
            // Back button
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            
            const Spacer(),
            
            // Map controls
            Column(
              children: [
                _buildMapButton(Icons.center_focus_strong, 'Centrer', () {
                  final pos = context.read<LivreurProvider>().currentPosition;
                  if (pos != null) _mapController.move(pos, 14);
                }),
                const SizedBox(height: 8),
                _buildMapButton(Icons.zoom_out_map, 'Tout voir', _fitAllMarkers),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapButton(IconData icon, String tooltip, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: const Color(0xFF1a237e)),
        onPressed: onPressed,
        tooltip: tooltip,
      ),
    );
  }

  Widget _buildOptimizationOverlay() {
    return Container(
      color: const Color(0xFF1a237e).withOpacity(0.9),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00e676)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _optimizationStatus.isNotEmpty ? _optimizationStatus : 'Calcul en cours...',
              style: AppStyles.bodyLarge.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 12),
            Consumer<DeliveryRouteProvider>(
              builder: (context, provider, _) {
                return Text(
                  provider.isOsrmAvailable ? 'Via OSRM (routes réelles)' : 'Via Haversine (estimation)',
                  style: AppStyles.bodySmall.copyWith(color: Colors.white70),
                );
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 280,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _optimizationProgress,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00e676)),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(_optimizationProgress * 100).toInt()}%',
                    style: AppStyles.caption.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _optimizeRoute() async {
    setState(() {
      _isOptimizing = true;
      _optimizationProgress = 0;
      _optimizationStatus = 'Calcul de la matrice des distances...';
    });
    
    final routeProvider = context.read<DeliveryRouteProvider>();
    
    // Simulate progress updates
    for (int i = 1; i <= 5; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      setState(() {
        _optimizationProgress = i * 0.15;
        if (i == 2) _optimizationStatus = 'Construction de la matrice...';
        if (i == 3) _optimizationStatus = 'Optimisation TSP...';
        if (i == 4) _optimizationStatus = 'Génération de la route...';
      });
    }
    
    await routeProvider.calculateOptimizedRoute();
    
    setState(() {
      _optimizationProgress = 1.0;
      _optimizationStatus = 'Terminé!';
    });
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      setState(() => _isOptimizing = false);
      
      if (routeProvider.routePoints.isNotEmpty) {
        _fitAllMarkers();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Text('✅'),
                const SizedBox(width: 8),
                Text(
                  routeProvider.isOsrmAvailable 
                      ? 'Trajet optimal calculé via OSRM!' 
                      : 'Trajet calculé (mode hors-ligne)',
                ),
              ],
            ),
            backgroundColor: const Color(0xFF00c853),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _fitAllMarkers() {
    final routeProvider = context.read<DeliveryRouteProvider>();
    final livreurProvider = context.read<LivreurProvider>();
    
    final points = <LatLng>[];
    if (livreurProvider.currentPosition != null) {
      points.add(livreurProvider.currentPosition!);
    }
    points.addAll(routeProvider.stops.map((s) => s.position));
    
    if (points.length >= 2) {
      final bounds = LatLngBounds.fromPoints(points);
      _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)));
    } else if (points.isNotEmpty) {
      _mapController.move(points.first, 14);
    }
  }

  void _showStopDetails(DeliveryStop stop) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: stop.isDelivered ? AppColors.success : AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    stop.isDelivered ? Icons.check : Icons.location_on,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(stop.name, style: AppStyles.headingSmall),
                      Text(
                        stop.isDelivered ? 'Livré ✓' : 'En attente',
                        style: AppStyles.bodySmall.copyWith(
                          color: stop.isDelivered ? AppColors.success : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _buildDetailRow(Icons.shopping_bag, 'Commande', '#${stop.order.id}'),
            _buildDetailRow(Icons.location_on, 'Adresse', stop.address.isNotEmpty ? stop.address : 'Non spécifiée'),
            _buildDetailRow(Icons.map, 'Coordonnées', '${stop.position.latitude.toStringAsFixed(5)}, ${stop.position.longitude.toStringAsFixed(5)}'),
            if (stop.order.montantTTC != null)
              _buildDetailRow(Icons.attach_money, 'Montant', '${stop.order.montantTTC!.toStringAsFixed(2)} TND'),
            const SizedBox(height: 24),
            if (!stop.isDelivered)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _markDelivered(stop);
                  },
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Marquer comme livré'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Text('$label: ', style: AppStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          Expanded(child: Text(value, style: AppStyles.bodyMedium)),
        ],
      ),
    );
  }

  Future<void> _markDelivered(DeliveryStop stop) async {
    final routeProvider = context.read<DeliveryRouteProvider>();
    final orderProvider = context.read<OrderProvider>();
    
    final success = await orderProvider.markAsDelivered(stop.order.id!);
    
    if (success) {
      routeProvider.markStopAsDelivered(stop.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${stop.name} - Livraison confirmée ✓'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        
        if (routeProvider.allDelivered) {
          _showCompletionDialog();
        }
      }
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('🎉', style: TextStyle(fontSize: 28)),
            SizedBox(width: 12),
            Text('Félicitations !'),
          ],
        ),
        content: Consumer<DeliveryRouteProvider>(
          builder: (context, provider, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Toutes les livraisons ont été effectuées !',
                  style: AppStyles.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        Text('${provider.stops.length}', style: AppStyles.headingLarge),
                        Text('Livraisons', style: AppStyles.caption),
                      ],
                    ),
                    Column(
                      children: [
                        Text(provider.formattedDistance, style: AppStyles.headingLarge),
                        Text('Parcourus', style: AppStyles.caption),
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Terminer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
