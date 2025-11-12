import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/donations_service.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import '../theme/app_colors.dart';
import 'admin_donation_detail_page.dart';
import 'admin_donation_create_page.dart';

class AdminDonationsPage extends StatefulWidget {
  const AdminDonationsPage({super.key});

  @override
  State<AdminDonationsPage> createState() => _AdminDonationsPageState();
}

class _AdminDonationsPageState extends State<AdminDonationsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'ALL';
  int _currentPage = 0;
  bool _isLoading = false;
  List<dynamic> _donations = [];
  int _totalPages = 0;
  int _totalElements = 0;
  late DonationsService _donationsService;

  final Map<String, String> _statusFilters = {
    'ALL': 'All',
    'PENDING_VALUATION': 'Pending Valuation',
    'VALUATED': 'Valuated',
    'ACCEPTED': 'Accepted',
    'READY_FOR_SALE': 'Ready for Sale',
    'REJECTED': 'Rejected',
  };

  @override
  void initState() {
    super.initState();
    final api = Provider.of<ApiClient>(context, listen: false);
    _donationsService = DonationsService(api);
    _loadDonations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDonations() async {
    setState(() => _isLoading = true);
    try {
      final result = _selectedStatus == 'ALL'
          ? await _donationsService.getAllDonations(page: _currentPage, size: 20)
          : await _donationsService.getDonationsByStatus(_selectedStatus, page: _currentPage, size: 20);
      
      setState(() {
        _donations = result['content'] is List ? List.from(result['content']) : [];
        _totalPages = result['totalPages'] ?? 0;
        _totalElements = result['totalElements'] ?? 0;
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

  Future<void> _searchDonations() async {
    if (_searchController.text.trim().isEmpty) {
      _loadDonations();
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await _donationsService.searchDonations(
        _searchController.text.trim(),
        page: _currentPage,
        size: 20,
      );
      
      setState(() {
        _donations = result['content'] is List ? List.from(result['content']) : [];
        _totalPages = result['totalPages'] ?? 0;
        _totalElements = result['totalElements'] ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching: $e')),
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

  String _formatCurrency(double? amount) {
    if (amount == null) return '—';
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} VND';
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    // Check if user has admin access (both admin and staff can access donations)
    if (user == null || !authService.hasAdminAccess) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Access Denied'),
        ),
        body: const Center(
          child: Text('Only admin and staff can access this page'),
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
          'Manage Donations',
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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminDonationCreatePage()),
              ).then((_) => _loadDonations());
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDonations,
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
                        hintText: 'Search donations...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onSubmitted: (_) => _searchDonations(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _searchDonations,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Status Filter
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: _statusFilters.entries.map((entry) {
                  final isSelected = _selectedStatus == entry.key;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(entry.value),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedStatus = entry.key;
                            _currentPage = 0;
                          });
                          _loadDonations();
                        }
                      },
                      selectedColor: AppColors.primary.withOpacity(0.2),
                      checkmarkColor: AppColors.primary,
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 8),

            // Donations List
            Expanded(
              child: _isLoading && _donations.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _donations.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'No donations found',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _donations.length + (_currentPage < _totalPages - 1 ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _donations.length) {
                              return Padding(
                                padding: const EdgeInsets.all(16),
                                child: Center(
                                  child: TextButton(
                                    onPressed: () {
                                      setState(() => _currentPage++);
                                      _loadDonations();
                                    },
                                    child: const Text('Load More'),
                                  ),
                                ),
                              );
                            }

                            final donation = _donations[index];
                            final donationId = donation['donatedItemId']?.toString() ?? '';
                            final donationCode = donation['donationCode']?.toString() ?? '';
                            final name = donation['name']?.toString() ?? '';
                            final status = donation['donationStatus']?.toString() ?? '';
                            final estimatedValue = donation['estimatedValue']?.toDouble();
                            final createdAt = donation['createdAt']?.toString() ?? '';
                            final images = donation['images'] is List ? List<String>.from(donation['images']) : [];
                            final customerName = donation['customerName'] ?? 
                                (donation['customer'] != null 
                                    ? '${donation['customer']['firstName'] ?? ''} ${donation['customer']['lastName'] ?? ''}'.trim()
                                    : '');

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
                                    if (customerName.isNotEmpty)
                                      Text('Customer: $customerName'),
                                    Text('Code: $donationCode'),
                                    if (estimatedValue != null)
                                      Text('Value: ${_formatCurrency(estimatedValue)}'),
                                    Text('Date: ${createdAt.split('T').first}'),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getStatusBadgeColor(status) == 'yellow'
                                            ? Colors.yellow[100]
                                            : _getStatusBadgeColor(status) == 'blue'
                                                ? Colors.blue[100]
                                                : _getStatusBadgeColor(status) == 'green'
                                                    ? Colors.green[100]
                                                    : _getStatusBadgeColor(status) == 'emerald'
                                                        ? Colors.teal[100]
                                                        : Colors.red[100],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _statusFilters[status] ?? status,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: _getStatusBadgeColor(status) == 'yellow'
                                              ? Colors.yellow[900]
                                              : _getStatusBadgeColor(status) == 'blue'
                                                  ? Colors.blue[900]
                                                  : _getStatusBadgeColor(status) == 'green'
                                                      ? Colors.green[900]
                                                      : _getStatusBadgeColor(status) == 'emerald'
                                                          ? Colors.teal[900]
                                                          : Colors.red[900],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AdminDonationDetailPage(donationId: donationId),
                                    ),
                                  ).then((_) => _loadDonations());
                                },
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

