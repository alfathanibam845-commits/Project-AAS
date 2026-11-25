
import 'package:flutter/foundation.dart';
import 'package:item_shop/models/product_model.dart';

class CartItem {
  final ProductModel product;
  int quantity;
  bool selected;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.selected = true,
  });
}

class CartService extends ChangeNotifier {
  CartService._();

  static final CartService instance = CartService._();

  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  List<CartItem> get selectedItems =>
      _items.where((item) => item.selected).toList();

  int get totalItems =>
      _items.fold(0, (total, item) => total + item.quantity);

  double get selectedTotal {
    return selectedItems.fold(
      0.0,
      (total, item) =>
          total + (item.product.price * item.quantity),
    );
  }

  bool get isAllSelected =>
      _items.isNotEmpty && _items.every((item) => item.selected);

  // Menambahkan produk ke keranjang.
  // true = berhasil, false = gagal karena stok.
  bool addProduct(Map<String, dynamic> json) {
    final product = ProductModel.fromJson(json);

    // Validasi stok kosong.
    if (product.stock <= 0) {
      return false;
    }

    final index = _items.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (index != -1) {
      // Validasi batas stok.
      if (_items[index].quantity >= product.stock) {
        return false;
      }

      _items[index].quantity++;
    } else {
      _items.add(CartItem(product: product));
    }

    notifyListeners();
    return true;
  }

  // Memperbarui stok produk berdasarkan data terbaru dari API.
  void updateProductStock(int productId, int newStock) {
    final index = _items.indexWhere(
      (item) => item.product.id == productId,
    );

    if (index == -1) return;

    final currentItem = _items[index];

    // Hapus produk jika stok habis.
    if (newStock <= 0) {
      _items.removeAt(index);
      notifyListeners();
      return;
    }

    // Perbarui stok tanpa menghilangkan data produk lainnya.
    final updatedProduct = currentItem.product.copyWith(
      stock: newStock,
    );

    // Sesuaikan jumlah jika melebihi stok terbaru.
    final updatedQuantity = currentItem.quantity > newStock
        ? newStock
        : currentItem.quantity;

    _items[index] = CartItem(
      product: updatedProduct,
      quantity: updatedQuantity,
      selected: currentItem.selected,
    );

    notifyListeners();
  }

  // Menambah jumlah produk.
  void increase(CartItem item) {
    if (item.quantity < item.product.stock) {
      item.quantity++;
      notifyListeners();
    }
  }

  // Mengurangi jumlah produk.
  void decrease(CartItem item) {
    if (item.quantity > 1) {
      item.quantity--;
      notifyListeners();
    }
  }

  // Memilih atau membatalkan pilihan produk.
  void toggleItem(CartItem item, bool value) {
    item.selected = value;
    notifyListeners();
  }

  // Memilih atau membatalkan semua produk.
  void toggleAll(bool value) {
    for (final item in _items) {
      item.selected = value;
    }

    notifyListeners();
  }

  // Menghapus satu produk.
  void remove(CartItem item) {
    _items.remove(item);
    notifyListeners();
  }

  // Menghapus semua produk yang dipilih.
  void clearSelected() {
    _items.removeWhere((item) => item.selected);
    notifyListeners();
  }
}
