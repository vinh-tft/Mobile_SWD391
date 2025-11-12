import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/items_service.dart';
import '../theme/app_colors.dart';
import '../models/api_models.dart';

class AdminItemDetailPage extends StatefulWidget {
  final String itemId;

  const AdminItemDetailPage({
    super.key,
    required this.itemId,
  });

  @override
  State<AdminItemDetailPage> createState() => _AdminItemDetailPageState();
}

class _AdminItemDetailPageState extends State<AdminItemDetailPage> {
  ItemResponse? _item;
  bool _loading = true;
  String? _error;
  bool _showEditModal = false;
  bool _saving = false;

  // Edit form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _sizeController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _conditionScoreController = TextEditingController();
  final TextEditingController _conditionDescriptionController = TextEditingController();
  final TextEditingController _originalPriceController = TextEditingController();
  final TextEditingController _currentEstimatedValueController = TextEditingController();
  final TextEditingController _resellPriceController = TextEditingController();
  String _selectedItemStatus = 'SUBMITTED';

  @override
  void initState() {
    super.initState();
    _loadItem();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _sizeController.dispose();
    _colorController.dispose();
    _conditionScoreController.dispose();
    _conditionDescriptionController.dispose();
    _originalPriceController.dispose();
    _currentEstimatedValueController.dispose();
    _resellPriceController.dispose();
    super.dispose();
  }

  Future<void> _loadItem() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final itemsService = context.read<ItemsService>();
      final item = await itemsService.getItemById(widget.itemId);
      
      if (mounted) {
        setState(() {
          _item = item;
          _loading = false;
          if (item != null) {
            _initializeEditForm(item);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _initializeEditForm(ItemResponse item) {
    _nameController.text = item.name;
    _descriptionController.text = item.description;
    _sizeController.text = item.size;
    _colorController.text = item.color;
    _conditionScoreController.text = item.conditionScore?.toString() ?? '';
    _conditionDescriptionController.text = item.conditionDescription ?? '';
    _originalPriceController.text = item.originalPrice?.toString() ?? '';
    _currentEstimatedValueController.text = item.currentEstimatedValue?.toString() ?? '';
    _resellPriceController.text = item.resellPrice?.toString() ?? '';
    _selectedItemStatus = item.status.toString().split('.').last;
  }

  Future<void> _saveEdit() async {
    if (_item == null) return;

    setState(() => _saving = true);

    try {
      final updateData = <String, dynamic>{
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'size': _sizeController.text.trim(),
        'color': _colorController.text.trim(),
        if (_conditionScoreController.text.isNotEmpty)
          'conditionScore': double.tryParse(_conditionScoreController.text),
        if (_conditionDescriptionController.text.isNotEmpty)
          'conditionDescription': _conditionDescriptionController.text.trim(),
        if (_originalPriceController.text.isNotEmpty)
          'originalPrice': double.tryParse(_originalPriceController.text),
        if (_currentEstimatedValueController.text.isNotEmpty)
          'currentEstimatedValue': double.tryParse(_currentEstimatedValueController.text),
        if (_resellPriceController.text.isNotEmpty)
          'resellPrice': double.tryParse(_resellPriceController.text),
        'itemStatus': _selectedItemStatus,
      };

      final itemsService = context.read<ItemsService>();
      final updatedItem = await itemsService.updateItem(_item!.itemId, updateData);

      if (updatedItem != null && mounted) {
        setState(() {
          _item = updatedItem;
          _showEditModal = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Product updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.destructive,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Color _getConditionColor(double? score) {
    if (score == null) return Colors.grey;
    if (score >= 4.5) return Colors.green;
    if (score >= 3.5) return Colors.orange;
    if (score >= 2.5) return Colors.orange;
    return Colors.red;
  }

  Color _getStatusColor(ItemStatus status) {
    switch (status) {
      case ItemStatus.LISTED:
      case ItemStatus.READY_FOR_SALE:
        return AppColors.success;
      case ItemStatus.SOLD:
        return AppColors.success;
      case ItemStatus.PENDING_COLLECTION:
      case ItemStatus.VALUING:
        return AppColors.warning;
      default:
        return AppColors.mutedForeground;
    }
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
        title: _item != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _item!.displayName ?? _item!.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_item!.itemCode != null)
                    Text(
                      'ID: ${_item!.itemCode}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                ],
              )
            : const Text(
                'Product Details',
                style: TextStyle(color: Colors.white),
              ),
        actions: [
          if (_item != null)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () {
                _initializeEditForm(_item!);
                setState(() => _showEditModal = true);
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null || _item == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.destructive),
              const SizedBox(height: 16),
              Text(
                _error ?? 'Product not found',
                style: TextStyle(color: AppColors.foreground),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      );
    }

    final item = _item!;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Images Section
              _buildSectionCard(
                icon: Icons.camera_alt,
                title: 'Images (${item.imageUrls.length})',
                child: item.imageUrls.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'No images',
                          style: TextStyle(color: AppColors.mutedForeground),
                        ),
                      )
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: item.imageUrls.length,
                        itemBuilder: (context, index) {
                          final isPrimary = index == 0;
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  item.imageUrls[index],
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: AppColors.muted,
                                    child: Icon(Icons.image, color: AppColors.mutedForeground),
                                  ),
                                ),
                              ),
                              if (isPrimary)
                                Positioned(
                                  top: 4,
                                  left: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.amber,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.star, size: 12, color: Colors.white),
                                        const SizedBox(width: 2),
                                        Text(
                                          'Primary',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
              ),

              const SizedBox(height: 16),

              // Basic Information
              _buildSectionCard(
                icon: Icons.inventory_2,
                title: 'Basic Information',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Category', item.categoryName ?? 'N/A'),
                    _buildInfoRow('Brand', item.brandName ?? 'N/A'),
                    _buildInfoRow('Size', item.size),
                    _buildInfoRow('Color', item.color),
                    if (item.weightGrams != null)
                      _buildInfoRow('Weight', '${item.weightGrams}g'),
                    if (item.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        style: TextStyle(color: AppColors.foreground),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Pricing & Valuation
              _buildSectionCard(
                icon: Icons.attach_money,
                title: 'Pricing & Valuation',
                child: Row(
                  children: [
                    if (item.originalPrice != null)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Original Price',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.mutedForeground,
                              ),
                            ),
                            Text(
                              '\$${item.originalPrice!.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.foreground,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (item.currentEstimatedValue != null) ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Estimated Value',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.mutedForeground,
                              ),
                            ),
                            Text(
                              '\$${item.currentEstimatedValue!.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (item.resellPrice != null) ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Resell Price',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.mutedForeground,
                              ),
                            ),
                            Text(
                              '\$${item.resellPrice!.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Condition
              _buildSectionCard(
                icon: Icons.star,
                title: 'Condition',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Stars
                        Row(
                          children: List.generate(5, (index) {
                            final starValue = index + 1;
                            return Icon(
                              Icons.star,
                              size: 24,
                              color: item.conditionScore != null &&
                                      starValue <= item.conditionScore!.round()
                                  ? Colors.amber
                                  : Colors.grey[300],
                              fill: item.conditionScore != null &&
                                      starValue <= item.conditionScore!.round()
                                  ? 1.0
                                  : 0.0,
                            );
                          }),
                        ),
                        const SizedBox(width: 12),
                        if (item.conditionScore != null)
                          Text(
                            item.conditionScore!.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.foreground,
                            ),
                          ),
                        const SizedBox(width: 12),
                        if (item.conditionText != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getConditionColor(item.conditionScore).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: _getConditionColor(item.conditionScore)),
                            ),
                            child: Text(
                              item.conditionText!,
                              style: TextStyle(
                                color: _getConditionColor(item.conditionScore),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (item.conditionDescription != null &&
                        item.conditionDescription!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        item.conditionDescription!,
                        style: TextStyle(color: AppColors.foreground),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Status & Verification
              _buildSectionCard(
                icon: Icons.info,
                title: 'Status',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      'Status',
                      item.status.toString().split('.').last.replaceAll('_', ' '),
                      badge: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(item.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: _getStatusColor(item.status)),
                        ),
                        child: Text(
                          item.status.toString().split('.').last.replaceAll('_', ' '),
                          style: TextStyle(
                            color: _getStatusColor(item.status),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'Verification',
                      item.isVerified == true ? 'Verified' : 'Pending Verification',
                      badge: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (item.isVerified == true ? AppColors.success : AppColors.warning)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: item.isVerified == true ? AppColors.success : AppColors.warning,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 12,
                              color: item.isVerified == true ? AppColors.success : AppColors.warning,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item.isVerified == true ? 'Verified' : 'Pending',
                              style: TextStyle(
                                color: item.isVerified == true ? AppColors.success : AppColors.warning,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Ownership
              _buildSectionCard(
                icon: Icons.person,
                title: 'Ownership',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Original Owner', item.originalOwnerName ?? item.ownerName),
                    _buildInfoRow('Current Owner', item.currentOwnerName ?? item.ownerName),
                    if (item.acquisitionMethod != null)
                      _buildInfoRow(
                        'Method',
                        item.acquisitionMethod!.replaceAll('_', ' '),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Timeline
              _buildSectionCard(
                icon: Icons.access_time,
                title: 'Timeline',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Created Date', _formatDateTime(item.createdAt)),
                    if (item.verifiedAt != null)
                      _buildInfoRow('Verified Date', _formatDateTime(item.verifiedAt!)),
                    _buildInfoRow('Last Updated', _formatDateTime(item.updatedAt)),
                  ],
                ),
              ),

              // Tags
              if (item.tags.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildSectionCard(
                  icon: Icons.label,
                  title: 'Tags',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: item.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.muted,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            color: AppColors.foreground,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
        // Edit Modal
        if (_showEditModal) _buildEditModal(),
      ],
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.foreground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Widget? badge}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.mutedForeground,
              ),
            ),
          ),
          Expanded(
            child: badge ??
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.foreground,
                  ),
                ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildEditModal() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
          ),
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Edit Product',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.foreground,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _showEditModal = false),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Product Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        maxLines: 4,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _sizeController,
                              decoration: InputDecoration(
                                labelText: 'Size',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _colorController,
                              decoration: InputDecoration(
                                labelText: 'Color',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _conditionScoreController,
                        decoration: InputDecoration(
                          labelText: 'Condition Score (1-5)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _conditionDescriptionController,
                        decoration: InputDecoration(
                          labelText: 'Condition Description',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedItemStatus,
                        decoration: InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: [
                          'SUBMITTED',
                          'PENDING_COLLECTION',
                          'COLLECTED',
                          'VALUING',
                          'VALUED',
                          'PROCESSING',
                          'READY_FOR_SALE',
                          'LISTED',
                          'SOLD',
                          'RENTED',
                          'DONATED',
                          'RECYCLED',
                          'REJECTED',
                        ].map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(status.replaceAll('_', ' ')),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedItemStatus = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _originalPriceController,
                              decoration: InputDecoration(
                                labelText: 'Original Price (\$)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _currentEstimatedValueController,
                              decoration: InputDecoration(
                                labelText: 'Estimated Value (\$)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _resellPriceController,
                              decoration: InputDecoration(
                                labelText: 'Resell Price (\$)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _saving ? null : () => setState(() => _showEditModal = false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _saving ? null : _saveEdit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

