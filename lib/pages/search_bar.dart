
import 'package:flutter/material.dart';
import 'package:item_shop/pages/homepage.dart';
import 'package:item_shop/services/api.dart';
import 'package:item_shop/utils/format_currency.dart';

class SearchPage extends StatefulWidget {
  final bool autoFocus;

  const SearchPage({
    super.key,
    this.autoFocus = false,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();

  List<Map<String, dynamic>> _products = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
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

        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    final query = _controller.text.trim().toLowerCase();

    final filtered = _products.where((product) {
      final name =
          product['name']?.toString().toLowerCase() ?? '';

      final category =
          product['category']?.toString().toLowerCase() ?? '';

      return name.contains(query) || category.contains(query);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: TextField(
            controller: _controller,
            autofocus: widget.autoFocus,
            onChanged: (value) => setState(() {}),
            style: TextStyle(color: p.title),
            cursorColor: p.title,
            decoration: InputDecoration(
              hintText: 'Search products or categories',
              hintStyle: TextStyle(color: p.hint),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: p.subtitle,
              ),
              suffixIcon: IconButton(
                onPressed: () {
                  _controller.clear();
                  setState(() {});
                },
                icon: Icon(
                  Icons.close_rounded,
                  color: p.subtitle,
                ),
              ),
              filled: true,
              fillColor: p.field,
              focusColor: Colors.transparent,
              hoverColor: Colors.transparent,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: p.fieldBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: p.fieldBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(
                  color: p.isDark
                      ? const Color(0xFF7CE0A3)
                      : const Color.fromARGB(255, 255, 102, 102),
                  width: 1.4,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: p.title),
                        ),
                      ),
                    )
                  : filtered.isEmpty
                      ? Center(
                          child: Text(
                            'No matching products found.',
                            style: TextStyle(color: p.title),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                            16,
                            0,
                            16,
                            20,
                          ),
                          itemCount: filtered.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final product = filtered[index];

                            final image =
                                product['imageUrl']?.toString() ?? '';

                            final priceValue = num.tryParse(
                                  product['price']?.toString() ?? '0',
                                ) ??
                                0;

                            return Card(
                              color: p.tile,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                                side: BorderSide(
                                  color: p.isDark
                                      ? p.cardBorder
                                      : const Color(0xFFE8ECE8),
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(10),
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: SizedBox(
                                    width: 58,
                                    height: 58,
                                    child: image.isEmpty
                                        ? ColoredBox(
                                            color: p.placeholderBg,
                                            child: Icon(
                                              Icons.image_outlined,
                                              color: p.placeholderIcon,
                                            ),
                                          )
                                        : Image.network(
                                            image,
                                            fit: BoxFit.cover,
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
                                              return ColoredBox(
                                                color: p.placeholderBg,
                                                child: Icon(
                                                  Icons.broken_image_outlined,
                                                  color: p.placeholderIcon,
                                                ),
                                              );
                                            },
                                          ),
                                  ),
                                ),
                                title: Text(
                                  product['name']?.toString() ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: p.title,
                                  ),
                                ),
                                subtitle: Text(
                                  '${product['category'] ?? ''}  •  ${formatRupiah(priceValue)}',
                                  style: TextStyle(color: p.subtitle),
                                ),
                                trailing: Icon(
                                  Icons.chevron_right_rounded,
                                  color: p.subtitle,
                                ),
                                onTap: () {
                                  showModalBottomSheet<void>(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) {
                                      return ProductDetailSheet(
                                        product: product,
                                        onRefresh: _load,
                                      );
                                    },
                                  );
                                },
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }
}
