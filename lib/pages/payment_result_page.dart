import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';

class PaymentResultPage extends StatefulWidget {
  final bool success;
  final String? message;
  final String? orderId;

  const PaymentResultPage({
    super.key,
    required this.success,
    this.message,
    this.orderId,
  });

  @override
  State<PaymentResultPage> createState() => _PaymentResultPageState();
}

class _PaymentResultPageState extends State<PaymentResultPage> {
  @override
  void initState() {
    super.initState();
    // Refresh points if payment was successful
    if (widget.success) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final authService = Provider.of<AuthService>(context, listen: false);
        authService.refreshPoints();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Status Icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: widget.success
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.error.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.success ? Icons.check_circle : Icons.error,
                    size: 60,
                    color: widget.success ? AppColors.success : AppColors.error,
                  ),
                ),

                const SizedBox(height: 24),

                // Status Message
                Text(
                  widget.success ? 'Success' : 'Failed',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: widget.success ? AppColors.success : AppColors.error,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  widget.message ?? 
                      (widget.success 
                          ? 'Payment successful! Points have been added to your account.' 
                          : 'Payment failed. Please try again.'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),

                if (widget.orderId != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Order ID',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.orderId!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Action Buttons
                if (widget.success) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/profile/points',
                          (route) => route.isFirst,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        'View My Points',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/marketplace',
                          (route) => route.isFirst,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                      ),
                      child: const Text(
                        'Continue Shopping',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/profile/points',
                          (route) => route.isFirst,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        'Try Again',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/',
                          (route) => route.isFirst,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                      ),
                      child: const Text(
                        'Back to Home',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

