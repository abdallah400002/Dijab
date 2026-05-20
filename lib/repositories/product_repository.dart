import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dijab/utils/safe_firestore_parse.dart';
import '../models/product.dart';

class ProductRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all products
  Stream<List<Product>> getAllProducts() {
    return _firestore
        .collection('products')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Product.fromFirestore(doc))
            .toList());
  }

  // Get products by category
  Stream<List<Product>> getProductsByCategory(String category) {
    return _firestore
        .collection('products')
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Product.fromFirestore(doc))
            .toList());
  }

  // Get single product by ID
  Future<Product?> getProductById(String productId) async {
    try {
      final doc = await _firestore.collection('products').doc(productId).get();
      if (doc.exists) {
        return Product.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching product: $e');
    }
  }

  // Decrement stock for a variant (used in transactions)
  Future<void> decrementStock(
    String productId,
    String color,
    String size,
    int quantity,
  ) async {
    final variantKey = '${color}_$size';
    
    await _firestore.runTransaction((transaction) async {
      final productRef = _firestore.collection('products').doc(productId);
      final productDoc = await transaction.get(productRef);
      
      if (!productDoc.exists) {
        throw Exception('Product not found');
      }

      final data = productDoc.data()!;
      final variants = data['variants'] as Map<String, dynamic>;
      
      if (!variants.containsKey(variantKey)) {
        throw Exception('Variant not found');
      }

      final variant = variants[variantKey] as Map<String, dynamic>;
      final currentStock = safeInt(variant['stock']);

      if (currentStock < quantity) {
        throw Exception('Insufficient stock');
      }

      // Use FieldValue.increment to prevent race conditions
      transaction.update(productRef, {
        'variants.$variantKey.stock': FieldValue.increment(-quantity),
      });
    });
  }

  // Check stock availability
  Future<bool> checkStock(String productId, String color, String size, int quantity) async {
    try {
      final doc = await _firestore.collection('products').doc(productId).get();
      if (!doc.exists) return false;

      final data = doc.data()!;
      final variants = data['variants'] as Map<String, dynamic>;
      final variantKey = '${color}_$size';
      
      if (!variants.containsKey(variantKey)) return false;

      final variant = variants[variantKey] as Map<String, dynamic>;
      final stock = safeInt(variant['stock']);

      return stock >= quantity;
    } catch (e) {
      return false;
    }
  }
}
