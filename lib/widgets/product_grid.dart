import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';

class ProductGrid extends StatelessWidget {
  final List<Product> products;
  final Function(Product) onProductTap;

  const ProductGrid({
    super.key,
    required this.products,
    required this.onProductTap,
  });

  @override
  Widget build(BuildContext context) {
    // Responsive: 2 columns on mobile, 4 columns on desktop
    final crossAxisCount = ResponsiveValue<int>(
      context,
      defaultValue: 2,
      conditionalValues: [
        const Condition.largerThan(name: MOBILE, value: 2),
        const Condition.largerThan(name: TABLET, value: 4),
      ],
    ).value;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return ProductCard(
          product: products[index],
          onTap: () => onProductTap(products[index]),
        );
      },
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallCard = constraints.maxWidth < 180;

          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: AppTheme.cardColor,
              border: Border.all(
                color: AppTheme.neonAccent.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.neonAccent.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                Expanded(
                  flex: 3,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          'https://m.media-amazon.com/images/I/31p8b4jxUUL._AC_SR38,50_.jpg'
                          ,
                        ),

                        // CachedNetworkImage(
                        //   imageUrl: product.imageUrls.isNotEmpty
                        //       ? product.imageUrls.first
                        //       : '',
                        //   fit: BoxFit.cover,
                        //   placeholder: (context, url) => Container(
                        //     color: AppTheme.darkBackground,
                        //     child: const Center(
                        //       child: CircularProgressIndicator(
                        //         color: AppTheme.neonAccent,
                        //       ),
                        //     ),
                        //   ),
                        //   errorWidget: (context, url, error) => Container(
                        //     color: AppTheme.darkBackground,
                        //     child: const Icon(
                        //       Icons.image_not_supported,
                        //       color: AppTheme.neonAccent,
                        //     ),
                        //   ),
                        // ),
                        // Glassmorphism overlay
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  AppTheme.darkBackground.withOpacity(0.9),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Product Info
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child:
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallCard ? 8 : 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product.category,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.neonAccent.withOpacity(0.7),
                            fontSize: isSmallCard ? 8 : 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer() ,
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              product.priceFormatted,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: AppTheme.neonAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.neonAccent,
                                    AppTheme.neonAccent.withOpacity(0.7),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Add to Cart',
                                style: TextStyle(
                                  color: AppTheme.darkBackground,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
