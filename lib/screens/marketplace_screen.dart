import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

// ── Cart Item Model ───────────────────────────────────────────────────────────

class CartItem {
  final Map<String, dynamic> product;
  int quantity;
  CartItem({required this.product, this.quantity = 1});

  double get subtotal =>
      ((product['price'] as num).toDouble()) * quantity;
}

// ── Cart Provider (local state) ───────────────────────────────────────────────

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  List<CartItem> get items => List.unmodifiable(_items);

  int get totalCount => _items.fold(0, (s, i) => s + i.quantity);

  double get totalPrice => _items.fold(0.0, (s, i) => s + i.subtotal);

  void addItem(Map<String, dynamic> product) {
    final existing = _items.indexWhere(
        (i) => i.product['name'] == product['name']);
    if (existing >= 0) {
      _items[existing].quantity++;
    } else {
      _items.add(CartItem(product: product));
    }
    notifyListeners();
  }

  void removeItem(int index) {
    _items.removeAt(index);
    notifyListeners();
  }

  void increment(int index) {
    _items[index].quantity++;
    notifyListeners();
  }

  void decrement(int index) {
    if (_items[index].quantity > 1) {
      _items[index].quantity--;
    } else {
      _items.removeAt(index);
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}

// ── Marketplace Screen ────────────────────────────────────────────────────────

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({Key? key}) : super(key: key);

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final CartProvider _cart = CartProvider();
  String _search = '';
  String _selectedCategory = 'All';
  final List<String> _categories = [
    'All',
    'Fertilisers',
    'Seeds',
    'Equipment',
    'Pesticides'
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
          p['name']
              .toString()
              .toLowerCase()
              .contains(_search.toLowerCase()) ||
          (p['seller_name'] ?? '')
              .toString()
              .toLowerCase()
              .contains(_search.toLowerCase());
      return matchCat && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final filtered = _filtered(provider.products);

    return ChangeNotifierProvider.value(
      value: _cart,
      child: Consumer<CartProvider>(
        builder: (context, cart, _) => Scaffold(
          backgroundColor: AppTheme.backgroundLight,
          body: CustomScrollView(
            slivers: [
              // ── App Bar ──────────────────────────────────────────────────
              SliverAppBar(
                pinned: true,
                backgroundColor: AppTheme.primaryGreen,
                elevation: 0,
                expandedHeight: 130,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                        gradient: AppTheme.heroGradient),
                    child: SafeArea(
                      child: Padding(
                        padding:
                            const EdgeInsets.fromLTRB(20, 12, 20, 0),
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
                actions: [
                  // ── Cart Icon with Badge ──────────────────────────────
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () => _openCart(context, cart),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(Icons.shopping_cart_outlined,
                              color: Colors.white, size: 28),
                          if (cart.totalCount > 0)
                            Positioned(
                              right: -6,
                              top: -6,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: AppTheme.errorRed,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 1.5),
                                ),
                                child: Center(
                                  child: Text(
                                    '${cart.totalCount > 9 ? '9+' : cart.totalCount}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // Search
                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: TextField(
                        onChanged: (v) =>
                            setState(() => _search = v),
                        decoration: InputDecoration(
                          hintText: 'Search products or sellers...',
                          prefixIcon: const Icon(Icons.search,
                              color: AppTheme.textMuted),
                          suffixIcon: _search.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear,
                                      color: AppTheme.textMuted),
                                  onPressed: () =>
                                      setState(() => _search = ''),
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

                    // Category chips
                    SizedBox(
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16),
                        itemCount: _categories.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final cat = _categories[i];
                          final sel = cat == _selectedCategory;
                          return GestureDetector(
                            onTap: () => setState(
                                () => _selectedCategory = cat),
                            child: AnimatedContainer(
                              duration:
                                  const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: sel
                                    ? AppTheme.primaryGreen
                                    : Colors.white,
                                borderRadius:
                                    BorderRadius.circular(20),
                                boxShadow: sel
                                    ? AppTheme.elevatedShadow
                                    : AppTheme.cardShadow,
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
                            style:
                                TextStyle(color: AppTheme.textMuted)),
                      )
                    else ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics:
                              const NeverScrollableScrollPhysics(),
                          itemCount: filtered.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.68,
                          ),
                          itemBuilder: (_, i) => _ProductCard(
                            product: filtered[i],
                            onAddToCart: () {
                              cart.addItem(filtered[i]
                                  as Map<String, dynamic>);
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(
                                          Icons.check_circle_outline,
                                          color: Colors.white,
                                          size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                          child: Text(
                                              '${filtered[i]['name']} added to cart')),
                                    ],
                                  ),
                                  backgroundColor:
                                      AppTheme.primaryGreen,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10)),
                                  duration:
                                      const Duration(seconds: 2),
                                  action: SnackBarAction(
                                    label: 'View Cart',
                                    textColor: Colors.white,
                                    onPressed: () =>
                                        _openCart(context, cart),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ],
                ),
              ),
            ],
          ),

          // ── Floating Cart Button ──────────────────────────────────────
          floatingActionButton: cart.totalCount > 0
              ? FloatingActionButton.extended(
                  onPressed: () => _openCart(context, cart),
                  backgroundColor: AppTheme.primaryGreen,
                  icon: const Icon(Icons.shopping_cart,
                      color: Colors.white),
                  label: Text(
                    '${cart.totalCount} item${cart.totalCount > 1 ? 's' : ''} · ₱${cart.totalPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700),
                  ),
                )
              : null,
        ),
      ),
    );
  }

  void _openCart(BuildContext context, CartProvider cart) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: cart,
        child: const _CartSheet(),
      ),
    );
  }
}

// ── Product Card ──────────────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final dynamic product;
  final VoidCallback onAddToCart;
  const _ProductCard(
      {required this.product, required this.onAddToCart});

  @override
  Widget build(BuildContext context) {
    final inStock = product['in_stock'] as bool? ?? true;
    final hasDiscount = product['original_price'] != null &&
        product['original_price'] != false;

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
            // Product image area
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
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['name'] ?? '',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(product['seller_name'] ?? '',
                        style: const TextStyle(
                            fontSize: 10, color: AppTheme.textMuted)),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: AppTheme.accentAmber, size: 13),
                        const SizedBox(width: 2),
                        Text('${product['rating']}',
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary)),
                        Text(
                            '  ·  ${product['sold']} sold',
                            style: const TextStyle(
                                fontSize: 9,
                                color: AppTheme.textMuted)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '₱${product['price']}',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryGreen),
                        ),
                        if (hasDiscount) ...[
                          const SizedBox(width: 4),
                          Text(
                            '₱${product['original_price']}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.textMuted,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text('per ${product['unit']}',
                        style: const TextStyle(
                            fontSize: 9, color: AppTheme.textMuted)),
                  ],
                ),
              ),
            ),

            // Add to cart button
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: inStock ? onAddToCart : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    disabledBackgroundColor: Colors.grey[200],
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text(
                    '+ Add to Cart',
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700),
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
    final cart =
        Provider.of<CartProvider>(context, listen: false);
    final inStock = product['in_stock'] as bool? ?? true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppTheme.dividerColor,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            // Hero image
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.mintGreen.withOpacity(0.5),
                    AppTheme.lightGreen.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Icon(Icons.inventory_2_outlined,
                    size: 64, color: AppTheme.primaryGreen),
              ),
            ),
            const SizedBox(height: 16),
            Text(product['name'] ?? '', style: AppTheme.heading1),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.storefront_outlined,
                    size: 14, color: AppTheme.textMuted),
                const SizedBox(width: 4),
                Text('Sold by: ${product['seller_name'] ?? ''}',
                    style: AppTheme.bodySmall),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: inStock
                        ? const Color(0xFFDDF3E4)
                        : const Color(0xFFFFEBEB),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    inStock ? 'In Stock' : 'Out of Stock',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: inStock
                          ? AppTheme.primaryGreen
                          : AppTheme.errorRed,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₱${product['price']}',
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryGreen),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text('/ ${product['unit']}',
                      style: AppTheme.bodySmall),
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
              child: ElevatedButton.icon(
                onPressed: inStock
                    ? () {
                        cart.addItem(
                            product as Map<String, dynamic>);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                '${product['name']} added to cart!'),
                            backgroundColor: AppTheme.primaryGreen,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(10)),
                          ),
                        );
                      }
                    : null,
                icon: const Icon(Icons.shopping_cart_outlined,
                    size: 18),
                label: const Text('Add to Cart',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Cart Bottom Sheet ─────────────────────────────────────────────────────────

class _CartSheet extends StatelessWidget {
  const _CartSheet();

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: AppTheme.dividerColor,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.shopping_cart,
                    color: AppTheme.primaryGreen),
                const SizedBox(width: 8),
                const Text('My Cart',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary)),
                const Spacer(),
                if (cart.items.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      cart.clear();
                    },
                    child: const Text('Clear all',
                        style: TextStyle(color: AppTheme.errorRed)),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Cart Items or Empty State
          Expanded(
            child: cart.items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined,
                            size: 64,
                            color: AppTheme.textMuted
                                .withOpacity(0.4)),
                        const SizedBox(height: 16),
                        const Text('Your cart is empty',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textMuted)),
                        const SizedBox(height: 6),
                        const Text('Add products from the marketplace',
                            style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textMuted)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final item = cart.items[i];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundLight,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            // Icon
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: AppTheme.mintGreen
                                    .withOpacity(0.4),
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                  Icons.inventory_2_outlined,
                                  color: AppTheme.primaryGreen,
                                  size: 26),
                            ),
                            const SizedBox(width: 12),
                            // Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(item.product['name'] ?? '',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color:
                                              AppTheme.textPrimary),
                                      maxLines: 1,
                                      overflow:
                                          TextOverflow.ellipsis),
                                  const SizedBox(height: 2),
                                  Text(
                                      '₱${item.product['price']} / ${item.product['unit']}',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.textMuted)),
                                ],
                              ),
                            ),
                            // Quantity controls
                            Row(
                              children: [
                                _qtyBtn(
                                  icon: Icons.remove,
                                  onTap: () => cart.decrement(i),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  child: Text('${item.quantity}',
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight:
                                              FontWeight.w800,
                                          color:
                                              AppTheme.textPrimary)),
                                ),
                                _qtyBtn(
                                  icon: Icons.add,
                                  onTap: () => cart.increment(i),
                                ),
                              ],
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '₱${item.subtotal.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primaryGreen),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Order Summary + Checkout
          if (cart.items.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  16 + MediaQuery.of(context).padding.bottom),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          '${cart.totalCount} item${cart.totalCount > 1 ? 's' : ''}',
                          style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13)),
                      Text(
                        'Total: ₱${cart.totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _openCheckout(context, cart),
                      icon: const Icon(Icons.payment, size: 18),
                      label: const Text('Proceed to Checkout',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _qtyBtn(
      {required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: AppTheme.primaryGreen),
      ),
    );
  }

  void _openCheckout(BuildContext context, CartProvider cart) {
    Navigator.pop(context); // close cart sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: cart,
        child: const _CheckoutSheet(),
      ),
    );
  }
}

// ── Checkout Sheet ────────────────────────────────────────────────────────────

class _CheckoutSheet extends StatefulWidget {
  const _CheckoutSheet();

  @override
  State<_CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<_CheckoutSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  String _paymentMethod = 'Cash on Delivery';
  bool _placing = false;

  final List<String> _paymentMethods = [
    'Cash on Delivery',
    'GCash',
    'PayMaya',
    'Bank Transfer',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _placeOrder(CartProvider cart) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _placing = true);
    // Simulate order processing
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    cart.clear();
    Navigator.pop(context);
    _showOrderSuccess(context);
  }

  void _showOrderSuccess(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDF3E4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: AppTheme.primaryGreen, size: 44),
              ),
              const SizedBox(height: 16),
              const Text('Order Placed!',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              const Text(
                'Your order has been placed successfully.\nThe seller will contact you shortly.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Continue Shopping',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: AppTheme.dividerColor,
                borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 14),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_ios_new,
                      size: 18, color: AppTheme.textPrimary),
                ),
                const SizedBox(width: 12),
                const Text('Checkout',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary)),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Order Summary ──────────────────────────────
                    _sectionTitle('Order Summary'),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundLight,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          ...cart.items.map((item) => Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 5),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${item.product['name']} × ${item.quantity}',
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: AppTheme
                                                .textPrimary),
                                      ),
                                    ),
                                    Text(
                                      '₱${item.subtotal.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.textPrimary),
                                    ),
                                  ],
                                ),
                              )),
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: AppTheme.textPrimary)),
                              Text(
                                '₱${cart.totalPrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 17,
                                    color: AppTheme.primaryGreen),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Delivery Info ──────────────────────────────
                    _sectionTitle('Delivery Information'),
                    const SizedBox(height: 10),
                    _buildField(
                      controller: _nameCtrl,
                      label: 'Full Name',
                      hint: 'e.g. Maria Santos',
                      icon: Icons.person_outline,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Name is required'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    _buildField(
                      controller: _phoneCtrl,
                      label: 'Phone Number',
                      hint: 'e.g. 09XXXXXXXXX',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (v) =>
                          v == null || v.trim().length < 10
                              ? 'Enter a valid phone number'
                              : null,
                    ),
                    const SizedBox(height: 10),
                    _buildField(
                      controller: _addressCtrl,
                      label: 'Delivery Address',
                      hint: 'Street, Barangay, City, Province',
                      icon: Icons.location_on_outlined,
                      maxLines: 2,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Address is required'
                          : null,
                    ),
                    const SizedBox(height: 24),

                    // ── Payment Method ─────────────────────────────
                    _sectionTitle('Payment Method'),
                    const SizedBox(height: 10),
                    ...
                    _paymentMethods.map((method) {
                      final icons = {
                        'Cash on Delivery':
                            Icons.local_shipping_outlined,
                        'GCash': Icons.account_balance_wallet_outlined,
                        'PayMaya': Icons.credit_card_outlined,
                        'Bank Transfer': Icons.account_balance_outlined,
                      };
                      return GestureDetector(
                        onTap: () => setState(
                            () => _paymentMethod = method),
                        child: AnimatedContainer(
                          duration:
                              const Duration(milliseconds: 150),
                          margin:
                              const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: _paymentMethod == method
                                ? AppTheme.primaryGreen
                                    .withOpacity(0.06)
                                : Colors.white,
                            borderRadius:
                                BorderRadius.circular(12),
                            border: Border.all(
                              color: _paymentMethod == method
                                  ? AppTheme.primaryGreen
                                  : AppTheme.dividerColor,
                              width: _paymentMethod == method
                                  ? 1.5
                                  : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(icons[method],
                                  color: _paymentMethod == method
                                      ? AppTheme.primaryGreen
                                      : AppTheme.textMuted,
                                  size: 22),
                              const SizedBox(width: 12),
                              Text(method,
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          _paymentMethod == method
                                              ? AppTheme.primaryGreen
                                              : AppTheme.textPrimary)),
                              const Spacer(),
                              if (_paymentMethod == method)
                                const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppTheme.primaryGreen,
                                    size: 20),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),

          // Place Order Button
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                12 + MediaQuery.of(context).padding.bottom),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _placing ? null : () => _placeOrder(cart),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _placing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white))
                    : Text(
                        'Place Order · ₱${cart.totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(
        title,
        style: AppTheme.heading2,
      );

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon:
                Icon(icon, color: AppTheme.textMuted, size: 20),
            filled: true,
            fillColor: AppTheme.backgroundLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
                vertical: 12, horizontal: 14),
          ),
        ),
      ],
    );
  }
}