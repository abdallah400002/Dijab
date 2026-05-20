import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'bloc/auth/auth_event.dart';
import 'bloc/auth/auth_state.dart';
import 'bloc/products/products_bloc.dart';
import 'bloc/products/products_event.dart';
import 'bloc/cart/cart_bloc.dart';
import 'bloc/cart/cart_event.dart';
import 'bloc/auth/auth_bloc.dart';
import 'firebase_options.dart';
import 'repositories/product_repository.dart';
import 'repositories/user_repository.dart';
import 'repositories/order_repository.dart';
import 'theme/app_theme.dart';
import 'views/home_screen.dart';
import 'views/login_screen.dart';
import 'views/product_detail_screen.dart';
import 'views/cart_screen.dart';
import 'views/checkout_screen.dart';
import 'models/product.dart';
import 'utils/seo_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Initialize SEO for web
  if (kIsWeb) {
    SEOUtils.initializeSEO();
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize repositories
    final productRepository = ProductRepository();
    final userRepository = UserRepository();
    final orderRepository = OrderRepository();

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => ProductsBloc(productRepository)
            ..add(const LoadProducts()),
        ),
        BlocProvider(
          create: (context) => CartBloc(userRepository),
        ),
        BlocProvider(
          create: (context) => AuthBloc(userRepository)
            ..add(const AuthCheckRequested()),
        ),
      ],
      child: MaterialApp(
        title: 'dijab',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        builder: (context, child) => ResponsiveBreakpoints.builder(
          child: child!,
          breakpoints: [
            const Breakpoint(start: 0, end: 450, name: MOBILE),
            const Breakpoint(start: 451, end: 800, name: TABLET),
            const Breakpoint(start: 801, end: 1920, name: DESKTOP),
            const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
          ],
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthGate(),
          '/login': (context) => const LoginScreen(),
          '/product-detail': (context) {
            final arguments = ModalRoute.of(context)?.settings.arguments;
            if (arguments == null || arguments is! Product) {
              // If no product argument, navigate back or to home
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context).pop();
              });
              return const Scaffold(
                body: Center(
                  child: Text('Product not found'),
                ),
              );
            }
            return ProductDetailScreen(product: arguments);
          },
          '/cart': (context) => const CartScreen(),
          '/checkout': (context) {
            final arguments = ModalRoute.of(context)?.settings.arguments;
            if (arguments == null || arguments is! int) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context).pop();
              });
              return const Scaffold(
                body: Center(
                  child: Text('Invalid checkout data'),
                ),
              );
            }
            return CheckoutScreen(total: arguments);
          },
          '/order-success': (context) {
            final arguments = ModalRoute.of(context)?.settings.arguments;
            if (arguments == null || arguments is! String) {
              // If no orderId argument, navigate back or to home
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context).pop();
              });
              return const Scaffold(
                body: Center(
                  child: Text('Order ID not found'),
                ),
              );
            }
            return OrderSuccessScreen(orderId: arguments);
          },
        },
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) => current is AuthAuthenticated,
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.read<CartBloc>().add(LoadCart(state.user.uid));
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthLoading || state is AuthInitial) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (state is AuthAuthenticated) {
            return const HomeScreen();
          }
          // AuthUnauthenticated or AuthError -> show login
          return const LoginScreen();
        },
      ),
    );
  }
}

// Placeholder for order success screen
class OrderSuccessScreen extends StatelessWidget {
  final String orderId;

  const OrderSuccessScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Confirmed'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              color: AppTheme.neonAccent,
              size: 80,
            ),
            const SizedBox(height: 24),
            const Text(
              'Order Placed Successfully!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Order ID: $orderId',
              style: const TextStyle(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/',
                  (route) => false,
                );
              },
              child: const Text('Continue Shopping'),
            ),
          ],
        ),
      ),
    );
  }
}
