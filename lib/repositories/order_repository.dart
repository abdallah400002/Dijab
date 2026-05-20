import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../models/order.dart';

class OrderRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create new order
  Future<String> createOrder(Order order) async {
    try {
      final docRef = await _firestore.collection('orders').add(order.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Error creating order: $e');
    }
  }

  // Get user orders
  Stream<List<Order>> getUserOrders(String userId) {
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Order.fromFirestore(doc))
            .toList());
  }

  // Get single order by ID
  Future<Order?> getOrderById(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      if (doc.exists) {
        return Order.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching order: $e');
    }
  }

  // Update order status
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': status.toString(),
      });
    } catch (e) {
      throw Exception('Error updating order status: $e');
    }
  }
}
