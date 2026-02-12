import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../providers/providers.dart';

class AdminMapScreen extends StatefulWidget {
  const AdminMapScreen({super.key});

  @override
  State<AdminMapScreen> createState() => _AdminMapScreenState();
}

class _AdminMapScreenState extends State<AdminMapScreen> {
  final MapController _mapController = MapController();
  static const LatLng _defaultCenter = LatLng(34.74, 10.76);
  bool _showLegend = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadMapData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text('Carte', style: AppStyles.headingMedium.copyWith(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(_showLegend ? Icons.layers : Icons.layers_outlined, color: Colors.white),
            onPressed: () => setState(() => _showLegend = !_showLegend),
            tooltip: 'Légende',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => context.read<OrderProvider>().loadMapData(),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Consumer<OrderProvider>(
        builder: (context, provider, _) {
          final mapData = provider.mapData;
          final markers = <Marker>[];

          LatLng center = _defaultCenter;

          if (mapData != null) {
            // Société marker (big blue building icon)
            final societe = mapData['societe'];
            if (societe != null && societe['latitude'] != null && societe['longitude'] != null) {
              final pos = LatLng(
                (societe['latitude'] as num).toDouble(),
                (societe['longitude'] as num).toDouble(),
              );
              center = pos;
              markers.add(Marker(
                point: pos,
                width: 50,
                height: 50,
                child: Tooltip(
                  message: '${societe['nom']} (Société)',
                  child: const Icon(Icons.business, color: Colors.blue, size: 40),
                ),
              ));
            }

            // Magasin markers (green store)
            final magasins = mapData['magasins'] as List?;
            if (magasins != null) {
              for (final m in magasins) {
                if (m['latitude'] != null && m['longitude'] != null) {
                  markers.add(Marker(
                    point: LatLng(
                      (m['latitude'] as num).toDouble(),
                      (m['longitude'] as num).toDouble(),
                    ),
                    width: 44,
                    height: 44,
                    child: Tooltip(
                      message: '${m['nom']} (Magasin)',
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.green.shade700,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                        ),
                        child: const Icon(Icons.store, color: Colors.white, size: 24),
                      ),
                    ),
                  ));
                }
              }
            }

            // Depot markers (orange warehouse)
            final depots = mapData['depots'] as List?;
            if (depots != null) {
              for (final d in depots) {
                if (d['latitude'] != null && d['longitude'] != null) {
                  markers.add(Marker(
                    point: LatLng(
                      (d['latitude'] as num).toDouble(),
                      (d['longitude'] as num).toDouble(),
                    ),
                    width: 44,
                    height: 44,
                    child: Tooltip(
                      message: '${d['nom']} (Dépôt)',
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.orange.shade700,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                        ),
                        child: const Icon(Icons.warehouse, color: Colors.white, size: 24),
                      ),
                    ),
                  ));
                }
              }
            }

            // Livreur markers (red delivery icon)
            final livreurs = mapData['livreurs'] as List?;
            if (livreurs != null) {
              for (final l in livreurs) {
                if (l['latitude'] != null && l['longitude'] != null) {
                  markers.add(Marker(
                    point: LatLng(
                      (l['latitude'] as num).toDouble(),
                      (l['longitude'] as num).toDouble(),
                    ),
                    width: 44,
                    height: 44,
                    child: Tooltip(
                      message: '${l['prenom']} ${l['nom']} (Livreur)\n${l['dernierePositionAt'] ?? ''}',
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                        ),
                        child: const Icon(Icons.delivery_dining, color: Colors.white, size: 24),
                      ),
                    ),
                  ));
                }
              }
            }
          }

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: 12,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.smartdelivery',
                  ),
                  MarkerLayer(markers: markers),
                ],
              ),
              // Legend
              if (_showLegend)
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Légende', style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        _legendItem(Icons.business, Colors.blue, 'Société'),
                        _legendItem(Icons.store, Colors.green.shade700, 'Magasins'),
                        _legendItem(Icons.warehouse, Colors.orange.shade700, 'Dépôts'),
                        _legendItem(Icons.delivery_dining, Colors.red.shade600, 'Livreurs'),
                      ],
                    ),
                  ),
                ),
              // Loading
              if (provider.isLoading)
                const Center(child: CircularProgressIndicator()),
              // Stats
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${markers.length} marqueurs',
                    style: AppStyles.caption.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _legendItem(IconData icon, Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(label, style: AppStyles.bodySmall),
        ],
      ),
    );
  }
}
