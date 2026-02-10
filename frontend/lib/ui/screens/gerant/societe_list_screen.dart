import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../data/models/models.dart';
import '../../../providers/providers.dart';

class SocieteListScreen extends StatefulWidget {
  const SocieteListScreen({super.key});

  @override
  State<SocieteListScreen> createState() => _SocieteListScreenState();
}

class _SocieteListScreenState extends State<SocieteListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SocieteProvider>().loadSocietes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text('Sociétés', style: AppStyles.headingMedium.copyWith(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<SocieteProvider>(
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
                    onPressed: () => provider.loadSocietes(),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          if (provider.societes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.business_outlined, size: 64, color: AppColors.textSecondary.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text('Aucune société', style: AppStyles.bodyLarge.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Text('Ajoutez votre première société', style: AppStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadSocietes(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.societes.length,
              itemBuilder: (context, index) {
                final societe = provider.societes[index];
                return _buildSocieteCard(societe, provider);
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

  Widget _buildSocieteCard(Societe societe, SocieteProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.business, color: AppColors.primary),
        ),
        title: Text(
          societe.raisonSociale,
          style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (societe.adresse != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      societe.adresse!,
                      style: AppStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (societe.telephone != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    societe.telephone!,
                    style: AppStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _showAddEditDialog(context, societe: societe);
            } else if (value == 'delete') {
              _confirmDelete(context, societe, provider);
            } else if (value == 'magasins') {
              Navigator.pushNamed(context, '/gerant/magasins', arguments: societe.id);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'magasins', child: Row(
              children: [Icon(Icons.store_outlined, size: 20), SizedBox(width: 8), Text('Voir magasins')],
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

  Future<void> _showAddEditDialog(BuildContext context, {Societe? societe}) async {
    final isEdit = societe != null;
    final nomController = TextEditingController(text: societe?.raisonSociale);
    final adresseController = TextEditingController(text: societe?.adresse);
    final telephoneController = TextEditingController(text: societe?.telephone);
    final emailController = TextEditingController(text: societe?.email);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Modifier société' : 'Nouvelle société'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomController,
                decoration: AppStyles.inputDecoration(label: 'Nom *', prefixIcon: Icons.business),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: adresseController,
                decoration: AppStyles.inputDecoration(label: 'Adresse', prefixIcon: Icons.location_on_outlined),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: telephoneController,
                decoration: AppStyles.inputDecoration(label: 'Téléphone', prefixIcon: Icons.phone_outlined),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: AppStyles.inputDecoration(label: 'Email', prefixIcon: Icons.email_outlined),
                keyboardType: TextInputType.emailAddress,
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
              if (nomController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Le nom est obligatoire'), backgroundColor: AppColors.error),
                );
                return;
              }

              final provider = context.read<SocieteProvider>();
              final newSociete = Societe(
                id: societe?.id,
                raisonSociale: nomController.text,
                adresse: adresseController.text.isEmpty ? null : adresseController.text,
                telephone: telephoneController.text.isEmpty ? null : telephoneController.text,
                email: emailController.text.isEmpty ? null : emailController.text,
              );

              bool success;
              if (isEdit) {
                success = await provider.updateSociete(societe!.id!, newSociete);
              } else {
                success = await provider.createSociete(newSociete);
              }

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? (isEdit ? 'Société modifiée' : 'Société créée') : 'Erreur'),
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

  Future<void> _confirmDelete(BuildContext context, Societe societe, SocieteProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer société'),
        content: Text('Voulez-vous vraiment supprimer "${societe.raisonSociale}" ?'),
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
      final success = await provider.deleteSociete(societe.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Société supprimée' : 'Erreur de suppression'),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    }
  }
}
