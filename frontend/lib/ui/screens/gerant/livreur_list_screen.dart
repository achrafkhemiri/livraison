import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../data/models/models.dart';
import '../../../providers/providers.dart';

class LivreurListScreen extends StatefulWidget {
  const LivreurListScreen({super.key});

  @override
  State<LivreurListScreen> createState() => _LivreurListScreenState();
}

class _LivreurListScreenState extends State<LivreurListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LivreurProvider>().loadLivreurs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text('Livreurs', style: AppStyles.headingMedium.copyWith(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/gerant/map'),
            tooltip: 'Voir sur la carte',
          ),
        ],
      ),
      body: Consumer<LivreurProvider>(
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
                    onPressed: () => provider.loadLivreurs(),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          if (provider.livreurs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delivery_dining_outlined, size: 64, color: AppColors.textSecondary.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text('Aucun livreur', style: AppStyles.bodyLarge.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Text('Ajoutez votre premier livreur', style: AppStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadLivreurs(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.livreurs.length,
              itemBuilder: (context, index) {
                final livreur = provider.livreurs[index];
                return _buildLivreurCard(livreur, provider);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildLivreurCard(User livreur, LivreurProvider provider) {
    final hasPosition = livreur.latitude != null && livreur.longitude != null;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Stack(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delivery_dining, color: AppColors.accent),
            ),
            if (hasPosition)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          livreur.nom ?? 'Sans nom',
          style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (livreur.email.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    livreur.email,
                    style: AppStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
            if (livreur.telephone != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    livreur.telephone!,
                    style: AppStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
            if (livreur.email != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.email_outlined, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      livreur.email!,
                      style: AppStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (hasPosition) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: AppColors.success),
                  const SizedBox(width: 4),
                  Text(
                    '${livreur.latitude!.toStringAsFixed(4)}, ${livreur.longitude!.toStringAsFixed(4)}',
                    style: AppStyles.bodySmall.copyWith(color: AppColors.success),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _showAddEditDialog(context, livreur: livreur);
            } else if (value == 'delete') {
              _confirmDelete(context, livreur, provider);
            } else if (value == 'orders') {
              Navigator.pushNamed(context, '/gerant/orders', arguments: livreur.id);
            } else if (value == 'locate') {
              if (hasPosition) {
                Navigator.pushNamed(context, '/gerant/map', arguments: {
                  'livreurId': livreur.id,
                  'latitude': livreur.latitude,
                  'longitude': livreur.longitude,
                });
              }
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'orders', child: Row(
              children: [Icon(Icons.shopping_bag_outlined, size: 20), SizedBox(width: 8), Text('Commandes')],
            )),
            if (hasPosition)
              const PopupMenuItem(value: 'locate', child: Row(
                children: [Icon(Icons.location_on_outlined, size: 20), SizedBox(width: 8), Text('Localiser')],
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

  Future<void> _showAddEditDialog(BuildContext context, {User? livreur}) async {
    final isEdit = livreur != null;
    final nomController = TextEditingController(text: livreur?.nom);
    final prenomController = TextEditingController(text: livreur?.prenom);
    final emailController = TextEditingController(text: livreur?.email);
    final telephoneController = TextEditingController(text: livreur?.telephone);
    final passwordController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Modifier livreur' : 'Nouveau livreur'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomController,
                decoration: AppStyles.inputDecoration(label: 'Nom *', prefixIcon: Icons.person),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: prenomController,
                decoration: AppStyles.inputDecoration(label: 'Prénom *', prefixIcon: Icons.person_outline),
              ),
              const SizedBox(height: 12),
              if (!isEdit) ...[
                TextField(
                  controller: passwordController,
                  decoration: AppStyles.inputDecoration(label: 'Mot de passe *', prefixIcon: Icons.lock_outline),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: emailController,
                decoration: AppStyles.inputDecoration(label: 'Email', prefixIcon: Icons.email_outlined),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: telephoneController,
                decoration: AppStyles.inputDecoration(label: 'Téléphone', prefixIcon: Icons.phone_outlined),
                keyboardType: TextInputType.phone,
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
              if (nomController.text.isEmpty || prenomController.text.isEmpty || emailController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nom, prénom et email sont obligatoires'), backgroundColor: AppColors.error),
                );
                return;
              }
              
              if (!isEdit && passwordController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mot de passe obligatoire pour un nouveau livreur'), backgroundColor: AppColors.error),
                );
                return;
              }

              final provider = context.read<LivreurProvider>();
              final newLivreur = User(
                id: livreur?.id ?? 0,
                nom: nomController.text,
                prenom: prenomController.text,
                email: emailController.text,
                telephone: telephoneController.text.isEmpty ? null : telephoneController.text,
                role: 'LIVREUR',
              );

              bool success;
              if (isEdit) {
                success = await provider.updateLivreur(livreur!.id!, newLivreur);
              } else {
                success = await provider.createLivreur(newLivreur);
              }

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? (isEdit ? 'Livreur modifié' : 'Livreur créé') : 'Erreur'),
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
    );
  }

  Future<void> _confirmDelete(BuildContext context, User livreur, LivreurProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer livreur'),
        content: Text('Voulez-vous vraiment supprimer "${livreur.nom}" ?'),
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
      final success = await provider.deleteLivreur(livreur.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Livreur supprimé' : 'Erreur de suppression'),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    }
  }
}
