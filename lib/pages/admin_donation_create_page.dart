import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/donations_service.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import '../services/categories_service.dart';
import '../services/brands_service.dart';
import '../theme/app_colors.dart';

class AdminDonationCreatePage extends StatefulWidget {
  const AdminDonationCreatePage({super.key});

  @override
  State<AdminDonationCreatePage> createState() => _AdminDonationCreatePageState();
}

class _AdminDonationCreatePageState extends State<AdminDonationCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _customerEmailController = TextEditingController();
  final _sizeController = TextEditingController();
  final _colorController = TextEditingController();
  final _originalPriceController = TextEditingController();

  String? _selectedCategoryId;
  String? _selectedBrandId;
  bool _isLoading = false;
  late DonationsService _donationsService;

  @override
  void initState() {
    super.initState();
    final api = Provider.of<ApiClient>(context, listen: false);
    _donationsService = DonationsService(api);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _customerEmailController.dispose();
    _sizeController.dispose();
    _colorController.dispose();
    _originalPriceController.dispose();
    super.dispose();
  }

  Future<void> _submitDonation() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    if (user?.staffId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Staff ID not found')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final donationData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'categoryId': _selectedCategoryId,
        if (_selectedBrandId != null) 'brandId': _selectedBrandId,
        if (_customerNameController.text.trim().isNotEmpty)
          'customerName': _customerNameController.text.trim(),
        if (_customerPhoneController.text.trim().isNotEmpty)
          'customerPhone': _customerPhoneController.text.trim(),
        if (_customerEmailController.text.trim().isNotEmpty)
          'customerEmail': _customerEmailController.text.trim(),
        if (_sizeController.text.trim().isNotEmpty) 'size': _sizeController.text.trim(),
        if (_colorController.text.trim().isNotEmpty) 'color': _colorController.text.trim(),
        if (_originalPriceController.text.trim().isNotEmpty)
          'originalPrice': double.tryParse(_originalPriceController.text.trim()),
      };

      await _donationsService.createDonation(donationData, user!.staffId!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Donation created successfully')),
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
          'Create New Donation',
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
                labelText: 'Product Name *',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value?.isEmpty ?? true ? 'Please enter product name' : null,
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description *',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) => value?.isEmpty ?? true ? 'Please enter description' : null,
            ),
            const SizedBox(height: 16),

            // Category
            Consumer<CategoriesService>(
              builder: (context, categoriesService, _) {
                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Category *',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedCategoryId,
                  items: categoriesService.categories.map((category) {
                    return DropdownMenuItem(
                      value: category.categoryId,
                      child: Text(category.name),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedCategoryId = value),
                  validator: (value) => value == null ? 'Please select a category' : null,
                );
              },
            ),
            const SizedBox(height: 16),

            // Brand
            Consumer<BrandsService>(
              builder: (context, brandsService, _) {
                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Brand',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedBrandId,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('None')),
                    ...brandsService.brands.map((brand) {
                      return DropdownMenuItem(
                        value: brand.brandId,
                        child: Text(brand.name),
                      );
                    }),
                  ],
                  onChanged: (value) => setState(() => _selectedBrandId = value),
                );
              },
            ),
            const SizedBox(height: 16),

            // Customer Name
            TextFormField(
              controller: _customerNameController,
              decoration: const InputDecoration(
                labelText: 'Customer Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Customer Phone
            TextFormField(
              controller: _customerPhoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),

            // Customer Email
            TextFormField(
              controller: _customerEmailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            // Size
            TextFormField(
              controller: _sizeController,
              decoration: const InputDecoration(
                labelText: 'Size',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Color
            TextFormField(
              controller: _colorController,
              decoration: const InputDecoration(
                labelText: 'Color',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Original Price
            TextFormField(
              controller: _originalPriceController,
              decoration: const InputDecoration(
                labelText: 'Original Price',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitDonation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Create Donation',
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

