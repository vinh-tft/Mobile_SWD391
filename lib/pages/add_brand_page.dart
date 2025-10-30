import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/brands_service.dart';
import '../models/api_models.dart';

class AddBrandPage extends StatefulWidget {
  const AddBrandPage({super.key});

  @override
  State<AddBrandPage> createState() => _AddBrandPageState();
}

class _AddBrandPageState extends State<AddBrandPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _logoUrlController = TextEditingController();
  final _websiteUrlController = TextEditingController();
  bool _isVerified = false;
  bool _isSustainable = false;
  bool _isPartner = false;
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _logoUrlController.dispose();
    _websiteUrlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final brandsService = context.read<BrandsService>();
      final success = await brandsService.createBrand(
        BrandCreateRequest(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          logoUrl: _logoUrlController.text.trim().isEmpty ? null : _logoUrlController.text.trim(),
          websiteUrl: _websiteUrlController.text.trim().isEmpty ? null : _websiteUrlController.text.trim(),
          isVerified: _isVerified,
          isSustainable: _isSustainable,
          isPartner: _isPartner,
          isActive: _isActive,
        ),
      );

      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Brand created successfully'), backgroundColor: Color(0xFF22C55E)),
        );
        Navigator.of(context).pop();
      } else {
        final errorMessage = brandsService.error ?? 'Failed to create brand';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFEF4444)),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Brand'),
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Brand information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF374151))),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Brand name *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.sell_outlined)),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter brand name' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder(), prefixIcon: Icon(Icons.description_outlined)),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _logoUrlController,
                        decoration: const InputDecoration(labelText: 'Logo URL (optional)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.image_outlined)),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _websiteUrlController,
                        decoration: const InputDecoration(labelText: 'Website URL (optional)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.public_outlined)),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(title: const Text('Verified'), value: _isVerified, onChanged: (v) => setState(() => _isVerified = v), activeColor: const Color(0xFF10B981)),
                      SwitchListTile(title: const Text('Sustainable'), value: _isSustainable, onChanged: (v) => setState(() => _isSustainable = v), activeColor: const Color(0xFF10B981)),
                      SwitchListTile(title: const Text('Partner'), value: _isPartner, onChanged: (v) => setState(() => _isPartner = v), activeColor: const Color(0xFF10B981)),
                      SwitchListTile(title: const Text('Active'), value: _isActive, onChanged: (v) => setState(() => _isActive = v), activeColor: const Color(0xFF10B981)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Create Brand', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


