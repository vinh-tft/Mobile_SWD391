import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/brands_service.dart';
import '../services/api_client.dart';
import '../theme/app_colors.dart';
import '../models/api_models.dart';

class AdminBrandEditPage extends StatefulWidget {
  final BrandResponse brand;

  const AdminBrandEditPage({super.key, required this.brand});

  @override
  State<AdminBrandEditPage> createState() => _AdminBrandEditPageState();
}

class _AdminBrandEditPageState extends State<AdminBrandEditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _logoUrlController;
  late TextEditingController _websiteController;
  late TextEditingController _sustainabilityRatingController;

  late bool _isVerified;
  late bool _isPartner;
  late bool _isActive;
  bool _isLoading = false;
  late BrandsService _brandsService;

  @override
  void initState() {
    super.initState();
    final api = Provider.of<ApiClient>(context, listen: false);
    _brandsService = BrandsService(api);

    _nameController = TextEditingController(text: widget.brand.name);
    _descriptionController = TextEditingController(text: widget.brand.description);
    _logoUrlController = TextEditingController(text: widget.brand.logoUrl ?? '');
    _websiteController = TextEditingController(text: widget.brand.websiteUrl ?? '');
    _sustainabilityRatingController = TextEditingController(text: '0'); // Not available in BrandResponse
    _isVerified = widget.brand.isVerified ?? false;
    _isPartner = widget.brand.isPartner ?? false;
    _isActive = widget.brand.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _logoUrlController.dispose();
    _websiteController.dispose();
    _sustainabilityRatingController.dispose();
    super.dispose();
  }

  Future<void> _updateBrand() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final brandData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        'logoUrl': _logoUrlController.text.trim().isNotEmpty
            ? _logoUrlController.text.trim()
            : null,
        'websiteUrl': _websiteController.text.trim().isNotEmpty
            ? _websiteController.text.trim()
            : null,
        'isVerified': _isVerified,
        'isSustainable': widget.brand.isSustainable,
        'isPartner': _isPartner,
        'isActive': _isActive,
      };

      final success = await _brandsService.updateBrand(widget.brand.brandId, brandData);
      if (!success) {
        throw Exception(_brandsService.error ?? 'Unable to update brand');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Brand updated successfully')),
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
          'Edit Brand',
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
                labelText: 'Brand Name *',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value?.isEmpty ?? true ? 'Please enter brand name' : null,
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

            // Logo URL
            TextFormField(
              controller: _logoUrlController,
              decoration: const InputDecoration(
                labelText: 'Logo URL',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),

            // Website
            TextFormField(
              controller: _websiteController,
              decoration: const InputDecoration(
                labelText: 'Website',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),

            // Sustainability Rating
            TextFormField(
              controller: _sustainabilityRatingController,
              decoration: const InputDecoration(
                labelText: 'Sustainability Rating (0-5)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Checkboxes
            CheckboxListTile(
              title: const Text('Verified'),
              value: _isVerified,
              onChanged: (value) => setState(() => _isVerified = value ?? false),
            ),
            CheckboxListTile(
              title: const Text('Partner'),
              value: _isPartner,
              onChanged: (value) => setState(() => _isPartner = value ?? false),
            ),
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
                onPressed: _isLoading ? null : _updateBrand,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Update Brand',
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

