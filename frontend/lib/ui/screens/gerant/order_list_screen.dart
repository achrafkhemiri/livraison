import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../data/models/models.dart';
import '../../../data/services/services.dart';
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
      case 'assigned':
        statusColor = Colors.amber;
        statusText = 'Proposée au livreur';
        statusIcon = Icons.assignment_ind;
        break;
      case 'en_cours':
        statusColor = AppColors.statusProcessing;
        statusText = 'Acceptée';
        statusIcon = Icons.thumb_up;
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
                        if (order.status == 'assigned') ...[
                          PopupMenuItem(value: 'assign', child: Row(
                            children: [Icon(Icons.swap_horiz, size: 20, color: Colors.amber), const SizedBox(width: 8), Text('Re-assigner', style: TextStyle(color: Colors.amber[800]))],
                          )),
                        ],
                        if (order.status == 'en_cours')
                          const PopupMenuItem(value: 'processing', child: Row(
                            children: [Icon(Icons.play_arrow, size: 20), SizedBox(width: 8), Text('Commencer traitement')],
                          )),
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
    // Show loading while fetching recommendations
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    List<Map<String, dynamic>> recommendations = [];
    try {
      recommendations = await provider.getRecommendedLivreurs(order.id!);
    } catch (_) {}

    if (!mounted) return;
    Navigator.pop(context); // dismiss loading

    // Fallback: if recommendation API fails, fall back to basic livreur list
    if (recommendations.isEmpty) {
      await _showFallbackAssignDialog(order, provider);
      return;
    }

    int? selectedLivreurId;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.recommend, color: AppColors.primary),
              const SizedBox(width: 8),
              const Expanded(child: Text('Assigner un livreur')),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Livreurs triés par proximité (collecte + livraison)',
                  style: AppStyles.caption.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.45,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: recommendations.length,
                    itemBuilder: (context, index) {
                      final rec = recommendations[index];
                      final livreurId = rec['livreurId'] as int?;
                      final nom = rec['livreurNom'] ?? 'Livreur #$livreurId';
                      final distance = (rec['distanceTotaleKm'] as num?)?.toDouble() ?? 0;
                      final score = (rec['score'] as num?)?.toDouble() ?? 0;
                      final activeOrders = rec['commandesActives'] as int? ?? 0;
                      final tempsMinutes = (rec['tempsEstimeMinutes'] as num?)?.toDouble();
                      final isRecommended = rec['recommended'] == true;
                      final telephone = rec['telephone'] ?? '';
                      final isSelected = selectedLivreurId == livreurId;

                      return Card(
                        elevation: isSelected ? 3 : 1,
                        color: isSelected
                            ? AppColors.primary.withOpacity(0.08)
                            : isRecommended
                                ? Colors.green.withOpacity(0.05)
                                : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.primary
                                : isRecommended
                                    ? AppColors.success.withOpacity(0.5)
                                    : Colors.transparent,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => setState(() => selectedLivreurId = livreurId),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                // Rank
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: isRecommended
                                        ? AppColors.success
                                        : AppColors.textSecondary.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        color: isRecommended ? Colors.white : AppColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              nom.toString(),
                                              style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (isRecommended) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.success,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Text(
                                                'Recommandé',
                                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.route, size: 14, color: AppColors.textSecondary),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${distance.toStringAsFixed(1)} km',
                                            style: AppStyles.caption.copyWith(color: AppColors.textSecondary),
                                          ),
                                          if (tempsMinutes != null) ...[
                                            const SizedBox(width: 8),
                                            Icon(Icons.schedule, size: 14, color: AppColors.textSecondary),
                                            const SizedBox(width: 4),
                                            Text(
                                              tempsMinutes < 60
                                                  ? '${tempsMinutes.toStringAsFixed(0)} min'
                                                  : '${(tempsMinutes / 60).toStringAsFixed(1)} h',
                                              style: AppStyles.caption.copyWith(color: AppColors.textSecondary),
                                            ),
                                          ],
                                          const SizedBox(width: 8),
                                          Icon(Icons.assignment, size: 14, color: AppColors.textSecondary),
                                          const SizedBox(width: 4),
                                          Text(
                                            '$activeOrders cmd active${activeOrders > 1 ? 's' : ''}',
                                            style: AppStyles.caption.copyWith(color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                      if (telephone.toString().isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2),
                                          child: Text(
                                            telephone.toString(),
                                            style: AppStyles.caption.copyWith(color: AppColors.textSecondary, fontSize: 11),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                // Score
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Score',
                                      style: AppStyles.caption.copyWith(color: AppColors.textSecondary, fontSize: 10),
                                    ),
                                    Text(
                                      score.toStringAsFixed(1),
                                      style: AppStyles.bodyMedium.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: isRecommended ? AppColors.success : AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton.icon(
              onPressed: selectedLivreurId == null
                  ? null
                  : () async {
                      final success = await provider.assignOrderToLivreur(order.id!, selectedLivreurId!);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success
                                ? 'Commande proposée au livreur. En attente de sa réponse.'
                                : 'Erreur: ${provider.errorMessage}'),
                            backgroundColor: success ? AppColors.success : AppColors.error,
                          ),
                        );
                      }
                    },
              icon: const Icon(Icons.send, size: 18),
              label: const Text('Proposer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Fallback dialog when recommendation API is unavailable
  Future<void> _showFallbackAssignDialog(Order order, OrderProvider provider) async {
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
    final latController = TextEditingController();
    final lngController = TextEditingController();
    final adresseController = TextEditingController();
    final notesController = TextEditingController();
    
    // Clients list
    List<Client> clients = [];
    Client? selectedClient;
    bool loadingClients = true;

    // Products with stock from the API
    List<Map<String, dynamic>> productsStock = [];
    // Selected items: [{produitId, produitNom, prixHT, quantite, depotStocks: [...]}]
    List<Map<String, dynamic>> selectedItems = [];
    bool loadingProducts = true;

    // Collection plan mode: 'auto' or 'manual'
    String planMode = 'auto';
    // Manual depot assignments per product index:
    //   { productIndex: [ { depotId, depotNom, depotLatitude, depotLongitude, quantite } ] }
    Map<int, List<Map<String, dynamic>>> manualAssignments = {};

    // Load clients and products BEFORE showing dialog to avoid display issues
    final orderProvider = context.read<OrderProvider>();
    final clientService = ClientService();
    
    try {
      clients = await clientService.getAll();
    } catch (_) {}
    loadingClients = false;
    
    await orderProvider.loadProductsStock();
    productsStock = orderProvider.productsStock;
    loadingProducts = false;

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {

          double totalHT = 0;
          for (var item in selectedItems) {
            totalHT += (item['prixHT'] ?? 0.0) * (item['quantite'] ?? 1);
          }

          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.shopping_bag, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text('Nouvelle commande'),
              ],
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.6,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Client info
                    Text('Informations client', style: AppStyles.headingSmall),
                    const SizedBox(height: 8),
                    if (loadingClients)
                      const Center(child: CircularProgressIndicator())
                    else
                      DropdownButtonFormField<Client>(
                        value: selectedClient,
                        decoration: AppStyles.inputDecoration(label: 'Client *', prefixIcon: Icons.person),
                        isExpanded: true,
                        items: clients.map((client) {
                          final displayName = client.nom != null && client.nom!.isNotEmpty
                              ? client.nom!
                              : client.email ?? 'Client #${client.id}';
                          return DropdownMenuItem<Client>(
                            value: client,
                            child: Text(
                              '#${client.id} - $displayName',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (client) {
                          setState(() {
                            selectedClient = client;
                            if (client != null) {
                              latController.text = client.latitude?.toString() ?? '';
                              lngController.text = client.longitude?.toString() ?? '';
                              adresseController.text = client.adresse ?? '';
                            }
                          });
                        },
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: latController,
                            decoration: AppStyles.inputDecoration(label: 'Latitude', prefixIcon: Icons.location_on),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: lngController,
                            decoration: AppStyles.inputDecoration(label: 'Longitude', prefixIcon: Icons.location_on),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: adresseController,
                      decoration: AppStyles.inputDecoration(label: 'Adresse de livraison', prefixIcon: Icons.home),
                    ),
                    const SizedBox(height: 16),
                    
                    // Section 2: Products
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Produits', style: AppStyles.headingSmall),
                        if (!loadingProducts)
                          ElevatedButton.icon(
                            onPressed: () {
                              _showProductPicker(context, productsStock, selectedItems, setState);
                            },
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Ajouter'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (loadingProducts)
                      const Center(child: CircularProgressIndicator())
                    else if (selectedItems.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text('Aucun produit ajouté', style: AppStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                        ),
                      )
                    else
                      ...selectedItems.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final item = entry.value;
                        return Card(
                          child: ListTile(
                            dense: true,
                            title: Text(item['produitNom'] ?? 'Produit #${item['produitId']}'),
                            subtitle: Text('Prix: ${(item['prixHT'] ?? 0.0).toStringAsFixed(2)} TND | Stock total: ${item['totalStock']}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                                  onPressed: () {
                                    setState(() {
                                      if ((item['quantite'] as int) > 1) {
                                        item['quantite'] = (item['quantite'] as int) - 1;
                                      }
                                    });
                                  },
                                ),
                                Text('${item['quantite']}', style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline, size: 20),
                                  onPressed: () {
                                    setState(() {
                                      item['quantite'] = (item['quantite'] as int) + 1;
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                                  onPressed: () {
                                    setState(() {
                                      selectedItems.removeAt(idx);
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    
                    if (selectedItems.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Total HT: ${totalHT.toStringAsFixed(2)} TND',
                          style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                    ],
                    
                    // ── Section 3: Plan de collection ─────────────────
                    if (selectedItems.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text('Plan de collection', style: AppStyles.headingSmall),
                      const SizedBox(height: 8),
                      // Toggle auto / manual
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() { planMode = 'auto'; manualAssignments.clear(); }),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: planMode == 'auto' ? AppColors.primary : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.auto_awesome, size: 18,
                                        color: planMode == 'auto' ? Colors.white : AppColors.textSecondary),
                                      const SizedBox(width: 6),
                                      Text('Automatique',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600, fontSize: 13,
                                          color: planMode == 'auto' ? Colors.white : AppColors.textSecondary,
                                        )),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() { planMode = 'manual'; }),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: planMode == 'manual' ? AppColors.primary : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.touch_app, size: 18,
                                        color: planMode == 'manual' ? Colors.white : AppColors.textSecondary),
                                      const SizedBox(width: 6),
                                      Text('Manuel',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600, fontSize: 13,
                                          color: planMode == 'manual' ? Colors.white : AppColors.textSecondary,
                                        )),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (planMode == 'auto')
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 18, color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Le système choisira automatiquement les dépôts optimaux (minimum de dépôts + trajet le plus court).',
                                  style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (planMode == 'manual') ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 18, color: Colors.orange.shade700),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Choisissez le dépôt source pour chaque produit. Le livreur suivra ce plan.',
                                  style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Per-product depot picker
                        ...selectedItems.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final item = entry.value;
                          final depotStocks = (item['depotStocks'] as List?) ?? [];
                          final needed = item['quantite'] as int;
                          final assignments = manualAssignments[idx] ?? [];
                          final assignedTotal = assignments.fold<int>(0, (s, a) => s + ((a['quantite'] as int?) ?? 0));
                          final fulfilled = assignedTotal >= needed;
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: fulfilled ? AppColors.success.withOpacity(0.5) : Colors.orange.shade300,
                                width: 1.5,
                              ),
                            ),
                            child: Theme(
                              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                initiallyExpanded: true,
                                tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                                title: Row(
                                  children: [
                                    Icon(
                                      fulfilled ? Icons.check_circle : Icons.warning_amber_rounded,
                                      size: 20,
                                      color: fulfilled ? AppColors.success : Colors.orange,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        item['produitNom'] ?? 'Produit',
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: fulfilled ? AppColors.success.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '$assignedTotal / $needed',
                                        style: TextStyle(
                                          fontSize: 12, fontWeight: FontWeight.w600,
                                          color: fulfilled ? AppColors.success : Colors.orange.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                                    child: Column(
                                      children: depotStocks.map<Widget>((depot) {
                                        final depotId = depot['depotId'];
                                        final depotNom = depot['depotNom'] ?? 'Dépôt #$depotId';
                                        final available = (depot['quantiteDisponible'] as num?)?.toInt() ?? 0;
                                        // Find this depot's current assignment
                                        final existingIdx = assignments.indexWhere((a) => a['depotId'] == depotId);
                                        final isAssigned = existingIdx >= 0;
                                        final assignedQty = isAssigned ? (assignments[existingIdx]['quantite'] as int) : 0;
                                        
                                        return Container(
                                          margin: const EdgeInsets.only(top: 6),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: isAssigned ? AppColors.primary.withOpacity(0.05) : Colors.grey.shade50,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: isAssigned ? AppColors.primary.withOpacity(0.3) : Colors.grey.shade200,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              // Depot info
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(depotNom,
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.w600, fontSize: 13,
                                                        color: isAssigned ? AppColors.primary : AppColors.textPrimary,
                                                      )),
                                                    Text('Disponible: $available',
                                                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                                  ],
                                                ),
                                              ),
                                              // Quantity controls
                                              if (isAssigned) ...[
                                                IconButton(
                                                  icon: const Icon(Icons.remove_circle_outline, size: 22),
                                                  color: AppColors.primary,
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                                  onPressed: () {
                                                    setState(() {
                                                      if (assignedQty <= 1) {
                                                        assignments.removeAt(existingIdx);
                                                        if (assignments.isEmpty) manualAssignments.remove(idx);
                                                      } else {
                                                        assignments[existingIdx]['quantite'] = assignedQty - 1;
                                                      }
                                                    });
                                                  },
                                                ),
                                                Container(
                                                  width: 32,
                                                  alignment: Alignment.center,
                                                  child: Text('$assignedQty',
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.add_circle_outline, size: 22),
                                                  color: AppColors.primary,
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                                  onPressed: () {
                                                    setState(() {
                                                      if (assignedQty < available) {
                                                        assignments[existingIdx]['quantite'] = assignedQty + 1;
                                                      }
                                                    });
                                                  },
                                                ),
                                                IconButton(
                                                  icon: Icon(Icons.close, size: 18, color: AppColors.error),
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                                  onPressed: () {
                                                    setState(() {
                                                      assignments.removeAt(existingIdx);
                                                      if (assignments.isEmpty) manualAssignments.remove(idx);
                                                    });
                                                  },
                                                ),
                                              ] else
                                                TextButton.icon(
                                                  onPressed: available <= 0 ? null : () {
                                                    setState(() {
                                                      final remaining = needed - assignedTotal;
                                                      final qty = remaining > 0 ? (remaining <= available ? remaining : available) : 1;
                                                      final newAssignment = {
                                                        'depotId': depotId,
                                                        'depotNom': depotNom,
                                                        'depotLatitude': depot['depotLatitude'],
                                                        'depotLongitude': depot['depotLongitude'],
                                                        'quantite': qty > available ? available : qty,
                                                      };
                                                      manualAssignments.putIfAbsent(idx, () => []);
                                                      manualAssignments[idx]!.add(newAssignment);
                                                    });
                                                  },
                                                  icon: Icon(Icons.add, size: 16, color: available <= 0 ? Colors.grey : AppColors.primary),
                                                  label: Text(
                                                    available <= 0 ? 'Rupture' : 'Sélectionner',
                                                    style: TextStyle(fontSize: 12, color: available <= 0 ? Colors.grey : AppColors.primary),
                                                  ),
                                                  style: TextButton.styleFrom(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    minimumSize: Size.zero,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ],
                    
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      decoration: AppStyles.inputDecoration(label: 'Notes', prefixIcon: Icons.note),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (selectedClient == null || selectedClient!.id == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Veuillez sélectionner un client'), backgroundColor: AppColors.error),
                    );
                    return;
                  }

                  // Validate manual assignments if manual mode
                  if (planMode == 'manual' && selectedItems.isNotEmpty) {
                    for (int i = 0; i < selectedItems.length; i++) {
                      final item = selectedItems[i];
                      final needed = item['quantite'] as int;
                      final assignments = manualAssignments[i] ?? [];
                      final assignedTotal = assignments.fold<int>(0, (s, a) => s + ((a['quantite'] as int?) ?? 0));
                      if (assignedTotal < needed) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Quantité insuffisante pour "${item['produitNom']}" ($assignedTotal / $needed)'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }
                    }
                  }

                  final clientId = selectedClient!.id!;
                  final lat = double.tryParse(latController.text);
                  final lng = double.tryParse(lngController.text);

                  final items = selectedItems.map((item) => OrderItem(
                    produitId: item['produitId'] as int,
                    quantite: item['quantite'] as int,
                  )).toList();

                  // Build manual collection plan JSON if manual mode
                  String? collectionPlanJson;
                  if (planMode == 'manual' && manualAssignments.isNotEmpty) {
                    collectionPlanJson = _buildManualCollectionPlan(selectedItems, manualAssignments);
                  }

                  final provider = context.read<OrderProvider>();
                  final order = Order(
                    clientId: clientId,
                    latitudeLivraison: lat,
                    longitudeLivraison: lng,
                    adresseLivraison: adresseController.text.isEmpty ? null : adresseController.text,
                    notes: notesController.text.isEmpty ? null : notesController.text,
                    status: 'pending',
                    items: items.isNotEmpty ? items : null,
                    collectionPlan: collectionPlanJson,
                  );

                  final success = await provider.createOrder(order);
                  if (context.mounted) {
                    Navigator.pop(context);
                    final modeLabel = planMode == 'manual' ? ' (plan manuel)' : '';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? 'Commande créée avec ${items.length} produit(s)$modeLabel' : 'Erreur: ${provider.errorMessage}'),
                        backgroundColor: success ? AppColors.success : AppColors.error,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Créer', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Build collection plan JSON from manual depot assignments.
  /// Format matches backend's mergedSteps: group items by depot.
  String _buildManualCollectionPlan(
    List<Map<String, dynamic>> selectedItems,
    Map<int, List<Map<String, dynamic>>> manualAssignments,
  ) {
    // Group by depotId → list of items
    final Map<int, Map<String, dynamic>> depotSteps = {};

    for (final entry in manualAssignments.entries) {
      final productIdx = entry.key;
      final item = selectedItems[productIdx];
      for (final assignment in entry.value) {
        final depotId = assignment['depotId'] as int;
        depotSteps.putIfAbsent(depotId, () => {
          'depotId': depotId,
          'depotNom': assignment['depotNom'],
          'depotLatitude': assignment['depotLatitude'],
          'depotLongitude': assignment['depotLongitude'],
          'items': <Map<String, dynamic>>[],
          'orderIds': <int>[],
        });
        (depotSteps[depotId]!['items'] as List).add({
          'produitId': item['produitId'],
          'produitNom': item['produitNom'],
          'quantite': assignment['quantite'],
        });
      }
    }

    // Build steps array with step indices (1-based for consistency)
    final steps = depotSteps.values.toList().asMap().entries.map((e) {
      final step = Map<String, dynamic>.from(e.value);
      step['step'] = e.key + 1;
      return step;
    }).toList();

    return jsonEncode(steps);
  }

  void _showProductPicker(
    BuildContext context,
    List<Map<String, dynamic>> productsStock,
    List<Map<String, dynamic>> selectedItems,
    StateSetter parentSetState,
  ) {
    final searchController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final query = searchController.text.toLowerCase();
          final filtered = productsStock.where((p) {
            final nom = (p['produitNom'] ?? '').toString().toLowerCase();
            final ref = (p['produitReference'] ?? '').toString().toLowerCase();
            return nom.contains(query) || ref.contains(query);
          }).toList();

          // Already selected product IDs
          final selectedIds = selectedItems.map((e) => e['produitId']).toSet();

          return AlertDialog(
            title: const Text('Sélectionner un produit'),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.5,
              height: MediaQuery.of(context).size.height * 0.5,
              child: Column(
                children: [
                  TextField(
                    controller: searchController,
                    decoration: AppStyles.inputDecoration(label: 'Rechercher...', prefixIcon: Icons.search),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(child: Text('Aucun produit disponible', style: AppStyles.bodyMedium))
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final product = filtered[index];
                              final pid = product['produitId'];
                              final isSelected = selectedIds.contains(pid);
                              final totalStock = product['totalStock'];
                              
                              return ListTile(
                                leading: Icon(
                                  isSelected ? Icons.check_circle : Icons.inventory_2,
                                  color: isSelected ? AppColors.success : AppColors.primary,
                                ),
                                title: Text(product['produitNom'] ?? 'Produit #$pid'),
                                subtitle: Text('Réf: ${product['produitReference'] ?? 'N/A'} | Prix: ${(product['prixHT'] ?? 0).toStringAsFixed(2)} TND | Stock: $totalStock'),
                                enabled: !isSelected,
                                onTap: isSelected ? null : () {
                                  parentSetState(() {
                                    selectedItems.add({
                                      'produitId': pid,
                                      'produitNom': product['produitNom'],
                                      'prixHT': (product['prixHT'] ?? 0).toDouble(),
                                      'totalStock': totalStock,
                                      'depotStocks': product['depotStocks'] ?? [],
                                      'quantite': 1,
                                    });
                                  });
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
            ],
          );
        },
      ),
    );
  }
}
