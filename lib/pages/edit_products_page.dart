import 'package:flutter/material.dart';
import 'package:item_shop/pages/form_page.dart';
import 'package:item_shop/pages/homepage.dart';
import 'package:item_shop/services/api.dart';
import 'package:item_shop/utils/format_currency.dart';

class EditProductsPage extends StatefulWidget {
  final VoidCallback onChanged;

  const EditProductsPage({
    super.key,
    required this.onChanged,
  });

  @override
  State<EditProductsPage> createState() => _EditProductsPageState();
}

class _EditProductsPageState extends State<EditProductsPage> {
  List<Map<String, dynamic>> _products = [];

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  // ==========================================
  // LOAD PRODUCTS
  // ==========================================

  Future<void> _loadProducts() async {
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
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  // ==========================================
  // EDIT PRODUCT
  // ==========================================

  Future<void> _editProduct(
    Map<String, dynamic> product,
  ) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => FormPage(product: product),
      ),
    );

    if (updated == true && mounted) {
      await _loadProducts();
      widget.onChanged();
    }
  }

  // ==========================================
  // DELETE PRODUCT
  // ==========================================

  Future<void> _deleteProduct(
    Map<String, dynamic> product,
  ) async {
    final name = product['name']?.toString() ?? 'produk ini';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus produk?'),
        content: Text(
          'Apakah kamu yakin ingin menghapus "$name"? '
          'Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, false);
            },
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final id = product['id'];

      await ApiService.delete('/products/$id');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produk berhasil dihapus.'),
        ),
      );

      await _loadProducts();
      widget.onChanged();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  // ==========================================
  // ACTION BUTTONS
  // ==========================================

  Widget _actionButtons(Map<String, dynamic> product, AppPalette p) {
    final deleteColor =
        p.isDark ? const Color(0xFFFF8A8A) : const Color(0xFFE65353);
    final editColor =
        p.isDark ? const Color(0xFF7CE0A3) : const Color(0xFF36A853);
    final bgOpacity = p.isDark ? 0.18 : 0.10;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // DELETE BUTTON
        Material(
          color: Colors.red.withOpacity(bgOpacity),
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _deleteProduct(product),
            child: SizedBox(
              width: 43,
              height: 66,
              child: Icon(
                Icons.delete_outline_rounded,
                color: deleteColor,
                size: 21,
              ),
            ),
          ),
        ),

        const SizedBox(width: 7),

        // EDIT BUTTON
        Material(
          color: const Color(0xFF36A853).withOpacity(bgOpacity),
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _editProduct(product),
            child: SizedBox(
              width: 43,
              height: 66,
              child: Icon(
                Icons.edit_outlined,
                color: editColor,
                size: 21,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // PRODUCT CARD
  // ==========================================

  Widget _productCard(Map<String, dynamic> product) {
    final p = AppPalette.of(context);

    final imageUrl = product['imageUrl']?.toString() ?? '';

    final name = product['name']?.toString() ?? 'Untitled';

    final category = product['category']?.toString() ?? '';

    final price =
        num.tryParse(product['price']?.toString() ?? '0') ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: p.cardBorder),
      ),
      child: Row(
        children: [
          // PRODUCT IMAGE
          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: SizedBox(
              width: 66,
              height: 66,
              child: imageUrl.isEmpty
                  ? ColoredBox(
                      color: p.placeholderBg,
                      child: Icon(
                        Icons.image_outlined,
                        size: 28,
                        color: p.placeholderIcon,
                      ),
                    )
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return ColoredBox(
                          color: p.placeholderBg,
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: 28,
                            color: p.placeholderIcon,
                          ),
                        );
                      },
                    ),
            ),
          ),

          const SizedBox(width: 12),

          // PRODUCT INFORMATION
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: p.title,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: p.subtitle,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  formatRupiah(price),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: p.price,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // EDIT & DELETE BUTTONS
          _actionButtons(product, p),
        ],
      ),
    );
  }

  // ==========================================
  // BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _error != null
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 120),

                    Icon(
                      Icons.cloud_off_outlined,
                      size: 45,
                      color: p.muted,
                    ),

                    const SizedBox(height: 12),

                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 25,
                        ),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: p.title),
                        ),
                      ),
                    ),

                    Center(
                      child: TextButton(
                        onPressed: _loadProducts,
                        child: const Text('Try again'),
                      ),
                    ),
                  ],
                )
              : _products.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 130),

                        Icon(
                          Icons.inventory_2_outlined,
                          size: 50,
                          color: p.muted,
                        ),

                        const SizedBox(height: 12),

                        Center(
                          child: Text(
                            'No products available',
                            style: TextStyle(color: p.title),
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        16,
                        16,
                        30,
                      ),
                      children: [
                        Text(
                          'Manage products',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            color: p.heading,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          '${_products.length} products available',
                          style: TextStyle(
                            color: p.muted,
                            fontSize: 12,
                          ),
                        ),

                        const SizedBox(height: 18),

                        ..._products.map(_productCard),
                      ],
                    ),
    );
  }
}
