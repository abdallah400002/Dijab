import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/address.dart';
import '../models/user_model.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user by ID
  Future<UserModel?> getUserById(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching user: $e');
    }
  }

  // Stream user data
  Stream<UserModel?> getUserStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  // Create or update user
  Future<void> createOrUpdateUser(UserModel user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(user.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Error saving user: $e');
    }
  }

  // Update user cart
  Future<void> updateCart(String uid, List<CartItem> cart) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'cart': cart.map((item) => item.toMap()).toList(),
      });
    } catch (e) {
      throw Exception('Error updating cart: $e');
    }
  }

  // Add address
  Future<void> addAddress(String uid, Address address) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'address_book': FieldValue.arrayUnion([address.toMap()]),
      });
    } catch (e) {
      throw Exception('Error adding address: $e');
    }
  }
}
