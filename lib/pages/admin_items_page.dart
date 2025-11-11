import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/items_service.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../models/api_models.dart';
import 'create_listing_page.dart';
import 'product_detail_page.dart';

class AdminItemsPage extends StatefulWidget {
  const AdminItemsPage({super.key});

  @override
  State<AdminItemsPage> createState() => _AdminItemsPageState();
}

class _AdminItemsPageState extends State<AdminItemsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'all';
  bool _isLoading = false;

  final Map<String, String> _statusFilters = {
    'all': 'Tất cả',
    'VERIFIED': 'Đã xác minh',
    'PENDING_VERIFICATION': 'Chờ xác minh',
    'DRAFT': 'Nháp',
    'SOLD': 'Đã bán',
  };

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    await context.read<ItemsService>().loadItems();
    setState(() => _isLoading = false);
  }

  List<ItemSummaryResponse> _getFilteredItems(List<ItemSummaryResponse> items) {
    var filtered = items;

    // Filter by status
    if (_selectedStatus != 'all') {
      filtered = filtered.where((item) => 
        item.status.toString().split('.').last == _selectedStatus
      ).toList();
    }

    // Filter by search
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((item) => 
        item.name.toLowerCase().contains(query) ||
        (item.brandName?.toLowerCase().contains(query) ?? false)
      ).toList();
    }

    return filtered;
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
          'Quản lý sản phẩm',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateListingPage()),
              ).then((_) => _loadItems());
            },
          ),
        ],
      ),
      body: Consumer<ItemsService>(
        builder: (context, itemsService, _) {
          return RefreshIndicator(
            onRefresh: _loadItems,
            color: AppColors.primary,
            child: Column(
              children: [
                // Stats Cards
                _buildStatsCards(itemsService.items),
                
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

  Widget _buildStatsCards(List<ItemSummaryResponse> allItems) {
    final stats = {
      'total': allItems.length,
      'verified': allItems.where((i) => i.status == ItemStatus.VERIFIED).length,
      'pending': allItems.where((i) => i.status == ItemStatus.PENDING_VERIFICATION).length,
      'sold': allItems.where((i) => i.status == ItemStatus.SOLD).length,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(child: _buildStatCard('Tổng số', stats['total']!, Icons.inventory_2, AppColors.primary)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard('Đã xác minh', stats['verified']!, Icons.verified, AppColors.success)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard('Chờ', stats['pending']!, Icons.pending, AppColors.warning)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard('Đã bán', stats['sold']!, Icons.check_circle, AppColors.info)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int value, IconData icon, Color color) {
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
            '$value',
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
                      hintText: 'Tìm kiếm sản phẩm...',
                      hintStyle: TextStyle(color: AppColors.mutedForeground),
                      border: InputBorder.none,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.clear, color: AppColors.mutedForeground, size: 20),
                    onPressed: () {
                      setState(() => _searchController.clear());
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Status Filter
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _statusFilters.length,
              itemBuilder: (context, index) {
                final entry = _statusFilters.entries.elementAt(index);
                final isSelected = _selectedStatus == entry.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(entry.value),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _selectedStatus = entry.key);
                    },
                    backgroundColor: AppColors.card,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.foreground,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 13,
                    ),
                    side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
                  ),
                );
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

    final filteredItems = _getFilteredItems(itemsService.items);

    if (filteredItems.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        return _buildItemCard(item);
      },
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
                const SizedBox(width: 16),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.foreground,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (item.brandName != null)
                        Text(
                          item.brandName!,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildStatusBadge(item.status),
                          const SizedBox(width: 8),
                          _buildConditionBadge(item.condition),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.stars_rounded, color: AppColors.primary, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${item.pointValue} điểm',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Size: ${item.size}',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                        ],
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
                          builder: (context) => ProductDetailPage(
                            title: item.name,
                            price: '${item.pointValue} điểm',
                            rating: '4.5',
                            description: item.description,
                            images: item.primaryImageUrl != null ? [item.primaryImageUrl!] : [],
                            seller: item.ownerName,
                            condition: item.condition.toString().split('.').last,
                            size: item.size,
                            brand: item.brandName ?? '',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('Xem'),
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
                      // Edit item
                      _showEditDialog(item);
                    },
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Sửa'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.warning,
                      side: BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {
                    _showDeleteDialog(item);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.destructive,
                    side: BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.all(12),
                  ),
                  child: const Icon(Icons.delete_outline, size: 20),
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
      case ItemStatus.VERIFIED:
        color = AppColors.success;
        label = 'Đã xác minh';
        break;
      case ItemStatus.PENDING_VERIFICATION:
        color = AppColors.warning;
        label = 'Chờ xác minh';
        break;
      case ItemStatus.SOLD:
        color = AppColors.info;
        label = 'Đã bán';
        break;
      case ItemStatus.REJECTED:
        color = AppColors.destructive;
        label = 'Từ chối';
        break;
      default:
        color = AppColors.mutedForeground;
        label = 'Nháp';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
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

  Widget _buildConditionBadge(ItemCondition condition) {
    final labels = {
      ItemCondition.EXCELLENT: 'Xuất sắc',
      ItemCondition.GOOD: 'Tốt',
      ItemCondition.FAIR: 'Khá',
      ItemCondition.POOR: 'Kém',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        labels[condition] ?? condition.toString(),
        style: TextStyle(
          color: AppColors.mutedForeground,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
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
              'Không tìm thấy sản phẩm',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.foreground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Thử thay đổi bộ lọc hoặc thêm sản phẩm mới',
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
        title: const Text('Chỉnh sửa sản phẩm'),
        content: const Text('Tính năng chỉnh sửa sẽ được phát triển sớm.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(ItemSummaryResponse item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: AppColors.destructive),
            const SizedBox(width: 8),
            const Text('Xóa sản phẩm'),
          ],
        ),
        content: Text('Bạn có chắc muốn xóa "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await context.read<ItemsService>().deleteItem(item.itemId);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Đã xóa sản phẩm'),
                    backgroundColor: AppColors.success,
                  ),
                );
                _loadItems();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.destructive,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}

