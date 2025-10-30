import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/sales_service.dart';
import '../models/api_models.dart';

class CreateListingPage extends StatefulWidget {
  const CreateListingPage({super.key});

  @override
  State<CreateListingPage> createState() => _CreateListingPageState();
}

class _CreateListingPageState extends State<CreateListingPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _priceController = TextEditingController(text: '0');

  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng sản phẩm'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên sản phẩm *',
                    hintText: 'Ví dụ: Áo khoác denim vintage',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title, color: Color(0xFF22C55E)),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên sản phẩm' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả',
                    hintText: 'Mô tả chi tiết về sản phẩm...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description, color: Color(0xFF22C55E)),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập mô tả' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Số lượng *',
                    hintText: 'Ví dụ: 1',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.format_list_numbered, color: Color(0xFF22C55E)),
                  ),
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null || n <= 0) return 'Số lượng phải > 0';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Giá (VND) *',
                    hintText: 'Ví dụ: 100000',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money, color: Color(0xFF22C55E)),
                  ),
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null || n < 0) return 'Giá phải >= 0';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Đăng sản phẩm', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final salesService = context.read<SalesService>();
      final name = (_nameController.text).trim();
      final description = (_descriptionController.text).trim();
      final quantityStr = (_quantityController.text).trim();
      final priceStr = (_priceController.text).trim();
      final quantity = int.tryParse(quantityStr);
      final price = int.tryParse(priceStr);

      if (name.isEmpty || description.isEmpty || quantity == null || quantity <= 0 || price == null || price < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng nhập dữ liệu hợp lệ')), 
        );
        return;
      }

      final req = SaleCreateRequest(
        name: name,
        description: description,
        quantity: quantity,
        price: price,
      );
      final ok = await salesService.createSaleItem(req);
      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng sản phẩm thành công!'), backgroundColor: Color(0xFF22C55E)),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(salesService.error ?? 'Không thể đăng sản phẩm!'), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: const Color(0xFFEF4444)),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}


