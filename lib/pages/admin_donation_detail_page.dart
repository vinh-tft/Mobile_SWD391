import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/donations_service.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import '../theme/app_colors.dart';

class AdminDonationDetailPage extends StatefulWidget {
  final String donationId;

  const AdminDonationDetailPage({super.key, required this.donationId});

  @override
  State<AdminDonationDetailPage> createState() => _AdminDonationDetailPageState();
}

class _AdminDonationDetailPageState extends State<AdminDonationDetailPage> {
  bool _isLoading = true;
  DonatedItem? _donation;
  late DonationsService _donationsService;

  @override
  void initState() {
    super.initState();
    final api = Provider.of<ApiClient>(context, listen: false);
    _donationsService = DonationsService(api);
    _loadDonation();
  }

  Future<void> _loadDonation() async {
    setState(() => _isLoading = true);
    try {
      final donation = await _donationsService.getDonationById(widget.donationId);
      setState(() {
        _donation = donation;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _acceptDonation() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    if (user?.staffId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Staff ID not found')),
      );
      return;
    }

    try {
      await _donationsService.acceptDonation(widget.donationId, user!.staffId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Donation accepted successfully')),
        );
        _loadDonation();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  String _formatCurrency(double? amount) {
    if (amount == null) return '—';
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} VND';
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
          'Donation Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _donation == null
              ? const Center(child: Text('Data not found'))
              : Builder(
                  builder: (context) {
                    final donation = _donation!;
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Images
                          if (donation.images != null && donation.images!.isNotEmpty)
                            SizedBox(
                              height: 200,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: donation.images!.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        donation.images![index],
                                        width: 200,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 200,
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.image),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                          const SizedBox(height: 16),

                          // Basic Info
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    donation.name ?? '',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    donation.description ?? '',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildInfoItem('Donation Code', donation.donationCode ?? ''),
                                      ),
                                      Expanded(
                                        child: _buildInfoItem('Status', donation.donationStatus ?? ''),
                                      ),
                                    ],
                                  ),
                                  if (donation.size != null)
                                    _buildInfoItem('Size', donation.size!),
                                  if (donation.color != null)
                                    _buildInfoItem('Color', donation.color!),
                                  if (donation.estimatedValue != null)
                                    _buildInfoItem('Estimated Value', _formatCurrency(donation.estimatedValue)),
                                  if (donation.pointsAwarded != null)
                                    _buildInfoItem('Points Awarded', '${donation.pointsAwarded}'),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Customer Info
                          if (donation.customerName != null || donation.customer != null)
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Customer Information',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    if (donation.customerName != null)
                                      _buildInfoItem('Name', donation.customerName!),
                                    if (donation.customerPhone != null)
                                      _buildInfoItem('Phone Number', donation.customerPhone!),
                                    if (donation.customerEmail != null)
                                      _buildInfoItem('Email', donation.customerEmail!),
                                    if (donation.customer != null)
                                      _buildInfoItem(
                                        'Full Name',
                                        '${donation.customer!['firstName'] ?? ''} ${donation.customer!['lastName'] ?? ''}'.trim(),
                                      ),
                                  ],
                                ),
                              ),
                            ),

                          const SizedBox(height: 16),

                          // Actions
                          if (donation.donationStatus == 'PENDING_VALUATION' ||
                              donation.donationStatus == 'VALUATED')
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    if (donation.donationStatus == 'VALUATED')
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: _acceptDonation,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.success,
                                            foregroundColor: Colors.white,
                                          ),
                                          child: const Text('Accept Donation'),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

