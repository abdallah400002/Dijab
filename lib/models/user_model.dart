import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dijab/utils/safe_firestore_parse.dart';
import 'address.dart';

class UserModel {
  final String uid;
  final String email;
  final List<Address> addressBook;
  final List<CartItem> cart;

  UserModel({
    required this.uid,
    required this.email,
    this.addressBook = const [],
    this.cart = const [],
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    final addressList = (data['address_book'] as List<dynamic>? ?? [])
        .map((addr) => Address.fromMap(addr as Map<String, dynamic>))
        .toList();

    final cartList = (data['cart'] as List<dynamic>? ?? [])
        .map((item) => CartItem.fromMap(item as Map<String, dynamic>))
        .toList();

    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      addressBook: addressList,
      cart: cartList,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'address_book': addressBook.map((addr) => addr.toMap()).toList(),
      'cart': cart.map((item) => item.toMap()).toList(),
    };
  }
}

class CartItem {
  final String productId;
  final int quantity;
  final String size;
  final String color;
  final int price;

  CartItem({
    required this.productId,
    required this.quantity,
    required this.size,
    required this.color,
    required this.price,

  });

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      productId: map['productId'] ?? '',
      quantity: safeInt(map['qty'] ?? map['quantity'], 1),
      size: map['size'] ?? '',
      color: map['color'] ?? '',
      price: safeInt(map['prc'] ?? map['price'], 1),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'qty': quantity,
      'size': size,
      'color': color,
      'price': price,

    };
  }
}
