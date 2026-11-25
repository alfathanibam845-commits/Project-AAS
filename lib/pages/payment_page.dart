
import 'package:flutter/material.dart';
import 'package:item_shop/utils/format_currency.dart';
import 'package:item_shop/services/api.dart';
import 'package:qr_flutter/qr_flutter.dart';

class PaymentPage extends StatefulWidget {
  final Map<String, dynamic> product;
  final List<Map<String, dynamic>>? cartItems;

  const PaymentPage({
    super.key,
    required this.product,
    this.cartItems,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  static const Color green = Color(0xFF174D3A);

  String _selectedMethod = 'Bank Transfer';
  bool _isPaying = false;

  late List<Map<String, dynamic>> _items;

  final List<Map<String, dynamic>> _methods = [
    {
      'name': 'Bank Transfer',
      'description': 'Transfer melalui rekening bank',
      'icon': Icons.account_balance_rounded,
    },
    {
      'name': 'E-Wallet',
      'description': 'GoPay, OVO, DANA, dan lainnya',
      'icon': Icons.account_balance_wallet_rounded,
    },
    {
      'name': 'QRIS',
      'description': 'Pembayaran menggunakan kode QR',
      'icon': Icons.qr_code_2_rounded,
    },
    {
      'name': 'Credit Card',
      'description': 'Visa, Mastercard, dan lainnya',
      'icon': Icons.credit_card_rounded,
    },
  ];

  // ==========================================
  // INITIALIZATION
  // ==========================================

  @override
  void initState() {
    super.initState();

    final source = widget.cartItems;

    if (source == null || source.isEmpty) {
      _items = [
        {
          'product': Map<String, dynamic>.from(widget.product),
          'quantity': 1,
        },
      ];
    } else {
      _items = source.map((item) {
        return {
          'product': Map<String, dynamic>.from(
            item['product'],
          ),
          'quantity': _quantity(item),
        };
      }).toList();
    }
  }

  List<Map<String, dynamic>> get _checkoutItems => _items;

  // ==========================================
  // PRODUCT HELPERS
  // ==========================================

  double _productPrice(Map<String, dynamic> product) {
    return double.tryParse(
          product['price']?.toString() ?? '0',
        ) ??
        0;
  }

  int _quantity(Map<String, dynamic> item) {
    return int.tryParse(
          item['quantity']?.toString() ?? '1',
        ) ??
        1;
  }

  int _stock(Map<String, dynamic> product) {
    return int.tryParse(
          product['stock']?.toString() ?? '0',
        ) ??
        0;
  }

  // ==========================================
  // QUANTITY CONTROLS
  // ==========================================

  void _changeQuantity(int index, int change) {
    if (index < 0 || index >= _items.length) return;

    final item = _items[index];
    final product = Map<String, dynamic>.from(
      item['product'],
    );

    final currentQuantity = _quantity(item);
    final availableStock = _stock(product);
    final newQuantity = currentQuantity + change;

    if (newQuantity < 1) return;

    if (newQuantity > availableStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            availableStock <= 0
                ? 'Stok produk habis'
                : 'Stok tersedia hanya $availableStock',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _items[index]['quantity'] = newQuantity;
    });
  }

  // ==========================================
  // PRICE CALCULATION
  // ==========================================

  double get _price {
    return _checkoutItems.fold<double>(
      0,
      (total, item) {
        final product = Map<String, dynamic>.from(
          item['product'],
        );

        return total +
            (_productPrice(product) * _quantity(item));
      },
    );
  }

  double get _additionalCost => 0;

  double get _total => _price + _additionalCost;

  int get _totalQuantity {
    return _checkoutItems.fold<int>(
      0,
      (total, item) => total + _quantity(item),
    );
  }

  bool get _hasInvalidQuantity {
    for (final item in _checkoutItems) {
      final product = Map<String, dynamic>.from(
        item['product'],
      );

      if (_quantity(item) < 1 ||
          _quantity(item) > _stock(product)) {
        return true;
      }
    }

    return false;
  }

  // ==========================================
  // CHECKOUT BACKEND
  // ==========================================

  Future<void> _processCheckout() async {
    if (_isPaying) return;

    if (_hasInvalidQuantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Jumlah pembelian melebihi stok yang tersedia',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isPaying = true;
    });

    try {
      final checkoutData = _checkoutItems.map((item) {
        final product = Map<String, dynamic>.from(
          item['product'],
        );

        final productId = int.tryParse(
          product['id']?.toString() ?? '',
        );

        if (productId == null || productId <= 0) {
          throw Exception(
            'ID produk ${product['name'] ?? ''} tidak valid',
          );
        }

        return {
          'productId': productId,
          'quantity': _quantity(item),
        };
      }).toList();

      final response = await ApiService.post(
        '/products/checkout',
        {
          'items': checkoutData,
        },
      );

      if (!mounted) return;

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Checkout berhasil! Stok produk diperbarui.',
            ),
            backgroundColor: green,
          ),
        );

        Navigator.pop(context, true);
      } else {
        setState(() {
          _isPaying = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message']?.toString() ??
                  'Checkout gagal',
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isPaying = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Checkout gagal: $error'),
        ),
      );
    }
  }

  // ==========================================
  // CONTINUE PAYMENT
  // ==========================================

  Future<void> _continuePayment() async {
    if (_isPaying) return;

    if (_hasInvalidQuantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Periksa jumlah dan stok produk'),
        ),
      );
      return;
    }

    if (_selectedMethod == 'QRIS') {
      final completed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => QrisScanPage(
            products: _checkoutItems,
            total: _total,
          ),
        ),
      );

      if (completed == true && mounted) {
        await _processCheckout();
      }

      return;
    }

    await _payDemo();
  }

  // ==========================================
  // DEMO PAYMENT
  // ==========================================

  Future<void> _payDemo() async {
    setState(() {
      _isPaying = true;
    });

    await Future.delayed(
      const Duration(seconds: 1),
    );

    if (!mounted) return;

    setState(() {
      _isPaying = false;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF2E9D68),
                size: 65,
              ),
              const SizedBox(height: 15),
              const Text(
                'Payment Demo',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Simulasi pembayaran ${formatRupiah(_total)} '
                'berhasil dijalankan.\n\n'
                'Pembayaran belum diproses secara nyata.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    await _processCheckout();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: green,
                  ),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // PRODUCT CARD
  // ==========================================

  Widget _productCard(
    int index,
    Color cardColor,
    Color textColor,
    Color mutedColor,
    bool isDark,
  ) {
    final item = _checkoutItems[index];

    final product = Map<String, dynamic>.from(
      item['product'],
    );

    final imageUrl =
        product['imageUrl']?.toString() ?? '';

    final name =
        product['name']?.toString() ?? 'Product';

    final category =
        product['category']?.toString() ?? '';

    final quantity = _quantity(item);
    final stock = _stock(product);
    final price = _productPrice(product);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isDark
              ? Colors.white12
              : const Color(0xFFE8ECE8),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: SizedBox(
              width: 68,
              height: 68,
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return Container(
                          color: const Color(0xFFEAF0EB),
                          child: const Icon(
                            Icons.image_not_supported_outlined,
                            color: green,
                          ),
                        );
                      },
                    )
                  : Container(
                      color: const Color(0xFFEAF0EB),
                      child: const Icon(
                        Icons.image_outlined,
                        color: green,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  category,
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  formatRupiah(price),
                  style: const TextStyle(
                    color: green,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),

                // QUANTITY CONTROLS
                Row(
                  children: [
                    _quantityButton(
                      icon: Icons.remove,
                      onTap: quantity > 1
                          ? () => _changeQuantity(index, -1)
                          : null,
                      filled: false,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                      ),
                      child: Text(
                        '$quantity',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    _quantityButton(
                      icon: Icons.add,
                      onTap: quantity < stock
                          ? () => _changeQuantity(index, 1)
                          : null,
                      filled: true,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  stock <= 0
                      ? 'Stok habis'
                      : 'Stok tersedia: $stock',
                  style: TextStyle(
                    color: stock <= 0
                        ? Colors.red
                        : mutedColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatRupiah(price * quantity),
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quantityButton({
    required IconData icon,
    required VoidCallback? onTap,
    required bool filled,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: filled
              ? (onTap == null
                  ? Colors.grey
                  : green)
              : Colors.transparent,
          border: Border.all(
            color: onTap == null
                ? Colors.grey
                : green,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: filled
              ? Colors.white
              : (onTap == null ? Colors.grey : green),
          size: 17,
        ),
      ),
    );
  }

  // ==========================================
  // BUILD PAYMENT PAGE
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    final background =
        Theme.of(context).colorScheme.surface;

    final cardColor = isDark
        ? const Color(0xFF26352F)
        : Colors.white;

    final textColor =
        Theme.of(context).colorScheme.onSurface;

    final mutedColor =
        Theme.of(context).colorScheme.onSurfaceVariant;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'Payment Method',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        backgroundColor: background,
        foregroundColor: textColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            24,
          ),
          children: [
            // ORDER SUMMARY
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order Summary',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '$_totalQuantity Items',
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 13),

            ...List.generate(
              _checkoutItems.length,
              (index) => _productCard(
                index,
                cardColor,
                textColor,
                mutedColor,
                isDark,
              ),
            ),

            const SizedBox(height: 18),

            // PAYMENT METHODS
            Text(
              'Select Payment Method',
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 13),

            ..._methods.map((method) {
              final selected =
                  _selectedMethod == method['name'];

              return Padding(
                padding: const EdgeInsets.only(
                  bottom: 10,
                ),
                child: Material(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      setState(() {
                        _selectedMethod =
                            method['name'].toString();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 15,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? green
                              : (isDark
                                  ? Colors.white12
                                  : const Color(0xFFE8ECE8)),
                          width: selected ? 1.6 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 43,
                            height: 43,
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCE9DF),
                              borderRadius:
                                  BorderRadius.circular(11),
                            ),
                            child: Icon(
                              method['icon'] as IconData,
                              color: green,
                              size: 23,
                            ),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  method['name'].toString(),
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  method['description'].toString(),
                                  style: TextStyle(
                                    color: mutedColor,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            selected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: selected ? green : mutedColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 20),

            // PAYMENT DETAILS
            Text(
              'Payment Details',
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 15),

            _priceRow(
              'Product Price',
              formatRupiah(_price),
              mutedColor,
              textColor,
            ),

            const SizedBox(height: 12),

            _priceRow(
              'Additional Cost',
              formatRupiah(_additionalCost),
              mutedColor,
              textColor,
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 15),
              child: Divider(),
            ),

            _priceRow(
              'Total Payment',
              formatRupiah(_total),
              textColor,
              green,
              bold: true,
            ),

            const SizedBox(height: 28),

            // CONTINUE BUTTON
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _isPaying || _hasInvalidQuantity
                    ? null
                    : _continuePayment,
                style: FilledButton.styleFrom(
                  backgroundColor: green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isPaying
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _selectedMethod == 'QRIS'
                            ? 'Continue to QRIS'
                            : 'Pay ${formatRupiah(_total)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 12),

            Center(
              child: Text(
                'Payment is currently in demonstration mode.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: mutedColor,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // PRICE ROW
  // ==========================================

  Widget _priceRow(
    String label,
    String value,
    Color labelColor,
    Color valueColor, {
    bool bold = false,
  }) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: 13,
            fontWeight:
                bold ? FontWeight.w800 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: bold ? 17 : 13,
            fontWeight:
                bold ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ==============================================
// QRIS SCAN PAGE
// ==============================================

class QrisScanPage extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  final double total;

  const QrisScanPage({
    super.key,
    required this.products,
    required this.total,
  });

  static const Color green = Color(0xFF174D3A);

  String get _productNames {
    return products.map((item) {
      final product = Map<String, dynamic>.from(
        item['product'],
      );

      return product['name']?.toString() ?? 'Product';
    }).join(', ');
  }

  Future<void> _completePayment(
    BuildContext context,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Selesaikan Pembayaran?'),
          content: const Text(
            'Ini hanya simulasi. Tidak ada transaksi uang '
            'yang benar-benar dilakukan.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: green,
              ),
              child: const Text('Ya, Selesai'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    final background =
        Theme.of(context).colorScheme.surface;

    final textColor =
        Theme.of(context).colorScheme.onSurface;

    final mutedColor =
        Theme.of(context).colorScheme.onSurfaceVariant;

    final qrData = [
      'ITEMSHOP-DEMO',
      'PRODUCTS:$_productNames',
      'AMOUNT:${total.toStringAsFixed(0)}',
    ].join('|');

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'QRIS Payment',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        backgroundColor: background,
        foregroundColor: textColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            const SizedBox(height: 12),

            const Icon(
              Icons.qr_code_2_rounded,
              size: 38,
              color: green,
            ),

            const SizedBox(height: 12),

            Text(
              'Scan QR Code',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 7),

            Text(
              'Pindai kode QR berikut menggunakan aplikasi '
              'pembayaran yang mendukung QRIS.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: mutedColor,
                fontSize: 13,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 28),

            // QR CODE DEMO
            Center(
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? Colors.white24
                        : const Color(0xFFE5EAE6),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.07),
                      blurRadius: 18,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 230,
                  backgroundColor: Colors.white,
                  errorCorrectionLevel:
                      QrErrorCorrectLevel.H,
                ),
              ),
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF26382E)
                    : const Color(0xFFEAF2EC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: green,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'QR ini adalah kode simulasi, bukan QRIS '
                      'aktif untuk pembayaran sungguhan.',
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFFD5E5D9)
                            : const Color(0xFF436452),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 27),

            // PAYMENT SUMMARY
            Container(
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF26352F)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white12
                      : const Color(0xFFE8ECE8),
                ),
              ),
              child: Column(
                children: [
                  _summaryRow(
                    'Products',
                    '${products.length} jenis produk',
                    textColor,
                    mutedColor,
                  ),
                  const SizedBox(height: 13),
                  _summaryRow(
                    'Payment Method',
                    'QRIS',
                    textColor,
                    mutedColor,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 13),
                    child: Divider(),
                  ),
                  _summaryRow(
                    'Total Payment',
                    formatRupiah(total),
                    green,
                    textColor,
                    bold: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              height: 53,
              child: FilledButton.icon(
                onPressed: () => _completePayment(context),
                icon: const Icon(
                  Icons.check_circle_outline_rounded,
                ),
                label: const Text(
                  'Pembayaran Selesai',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Center(
              child: Text(
                'ItemShop Payment Demo',
                style: TextStyle(
                  color: mutedColor,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value,
    Color valueColor,
    Color labelColor, {
    bool bold = false,
  }) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: labelColor,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: valueColor,
              fontSize: bold ? 16 : 13,
              fontWeight:
                  bold ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
