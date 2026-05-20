import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_state.dart';
import '../bloc/cart/cart_bloc.dart';
import '../bloc/cart/cart_state.dart';
import '../bloc/cart/cart_event.dart';
import '../repositories/product_repository.dart';
import '../models/product.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        context.read<CartBloc>().add(LoadCart(authState.user.uid));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.read<CartBloc>().add(LoadCart(state.user.uid));
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Shopping Cart'),
        ),
        body: BlocBuilder<CartBloc, CartState>(
          builder: (context, cartState) {
            if (cartState is CartLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.neonAccent,
                ),
              );
            }

            if (cartState is CartError) {
              return Center(
                child: Text(
                  cartState.message,
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
              );
            }

            if (cartState is CartLoaded) {
              if (cartState.items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.shopping_cart_outlined,
                        size: 64,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Your cart is empty',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Continue Shopping'),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: cartState.items.length,
                      itemBuilder: (context, index) {
                        final item = cartState.items[index];
                        return FutureBuilder<Product?>(
                          future: ProductRepository().getProductById(item.productId),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const SizedBox.shrink();
                            }

                            final product = snapshot.data!;
                            return CartItemCard(
                              product: product,
                              cartItem: item,
                            );
                          },
                        );
                      },
                    ),
                  ),
                  // Checkout Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      border: Border(
                        top: BorderSide(
                          color: AppTheme.neonAccent.withOpacity(0.3),
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              "${_calculateTotal(cartState.items, context)} EGP",
                              style: const TextStyle(
                                color: AppTheme.neonAccent,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/checkout',arguments: _calculateTotal(cartState.items, context));
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              'Proceed to Checkout',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  int _calculateTotal(List<CartItem> items, BuildContext context) {
    // This would need to fetch product prices from repository
    // For now, return placeholder - implement with FutureBuilder if needed
    int total = 0;
    for (final item in items) {
      total += item.quantity * item.price;
      // Would need to fetch product price here
      // For now, placeholder
    }
    return total;
  }
}

class CartItemCard extends StatelessWidget {
  final Product product;
  final CartItem cartItem;

  const CartItemCard({
    super.key,
    required this.product,
    required this.cartItem,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                product.imageUrls.isNotEmpty ? product.imageUrls.first : '',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 80,
                    height: 80,
                    color: AppTheme.darkSurface,
                    child: const Icon(Icons.image_not_supported),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${cartItem.color} • ${cartItem.size}',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.priceFormatted,
                    style: const TextStyle(
                      color: AppTheme.neonAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Quantity Controls
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    if (cartItem.quantity > 1) {
                      context.read<CartBloc>().add(
                            UpdateCartItemQuantity(
                              productId: cartItem.productId,
                              size: cartItem.size,
                              color: cartItem.color,
                              quantity: cartItem.quantity - 1,
                            ),
                          );
                    }
                  },
                  color: AppTheme.neonAccent,
                ),
                Text(
                  '${cartItem.quantity}',
                  style: const TextStyle(color: Colors.white),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    context.read<CartBloc>().add(
                          UpdateCartItemQuantity(
                            productId: cartItem.productId,
                            size: cartItem.size,
                            color: cartItem.color,
                            quantity: cartItem.quantity + 1,
                          ),
                        );
                  },
                  color: AppTheme.neonAccent,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    context.read<CartBloc>().add(
                          RemoveFromCart(
                            productId: cartItem.productId,
                            size: cartItem.size,
                            color: cartItem.color,
                          ),
                        );
                  },
                  color: Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
