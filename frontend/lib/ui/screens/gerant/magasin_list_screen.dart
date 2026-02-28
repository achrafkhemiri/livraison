import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/constants/responsive.dart';
import '../../../data/models/models.dart';
import '../../../providers/providers.dart';

class MagasinListScreen extends StatefulWidget {
  final int? societeId;
  
  const MagasinListScreen({super.key, this.societeId});

  @override
  State<MagasinListScreen> createState() => _MagasinListScreenState();
}

class _MagasinListScreenState extends State<MagasinListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<MagasinProvider>();
      if (widget.societeId != null) {
        provider.loadMagasinsBySociete(widget.societeId!);
      } else {
        provider.loadMagasins();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    final societeId = widget.societeId ?? (ModalRoute.of(context)?.settings.arguments as int?);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text('Magasins', style: AppStyles.headingMediumR(r).copyWith(color: Colors.white)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: r.iconSize(24)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<MagasinProvider>(
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
                      if (societeId != null) {
                        provider.loadMagasinsBySociete(societeId);
                      } else {
                        provider.loadMagasins();
                      }
                    },
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          if (provider.magasins.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.store_outlined, size: r.iconSize(64), color: AppColors.textSecondary.withOpacity(0.5)),
                  r.verticalSpace(16),
                  Text('Aucun magasin', style: AppStyles.bodyLargeR(r).copyWith(color: AppColors.textSecondary)),
                  r.verticalSpace(8),
                  Text('Ajoutez votre premier magasin', style: AppStyles.bodySmallR(r).copyWith(color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              if (societeId != null) {
                await provider.loadMagasinsBySociete(societeId);
              } else {
                await provider.loadMagasins();
              }
            },
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: r.maxContentWidth),
                child: ListView.builder(
                  padding: r.paddingAll(16),
                  itemCount: provider.magasins.length,
                  itemBuilder: (context, index) {
                    final magasin = provider.magasins[index];
                    return _buildMagasinCard(magasin, provider, r);
                  },
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(context, societeId: societeId),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildMagasinCard(Magasin magasin, MagasinProvider provider, Responsive r) {
    return Card(
      margin: EdgeInsets.only(bottom: r.space(12)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.radius(12))),
      child: ListTile(
        contentPadding: r.paddingAll(16),
        leading: Container(
          width: r.scale(50),
          height: r.scale(50),
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(r.radius(12)),
          ),
          child: Icon(Icons.store, color: AppColors.accent, size: r.iconSize(24)),
        ),
        title: Text(
          magasin.nom ?? 'Sans nom',
          style: AppStyles.bodyLargeR(r).copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (magasin.adresse != null) ...[
              r.verticalSpace(4),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: r.iconSize(14), color: AppColors.textSecondary),
                  SizedBox(width: r.space(4)),
                  Expanded(
                    child: Text(
                      magasin.adresse!,
                      style: AppStyles.bodySmallR(r).copyWith(color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (magasin.societeNom != null) ...[
              r.verticalSpace(4),
              Row(
                children: [
                  Icon(Icons.business_outlined, size: r.iconSize(14), color: AppColors.textSecondary),
                  SizedBox(width: r.space(4)),
                  Text(
                    magasin.societeNom!,
                    style: AppStyles.bodySmallR(r).copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
            if (magasin.latitude != null && magasin.longitude != null) ...[
              r.verticalSpace(4),
              Row(
                children: [
                  Icon(Icons.gps_fixed, size: r.iconSize(14), color: AppColors.textSecondary),
                  SizedBox(width: r.space(4)),
                  Text(
                    '${magasin.latitude!.toStringAsFixed(4)}, ${magasin.longitude!.toStringAsFixed(4)}',
                    style: AppStyles.bodySmallR(r).copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _showAddEditDialog(context, magasin: magasin);
            } else if (value == 'delete') {
              _confirmDelete(context, magasin, provider);
            } else if (value == 'depots') {
              Navigator.pushNamed(context, '/gerant/depots', arguments: magasin.id);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'depots', child: Row(
              children: [Icon(Icons.warehouse_outlined, size: 20), SizedBox(width: 8), Text('Voir dépôts')],
            )),
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

  Future<void> _showAddEditDialog(BuildContext context, {Magasin? magasin, int? societeId}) async {
    final isEdit = magasin != null;
    final nomController = TextEditingController(text: magasin?.nom);
    final adresseController = TextEditingController(text: magasin?.adresse);
    final latitudeController = TextEditingController(text: magasin?.latitude?.toString());
    final longitudeController = TextEditingController(text: magasin?.longitude?.toString());
    int? selectedSocieteId = magasin?.societeId ?? societeId;

    final societeProvider = context.read<SocieteProvider>();
    if (societeProvider.societes.isEmpty) {
      await societeProvider.loadSocietes();
    }

    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEdit ? 'Modifier magasin' : 'Nouveau magasin'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: selectedSocieteId,
                  decoration: AppStyles.inputDecoration(label: 'Société *', prefixIcon: Icons.business),
                  items: societeProvider.societes.map((s) => DropdownMenuItem(
                    value: s.id,
                    child: Text(s.raisonSociale),
                  )).toList(),
                  onChanged: (value) => setState(() => selectedSocieteId = value),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nomController,
                  decoration: AppStyles.inputDecoration(label: 'Nom *', prefixIcon: Icons.store),
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
                if (nomController.text.isEmpty || selectedSocieteId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nom et société sont obligatoires'), backgroundColor: AppColors.error),
                  );
                  return;
                }

                final provider = context.read<MagasinProvider>();
                final newMagasin = Magasin(
                  id: magasin?.id,
                  code: magasin?.code ?? 'MAG${DateTime.now().millisecondsSinceEpoch}',
                  nom: nomController.text,
                  adresse: adresseController.text.isEmpty ? null : adresseController.text,
                  latitude: double.tryParse(latitudeController.text),
                  longitude: double.tryParse(longitudeController.text),
                  societeId: selectedSocieteId,
                );

                bool success;
                if (isEdit) {
                  success = await provider.updateMagasin(magasin!.id!, newMagasin);
                } else {
                  success = await provider.createMagasin(newMagasin);
                }

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? (isEdit ? 'Magasin modifié' : 'Magasin créé') : 'Erreur'),
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

  Future<void> _confirmDelete(BuildContext context, Magasin magasin, MagasinProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer magasin'),
        content: Text('Voulez-vous vraiment supprimer "${magasin.nom}" ?'),
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
      final success = await provider.deleteMagasin(magasin.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Magasin supprimé' : 'Erreur de suppression'),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    }
  }
}
