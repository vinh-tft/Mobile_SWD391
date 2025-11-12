import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../services/items_service.dart';
import '../services/categories_service.dart';
import '../services/brands_service.dart';
import '../services/users_service.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import '../theme/app_colors.dart';
import '../models/api_models.dart';

class AdminItemCreatePage extends StatefulWidget {
  const AdminItemCreatePage({super.key});

  @override
  State<AdminItemCreatePage> createState() => _AdminItemCreatePageState();
}

class _AdminItemCreatePageState extends State<AdminItemCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _sizeController = TextEditingController();
  final _colorController = TextEditingController();
  final _weightController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _currentEstimatedValueController = TextEditingController();
  final _resellPriceController = TextEditingController();
  final _conditionDescriptionController = TextEditingController();
  final _userSearchController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();
  List<XFile> _images = [];
  Map<String, Uint8List> _imageBytes = {}; // Store image bytes for web
  String? _selectedCategoryId;
  String? _selectedBrandId;
  String? _selectedUserId;
  Map<String, dynamic>? _selectedUser;
  ItemCondition _selectedCondition = ItemCondition.EXCELLENT;
  double _conditionScore = 5.0;
  String _acquisitionMethod = 'COLLECTED';
  String _itemStatus = 'SUBMITTED';

  List<CategoryResponse> _categories = [];
  List<BrandResponse> _brands = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _showUserDropdown = false;
  bool _isSearchingUsers = false;
  Timer? _searchTimer;

  bool _isLoading = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadBrands();
    _userSearchController.addListener(_onUserSearchChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _sizeController.dispose();
    _colorController.dispose();
    _weightController.dispose();
    _originalPriceController.dispose();
    _currentEstimatedValueController.dispose();
    _resellPriceController.dispose();
    _conditionDescriptionController.dispose();
    _userSearchController.removeListener(_onUserSearchChanged);
    _userSearchController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  void _onUserSearchChanged() {
    _searchTimer?.cancel();
    if (_userSearchController.text.trim().length < 2) {
      setState(() {
        _filteredUsers = [];
        _showUserDropdown = false;
      });
      return;
    }

    _searchTimer = Timer(const Duration(milliseconds: 300), () {
      _searchUsers(_userSearchController.text.trim());
    });
  }

  Future<void> _loadCategories() async {
    try {
      final categoriesService = context.read<CategoriesService>();
      await categoriesService.loadActiveCategories();
      setState(() => _categories = categoriesService.categories);
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  Future<void> _loadBrands() async {
    try {
      final brandsService = context.read<BrandsService>();
      await brandsService.loadActiveBrands();
      setState(() => _brands = brandsService.brands);
    } catch (e) {
      print('Error loading brands: $e');
    }
  }

  Future<void> _searchUsers(String keyword) async {
    if (keyword.length < 2) return;

    setState(() {
      _isSearchingUsers = true;
      _showUserDropdown = false;
    });

    try {
      final usersService = UsersService(context.read<ApiClient>());
      final users = await usersService.searchUsers(keyword);
      setState(() {
        _filteredUsers = users;
        _showUserDropdown = users.isNotEmpty;
        _isSearchingUsers = false;
      });
    } catch (e) {
      setState(() {
        _isSearchingUsers = false;
        _showUserDropdown = false;
      });
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> pickedFiles = await _imagePicker.pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        final remaining = 10 - _images.length;
        final newImages = pickedFiles.take(remaining).toList();
        
        // Load image bytes for web platform
        if (kIsWeb) {
          for (final image in newImages) {
            final bytes = await image.readAsBytes();
            _imageBytes[image.path] = bytes;
          }
        }
        
        setState(() {
          _images.addAll(newImages);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting image: $e')),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      final image = _images[index];
      _imageBytes.remove(image.path);
      _images.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authService = context.read<AuthService>();
      final user = authService.currentUser;
      if (user == null) {
        throw Exception('You need to login');
      }

      final ownerId = _selectedUserId ?? user.id;

      // Calculate point value from estimated value (simplified)
      final estimatedValue = double.tryParse(_currentEstimatedValueController.text) ?? 0;
      final pointValue = (estimatedValue * 10).round(); // 1$ = 10 points

      // Map condition score to ItemCondition enum
      ItemCondition condition;
      if (_conditionScore >= 4.5) {
        condition = ItemCondition.EXCELLENT;
      } else if (_conditionScore >= 3.5) {
        condition = ItemCondition.GOOD;
      } else if (_conditionScore >= 2.5) {
        condition = ItemCondition.FAIR;
      } else {
        condition = ItemCondition.POOR;
      }

      // Prepare item data matching backend ItemCreateRequest
      // Backend fields: categoryId, brandId, name, description, size, color,
      // conditionScore, conditionDescription, originalPrice, currentEstimatedValue,
      // weightGrams, acquisitionMethod, images, videos, tags
      final itemData = <String, dynamic>{
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'categoryId': _selectedCategoryId!,
        if (_selectedBrandId != null && _selectedBrandId!.isNotEmpty) 'brandId': _selectedBrandId,
        'size': _sizeController.text.trim().isEmpty ? 'N/A' : _sizeController.text.trim(),
        'color': _colorController.text.trim().isEmpty ? 'N/A' : _colorController.text.trim(),
        'conditionScore': _conditionScore, // BigDecimal in backend
        if (_conditionDescriptionController.text.trim().isNotEmpty)
          'conditionDescription': _conditionDescriptionController.text.trim(),
        if (_originalPriceController.text.trim().isNotEmpty)
          'originalPrice': double.tryParse(_originalPriceController.text),
        'currentEstimatedValue': estimatedValue, // BigDecimal in backend
        if (_weightController.text.trim().isNotEmpty)
          'weightGrams': int.tryParse(_weightController.text),
        'acquisitionMethod': _acquisitionMethod,
        'imageUrls': [], // Backend expects 'images' field, will be mapped in service
        'tags': [],
      };

      final itemsService = context.read<ItemsService>();
      
      // Create item with full admin fields
      final createdItem = await itemsService.createItemAsAdmin(itemData, ownerId);

      if (createdItem != null && mounted) {
        // Upload images if any
        if (_images.isNotEmpty) {
          try {
            // Convert XFile to File
            final imageFiles = <File>[];
            for (var xFile in _images) {
              if (!kIsWeb) {
                final file = File(xFile.path);
                if (await file.exists()) {
                  imageFiles.add(file);
                }
              } else {
                // For web, we need to convert Uint8List to File
                // This is a limitation - web doesn't support File.fromPath
                // We'll skip web upload for now or implement a workaround
                print('⚠️ Image upload on web is not fully supported yet');
              }
            }

            if (imageFiles.isNotEmpty) {
              print('📤 Uploading ${imageFiles.length} images...');
              final updatedItem = await itemsService.uploadItemImages(createdItem.itemId, imageFiles);
              if (updatedItem != null) {
                print('✅ Images uploaded successfully');
              } else {
                print('⚠️ Item created but images failed to upload: ${itemsService.error}');
              }
            }
          } catch (e) {
            print('⚠️ Error uploading images: $e');
            // Don't fail the whole operation if image upload fails
          }
        }

        // Show success dialog with item code
        _showSuccessDialog(createdItem.itemId, createdItem.itemCode ?? '');
      } else {
        throw Exception(itemsService.error ?? 'Unable to create item');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSuccessDialog(String itemId, String itemCode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle, color: AppColors.success, size: 32),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Item Created Successfully!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (itemCode.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.muted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tracking Code:',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      itemCode,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Icon(Icons.check, size: 16, color: AppColors.success),
                const SizedBox(width: 8),
                const Expanded(child: Text('Item created and verified')),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.check, size: 16, color: AppColors.success),
                const SizedBox(width: 8),
                const Expanded(child: Text('Tracking code generated')),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, true); // Return to items page
            },
            child: const Text('Back to Items'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              // Reset form
              _formKey.currentState?.reset();
              _images.clear();
              _selectedCategoryId = null;
              _selectedBrandId = null;
              _selectedUserId = null;
              _selectedUser = null;
              _userSearchController.clear();
              _conditionScore = 5.0;
              _acquisitionMethod = 'COLLECTED';
              _itemStatus = 'SUBMITTED';
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Create Another'),
          ),
        ],
      ),
    );
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
          'Tạo Item (Admin)',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Images Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.camera_alt, color: AppColors.primary),
                        const SizedBox(width: 8),
                        const Text(
                          'Photos',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add up to 10 images. The first image will be the primary image.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    if (_images.length < 10)
                      InkWell(
                        onTap: _pickImages,
                        child: Container(
                          height: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey, style: BorderStyle.solid, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.upload, size: 32, color: Colors.grey[600]),
                              const SizedBox(height: 8),
                              Text(
                                'Select Images (${_images.length}/10)',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (_images.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _images.asMap().entries.map((entry) {
                          final index = entry.key;
                          final image = entry.value;
                          return Stack(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: kIsWeb
                                      ? _imageBytes[image.path] != null
                                          ? Image.memory(
                                              _imageBytes[image.path]!,
                                              fit: BoxFit.cover,
                                            )
                                          : const Center(child: CircularProgressIndicator())
                                      : Image.file(
                                          File(image.path),
                                          fit: BoxFit.cover,
                                        ),
                                ),
                              ),
                              if (index == 0)
                                Positioned(
                                  top: 4,
                                  left: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.amber,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Primary',
                                      style: TextStyle(fontSize: 8, color: Colors.white),
                                    ),
                                  ),
                                ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removeImage(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, size: 16, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Basic Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Basic Information',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Item Name *',
                        hintText: 'e.g., Vintage Levi\'s Denim Jacket',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v?.isEmpty ?? true ? 'Please enter name' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description *',
                        hintText: 'Detailed description...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 4,
                      validator: (v) => (v?.isEmpty ?? true) || (v?.length ?? 0) < 10
                          ? 'Description must be at least 10 characters'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Category *',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories.map((cat) {
                        return DropdownMenuItem(
                          value: cat.categoryId,
                          child: Text(cat.name),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedCategoryId = value),
                      validator: (v) => v == null ? 'Please select a category' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedBrandId,
                      decoration: const InputDecoration(
                        labelText: 'Brand (optional)',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(value: '', child: Text('None')),
                        ..._brands.map((brand) {
                          return DropdownMenuItem(
                            value: brand.brandId,
                            child: Text(brand.name),
                          );
                        }),
                      ],
                      onChanged: (value) => setState(() => _selectedBrandId = value),
                    ),
                    const SizedBox(height: 16),
                    // User search
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Collect from user (optional)'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _userSearchController,
                          decoration: InputDecoration(
                            hintText: 'Search by email, phone, name... (minimum 2 characters)',
                            border: const OutlineInputBorder(),
                            suffixIcon: _isSearchingUsers
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  )
                                : _selectedUser != null
                                    ? IconButton(
                                        icon: const Icon(Icons.close),
                                        onPressed: () {
                                          setState(() {
                                            _selectedUser = null;
                                            _selectedUserId = null;
                                            _userSearchController.clear();
                                            _filteredUsers = [];
                                            _showUserDropdown = false;
                                          });
                                        },
                                      )
                                    : null,
                          ),
                          onTap: () {
                            if (_filteredUsers.isNotEmpty && !_isSearchingUsers) {
                              setState(() => _showUserDropdown = true);
                            }
                          },
                        ),
                        if (_showUserDropdown && _filteredUsers.isNotEmpty)
                          Container(
                            constraints: const BoxConstraints(maxHeight: 200),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _filteredUsers.length,
                              itemBuilder: (context, index) {
                                final user = _filteredUsers[index];
                                return ListTile(
                                  dense: true,
                                  title: Text(user['username'] ?? ''),
                                  subtitle: Text(user['email'] ?? ''),
                                  onTap: () {
                                    setState(() {
                                      _selectedUser = user;
                                      _selectedUserId = user['userId'];
                                      _userSearchController.text = '${user['username']} - ${user['email']}';
                                      _showUserDropdown = false;
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        if (_selectedUser != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '✓ Selected: ${_selectedUser!['username']}',
                              style: TextStyle(color: AppColors.success),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _sizeController,
                            decoration: const InputDecoration(
                              labelText: 'Size',
                              hintText: 'M, L, XL',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _colorController,
                            decoration: const InputDecoration(
                              labelText: 'Màu',
                              hintText: 'Blue, Black',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _weightController,
                      decoration: const InputDecoration(
                              labelText: 'Weight (grams)',
                        hintText: '500',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _acquisitionMethod,
                      decoration: const InputDecoration(
                        labelText: 'Acquisition Method *',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'COLLECTED', child: Text('Collected')),
                        DropdownMenuItem(value: 'PURCHASED', child: Text('Purchased')),
                        DropdownMenuItem(value: 'TRADED', child: Text('Traded')),
                        DropdownMenuItem(value: 'DONATED', child: Text('Donated')),
                        DropdownMenuItem(value: 'IMPORTED', child: Text('Imported')),
                      ],
                      onChanged: (value) => setState(() => _acquisitionMethod = value ?? 'COLLECTED'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _itemStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'SUBMITTED', child: Text('Submitted')),
                        DropdownMenuItem(value: 'PENDING_COLLECTION', child: Text('Pending Collection')),
                        DropdownMenuItem(value: 'COLLECTED', child: Text('Collected')),
                        DropdownMenuItem(value: 'READY_FOR_SALE', child: Text('Ready for Sale')),
                        DropdownMenuItem(value: 'LISTED', child: Text('Listed')),
                      ],
                      onChanged: (value) => setState(() => _itemStatus = value ?? 'SUBMITTED'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Condition & Pricing
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.attach_money, color: AppColors.primary),
                        const SizedBox(width: 8),
                        const Text(
                          'Condition & Pricing',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Condition Score (1-5) *'),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: _conditionScore.toString(),
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (v) {
                                        final score = double.tryParse(v);
                                        if (score != null && score >= 1 && score <= 5) {
                                          setState(() => _conditionScore = score);
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ...List.generate(5, (index) {
                                    return Icon(
                                      Icons.star,
                                      color: index < _conditionScore.round()
                                          ? Colors.amber
                                          : Colors.grey[300],
                                      size: 24,
                                    );
                                  }),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _conditionDescriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Condition Description',
                        hintText: 'e.g., Excellent, minor wear on sleeves',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _originalPriceController,
                            decoration: const InputDecoration(
                              labelText: 'Original Price (\$)',
                              hintText: '0.00',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _currentEstimatedValueController,
                            decoration: const InputDecoration(
                              labelText: 'Estimated Value (\$) *',
                              hintText: '0.00',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              final value = double.tryParse(v ?? '');
                              if (value == null || value < 0) {
                                return 'Please enter a valid value';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _resellPriceController,
                      decoration: const InputDecoration(
                        labelText: 'Resell Price (\$) *',
                        hintText: '0.00',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final value = double.tryParse(v ?? '');
                        if (value == null || value < 0) {
                          return 'Vui lòng nhập giá trị hợp lệ';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Create & Verify Item',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

