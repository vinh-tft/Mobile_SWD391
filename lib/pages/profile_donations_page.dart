import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/donations_service.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import '../theme/app_colors.dart';

class ProfileDonationsPage extends StatefulWidget {
  const ProfileDonationsPage({super.key});

  @override
  State<ProfileDonationsPage> createState() => _ProfileDonationsPageState();
}

class _ProfileDonationsPageState extends State<ProfileDonationsPage> {
  bool _isLoading = false;
  List<dynamic> _donations = [];
  late DonationsService _donationsService;

  @override
  void initState() {
    super.initState();
    final api = Provider.of<ApiClient>(context, listen: false);
    _donationsService = DonationsService(api);
    _loadDonations();
  }

  Future<void> _loadDonations() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final result = await _donationsService.getDonationsByStaff(
        user.staffId ?? user.id,
        page: 0,
        size: 50,
      );
      
      setState(() {
        _donations = result['content'] is List ? List.from(result['content']) : [];
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

  String _getStatusBadgeColor(String status) {
    switch (status) {
      case 'PENDING_VALUATION':
        return 'yellow';
      case 'VALUATED':
        return 'blue';
      case 'ACCEPTED':
        return 'green';
      case 'READY_FOR_SALE':
        return 'emerald';
      case 'REJECTED':
        return 'red';
      default:
        return 'gray';
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
          'My Donations',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadDonations,
        color: AppColors.primary,
        child: _isLoading && _donations.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _donations.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No donations yet',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _donations.length,
                    itemBuilder: (context, index) {
                      final donation = _donations[index];
                      final donationCode = donation['donationCode']?.toString() ?? '';
                      final name = donation['name']?.toString() ?? '';
                      final status = donation['donationStatus']?.toString() ?? '';
                      final createdAt = donation['createdAt']?.toString() ?? '';
                      final images = donation['images'] is List ? List<String>.from(donation['images']) : [];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: images.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    images.first,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.image),
                                  ),
                                )
                              : const Icon(Icons.inventory_2, size: 40),
                          title: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Code: $donationCode'),
                              Text('Date: ${createdAt.split('T').first}'),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusBadgeColor(status) == 'yellow'
                                  ? Colors.yellow[100]
                                  : _getStatusBadgeColor(status) == 'blue'
                                      ? Colors.blue[100]
                                      : _getStatusBadgeColor(status) == 'green'
                                          ? Colors.green[100]
                                          : Colors.red[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status.replaceAll('_', ' '),
                              style: TextStyle(
                                fontSize: 10,
                                color: _getStatusBadgeColor(status) == 'yellow'
                                    ? Colors.yellow[900]
                                    : _getStatusBadgeColor(status) == 'blue'
                                        ? Colors.blue[900]
                                        : _getStatusBadgeColor(status) == 'green'
                                            ? Colors.green[900]
                                            : Colors.red[900],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

