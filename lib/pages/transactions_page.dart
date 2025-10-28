import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/clothing_service.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Giao dịch',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer2<AuthService, ClothingService>(
        builder: (context, authService, clothingService, child) {
          return Column(
            children: [
              // Filter Tabs
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    _buildFilterTab('Tất cả', 'all'),
                    const SizedBox(width: 12),
                    _buildFilterTab('Thu mua', 'purchase'),
                    const SizedBox(width: 12),
                    _buildFilterTab('Bán hàng', 'sale'),
                    const SizedBox(width: 12),
                    _buildFilterTab('Đổi quần áo', 'exchange'),
                  ],
                ),
              ),
              
              // Transactions List
              Expanded(
                child: _buildTransactionsList(clothingService),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterTab(String label, String value) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF22C55E) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF6B7280),
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionsList(ClothingService clothingService) {
    // Mock data for transactions
    final transactions = [
      {
        'id': 'T001',
        'type': 'purchase',
        'customerName': 'Nguyễn Văn A',
        'itemName': 'Áo khoác denim',
        'points': 800,
        'date': DateTime.now().subtract(const Duration(hours: 2)),
        'status': 'completed',
      },
      {
        'id': 'T002',
        'type': 'sale',
        'customerName': 'Trần Thị B',
        'itemName': 'Quần jean',
        'points': 600,
        'date': DateTime.now().subtract(const Duration(hours: 5)),
        'status': 'completed',
      },
      {
        'id': 'T003',
        'type': 'exchange',
        'customerName': 'Lê Văn C',
        'itemName': 'Váy hoa',
        'points': 500,
        'date': DateTime.now().subtract(const Duration(days: 1)),
        'status': 'pending',
      },
      {
        'id': 'T004',
        'type': 'purchase',
        'customerName': 'Phạm Thị D',
        'itemName': 'Giày sneakers',
        'points': 1200,
        'date': DateTime.now().subtract(const Duration(days: 2)),
        'status': 'completed',
      },
    ];

    final filteredTransactions = _selectedFilter == 'all'
        ? transactions
        : transactions.where((t) => t['type'] == _selectedFilter).toList();

    if (filteredTransactions.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: filteredTransactions.length,
      itemBuilder: (context, index) {
        final transaction = filteredTransactions[index];
        return _buildTransactionCard(transaction);
      },
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final type = transaction['type'] as String;
    final status = transaction['status'] as String;
    
    Color typeColor;
    IconData typeIcon;
    String typeLabel;
    
    switch (type) {
      case 'purchase':
        typeColor = const Color(0xFF22C55E);
        typeIcon = Icons.shopping_cart;
        typeLabel = 'Thu mua';
        break;
      case 'sale':
        typeColor = const Color(0xFF3B82F6);
        typeIcon = Icons.sell;
        typeLabel = 'Bán hàng';
        break;
      case 'exchange':
        typeColor = const Color(0xFF8B5CF6);
        typeIcon = Icons.swap_horiz;
        typeLabel = 'Đổi quần áo';
        break;
      default:
        typeColor = Colors.grey;
        typeIcon = Icons.receipt;
        typeLabel = 'Giao dịch';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  typeIcon,
                  color: typeColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      typeLabel,
                      style: TextStyle(
                        color: typeColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      transaction['itemName'] as String,
                      style: const TextStyle(
                        color: Color(0xFF1F2937),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: status == 'completed' 
                      ? const Color(0xFF22C55E).withOpacity(0.1)
                      : const Color(0xFFF59E0B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status == 'completed' ? 'Hoàn thành' : 'Chờ xử lý',
                  style: TextStyle(
                    color: status == 'completed' 
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFF59E0B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.person,
                color: Colors.grey[600],
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                transaction['customerName'] as String,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.stars,
                color: Colors.amber[600],
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '${transaction['points']} điểm',
                style: const TextStyle(
                  color: Color(0xFF1F2937),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.access_time,
                color: Colors.grey[600],
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                _formatDateTime(transaction['date'] as DateTime),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                'ID: ${transaction['id']}',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có giao dịch nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Các giao dịch sẽ hiển thị ở đây',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }
}
