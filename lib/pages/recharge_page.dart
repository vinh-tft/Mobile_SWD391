import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uni_links/uni_links.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/points_service.dart';

class RechargePage extends StatefulWidget {
  const RechargePage({super.key});

  @override
  State<RechargePage> createState() => _RechargePageState();
}

class _RechargePageState extends State<RechargePage> {
  final TextEditingController _amountController = TextEditingController();
  int? _selectedPackage;
  bool _isLoading = false;
  bool _handlingDeepLink = false;
  StreamSubscription<Uri?>? _linkSubscription;
  String? _pendingOrderId;
  String? _pendingRequestId;
  final Set<String> _handledOrderIds = {};

  final List<Map<String, dynamic>> _pointPackages = [
    { 'points': 10000, 'price': 10000, 'popular': false, 'label': '10K' },
    { 'points': 50000, 'price': 50000, 'popular': true, 'label': '50K' },
    { 'points': 100000, 'price': 100000, 'popular': false, 'label': '100K' },
    { 'points': 500000, 'price': 500000, 'popular': false, 'label': '500K' },
  ];

  static const int PRICE_PER_POINT = 1; // 1 VND per point
  static const int MIN_POINTS = 10000;    // Minimum 10,000 points
  static const int MAX_POINTS = 10000000; // Maximum 10,000,000 points
  static const String _momoReturnUrl = 'greenloop://payments/momo-result';

  @override
  void initState() {
    super.initState();
    _listenForDeepLinks();
    _handleInitialUri();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Recharge Points',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<AuthService>(
        builder: (context, authService, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current Points Display
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.account_balance_wallet,
                        color: Colors.white,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Current Points',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${authService.currentUser?.points ?? 0} points',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Package Selection
                const Text(
                  'Select Points Package',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: _pointPackages.length,
                  itemBuilder: (context, index) {
                    final package = _pointPackages[index];
                    final points = package['points'] as int;
                    final price = package['price'] as int;
                    final label = package['label'] as String;
                    final popular = package['popular'] as bool;
                    final isSelected = _selectedPackage == points;
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedPackage = points;
                          _amountController.text = points.toString();
                        });
                      },
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? const Color(0xFF22C55E).withOpacity(0.1)
                                  : Colors.white,
                              border: Border.all(
                                color: isSelected 
                                    ? const Color(0xFF22C55E)
                                    : Colors.grey[300]!,
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected 
                                          ? const Color(0xFF22C55E)
                                          : const Color(0xFF1F2937),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${points.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} points',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} VNĐ',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF22C55E),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (popular)
                            Positioned(
                              top: -8,
                              right: -8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF22C55E),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Popular',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Custom Amount Input
                const Text(
                  'Or Enter Custom Points',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Enter points (${MIN_POINTS.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} - ${MAX_POINTS.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')})',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF22C55E), width: 2),
                    ),
                  ),
                  onChanged: (value) {
                    final amount = int.tryParse(value);
                    if (amount != null) {
                      setState(() {
                        _selectedPackage = null; // Clear package selection when custom input
                      });
                    }
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Minimum: ${MIN_POINTS.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} points | Maximum: ${MAX_POINTS.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} points',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),

                const SizedBox(height: 24),

                // Price Summary
                if (_getSelectedPoints() > 0) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD1FAE5), Color(0xFFDBEAFE)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Points:',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            Text(
                              '${_getSelectedPoints().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} points',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Unit Price:',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            Text(
                              '${PRICE_PER_POINT.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} VND/point',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            Text(
                              '${_calculateTotalPrice().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} VNĐ',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF22C55E),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Payment Method Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDBEAFE).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: const Color(0xFF3B82F6), size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pay with MoMo',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E40AF),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'You will be redirected to the MoMo payment page to complete the transaction. Points will be added to your account after successful payment.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF22C55E), Color(0xFF3B82F6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading || _getSelectedPoints() < MIN_POINTS ? null : _handleRecharge,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Pay with MoMo',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),

              ],
            ),
          );
        },
      ),
    );
  }

  int _getSelectedPoints() {
    if (_selectedPackage != null) {
      return _selectedPackage!;
    }
    final customAmount = int.tryParse(_amountController.text);
    return customAmount ?? 0;
  }

  int _calculateTotalPrice() {
    return _getSelectedPoints() * PRICE_PER_POINT;
  }

  Future<void> _handleRecharge() async {
    if (_isLoading) return;
    final points = _getSelectedPoints();
    
    if (points < MIN_POINTS) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter at least ${MIN_POINTS.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} points'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (points > MAX_POINTS) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum ${MAX_POINTS.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} points per transaction'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final pointsService = Provider.of<PointsService>(context, listen: false);

    final userId = authService.currentUser?.id;
    if (userId == null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Call MoMo payment API
      final paymentResponse = await pointsService.buyPointsWithMomo(
        userId: userId,
        pointsAmount: points,
        description: 'Buy $points points',
        returnUrl: _momoReturnUrl,
      );

      setState(() => _isLoading = false);

      if (paymentResponse == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to create payment transaction. Please try again'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final success = paymentResponse['success'] as bool? ?? false;
      final payUrl = paymentResponse['payUrl'] as String?;
      final paymentId = paymentResponse['paymentId'] as String?;
      final errorMessage = paymentResponse['errorMessage'] as String?;
      final requestId = paymentResponse['requestId']?.toString();
      final orderId = paymentResponse['orderId']?.toString();

      if (!success || payUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage ?? 'Unable to create payment transaction'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Store payment ID for callback handling
      if (paymentId != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('lastPaymentId', paymentId);
      }
      if (orderId != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('pendingMomoOrderId', orderId);
      }
      if (requestId != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('pendingMomoRequestId', requestId);
      }

      _pendingOrderId = orderId;
      _pendingRequestId = requestId;

      // Open MoMo payment URL
      final uri = Uri.parse(payUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Complete the payment in MoMo, then return to the app.'),
              duration: Duration(seconds: 4),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open payment page'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _listenForDeepLinks() {
    // Handle stream updates while the page is alive
    _linkSubscription = uriLinkStream.listen(
      (uri) {
        if (uri != null) {
          _handleIncomingUri(uri);
        }
      },
      onError: (Object err) {
        debugPrint('❌ Error processing incoming link: $err');
      },
    );
  }

  Future<void> _handleInitialUri() async {
    try {
      final uri = await getInitialUri();
      if (uri != null) {
        await _handleIncomingUri(uri);
      }
    } on PlatformException catch (e) {
      debugPrint('❌ Failed to get initial URI: $e');
    } on FormatException catch (e) {
      debugPrint('❌ Malformed initial URI: $e');
    }
  }

  Future<void> _handleIncomingUri(Uri uri) async {
    if (uri.scheme != 'greenloop') return;
    if (uri.host != 'payments') return;
    if (uri.pathSegments.isEmpty || uri.pathSegments.first != 'momo-result') return;

    final orderId = uri.queryParameters['orderId'] ?? uri.queryParameters['orderid'];
    if (orderId != null && _handledOrderIds.contains(orderId)) {
      return;
    }

    final requestId = uri.queryParameters['requestId'] ?? uri.queryParameters['requestid'] ?? _pendingRequestId;
    final resultCode = uri.queryParameters['resultCode'] ?? uri.queryParameters['resultcode'];
    final message = uri.queryParameters['message'];

    if (orderId == null || resultCode == null || requestId == null) {
      debugPrint('⚠️ Missing required MoMo callback params: orderId=$orderId, requestId=$requestId, resultCode=$resultCode');
      return;
    }

    _handledOrderIds.add(orderId);
    await _completePayment(orderId: orderId, requestId: requestId, resultCode: resultCode, message: message);
  }

  Future<void> _completePayment({
    required String orderId,
    required String requestId,
    required String resultCode,
    String? message,
  }) async {
    if (!mounted || _handlingDeepLink) return;
    _handlingDeepLink = true;

    setState(() {
      _isLoading = true;
    });

    final pointsService = context.read<PointsService>();
    final authService = context.read<AuthService>();

    try {
      final success = await pointsService.completeMomoPayment(
        orderId: orderId,
        requestId: requestId,
        resultCode: resultCode,
        message: message,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('lastPaymentId');
      await prefs.remove('pendingMomoOrderId');
      await prefs.remove('pendingMomoRequestId');

      if (success && mounted) {
        await authService.refreshPoints();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment completed successfully. Points have been updated.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message ?? 'Unable to validate payment. Please check your history.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing payment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      _handlingDeepLink = false;
    }
  }

  // Removed _showPaymentConfirmationDialog - no longer needed with direct MoMo redirect
}
