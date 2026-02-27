import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

class _OrderListScreenState extends State<OrderListScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _selectedStatus = 'all';
  DateTime? _dateFrom;
  DateTime? _dateTo;
  bool _showFilters = false;

  final List<Map<String, dynamic>> _statusOptions = [
    {'value': 'all', 'label': 'Toutes', 'icon': Icons.list_alt, 'color': AppColors.primary},
    {'value': 'pending', 'label': 'En attente', 'icon': Icons.schedule, 'color': AppColors.statusPending},
    {'value': 'assigned', 'label': 'Proposée', 'icon': Icons.assignment_ind, 'color': Colors.amber},
    {'value': 'en_cours', 'label': 'Acceptée', 'icon': Icons.thumb_up, 'color': AppColors.statusProcessing},
    {'value': 'processing', 'label': 'En cours', 'icon': Icons.sync, 'color': AppColors.statusProcessing},
    {'value': 'shipped', 'label': 'Livraison', 'icon': Icons.local_shipping, 'color': AppColors.statusShipped},
    {'value': 'delivered', 'label': 'Livrées', 'icon': Icons.check_circle, 'color': AppColors.statusDelivered},
    {'value': 'cancelled', 'label': 'Annulées', 'icon': Icons.cancel, 'color': AppColors.statusCancelled},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrders();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _loadOrders() {
    context.read<OrderProvider>().searchOrders(
      page: 0,
      search: _searchController.text.isNotEmpty ? _searchController.text : null,
      status: _selectedStatus != 'all' ? _selectedStatus : null,
      dateFrom: _dateFrom,
      dateTo: _dateTo,
    );
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _loadOrders();
    });
  }

  void _onStatusChanged(String status) {
    setState(() => _selectedStatus = status);
    _loadOrders();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedStatus = 'all';
      _dateFrom = null;
      _dateTo = null;
      _showFilters = false;
    });
    _loadOrders();
  }

  bool get _hasActiveFilters =>
      _searchController.text.isNotEmpty ||
      _selectedStatus != 'all' ||
      _dateFrom != null ||
      _dateTo != null;

  // ── Build ───────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallPhone = screenWidth < 360;
    final isMediumPhone = screenWidth >= 360 && screenWidth < 400;
    final horizontalPadding = isSmallPhone ? 12.0 : 16.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, isSmallPhone),
            _buildSearchBar(horizontalPadding, isSmallPhone),
            _buildStatusChips(isSmallPhone),
            if (_showFilters) _buildDateFilter(horizontalPadding, isSmallPhone),
            if (_hasActiveFilters) _buildActiveFiltersBanner(horizontalPadding),
            _buildResultsHeader(horizontalPadding, isSmallPhone),
            Expanded(
              child: _buildOrdersList(horizontalPadding, isSmallPhone, isMediumPhone),
            ),
            _buildPaginationControls(isSmallPhone),
          ],
        ),
      ),
      // Bottom FAB removed; add button moved to header
    );
  }

  // ── Header ──────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, bool isSmall) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(isSmall ? 12 : 16, 12, isSmall ? 12 : 16, 20),
      child: Row(
        children: [
          Material(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.pop(context),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Commandes',
                  style: AppStyles.headingMedium.copyWith(
                    color: Colors.white,
                    fontSize: isSmall ? 18 : 22,
                  ),
                ),
                Consumer<OrderProvider>(
                  builder: (_, provider, __) => Text(
                    '${provider.totalElements} commande${provider.totalElements > 1 ? 's' : ''}',
                    style: AppStyles.bodySmall.copyWith(
                      color: Colors.white70,
                      fontSize: isSmall ? 11 : 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                setState(() => _showFilters = !_showFilters);
              },
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Stack(
                  children: [
                    Icon(
                      _showFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                    if (_hasActiveFilters)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // Small round '+' button placed next to filter
          const SizedBox(width: 8),
          Material(
            color: Colors.white.withOpacity(0.2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _showCreateOrderDialog(context),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.add, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Search Bar ──────────────────────────────────────────────
  Widget _buildSearchBar(double hPad, bool isSmall) {
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          style: AppStyles.bodyMedium.copyWith(fontSize: isSmall ? 13 : 14),
          decoration: InputDecoration(
            hintText: 'Rechercher par n°, client, livreur...',
            hintStyle: AppStyles.bodyMedium.copyWith(
              color: AppColors.textHint,
              fontSize: isSmall ? 12 : 14,
            ),
            prefixIcon: Icon(Icons.search, color: AppColors.textSecondary, size: isSmall ? 20 : 22),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: AppColors.textSecondary, size: isSmall ? 18 : 20),
                    onPressed: () {
                      _searchController.clear();
                      _loadOrders();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: isSmall ? 12 : 14,
            ),
          ),
        ),
      ),
    );
  }

  // ── Status Chips ────────────────────────────────────────────
  Widget _buildStatusChips(bool isSmall) {
    return SizedBox(
      height: isSmall ? 42 : 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 16),
        itemCount: _statusOptions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = _statusOptions[index];
          final isSelected = _selectedStatus == option['value'];
          final color = option['color'] as Color;

          return GestureDetector(
            onTap: () => _onStatusChanged(option['value'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                horizontal: isSmall ? 10 : 14,
                vertical: isSmall ? 6 : 8,
              ),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected ? color : AppColors.border,
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    option['icon'] as IconData,
                    size: isSmall ? 14 : 16,
                    color: isSelected ? Colors.white : color,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    option['label'] as String,
                    style: TextStyle(
                      fontSize: isSmall ? 11 : 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Date Filter Panel ───────────────────────────────────────
  Widget _buildDateFilter(double hPad, bool isSmall) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.fromLTRB(hPad, 8, hPad, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.date_range, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Filtrer par date',
                style: AppStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: isSmall ? 13 : 14,
                ),
              ),
              const Spacer(),
              if (_dateFrom != null || _dateTo != null)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _dateFrom = null;
                      _dateTo = null;
                    });
                    _loadOrders();
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Effacer',
                    style: TextStyle(fontSize: isSmall ? 11 : 12, color: AppColors.error),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildDatePickerButton(
                  label: 'Du',
                  date: _dateFrom,
                  dateFormat: dateFormat,
                  isSmall: isSmall,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _dateFrom ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => _dateFrom = picked);
                      _loadOrders();
                    }
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward, size: 16, color: AppColors.textSecondary),
              ),
              Expanded(
                child: _buildDatePickerButton(
                  label: 'Au',
                  date: _dateTo,
                  dateFormat: dateFormat,
                  isSmall: isSmall,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _dateTo ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => _dateTo = picked);
                      _loadOrders();
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerButton({
    required String label,
    required DateTime? date,
    required DateFormat dateFormat,
    required bool isSmall,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: isSmall ? 10 : 12),
        decoration: BoxDecoration(
          color: date != null ? AppColors.primary.withOpacity(0.08) : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: date != null ? AppColors.primary.withOpacity(0.3) : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: isSmall ? 14 : 16,
              color: date != null ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                date != null ? dateFormat.format(date) : label,
                style: TextStyle(
                  fontSize: isSmall ? 12 : 13,
                  color: date != null ? AppColors.primary : AppColors.textHint,
                  fontWeight: date != null ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Active Filters Banner ───────────────────────────────────
  Widget _buildActiveFiltersBanner(double hPad) {
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.info.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.info.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.filter_list, size: 16, color: AppColors.info),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Filtres actifs',
                style: TextStyle(fontSize: 12, color: AppColors.info, fontWeight: FontWeight.w600),
              ),
            ),
            GestureDetector(
              onTap: _clearFilters,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Effacer tout',
                  style: TextStyle(fontSize: 11, color: AppColors.info, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Results Header ──────────────────────────────────────────
  Widget _buildResultsHeader(double hPad, bool isSmall) {
    return Consumer<OrderProvider>(
      builder: (_, provider, __) {
        if (provider.isLoadingPage) return const SizedBox.shrink();
        return Padding(
          padding: EdgeInsets.fromLTRB(hPad, 10, hPad, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${provider.totalElements} résultat${provider.totalElements > 1 ? 's' : ''}',
                style: AppStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: isSmall ? 11 : 12,
                ),
              ),
              Row(
                children: [
                  // Page size selector (smaller square)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: SizedBox(
                      width: 52,
                      height: 36,
                      child: DropdownButton<int>(
                        isExpanded: true,
                        alignment: Alignment.center,
                        value: provider.pageSize,
                        iconSize: 18,
                        style: AppStyles.bodySmall.copyWith(fontSize: 12),
                        underline: const SizedBox.shrink(),
                        items: const [5, 10, 15].map((v) {
                          return DropdownMenuItem<int>(
                            value: v,
                            child: Center(child: Text('$v')),
                          );
                        }).toList(),
                        onChanged: (v) async {
                          if (v == null) return;
                          await provider.searchOrders(
                            page: 0,
                            size: v,
                            search: provider.searchQuery,
                            status: provider.statusFilter,
                            dateFrom: provider.dateFrom,
                            dateTo: provider.dateTo,
                          );
                        },
                      ),
                    ),
                  ),
                  if (provider.totalPages > 1)
                    Text(
                      'Page ${provider.currentPage + 1}/${provider.totalPages}',
                      style: AppStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: isSmall ? 11 : 12,
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Orders List ─────────────────────────────────────────────
  Widget _buildOrdersList(double hPad, bool isSmall, bool isMedium) {
    return Consumer<OrderProvider>(
      builder: (context, provider, _) {
        if (provider.isLoadingPage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(strokeWidth: 3),
                const SizedBox(height: 16),
                Text(
                  'Chargement...',
                  style: AppStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }

        if (provider.errorMessage != null) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(hPad),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur de chargement',
                    style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.errorMessage!,
                    style: AppStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _loadOrders,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Réessayer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (provider.paginatedOrders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.06),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.inbox_outlined,
                    size: isSmall ? 48 : 64,
                    color: AppColors.primary.withOpacity(0.4),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _hasActiveFilters ? 'Aucun résultat trouvé' : 'Aucune commande',
                  style: AppStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: isSmall ? 14 : 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _hasActiveFilters
                      ? 'Essayez de modifier vos filtres'
                      : 'Les commandes apparaîtront ici',
                  style: AppStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                if (_hasActiveFilters) ...[
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Effacer les filtres'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                  ),
                ],
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.refreshCurrentPage(),
          color: AppColors.primary,
          child: ListView.builder(
            padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 80),
            itemCount: provider.paginatedOrders.length,
            itemBuilder: (context, index) {
              final order = provider.paginatedOrders[index];
              return _buildOrderCard(order, provider, isSmall, isMedium);
            },
          ),
        );
      },
    );
  }

  // ── Order Card ──────────────────────────────────────────────
  Widget _buildOrderCard(Order order, OrderProvider provider, bool isSmall, bool isMedium) {
    final statusInfo = _getStatusInfo(order.status);
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'fr_FR');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showOrderDetails(order),
          child: Padding(
            padding: EdgeInsets.all(isSmall ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: status icon + order info + status badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: isSmall ? 36 : 44,
                      height: isSmall ? 36 : 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            statusInfo.color.withOpacity(0.15),
                            statusInfo.color.withOpacity(0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        statusInfo.icon,
                        color: statusInfo.color,
                        size: isSmall ? 18 : 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'CMD ${order.id}',
                                  style: AppStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: isSmall ? 13 : 15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmall ? 8 : 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusInfo.color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  statusInfo.label,
                                  style: TextStyle(
                                    fontSize: isSmall ? 10 : 11,
                                    fontWeight: FontWeight.w700,
                                    color: statusInfo.color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            order.dateCommande != null
                                ? dateFormat.format(order.dateCommande!)
                                : 'Date inconnue',
                            style: AppStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: isSmall ? 10 : 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(height: 1, color: AppColors.divider.withOpacity(0.5)),
                const SizedBox(height: 12),
                // Details section — adaptive layout
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 300;
                    if (isNarrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(Icons.person_outline, 'Client',
                              order.clientNom ?? 'Client #${order.clientId}', isSmall),
                          const SizedBox(height: 6),
                          _buildInfoRow(Icons.delivery_dining, 'Livreur',
                              order.livreurNom ?? (order.livreurId != null ? '#${order.livreurId}' : 'Non assigné'), isSmall),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildAmountBadge(order, isSmall),
                              _buildActionsButton(order, provider, isSmall),
                            ],
                          ),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoRow(Icons.person_outline, 'Client',
                                  order.clientNom ?? 'Client #${order.clientId}', isSmall),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildInfoRow(Icons.delivery_dining, 'Livreur',
                                  order.livreurNom ?? (order.livreurId != null ? '#${order.livreurId}' : 'Non assigné'), isSmall),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildAmountBadge(order, isSmall),
                            _buildActionsButton(order, provider, isSmall),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, bool isSmall) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: isSmall ? 14 : 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isSmall ? 9 : 10,
                  color: AppColors.textHint,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: isSmall ? 11 : 12,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAmountBadge(Order order, bool isSmall) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 10 : 12,
        vertical: isSmall ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.payments_outlined, size: isSmall ? 14 : 16, color: AppColors.accent),
          const SizedBox(width: 6),
          Text(
            '${order.montantTTC?.toStringAsFixed(2) ?? "0.00"} TND',
            style: TextStyle(
              fontSize: isSmall ? 12 : 13,
              fontWeight: FontWeight.w700,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsButton(Order order, OrderProvider provider, bool isSmall) {
    return PopupMenuButton<String>(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmall ? 10 : 12,
          vertical: isSmall ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.more_horiz, size: isSmall ? 16 : 18, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              'Actions',
              style: TextStyle(
                fontSize: isSmall ? 11 : 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
      onSelected: (value) => _handleOrderAction(order, value, provider),
      itemBuilder: (context) => [
        if (order.status == 'pending') ...[
          _buildPopupItem('assign', Icons.person_add, 'Assigner', AppColors.primary),
          _buildPopupItem('processing', Icons.play_arrow, 'Commencer', AppColors.statusProcessing),
        ],
        if (order.status == 'assigned')
          _buildPopupItem('assign', Icons.swap_horiz, 'Re-assigner', Colors.amber.shade700),
        if (order.status == 'en_cours')
          _buildPopupItem('processing', Icons.play_arrow, 'Commencer traitement', AppColors.statusProcessing),
        if (order.status == 'processing')
          _buildPopupItem('shipped', Icons.local_shipping, 'Expédier', AppColors.statusShipped),
        if (order.status == 'shipped')
          _buildPopupItem('delivered', Icons.check_circle, 'Livré', AppColors.statusDelivered),
        if (order.status != 'cancelled' && order.status != 'delivered')
          _buildPopupItem('cancelled', Icons.cancel, 'Annuler', AppColors.error),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupItem(String value, IconData icon, String label, Color color) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ── Pagination Controls ─────────────────────────────────────
  Widget _buildPaginationControls(bool isSmall) {
    return Consumer<OrderProvider>(
      builder: (_, provider, __) {
        if (provider.totalPages <= 1) return const SizedBox.shrink();
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSmall ? 12 : 16,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPaginationButton(
                icon: Icons.chevron_left,
                onTap: provider.isFirstPage ? null : () => provider.previousPage(),
                isSmall: isSmall,
              ),
              const SizedBox(width: 8),
              ..._buildPageNumbers(provider, isSmall),
              const SizedBox(width: 8),
              _buildPaginationButton(
                icon: Icons.chevron_right,
                onTap: provider.isLastPage ? null : () => provider.nextPage(),
                isSmall: isSmall,
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildPageNumbers(OrderProvider provider, bool isSmall) {
    final List<Widget> buttons = [];
    final current = provider.currentPage;
    final total = provider.totalPages;

    int start = (current - 2).clamp(0, total - 1);
    int end = (current + 2).clamp(0, total - 1);
    if (end - start < 4 && total >= 5) {
      if (start == 0) {
        end = (4).clamp(0, total - 1);
      } else if (end == total - 1) {
        start = (total - 5).clamp(0, total - 1);
      }
    }

    if (start > 0) {
      buttons.add(_buildPageButton(0, current == 0, provider, isSmall));
      if (start > 1) {
        buttons.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text('...', style: TextStyle(color: AppColors.textSecondary, fontSize: isSmall ? 12 : 14)),
        ));
      }
    }

    for (int i = start; i <= end; i++) {
      buttons.add(_buildPageButton(i, i == current, provider, isSmall));
    }

    if (end < total - 1) {
      if (end < total - 2) {
        buttons.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text('...', style: TextStyle(color: AppColors.textSecondary, fontSize: isSmall ? 12 : 14)),
        ));
      }
      buttons.add(_buildPageButton(total - 1, current == total - 1, provider, isSmall));
    }

    return buttons;
  }

  Widget _buildPageButton(int page, bool isActive, OrderProvider provider, bool isSmall) {
    return GestureDetector(
      onTap: isActive ? null : () => provider.goToPage(page),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isSmall ? 32 : 36,
        height: isSmall ? 32 : 36,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            '${page + 1}',
            style: TextStyle(
              fontSize: isSmall ? 12 : 13,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationButton({
    required IconData icon,
    required VoidCallback? onTap,
    required bool isSmall,
  }) {
    final isDisabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isSmall ? 32 : 36,
        height: isSmall ? 32 : 36,
        decoration: BoxDecoration(
          color: isDisabled ? AppColors.background : AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: isSmall ? 18 : 20,
          color: isDisabled ? AppColors.textHint : AppColors.primary,
        ),
      ),
    );
  }

  // ── Status Helper ───────────────────────────────────────────
  _StatusInfo _getStatusInfo(String? status) {
    switch (status) {
      case 'pending':
        return _StatusInfo('En attente', Icons.schedule, AppColors.statusPending);
      case 'assigned':
        return _StatusInfo('Proposée', Icons.assignment_ind, Colors.amber);
      case 'en_cours':
        return _StatusInfo('Acceptée', Icons.thumb_up, AppColors.statusProcessing);
      case 'processing':
        return _StatusInfo('En cours', Icons.sync, AppColors.statusProcessing);
      case 'shipped':
        return _StatusInfo('En livraison', Icons.local_shipping, AppColors.statusShipped);
      case 'delivered':
        return _StatusInfo('Livrée', Icons.check_circle, AppColors.statusDelivered);
      case 'cancelled':
        return _StatusInfo('Annulée', Icons.cancel, AppColors.statusCancelled);
      case 'done':
        return _StatusInfo('Terminée', Icons.done_all, AppColors.success);
      default:
        return _StatusInfo(status ?? 'Inconnu', Icons.help_outline, AppColors.textSecondary);
    }
  }

  // ── Actions & Dialogs ───────────────────────────────────────
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
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        if (success) provider.refreshCurrentPage();
      }
    }
  }

  Future<void> _showAssignDialog(Order order, OrderProvider provider) async {
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
    Navigator.pop(context);

    if (recommendations.isEmpty) {
      await _showFallbackAssignDialog(order, provider);
      return;
    }

    int? selectedLivreurId;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.recommend, color: AppColors.primary),
              SizedBox(width: 8),
              Expanded(child: Text('Assigner un livreur')),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Livreurs triés par proximité',
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
                      final isSelected = selectedLivreurId == livreurId;

                      return Card(
                        elevation: isSelected ? 3 : 1,
                        color: isSelected ? AppColors.primary.withOpacity(0.08) : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : Colors.transparent,
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
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text('${index + 1}',
                                        style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(nom.toString(),
                                          style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                                      Text('${distance.toStringAsFixed(1)} km',
                                          style: AppStyles.caption.copyWith(color: AppColors.textSecondary)),
                                    ],
                                  ),
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
                            content: Text(success ? 'Commande proposée au livreur' : 'Erreur'),
                            backgroundColor: success ? AppColors.success : AppColors.error,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        if (success) provider.refreshCurrentPage();
                      }
                    },
              icon: const Icon(Icons.send, size: 18),
              label: const Text('Proposer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Assigner un livreur'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: selectedLivreurId,
                decoration: AppStyles.inputDecoration(label: 'Livreur', prefixIcon: Icons.delivery_dining),
                items: livreurProvider.livreurs
                    .map((l) => DropdownMenuItem(
                          value: l.id,
                          child: Text(l.nom),
                        ))
                    .toList(),
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
              onPressed: selectedLivreurId == null
                  ? null
                  : () async {
                      final success = await provider.assignOrderToLivreur(order.id!, selectedLivreurId!);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success ? 'Livreur assigné' : 'Erreur'),
                            backgroundColor: success ? AppColors.success : AppColors.error,
                          ),
                        );
                        if (success) provider.refreshCurrentPage();
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

  // ── Order Details Bottom Sheet ──────────────────────────────
  Future<void> _showOrderDetails(Order order) async {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'fr_FR');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.receipt_long, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Text('Commande CMD ${order.id}',
                              style: AppStyles.headingSmall.copyWith(fontSize: 18)),
                          if (order.dateCommande != null)
                            Text(dateFormat.format(order.dateCommande!),
                                style: AppStyles.caption.copyWith(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildDetailCard('Informations', [
                  _buildDetailItem(Icons.label, 'Statut', order.statusLabel),
                  _buildDetailItem(Icons.person_outline, 'Client',
                      order.clientNom ?? 'Client #${order.clientId}'),
                  if (order.clientPhone != null)
                    _buildDetailItem(Icons.phone, 'Téléphone', order.clientPhone!),
                  if (order.clientEmail != null)
                    _buildDetailItem(Icons.email, 'Email', order.clientEmail!),
                  _buildDetailItem(
                      Icons.delivery_dining,
                      'Livreur',
                      order.livreurNom ??
                          (order.livreurId != null ? 'Livreur #${order.livreurId}' : 'Non assigné')),
                  _buildDetailItem(Icons.warehouse, 'Dépôt',
                      order.depotNom ?? (order.depotId != null ? 'Dépôt #${order.depotId}' : 'N/A')),
                ]),
                const SizedBox(height: 12),
                _buildDetailCard('Montants', [
                  _buildDetailItem(
                      Icons.payments, 'Total TTC', '${order.montantTTC?.toStringAsFixed(2) ?? "0.00"} TND'),
                  if (order.montantHT != null)
                    _buildDetailItem(Icons.receipt, 'HT', '${order.montantHT!.toStringAsFixed(2)} TND'),
                  if (order.montantTVA != null)
                    _buildDetailItem(Icons.percent, 'TVA', '${order.montantTVA!.toStringAsFixed(2)} TND'),
                ]),
                if (order.adresseLivraison != null) ...[
                  const SizedBox(height: 12),
                  _buildDetailCard('Livraison', [
                    _buildDetailItem(Icons.location_on, 'Adresse', order.adresseLivraison!),
                    if (order.notes != null && order.notes!.isNotEmpty)
                      _buildDetailItem(Icons.note, 'Notes', order.notes!),
                  ]),
                ],
                if (order.items != null && order.items!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Articles (${order.items!.length})',
                      style: AppStyles.headingSmall.copyWith(fontSize: 16)),
                  const SizedBox(height: 8),
                  ...order.items!.map((item) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.inventory_2, size: 18, color: AppColors.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.displayName,
                                      style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                                  Text('Quantité: ${item.quantite}', style: AppStyles.caption),
                                ],
                              ),
                            ),
                            Text(
                              '${item.montantTTC?.toStringAsFixed(2) ?? "0.00"} TND',
                              style: AppStyles.bodyMedium
                                  .copyWith(fontWeight: FontWeight.w700, color: AppColors.accent),
                            ),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard(String title, List<Widget> items) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.w700, color: AppColors.primary)),
          const SizedBox(height: 8),
          ...items,
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: Text(label, style: AppStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value, style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  // ── Create Order Dialog ─────────────────────────────────────
  Future<void> _showCreateOrderDialog(BuildContext context) async {
    final latController = TextEditingController();
    final lngController = TextEditingController();
    final adresseController = TextEditingController();
    final notesController = TextEditingController();

    List<Client> clients = [];
    Client? selectedClient;
    bool loadingClients = true;

    List<Map<String, dynamic>> productsStock = [];
    List<Map<String, dynamic>> selectedItems = [];
    bool loadingProducts = true;

    Map<int, List<Map<String, dynamic>>> manualAssignments = {};

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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.shopping_bag, color: AppColors.primary),
                SizedBox(width: 8),
                Expanded(child: Text('Nouvelle commande')),
              ],
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.85,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Client', style: AppStyles.headingSmall.copyWith(fontSize: 16)),
                    const SizedBox(height: 8),
                    if (loadingClients)
                      const Center(child: CircularProgressIndicator())
                    else
                      DropdownButtonFormField<Client>(
                        value: selectedClient,
                        decoration:
                            AppStyles.inputDecoration(label: 'Client *', prefixIcon: Icons.person),
                        isExpanded: true,
                        style: AppStyles.bodyMedium,
                        items: clients.map((client) {
                          final displayName = client.nom != null && client.nom!.isNotEmpty
                              ? client.nom!
                              : client.email ?? 'Client #${client.id}';
                          return DropdownMenuItem<Client>(
                            value: client,
                            child:
                                Text('#${client.id} - $displayName', overflow: TextOverflow.ellipsis),
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
                            style: AppStyles.bodyMedium,
                            decoration: AppStyles.inputDecoration(
                                label: 'Latitude', prefixIcon: Icons.location_on),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: lngController,
                            style: AppStyles.bodyMedium,
                            decoration: AppStyles.inputDecoration(
                                label: 'Longitude', prefixIcon: Icons.location_on),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: adresseController,
                      style: AppStyles.bodyMedium,
                      decoration: AppStyles.inputDecoration(
                          label: 'Adresse de livraison', prefixIcon: Icons.home),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Produits', style: AppStyles.headingSmall.copyWith(fontSize: 16)),
                        if (!loadingProducts)
                          ElevatedButton.icon(
                            onPressed: () =>
                                _showProductPicker(context, productsStock, selectedItems, setState),
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
                            child: Text('Aucun produit ajouté', style: AppStyles.bodySmall)),
                      )
                    else
                      ...selectedItems.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final item = entry.value;
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text(item['produitNom'] ?? 'Produit',
                                style: AppStyles.bodyMedium),
                            subtitle: Text(
                                '${(item['prixHT'] ?? 0.0).toStringAsFixed(2)} TND x ${item['quantite']}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, size: 18),
                                  onPressed: () {
                                    setState(() {
                                      if ((item['quantite'] as int) > 1) {
                                        item['quantite'] = (item['quantite'] as int) - 1;
                                      }
                                    });
                                  },
                                ),
                                Text('${item['quantite']}',
                                    style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: const Icon(Icons.add, size: 18),
                                  onPressed: () {
                                    setState(
                                        () => item['quantite'] = (item['quantite'] as int) + 1);
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete_outline,
                                      size: 18, color: AppColors.error),
                                  onPressed: () => setState(() => selectedItems.removeAt(idx)),
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
                          style: AppStyles.bodyLarge
                              .copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      decoration:
                          AppStyles.inputDecoration(label: 'Notes', prefixIcon: Icons.note),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
              ElevatedButton(
                onPressed: () async {
                  if (selectedClient == null || selectedClient!.id == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Veuillez sélectionner un client'),
                          backgroundColor: AppColors.error),
                    );
                    return;
                  }
                  final lat = double.tryParse(latController.text);
                  final lng = double.tryParse(lngController.text);
                  final items = selectedItems
                      .map((item) => OrderItem(
                            produitId: item['produitId'] as int,
                            quantite: item['quantite'] as int,
                          ))
                      .toList();

                  String? collectionPlanJson;
                  if (manualAssignments.isNotEmpty) {
                    collectionPlanJson =
                        _buildManualCollectionPlan(selectedItems, manualAssignments);
                  }

                  final provider = context.read<OrderProvider>();
                  final order = Order(
                    clientId: selectedClient!.id!,
                    latitudeLivraison: lat,
                    longitudeLivraison: lng,
                    adresseLivraison:
                        adresseController.text.isEmpty ? null : adresseController.text,
                    notes: notesController.text.isEmpty ? null : notesController.text,
                    status: 'pending',
                    items: items.isNotEmpty ? items : null,
                    collectionPlan: collectionPlanJson,
                  );
                  final success = await provider.createOrder(order);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            success ? 'Commande créée' : 'Erreur: ${provider.errorMessage}'),
                        backgroundColor: success ? AppColors.success : AppColors.error,
                      ),
                    );
                    if (success) provider.refreshCurrentPage();
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

  String _buildManualCollectionPlan(
    List<Map<String, dynamic>> selectedItems,
    Map<int, List<Map<String, dynamic>>> manualAssignments,
  ) {
    final Map<int, Map<String, dynamic>> depotSteps = {};
    for (final entry in manualAssignments.entries) {
      final productIdx = entry.key;
      final item = selectedItems[productIdx];
      for (final assignment in entry.value) {
        final depotId = assignment['depotId'] as int;
        depotSteps.putIfAbsent(
            depotId,
            () => {
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
          final selectedIds = selectedItems.map((e) => e['produitId']).toSet();

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Sélectionner un produit'),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.85,
              height: MediaQuery.of(context).size.height * 0.5,
              child: Column(
                children: [
                  TextField(
                    controller: searchController,
                    decoration: AppStyles.inputDecoration(
                        label: 'Rechercher...', prefixIcon: Icons.search),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(child: Text('Aucun produit', style: AppStyles.bodyMedium))
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final product = filtered[index];
                              final pid = product['produitId'];
                              final isSelected = selectedIds.contains(pid);
                              return ListTile(
                                leading: Icon(
                                    isSelected ? Icons.check_circle : Icons.inventory_2,
                                    color: isSelected ? AppColors.success : AppColors.primary),
                                title:
                                    Text(product['produitNom'] ?? 'Produit #$pid'),
                                subtitle: Text(
                                    'Prix: ${(product['prixHT'] ?? 0).toStringAsFixed(2)} TND | Stock: ${product['totalStock']}'),
                                enabled: !isSelected,
                                onTap: isSelected
                                    ? null
                                    : () {
                                        parentSetState(() {
                                          selectedItems.add({
                                            'produitId': pid,
                                            'produitNom': product['produitNom'],
                                            'prixHT': (product['prixHT'] ?? 0).toDouble(),
                                            'totalStock': product['totalStock'],
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
                  onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
            ],
          );
        },
      ),
    );
  }
}

class _StatusInfo {
  final String label;
  final IconData icon;
  final Color color;

  _StatusInfo(this.label, this.icon, this.color);
}
