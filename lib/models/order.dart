import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dijab/utils/safe_firestore_parse.dart';
import 'address.dart';

class Order {
  final String id;
  final String userId;
  final String contact;
  final String? phoneNumber;
  final List<OrderItem> items;
  final OrderStatus status;
  final DateTime createdAt;
  final int total;
  final int shippingCost;
  final Address? shippingAddress;

  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.status,
    required this.total,
    required this.shippingCost,
    required this.createdAt,
    required this.contact,
    this.phoneNumber,
    this.shippingAddress,
  });

  factory Order.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    final itemsList = (data['items'] as List<dynamic>? ?? [])
        .map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
        .toList();

    final timestamp = data['createdAt'] as Timestamp?;
    final address = data['shipping_address'] != null
        ? Address.fromMap(data['shipping_address'] as Map<String, dynamic>)
        : null;

    return Order(
      id: doc.id,
      userId: data['userId'] ?? '',
      items: itemsList,
      status: OrderStatus.fromString(data['status'] ?? 'pending'),
      total: safeInt(data['total']),
      shippingCost: safeInt(data['shippingCost']),
      createdAt: timestamp?.toDate() ?? DateTime.now(),
      contact: data['contact'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      shippingAddress: address,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'items': items.map((item) => item.toMap()).toList(),
      'status': status.toString(),
      'total': total,
      'shippingCost': shippingCost,
      'contact': contact,
      'createdAt': Timestamp.fromDate(createdAt),
      if (shippingAddress != null)
        'shipping_address': shippingAddress!.toMap(),
      'phoneNumber': phoneNumber!.toString(),

    };
  }

  String get totalFormatted => '$total EGP';
}

class OrderItem {
  final String name;
  final int quantity;
  final int price;
  final String size;
  final String color;

  OrderItem({
    required this.name,
    required this.quantity,
    required this.price,
    required this.size,
    required this.color,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      name: map['name'] ?? '',
      quantity: safeInt(map['qty'] ?? map['quantity'], 1),
      price: safeInt(map['price']),
      size: map['size'] ?? '',
      color: map['color'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'qty': quantity,
      'price': price,
      'size': size,
      'color': color,
    };
  }

  int get subtotal => price * quantity;
}

enum OrderStatus {
  pending,
  shipped,
  delivered,
  cancelled;

  static OrderStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return OrderStatus.pending;
      case 'shipped':
        return OrderStatus.shipped;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }

  @override
  String toString() {
    switch (this) {
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.shipped:
        return 'shipped';
      case OrderStatus.delivered:
        return 'delivered';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }
}

