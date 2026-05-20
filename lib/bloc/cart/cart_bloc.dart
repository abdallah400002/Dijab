import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/user_repository.dart';
import '../../models/user_model.dart';
import 'cart_event.dart';
import 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  final UserRepository _userRepository;
  String? _currentUserId;

  CartBloc(this._userRepository) : super(CartInitial()) {
    on<LoadCart>(_onLoadCart);
    on<AddToCart>(_onAddToCart);
    on<RemoveFromCart>(_onRemoveFromCart);
    on<UpdateCartItemQuantity>(_onUpdateCartItemQuantity);
    on<ClearCart>(_onClearCart);
  }

  void _onLoadCart(LoadCart event, Emitter<CartState> emit) async {
    _currentUserId = event.userId;
    emit(CartLoading());
    try {
      await emit.forEach(
        _userRepository.getUserStream(event.userId),
        onData: (user) {
          if (user != null) {
            return CartLoaded(user.cart);
          }
          return CartLoaded([]);
        },
        onError: (error, stackTrace) => CartError(error.toString()),
      );
    } catch (e) {
      emit(CartError(e.toString()));
    }
  }

  void _onAddToCart(AddToCart event, Emitter<CartState> emit) async {
    if (_currentUserId == null) {
      emit(const CartError('User not loaded'));
      return;
    }

    try {
      final user = await _userRepository.getUserById(_currentUserId!);
      if (user == null) {
        emit(const CartError('User not found'));
        return;
      }

      // Check if item already exists in cart
      final existingIndex = user.cart.indexWhere(
        (item) =>
            item.productId == event.item.productId &&
            item.size == event.item.size &&
            item.color == event.item.color,
      );

      List<CartItem> updatedCart;
      if (existingIndex >= 0) {
        // Update quantity
        updatedCart = List.from(user.cart);
        updatedCart[existingIndex] = CartItem(
          productId: event.item.productId,
          quantity: user.cart[existingIndex].quantity + event.item.quantity,
          size: event.item.size,
          color: event.item.color,
          price: event.item.price
        );
      } else {
        // Add new item
        updatedCart = [...user.cart, event.item];
      }

      await _userRepository.updateCart(_currentUserId!, updatedCart);
      emit(CartLoaded(updatedCart));
    } catch (e) {
      emit(CartError(e.toString()));
    }
  }

  void _onRemoveFromCart(
    RemoveFromCart event,
    Emitter<CartState> emit,
  ) async {
    if (_currentUserId == null) {
      emit(const CartError('User not loaded'));
      return;
    }

    try {
      final user = await _userRepository.getUserById(_currentUserId!);
      if (user == null) {
        emit(const CartError('User not found'));
        return;
      }

      final updatedCart = user.cart.where(
        (item) =>
            !(item.productId == event.productId &&
                item.size == event.size &&
                item.color == event.color),
      ).toList();

      await _userRepository.updateCart(_currentUserId!, updatedCart);
      emit(CartLoaded(updatedCart));
    } catch (e) {
      emit(CartError(e.toString()));
    }
  }

  void _onUpdateCartItemQuantity(
    UpdateCartItemQuantity event,
    Emitter<CartState> emit,
  ) async {
    if (_currentUserId == null) {
      emit(const CartError('User not loaded'));
      return;
    }

    try {
      final user = await _userRepository.getUserById(_currentUserId!);
      if (user == null) {
        emit(const CartError('User not found'));
        return;
      }

      final updatedCart = user.cart.map((item) {
        if (item.productId == event.productId &&
            item.size == event.size &&
            item.color == event.color) {
          return CartItem(
            productId: item.productId,
            quantity: event.quantity,
            size: item.size,
            color: item.color,
            price: item.price
          );
        }
        return item;
      }).where((item) => item.quantity > 0).toList();

      await _userRepository.updateCart(_currentUserId!, updatedCart);
      emit(CartLoaded(updatedCart));
    } catch (e) {
      emit(CartError(e.toString()));
    }
  }

  void _onClearCart(ClearCart event, Emitter<CartState> emit) async {
    if (_currentUserId == null) {
      emit(const CartError('User not loaded'));
      return;
    }

    try {
      await _userRepository.updateCart(_currentUserId!, []);
      emit(const CartLoaded([]));
    } catch (e) {
      emit(CartError(e.toString()));
    }
  }
}
