import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../data/models/models.dart';
import '../../../data/services/services.dart';
import '../../../providers/providers.dart';

class DeliveryMapScreen extends StatefulWidget {
  final List<Order>? orders;
  final int? orderId;
  
  const DeliveryMapScreen({super.key, this.orders, this.orderId});

  @override
  State<DeliveryMapScreen> createState() => _DeliveryMapScreenState();
}

class _DeliveryMapScreenState extends State<DeliveryMapScreen> with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  bool _isOptimizing = false;
  double _optimizationProgress = 0;
  String _optimizationStatus = '';
  bool _showSidebar = true;
  late TabController _tabController;
  
  // Default center: Sfax, Tunisia
  static const LatLng _defaultCenter = LatLng(34.74, 10.76);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final routeProvider = context.read<DeliveryRouteProvider>();
        routeProvider.setMapMode(
          _tabController.index == 0 ? MapMode.collect : MapMode.deliver,
        );
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeMap();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    if (!mounted) return;
    
    final routeProvider = context.read<DeliveryRouteProvider>();
    final livreurProvider = context.read<LivreurProvider>();
    final orderProvider = context.read<OrderProvider>();
    
    // Run independent network calls in parallel for speed
    await Future.wait([
      routeProvider.checkOsrmConnection(),
      orderProvider.loadMapData(),
      livreurProvider.startPositionTracking(),
    ]);
    if (!mounted) return;
    
    // Get current position
    final position = livreurProvider.currentPosition ?? await livreurProvider.getCurrentPosition();
    if (!mounted) return;
    
    if (position != null) {
      routeProvider.setStartPosition(position);
      _mapController.move(position, 13);
    } else {
      routeProvider.setStartPosition(_defaultCenter);
      _mapController.move(_defaultCenter, 12);
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
      // Initialize both collection stops (from orders to collect) and delivery stops
      final ordersToCollect = orders.where((o) => o.collected != true).toList();
      final ordersToDeliver = orders.where((o) => o.collected == true).toList();
      
      // Initialize collection stops from orders needing collection
      if (ordersToCollect.isNotEmpty) {
        await routeProvider.initializeCollectionStops(ordersToCollect, OrderService());
      }
      
      // Initialize delivery stops from already-collected orders
      if (ordersToDeliver.isNotEmpty) {
        await routeProvider.initializeFromOrders(ordersToDeliver);
      }
      
      // If no orders to collect, switch to deliver tab
      if (ordersToCollect.isEmpty && ordersToDeliver.isNotEmpty) {
        _tabController.animateTo(1);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          if (_showSidebar) _buildSidebar(),
          Expanded(
            child: Stack(
              children: [
                _buildMap(),
                _buildTopControls(),
                if (_isOptimizing) _buildOptimizationOverlay(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================== SIDEBAR ==================

  Widget _buildSidebar() {
    return Consumer2<DeliveryRouteProvider, OrderProvider>(
      builder: (context, routeProvider, orderProvider, _) {
        return Container(
          width: 340,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1a237e), Color(0xFF0d47a1)],
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
              _buildSidebarHeader(routeProvider),
              _buildModeTabs(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCollectContent(routeProvider, orderProvider),
                    _buildDeliverContent(routeProvider),
                  ],
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.2)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🚚', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text('Smart Delivery', style: AppStyles.headingMedium.copyWith(color: Colors.white)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Plus Court Chemin - OSRM', style: AppStyles.bodySmall.copyWith(color: Colors.white70)),
          const SizedBox(height: 10),
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
                    color: provider.isOsrmAvailable ? const Color(0xFF00e676) : const Color(0xFFff5252),
                    boxShadow: [
                      BoxShadow(
                        color: (provider.isOsrmAvailable ? const Color(0xFF00e676) : const Color(0xFFff5252)).withOpacity(0.5),
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

  Widget _buildModeTabs() {
    return Container(
      color: Colors.black.withOpacity(0.15),
      child: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 12),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.inventory_2, size: 16),
                const SizedBox(width: 5),
                Consumer<DeliveryRouteProvider>(
                  builder: (context, p, _) => Text('Collecter (${p.collectionStops.where((s) => !s.isCollected).map((s) => s.orderId).toSet().length})'),
                ),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.local_shipping, size: 16),
                const SizedBox(width: 5),
                Consumer<DeliveryRouteProvider>(
                  builder: (context, p, _) => Text('Livrer (${p.stops.where((s) => !s.isDelivered).length})'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================== COLLECT TAB ==================

  Widget _buildCollectContent(DeliveryRouteProvider routeProvider, OrderProvider orderProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _buildLivreurSection(),
          const SizedBox(height: 12),
          _buildCollectionStopsSection(routeProvider, orderProvider),
          const SizedBox(height: 12),
          _buildCollectionOptimizationSection(routeProvider),
          if (routeProvider.collectionRoutePoints.isNotEmpty)
            _buildCollectionResultsSection(routeProvider),
        ],
      ),
    );
  }

  Widget _buildCollectionStopsSection(DeliveryRouteProvider routeProvider, OrderProvider orderProvider) {
    final stops = routeProvider.collectionStops.where((s) => !s.isCollected).toList();
    
    // Group stops by orderId
    final grouped = <int, List<CollectionStop>>{};
    for (final stop in stops) {
      grouped.putIfAbsent(stop.orderId, () => []).add(stop);
    }
    final selectedCount = routeProvider.selectedCollectionIds.length;
    
    return _buildSection(
      icon: Icons.warehouse,
      title: 'Dépôts à visiter (${stops.length})',
      color: Colors.orange,
      child: Column(
        children: [
          if (stops.isNotEmpty) ...[
            Row(
              children: [
                Text('Commandes: $selectedCount/${grouped.length}', style: AppStyles.caption.copyWith(color: Colors.white70)),
                const Spacer(),
                _miniTextButton(
                  icon: Icons.check_box,
                  label: 'Tout',
                  onPressed: () => routeProvider.selectAllCollectionStops(),
                ),
                _miniTextButton(
                  icon: Icons.check_box_outline_blank,
                  label: 'Aucun',
                  onPressed: () => routeProvider.deselectAllCollectionStops(),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          if (stops.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.check_circle_outline, size: 40, color: Colors.white.withOpacity(0.3)),
                  const SizedBox(height: 8),
                  Text('Rien à collecter', style: AppStyles.bodySmall.copyWith(color: Colors.white70), textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Text('Les commandes collectées sont\ndans "À livrer"', style: AppStyles.caption.copyWith(color: Colors.white38), textAlign: TextAlign.center),
                ],
              ),
            )
          else
            ...grouped.entries.map((entry) => _buildOrderCollectionGroup(
              entry.key, entry.value, routeProvider, orderProvider,
            )),
        ],
      ),
    );
  }

  Widget _buildOrderCollectionGroup(int orderId, List<CollectionStop> depotStops, DeliveryRouteProvider routeProvider, OrderProvider orderProvider) {
    final isSelected = routeProvider.selectedCollectionIds.contains(orderId);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.orange.withOpacity(0.3) : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: isSelected ? Border.all(color: Colors.orange, width: 2) : null,
      ),
      child: Column(
        children: [
          // Order header with checkbox
          InkWell(
            onTap: () => routeProvider.toggleCollectionSelection(orderId),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) => routeProvider.toggleCollectionSelection(orderId),
                    activeColor: Colors.orange,
                    checkColor: Colors.white,
                    side: const BorderSide(color: Colors.white54, width: 1.5),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.orange.shade700,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(child: Icon(Icons.shopping_bag, color: Colors.white, size: 14)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CMD #$orderId',
                          style: AppStyles.bodySmall.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${depotStops.length} dépôt(s) à visiter',
                          style: AppStyles.caption.copyWith(color: Colors.white60),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Show depot stops when selected
          if (isSelected)
            ...depotStops.map((stop) => _buildDepotStopItem(stop, routeProvider, orderProvider)),
        ],
      ),
    );
  }

  Widget _buildDepotStopItem(CollectionStop stop, DeliveryRouteProvider routeProvider, OrderProvider orderProvider) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 8, bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 24, height: 24,
                decoration: BoxDecoration(
                  color: Colors.orange.shade600,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('${stop.stepIndex + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stop.depotName,
                      style: AppStyles.bodySmall.copyWith(color: Colors.white, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    ...stop.items.map((item) => Text(
                      '${item.name} x${item.quantity}',
                      style: AppStyles.caption.copyWith(color: Colors.white54, fontSize: 10),
                    )),
                  ],
                ),
              ),
              _collectButton(stop, routeProvider, orderProvider),
            ],
          ),
        ],
      ),
    );
  }

  Widget _collectButton(CollectionStop stop, DeliveryRouteProvider routeProvider, OrderProvider orderProvider) {
    return SizedBox(
      height: 28,
      child: ElevatedButton.icon(
        onPressed: () => _markCollected(stop, routeProvider, orderProvider),
        icon: const Icon(Icons.check, size: 14),
        label: const Text('Collecté', style: TextStyle(fontSize: 11)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00c853),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
    );
  }

  Widget _buildCollectionOptimizationSection(DeliveryRouteProvider provider) {
    final selectedStops = provider.selectedCollectionStops.where((s) => !s.isCollected).toList();
    return _buildSection(
      icon: Icons.route,
      title: 'Optimisation collecte',
      child: Column(
        children: [
          _buildButton(
            icon: Icons.auto_fix_high,
            label: 'Calculer le trajet de collecte',
            onPressed: selectedStops.isEmpty ? null : _optimizeCollectionRoute,
            isPrimary: true,
            color: Colors.orange,
          ),
          if (selectedStops.isEmpty && provider.collectionStops.any((s) => !s.isCollected))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Sélectionnez au moins un dépôt',
                style: AppStyles.caption.copyWith(color: Colors.orange.shade200),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 8),
          _buildButton(
            icon: Icons.delete_sweep,
            label: 'Effacer la route',
            onPressed: provider.collectionRoutePoints.isEmpty ? null : () {
              provider.clearCollectionRoute();
            },
            isPrimary: false,
            isDanger: true,
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionResultsSection(DeliveryRouteProvider provider) {
    final stops = provider.selectedCollectionStops.where((s) => !s.isCollected).toList();
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.orange.shade700, Colors.orange.shade500]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📦 Route de collecte', style: AppStyles.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildResultRow('Distance', provider.formattedCollectionDistance),
          _buildResultRow('Temps estimé', provider.formattedCollectionDuration),
          _buildResultRow('Dépôts', '${stops.length}'),
          _buildResultRow('Routing', provider.usedOsrmGeometryCollection ? 'OSRM ✓' : (provider.isOsrmAvailable ? 'Fallback' : 'Haversine')),
          const SizedBox(height: 12),
          Text('Ordre des dépôts:', style: AppStyles.caption.copyWith(color: Colors.white70)),
          const SizedBox(height: 8),
          ...stops.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Container(
                  width: 22, height: 22,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: Center(child: Text('${e.key + 1}', style: const TextStyle(color: Color(0xFF1a237e), fontWeight: FontWeight.bold, fontSize: 11))),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(e.value.depotName, style: AppStyles.caption.copyWith(color: Colors.white), overflow: TextOverflow.ellipsis)),
                Text('CMD #${e.value.orderId}', style: AppStyles.caption.copyWith(color: Colors.white60)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  // ================== DELIVER TAB ==================

  Widget _buildDeliverContent(DeliveryRouteProvider routeProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _buildLivreurSection(),
          const SizedBox(height: 12),
          _buildStopsSection(routeProvider),
          const SizedBox(height: 12),
          _buildOptimizationSection(routeProvider),
          if (routeProvider.routePoints.isNotEmpty)
            _buildResultsSection(routeProvider),
        ],
      ),
    );
  }

  // ================== SHARED WIDGETS ==================

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
                  Expanded(child: _buildInfoField('Latitude', pos?.latitude.toStringAsFixed(6) ?? '--')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildInfoField('Longitude', pos?.longitude.toStringAsFixed(6) ?? '--')),
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
                        if (pos != null) _mapController.move(pos, 14);
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
          if (provider.stops.isNotEmpty) ...[
            Row(
              children: [
                Text('Sélectionnés: $selectedCount', style: AppStyles.caption.copyWith(color: Colors.white70)),
                const Spacer(),
                _miniTextButton(icon: Icons.check_box, label: 'Tout', onPressed: () => provider.selectAllStops()),
                _miniTextButton(icon: Icons.check_box_outline_blank, label: 'Aucun', onPressed: () => provider.deselectAllStops()),
              ],
            ),
            const SizedBox(height: 8),
          ],
          if (provider.stops.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 40, color: Colors.white.withOpacity(0.3)),
                  const SizedBox(height: 8),
                  Text('Aucune livraison', style: AppStyles.bodySmall.copyWith(color: Colors.white70), textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Text('Collectez d\'abord les articles\ndans l\'onglet "Collecter"', style: AppStyles.caption.copyWith(color: Colors.white38), textAlign: TextAlign.center),
                ],
              ),
            )
          else
            ...provider.stops.asMap().entries.map((entry) => _buildStopItem(entry.key, entry.value, provider)),
        ],
      ),
    );
  }

  Widget _buildStopItem(int index, DeliveryStop stop, DeliveryRouteProvider provider) {
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
            : null,
      ),
      child: InkWell(
        onTap: () => provider.toggleStopSelection(stop.id),
        onDoubleTap: () {
          _mapController.move(stop.position, 15);
          _showStopDetails(stop);
        },
        child: Row(
          children: [
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
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: isDelivered ? const Color(0xFF00c853) : isSelected ? const Color(0xFF1B998B) : Colors.white54,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isDelivered
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : Text('${index + 1}', style: TextStyle(
                        color: isSelected || isDelivered ? Colors.white : const Color(0xFF1a237e),
                        fontWeight: FontWeight.bold, fontSize: 12,
                      )),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stop.name, style: AppStyles.bodySmall.copyWith(color: Colors.white, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('CMD #${stop.order.id}', style: AppStyles.caption.copyWith(color: Colors.white60)),
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
      title: 'Optimisation livraison',
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
              child: Text('Sélectionnez au moins un client', style: AppStyles.caption.copyWith(color: Colors.orange), textAlign: TextAlign.center),
            ),
          const SizedBox(height: 8),
          _buildButton(
            icon: Icons.delete_sweep,
            label: 'Effacer la route',
            onPressed: provider.routePoints.isEmpty ? null : () => provider.clearRoutePath(),
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
        gradient: const LinearGradient(colors: [Color(0xFF00c853), Color(0xFF00e676)]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📊 Route de livraison', style: AppStyles.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildResultRow('Distance', provider.formattedDistance),
          _buildResultRow('Temps estimé', provider.formattedDuration),
          _buildResultRow('Arrêts', '${provider.stops.length}'),
          _buildResultRow('Livrées', '${provider.stops.where((s) => s.isDelivered).length}'),
          _buildResultRow('Routing', provider.usedOsrmGeometry ? 'OSRM ✓' : (provider.isOsrmAvailable ? 'Fallback' : 'Haversine')),
          const SizedBox(height: 12),
          Text('Ordre des stops:', style: AppStyles.caption.copyWith(color: Colors.white70)),
          const SizedBox(height: 8),
          ...provider.stops.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Container(
                  width: 22, height: 22,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: Center(child: Text('${e.key + 1}', style: const TextStyle(color: Color(0xFF1a237e), fontWeight: FontWeight.bold, fontSize: 11))),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(e.value.name, style: AppStyles.caption.copyWith(color: Colors.white), overflow: TextOverflow.ellipsis)),
                if (e.value.isDelivered) const Icon(Icons.check, color: Colors.white, size: 16),
              ],
            ),
          )),
        ],
      ),
    );
  }

  // ================== MAP ==================

  Widget _buildMap() {
    return Consumer3<DeliveryRouteProvider, LivreurProvider, OrderProvider>(
      builder: (context, routeProvider, livreurProvider, orderProvider, _) {
        final isCollectMode = routeProvider.mapMode == MapMode.collect;
        
        return FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: livreurProvider.currentPosition ?? _defaultCenter,
            initialZoom: 12,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.smartdelivery',
            ),
            
            // Route polyline - show based on mode
            if (isCollectMode && routeProvider.collectionRoutePoints.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: routeProvider.collectionRoutePoints,
                    strokeWidth: 5,
                    color: routeProvider.usedOsrmGeometryCollection 
                        ? Colors.orange.shade600
                        : Colors.orange.shade400,
                  ),
                ],
              ),
            if (!isCollectMode && routeProvider.routePoints.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: routeProvider.routePoints,
                    strokeWidth: 5,
                    color: routeProvider.usedOsrmGeometry 
                        ? const Color(0xFF00C853)
                        : const Color(0xFFFF6D00),
                  ),
                ],
              ),
            
            // Markers
            MarkerLayer(
              markers: [
                // Infrastructure markers
                ..._buildInfraMarkers(orderProvider),
                
                // Livreur position
                if (livreurProvider.currentPosition != null)
                  Marker(
                    point: livreurProvider.currentPosition!,
                    width: 55, height: 55,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196f3),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, spreadRadius: 2)],
                      ),
                      child: const Center(child: Text('🚚', style: TextStyle(fontSize: 24))),
                    ),
                  ),
                
                // Collection stop markers (depot markers) - show in collect mode
                if (isCollectMode)
                  ...routeProvider.selectedCollectionStops.where((s) => !s.isCollected).toList().asMap().entries.map((entry) {
                    final index = entry.key;
                    final stop = entry.value;
                    return Marker(
                      point: stop.position,
                      width: 40, height: 50,
                      child: GestureDetector(
                        onTap: () => _showCollectionStopDetails(stop),
                        child: Container(
                          width: 35, height: 35,
                          decoration: BoxDecoration(
                            color: Colors.orange.shade700,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8)],
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                
                // Delivery stop markers - show in deliver mode
                if (!isCollectMode)
                  ...routeProvider.selectedStops.asMap().entries.map((entry) {
                    final index = entry.key;
                    final stop = entry.value;
                    final isOptimized = routeProvider.routePoints.isNotEmpty;
                    
                    return Marker(
                      point: stop.position,
                      width: 40, height: 50,
                      child: GestureDetector(
                        onTap: () => _showStopDetails(stop),
                        child: Container(
                          width: 35, height: 35,
                          decoration: BoxDecoration(
                            gradient: stop.isDelivered
                                ? const LinearGradient(colors: [Color(0xFF00c853), Color(0xFF00e676)])
                                : isOptimized
                                    ? const LinearGradient(colors: [Color(0xFF1B998B), Color(0xFF00c853)])
                                    : null,
                            color: stop.isDelivered || isOptimized ? null : const Color(0xFF1B998B),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8)],
                          ),
                          child: Center(
                            child: stop.isDelivered
                                ? const Icon(Icons.check, color: Colors.white, size: 18)
                                : Text('${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
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

  List<Marker> _buildInfraMarkers(OrderProvider orderProvider) {
    final markers = <Marker>[];
    final mapData = orderProvider.mapData;
    if (mapData == null) return markers;

    final societe = mapData['societe'];
    if (societe != null && societe['latitude'] != null && societe['longitude'] != null) {
      markers.add(Marker(
        point: LatLng((societe['latitude'] as num).toDouble(), (societe['longitude'] as num).toDouble()),
        width: 44, height: 44,
        child: Tooltip(message: '${societe['nom']} (Société)', child: const Icon(Icons.business, color: Colors.blue, size: 36)),
      ));
    }

    final magasins = mapData['magasins'] as List?;
    if (magasins != null) {
      for (final m in magasins) {
        if (m['latitude'] != null && m['longitude'] != null) {
          markers.add(Marker(
            point: LatLng((m['latitude'] as num).toDouble(), (m['longitude'] as num).toDouble()),
            width: 38, height: 38,
            child: Tooltip(
              message: '${m['nom']} (Magasin)',
              child: Container(
                decoration: BoxDecoration(color: Colors.green.shade700, shape: BoxShape.circle, boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)]),
                child: const Icon(Icons.store, color: Colors.white, size: 20),
              ),
            ),
          ));
        }
      }
    }

    final depots = mapData['depots'] as List?;
    if (depots != null) {
      for (final d in depots) {
        if (d['latitude'] != null && d['longitude'] != null) {
          markers.add(Marker(
            point: LatLng((d['latitude'] as num).toDouble(), (d['longitude'] as num).toDouble()),
            width: 38, height: 38,
            child: Tooltip(
              message: '${d['nom']} (Dépôt)',
              child: Container(
                decoration: BoxDecoration(color: Colors.orange.shade700, shape: BoxShape.circle, boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)]),
                child: const Icon(Icons.warehouse, color: Colors.white, size: 20),
              ),
            ),
          ));
        }
      }
    }

    return markers;
  }

  // ================== TOP CONTROLS ==================

  Widget _buildTopControls() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8)],
              ),
              child: IconButton(
                icon: Icon(_showSidebar ? Icons.menu_open : Icons.menu),
                onPressed: () => setState(() => _showSidebar = !_showSidebar),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8)],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const Spacer(),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8)],
      ),
      child: IconButton(icon: Icon(icon, color: const Color(0xFF1a237e)), onPressed: onPressed, tooltip: tooltip),
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
              width: 60, height: 60,
              child: CircularProgressIndicator(strokeWidth: 4, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00e676))),
            ),
            const SizedBox(height: 24),
            Text(_optimizationStatus.isNotEmpty ? _optimizationStatus : 'Calcul en cours...', style: AppStyles.bodyLarge.copyWith(color: Colors.white)),
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
                  Text('${(_optimizationProgress * 100).toInt()}%', style: AppStyles.caption.copyWith(color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================== REUSABLE WIDGETS ==================

  Widget _buildSection({required IconData icon, required String title, required Widget child, Color? color}) {
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
              Icon(icon, color: color ?? Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppStyles.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
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
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(8)),
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
    Color? color,
  }) {
    final Color bgColor;
    if (isDanger) {
      bgColor = const Color(0xFFf44336);
    } else if (isPrimary && color != null) {
      bgColor = color;
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

  Widget _miniTextButton({required IconData icon, required String label, required VoidCallback onPressed}) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white70, size: 16),
      label: Text(label, style: AppStyles.caption.copyWith(color: Colors.white70)),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  // ================== ACTIONS ==================

  Future<void> _optimizeCollectionRoute() async {
    setState(() {
      _isOptimizing = true;
      _optimizationProgress = 0;
      _optimizationStatus = 'Construction de la matrice...';
    });
    
    final routeProvider = context.read<DeliveryRouteProvider>();
    
    for (int i = 1; i <= 5; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      setState(() {
        _optimizationProgress = i * 0.15;
        if (i == 2) _optimizationStatus = 'Calcul des distances...';
        if (i == 3) _optimizationStatus = 'Optimisation du trajet...';
        if (i == 4) _optimizationStatus = 'Génération de la route...';
      });
    }
    
    await routeProvider.calculateCollectionRoute();
    
    setState(() {
      _optimizationProgress = 1.0;
      _optimizationStatus = 'Terminé!';
    });
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      setState(() => _isOptimizing = false);
      if (routeProvider.collectionRoutePoints.isNotEmpty) {
        _fitAllMarkers();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [Text('📦'), SizedBox(width: 8), Text('Trajet de collecte calculé!')]),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _optimizeRoute() async {
    setState(() {
      _isOptimizing = true;
      _optimizationProgress = 0;
      _optimizationStatus = 'Calcul de la matrice des distances...';
    });
    
    final routeProvider = context.read<DeliveryRouteProvider>();
    
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
            content: Row(children: [
              const Text('✅'),
              const SizedBox(width: 8),
              Text(routeProvider.isOsrmAvailable ? 'Trajet optimal calculé via OSRM!' : 'Trajet calculé (mode hors-ligne)'),
            ]),
            backgroundColor: const Color(0xFF00c853),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _markCollected(CollectionStop stop, DeliveryRouteProvider routeProvider, OrderProvider orderProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.inventory_2, color: Colors.orange),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text('Collecte - ${stop.depotName}')),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CMD #${stop.orderId} - Dépôt ${stop.stepIndex + 1}'),
            const SizedBox(height: 12),
            ...stop.items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(children: [
                const Icon(Icons.check_box_outline_blank, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text('${item.name} x${item.quantity}'),
              ]),
            )),
            const SizedBox(height: 12),
            const Text('Articles collectés de ce dépôt ?', style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Non')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00c853)),
            child: const Text('Oui, collecté', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Mark this individual depot stop as collected
      routeProvider.markCollectionStopCollected(stop.id);
      
      // Check if ALL depot stops of this order are now collected
      if (routeProvider.isOrderFullyCollected(stop.orderId)) {
        // All depots visited → mark order as collected on backend
        final success = await orderProvider.markAsCollected(stop.orderId);
        
        if (success && mounted) {
          // Add the order to delivery stops
          final order = stop.order.copyWith(collected: true);
          if (order.latitudeLivraison != null && order.longitudeLivraison != null) {
            routeProvider.addStop(DeliveryStop(
              id: order.id ?? 0,
              name: order.clientNom ?? 'Client ${order.clientId}',
              address: order.adresseLivraison ?? '',
              position: LatLng(order.latitudeLivraison!, order.longitudeLivraison!),
              order: order,
            ));
          } else if (order.clientLatitude != null && order.clientLongitude != null) {
            routeProvider.addStop(DeliveryStop(
              id: order.id ?? 0,
              name: order.clientNom ?? 'Client ${order.clientId}',
              address: order.adresseLivraison ?? '',
              position: LatLng(order.clientLatitude!, order.clientLongitude!),
              order: order,
            ));
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(children: [
                const Text('📦'),
                const SizedBox(width: 8),
                Expanded(child: Text('CMD #${stop.orderId} entièrement collectée → ajoutée aux livraisons')),
              ]),
              backgroundColor: const Color(0xFF00c853),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 3),
            ),
          );
          
          // If ALL orders collected, switch to deliver tab
          if (routeProvider.collectionStops.every((s) => s.isCollected)) {
            _tabController.animateTo(1);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(children: [
                    Text('🎉'),
                    SizedBox(width: 8),
                    Text('Toutes les collectes terminées! Passez aux livraisons.'),
                  ]),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          }
        }
      } else {
        // Partial collection - not all depots visited yet
        final remaining = routeProvider.collectionStops
            .where((s) => s.orderId == stop.orderId && !s.isCollected).length;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(children: [
                const Text('✅'),
                const SizedBox(width: 8),
                Expanded(child: Text('${stop.depotName} collecté! Encore $remaining dépôt(s) pour CMD #${stop.orderId}')),
              ]),
              backgroundColor: Colors.orange.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  void _fitAllMarkers() {
    final routeProvider = context.read<DeliveryRouteProvider>();
    final livreurProvider = context.read<LivreurProvider>();
    
    final points = <LatLng>[];
    if (livreurProvider.currentPosition != null) points.add(livreurProvider.currentPosition!);
    
    if (routeProvider.mapMode == MapMode.collect) {
      points.addAll(routeProvider.collectionStops.where((s) => !s.isCollected).map((s) => s.position));
    } else {
      points.addAll(routeProvider.stops.map((s) => s.position));
    }
    
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  color: stop.isDelivered ? AppColors.success : AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(stop.isDelivered ? Icons.check : Icons.location_on, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stop.name, style: AppStyles.headingSmall),
                  Text(stop.isDelivered ? 'Livré ✓' : 'En attente', style: AppStyles.bodySmall.copyWith(color: stop.isDelivered ? AppColors.success : Colors.orange)),
                ],
              )),
            ]),
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
                  onPressed: () { Navigator.pop(context); _markDelivered(stop); },
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

  void _showCollectionStopDetails(CollectionStop stop) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.warehouse, color: Colors.orange.shade700),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stop.depotName, style: AppStyles.headingSmall),
                  Text('Commande #${stop.orderId}', style: AppStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                ],
              )),
            ]),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Text('Articles à collecter:', style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...stop.items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.inventory, size: 18, color: Colors.orange.shade700),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(item.name, style: AppStyles.bodyMedium)),
                Text('x${item.quantity}', style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
              ]),
            )),
            const SizedBox(height: 16),
            _buildDetailRow(Icons.map, 'Coordonnées', '${stop.position.latitude.toStringAsFixed(5)}, ${stop.position.longitude.toStringAsFixed(5)}'),
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
        title: const Row(children: [
          Text('🎉', style: TextStyle(fontSize: 28)),
          SizedBox(width: 12),
          Text('Félicitations !'),
        ]),
        content: Consumer<DeliveryRouteProvider>(
          builder: (context, provider, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Toutes les livraisons ont été effectuées !', style: AppStyles.bodyMedium, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(children: [
                      Text('${provider.stops.length}', style: AppStyles.headingLarge),
                      Text('Livraisons', style: AppStyles.caption),
                    ]),
                    Column(children: [
                      Text(provider.formattedDistance, style: AppStyles.headingLarge),
                      Text('Parcourus', style: AppStyles.caption),
                    ]),
                  ],
                ),
              ],
            );
          },
        ),
        actions: [
          ElevatedButton(
            onPressed: () { Navigator.pop(context); Navigator.pop(context); },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Terminer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
