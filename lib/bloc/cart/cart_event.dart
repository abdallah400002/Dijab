import 'package:equatable/equatable.dart';
import '../../models/user_model.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object> get props => [];
}

class LoadCart extends CartEvent {
  final String userId;

  const LoadCart(this.userId);

  @override
  List<Object> get props => [userId];
}

class AddToCart extends CartEvent {
  final CartItem item;

  const AddToCart(this.item);

  @override
  List<Object> get props => [item];
}

class RemoveFromCart extends CartEvent {
  final String productId;
  final String size;
  final String color;

  const RemoveFromCart({
    required this.productId,
    required this.size,
    required this.color,
  });

  @override
  List<Object> get props => [productId, size, color];
}

class UpdateCartItemQuantity extends CartEvent {
  final String productId;
  final String size;
  final String color;
  final int quantity;

  const UpdateCartItemQuantity({
    required this.productId,
    required this.size,
    required this.color,
    required this.quantity,
  });

  @override
  List<Object> get props => [productId, size, color, quantity];
}

class ClearCart extends CartEvent {
  const ClearCart();
}
