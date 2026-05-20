import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/cart/cart_bloc.dart';
import '../bloc/cart/cart_state.dart';
import '../bloc/cart/cart_event.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_state.dart';
import '../models/address.dart';
import '../repositories/order_repository.dart';
import '../repositories/product_repository.dart';
import '../models/order.dart';
import '../models/user_model.dart';
import '../services/payment_service.dart';
import '../theme/app_theme.dart';

class CheckoutScreen extends StatefulWidget {
  final int total;

  const CheckoutScreen({super.key,required this.total});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cityController = TextEditingController();
  final _streetController = TextEditingController();
  final _buildingController = TextEditingController();
  final _apartmentController = TextEditingController();
  final _contactController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isProcessing = false;

  bool shippingStandard = true;
  bool shippingPro = false;

  bool CODPayment = true;
  bool payMob = false;

  late int shippingCost ;
  @override
  void dispose() {
    _cityController.dispose();
    _streetController.dispose();
    _buildingController.dispose();
    _apartmentController.dispose();
    _contactController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _processOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) {
        throw Exception('User not authenticated');
      }

      final cartState = context.read<CartBloc>().state;
      if (cartState is! CartLoaded || cartState.items.isEmpty) {
        throw Exception('Cart is empty');
      }

      // Create order items
      final orderItems = <OrderItem>[];
      final productRepository = ProductRepository();
      int total = 0;

      for (final cartItem in cartState.items) {
        final product = await productRepository.getProductById(cartItem.productId);
        if (product == null) continue;

        // Check stock before proceeding
        final inStock = await productRepository.checkStock(
          cartItem.productId,
          cartItem.color,
          cartItem.size,
          cartItem.quantity,
        );

        if (!inStock) {
          throw Exception('${product.name} is out of stock');
        }

        final variantKey = '${cartItem.color}_${cartItem.size}';
        final variant = product.variants[variantKey];
        final itemPrice = product.price + (variant?.priceAdjustment ?? 0);

        orderItems.add(OrderItem(
          name: product.name,
          quantity: cartItem.quantity,
          price: itemPrice,
          size: cartItem.size,
          color: cartItem.color,
        ));

        total += itemPrice * cartItem.quantity;
      }

      // Create shipping address
      final address = Address(
        city: _cityController.text,
        street: _streetController.text,
        building: _buildingController.text.isEmpty
            ? null
            : _buildingController.text,
        apartment: _apartmentController.text.isEmpty
            ? null
            : _apartmentController.text,
      );

      // Create order
      final order = Order(

        id: '', // Will be set by repository
        userId: authState.user.uid,
        items: orderItems,
        status: OrderStatus.pending,
        total: total,
        shippingCost: shippingCost,
        createdAt: DateTime.now(),
        shippingAddress: address,
        contact: _contactController.text,
        phoneNumber: _phoneController.text.isEmpty? null : _phoneController.text,

      );

      final orderRepository = OrderRepository();
      final orderId = await orderRepository.createOrder(order);

      // Decrement stock for all items
      for (final cartItem in cartState.items) {
        await productRepository.decrementStock(
          cartItem.productId,
          cartItem.color,
          cartItem.size,
          cartItem.quantity,
        );
      }

      // Initialize payment only if Paymob is configured; otherwise complete order without payment
      final paymentService = PaymentService();
      if (PaymentService.isConfigured) {
        final paymentResult = await paymentService.initializePaymobPayment(
          amount: total,
          orderId: orderId,
          billingData: {
            'apartment': address.apartment ?? 'N/A',
            'email': authState.user.email ?? '',
            'floor': address.building ?? 'N/A',
            'first_name': authState.user.displayName ?? 'Customer',
            'street': address.street,
            'building': address.building ?? 'N/A',
            'phone_number': authState.user.phoneNumber ??'', // Get from user profile
            'shipping_method': 'Standard',
            'postal_code': '00000',
            'city': address.city,
            'country': 'EG',
            'last_name': '',
            'state': address.city,
          },
        );

        if (paymentResult['success'] != true) {
          throw Exception(paymentResult['error'] ?? 'Payment initialization failed');
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order placed. Paymob is not configured — no payment taken.'),
            backgroundColor: Colors.orange,
          ),
        );
      }

      // Clear cart and go to success
      context.read<CartBloc>().add(const ClearCart());
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/order-success',
          arguments: orderId,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    shippingCost = shippingStandard ? 100 : 250;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, cartState) {
          if (cartState is! CartLoaded) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppTheme.neonAccent,
              ),
            );
          }



          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contact',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _contactController,
                    decoration: const InputDecoration(
                      labelText: 'Email or phone number',
                      hintText: 'john.calhoun@gmail.com or 01 xxxxxxxxx',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty || !value.contains('@')) {
                        return 'Please enter valid email or phone number';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 32),

                  Text(
                    'Shipping Address',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'City',
                      hintText: 'Cairo',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter city';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _streetController,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      hintText: '123 st. Main Street',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter street address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _buildingController,
                    decoration: const InputDecoration(
                      labelText: 'Building (Optional)',
                      hintText: 'Building 5',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _apartmentController,
                    decoration: const InputDecoration(
                      labelText: 'Apartment (Optional)',
                      hintText: 'Apartment 12',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'phone (Optional)',
                      hintText: '01 xxxxxxxxx',
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Shipping method',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),

                  GestureDetector(
                    onTap: () {
                      setState(() {
                        shippingPro = false;

                        shippingStandard = true;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: shippingStandard ? AppTheme.neonAccent : Colors.white,
                          width: shippingStandard ? 2 : 1,
                        ),
                        color: shippingStandard ? AppTheme.neonAccent.withOpacity(0.2) : Colors.transparent,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Standard',
                            style: TextStyle(
                              color: shippingStandard ? AppTheme.neonAccent : Colors.white,
                              fontWeight: shippingStandard ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          const Text('100 EGP')
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  GestureDetector(
                    onTap: () {
                      setState(() {
                        shippingStandard =false;
                        shippingPro = true;

                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: shippingPro ? AppTheme.neonAccent : Colors.white,
                          width: shippingPro ? 2 : 1,
                        ),
                        color: shippingPro ? AppTheme.neonAccent.withOpacity(0.2) : Colors.transparent,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Pro',
                            style: TextStyle(
                              color: shippingPro ? AppTheme.neonAccent : Colors.white,
                              fontWeight: shippingPro ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          const Text("250 EGP")
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Payment',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),

                  GestureDetector(
                    onTap: () {
                      setState(() {
                        payMob = false;

                        CODPayment = true;
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: CODPayment ? AppTheme.neonAccent : Colors.white,
                          width: CODPayment ? 2 : 1,
                        ),
                        color: CODPayment ? AppTheme.neonAccent.withOpacity(0.2) : Colors.transparent,
                      ),
                      child: Text(
                        'Cash On Delivery (COD)',
                        style: TextStyle(
                          color: CODPayment ? AppTheme.neonAccent : Colors.white,
                          fontWeight: CODPayment ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  GestureDetector(
                    onTap: () {
                      setState(() {
                        CODPayment =false;
                        payMob = true;

                      });
                    },
                    child: Container(
                      width: double.infinity,

                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: payMob ? AppTheme.neonAccent : Colors.white,
                          width: payMob ? 2 : 1,
                        ),
                        color: payMob ? AppTheme.neonAccent.withOpacity(0.2) : Colors.transparent,
                      ),
                      child: Text(
                        'Pay With Visa',
                        style: TextStyle(
                          color: payMob ? AppTheme.neonAccent : Colors.white,
                          fontWeight: payMob ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Order Summary',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Items (${cartState.itemCount})',
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              Text(
                                '${widget.total}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10,),
                           Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Shipping cost',
                                style:  TextStyle(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              Text(
                                '$shippingCost',
                                style:  const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                '${widget.total +shippingCost}',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: AppTheme.neonAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Place Order Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _processOrder,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isProcessing
                          ? const CircularProgressIndicator(
                              color: AppTheme.darkBackground,
                            )
                          : const Text(
                              'Place Order',
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
          );
        },
      ),
    );
  }
}
