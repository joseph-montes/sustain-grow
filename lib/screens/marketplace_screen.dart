import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({Key? key}) : super(key: key);

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  String _search = '';
  String _selectedCategory = 'All';
  final List<String> _categories = [
    'All', 'Fertilisers', 'Seeds', 'Equipment', 'Pesticides'
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final p = context.read<AppProvider>();
      if (p.products.isEmpty) p.fetchProducts();
    });
  }

  List<dynamic> _filtered(List<dynamic> products) {
    return products.where((p) {
      final matchCat =
          _selectedCategory == 'All' || p['category'] == _selectedCategory;
      final matchSearch = _search.isEmpty ||
          p['name'].toString().toLowerCase().contains(_search.toLowerCase()) ||
          (p['seller_name'] ?? '').toString().toLowerCase().contains(_search.toLowerCase());
      return matchCat && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final filtered = _filtered(provider.products);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: AppTheme.primaryGreen,
            elevation: 0,
            expandedHeight: 130,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Marketplace',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(
                          '${provider.products.length} products available',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                // Search
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v),
                    decoration: InputDecoration(
                      hintText: 'Search products or sellers...',
                      prefixIcon:
                          const Icon(Icons.search, color: AppTheme.textMuted),
                      suffixIcon: _search.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear,
                                  color: AppTheme.textMuted),
                              onPressed: () => setState(() => _search = ''),
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: AppTheme.buttonRadius,
                        borderSide: BorderSide.none,
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),

                // Category filter chips
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final cat = _categories[i];
                      final sel = cat == _selectedCategory;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel
                                ? AppTheme.primaryGreen
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: sel ? AppTheme.elevatedShadow : AppTheme.cardShadow,
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: sel
                                  ? Colors.white
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                if (provider.products.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(60),
                    child: CircularProgressIndicator(
                        color: AppTheme.primaryGreen),
                  )
                else if (filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Text('No products found',
                        style: TextStyle(color: AppTheme.textMuted)),
                  )
                else ...[
                  // ── Grid of Products ──────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.72,
                      ),
                      itemBuilder: (_, i) => _ProductCard(product: filtered[i]),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final dynamic product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final inStock = product['in_stock'] as bool? ?? true;
    final hasDiscount = product['original_price'] != null;

    return GestureDetector(
      onTap: () => _showProductDetail(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppTheme.cardRadius,
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image placeholder
            Container(
              height: 110,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.mintGreen.withOpacity(0.5),
                    AppTheme.lightGreen.withOpacity(0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Stack(
                children: [
                  const Center(
                    child: Icon(Icons.inventory_2_outlined,
                        size: 48, color: AppTheme.primaryGreen),
                  ),
                  if (!inStock)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: const Center(
                        child: Text('Out of Stock',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12)),
                      ),
                    ),
                  if (hasDiscount)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.errorRed,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '-${(((product['original_price'] - product['price']) / product['original_price']) * 100).round()}%',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['name'] ?? '',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(product['seller_name'] ?? '',
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textMuted)),
                    const Spacer(),
                    // Rating
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: AppTheme.accentAmber, size: 14),
                        const SizedBox(width: 2),
                        Text('${product['rating']}',
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary)),
                        Text('  ·  ${product['sold']} sold',
                            style: const TextStyle(
                                fontSize: 10, color: AppTheme.textMuted)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '₱${product['price']}',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryGreen),
                        ),
                        if (hasDiscount) ...[
                          const SizedBox(width: 6),
                          Text(
                            '₱${product['original_price']}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textMuted,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text('per ${product['unit']}',
                        style: const TextStyle(
                            fontSize: 10, color: AppTheme.textMuted)),
                  ],
                ),
              ),
            ),

            // Add to cart button
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: inStock
                      ? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${product['name']} added to cart!'),
                              backgroundColor: AppTheme.primaryGreen,
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    disabledBackgroundColor: Colors.grey[200],
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text(
                    'Add to Cart',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProductDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scroll) => SingleChildScrollView(
          controller: scroll,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: AppTheme.dividerColor,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Text(product['name'] ?? '', style: AppTheme.heading1),
              const SizedBox(height: 6),
              Text('Sold by: ${product['seller_name'] ?? ''}',
                  style: AppTheme.bodySmall),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '₱${product['price']} / ${product['unit']}',
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryGreen),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (product['description'] != null) ...[
                const Text('Description', style: AppTheme.heading2),
                const SizedBox(height: 6),
                Text(product['description'], style: AppTheme.bodyLarge),
                const SizedBox(height: 20),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${product['name']} added to cart!'),
                        backgroundColor: AppTheme.primaryGreen,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Text('Add to Cart'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}