import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../data/models/models.dart';
import '../../../providers/providers.dart';

class DepotListScreen extends StatefulWidget {
  final int? magasinId;
  
  const DepotListScreen({super.key, this.magasinId});

  @override
  State<DepotListScreen> createState() => _DepotListScreenState();
}

class _DepotListScreenState extends State<DepotListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<DepotProvider>();
      if (widget.magasinId != null) {
        provider.loadDepotsByMagasin(widget.magasinId!);
      } else {
        provider.loadDepotsWithStocks();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final magasinId = widget.magasinId ?? (ModalRoute.of(context)?.settings.arguments as int?);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text('Dépôts', style: AppStyles.headingMedium.copyWith(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<DepotProvider>(
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
                    onPressed: () {
                      if (magasinId != null) {
                        provider.loadDepotsByMagasin(magasinId);
                      } else {
                        provider.loadDepotsWithStocks();
                      }
                    },
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          if (provider.depots.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warehouse_outlined, size: 64, color: AppColors.textSecondary.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text('Aucun dépôt', style: AppStyles.bodyLarge.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Text('Ajoutez votre premier dépôt', style: AppStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              if (magasinId != null) {
                await provider.loadDepotsByMagasin(magasinId);
              } else {
                await provider.loadDepotsWithStocks();
              }
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.depots.length,
              itemBuilder: (context, index) {
                final depot = provider.depots[index];
                return _buildDepotCard(depot, provider);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(context, magasinId: magasinId),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildDepotCard(Depot depot, DepotProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.warehouse, color: Colors.orange),
        ),
        title: Text(
          depot.nom ?? 'Sans nom',
          style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (depot.adresse != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      depot.adresse!,
                      style: AppStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (depot.magasinNom != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.store_outlined, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    depot.magasinNom!,
                    style: AppStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
            if (depot.latitude != null && depot.longitude != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.gps_fixed, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${depot.latitude!.toStringAsFixed(4)}, ${depot.longitude!.toStringAsFixed(4)}',
                    style: AppStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],            // Display stock details
            if (depot.stocks != null && depot.stocks!.isNotEmpty) ...[              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Text(
                'Stocks (${depot.stocks!.length} produits)',
                style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              ...depot.stocks!.take(3).map((stock) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(
                      stock.isOutOfStock ? Icons.warning : Icons.inventory_2_outlined,
                      size: 12,
                      color: stock.isOutOfStock ? AppColors.error : (stock.isLowStock ? Colors.orange : AppColors.success),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        stock.produitNom,
                        style: AppStyles.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${stock.quantiteDisponible.toStringAsFixed(0)} unités',
                      style: AppStyles.bodySmall.copyWith(
                        color: stock.isOutOfStock ? AppColors.error : (stock.isLowStock ? Colors.orange : AppColors.textSecondary),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )),
              if (depot.stocks!.length > 3)
                InkWell(
                  onTap: () => _showAllStocksDialog(context, depot),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '+ ${depot.stocks!.length - 3} autres produits',
                      style: AppStyles.bodySmall.copyWith(color: AppColors.primary, decoration: TextDecoration.underline),
                    ),
                  ),
                ),
            ],          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _showAddEditDialog(context, depot: depot);
            } else if (value == 'delete') {
              _confirmDelete(context, depot, provider);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Row(
              children: [Icon(Icons.edit_outlined, size: 20), SizedBox(width: 8), Text('Modifier')],
            )),
            PopupMenuItem(value: 'delete', child: Row(
              children: [Icon(Icons.delete_outline, size: 20, color: AppColors.error), const SizedBox(width: 8), Text('Supprimer', style: TextStyle(color: AppColors.error))],
            )),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddEditDialog(BuildContext context, {Depot? depot, int? magasinId}) async {
    final isEdit = depot != null;
    final nomController = TextEditingController(text: depot?.nom);
    final adresseController = TextEditingController(text: depot?.adresse);
    final latitudeController = TextEditingController(text: depot?.latitude?.toString());
    final longitudeController = TextEditingController(text: depot?.longitude?.toString());
    int? selectedMagasinId = depot?.magasinId ?? magasinId;

    final magasinProvider = context.read<MagasinProvider>();
    if (magasinProvider.magasins.isEmpty) {
      await magasinProvider.loadMagasins();
    }

    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEdit ? 'Modifier dépôt' : 'Nouveau dépôt'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: selectedMagasinId,
                  decoration: AppStyles.inputDecoration(label: 'Magasin *', prefixIcon: Icons.store),
                  items: magasinProvider.magasins.map((m) => DropdownMenuItem(
                    value: m.id,
                    child: Text(m.nom ?? 'Sans nom'),
                  )).toList(),
                  onChanged: (value) => setState(() => selectedMagasinId = value),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nomController,
                  decoration: AppStyles.inputDecoration(label: 'Nom *', prefixIcon: Icons.warehouse),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: adresseController,
                  decoration: AppStyles.inputDecoration(label: 'Adresse', prefixIcon: Icons.location_on_outlined),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: latitudeController,
                        decoration: AppStyles.inputDecoration(label: 'Latitude', prefixIcon: Icons.gps_fixed),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: longitudeController,
                        decoration: AppStyles.inputDecoration(label: 'Longitude', prefixIcon: Icons.gps_fixed),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
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
                if (nomController.text.isEmpty || selectedMagasinId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nom et magasin sont obligatoires'), backgroundColor: AppColors.error),
                  );
                  return;
                }

                final provider = context.read<DepotProvider>();
                final newDepot = Depot(
                  id: depot?.id,
                  libelleDepot: depot?.libelleDepot ?? nomController.text,
                  nom: nomController.text,
                  adresse: adresseController.text.isEmpty ? null : adresseController.text,
                  latitude: double.tryParse(latitudeController.text),
                  longitude: double.tryParse(longitudeController.text),
                  magasinId: selectedMagasinId,
                );

                bool success;
                if (isEdit) {
                  success = await provider.updateDepot(depot!.id!, newDepot);
                } else {
                  success = await provider.createDepot(newDepot);
                }

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? (isEdit ? 'Dépôt modifié' : 'Dépôt créé') : 'Erreur'),
                      backgroundColor: success ? AppColors.success : AppColors.error,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: Text(isEdit ? 'Modifier' : 'Créer', style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Depot depot, DepotProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer dépôt'),
        content: Text('Voulez-vous vraiment supprimer "${depot.nom}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await provider.deleteDepot(depot.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Dépôt supprimé' : 'Erreur de suppression'),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    }
  }

  void _showAllStocksDialog(BuildContext context, Depot depot) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white54,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.inventory_2, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Stocks - ${depot.nom ?? depot.libelleDepot}',
                              style: AppStyles.headingMedium.copyWith(color: Colors.white),
                            ),
                            Text(
                              '${depot.stocks?.length ?? 0} produits',
                              style: AppStyles.bodySmall.copyWith(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: depot.stocks == null || depot.stocks!.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text('Aucun stock', style: AppStyles.bodyLarge.copyWith(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: depot.stocks!.length,
                      itemBuilder: (context, index) {
                        final stock = depot.stocks![index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: stock.isOutOfStock
                                  ? AppColors.error.withOpacity(0.1)
                                  : stock.isLowStock
                                      ? Colors.orange.withOpacity(0.1)
                                      : AppColors.success.withOpacity(0.1),
                              child: Icon(
                                stock.isOutOfStock ? Icons.warning : Icons.inventory_2,
                                color: stock.isOutOfStock
                                    ? AppColors.error
                                    : stock.isLowStock
                                        ? Colors.orange
                                        : AppColors.success,
                              ),
                            ),
                            title: Text(
                              stock.produitNom,
                              style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                            ),
                            subtitle: stock.produitCode != null
                                ? Text('Code: ${stock.produitCode}', style: AppStyles.bodySmall)
                                : null,
                            trailing: SizedBox(
                              width: 70,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${stock.quantiteDisponible.toStringAsFixed(0)}',
                                    style: AppStyles.bodyLarge.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: stock.isOutOfStock
                                          ? AppColors.error
                                          : stock.isLowStock
                                              ? Colors.orange
                                              : AppColors.success,
                                    ),
                                  ),
                                  Text('unités', style: AppStyles.caption.copyWith(color: Colors.grey)),
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
    );
  }
}
