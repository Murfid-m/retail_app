import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/product_provider.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';
import '../../widgets/image_carousel.dart';

class AddEditProductScreen extends StatefulWidget {
  final ProductModel? product;

  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  String _selectedCategory = ProductCategory.kaos;
  List<String> _selectedSizes = []; // Selected sizes for the product

  // Image related - Multi-image support
  List<String> _imageUrls = []; // Existing image URLs
  List<Uint8List> _newImageBytes = []; // New images to upload
  List<String> _newImageNames = []; // Names for new images
  bool _isUploadingImage = false;
  final ProductService _productService = ProductService();
  static const int maxImages = 5;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.product!.name;
      _descriptionController.text = widget.product!.description;
      _priceController.text = widget.product!.price.toStringAsFixed(0);
      _stockController.text = widget.product!.stock.toString();
      _imageUrls = List.from(widget.product!.allImages);
      _selectedCategory = widget.product!.category;
      _selectedSizes = List.from(widget.product!.availableSizes);
    } else {
      // Set default sizes based on initial category
      _selectedSizes = List.from(ProductModel.getDefaultSizesForCategory(_selectedCategory));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  int get _totalImages => _imageUrls.length + _newImageBytes.length;

  Future<void> _pickImage() async {
    if (_totalImages >= maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maksimal $maxImages gambar')),
      );
      return;
    }

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _newImageBytes.add(bytes);
          _newImageNames.add(image.name);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memilih gambar: $e')));
      }
    }
  }

  void _removeExistingImage(int index) {
    setState(() {
      _imageUrls.removeAt(index);
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImageBytes.removeAt(index);
      _newImageNames.removeAt(index);
    });
  }

  Future<List<String>> _uploadAllNewImages() async {
    List<String> uploadedUrls = [];

    for (int i = 0; i < _newImageBytes.length; i++) {
      try {
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${_newImageNames[i]}';
        final url = await _productService.uploadProductImageBytes(
          _newImageBytes[i],
          fileName,
        );
        if (url != null) {
          uploadedUrls.add(url);
        }
      } catch (e) {
        print('Error uploading image $i: $e');
      }
    }

    return uploadedUrls;
  }

  Widget _buildImagePlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 50,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            'Tap untuk pilih gambar',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGallery() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image preview section
        if (_imageUrls.isEmpty && _newImageBytes.isEmpty)
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: _buildImagePlaceholder(),
            ),
          )
        else
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // Existing images
                ..._imageUrls.asMap().entries.map((entry) {
                  return _buildImageThumbnail(
                    imageWidget: Image.network(
                      entry.value,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.broken_image),
                    ),
                    index: entry.key,
                    isNew: false,
                    isPrimary: entry.key == 0 && _newImageBytes.isEmpty,
                  );
                }),
                // New images to upload
                ..._newImageBytes.asMap().entries.map((entry) {
                  return _buildImageThumbnail(
                    imageWidget: Image.memory(
                      entry.value,
                      fit: BoxFit.cover,
                    ),
                    index: entry.key,
                    isNew: true,
                    isPrimary: _imageUrls.isEmpty && entry.key == 0,
                  );
                }),
                // Add more button
                if (_totalImages < maxImages)
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 80,
                      height: 80,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).primaryColor,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.add_photo_alternate,
                        color: Theme.of(context).primaryColor,
                        size: 32,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        
        const SizedBox(height: 8),
        Text(
          'Gambar: $_totalImages/$maxImages (Gambar pertama = utama)',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildImageThumbnail({
    required Widget imageWidget,
    required int index,
    required bool isNew,
    required bool isPrimary,
  }) {
    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isPrimary ? Theme.of(context).primaryColor : Colors.grey[300]!,
              width: isPrimary ? 2 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: imageWidget,
          ),
        ),
        // Remove button
        Positioned(
          top: -4,
          right: 4,
          child: GestureDetector(
            onTap: () {
              if (isNew) {
                _removeNewImage(index);
              } else {
                _removeExistingImage(index);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 12),
            ),
          ),
        ),
        // Primary badge
        if (isPrimary)
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Utama',
                style: TextStyle(color: Colors.white, fontSize: 8),
              ),
            ),
          ),
        // New badge
        if (isNew)
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Baru',
                style: TextStyle(color: Colors.white, fontSize: 8),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSizeSelector() {
    final allSizes = ProductModel.getDefaultSizesForCategory(_selectedCategory);
    final isShoeCategory = _selectedCategory == ProductCategory.sepatu;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isShoeCategory ? Icons.straighten : Icons.format_size,
                  color: const Color(0xFFFFC20E),
                ),
                const SizedBox(width: 8),
                Text(
                  isShoeCategory ? 'Ukuran Sepatu Tersedia' : 'Ukuran Tersedia',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      if (_selectedSizes.length == allSizes.length) {
                        _selectedSizes.clear();
                      } else {
                        _selectedSizes = List.from(allSizes);
                      }
                    });
                  },
                  child: Text(
                    _selectedSizes.length == allSizes.length 
                        ? 'Hapus Semua' 
                        : 'Pilih Semua',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Pilih ukuran yang tersedia untuk produk ini',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: allSizes.map((size) {
                final isSelected = _selectedSizes.contains(size);
                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedSizes.remove(size);
                      } else {
                        _selectedSizes.add(size);
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    constraints: BoxConstraints(
                      minWidth: isShoeCategory ? 45 : 50,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFFFC20E) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? const Color(0xFFFFC20E) : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      size,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.black : Colors.grey[700],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Text(
              'Terpilih: ${_selectedSizes.length} ukuran',
              style: TextStyle(
                color: _selectedSizes.isEmpty ? Colors.red : Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      // Check if at least one image exists
      if (_totalImages == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih minimal 1 gambar produk')),
        );
        return;
      }

      setState(() {
        _isUploadingImage = true;
      });

      final productProvider = Provider.of<ProductProvider>(
        context,
        listen: false,
      );

      // Upload new images
      List<String> uploadedUrls = await _uploadAllNewImages();
      
      // Combine existing and new image URLs
      List<String> allImageUrls = [..._imageUrls, ...uploadedUrls];
      
      // Primary image is the first one
      String primaryImageUrl = allImageUrls.isNotEmpty ? allImageUrls.first : '';
      // Additional images
      List<String> additionalImages = allImageUrls.length > 1 
          ? allImageUrls.sublist(1) 
          : [];

      setState(() {
        _isUploadingImage = false;
      });

      final product = ProductModel(
        id: widget.product?.id ?? '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text),
        category: _selectedCategory,
        imageUrl: primaryImageUrl,
        imageUrls: additionalImages,
        stock: int.parse(_stockController.text),
        createdAt: widget.product?.createdAt ?? DateTime.now(),
        averageRating: widget.product?.averageRating ?? 0,
        totalReviews: widget.product?.totalReviews ?? 0,
        availableSizes: _selectedSizes,
      );

      bool success;
      if (_isEditing) {
        success = await productProvider.updateProduct(product);
      } else {
        success = await productProvider.addProduct(product);
      }

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Produk berhasil diperbarui'
                  : 'Produk berhasil ditambahkan',
            ),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(productProvider.error ?? 'Terjadi kesalahan')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Produk' : 'Tambah Produk')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Multi-image gallery
              if (_isUploadingImage)
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 8),
                        Text('Mengupload gambar...'),
                      ],
                    ),
                  ),
                )
              else
                _buildImageGallery(),
              const SizedBox(height: 16),

              // Name field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nama Produk',
                  prefixIcon: const Icon(Icons.shopping_bag_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama produk harus diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Kategori',
                  prefixIcon: const Icon(Icons.category_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: ProductCategory.all.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value ?? ProductCategory.kaos;
                    // Update sizes when category changes (only if not editing)
                    if (!_isEditing || _selectedSizes.isEmpty) {
                      _selectedSizes = List.from(
                        ProductModel.getDefaultSizesForCategory(_selectedCategory),
                      );
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Size selector (only for categories that support sizes)
              if (ProductModel.categorySupportsSizes(_selectedCategory))
                _buildSizeSelector(),

              // Price field
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Harga',
                  prefixIcon: const Icon(Icons.attach_money),
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Harga harus diisi';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Harga tidak valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Stock field
              TextFormField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Stok',
                  prefixIcon: const Icon(Icons.inventory_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Stok harus diisi';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Stok tidak valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description field
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Deskripsi',
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 70),
                    child: Icon(Icons.description_outlined),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Save button
              Consumer<ProductProvider>(
                builder: (context, productProvider, child) {
                  return ElevatedButton(
                    onPressed: productProvider.isLoading ? null : _saveProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isEditing ? const Color(0xFFFFC20E) : null,
                      foregroundColor: _isEditing ? Colors.black : null,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: productProvider.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _isEditing ? 'Simpan Perubahan' : 'Tambah Produk',
                            style: const TextStyle(fontSize: 16),
                          ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
