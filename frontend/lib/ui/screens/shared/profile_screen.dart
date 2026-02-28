import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/constants/responsive.dart';
import '../../../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profil')),
        body: const Center(child: Text('Utilisateur non connecté')),
      );
    }

    final roleLabel = user.isGerant ? 'Gérant' : user.isLivreur ? 'Livreur' : user.role;
    final roleColor = user.isGerant ? AppColors.primary : AppColors.accent;
    final initials = '${user.prenom.isNotEmpty ? user.prenom[0] : ''}${user.nom.isNotEmpty ? user.nom[0] : ''}'.toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ========== HEADER ==========
          SliverAppBar(
            expandedHeight: r.scale(220),
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white, size: r.iconSize(24)),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: r.space(20)),
                      // Avatar
                      Container(
                        width: r.scale(90),
                        height: r.scale(90),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.2),
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: Center(
                          child: Text(
                            initials,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: r.fontSize(32),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: r.space(12)),
                      Text(
                        user.fullName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: r.fontSize(22),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: r.space(6)),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: r.space(16), vertical: r.space(4)),
                        decoration: BoxDecoration(
                          color: roleColor.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(r.radius(20)),
                          border: Border.all(color: Colors.white.withOpacity(0.5)),
                        ),
                        child: Text(
                          roleLabel,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: r.fontSize(13),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ========== CONTENT ==========
          SliverToBoxAdapter(
            child: Padding(
              padding: r.paddingAll(20),
              child: Column(
                children: [
                  // ---- Informations personnelles ----
                  _buildSectionCard(
                    r: r,
                    icon: Icons.person_outline,
                    title: 'Informations personnelles',
                    children: [
                      _buildInfoTile(r, Icons.badge_outlined, 'Nom complet', user.fullName),
                      _buildDivider(r),
                      _buildInfoTile(r, Icons.email_outlined, 'Email', user.email),
                      _buildDivider(r),
                      _buildInfoTile(r, Icons.phone_outlined, 'Téléphone', user.telephone ?? 'Non renseigné'),
                    ],
                  ),
                  SizedBox(height: r.space(16)),

                  // ---- Informations professionnelles ----
                  _buildSectionCard(
                    r: r,
                    icon: Icons.work_outline,
                    title: 'Informations professionnelles',
                    children: [
                      _buildInfoTile(r, Icons.shield_outlined, 'Rôle', roleLabel),
                      _buildDivider(r),
                      _buildInfoTile(r, Icons.business_outlined, 'Société', user.societeNom ?? 'Non assignée'),
                      _buildDivider(r),
                      _buildInfoTile(
                        r,
                        Icons.circle,
                        'Statut',
                        user.actif ? 'Actif' : 'Inactif',
                        valueColor: user.actif ? AppColors.success : AppColors.error,
                        iconColor: user.actif ? AppColors.success : AppColors.error,
                        iconSize: 12,
                      ),
                      if (user.createdAt != null) ...[
                        _buildDivider(r),
                        _buildInfoTile(r, Icons.calendar_today_outlined, 'Membre depuis', DateFormat('dd MMMM yyyy', 'fr_FR').format(user.createdAt!)),
                      ],
                    ],
                  ),
                  SizedBox(height: r.space(16)),

                  // ---- Localisation (livreur uniquement) ----
                  if (user.isLivreur) ...[
                    _buildSectionCard(
                      r: r,
                      icon: Icons.location_on_outlined,
                      title: 'Localisation',
                      children: [
                        _buildInfoTile(
                          r,
                          Icons.gps_fixed,
                          'Position GPS',
                          user.latitude != null && user.longitude != null
                              ? '${user.latitude!.toStringAsFixed(5)}, ${user.longitude!.toStringAsFixed(5)}'
                              : 'Non disponible',
                        ),
                        if (user.dernierePositionAt != null) ...[
                          _buildDivider(r),
                          _buildInfoTile(
                            r,
                            Icons.access_time,
                            'Dernière mise à jour',
                            DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(user.dernierePositionAt!),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: r.space(16)),
                  ],

                  // ---- ID ----
                  _buildSectionCard(
                    r: r,
                    icon: Icons.info_outline,
                    title: 'Détails du compte',
                    children: [
                      _buildInfoTile(r, Icons.tag, 'Identifiant', '#${user.id}'),
                    ],
                  ),
                  SizedBox(height: r.space(32)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== REUSABLE WIDGETS ==========

  Widget _buildSectionCard({
    required Responsive r,
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(r.radius(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: EdgeInsets.fromLTRB(r.space(16), r.space(16), r.space(16), r.space(8)),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(r.space(8)),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(r.radius(10)),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: r.iconSize(20)),
                ),
                SizedBox(width: r.space(12)),
                Text(
                  title,
                  style: AppStyles.headingSmallR(r).copyWith(fontSize: r.fontSize(16)),
                ),
              ],
            ),
          ),
          // Section content
          ...children,
          SizedBox(height: r.space(8)),
        ],
      ),
    );
  }

  Widget _buildInfoTile(
    Responsive r,
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
    Color? iconColor,
    double? iconSize,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: r.space(16), vertical: r.space(12)),
      child: Row(
        children: [
          Icon(icon, size: r.iconSize(iconSize ?? 20), color: iconColor ?? AppColors.textSecondary),
          SizedBox(width: r.space(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppStyles.captionR(r).copyWith(color: AppColors.textSecondary),
                ),
                SizedBox(height: r.space(2)),
                Text(
                  value,
                  style: AppStyles.bodyMediumR(r).copyWith(
                    fontWeight: FontWeight.w500,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(Responsive r) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: r.space(16)),
      child: const Divider(height: 1, color: AppColors.divider),
    );
  }
}
