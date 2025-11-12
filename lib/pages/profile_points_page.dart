import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class ProfilePointsPage extends StatefulWidget {
  const ProfilePointsPage({Key? key}) : super(key: key);

  @override
  State<ProfilePointsPage> createState() => _ProfilePointsPageState();
}

class _ProfilePointsPageState extends State<ProfilePointsPage> {
  int userPoints = 0;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchUserPoints();
  }

  Future<void> _fetchUserPoints() async {
    setState(() => isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      userPoints = 350; // example mock data
      isLoading = false;
    });
  }

  Future<void> _handlePurchasePoints(int amount) async {
    setState(() => isLoading = true);
    await Future.delayed(const Duration(seconds: 1)); // simulate API
    setState(() {
      userPoints += amount;
      isLoading = false;
    });
  }

  String _formatCurrency(dynamic value) {
    final stringValue = value == null ? '' : value.toString();
    final sanitizedString = stringValue.replaceAll(',', '');
    final intAmount = value is num
        ? value.round()
        : int.tryParse(sanitizedString) ?? 0;
    final formatted = intAmount
        .toString()
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]},');
    return '$formatted ₫';
  }

  String _formatDateString(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      return '$day/$month/${date.year}';
    } catch (_) {
      return dateString;
    }
  }

  Widget _buildPointsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text(
            "Your Points",
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            "$userPoints",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseOptions() {
    final List<Map<String, dynamic>> options = [
      {"points": 100, "price": 10000},
      {"points": 200, "price": 18000},
      {"points": 500, "price": 40000},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Buy More Points",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: options.map((opt) {
            return GestureDetector(
              onTap: () => _handlePurchasePoints(opt["points"]),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Text(
                      "${opt["points"]} pts",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCurrency(opt["price"]),
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPaymentHistoryContent(BuildContext context) {
    final history = [
      {"date": "2025-11-01", "points": 200, "amount": 18000},
      {"date": "2025-10-21", "points": 100, "amount": 10000},
    ];

    return Column(
      children: history.map((item) {
        return ListTile(
          leading: const Icon(Icons.payment, color: Colors.purpleAccent),
          title: Text("${item["points"]} points"),
          subtitle: Text(_formatDateString(item["date"] as String)),
          trailing: Text(_formatCurrency(item["amount"])),
        );
      }).toList(),
    );
  }

  Widget _buildPaymentHistory() {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payment History',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'All your point purchases via MoMo',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          _buildPaymentHistoryContent(context),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Points"),
        backgroundColor: AppColors.primary,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPointsCard(),
                    const SizedBox(height: 24),
                    _buildPurchaseOptions(),
                    const SizedBox(height: 24),
                    _buildPaymentHistory(),
                  ],
                ),
              ),
            ),
    );
  }
}
