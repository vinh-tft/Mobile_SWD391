import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/items_service.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../models/api_models.dart';
import 'admin_item_create_page.dart';
import 'admin_item_detail_page.dart';

class AdminItemsPage extends StatefulWidget {
  const AdminItemsPage({super.key});

  @override
  State<AdminItemsPage> createState() => _AdminItemsPageState();
}

class _AdminItemsPageState extends State<AdminItemsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'all';
  bool _isLoading = false;
  int _currentPage = 0;
  int _totalPages = 0;
  Timer? _searchDebounce;
  
  Map<String, int> _stats = {
    'total': 0,
    'approved': 0,
    'pending': 0,
    'rejected': 0,
  };

  final Map<String, String> _statusFilters = {
    'all': 'All',
    'LISTED': 'Listed',
    'READY_FOR_SALE': 'Ready for Sale',
    'SUBMITTED': 'Submitted',
    'PENDING_COLLECTION': 'Pending Collection',
    'COLLECTED': 'Collected',
    'VALUED': 'Valued',
    'REJECTED': 'Rejected',
  };

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final itemsService = context.read<ItemsService>();
    final stats = await itemsService.getStatistics();
    if (mounted) {
      setState(() {
        _stats = stats;
      });
    }
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    final itemsService = context.read<ItemsService>();
    
    try {
      Map<String, dynamic> result;
      
      if (_searchController.text.isNotEmpty) {
        result = await itemsService.searchItemsPaginated(
          _searchController.text,
          page: _currentPage,
          size: 20,
        );
      } else if (_selectedStatus != 'all') {
        result = await itemsService.getItemsByStatusPaginated(
          _selectedStatus,
          page: _currentPage,
          size: 20,
        );
      } else {
        result = await itemsService.loadItemsPaginated(
          page: _currentPage,
          size: 20,
        );
      }
      
      if (mounted) {
        setState(() {
          _totalPages = result['totalPages'] ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleSearchChange(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _currentPage = 0;
      });
      _loadItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Manage Products',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminItemCreatePage()),
              );
              if (result == true) {
                _loadStats();
                _loadItems();
              }
            },
          ),
        ],
      ),
      body: Consumer<ItemsService>(
        builder: (context, itemsService, _) {
          return RefreshIndicator(
            onRefresh: () async {
              await _loadStats();
              await _loadItems();
            },
            color: AppColors.primary,
            child: Column(
              children: [
                // Stats Cards
                _buildStatsCards(),
                
                // Search and Filter
                _buildSearchAndFilter(),
                
                // Items List
                Expanded(
                  child: _buildItemsList(itemsService),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsCards() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Tổng số',
              _stats['total']!.toString(),
              Icons.inventory_2,
              AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Approved',
              _stats['approved']!.toString(),
              Icons.check_circle,
              AppColors.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Pending',
              _stats['pending']!.toString(),
              Icons.pending,
              AppColors.warning,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Rejected',
              _stats['rejected']!.toString(),
              Icons.cancel,
              AppColors.destructive,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.mutedForeground,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.input,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: AppColors.mutedForeground, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      hintStyle: TextStyle(color: AppColors.mutedForeground),
                      border: InputBorder.none,
                    ),
                    onChanged: _handleSearchChange,
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.clear, color: AppColors.mutedForeground, size: 20),
                    onPressed: () {
                      setState(() => _searchController.clear());
                      _currentPage = 0;
                      _loadItems();
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Status Filter Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.input,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButton<String>(
              value: _selectedStatus,
              isExpanded: true,
              underline: const SizedBox(),
              items: _statusFilters.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedStatus = value;
                    _currentPage = 0;
                  });
                  _loadItems();
                }
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildItemsList(ItemsService itemsService) {
    if (itemsService.loading || _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final items = itemsService.items;

    if (items.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildItemCard(item);
            },
          ),
        ),
        // Pagination
        if (_totalPages > 1)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _currentPage > 0
                      ? () {
                          setState(() => _currentPage--);
                          _loadItems();
                        }
                      : null,
                ),
                Text(
                  'Page ${_currentPage + 1} / $_totalPages',
                  style: TextStyle(color: AppColors.foreground),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _currentPage < _totalPages - 1
                      ? () {
                          setState(() => _currentPage++);
                          _loadItems();
                        }
                      : null,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildItemCard(ItemSummaryResponse item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Item Info Row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 80,
                        height: 80,
                        color: AppColors.muted,
                        child: item.primaryImageUrl != null
                            ? Image.network(
                                item.primaryImageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.image,
                                  color: AppColors.mutedForeground,
                                  size: 32,
                                ),
                              )
                            : Icon(
                                Icons.image,
                                color: AppColors.mutedForeground,
                                size: 32,
                              ),
                      ),
                    ),
                    if (item.isVerified == true)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.displayName ?? item.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.foreground,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (item.isVerified == true)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppColors.success),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle, size: 12, color: AppColors.success),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Verified',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Category, Brand, Size, Color
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (item.categoryName.isNotEmpty)
                            Text(
                              item.categoryName,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.mutedForeground,
                              ),
                            ),
                          if (item.brandName != null && item.brandName!.isNotEmpty) ...[
                            Text('•', style: TextStyle(color: AppColors.mutedForeground, fontSize: 12)),
                            Text(
                              item.brandName!,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.mutedForeground,
                              ),
                            ),
                          ],
                          if (item.size.isNotEmpty && item.size != 'N/A') ...[
                            Text('•', style: TextStyle(color: AppColors.mutedForeground, fontSize: 12)),
                            Text(
                              'Size ${item.size}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.mutedForeground,
                              ),
                            ),
                          ],
                          if (item.color.isNotEmpty && item.color != 'N/A') ...[
                            Text('•', style: TextStyle(color: AppColors.mutedForeground, fontSize: 12)),
                            Text(
                              item.color,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.mutedForeground,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Item Code and Condition Score
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (item.itemCode != null && item.itemCode!.isNotEmpty)
                            Text(
                              'Code: ${item.itemCode}',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.mutedForeground,
                              ),
                            ),
                          if (item.conditionScore != null) ...[
                            Text('•', style: TextStyle(color: AppColors.mutedForeground, fontSize: 11)),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star, size: 12, color: Colors.amber, fill: 1),
                                const SizedBox(width: 2),
                                Text(
                                  '${item.conditionScore!.toStringAsFixed(1)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.mutedForeground,
                                  ),
                                ),
                                if (item.conditionText != null) ...[
                                  Text(
                                    ' - ${item.conditionText}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.mutedForeground,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Price and Status Row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Est. Value',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.mutedForeground,
                                  ),
                                ),
                                Text(
                                  '\$${item.currentEstimatedValue?.toStringAsFixed(2) ?? '0.00'}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                if (item.resellPrice != null && item.resellPrice! > 0) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Resell Price',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.mutedForeground,
                                    ),
                                  ),
                                  Text(
                                    '\$${item.resellPrice!.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          _buildStatusBadge(item.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(item.createdAt),
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Action Buttons
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AdminItemDetailPage(itemId: item.itemId),
                        ),
                      ).then((_) {
                        // Reload items after returning from detail page
                        _loadStats();
                        _loadItems();
                      });
                    },
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.info,
                      side: BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AdminItemDetailPage(itemId: item.itemId),
                        ),
                      ).then((_) {
                        // Reload items after returning from detail page
                        _loadStats();
                        _loadItems();
                      });
                    },
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.warning,
                      side: BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ItemStatus status) {
    Color color;
    String label;

    switch (status) {
      case ItemStatus.LISTED:
      case ItemStatus.READY_FOR_SALE:
        color = AppColors.success;
        label = status.toString().split('.').last.replaceAll('_', ' ');
        break;
      case ItemStatus.SUBMITTED:
      case ItemStatus.PENDING_COLLECTION:
        color = AppColors.warning;
        label = status.toString().split('.').last.replaceAll('_', ' ');
        break;
      case ItemStatus.REJECTED:
        color = AppColors.destructive;
        label = status.toString().split('.').last.replaceAll('_', ' ');
        break;
      default:
        color = AppColors.mutedForeground;
        label = status.toString().split('.').last.replaceAll('_', ' ');
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.muted,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                color: AppColors.mutedForeground,
                size: 64,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No products found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.foreground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try changing filters or add new products',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(ItemSummaryResponse item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Product'),
        content: const Text('Edit feature will be developed soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

}
