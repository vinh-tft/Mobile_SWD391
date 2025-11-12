import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ProfileAddressesPage extends StatefulWidget {
  const ProfileAddressesPage({super.key});

  @override
  State<ProfileAddressesPage> createState() => _ProfileAddressesPageState();
}

class _ProfileAddressesPageState extends State<ProfileAddressesPage> {
  List<Map<String, dynamic>> _addresses = [];

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    // TODO: Load addresses from API
    setState(() {
      _addresses = [];
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
          'Địa chỉ của tôi',
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
              // TODO: Navigate to add address page
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng đang phát triển')),
              );
            },
          ),
        ],
      ),
      body: _addresses.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_on_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có địa chỉ nào',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Navigate to add address page
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tính năng đang phát triển')),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm địa chỉ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _addresses.length,
              itemBuilder: (context, index) {
                final address = _addresses[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.location_on, color: AppColors.primary),
                    title: Text(address['label'] ?? 'Address'),
                    subtitle: Text(address['fullAddress'] ?? ''),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (address['isDefault'] == true)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Default',
                              style: TextStyle(
                                color: AppColors.success,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            // TODO: Edit address
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Tính năng đang phát triển')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

