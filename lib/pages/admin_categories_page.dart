import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/categories_service.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import '../theme/app_colors.dart';
import '../models/api_models.dart';
// Removed imports - categories are read-only

class AdminCategoriesPage extends StatefulWidget {
  const AdminCategoriesPage({super.key});

  @override
  State<AdminCategoriesPage> createState() => _AdminCategoriesPageState();
}

class _AdminCategoriesPageState extends State<AdminCategoriesPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  Set<String> _expandedCategories = {};

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      await context.read<CategoriesService>().loadCategories();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _searchCategories() async {
    if (_searchController.text.trim().isEmpty) {
      _loadCategories();
      return;
    }

    setState(() => _isLoading = true);
    try {
      final categoriesService = context.read<CategoriesService>();
      await categoriesService.searchCategories(_searchController.text.trim());
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching: $e')),
        );
      }
    }
  }

  void _toggleExpand(String categoryId) {
    setState(() {
      if (_expandedCategories.contains(categoryId)) {
        _expandedCategories.remove(categoryId);
      } else {
        _expandedCategories.add(categoryId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    // Check if user is admin
    if (user == null || !authService.isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Access Denied'),
        ),
        body: const Center(
          child: Text('Only admin can access this page'),
        ),
      );
    }

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
          'Manage Categories',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        // Removed add button - categories are read-only for admin/staff
      ),
      body: RefreshIndicator(
        onRefresh: _loadCategories,
        color: AppColors.primary,
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search categories...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onSubmitted: (_) => _searchCategories(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _searchCategories,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Stats Cards
            Consumer<CategoriesService>(
              builder: (context, categoriesService, _) {
                final categories = categoriesService.categories;
                final stats = {
                  'total': categories.length,
                  'root': categories.where((c) => c.isRootCategory).length,
                  'sub': categories.where((c) => !c.isRootCategory).length,
                };

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard('Total', stats['total']!, Icons.category, AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard('Root Categories', stats['root']!, Icons.folder, AppColors.success),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard('Sub Categories', stats['sub']!, Icons.folder_open, AppColors.info),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Categories List
            Expanded(
              child: Consumer<CategoriesService>(
                builder: (context, categoriesService, _) {
                  if (_isLoading && categoriesService.categories.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final categories = categoriesService.categories;
                  final filteredCategories = _searchController.text.trim().isEmpty
                      ? categories
                      : categories.where((category) {
                          final query = _searchController.text.toLowerCase();
                          return category.name.toLowerCase().contains(query) ||
                              category.description.toLowerCase().contains(query);
                        }).toList();

                  if (filteredCategories.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.category_outlined, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No categories found',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  }

                  // Group categories by parent
                  final rootCategories = filteredCategories.where((c) => c.isRootCategory).toList();
                  final subCategoriesMap = <String, List<CategoryResponse>>{};
                  
                  for (var category in filteredCategories) {
                    if (!category.isRootCategory && category.parentCategoryId != null) {
                      final parentId = category.parentCategoryId!;
                      if (!subCategoriesMap.containsKey(parentId)) {
                        subCategoriesMap[parentId] = [];
                      }
                      subCategoriesMap[parentId]!.add(category);
                    }
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: rootCategories.length,
                    itemBuilder: (context, index) {
                      final category = rootCategories[index];
                      final isExpanded = _expandedCategories.contains(category.categoryId);
                      final subCategories = subCategoriesMap[category.categoryId] ?? [];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          children: [
                            ListTile(
                              leading: Icon(
                                isExpanded ? Icons.folder_open : Icons.folder,
                                color: AppColors.primary,
                              ),
                              title: Text(
                                category.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: category.description.isNotEmpty
                                  ? Text(
                                      category.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  : null,
                              trailing: subCategories.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                                      onPressed: () => _toggleExpand(category.categoryId),
                                    )
                                  : null,
                            ),
                            if (isExpanded && subCategories.isNotEmpty)
                              ...subCategories.map((subCategory) {
                                return Padding(
                                  padding: const EdgeInsets.only(left: 16),
                                  child: ListTile(
                                    leading: const Icon(Icons.subdirectory_arrow_right, size: 20),
                                    title: Text(subCategory.name),
                                    subtitle: subCategory.description.isNotEmpty
                                        ? Text(
                                            subCategory.description,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          )
                                        : null,
                                    // Read-only: No edit button
                                  ),
                                );
                              }).toList(),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, int value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value.toString(),
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
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

