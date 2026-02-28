import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/constants/responsive.dart';
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
    final r = Responsive(context);
    final magasinId = widget.magasinId ?? (ModalRoute.of(context)?.settings.arguments as int?);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text('Dépôts', style: AppStyles.headingMediumR(r).copyWith(color: Colors.white)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: r.iconSize(24)),
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
                  Icon(Icons.error_outline, size: r.iconSize(48), color: AppColors.error),
                  r.verticalSpace(16),
                  Text(provider.errorMessage!, style: AppStyles.bodyMediumR(r)),
                  r.verticalSpace(16),
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
                  Icon(Icons.warehouse_outlined, size: r.iconSize(64), color: AppColors.textSecondary.withOpacity(0.5)),
                  r.verticalSpace(16),
                  Text('Aucun dépôt', style: AppStyles.bodyLargeR(r).copyWith(color: AppColors.textSecondary)),
                  r.verticalSpace(8),
                  Text('Ajoutez votre premier dépôt', style: AppStyles.bodySmallR(r).copyWith(color: AppColors.textSecondary)),
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
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: r.maxContentWidth),
                child: ListView.builder(
                  padding: r.paddingAll(16),
                  itemCount: provider.depots.length,
                  itemBuilder: (context, index) {
                    final depot = provider.depots[index];
                    return _buildDepotCard(depot, provider, r);
                  },
                ),
              ),
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

  Widget _buildDepotCard(Depot depot, DepotProvider provider, Responsive r) {
    return Card(
      margin: EdgeInsets.only(bottom: r.space(12)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.radius(12))),
      child: ListTile(
        contentPadding: r.paddingAll(16),
        leading: Container(
          width: r.scale(50),
          height: r.scale(50),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(r.radius(12)),
          ),
          child: Icon(Icons.warehouse, color: Colors.orange, size: r.iconSize(24)),
        ),
        title: Text(
          depot.nom ?? 'Sans nom',
          style: AppStyles.bodyLargeR(r).copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (depot.adresse != null) ...[
              r.verticalSpace(4),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: r.iconSize(14), color: AppColors.textSecondary),
                  SizedBox(width: r.space(4)),
                  Expanded(
                    child: Text(
                      depot.adresse!,
                      style: AppStyles.bodySmallR(r).copyWith(color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (depot.magasinNom != null) ...[
              r.verticalSpace(4),
              Row(
                children: [
                  Icon(Icons.store_outlined, size: r.iconSize(14), color: AppColors.textSecondary),
                  SizedBox(width: r.space(4)),
                  Text(
                    depot.magasinNom!,
                    style: AppStyles.bodySmallR(r).copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
            if (depot.latitude != null && depot.longitude != null) ...[
              r.verticalSpace(4),
              Row(
                children: [
                  Icon(Icons.gps_fixed, size: r.iconSize(14), color: AppColors.textSecondary),
                  SizedBox(width: r.space(4)),
                  Text(
                    '${depot.latitude!.toStringAsFixed(4)}, ${depot.longitude!.toStringAsFixed(4)}',
                    style: AppStyles.bodySmallR(r).copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],            // Display stock details
            if (depot.stocks != null && depot.stocks!.isNotEmpty) ...[              r.verticalSpace(8),
              const Divider(height: 1),
              r.verticalSpace(8),
              Text(
                'Stocks (${depot.stocks!.length} produits)',
                style: AppStyles.bodySmallR(r).copyWith(fontWeight: FontWeight.w600),
              ),
              r.verticalSpace(4),
              ...depot.stocks!.take(3).map((stock) => Padding(
                padding: EdgeInsets.symmetric(vertical: r.space(2)),
                child: Row(
                  children: [
                    Icon(
                      stock.isOutOfStock ? Icons.warning : Icons.inventory_2_outlined,
                      size: r.iconSize(12),
                      color: stock.isOutOfStock ? AppColors.error : (stock.isLowStock ? Colors.orange : AppColors.success),
                    ),
                    SizedBox(width: r.space(4)),
                    Expanded(
                      child: Text(
                        stock.produitNom,
                        style: AppStyles.bodySmallR(r),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${stock.quantiteDisponible.toStringAsFixed(0)} unités',
                      style: AppStyles.bodySmallR(r).copyWith(
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
                    padding: EdgeInsets.only(top: r.space(4)),
                    child: Text(
                      '+ ${depot.stocks!.length - 3} autres produits',
                      style: AppStyles.bodySmallR(r).copyWith(color: AppColors.primary, decoration: TextDecoration.underline),
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
    final r = Responsive(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(r.radius(20))),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: r.paddingAll(16),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(r.radius(20))),
              ),
              child: Column(
                children: [
                  Container(
                    width: r.scale(40),
                    height: r.scale(4),
                    margin: EdgeInsets.only(bottom: r.space(16)),
                    decoration: BoxDecoration(
                      color: Colors.white54,
                      borderRadius: BorderRadius.circular(r.radius(2)),
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.inventory_2, color: Colors.white, size: r.iconSize(24)),
                      SizedBox(width: r.space(12)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Stocks - ${depot.nom ?? depot.libelleDepot}',
                              style: AppStyles.headingMediumR(r).copyWith(color: Colors.white),
                            ),
                            Text(
                              '${depot.stocks?.length ?? 0} produits',
                              style: AppStyles.bodySmallR(r).copyWith(color: Colors.white70),
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
                          Icon(Icons.inventory_2_outlined, size: r.iconSize(64), color: Colors.grey[400]),
                          r.verticalSpace(16),
                          Text('Aucun stock', style: AppStyles.bodyLargeR(r).copyWith(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: r.paddingAll(16),
                      itemCount: depot.stocks!.length,
                      itemBuilder: (context, index) {
                        final stock = depot.stocks![index];
                        return Card(
                          margin: EdgeInsets.only(bottom: r.space(8)),
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
                              style: AppStyles.bodyMediumR(r).copyWith(fontWeight: FontWeight.w600),
                            ),
                            subtitle: stock.produitCode != null
                                ? Text('Code: ${stock.produitCode}', style: AppStyles.bodySmallR(r))
                                : null,
                            trailing: SizedBox(
                              width: r.scale(70),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${stock.quantiteDisponible.toStringAsFixed(0)}',
                                    style: AppStyles.bodyLargeR(r).copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: stock.isOutOfStock
                                          ? AppColors.error
                                          : stock.isLowStock
                                              ? Colors.orange
                                              : AppColors.success,
                                    ),
                                  ),
                                  Text('unités', style: AppStyles.captionR(r).copyWith(color: Colors.grey)),
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
