
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:item_shop/services/api.dart';

class FormPage extends StatefulWidget {
  final Map<String, dynamic>? product;

  const FormPage({super.key, this.product});

  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _price = TextEditingController();
  final _stock = TextEditingController();
  final _description = TextEditingController();

  XFile? _image;

  bool _loading = false;
  bool _categoryLoading = true;

  String? _selectedCategory;
  String? _categoryError;

  List<Map<String, dynamic>> _categories = [];

  bool get _isEditing => widget.product != null;

  String get _existingImageUrl =>
      widget.product?['imageUrl']?.toString() ?? '';

  @override
  void initState() {
    super.initState();

    final product = widget.product;

    if (product != null) {
      _name.text = product['name']?.toString() ?? '';
      _selectedCategory = product['category']?.toString();
      _price.text = product['price']?.toString() ?? '';
      _stock.text = product['stock']?.toString() ?? '';
      _description.text = product['description']?.toString() ?? '';
    }

    _fetchCategories();
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _stock.dispose();
    _description.dispose();
    super.dispose();
  }

  // AMBIL KATEGORI DARI API
  Future<void> _fetchCategories() async {
    if (mounted) {
      setState(() {
        _categoryLoading = true;
        _categoryError = null;
      });
    }

    try {
      final response = await ApiService.get('/categories');

      final rawCategories = response['data']?['categories'];

      if (rawCategories is! List) {
        throw Exception('Format data kategori tidak sesuai.');
      }

      final categories = rawCategories
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .where((item) =>
              item['title'] != null &&
              item['title'].toString().trim().isNotEmpty)
          .toList();

      // Jika kategori lama produk tidak ditemukan,
      // tetap tampilkan agar produk lama bisa diedit.
      final oldCategory = _selectedCategory;

      if (oldCategory != null &&
          oldCategory.trim().isNotEmpty &&
          !categories.any(
            (item) => item['title'].toString() == oldCategory,
          )) {
        categories.add({
          'title': oldCategory,
        });
      }

      if (!mounted) return;

      setState(() {
        _categories = categories;
        _categoryLoading = false;

        if (_selectedCategory != null &&
            !_categories.any(
              (item) =>
                  item['title'].toString() == _selectedCategory,
            )) {
          _selectedCategory = null;
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _categoryLoading = false;
        _categoryError = e
            .toString()
            .replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();

    final selected = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (selected != null && mounted) {
      setState(() => _image = selected);
    }
  }

  // SIMPAN PRODUK
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isEditing && _image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih gambar produk terlebih dahulu.'),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final data = {
        'name': _name.text.trim(),
        'category': _selectedCategory!,
        'price': _price.text.trim(),
        'stock': _stock.text.trim(),
        'description': _description.text.trim(),
      };

      if (_isEditing) {
        final id = widget.product!['id'];

        await ApiService.postMultiPart(
          endpoint: '/products/$id',
          method: 'PUT',
          data: data,
          image: _image,
        );
      } else {
        await ApiService.postMultiPart(
          endpoint: '/products',
          data: data,
          image: _image,
        );
      }

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
      ),
    );
  }

  // DROPDOWN KATEGORI
  Widget _categoryDropdown() {
    if (_categoryLoading) {
      return TextFormField(
        enabled: false,
        decoration: _decoration(
          'Loading categories...',
          Icons.category_outlined,
        ),
      );
    }

    if (_categoryError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gagal memuat kategori: $_categoryError',
            style: const TextStyle(
              color: Colors.red,
              fontSize: 12,
            ),
          ),
          TextButton.icon(
            onPressed: _fetchCategories,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba lagi'),
          ),
        ],
      );
    }

    if (_categories.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            value: null,
            decoration: _decoration(
              'Category',
              Icons.category_outlined,
            ),
            items: const [],
            onChanged: null,
            hint: const Text('Belum ada kategori'),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tambahkan kategori terlebih dahulu melalui pengelolaan kategori admin.',
            style: TextStyle(
              color: Colors.red,
              fontSize: 12,
            ),
          ),
          TextButton.icon(
            onPressed: _fetchCategories,
            icon: const Icon(Icons.refresh),
            label: const Text('Muat ulang kategori'),
          ),
        ],
      );
    }

    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      isExpanded: true,
      decoration: _decoration(
        'Category',
        Icons.category_outlined,
      ),
      hint: const Text('Pilih kategori produk'),
      items: _categories.map((category) {
        final title = category['title'].toString();

        return DropdownMenuItem<String>(
          value: title,
          child: Text(title),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCategory = value;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Kategori wajib dipilih.';
        }

        return null;
      },
    );
  }

  Widget _imagePreview() {
    if (_image != null) {
      return FutureBuilder(
        future: _image!.readAsBytes(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.memory(
              snapshot.data!,
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
            ),
          );
        },
      );
    }

    if (_existingImageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          _existingImageUrl,
          width: double.infinity,
          height: 180,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.broken_image_outlined,
            size: 45,
          ),
        ),
      );
    }

    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 42,
          color: Color(0xFF174D3A),
        ),
        SizedBox(height: 9),
        Text('Choose product image'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit product' : 'Add product'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                InkWell(
                  onTap: _pickImage,
                  borderRadius: BorderRadius.circular(17),
                  child: Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9EFE8),
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(
                        color: const Color(0xFFDCE5DA),
                      ),
                    ),
                    child: _imagePreview(),
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Tap the image to change it.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 20),

                TextFormField(
                  controller: _name,
                  decoration: _decoration(
                    'Product name',
                    Icons.inventory_2_outlined,
                  ),
                  validator: (v) =>
                      v == null || v.trim().length < 3
                          ? 'Nama minimal 3 karakter.'
                          : null,
                ),

                const SizedBox(height: 14),

                _categoryDropdown(),

                const SizedBox(height: 14),

                TextFormField(
                  controller: _price,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: _decoration(
                    'Price',
                    Icons.payments_outlined,
                  ),
                  validator: (v) {
                    final value = double.tryParse(v ?? '');

                    return value == null || value <= 0
                        ? 'Masukkan harga yang valid.'
                        : null;
                  },
                ),

                const SizedBox(height: 14),

                TextFormField(
                  controller: _stock,
                  keyboardType: TextInputType.number,
                  decoration: _decoration(
                    'Stock',
                    Icons.warehouse_outlined,
                  ),
                  validator: (v) {
                    final value = int.tryParse(v ?? '');

                    return value == null || value < 0
                        ? 'Masukkan stok yang valid.'
                        : null;
                  },
                ),

                const SizedBox(height: 14),

                TextFormField(
                  controller: _description,
                  minLines: 3,
                  maxLines: 5,
                  decoration: _decoration(
                    'Description',
                    Icons.notes_rounded,
                  ),
                ),

                const SizedBox(height: 22),

                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _loading ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF174D3A),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 21,
                            height: 21,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _isEditing
                                ? 'Save changes'
                                : 'Save product',
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
