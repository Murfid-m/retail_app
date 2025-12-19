import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';

class ProductDetailScreen extends StatelessWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Produk'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            Container(
              height: 300,
              width: double.infinity,
              color: Colors.grey[200],
              child: product.imageUrl.isNotEmpty
                  ? Image.network(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.image_not_supported,
                          size: 100,
                          color: Colors.grey,
                        );
                      },
                    )
                  : const Icon(
                      Icons.image,
                      size: 100,
                      color: Colors.grey,
                    ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category chip
                  Chip(
                    label: Text(product.category),
                    labelStyle: const TextStyle(
                      color: Color(0xFFFFC20E),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Product name
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Price
                  Text(
                    'Rp ${_formatPrice(product.price)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0080C6),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stock info
                  Row(
                    children: [
                      Icon(
                        product.stock > 0
                            ? Icons.check_circle_outline
                            : Icons.cancel_outlined,
                        color: product.stock > 0 ? Colors.green : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        product.stock > 0
                            ? 'Stok tersedia (${product.stock})'
                            : 'Stok habis',
                        style: TextStyle(
                          color: product.stock > 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Description
                  const Text(
                    'Deskripsi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description.isNotEmpty
                        ? product.description
                        : 'Tidak ada deskripsi',
                    style: TextStyle(
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Consumer<CartProvider>(
          builder: (context, cart, child) {
            final isInCart = cart.isInCart(product.id);
            final quantity = cart.getQuantity(product.id);

            if (isInCart) {
              return Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () {
                              cart.decrementQuantity(product.id);
                            },
                          ),
                          Text(
                            '$quantity',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: product.stock > quantity
                                ? () {
                                    cart.incrementQuantity(product.id);
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Lihat Keranjang'),
                    ),
                  ),
                ],
              );
            }

            return ElevatedButton(
              onPressed: product.stock > 0
                  ? () {
                      cart.addToCart(product);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ditambahkan ke keranjang'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart_outlined),
                  const SizedBox(width: 8),
                  Text(
                    product.stock > 0
                        ? 'Tambah ke Keranjang'
                        : 'Stok Habis',
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
