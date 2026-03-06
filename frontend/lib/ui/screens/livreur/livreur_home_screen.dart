import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/constants/responsive.dart';
import '../../../data/models/models.dart';
import '../../../data/services/fcm_notification_service.dart';
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

      // Listen for foreground FCM messages to auto-refresh orders
      final fcmService = FcmNotificationService();
      fcmService.onForegroundMessage = (data) {
        if (mounted && authProvider.user != null) {
          orderProvider.loadProposedOrders();
          orderProvider.loadOrdersForLivreur(authProvider.user!.id!);
          orderProvider.loadPendingOrdersForLivreur(authProvider.user!.id!);
          context.read<NotificationProvider>().fetchUnreadCount();
        }
      };
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
    final r = Responsive(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            Icon(Icons.delivery_dining, color: Colors.white, size: r.iconSize(24)),
            SizedBox(width: r.space(12)),
            Text(
              'Mes Livraisons',
              style: AppStyles.headingMediumR(r).copyWith(color: Colors.white),
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
                    icon: Icon(Icons.notifications_outlined, color: Colors.white, size: r.iconSize(24)),
                    onPressed: _openNotifications,
                    tooltip: 'Notifications',
                  ),
                  if (notifProvider.unreadCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: EdgeInsets.all(r.space(4)),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${notifProvider.unreadCount}',
                          style: TextStyle(color: Colors.white, fontSize: r.fontSize(10), fontWeight: FontWeight.bold),
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
                  size: r.iconSize(24),
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
            icon: Icon(Icons.account_circle_outlined, color: Colors.white, size: r.iconSize(24)),
            onSelected: (value) {
              if (value == 'profile') {
                Navigator.pushNamed(context, '/profile');
              } else if (value == 'logout') {
                _handleLogout();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline, color: AppColors.textSecondary, size: r.iconSize(20)),
                    SizedBox(width: r.space(12)),
                    Text('Mon profil', style: AppStyles.bodyMediumR(r)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: AppColors.error, size: r.iconSize(20)),
                    SizedBox(width: r.space(12)),
                    Text('Déconnexion', style: AppStyles.bodyMediumR(r).copyWith(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3.0,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: AppStyles.bodyMediumR(r).copyWith(color: Colors.white),
          unselectedLabelStyle: AppStyles.bodyMediumR(r).copyWith(color: Colors.white70),
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
          _buildCollectTab(r),
          _buildDeliverTab(r),
          _buildProposedOrdersTab(r),
          _buildPendingOrdersTab(r),
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
            icon: Icon(Icons.navigation, color: Colors.white, size: r.iconSize(24)),
            label: Text(
              'Démarrer (${activeOrders.length})',
              style: AppStyles.bodyMediumR(r).copyWith(color: Colors.white),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCollectTab(Responsive r) {
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
                Icon(Icons.check_circle_outline, size: r.iconSize(64), color: AppColors.success.withOpacity(0.5)),
                r.verticalSpace(16),
                Text('Rien à collecter', style: AppStyles.bodyLargeR(r).copyWith(color: AppColors.textSecondary)),
                r.verticalSpace(8),
                Text('Tous les articles ont été collectés', style: AppStyles.bodySmallR(r).copyWith(color: AppColors.textSecondary)),
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
            padding: EdgeInsets.all(r.space(16)),
            itemCount: toCollect.length,
            itemBuilder: (context, index) {
              final order = toCollect[index];
              return _buildCollectionCard(order, provider, r);
            },
          ),
        );
      },
    );
  }

  Widget _buildCollectionCard(Order order, OrderProvider provider, Responsive r) {
    return Card(
      margin: EdgeInsets.only(bottom: r.space(12)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.radius(16))),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(r.space(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: r.scale(50),
                      height: r.scale(50),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(r.radius(12)),
                      ),
                      child: Icon(Icons.inventory_2, color: Colors.orange, size: r.iconSize(24)),
                    ),
                    SizedBox(width: r.space(12)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Commande #${order.id}',
                          style: AppStyles.bodyLargeR(r).copyWith(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: r.space(4)),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: r.space(8), vertical: r.space(2)),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(r.radius(12)),
                          ),
                          child: Text(
                            'À collecter',
                            style: AppStyles.captionR(r).copyWith(color: Colors.orange, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (order.montantTTC != null)
                  Text(
                    '${order.montantTTC!.toStringAsFixed(2)} TND',
                    style: AppStyles.bodyLargeR(r).copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
            r.verticalSpace(12),
            // Show items
            if (order.items != null && order.items!.isNotEmpty) ...[
              ...order.items!.take(3).map((item) => Padding(
                padding: EdgeInsets.only(bottom: r.space(4)),
                child: Row(
                  children: [
                    Icon(Icons.circle, size: r.fontSize(6), color: AppColors.textSecondary),
                    SizedBox(width: r.space(8)),
                    Expanded(child: Text('${item.displayName} x${item.quantite}', style: AppStyles.bodySmallR(r))),
                  ],
                ),
              )),
              if (order.items!.length > 3)
                Text('... et ${order.items!.length - 3} autre(s)', style: AppStyles.captionR(r).copyWith(color: AppColors.textSecondary)),
            ],
            r.verticalSpace(12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showCollectionPlan(order, provider),
                    icon: Icon(Icons.route, size: r.iconSize(18)),
                    label: Text('Plan de collecte', style: TextStyle(fontSize: r.fontSize(13))),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.radius(10))),
                    ),
                  ),
                ),
                SizedBox(width: r.space(8)),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _markOrderCollected(order, provider),
                    icon: Icon(Icons.check, size: r.iconSize(18)),
                    label: Text('Collecté', style: TextStyle(fontSize: r.fontSize(13))),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.radius(10))),
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

  Widget _buildDeliverTab(Responsive r) {
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
                Icon(Icons.inbox_outlined, size: r.iconSize(64), color: AppColors.textSecondary.withOpacity(0.5)),
                r.verticalSpace(16),
                Text('Rien à livrer', style: AppStyles.bodyLargeR(r).copyWith(color: AppColors.textSecondary)),
                r.verticalSpace(8),
                Text('Collectez d\'abord les articles des dépôts', style: AppStyles.bodySmallR(r).copyWith(color: AppColors.textSecondary)),
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
            padding: EdgeInsets.all(r.space(16)),
            itemCount: toDeliver.length,
            itemBuilder: (context, index) {
              final order = toDeliver[index];
              return _buildOrderCard(order, provider, isMine: true, r: r);
            },
          ),
        );
      },
    );
  }

  Widget _buildProposedOrdersTab(Responsive r) {
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
                Icon(Icons.inbox_outlined, size: r.iconSize(64), color: AppColors.textSecondary.withOpacity(0.5)),
                r.verticalSpace(16),
                Text('Aucune commande proposée',
                    style: AppStyles.bodyLargeR(r).copyWith(color: AppColors.textSecondary)),
                r.verticalSpace(8),
                Text('Les commandes assignées par l\'admin apparaîtront ici',
                    style: AppStyles.bodySmallR(r).copyWith(color: AppColors.textSecondary)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await provider.loadProposedOrders();
          },
          child: ListView.builder(
            padding: EdgeInsets.all(r.space(16)),
            itemCount: provider.proposedOrders.length,
            itemBuilder: (context, index) {
              final order = provider.proposedOrders[index];
              return _buildProposedOrderCard(order, provider, r);
            },
          ),
        );
      },
    );
  }

  Widget _buildProposedOrderCard(Order order, OrderProvider provider, Responsive r) {
    return Card(
      margin: EdgeInsets.only(bottom: r.space(12)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.radius(16))),
      elevation: 3,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(r.radius(16)),
          border: Border.all(color: Colors.amber.withOpacity(0.5), width: 1.5),
        ),
        child: Padding(
          padding: EdgeInsets.all(r.space(16)),
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
                        width: r.scale(50),
                        height: r.scale(50),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(r.radius(12)),
                        ),
                        child: Icon(Icons.assignment_ind, color: Colors.amber, size: r.iconSize(24)),
                      ),
                      SizedBox(width: r.space(12)),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Commande #${order.id}',
                            style: AppStyles.bodyLargeR(r).copyWith(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: r.space(4)),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: r.space(8), vertical: r.space(2)),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(r.radius(12)),
                            ),
                            child: Text(
                              'En attente de votre réponse',
                              style: AppStyles.captionR(r).copyWith(color: Colors.amber[800], fontWeight: FontWeight.w600),
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
                          style: AppStyles.headingSmallR(r).copyWith(color: AppColors.primary),
                        ),
                        Text('TND', style: AppStyles.captionR(r).copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                ],
              ),
              r.verticalSpace(12),
              // Client & date info
              Row(
                children: [
                  Icon(Icons.person_outline, size: r.iconSize(16), color: AppColors.textSecondary),
                  SizedBox(width: r.space(4)),
                  Text(order.clientNom ?? 'Client #${order.clientId ?? "N/A"}',
                      style: AppStyles.bodySmallR(r).copyWith(color: AppColors.textSecondary)),
                  SizedBox(width: r.space(16)),
                  Icon(Icons.access_time, size: r.iconSize(16), color: AppColors.textSecondary),
                  SizedBox(width: r.space(4)),
                  Text(order.dateCommande?.toString().substring(0, 10) ?? '',
                      style: AppStyles.bodySmallR(r).copyWith(color: AppColors.textSecondary)),
                ],
              ),
              if (order.adresseLivraison != null) ...[
                r.verticalSpace(8),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: r.iconSize(16), color: AppColors.textSecondary),
                    SizedBox(width: r.space(4)),
                    Expanded(
                      child: Text(order.adresseLivraison!,
                          style: AppStyles.bodySmallR(r).copyWith(color: AppColors.textSecondary),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ],
              // Items summary
              if (order.items != null && order.items!.isNotEmpty) ...[
                r.verticalSpace(8),
                Text('${order.items!.length} article(s)',
                    style: AppStyles.bodySmallR(r).copyWith(color: AppColors.textSecondary)),
              ],
              r.verticalSpace(16),
              // Accept / Reject buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectOrder(order, provider),
                      icon: Icon(Icons.close, size: r.iconSize(18)),
                      label: Text('Refuser', style: TextStyle(fontSize: r.fontSize(13))),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.radius(10))),
                        padding: EdgeInsets.symmetric(vertical: r.space(12)),
                      ),
                    ),
                  ),
                  SizedBox(width: r.space(12)),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => _acceptOrder(order, provider),
                      icon: Icon(Icons.check, size: r.iconSize(18)),
                      label: Text('Accepter', style: TextStyle(fontSize: r.fontSize(13))),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.radius(10))),
                        padding: EdgeInsets.symmetric(vertical: r.space(12)),
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

  Widget _buildPendingOrdersTab(Responsive r) {
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
                Icon(Icons.check_circle_outline, size: r.iconSize(64), color: AppColors.success.withOpacity(0.5)),
                r.verticalSpace(16),
                Text('Toutes les commandes sont assignées', style: AppStyles.bodyLargeR(r).copyWith(color: AppColors.textSecondary)),
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
            padding: EdgeInsets.all(r.space(16)),
            itemCount: provider.pendingOrders.length,
            itemBuilder: (context, index) {
              final order = provider.pendingOrders[index];
              return _buildOrderCard(order, provider, isMine: false, r: r);
            },
          ),
        );
      },
    );
  }

  Widget _buildOrderCard(Order order, OrderProvider provider, {required bool isMine, required Responsive r}) {
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
      margin: EdgeInsets.only(bottom: r.space(12)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.radius(16))),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(r.space(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: r.scale(50),
                      height: r.scale(50),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(r.radius(12)),
                      ),
                      child: Icon(Icons.shopping_bag, color: statusColor, size: r.iconSize(24)),
                    ),
                    SizedBox(width: r.space(12)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Commande #${order.id}',
                          style: AppStyles.bodyLargeR(r).copyWith(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: r.space(4)),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: r.space(8), vertical: r.space(2)),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(r.radius(12)),
                          ),
                          child: Text(
                            statusText,
                            style: AppStyles.captionR(r).copyWith(color: statusColor, fontWeight: FontWeight.w600),
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
                        style: AppStyles.headingSmallR(r).copyWith(color: AppColors.primary),
                      ),
                      Text('TND', style: AppStyles.captionR(r).copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
              ],
            ),
            r.verticalSpace(16),
            Row(
              children: [
                Icon(Icons.person_outline, size: r.iconSize(16), color: AppColors.textSecondary),
                SizedBox(width: r.space(4)),
                Text('Client #${order.clientId ?? "N/A"}', style: AppStyles.bodySmallR(r).copyWith(color: AppColors.textSecondary)),
                SizedBox(width: r.space(16)),
                Icon(Icons.access_time, size: r.iconSize(16), color: AppColors.textSecondary),
                SizedBox(width: r.space(4)),
                Text(order.dateCommande?.toString().substring(0, 10) ?? '', style: AppStyles.bodySmallR(r).copyWith(color: AppColors.textSecondary)),
              ],
            ),
            r.verticalSpace(16),
            Row(
              children: [
                if (!isMine) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _acceptOrder(order, provider),
                      icon: Icon(Icons.check, size: r.iconSize(18)),
                      label: Text('Accepter', style: TextStyle(fontSize: r.fontSize(13))),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.radius(10))),
                      ),
                    ),
                  ),
                ] else ...[
                  if (order.status == 'processing')
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _updateStatus(order, 'shipped', provider),
                        icon: Icon(Icons.local_shipping, size: r.iconSize(18)),
                        label: Text('En route', style: TextStyle(fontSize: r.fontSize(13))),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.statusShipped,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.radius(10))),
                        ),
                      ),
                    ),
                  if (order.status == 'shipped')
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _updateStatus(order, 'delivered', provider),
                        icon: Icon(Icons.check_circle, size: r.iconSize(18)),
                        label: Text('Livré', style: TextStyle(fontSize: r.fontSize(13))),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.radius(10))),
                        ),
                      ),
                    ),
                  if (order.status == 'delivered')
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: r.space(12)),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(r.radius(10)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, color: AppColors.success, size: r.iconSize(20)),
                            SizedBox(width: r.space(8)),
                            Text('Livraison terminée', style: AppStyles.bodyMediumR(r).copyWith(color: AppColors.success)),
                          ],
                        ),
                      ),
                    ),
                ],
                SizedBox(width: r.space(8)),
                IconButton(
                  onPressed: () => _showOrderOnMap(order),
                  icon: Icon(Icons.map_outlined, size: r.iconSize(24)),
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
