import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/money.dart';
import '../../domain/entities/product.dart';
import '../../providers/product_provider.dart';

/// Used for both "Add" (product == null) and "Edit".
class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key, this.product});
  final Product? product;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.product?.title);
  late final _brand = TextEditingController(text: widget.product?.brand);
  late final _category = TextEditingController(text: widget.product?.category);
  late final _price = TextEditingController(
    text: widget.product == null ? null : widget.product!.bdtPrice.round().toString(),
  );
  late final _stock = TextEditingController(text: widget.product?.stock.toString());
  late final _image = TextEditingController(text: widget.product?.thumbnail);
  late final _desc = TextEditingController(text: widget.product?.description);
  bool _saving = false;

  bool get _isEdit => widget.product != null;

  @override
  void dispose() {
    for (final c in [_title, _brand, _category, _price, _stock, _image, _desc]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'This field is required' : null;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final provider = context.read<ProductProvider>();
    // The form is in ৳; the API and cache store USD, so undo the local-market factor.
    final factor = priceFactor(_category.text.trim().toLowerCase(), _title.text.trim());
    final price = double.parse(_price.text.trim()) / (kUsdToBdt * factor);
    final stock = int.tryParse(_stock.text.trim()) ?? 0;
    final image = _image.text.trim();

    if (_isEdit) {
      await provider.updateProduct(
        widget.product!.copyWith(
          title: _title.text.trim(),
          brand: _brand.text.trim(),
          category: _category.text.trim().toLowerCase(),
          description: _desc.text.trim(),
          price: price,
          stock: stock,
          thumbnail: image,
          images: image.isEmpty
              ? widget.product!.images
              : [image, ...widget.product!.images.where((i) => i != image)],
        ),
      );
    } else {
      await provider.addProduct(
        title: _title.text.trim(),
        brand: _brand.text.trim(),
        category: _category.text.trim().toLowerCase(),
        description: _desc.text.trim(),
        price: price,
        stock: stock,
        imageUrl: image,
      );
    }
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(_isEdit ? 'Product updated' : 'Product added')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit product' : 'Add product')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  controller: _title,
                  validator: _required,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Title *'),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _brand,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(labelText: 'Brand'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _category,
                        validator: _required,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(labelText: 'Category *'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _price,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          final n = double.tryParse((v ?? '').trim());
                          if (n == null || n < 0) return 'Enter a valid price';
                          return null;
                        },
                        decoration: const InputDecoration(labelText: 'Price *', prefixText: '৳ '),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _stock,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          return int.tryParse(v.trim()) == null ? 'Whole number only' : null;
                        },
                        decoration: const InputDecoration(labelText: 'Stock'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _image,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Image URL (optional)'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _desc,
                  maxLines: 4,
                  validator: _required,
                  decoration: const InputDecoration(
                    labelText: 'Description *',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(_isEdit ? 'Save changes' : 'Add product'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
