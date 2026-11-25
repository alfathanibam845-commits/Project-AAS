
import 'package:flutter/material.dart';
import 'package:item_shop/services/api.dart';
import 'package:item_shop/utils/format_currency.dart';
import 'package:item_shop/pages/payment_page.dart';
import 'package:item_shop/services/cart_service.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  static const Color green = Color(0xFF174D3A);

  final CartService cart = CartService.instance;

  bool _checkingOut = false;

  @override
  void initState() {
    super.initState();
    cart.addListener(_update);
  }

  @override
  void dispose() {
    cart.removeListener(_update);
    super.dispose();
  }

  void _update() {
    if (mounted) {
      setState(() {});
    }
  }

  // Mengambil stok terbaru dari backend.
  Future<void> _refreshProductStock() async {
    try {
      final response = await ApiService.get('/products');

      final data = Map<String, dynamic>.from(
        response['data'] ?? {},
      );

      final products = data['products'] as List? ?? [];

      for (final item in products) {
        final product = Map<String, dynamic>.from(item);

        final id = int.tryParse(
          product['id']?.toString() ?? '',
        );

        if (id == null) continue;

        final stock = int.tryParse(
              product['stock']?.toString() ?? '0',
            ) ??
            0;

        cart.updateProductStock(id, stock);
      }
    } catch (e) {
      debugPrint('Gagal memperbarui stok produk: $e');
    }
  }

  // Checkout.
  Future<void> _checkout() async {
    if (_checkingOut) return;

    final selected = cart.selectedItems;

    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pilih produk yang ingin dibeli terlebih dahulu.',
          ),
        ),
      );
      return;
    }

    // Validasi stok.
    for (final item in selected) {
      if (item.quantity > item.product.stock ||
          item.product.stock <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Stok ${item.product.name} tidak mencukupi.',
            ),
          ),
        );
        return;
      }
    }

    final checkoutItems = selected.map((item) {
      return {
        'product': {
          'id': item.product.id,
          'name': item.product.name,
          'category': item.product.category,
          'price': item.product.price,
          'stock': item.product.stock,
          'description': item.product.description,
          'imageUrl': item.product.imageUrl,
        },
        'quantity': item.quantity,
      };
    }).toList();

    final firstProduct = checkoutItems.first['product']
        as Map<String, dynamic>;

    setState(() {
      _checkingOut = true;
    });

    try {
      final completed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentPage(
            product: firstProduct,
            cartItems: checkoutItems,
          ),
        ),
      );

      if (completed == true && mounted) {
        // Ambil stok terbaru setelah checkout berhasil.
        await _refreshProductStock();

        if (!mounted) return;

        // Hapus produk yang sudah dibeli.
        cart.clearSelected();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Checkout berhasil. Stok produk telah diperbarui.',
            ),
            backgroundColor: green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Checkout gagal: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _checkingOut = false;
        });
      }
    }
  }

  // Kartu produk di keranjang.
  Widget _cartItem(CartItem item) {
    final product = item.product;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: item.selected,
            activeColor: green,
            onChanged: (value) {
              cart.toggleItem(item, value ?? false);
            },
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 76,
              height: 76,
              child: product.imageUrl.isEmpty
                  ? const ColoredBox(
                      color: Color(0xFFEFF2EE),
                      child: Icon(Icons.image_outlined),
                    )
                  : Image.network(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const ColoredBox(
                          color: Color(0xFFEFF2EE),
                          child: Icon(Icons.broken_image_outlined),
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  formatRupiah(product.price),
                  style: const TextStyle(
                    color: green,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    _quantityButton(
                      icon: Icons.remove,
                      onTap: () => cart.decrease(item),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                      child: Text(
                        '${item.quantity}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _quantityButton(
                      icon: Icons.add,
                      onTap: () {
                        if (item.quantity >= product.stock) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Stok tidak mencukupi.'),
                            ),
                          );
                          return;
                        }

                        cart.increase(item);
                      },
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => cart.remove(item),
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                        size: 21,
                      ),
                    ),
                  ],
                ),
                Text(
                  product.stock <= 0
                      ? 'Stok habis'
                      : 'Stok tersedia: ${product.stock}',
                  style: TextStyle(
                    fontSize: 10,
                    color: product.stock <= 0
                        ? Colors.red
                        : Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Tombol tambah dan kurang jumlah.
  Widget _quantityButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        width: 27,
        height: 27,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.black.withValues(alpha: 0.1),
          ),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(icon, size: 15),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = cart.items;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Keranjang Saya',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 65,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 13),
                  const Text(
                    'Keranjang masih kosong',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Tambahkan produk untuk mulai berbelanja.',
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                15,
                15,
                15,
                150,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return _cartItem(items[index]);
              },
            ),
      bottomNavigationBar: items.isEmpty
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(
                  15,
                  12,
                  15,
                  12,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: cart.isAllSelected,
                          activeColor: green,
                          onChanged: (value) {
                            cart.toggleAll(value ?? false);
                          },
                        ),
                        const Text(
                          'Pilih Semua',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${cart.selectedItems.length} produk dipilih',
                          style: const TextStyle(
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 12),
                    Row(
                      children: [
                        const Text(
                          'Total Harga',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          formatRupiah(cart.selectedTotal),
                          style: const TextStyle(
                            color: green,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: cart.selectedItems.isEmpty ||
                                _checkingOut
                            ? null
                            : _checkout,
                        style: FilledButton.styleFrom(
                          backgroundColor: green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _checkingOut
                            ? const SizedBox(
                                width: 21,
                                height: 21,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Checkout',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
