import 'dart:convert';
import 'dart:typed_data';

import 'package:dijab/services/image_service.dart';
import 'package:dijab/theme/app_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product.dart';
import '../bloc/cart/cart_bloc.dart';
import '../bloc/cart/cart_event.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_state.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/user_model.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with TickerProviderStateMixin {
  String? selectedColor;
  String? selectedSize;
  int quantity = 1;
  int _currentImageIndex = 0;
  late Overlay overlay;
  OverlayEntry? overlayEntry;
  late AnimationController animationController;
  late Animation anim;
  Uint8List? _selectedImage;
  bool _isLoading = false;
  Uint8List? _imageBytes;
  final ImageService _imageService = ImageService();

  @override
  void initState() {
    super.initState();
    final colors = widget.product.getAvailableColors(selectedSize ?? '');
    if (colors.isNotEmpty) {
      selectedColor = colors.first;
      final sizes = widget.product.getAvailableSizes(selectedColor!);
      if (sizes.isNotEmpty) {
        selectedSize = sizes.first;
      }
    }
    animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    anim = Tween(begin: 0.0001, end: 5.0).animate(animationController);
    animationController.addListener(() {
      if (animationController.isDismissed) {
        overlayEntry?.remove();
        overlayEntry = null;
      }
    });
  }

  Future<void> tryOn(
      String userPhotoUrl, String productUrl, StateSetter setState) async {
    setState(() {
      _isLoading = true;
    });

    try {
      HttpsCallable callable =
          FirebaseFunctions.instance.httpsCallable('startVertexTryOn');

      final result = await callable.call({
        'personImageUrl': userPhotoUrl,
        'productImageUrl': productUrl,
      });

      setState(() {
        String base64String = result.data['tryOnImageBase64'];
        _imageBytes = base64Decode(base64String);
        _isLoading = false;
      });
    } catch (e) {
      print("Error calling Vertex AI: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> pickImage(StateSetter setState) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImage = bytes;
        _imageBytes = null;
      });
      final imageUrl = await _imageService.uploadProductImageFromBytes(
          bytes, image.name, widget.product.id);
      await tryOn(
          imageUrl, widget.product.imageUrls[_currentImageIndex], setState);
    }
  }

  void tryOnOverlay() {
    animationController.forward();
    overlayEntry = OverlayEntry(builder: (context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AnimatedBuilder(
            animation: animationController,
            builder: (context, child) => Align(
              alignment: Alignment.center,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 300,
                  height: 600,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: const Color(0xFF13151D),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      const Text("Virtual Try-On",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      Spacer(),

                      const Text(
                          "Upload your photo to see how this product looks on you!",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 20),
                      if (_isLoading)
                        const CircularProgressIndicator(
                          color: AppTheme.neonAccent,
                        )
                      else if (_imageBytes != null) // Corrected condition
                        Image.memory(
                          _imageBytes!,
                          width: 300,
                          height: 400,
                          fit: BoxFit.cover,
                        )
                      else if (_selectedImage != null)
                        Image.memory(
                          _selectedImage!,
                          width: 150,
                          height: 150,
                          fit: BoxFit.cover,
                        )
                      else
                        Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white24),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.image,
                              color: Colors.white54, size: 50),
                        ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed:
                            _isLoading ? null : () => pickImage(setState),
                        child: const Text("Upload Photo"),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () {
                          animationController.reverse();
                        },
                        child: const Text("Close",
                            style: TextStyle(color: AppTheme.neonAccent)),
                      ),
                      Spacer()
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    });
    Overlay.of(context, debugRequiredFor: widget).insert(overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = context.watch<AuthBloc>().state;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 400,
              child: PageView.builder(
                itemCount: widget.product.imageUrls.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentImageIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return CachedNetworkImage(
                    imageUrl: widget.product.imageUrls[index],
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppTheme.darkBackground,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.neonAccent,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (widget.product.imageUrls.length > 1)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.product.imageUrls.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentImageIndex == index
                            ? AppTheme.neonAccent
                            : AppTheme.textSecondary.withOpacity(0.3),
                      ),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.product.category,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.neonAccent,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.product.priceFormatted,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: tryOnOverlay,
                    child: Container(
                      width: 100,
                      height: 50,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          color: AppTheme.neonAccent),
                      child: const Center(
                        child: Text("Try on"),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text("Color : ${selectedColor ?? 'Not selected'}",
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                      )),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: widget.product
                          .getAvailableColors(selectedSize!)
                          .map((color) {
                        final isSelected = selectedColor == color;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedColor = color;
                                final sizes =
                                    widget.product.getAvailableSizes(color);
                                if (sizes.isNotEmpty) {
                                  selectedSize = sizes.first;
                                } else {
                                  selectedSize = null;
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.neonAccent
                                      : Colors.white,
                                  width: isSelected ? 2 : 1,
                                ),
                                color: isSelected
                                    ? AppTheme.neonAccent.withOpacity(0.2)
                                    : Colors.transparent,
                              ),
                              child: Text(
                                color,
                                style: TextStyle(
                                  color: isSelected
                                      ? AppTheme.neonAccent
                                      : Colors.white,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (selectedColor != null) ...[
                    Text("Size : ${selectedSize ?? 'Not selected'}",
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                        )),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: widget.product
                            .getAvailableSizes(selectedColor!)
                            .map((size) {
                          final isSelected = selectedSize == size;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedSize = size;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(2),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppTheme.neonAccent
                                        : Colors.white,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  color: isSelected
                                      ? AppTheme.neonAccent.withOpacity(0.2)
                                      : Colors.transparent,
                                ),
                                child: Text(
                                  size,
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppTheme.neonAccent
                                        : Colors.white,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    'Description',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text(
                        'Quantity',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: quantity > 1
                                ? () {
                                    setState(() {
                                      quantity--;
                                    });
                                  }
                                : null,
                            color: AppTheme.neonAccent,
                          ),
                          Text(
                            '$quantity',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              setState(() {
                                quantity++;
                              });
                            },
                            color: AppTheme.neonAccent,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (authState is AuthAuthenticated)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: selectedColor != null && selectedSize != null
                            ? () {
                                context.read<CartBloc>().add(
                                      AddToCart(
                                        CartItem(
                                          productId: widget.product.id,
                                          quantity: quantity,
                                          size: selectedSize!,
                                          color: selectedColor!,
                                          price: widget.product.price,
                                        ),
                                      ),
                                    );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Added to cart!'),
                                    backgroundColor: AppTheme.neonAccent,
                                  ),
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Add to Cart',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/login');
                        },
                        child: const Text('Login to Add to Cart'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
