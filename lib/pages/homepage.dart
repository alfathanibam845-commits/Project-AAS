
import 'package:flutter/material.dart';
import 'package:item_shop/services/api.dart';
import 'package:item_shop/utils/format_currency.dart';
import 'package:item_shop/pages/payment_page.dart';
import 'package:item_shop/pages/cart_page.dart';
import 'package:item_shop/services/cart_service.dart';

/// ==========================================
/// APP COLOR PALETTE
/// ==========================================

class AppPalette {
  final bool isDark;
  final Color card;
  final Color tile;
  final Color cardBorder;
  final Color title;
  final Color subtitle;
  final Color muted;
  final Color price;
  final Color heading;
  final Color accent;
  final Color onAccent;
  final Color buttonBorder;
  final Color field;
  final Color fieldBorder;
  final Color hint;
  final Color placeholderBg;
  final Color placeholderIcon;
  final Color sheetBg;
  final Color sheetBody;
  final Color handle;

  const AppPalette._({
    required this.isDark,
    required this.card,
    required this.tile,
    required this.cardBorder,
    required this.title,
    required this.subtitle,
    required this.muted,
    required this.price,
    required this.heading,
    required this.accent,
    required this.onAccent,
    required this.buttonBorder,
    required this.field,
    required this.fieldBorder,
    required this.hint,
    required this.placeholderBg,
    required this.placeholderIcon,
    required this.sheetBg,
    required this.sheetBody,
    required this.handle,
  });

  static const _light = AppPalette._(
    isDark: false,
    card: Color(0xFFFFFFFF),
    tile: Color(0xFFFFFFFF),
    cardBorder: Color(0xFFE5EAE5),
    title: Color(0xFF26352D),
    subtitle: Color(0xFF7B887F),
    muted: Color(0xFF87928A),
    price: Color(0xFF174D3A),
    heading: Color(0xFF436452),
    accent: Color(0xFF174D3A),
    onAccent: Colors.white,
    buttonBorder: Color(0xFF174D3A),
    field: Color(0xFFE3E9E2),
    fieldBorder: Color(0xFFD5DED6),
    hint: Color(0xFF5E6B63),
    placeholderBg: Color(0xFFEFF2EE),
    placeholderIcon: Color(0xFF87928A),
    sheetBg: Colors.white,
    sheetBody: Color(0xFF58665D),
    handle: Color(0xFFD9DED8),
  );

  static const _dark = AppPalette._(
    isDark: true,
    card: Color(0xFF1B2922),
    tile: Color(0xFF1B2922),
    cardBorder: Color(0xFF34483D),
    title: Color(0xFFE0EAE3),
    subtitle: Color(0xFFB4C5BA),
    muted: Color(0xFF91A69A),
    price: Color(0xFF8BD9A9),
    heading: Color(0xFFE0EAE3),
    accent: Color(0xFF367B59),
    onAccent: Colors.white,
    buttonBorder: Color(0xFF6DAF87),
    field: Color(0xFF26382E),
    fieldBorder: Color(0xFF405649),
    hint: Color(0xFFB4C5BA),
    placeholderBg: Color(0xFF26382E),
    placeholderIcon: Color(0xFF91A69A),
    sheetBg: Color(0xFF1B2922),
    sheetBody: Color(0xFFCAD8CE),
    handle: Color(0xFF52675A),
  );

  static AppPalette of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? _dark
        : _light;
  }
}

/// ==========================================
/// HOME PAGE
/// ==========================================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _products = [];
  List<String> _categoryList = [];

  bool _loading = true;
  bool _categoryLoading = false;

  String? _error;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    refresh();
    _fetchCategories();
  }

  /// ==========================================
  /// GET PRODUCTS / REFRESH
  /// ==========================================

  Future<void> refresh() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await ApiService.get('/products');

      final data = Map<String, dynamic>.from(
        response['data'] ?? {},
      );

      final list = data['products'] as List? ?? [];

      if (!mounted) return;

      setState(() {
        _products = list
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst(
          'Exception: ',
          '',
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  /// ==========================================
  /// GET CATEGORIES
  /// ==========================================

  Future<void> _fetchCategories() async {
    if (mounted) {
      setState(() {
        _categoryLoading = true;
      });
    }

    try {
      final response = await ApiService.get('/categories');

      final list = response['data']?['categories'] as List? ?? [];

      if (!mounted) return;

      setState(() {
        _categoryList = list
            .map((item) => item['title'].toString())
            .where((title) => title.trim().isNotEmpty)
            .toSet()
            .toList();
      });
    } catch (e) {
      debugPrint('Gagal mengambil kategori: $e');
    } finally {
      if (mounted) {
        setState(() {
          _categoryLoading = false;
        });
      }
    }
  }

  /// ==========================================
  /// FILTER PRODUCTS
  /// ==========================================

  List<Map<String, dynamic>> get _filteredProducts {
    if (_selectedCategory == null) {
      return _products;
    }

    return _products.where((product) {
      return product['category']?.toString() == _selectedCategory;
    }).toList();
  }

  /// ==========================================
  /// CATEGORY BUTTONS
  /// ==========================================

  Widget _categoryFilters(AppPalette p) {
    return Wrap(
      spacing: 8,
      runSpacing: 9,
      children: [
        _categoryChip('Semua', p),
        ..._categoryList.map(
          (category) => _categoryChip(category, p),
        ),
      ],
    );
  }

  Widget _categoryChip(String category, AppPalette p) {
    final isAll = category == 'Semua';

    final selected = isAll
        ? _selectedCategory == null
        : _selectedCategory == category;

    return ChoiceChip(
      label: Text(category),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) {
        setState(() {
          _selectedCategory = isAll ? null : category;
        });
      },
      backgroundColor: p.tile,
      selectedColor: p.accent,
      side: BorderSide(
        color: selected ? p.accent : p.cardBorder,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: selected ? Colors.white : p.title,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 0,
      ),
      visualDensity: VisualDensity.compact,
    );
  }

  /// ==========================================
  /// PRODUCT DETAIL
  /// ==========================================

  void _showDetail(Map<String, dynamic> product) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ProductDetailSheet(
          product: product,
          onRefresh: refresh,
        );
      },
    );
  }

  /// ==========================================
  /// OPEN CART
  /// ==========================================

  void _openCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CartPage(),
      ),
    );
  }

  /// ==========================================
  /// PROMOTION BANNER
  /// ==========================================

  Widget _promotionBanner(AppPalette p) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(21),
      child: SizedBox(
        width: double.infinity,
        height: 180,
        child: Image.asset(
          'assets/images/Barkas.jpg',
          width: double.infinity,
          height: 180,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: p.placeholderBg,
              alignment: Alignment.center,
              child: Icon(
                Icons.image_not_supported_outlined,
                size: 40,
                color: p.placeholderIcon,
              ),
            );
          },
        ),
      ),
    );
  }

  /// ==========================================
  /// PRODUCT CARD
  /// ==========================================

  Widget _productCard(
    Map<String, dynamic> product,
    AppPalette p,
  ) {
    final imageUrl = product['imageUrl']?.toString() ?? '';
    final name = product['name']?.toString() ?? 'Untitled product';
    final category = product['category']?.toString() ?? '';

    final priceValue = num.tryParse(
          product['price']?.toString() ?? '0',
        ) ??
        0;

    final stock = int.tryParse(
          product['stock']?.toString() ?? '0',
        ) ??
        0;

    return Material(
      color: p.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _showDetail(product),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.cardBorder),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    imageUrl.isEmpty
                        ? ColoredBox(
                            color: p.placeholderBg,
                            child: Icon(
                              Icons.image_outlined,
                              size: 40,
                              color: p.placeholderIcon,
                            ),
                          )
                        : Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return ColoredBox(
                                color: p.placeholderBg,
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  size: 40,
                                  color: p.placeholderIcon,
                                ),
                              );
                            },
                          ),

                    Positioned(
                      top: 9,
                      left: 9,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          category,
                          style: const TextStyle(
                            color: Color(0xFF245541),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    if (stock <= 0)
                      Positioned(
                        top: 9,
                        right: 9,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade700,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'HABIS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: p.title,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const Spacer(),

                      Text(
                        formatRupiah(priceValue),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: p.price,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        stock <= 0 ? 'Stok habis' : 'Stok: $stock',
                        style: TextStyle(
                          color: stock <= 0 ? Colors.red : p.muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ==========================================
  /// EMPTY STATE
  /// ==========================================

  Widget _emptyState(AppPalette p) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 45),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 48,
            color: p.muted,
          ),
          const SizedBox(height: 12),
          Text(
            'No products available',
            style: TextStyle(
              color: p.title,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Products will appear here when available.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: p.muted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// ==========================================
  /// BUILD
  /// ==========================================

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 110),
          Icon(
            Icons.cloud_off_outlined,
            size: 48,
            color: p.muted,
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: p.title),
            ),
          ),
          Center(
            child: TextButton(
              onPressed: refresh,
              child: const Text('Try again'),
            ),
          ),
        ],
      );
    }

    final filteredProducts = _filteredProducts;

    return RefreshIndicator(
      onRefresh: () async {
        await refresh();
        await _fetchCategories();
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 17, 18, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BARKAS',
                            style: TextStyle(
                              color: p.accent,
                              fontSize: 23,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            'Marketplace barang bekas',
                            style: TextStyle(
                              color: p.muted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),

                      ListenableBuilder(
                        listenable: CartService.instance,
                        builder: (context, child) {
                          final totalItems =
                              CartService.instance.totalItems;

                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              IconButton(
                                onPressed: _openCart,
                                tooltip: 'Keranjang',
                                icon: Icon(
                                  Icons.shopping_cart_outlined,
                                  color: p.accent,
                                  size: 27,
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  fixedSize: const Size(46, 46),
                                  shape: const CircleBorder(),
                                ),
                              ),

                              if (totalItems > 0)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    constraints: const BoxConstraints(
                                      minWidth: 19,
                                      minHeight: 19,
                                    ),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFE45B4F),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      totalItems > 99
                                          ? '99+'
                                          : '$totalItems',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  Row(
                    children: [
                      Text(
                        'Explore Categories',
                        style: TextStyle(
                          color: p.title,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      if (_selectedCategory != null)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedCategory = null;
                            });
                          },
                          child: Text(
                            'Reset',
                            style: TextStyle(
                              color: p.accent,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  if (_categoryLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: LinearProgressIndicator(),
                    )
                  else if (_categoryList.isEmpty)
                    Text(
                      'Belum ada kategori.',
                      style: TextStyle(
                        color: p.muted,
                        fontSize: 12,
                      ),
                    )
                  else
                    _categoryFilters(p),

                  const SizedBox(height: 22),

                  _promotionBanner(p),

                  const SizedBox(height: 25),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedCategory == null
                              ? 'Recommended Products'
                              : _selectedCategory!,
                          style: TextStyle(
                            color: p.title,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        '${filteredProducts.length} items',
                        style: TextStyle(
                          color: p.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),

          if (filteredProducts.isEmpty)
            SliverToBoxAdapter(
              child: _emptyState(p),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
              sliver: SliverLayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.crossAxisExtent;

                  final columns = width < 600
                      ? 2
                      : width < 1000
                          ? 3
                          : 4;

                  return SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return _productCard(
                          filteredProducts[index],
                          p,
                        );
                      },
                      childCount: filteredProducts.length,
                    ),
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 13,
                      mainAxisSpacing: 13,
                      childAspectRatio: width < 600 ? 0.68 : 0.78,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// ==========================================
/// PRODUCT DETAIL BOTTOM SHEET
/// ==========================================

class ProductDetailSheet extends StatelessWidget {
  final Map<String, dynamic> product;
  final Future<void> Function() onRefresh;

  const ProductDetailSheet({
    super.key,
    required this.product,
    required this.onRefresh,
  });

  /// ==========================================
  /// SNACKBAR VALIDATION
  /// ==========================================

  void _showMessage(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    final messenger = ScaffoldMessenger.of(context);

    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        backgroundColor: isError
            ? Colors.red.shade700
            : const Color(0xFF174D3A),
      ),
    );
  }

  /// ==========================================
  /// ADD PRODUCT TO CART
  /// ==========================================

  void _addToCart(BuildContext context, int stock) {
    final cart = CartService.instance;

    if (stock <= 0) {
      _showMessage(
        context,
        'Maaf, stok produk sedang habis.',
        isError: true,
      );
      return;
    }

    final productId = int.tryParse(
      product['id']?.toString() ?? '',
    );

    if (productId == null) {
      _showMessage(
        context,
        'Data produk tidak valid.',
        isError: true,
      );
      return;
    }

    final existingItems = cart.items.where(
      (item) => item.product.id == productId,
    );

    if (existingItems.isNotEmpty &&
        existingItems.first.quantity >= stock) {
      _showMessage(
        context,
        'Jumlah produk sudah mencapai batas stok ($stock).',
        isError: true,
      );
      return;
    }

    cart.addProduct(product);

    final updatedItem = cart.items.firstWhere(
      (item) => item.product.id == productId,
    );

    _showMessage(
      context,
      'Berhasil ditambahkan! Jumlah di keranjang: ${updatedItem.quantity}',
    );
  }

  /// ==========================================
  /// BUILD DETAIL
  /// ==========================================

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    final imageUrl = product['imageUrl']?.toString() ?? '';
    final description = product['description']?.toString() ?? '';

    final priceValue = num.tryParse(
          product['price']?.toString() ?? '0',
        ) ??
        0;

    final stock = int.tryParse(
          product['stock']?.toString() ?? '0',
        ) ??
        0;

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.88,
      decoration: BoxDecoration(
        color: p.sheetBg,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 13, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: p.handle,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(17),
                    child: AspectRatio(
                      aspectRatio: 16 / 10,
                      child: imageUrl.isEmpty
                          ? ColoredBox(
                              color: p.placeholderBg,
                              child: Icon(
                                Icons.image_outlined,
                                size: 50,
                                color: p.placeholderIcon,
                              ),
                            )
                          : Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return ColoredBox(
                                  color: p.placeholderBg,
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    size: 50,
                                    color: p.placeholderIcon,
                                  ),
                                );
                              },
                            ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  Text(
                    product['category']?.toString() ?? '',
                    style: TextStyle(
                      color: p.subtitle,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    product['name']?.toString() ?? '',
                    style: TextStyle(
                      color: p.title,
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 9),

                  Text(
                    formatRupiah(priceValue),
                    style: TextStyle(
                      color: p.price,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 7),

                  Text(
                    stock <= 0
                        ? 'Stok habis'
                        : 'Stok tersedia: $stock',
                    style: TextStyle(
                      color: stock <= 0 ? Colors.red : p.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 22),

                  Text(
                    'Product Description',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: p.title,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    description.isEmpty
                        ? 'No description provided.'
                        : description,
                    style: TextStyle(
                      color: p.sheetBody,
                      height: 1.7,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 18),
                ],
              ),
            ),
          ),

          /// ==========================================
          /// BOTTOM ACTION BUTTONS
          /// ==========================================

          SafeArea(
            top: false,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              decoration: BoxDecoration(
                color: p.sheetBg,
                border: Border(
                  top: BorderSide(
                    color: p.cardBorder,
                    width: 1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _addToCart(context, stock);
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: p.card,
                        foregroundColor: p.accent,
                        side: BorderSide(
                          color: p.buttonBorder,
                          width: 1.2,
                        ),
                        minimumSize: const Size(0, 50),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(
                        Icons.add_shopping_cart_rounded,
                        size: 19,
                      ),
                      label: const Text(
                        '+ Keranjang',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: FilledButton.icon(
                      onPressed: stock <= 0
                          ? null
                          : () async {
                              final navigator = Navigator.of(context);

                              navigator.pop();

                              final result = await navigator.push<bool>(
                                MaterialPageRoute(
                                  builder: (context) => PaymentPage(
                                    product: product,
                                  ),
                                ),
                              );

                              if (result == true) {
                                await onRefresh();
                              }
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: p.accent,
                        foregroundColor: p.onAccent,
                        minimumSize: const Size(0, 50),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(
                        Icons.shopping_bag_outlined,
                        size: 19,
                      ),
                      label: const Text(
                        'Beli',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
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
    );
  }
}
