import 'package:flutter/material.dart';
import 'product_detail_page.dart';

class LovedPage extends StatefulWidget {
  const LovedPage({super.key});

  @override
  State<LovedPage> createState() => _LovedPageState();
}

class _LovedPageState extends State<LovedPage> {
  List<Map<String, dynamic>> _lovedItems = [
    {
      'title': 'Áo khoác denim vintage',
      'price': '1.050.000 VND',
      'rating': '4.8',
      'description': 'Áo khoác denim vintage từ thập niên 90. Tình trạng hoàn hảo với vết mòn tự nhiên tạo nét đặc trưng. Làm từ 100% cotton denim.',
      'images': [
        'https://images.unsplash.com/photo-1548883354-94bcfe321c35?q=80&w=1200&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1544025162-d76694265947?q=80&w=1200&auto=format&fit=crop'
      ],
      'seller': 'Sarah Johnson',
      'condition': 'Excellent',
      'size': 'M',
      'brand': 'Levi\'s',
      'dateAdded': DateTime.now().subtract(const Duration(days: 2)),
    },
    {
      'title': 'Giày sneaker eco',
      'price': '1.550.000 VND',
      'rating': '4.9',
      'description': 'Giày sneaker bền vững làm từ vật liệu tái chế. Thoải mái, thời trang và thân thiện với môi trường. Hoàn hảo cho việc sử dụng hàng ngày.',
      'images': [
        'https://images.unsplash.com/photo-1542291026-7eec264c27ff?q=80&w=1200&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1520256862855-398228c41684?q=80&w=1200&auto=format&fit=crop'
      ],
      'seller': 'Mike Chen',
      'condition': 'Like New',
      'size': '9',
      'brand': 'Allbirds',
      'dateAdded': DateTime.now().subtract(const Duration(days: 5)),
    },
  ];
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header Section
          _buildHeader(),
          
          // Loved Items Title
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Loved Items',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                if (_lovedItems.isNotEmpty)
                  Text(
                    '${_lovedItems.length} items',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
              ],
            ),
          ),
          
          // Loved Items List or Empty State
          _lovedItems.isEmpty ? _buildEmptyState() : _buildLovedItemsList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo
          Flexible(
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.recycling,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                const Flexible(
                  child: Text(
                    'Green Loop',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Theme toggle
          const Icon(
            Icons.wb_sunny_outlined,
            color: Color(0xFF6B7280),
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const Icon(
            Icons.favorite_border,
            color: Color(0xFF6B7280),
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'No loved items yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start exploring and add items you love to your collection',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Navigate to Marketplace'),
                  backgroundColor: Color(0xFF22C55E),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Explore Marketplace'),
          ),
        ],
      ),
    );
  }

  Widget _buildLovedItemsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _lovedItems.length,
      itemBuilder: (context, index) {
        final item = _lovedItems[index];
        return _buildLovedItemCard(item, index);
      },
    );
  }

  Widget _buildLovedItemCard(Map<String, dynamic> item, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailPage(
                title: item['title'],
                price: item['price'],
                rating: item['rating'],
                description: item['description'],
                images: item['images'],
                seller: item['seller'],
                condition: item['condition'],
                size: item['size'],
                brand: item['brand'],
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: (item['images'] is List && (item['images'] as List).isNotEmpty)
                    ? Image.network(
                        (item['images'] as List).first,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 80,
                          height: 80,
                          color: const Color(0xFFF3F4F6),
                          child: const Icon(Icons.broken_image, color: Color(0xFF6B7280), size: 32),
                        ),
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: const Color(0xFFF3F4F6),
                        child: const Icon(Icons.image, color: Color(0xFF6B7280), size: 32),
                      ),
              ),
              const SizedBox(width: 16),
              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['brand'],
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Color(0xFFFBBF24), size: 16),
                        const SizedBox(width: 4),
                        Text(
                          item['rating'],
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          item['price'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF22C55E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Added ${_getTimeAgo(item['dateAdded'])}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              // Actions
              Column(
                children: [
                  IconButton(
                    onPressed: () => _removeFromLoved(index),
                    icon: const Icon(
                      Icons.favorite,
                      color: Color(0xFFEF4444),
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Buy Now',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF22C55E),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  void _removeFromLoved(int index) {
    setState(() {
      _lovedItems.removeAt(index);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Removed from loved items'),
        backgroundColor: Color(0xFF22C55E),
      ),
    );
  }
}
