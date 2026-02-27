import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
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
  late TabController _tabController;
  final DraggableScrollableController _sheetController = DraggableScrollableController();
  double _sheetPosition = 0.4;
  bool _isSheetExpanded = true; // Contrôle l'état du bottom sheet
  
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
    
    // Écouter les changements de position du sheet pour synchroniser l'état
    _sheetController.addListener(() {
      if (_sheetController.size > 0.25 && !_isSheetExpanded) {
        setState(() => _isSheetExpanded = true);
      } else if (_sheetController.size <= 0.25 && _isSheetExpanded) {
        setState(() => _isSheetExpanded = false);
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
    _sheetController.dispose();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    if (!mounted) return;
    
    final routeProvider = context.read<DeliveryRouteProvider>();
    final livreurProvider = context.read<LivreurProvider>();
    final orderProvider = context.read<OrderProvider>();
    final authProvider = context.read<AuthProvider>();
    
    // Run independent network calls in parallel for speed
    // Also ensure livreur orders are loaded (may not be ready yet)
    await Future.wait([
      routeProvider.checkOsrmConnection(),
      orderProvider.loadMapData(),
      livreurProvider.startPositionTracking(),
      if (authProvider.user != null && orderProvider.myOrders.isEmpty)
        orderProvider.loadOrdersForLivreur(authProvider.user!.id!),
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
        final pos = livreurProvider.currentPosition;
        await routeProvider.initializeCollectionStops(
          ordersToCollect,
          OrderService(),
          livreurLat: pos?.latitude,
          livreurLon: pos?.longitude,
        );
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
      backgroundColor: Colors.grey.shade100,
      appBar: _buildModernAppBar(),
      body: Stack(
        children: [
          _buildMap(),
          _buildFloatingControls(),
          _buildBottomSheet(),
          if (_isOptimizing) _buildOptimizationOverlay(),
        ],
      ),
    );
  }

  // ================== MODERN APP BAR ==================

  PreferredSizeWidget _buildModernAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFF1a237e),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('🚚', style: TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Smart Delivery',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Consumer<DeliveryRouteProvider>(
                  builder: (context, provider, _) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: provider.isOsrmAvailable
                          ? const Color(0xFF00e676).withOpacity(0.2)
                          : Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: provider.isOsrmAvailable
                                ? const Color(0xFF00e676)
                                : Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          provider.isOsrmAvailable ? 'OSRM' : 'Hors-ligne',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Consumer<LivreurProvider>(
          builder: (context, livreurProvider, _) => IconButton(
            icon: const Icon(Icons.my_location, color: Colors.white),
            tooltip: 'Ma position',
            onPressed: () async {
              final position = await livreurProvider.getCurrentPosition();
              if (position != null && mounted) {
                context.read<DeliveryRouteProvider>().setStartPosition(position);
                _mapController.move(position, 14);
              }
            },
          ),
        ),
        IconButton(
          icon: const Icon(Icons.center_focus_strong, color: Colors.white),
          tooltip: 'Tout voir',
          onPressed: _fitAllMarkers,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ================== BOTTOM SHEET ==================

  Widget _buildBottomSheet() {
    return Consumer2<DeliveryRouteProvider, OrderProvider>(
      builder: (context, routeProvider, orderProvider, _) {
        return DraggableScrollableSheet(
          controller: _sheetController,
          initialChildSize: _isSheetExpanded ? 0.4 : 0.12,
          minChildSize: 0.12,
          maxChildSize: 0.85,
          snap: true,
          snapSizes: const [0.12, 0.4, 0.85],
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSheetHandle(),
                  _buildModeTabs(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildCollectContent(routeProvider, orderProvider, scrollController),
                        _buildDeliverContent(routeProvider, scrollController),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSheetHandle() {
    return Container(
      padding: const EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 8),
      child: Row(
        children: [
          const Spacer(),
          Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const Spacer(),
          // Bouton pour contrôler le bottom sheet
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: _toggleBottomSheet,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1a237e).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  _isSheetExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                  color: const Color(0xFF1a237e),
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: const Color(0xFF1a237e),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1a237e).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey.shade700,
        labelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        dividerColor: Colors.transparent,
        tabs: [
          Tab(
            height: 44,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.inventory_2, size: 18),
                const SizedBox(width: 6),
                Consumer<DeliveryRouteProvider>(
                  builder: (context, p, _) => Text(
                    'Collecter (${p.collectionStops.where((s) => !s.isCollected).expand((s) => s.orderIds).toSet().length})',
                  ),
                ),
              ],
            ),
          ),
          Tab(
            height: 44,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.local_shipping, size: 18),
                const SizedBox(width: 6),
                Consumer<DeliveryRouteProvider>(
                  builder: (context, p, _) => Text(
                    'Livrer (${p.stops.where((s) => !s.isDelivered).length})',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================== COLLECT TAB ==================

  Widget _buildCollectContent(DeliveryRouteProvider routeProvider, OrderProvider orderProvider, ScrollController scrollController) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildCollectionStopsSection(routeProvider, orderProvider),
          const SizedBox(height: 16),
          _buildCollectionOptimizationSection(routeProvider),
          if (routeProvider.collectionRoutePoints.isNotEmpty)
            _buildCollectionResultsSection(routeProvider),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCollectionStopsSection(DeliveryRouteProvider routeProvider, OrderProvider orderProvider) {
    final stops = routeProvider.collectionStops.where((s) => !s.isCollected).toList();
    
    // All available order IDs (from initial load, not just current plan)
    final allAvailableOrderIds = routeProvider.allAvailableOrders
        .where((o) => o.id != null)
        .map((o) => o.id!)
        .toSet();
    final selectedCount = routeProvider.selectedCollectionIds.length;
    final needsRecompute = routeProvider.needsRecomputation;
    
    return _buildSection(
      icon: Icons.warehouse,
      title: 'Dépôts à visiter (${stops.length})',
      color: Colors.orange,
      child: Column(
        children: [
          if (allAvailableOrderIds.isNotEmpty) ...[
            Row(
              children: [
                Text('Commandes: $selectedCount/${allAvailableOrderIds.length}', style: AppStyles.caption.copyWith(color: Colors.white70)),
                const Spacer(),
                _miniTextButton(
                  icon: Icons.check_box,
                  label: 'Tout',
                  onPressed: () {
                    // Select all available orders, not just those in current plan
                    for (final oid in allAvailableOrderIds) {
                      if (!routeProvider.selectedCollectionIds.contains(oid)) {
                        routeProvider.toggleCollectionSelection(oid);
                      }
                    }
                  },
                ),
                _miniTextButton(
                  icon: Icons.check_box_outline_blank,
                  label: 'Aucun',
                  onPressed: () => routeProvider.deselectAllCollectionStops(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Order filter chips — show ALL available orders
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: allAvailableOrderIds.map((oid) {
                final selected = routeProvider.selectedCollectionIds.contains(oid);
                return FilterChip(
                  label: Text(
                    'CMD #$oid',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: selected ? Colors.white : const Color(0xFF1a237e),
                    ),
                  ),
                  selected: selected,
                  onSelected: (_) => routeProvider.toggleCollectionSelection(oid),
                  selectedColor: Colors.orange.shade600,
                  backgroundColor: Colors.grey.shade100,
                  checkmarkColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  side: BorderSide(
                    color: selected ? Colors.orange.shade600 : Colors.grey.shade300,
                    width: 1.5,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            // "Recalculate" button — shown when selection changed
            if (needsRecompute)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                child: ElevatedButton.icon(
                  onPressed: routeProvider.isLoading ? null : () => _recomputePlan(routeProvider),
                  icon: routeProvider.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.refresh, size: 20),
                  label: Text(
                    routeProvider.isLoading
                        ? 'Calcul en cours...'
                        : 'Recalculer le plan (${routeProvider.selectedCollectionIds.length} cmd)',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
          ],
          if (stops.isEmpty && !needsRecompute)
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    selectedCount == 0
                        ? 'Sélectionnez des commandes puis recalculez'
                        : 'Rien à collecter',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Les commandes collectées sont\ndans "À livrer"',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else if (!needsRecompute)
            ...stops.asMap().entries.map((entry) => _buildMergedDepotItem(
              entry.key, entry.value, routeProvider, orderProvider,
            )),
        ],
      ),
    );
  }

  Future<void> _recomputePlan(DeliveryRouteProvider routeProvider) async {
    final livreurProvider = context.read<LivreurProvider>();
    final pos = livreurProvider.currentPosition;
    await routeProvider.recomputeCollectionPlan(
      OrderService(),
      livreurLat: pos?.latitude,
      livreurLon: pos?.longitude,
    );
  }

  Widget _buildMergedDepotItem(int index, CollectionStop stop, DeliveryRouteProvider routeProvider, OrderProvider orderProvider) {
    final isSelected = stop.orderIds.any((oid) => routeProvider.selectedCollectionIds.contains(oid));
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? Colors.orange.shade400 : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? Colors.orange.withOpacity(0.2)
                : Colors.grey.withOpacity(0.08),
            blurRadius: isSelected ? 8 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showCollectionStopDetails(stop),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.orange.shade600,
                        Colors.orange.shade400,
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stop.depotName,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1a237e),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'CMD ${stop.orderIds.map((id) => '#$id').join(', ')}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.orange.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      ...stop.items.map((item) => Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '${item.name} x${item.quantity} (CMD #${item.orderId})',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      )),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _collectButton(stop, routeProvider, orderProvider),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _collectButton(CollectionStop stop, DeliveryRouteProvider routeProvider, OrderProvider orderProvider) {
    return ElevatedButton.icon(
      onPressed: () => _markCollected(stop, routeProvider, orderProvider),
      icon: const Icon(Icons.check, size: 16),
      label: Text(
        'Collecté',
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00c853),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
      ),
    );
  }

  Widget _buildCollectionOptimizationSection(DeliveryRouteProvider provider) {
    final selectedStops = provider.selectedCollectionStops.where((s) => !s.isCollected).toList();
    return _buildSection(
      icon: Icons.route,
      title: 'Optimisation collecte',
      color: Colors.orange,
      child: Column(
        children: [
          _buildButton(
            icon: Icons.auto_fix_high,
            label: 'Calculer le trajet de collecte',
            onPressed: selectedStops.isEmpty ? null : _optimizeCollectionRoute,
            isPrimary: true,
            color: Colors.orange.shade600,
          ),
          if (selectedStops.isEmpty && provider.collectionStops.any((s) => !s.isCollected))
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Sélectionnez au moins un dépôt',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.orange.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 10),
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
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade600,
            Colors.orange.shade400,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📦', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Text(
                'Route de collecte',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildResultRow('Distance', provider.formattedCollectionDistance),
          _buildResultRow('Temps estimé', provider.formattedCollectionDuration),
          _buildResultRow('Dépôts', '${stops.length}'),
          _buildResultRow(
            'Routing',
            provider.usedOsrmGeometryCollection
                ? 'OSRM ✓'
                : (provider.isOsrmAvailable ? 'Fallback' : 'Haversine'),
          ),
          const SizedBox(height: 16),
          Text(
            'Ordre des dépôts:',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          ...stops.asMap().entries.map((e) => Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${e.key + 1}',
                      style: GoogleFonts.poppins(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    e.value.depotName,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  'CMD ${e.value.orderIds.map((id) => '#$id').join(', ')}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  // ================== DELIVER TAB ==================

  Widget _buildDeliverContent(DeliveryRouteProvider routeProvider, ScrollController scrollController) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStopsSection(routeProvider),
          const SizedBox(height: 16),
          _buildOptimizationSection(routeProvider),
          if (routeProvider.routePoints.isNotEmpty)
            _buildResultsSection(routeProvider),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ================== SHARED WIDGETS ==================

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
                Text(
                  'Sélectionnés: $selectedCount',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const Spacer(),
                _miniTextButton(
                  icon: Icons.check_box,
                  label: 'Tout',
                  onPressed: () => provider.selectAllStops(),
                ),
                _miniTextButton(
                  icon: Icons.check_box_outline_blank,
                  label: 'Aucun',
                  onPressed: () => provider.deselectAllStops(),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (provider.stops.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Aucune livraison',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Collectez d\'abord les articles\ndans l\'onglet "Collecter"',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...provider.stops.asMap().entries.map(
              (entry) => _buildStopItem(entry.key, entry.value, provider),
            ),
        ],
      ),
    );
  }

  Widget _buildStopItem(int index, DeliveryStop stop, DeliveryRouteProvider provider) {
    final isDelivered = stop.isDelivered;
    final isSelected = provider.isStopSelected(stop.id);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDelivered
              ? const Color(0xFF00c853)
              : isSelected
                  ? const Color(0xFF1a237e)
                  : Colors.grey.shade200,
          width: isSelected || isDelivered ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDelivered
                ? const Color(0xFF00c853).withOpacity(0.2)
                : isSelected
                    ? const Color(0xFF1a237e).withOpacity(0.15)
                    : Colors.grey.withOpacity(0.08),
            blurRadius: isSelected || isDelivered ? 8 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => provider.toggleStopSelection(stop.id),
          onDoubleTap: () {
            _mapController.move(stop.position, 15);
            _showStopDetails(stop);
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => provider.toggleStopSelection(stop.id),
                  activeColor: const Color(0xFF1a237e),
                  checkColor: Colors.white,
                  side: BorderSide(
                    color: isSelected ? const Color(0xFF1a237e) : Colors.grey.shade400,
                    width: 2,
                  ),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 6),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: isDelivered
                        ? const LinearGradient(
                            colors: [Color(0xFF00c853), Color(0xFF00e676)],
                          )
                        : isSelected
                            ? const LinearGradient(
                                colors: [Color(0xFF1a237e), Color(0xFF3949AB)],
                              )
                            : null,
                    color: !isDelivered && !isSelected ? Colors.grey.shade300 : null,
                    shape: BoxShape.circle,
                    boxShadow: isDelivered || isSelected
                        ? [
                            BoxShadow(
                              color: (isDelivered
                                      ? const Color(0xFF00c853)
                                      : const Color(0xFF1a237e))
                                  .withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: isDelivered
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : Text(
                            '${index + 1}',
                            style: GoogleFonts.poppins(
                              color: isSelected ? Colors.white : Colors.grey.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stop.name,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1a237e),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'CMD #${stop.order.id}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected && !isDelivered)
                  IconButton(
                    icon: Icon(
                      Icons.check_circle,
                      color: const Color(0xFF00c853),
                      size: 28,
                    ),
                    onPressed: () => _markDelivered(stop),
                    tooltip: 'Marquer livré',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
              ],
            ),
          ),
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
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Sélectionnez au moins un client',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.orange.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 10),
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
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1a237e), Color(0xFF3949AB)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1a237e).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📦', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Text(
                'Route de livraison',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildResultRow('Distance', provider.formattedDistance),
          _buildResultRow('Temps estimé', provider.formattedDuration),
          _buildResultRow('Arrêts', '${provider.stops.length}'),
          _buildResultRow(
            'Livrées',
            '${provider.stops.where((s) => s.isDelivered).length}',
          ),
          _buildResultRow(
            'Routing',
            provider.usedOsrmGeometry
                ? 'OSRM ✓'
                : (provider.isOsrmAvailable ? 'Fallback' : 'Haversine'),
          ),
          const SizedBox(height: 16),
          Text(
            'Ordre des stops:',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          ...provider.stops.asMap().entries.map((e) => Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: e.value.isDelivered
                        ? const Color(0xFF00c853)
                        : Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: e.value.isDelivered
                        ? const Icon(Icons.check, color: Colors.white, size: 14)
                        : Text(
                            '${e.key + 1}',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF1a237e),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    e.value.name,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (e.value.isDelivered)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00c853),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Livré',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
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
    return const SizedBox.shrink();
  }

  // ================== FLOATING CONTROLS ==================

  Widget _buildFloatingControls() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Contrôles de zoom
                Column(
                  children: [
                    _buildFloatingButton(
                      icon: Icons.add,
                      tooltip: 'Zoom +',
                      onPressed: () {
                        final zoom = _mapController.camera.zoom;
                        _mapController.move(_mapController.camera.center, zoom + 1);
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildFloatingButton(
                      icon: Icons.remove,
                      tooltip: 'Zoom -',
                      onPressed: () {
                        final zoom = _mapController.camera.zoom;
                        _mapController.move(_mapController.camera.center, zoom - 1);
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildFloatingButton(
                      icon: Icons.zoom_out_map,
                      tooltip: 'Tout voir',
                      onPressed: _fitAllMarkers,
                      backgroundColor: const Color(0xFF1a237e),
                      iconColor: Colors.white,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    Color? backgroundColor,
    Color? iconColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(
              icon,
              color: iconColor ?? const Color(0xFF1a237e),
              size: 24,
            ),
          ),
        ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (color ?? const Color(0xFF1a237e)).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color ?? const Color(0xFF1a237e), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1a237e),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
      bgColor = const Color(0xFF1a237e);
    } else {
      bgColor = Colors.grey.shade200;
    }
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: isPrimary || isDanger ? Colors.white : Colors.grey.shade700,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniTextButton({required IconData icon, required String label, required VoidCallback onPressed}) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: const Color(0xFF1a237e), size: 16),
      label: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: const Color(0xFF1a237e),
          fontWeight: FontWeight.w500,
        ),
      ),
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
            Text('CMD ${stop.orderIds.map((id) => '#$id').join(', ')}'),
            const SizedBox(height: 12),
            ...stop.items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(children: [
                const Icon(Icons.check_box_outline_blank, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(child: Text('${item.name} x${item.quantity} (CMD #${item.orderId})')),
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
      // Mark this depot stop as collected
      routeProvider.markCollectionStopCollected(stop.id);
      
      // Check each order served by this depot — if fully collected, move to delivery
      final fullyCollectedOrderIds = <int>[];
      for (final orderId in stop.orderIds) {
        if (routeProvider.isOrderFullyCollected(orderId)) {
          fullyCollectedOrderIds.add(orderId);
        }
      }
      
      for (final orderId in fullyCollectedOrderIds) {
        final success = await orderProvider.markAsCollected(orderId);
        if (success && mounted) {
          // Find the order object
          final order = stop.orders.firstWhere(
            (o) => o.id == orderId,
            orElse: () => Order(id: orderId, clientId: 0),
          ).copyWith(collected: true);
          
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
        }
      }
      
      if (mounted) {
        if (fullyCollectedOrderIds.isNotEmpty) {
          final cmdList = fullyCollectedOrderIds.map((id) => '#$id').join(', ');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(children: [
                const Text('📦'),
                const SizedBox(width: 8),
                Expanded(child: Text('CMD $cmdList entièrement collectée(s) → ajoutée(s) aux livraisons')),
              ]),
              backgroundColor: const Color(0xFF00c853),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          // Partial — depot collected but orders not fully done yet
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(children: [
                const Text('✅'),
                const SizedBox(width: 8),
                Expanded(child: Text('${stop.depotName} collecté!')),
              ]),
              backgroundColor: Colors.orange.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 3),
            ),
          );
        }
        
        // If ALL collection stops done, switch to deliver tab
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
    }
  }

  void _toggleBottomSheet() {
    setState(() {
      _isSheetExpanded = !_isSheetExpanded;
    });
    
    // Animer le bottom sheet vers la position désirée
    if (_isSheetExpanded) {
      _sheetController.animateTo(
        0.4,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _sheetController.animateTo(
        0.12,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
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
                  Text('CMD ${stop.orderIds.map((id) => '#$id').join(', ')}', style: AppStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
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
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: AppStyles.bodyMedium),
                    Text('CMD #${item.orderId}', style: AppStyles.caption.copyWith(color: AppColors.textSecondary)),
                  ],
                )),
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