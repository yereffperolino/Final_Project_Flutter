part of 'inventory_page.dart';

class _CreateProductDialog extends StatefulWidget {
  const _CreateProductDialog({this.product});

  final Product? product;

  @override
  State<_CreateProductDialog> createState() => _CreateProductDialogState();
}

class _CreateProductDialogState extends State<_CreateProductDialog> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _reorderLevel;
  final _picker = ImagePicker();
  late String _category;
  XFile? _image;
  Uint8List? _imageBytes;
  bool _uploading = false;
  String? _uploadError;

  bool get _isEditing => widget.product != null;
  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _name = TextEditingController(text: product?.name ?? '');
    _reorderLevel = TextEditingController(
      text: '${product?.reorderLevel ?? 10}',
    );
    _category = product?.category ?? 'Footwear';
  }

  @override
  void dispose() {
    _name.dispose();
    _reorderLevel.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() {
        _image = image;
        _imageBytes = bytes;
        _uploadError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _uploadError = 'Could not select product photo: $error');
    }
  }

  Future<void> _submit() async {
    if (_uploading || !_key.currentState!.validate()) return;
    setState(() {
      _uploading = true;
      _uploadError = null;
    });
    try {
      var imageUrl = '';
      final image = _image;
      if (image != null) {
        imageUrl = await CloudinaryService.uploadImage(
          bytes: _imageBytes!,
          filename: image.name,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(
        Product(
          id: widget.product?.id ?? '',
          name: _name.text.trim(),
          sku: widget.product?.sku ?? '',
          category: _category,
          variant: '',
          price: widget.product?.price ?? 0,
          stock: widget.product?.stock ?? 0,
          imageUrl: image == null ? widget.product?.imageUrl ?? '' : imageUrl,
          reorderLevel: int.parse(_reorderLevel.text),
          isArchived: widget.product?.isArchived ?? false,
        ),
      );
    } catch (error) {
      if (mounted) {
        setState(() => _uploadError = 'Could not upload product photo: $error');
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: Text(
        _isEditing ? 'Edit product' : 'Add product',
        style: const TextStyle(color: _ink),
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: _key,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ProductInput(
                  controller: _name,
                  label: 'Product name',
                  requiredField: true,
                ),
                _DropdownInput(
                  label: 'Category',
                  value: _category,
                  options: const [
                    'Footwear',
                    'Basketball',
                    'Apparel',
                    'Accessories',
                    'Equipment',
                    'Other',
                  ],
                  onChanged: (value) => setState(() => _category = value),
                ),
                _ProductInput(
                  controller: _reorderLevel,
                  label: 'Stock reorder level',
                  requiredField: true,
                  numeric: true,
                ),
                if (!_isEditing)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Text(
                      'A master product contains the shared name, category, and photo. Choose sizes and batch-specific prices when recording stock in.',
                      style: TextStyle(color: _muted, fontSize: 12),
                    ),
                  ),
                if (_isEditing)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Current total stock: ${widget.product!.stock} · '
                        'SKU: ${widget.product!.sku}',
                        style: const TextStyle(color: _muted, fontSize: 12),
                      ),
                    ),
                  ),
                const SizedBox(height: 5),
                OutlinedButton.icon(
                  onPressed: _uploading ? null : _pickImage,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(
                    _image == null ? 'Choose product photo' : 'Change photo',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _orange,
                    side: const BorderSide(color: Color(0xFFFED7AA)),
                    minimumSize: const Size(double.infinity, 44),
                  ),
                ),
                if (_image != null) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      _imageBytes!,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
                if (_uploadError != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _uploadError!,
                    style: const TextStyle(
                      color: Color(0xFFB91C1C),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _uploading ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: _orange,
            foregroundColor: Colors.white,
          ),
          child: _uploading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(_isEditing ? 'Save changes' : 'Save product'),
        ),
      ],
    );
  }
}

class _DropdownInput extends StatelessWidget {
  const _DropdownInput({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        style: const TextStyle(color: _ink, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: _muted),
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        items: [
          for (final option in options)
            DropdownMenuItem(value: option, child: Text(option)),
        ],
        onChanged: (selected) {
          if (selected != null) onChanged(selected);
        },
      ),
    );
  }
}

class _ProductInput extends StatelessWidget {
  const _ProductInput({
    required this.controller,
    required this.label,
    this.requiredField = false,
    this.numeric = false,
  });

  final TextEditingController controller;
  final String label;
  final bool requiredField;
  final bool numeric;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: numeric ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: _ink),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: _muted),
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        validator: (value) {
          final text = value?.trim() ?? '';
          if (requiredField && text.isEmpty) return 'Required';
          if (numeric && text.isNotEmpty && int.tryParse(text) == null) {
            return 'Enter a whole number';
          }
          if (numeric && text.isNotEmpty && int.parse(text) < 0) {
            return 'Cannot be negative';
          }
          return null;
        },
      ),
    );
  }
}
