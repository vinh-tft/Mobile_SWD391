import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/categories_service.dart';
import '../services/api_client.dart';
import '../theme/app_colors.dart';
import '../models/api_models.dart';

class AdminCategoryCreatePage extends StatefulWidget {
  const AdminCategoryCreatePage({super.key});

  @override
  State<AdminCategoryCreatePage> createState() => _AdminCategoryCreatePageState();
}

class _AdminCategoryCreatePageState extends State<AdminCategoryCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _displayOrderController = TextEditingController();

  String? _selectedParentCategoryId;
  bool _isActive = true;
  bool _isLoading = false;
  late CategoriesService _categoriesService;

  @override
  void initState() {
    super.initState();
    final api = Provider.of<ApiClient>(context, listen: false);
    _categoriesService = CategoriesService(api);
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _displayOrderController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    await _categoriesService.loadCategories();
  }

  Future<void> _createCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final categoryData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'parentCategoryId': _selectedParentCategoryId,
        'displayOrder': _displayOrderController.text.trim().isNotEmpty
            ? int.tryParse(_displayOrderController.text.trim()) ?? 0
            : 0,
        'isActive': _isActive,
      };

      final success = await _categoriesService.createCategoryWithMap(categoryData);
      if (!success) {
        throw Exception(_categoriesService.error ?? 'Unable to create category');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category created successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
        title: const Text(
          'Create New Category',
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
            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Category Name *',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value?.isEmpty ?? true ? 'Please enter category name' : null,
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Parent Category
            Consumer<CategoriesService>(
              builder: (context, categoriesService, _) {
                final rootCategories = categoriesService.categories
                    .where((c) => c.isRootCategory)
                    .toList();

                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Parent Category (optional)',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedParentCategoryId,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('None (root category)')),
                    ...rootCategories.map((category) {
                      return DropdownMenuItem(
                        value: category.categoryId,
                        child: Text(category.name),
                      );
                    }),
                  ],
                  onChanged: (value) => setState(() => _selectedParentCategoryId = value),
                );
              },
            ),
            const SizedBox(height: 16),

            // Display Order
            TextFormField(
              controller: _displayOrderController,
              decoration: const InputDecoration(
                labelText: 'Display Order',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Active Checkbox
            CheckboxListTile(
              title: const Text('Active'),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value ?? false),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createCategory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Create Category',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

