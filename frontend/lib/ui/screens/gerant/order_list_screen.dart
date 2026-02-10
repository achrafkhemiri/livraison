import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../data/models/models.dart';
import '../../../providers/providers.dart';

class OrderListScreen extends StatefulWidget {
  final int? livreurId;
  
  const OrderListScreen({super.key, this.livreurId});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _statuses = ['all', 'pending', 'processing', 'shipped', 'delivered', 'cancelled'];
  final List<String> _statusLabels = ['Toutes', 'En attente', 'En cours', 'Livraison', 'Livrées', 'Annulées'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statuses.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadOrders();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Order> _filterOrders(List<Order> orders, String status) {
    final livreurId = widget.livreurId ?? (ModalRoute.of(context)?.settings.arguments as int?);
    
    var filtered = orders;
    if (livreurId != null) {
      filtered = orders.where((o) => o.livreurId == livreurId).toList();
    }
    
    if (status == 'all') return filtered;
    return filtered.where((o) => o.status == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text('Commandes', style: AppStyles.headingMedium.copyWith(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: _statusLabels.map((label) => Tab(text: label)).toList(),
        ),
      ),
      body: Consumer<OrderProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(provider.errorMessage!, style: AppStyles.bodyMedium),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadOrders(),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: _statuses.map((status) {
              final filteredOrders = _filterOrders(provider.orders, status);
              
              if (filteredOrders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_outlined, size: 64, color: AppColors.textSecondary.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text('Aucune commande', style: AppStyles.bodyLarge.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => provider.loadOrders(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredOrders.length,
                  itemBuilder: (context, index) {
                    final order = filteredOrders[index];
                    return _buildOrderCard(order, provider);
                  },
                ),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateOrderDialog(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildOrderCard(Order order, OrderProvider provider) {
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    switch (order.status) {
      case 'pending':
        statusColor = AppColors.statusPending;
        statusText = 'En attente';
        statusIcon = Icons.schedule;
        break;
      case 'processing':
        statusColor = AppColors.statusProcessing;
        statusText = 'En cours';
        statusIcon = Icons.sync;
        break;
      case 'shipped':
        statusColor = AppColors.statusShipped;
        statusText = 'En livraison';
        statusIcon = Icons.local_shipping;
        break;
      case 'delivered':
        statusColor = AppColors.statusDelivered;
        statusText = 'Livrée';
        statusIcon = Icons.check_circle;
        break;
      case 'cancelled':
        statusColor = AppColors.statusCancelled;
        statusText = 'Annulée';
        statusIcon = Icons.cancel;
        break;
      case 'done':
        statusColor = AppColors.success;
        statusText = 'Terminée';
        statusIcon = Icons.done_all;
        break;
      default:
        statusColor = AppColors.textSecondary;
        statusText = order.status ?? 'Inconnu';
        statusIcon = Icons.help_outline;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showOrderDetails(order),
        borderRadius: BorderRadius.circular(12),
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
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(statusIcon, color: statusColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Commande #${order.id}',
                            style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            order.dateCommande?.toString().substring(0, 10) ?? '',
                            style: AppStyles.caption.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusText,
                      style: AppStyles.caption.copyWith(color: statusColor, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoChip(Icons.person_outline, 'Client: ${order.clientId ?? "N/A"}'),
                  _buildInfoChip(Icons.delivery_dining, 'Livreur: ${order.livreurId ?? "Non assigné"}'),
                ],
              ),
              if (order.montantTTC != null) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoChip(Icons.attach_money, '${order.montantTTC!.toStringAsFixed(2)} TND'),
                    PopupMenuButton<String>(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Actions', style: AppStyles.caption.copyWith(color: AppColors.primary)),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_drop_down, size: 16, color: AppColors.primary),
                          ],
                        ),
                      ),
                      onSelected: (value) => _handleOrderAction(order, value, provider),
                      itemBuilder: (context) => [
                        if (order.status == 'pending') ...[
                          const PopupMenuItem(value: 'assign', child: Row(
                            children: [Icon(Icons.person_add, size: 20), SizedBox(width: 8), Text('Assigner')],
                          )),
                          const PopupMenuItem(value: 'processing', child: Row(
                            children: [Icon(Icons.play_arrow, size: 20), SizedBox(width: 8), Text('Commencer')],
                          )),
                        ],
                        if (order.status == 'processing')
                          const PopupMenuItem(value: 'shipped', child: Row(
                            children: [Icon(Icons.local_shipping, size: 20), SizedBox(width: 8), Text('Expédier')],
                          )),
                        if (order.status == 'shipped')
                          const PopupMenuItem(value: 'delivered', child: Row(
                            children: [Icon(Icons.check_circle, size: 20), SizedBox(width: 8), Text('Livré')],
                          )),
                        if (order.status != 'cancelled' && order.status != 'delivered')
                          PopupMenuItem(value: 'cancelled', child: Row(
                            children: [Icon(Icons.cancel, size: 20, color: AppColors.error), const SizedBox(width: 8), Text('Annuler', style: TextStyle(color: AppColors.error))],
                          )),
                      ],
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(text, style: AppStyles.caption.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }

  Future<void> _handleOrderAction(Order order, String action, OrderProvider provider) async {
    if (action == 'assign') {
      await _showAssignDialog(order, provider);
    } else {
      final success = await provider.updateOrderStatus(order.id!, action);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Statut mis à jour' : 'Erreur'),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _showAssignDialog(Order order, OrderProvider provider) async {
    final livreurProvider = context.read<LivreurProvider>();
    if (livreurProvider.livreurs.isEmpty) {
      await livreurProvider.loadLivreurs();
    }

    if (!mounted) return;

    int? selectedLivreurId;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Assigner un livreur'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: selectedLivreurId,
                decoration: AppStyles.inputDecoration(label: 'Livreur', prefixIcon: Icons.delivery_dining),
                items: livreurProvider.livreurs.map((l) => DropdownMenuItem(
                  value: l.id,
                  child: Text(l.nom ?? 'Sans nom'),
                )).toList(),
                onChanged: (value) => setState(() => selectedLivreurId = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: selectedLivreurId == null ? null : () async {
                final success = await provider.assignOrderToLivreur(order.id!, selectedLivreurId!);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Livreur assigné' : 'Erreur'),
                      backgroundColor: success ? AppColors.success : AppColors.error,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Assigner', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showOrderDetails(Order order) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
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
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Commande #${order.id}', style: AppStyles.headingMedium),
              const SizedBox(height: 16),
              _buildDetailRow('Statut', order.status ?? 'N/A'),
              _buildDetailRow('Client', order.clientNom ?? 'Client #${order.clientId}'),
              if (order.clientPhone != null)
                _buildDetailRow('Téléphone', order.clientPhone!),
              if (order.clientEmail != null)
                _buildDetailRow('Email', order.clientEmail!),
              _buildDetailRow('Livreur', order.livreurNom ?? (order.livreurId != null ? 'Livreur #${order.livreurId}' : 'Non assigné')),
              _buildDetailRow('Dépôt', order.depotNom ?? (order.depotId != null ? 'Dépôt #${order.depotId}' : 'N/A')),
              _buildDetailRow('Montant Total', '${order.montantTTC?.toStringAsFixed(2) ?? "0.00"} TND'),
              _buildDetailRow('Date création', order.dateCommande?.toString().substring(0, 10) ?? 'N/A'),
              if (order.adresseLivraison != null)
                _buildDetailRow('Adresse', order.adresseLivraison!),
              _buildDetailRow('Notes', order.notes ?? 'Aucune note'),
              if (order.items != null && order.items!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Articles (${order.items!.length})', style: AppStyles.headingSmall),
                const SizedBox(height: 8),
                ...order.items!.map((item) => Card(
                  child: ListTile(
                    title: Text(item.displayName),
                    subtitle: Text('Quantité: ${item.quantite}'),
                    trailing: Text('${item.montantTTC?.toStringAsFixed(2) ?? item.prixUnitaireTTC?.toStringAsFixed(2) ?? "0.00"} TND'),
                  ),
                )),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          Text(value, style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Future<void> _showCreateOrderDialog(BuildContext context) async {
    final clientIdController = TextEditingController();
    final notesController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvelle commande'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: clientIdController,
                decoration: AppStyles.inputDecoration(label: 'ID Client *', prefixIcon: Icons.person),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: AppStyles.inputDecoration(label: 'Notes', prefixIcon: Icons.note),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final clientId = int.tryParse(clientIdController.text);
              if (clientId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ID client invalide'), backgroundColor: AppColors.error),
                );
                return;
              }

              final provider = context.read<OrderProvider>();
              final order = Order(
                clientId: clientId,
                notes: notesController.text.isEmpty ? null : notesController.text,
                status: 'pending',
              );

              final success = await provider.createOrder(order);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Commande créée' : 'Erreur'),
                    backgroundColor: success ? AppColors.success : AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Créer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
