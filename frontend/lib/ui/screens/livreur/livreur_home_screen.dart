import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../data/models/models.dart';
import '../../../providers/providers.dart';

class LivreurHomeScreen extends StatefulWidget {
  const LivreurHomeScreen({super.key});

  @override
  State<LivreurHomeScreen> createState() => _LivreurHomeScreenState();
}

class _LivreurHomeScreenState extends State<LivreurHomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeData();
  }

  Future<void> _initializeData() async {
    final authProvider = context.read<AuthProvider>();
    final orderProvider = context.read<OrderProvider>();
    final livreurProvider = context.read<LivreurProvider>();
    
    if (authProvider.user != null) {
      livreurProvider.setCurrentLivreur(authProvider.user!);
      
      // Load orders for this livreur
      await Future.wait([
        orderProvider.loadOrdersForLivreur(authProvider.user!.id!),
        orderProvider.loadPendingOrdersForLivreur(authProvider.user!.id!),
      ]);
      
      // Start position tracking
      await livreurProvider.startPositionTracking();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.delivery_dining, color: Colors.white),
            const SizedBox(width: 12),
            Text(
              'Mes Livraisons',
              style: AppStyles.headingMedium.copyWith(color: Colors.white),
            ),
          ],
        ),
        actions: [
          // Position status indicator
          Consumer<LivreurProvider>(
            builder: (context, provider, _) {
              return IconButton(
                icon: Icon(
                  provider.isTrackingPosition ? Icons.gps_fixed : Icons.gps_off,
                  color: provider.isTrackingPosition ? Colors.greenAccent : Colors.white60,
                ),
                onPressed: () async {
                  if (!provider.isTrackingPosition) {
                    await provider.startPositionTracking();
                  }
                },
                tooltip: provider.isTrackingPosition ? 'GPS actif' : 'GPS inactif',
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle_outlined, color: Colors.white),
            onSelected: (value) {
              if (value == 'logout') {
                _handleLogout();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    const Icon(Icons.person_outline, color: AppColors.textSecondary),
                    const SizedBox(width: 12),
                    Text('Mon profil', style: AppStyles.bodyMedium),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    const Icon(Icons.logout, color: AppColors.error),
                    const SizedBox(width: 12),
                    Text('Déconnexion', style: AppStyles.bodyMedium.copyWith(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Mes commandes', icon: Icon(Icons.shopping_bag)),
            Tab(text: 'Disponibles', icon: Icon(Icons.pending_actions)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyOrdersTab(),
          _buildPendingOrdersTab(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: Consumer<OrderProvider>(
        builder: (context, orderProvider, _) {
          final activeOrders = orderProvider.activeOrders;
          if (activeOrders.isEmpty) return const SizedBox.shrink();
          
          return FloatingActionButton.extended(
            onPressed: () => _startDeliveryRoute(activeOrders),
            backgroundColor: AppColors.accent,
            icon: const Icon(Icons.navigation, color: Colors.white),
            label: Text(
              'Démarrer (${activeOrders.length})',
              style: AppStyles.bodyMedium.copyWith(color: Colors.white),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMyOrdersTab() {
    return Consumer<OrderProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.myOrders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: AppColors.textSecondary.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text('Aucune commande assignée', style: AppStyles.bodyLarge.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Text('Vérifiez les commandes disponibles', style: AppStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            final auth = context.read<AuthProvider>();
            if (auth.user?.id != null) {
              await provider.loadOrdersForLivreur(auth.user!.id!);
            }
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.myOrders.length,
            itemBuilder: (context, index) {
              final order = provider.myOrders[index];
              return _buildOrderCard(order, provider, isMine: true);
            },
          ),
        );
      },
    );
  }

  Widget _buildPendingOrdersTab() {
    return Consumer<OrderProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.pendingOrders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 64, color: AppColors.success.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text('Toutes les commandes sont assignées', style: AppStyles.bodyLarge.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            final auth = context.read<AuthProvider>();
            if (auth.user?.id != null) {
              await provider.loadPendingOrdersForLivreur(auth.user!.id!);
            }
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.pendingOrders.length,
            itemBuilder: (context, index) {
              final order = provider.pendingOrders[index];
              return _buildOrderCard(order, provider, isMine: false);
            },
          ),
        );
      },
    );
  }

  Widget _buildOrderCard(Order order, OrderProvider provider, {required bool isMine}) {
    Color statusColor;
    String statusText;
    
    switch (order.status) {
      case 'pending':
        statusColor = AppColors.statusPending;
        statusText = 'En attente';
        break;
      case 'processing':
        statusColor = AppColors.statusProcessing;
        statusText = 'En cours';
        break;
      case 'shipped':
        statusColor = AppColors.statusShipped;
        statusText = 'En livraison';
        break;
      case 'delivered':
        statusColor = AppColors.statusDelivered;
        statusText = 'Livrée';
        break;
      default:
        statusColor = AppColors.textSecondary;
        statusText = order.status ?? 'Inconnu';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.shopping_bag, color: statusColor),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Commande #${order.id}',
                          style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            statusText,
                            style: AppStyles.caption.copyWith(color: statusColor, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (order.montantTTC != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${order.montantTTC!.toStringAsFixed(2)}',
                        style: AppStyles.headingSmall.copyWith(color: AppColors.primary),
                      ),
                      Text('TND', style: AppStyles.caption.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.person_outline, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text('Client #${order.clientId ?? "N/A"}', style: AppStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(order.dateCommande?.toString().substring(0, 10) ?? '', style: AppStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (!isMine) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _acceptOrder(order, provider),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Accepter'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ] else ...[
                  if (order.status == 'processing')
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _updateStatus(order, 'shipped', provider),
                        icon: const Icon(Icons.local_shipping, size: 18),
                        label: const Text('En route'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.statusShipped,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  if (order.status == 'shipped')
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _updateStatus(order, 'delivered', provider),
                        icon: const Icon(Icons.check_circle, size: 18),
                        label: const Text('Livré'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  if (order.status == 'delivered')
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, color: AppColors.success),
                            const SizedBox(width: 8),
                            Text('Livraison terminée', style: AppStyles.bodyMedium.copyWith(color: AppColors.success)),
                          ],
                        ),
                      ),
                    ),
                ],
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _showOrderOnMap(order),
                  icon: const Icon(Icons.map_outlined),
                  color: AppColors.primary,
                  tooltip: 'Voir sur la carte',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _acceptOrder(Order order, OrderProvider provider) async {
    final auth = context.read<AuthProvider>();
    if (auth.user?.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accepter la commande'),
        content: Text('Voulez-vous prendre en charge la commande #${order.id} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Accepter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await provider.acceptOrder(order.id!, auth.user!.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Commande acceptée' : 'Erreur'),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
        if (success) {
          await provider.loadOrdersForLivreur(auth.user!.id!);
          await provider.loadPendingOrdersForLivreur(auth.user!.id!);
        }
      }
    }
  }

  Future<void> _updateStatus(Order order, String status, OrderProvider provider) async {
    final success = await provider.updateOrderStatus(order.id!, status);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Statut mis à jour' : 'Erreur'),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  void _showOrderOnMap(Order order) {
    Navigator.pushNamed(context, '/livreur/map', arguments: {'orderId': order.id});
  }

  void _startDeliveryRoute(List<Order> orders) {
    Navigator.pushNamed(context, '/livreur/map', arguments: {'orders': orders});
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 1) {
            Navigator.pushNamed(context, '/livreur/map');
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Carte'),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Déconnexion', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final livreurProvider = context.read<LivreurProvider>();
      livreurProvider.stopPositionTracking();
      await context.read<AuthProvider>().logout();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }
}
