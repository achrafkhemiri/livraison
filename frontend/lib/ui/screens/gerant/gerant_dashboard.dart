import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/constants/responsive.dart';
import '../../../providers/providers.dart';

class GerantDashboard extends StatefulWidget {
  const GerantDashboard({super.key});

  @override
  State<GerantDashboard> createState() => _GerantDashboardState();
}

class _GerantDashboardState extends State<GerantDashboard> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final societeProvider = context.read<SocieteProvider>();
    final orderProvider = context.read<OrderProvider>();
    final livreurProvider = context.read<LivreurProvider>();
    final notifProvider = context.read<NotificationProvider>();

    await Future.wait([
      societeProvider.loadSocietes(),
      orderProvider.loadOrders(),
      livreurProvider.loadLivreurs(),
    ]);

    // Start notification polling for admin
    notifProvider.startPolling(seconds: 15);
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            return Row(
              children: [
                Icon(Icons.local_shipping_rounded, color: Colors.white, size: r.iconSize(24)),
                SizedBox(width: r.space(12)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Smart Delivery',
                      style: AppStyles.headingMediumR(r).copyWith(color: Colors.white, fontSize: r.fontSize(18)),
                    ),
                    if (auth.user?.societeNom != null)
                      Text(
                        auth.user!.societeNom!,
                        style: AppStyles.bodySmallR(r).copyWith(color: Colors.white70, fontSize: r.fontSize(12)),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notifProvider, _) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                    onPressed: () => _openNotifications(),
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
                    Text('Profil', style: AppStyles.bodyMedium),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    const Icon(Icons.settings_outlined, color: AppColors.textSecondary),
                    const SizedBox(width: 12),
                    Text('Paramètres', style: AppStyles.bodyMedium),
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
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: r.paddingAll(16),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: r.maxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome section
                  _buildWelcomeSection(r),
                  r.verticalSpace(24),
                  
                  // Statistics cards
                  _buildStatisticsSection(r),
                  r.verticalSpace(24),
                  
                  // Quick actions
                  _buildQuickActionsSection(r),
                  r.verticalSpace(24),
                  
                  // Recent orders
                  _buildRecentOrdersSection(),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(r),
    );
  }

  Widget _buildWelcomeSection(Responsive r) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return Container(
          padding: r.paddingAll(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(r.radius(16)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: r.scale(10),
                offset: Offset(0, r.scale(4)),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bonjour, ${auth.user?.nom ?? 'Gérant'}',
                      style: AppStyles.headingMediumR(r).copyWith(color: Colors.white),
                    ),
                    r.verticalSpace(8),
                    Text(
                      'Gérez vos livraisons et optimisez vos trajets',
                      style: AppStyles.bodyMediumR(r).copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Container(
                width: r.avatarSize(60),
                height: r.avatarSize(60),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.dashboard_rounded,
                  color: Colors.white,
                  size: r.iconSize(30),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatisticsSection(Responsive r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Statistiques', style: AppStyles.headingSmallR(r)),
        r.verticalSpace(16),
        Consumer3<OrderProvider, SocieteProvider, LivreurProvider>(
          builder: (context, orders, societes, livreurs, _) {
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: r.gridColumns(phoneCols: 2, tabletCols: 4, desktopCols: 4),
              mainAxisSpacing: r.space(12),
              crossAxisSpacing: r.space(12),
              childAspectRatio: r.cardAspectRatio,
              children: [
                _buildStatCard(
                  'Commandes',
                  orders.totalOrders.toString(),
                  Icons.shopping_bag_outlined,
                  AppColors.primary,
                ),
                _buildStatCard(
                  'En attente',
                  orders.pendingCount.toString(),
                  Icons.pending_outlined,
                  AppColors.statusPending,
                ),
                _buildStatCard(
                  'Livrées',
                  orders.deliveredCount.toString(),
                  Icons.check_circle_outlined,
                  AppColors.statusDelivered,
                ),
                _buildStatCard(
                  'Livreurs',
                  livreurs.livreurs.length.toString(),
                  Icons.delivery_dining,
                  AppColors.accent,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    final r = Responsive(context);
    return Container(
      padding: r.paddingAll(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(r.radius(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: r.scale(10),
            offset: Offset(0, r.scale(2)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
            Container(
              padding: r.paddingAll(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(r.radius(8)),
              ),
              child: Icon(icon, color: color, size: r.iconSize(20)),
            ),
            r.verticalSpace(10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: AppStyles.headingMediumR(r).copyWith(color: color),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    title,
                    style: AppStyles.bodySmallR(r).copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildQuickActionsSection(Responsive r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Actions rapides', style: AppStyles.headingSmallR(r)),
        r.verticalSpace(16),
        Wrap(
          spacing: r.space(12),
          runSpacing: r.space(12),
          children: [
            _buildActionButton(
              'Sociétés',
              Icons.business,
              () => Navigator.pushNamed(context, '/gerant/societes'),
              r,
            ),
            _buildActionButton(
              'Magasins',
              Icons.store,
              () => Navigator.pushNamed(context, '/gerant/magasins'),
              r,
            ),
            _buildActionButton(
              'Dépôts',
              Icons.warehouse,
              () => Navigator.pushNamed(context, '/gerant/depots'),
              r,
            ),
            _buildActionButton(
              'Livreurs',
              Icons.delivery_dining,
              () => Navigator.pushNamed(context, '/gerant/livreurs'),
              r,
            ),
            _buildActionButton(
              'Commandes',
              Icons.shopping_bag,
              () => Navigator.pushNamed(context, '/gerant/orders'),
              r,
            ),
            _buildActionButton(
              'Carte',
              Icons.map,
              () => Navigator.pushNamed(context, '/gerant/map'),
              r,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap, Responsive r) {
    final size = r.scale(100).clamp(80.0, 140.0);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(r.radius(12)),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(r.radius(12)),
        child: Container(
          width: size,
          height: size,
          padding: r.paddingSymmetric(vertical: 12, horizontal: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.primary, size: r.iconSize(28)),
              r.verticalSpace(8),
              Text(
                label,
                style: AppStyles.bodySmallR(r).copyWith(fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentOrdersSection() {
    final r = Responsive(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Commandes récentes', style: AppStyles.headingSmallR(r)),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/gerant/orders'),
              child: Text('Voir tout', style: AppStyles.bodySmallR(r).copyWith(color: AppColors.primary)),
            ),
          ],
        ),
        r.verticalSpace(12),
        Consumer<OrderProvider>(
          builder: (context, orderProvider, _) {
            if (orderProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final recentOrders = orderProvider.orders.take(5).toList();
            if (recentOrders.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.inbox_outlined, size: 48, color: AppColors.textSecondary.withOpacity(0.5)),
                      const SizedBox(height: 12),
                      Text(
                        'Aucune commande récente',
                        style: AppStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentOrders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final order = recentOrders[index];
                return _buildOrderCard(order);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildOrderCard(order) {
    final r = Responsive(context);
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
      case 'cancelled':
        statusColor = AppColors.statusCancelled;
        statusText = 'Annulée';
        break;
      default:
        statusColor = AppColors.textSecondary;
        statusText = order.status ?? 'Inconnu';
    }

    return Container(
      padding: r.paddingAll(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(r.radius(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: r.scale(5),
            offset: Offset(0, r.scale(2)),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: r.scale(48),
            height: r.scale(48),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(r.radius(12)),
            ),
            child: Icon(Icons.shopping_bag_outlined, color: statusColor, size: r.iconSize(24)),
          ),
          SizedBox(width: r.space(16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Commande #${order.id}',
                  style: AppStyles.bodyMediumR(r).copyWith(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: r.space(4)),
                Text(
                  'Client ID: ${order.clientId ?? 'N/A'}',
                  style: AppStyles.bodySmallR(r).copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: r.paddingSymmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(r.radius(20)),
            ),
            child: Text(
              statusText,
              style: AppStyles.captionR(r).copyWith(color: statusColor, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(Responsive r) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: r.scale(10),
            offset: Offset(0, r.scale(-2)),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          switch (index) {
            case 0:
              // Already on dashboard
              break;
            case 1:
              Navigator.pushNamed(context, '/gerant/orders');
              break;
            case 2:
              Navigator.pushNamed(context, '/gerant/livreurs');
              break;
            case 3:
              Navigator.pushNamed(context, '/gerant/map');
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        selectedFontSize: r.fontSize(12),
        unselectedFontSize: r.fontSize(12),
        iconSize: r.iconSize(24),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Commandes'),
          BottomNavigationBarItem(icon: Icon(Icons.delivery_dining), label: 'Livreurs'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Carte'),
        ],
      ),
    );
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
                                            : notif.type == 'ORDER_ASSIGNED'
                                                ? Icons.person_add
                                                : Icons.notifications,
                                color: notif.isRead
                                    ? AppColors.textSecondary
                                    : notif.type == 'ORDER_ACCEPTED'
                                        ? AppColors.success
                                        : notif.type == 'ORDER_REJECTED'
                                            ? AppColors.error
                                            : AppColors.primary,
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
                                // If it's about an order, reload orders to show latest status
                                if (notif.orderId != null) {
                                  context.read<OrderProvider>().loadOrders();
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
      await context.read<AuthProvider>().logout();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }
}
