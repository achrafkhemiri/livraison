import 'dart:convert';

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
    _tabController = TabController(length: 4, vsync: this);
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
        orderProvider.loadProposedOrders(),
      ]);
      
      // Start position tracking
      await livreurProvider.startPositionTracking();

      // Start notification polling
      if (mounted) {
        context.read<NotificationProvider>().startPolling(seconds: 15);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openNotifications() {
    final notifProvider = context.read<NotificationProvider>();
    notifProvider.loadAll();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (ctx, scrollController) => Consumer<NotificationProvider>(
          builder: (ctx, provider, _) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Notifications', style: AppStyles.headingSmall),
                      if (provider.unreadCount > 0)
                        TextButton(
                          onPressed: () => provider.markAllAsRead(),
                          child: const Text('Tout marquer lu'),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: provider.notifications.isEmpty
                      ? Center(
                          child: Text('Aucune notification',
                              style: AppStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: provider.notifications.length,
                          itemBuilder: (ctx, i) {
                            final notif = provider.notifications[i];
                            return ListTile(
                              leading: Icon(
                                notif.type == 'ORDER_PROPOSED'
                                    ? Icons.assignment_ind
                                    : notif.type == 'ORDER_ACCEPTED'
                                        ? Icons.check_circle
                                        : notif.type == 'ORDER_REJECTED'
                                            ? Icons.cancel
                                            : Icons.notifications,
                                color: notif.isRead ? AppColors.textSecondary : AppColors.primary,
                              ),
                              title: Text(
                                notif.typeLabel,
                                style: AppStyles.bodyMedium.copyWith(
                                  fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(notif.message ?? '', style: AppStyles.caption),
                              trailing: notif.isRead
                                  ? null
                                  : Container(
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                              onTap: () {
                                if (!notif.isRead && notif.id != null) {
                                  provider.markAsRead(notif.id!);
                                }
                              },
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
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
          // Notification bell
          Consumer<NotificationProvider>(
            builder: (context, notifProvider, _) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                    onPressed: _openNotifications,
                    tooltip: 'Notifications',
                  ),
                  if (notifProvider.unreadCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${notifProvider.unreadCount}',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
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
          tabs: [
            const Tab(text: 'À collecter', icon: Icon(Icons.inventory_2)),
            const Tab(text: 'À livrer', icon: Icon(Icons.local_shipping)),
            Tab(
              icon: Consumer<OrderProvider>(
                builder: (context, p, _) {
                  final count = p.proposedOrders.length;
                  return Badge(
                    isLabelVisible: count > 0,
                    label: Text('$count'),
                    child: const Icon(Icons.assignment_ind),
                  );
                },
              ),
              text: 'Proposées',
            ),
            const Tab(text: 'Disponibles', icon: Icon(Icons.pending_actions)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCollectTab(),
          _buildDeliverTab(),
          _buildProposedOrdersTab(),
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

  Widget _buildCollectTab() {
    return Consumer<OrderProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final toCollect = provider.ordersToCollect;

        if (toCollect.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 64, color: AppColors.success.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text('Rien à collecter', style: AppStyles.bodyLarge.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Text('Tous les articles ont été collectés', style: AppStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
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
            itemCount: toCollect.length,
            itemBuilder: (context, index) {
              final order = toCollect[index];
              return _buildCollectionCard(order, provider);
            },
          ),
        );
      },
    );
  }

  Widget _buildCollectionCard(Order order, OrderProvider provider) {
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
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.inventory_2, color: Colors.orange),
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
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'À collecter',
                            style: AppStyles.caption.copyWith(color: Colors.orange, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (order.montantTTC != null)
                  Text(
                    '${order.montantTTC!.toStringAsFixed(2)} TND',
                    style: AppStyles.bodyLarge.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Show items
            if (order.items != null && order.items!.isNotEmpty) ...[
              ...order.items!.take(3).map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 6, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(child: Text('${item.displayName} x${item.quantite}', style: AppStyles.bodySmall)),
                  ],
                ),
              )),
              if (order.items!.length > 3)
                Text('... et ${order.items!.length - 3} autre(s)', style: AppStyles.caption.copyWith(color: AppColors.textSecondary)),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showCollectionPlan(order, provider),
                    icon: const Icon(Icons.route, size: 18),
                    label: const Text('Plan de collecte'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _markOrderCollected(order, provider),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Collecté'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliverTab() {
    return Consumer<OrderProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final toDeliver = provider.ordersToDeliver;

        if (toDeliver.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: AppColors.textSecondary.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text('Rien à livrer', style: AppStyles.bodyLarge.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Text('Collectez d\'abord les articles des dépôts', style: AppStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
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
            itemCount: toDeliver.length,
            itemBuilder: (context, index) {
              final order = toDeliver[index];
              return _buildOrderCard(order, provider, isMine: true);
            },
          ),
        );
      },
    );
  }

  Widget _buildProposedOrdersTab() {
    return Consumer<OrderProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.proposedOrders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: AppColors.textSecondary.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text('Aucune commande proposée',
                    style: AppStyles.bodyLarge.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Text('Les commandes assignées par l\'admin apparaîtront ici',
                    style: AppStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await provider.loadProposedOrders();
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.proposedOrders.length,
            itemBuilder: (context, index) {
              final order = provider.proposedOrders[index];
              return _buildProposedOrderCard(order, provider);
            },
          ),
        );
      },
    );
  }

  Widget _buildProposedOrderCard(Order order, OrderProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber.withOpacity(0.5), width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.assignment_ind, color: Colors.amber),
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
                              color: Colors.amber.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'En attente de votre réponse',
                              style: AppStyles.caption.copyWith(color: Colors.amber[800], fontWeight: FontWeight.w600),
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
              const SizedBox(height: 12),
              // Client & date info
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(order.clientNom ?? 'Client #${order.clientId ?? "N/A"}',
                      style: AppStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(width: 16),
                  const Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(order.dateCommande?.toString().substring(0, 10) ?? '',
                      style: AppStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                ],
              ),
              if (order.adresseLivraison != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(order.adresseLivraison!,
                          style: AppStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ],
              // Items summary
              if (order.items != null && order.items!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('${order.items!.length} article(s)',
                    style: AppStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
              ],
              const SizedBox(height: 16),
              // Accept / Reject buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectOrder(order, provider),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Refuser'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => _acceptOrder(order, provider),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Accepter'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
      case 'assigned':
        statusColor = Colors.amber;
        statusText = 'Proposée';
        break;
      case 'en_cours':
        statusColor = AppColors.statusProcessing;
        statusText = 'Acceptée';
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

  Future<void> _showCollectionPlan(Order order, OrderProvider provider) async {
    List<dynamic> steps = [];
    int totalDepots = 0;
    bool isManual = false;

    // 1) Try to use the existing local collection plan (manual or previously generated)
    if (order.collectionPlan != null && order.collectionPlan!.isNotEmpty) {
      try {
        steps = jsonDecode(order.collectionPlan!) as List;
        totalDepots = steps.length;
        isManual = true;
        debugPrint('Using local collectionPlan for order #${order.id}: $totalDepots depot(s)');
      } catch (e) {
        debugPrint('Error parsing local collectionPlan: $e');
      }
    }

    // 2) Fallback to backend API only if no local plan
    if (steps.isEmpty) {
      final plan = await provider.generateCollectionPlan(order.id!);
      if (!mounted) return;

      if (plan == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${provider.errorMessage}'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      steps = plan['collectionSteps'] as List? ?? [];
      totalDepots = plan['totalDepots'] ?? 0;
    }

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.route, color: AppColors.primary, size: 28),
                  const SizedBox(width: 12),
                  Text('Plan de collecte', style: AppStyles.headingMedium),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text('Commande #${order.id} - $totalDepots dépôt(s) à visiter', style: AppStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                  ),
                  if (isManual)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Manuel', style: TextStyle(fontSize: 11, color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (steps.isEmpty)
                Center(child: Text('Aucun article à collecter', style: AppStyles.bodyMedium))
              else
                ...steps.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final step = entry.value;
                  final stepNum = idx + 1; // Always 1-based display
                  final depotNom = step['depotNom'] ?? 'Dépôt';
                  final items = step['items'] as List? ?? [];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text('$stepNum', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(depotNom, style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                                  if (step['depotLatitude'] != null)
                                    Text(
                                      '${step['depotLatitude']}, ${step['depotLongitude']}',
                                      style: AppStyles.caption.copyWith(color: AppColors.textSecondary),
                                    ),
                                ],
                              ),
                            ),
                            const Icon(Icons.warehouse, color: Colors.orange),
                          ],
                        ),
                        const Divider(),
                        ...items.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(item['produitNom'] ?? 'Produit', style: AppStyles.bodySmall),
                              Text('x${item['quantite']}', style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _markOrderCollected(Order order, OrderProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la collecte'),
        content: Text('Avez-vous collecté tous les articles de la commande #${order.id} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Non'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Oui, tout collecté', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await provider.markAsCollected(order.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Commande marquée comme collectée' : 'Erreur'),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    }
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
            content: Text(success ? 'Commande acceptée ! Elle apparaît dans vos livraisons.' : 'Erreur: ${provider.errorMessage}'),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
        if (success) {
          await provider.loadOrdersForLivreur(auth.user!.id!);
          await provider.loadProposedOrders();
        }
      }
    }
  }

  Future<void> _rejectOrder(Order order, OrderProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Refuser la commande'),
        content: Text('Êtes-vous sûr de vouloir refuser la commande #${order.id} ?\n\nL\'admin sera notifié et pourra proposer un autre livreur.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Refuser', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await provider.rejectOrder(order.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Commande refusée' : 'Erreur: ${provider.errorMessage}'),
            backgroundColor: success ? Colors.orange : AppColors.error,
          ),
        );
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
