import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../bloc/products/products_bloc.dart';
import '../bloc/products/products_event.dart';
import '../bloc/products/products_state.dart';
import '../widgets/product_grid.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final breakpoints = ResponsiveBreakpoints.of(context);
    final isDesktop = breakpoints.largerThan(TABLET);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dijab'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () {
              Navigator.pushNamed(context, '/cart');
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 1200 : 800,
          ),
          child: BlocBuilder<ProductsBloc, ProductsState>(
            builder: (context, state) {
              if (state is ProductsLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.neonAccent,
                  ),
                );
              }

              if (state is ProductsError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppTheme.neonAccent,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        state.message,
                        style:
                        const TextStyle(color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context
                              .read<ProductsBloc>()
                              .add(const LoadProducts());
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              if (state is ProductsLoaded) {
                if (state.products.isEmpty) {
                  return const Center(
                    child: Text(
                      'No products available',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  );
                }

                return ProductGrid(
                  products: state.products,
                  onProductTap: (product) {
                    Navigator.pushNamed(
                      context,
                      '/product-detail',
                      arguments: product,
                    );
                  },
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}
