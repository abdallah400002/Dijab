# Firestore Database Schema Reference

## Collection: `products`

Each document represents a hoodie product.

### Document Structure
```typescript
{
  name: string,              // e.g., "Oversized 'Cairo Night' Hoodie"
  price: number,             // Price in EGP (stored as integer)
  description: string,       // Product description
  images: string[],          // Array of Firebase Storage URLs
  category: string,          // e.g., "Oversized", "Classic", "Limited"
  variants: {
    [color_size]: {
      stock: number,         // Available quantity
      price_adjustment: number  // Additional price (default: 0)
    }
  }
}
```

### Example Document
```json
{
  "name": "Oversized 'Cairo Night' Hoodie",
  "price": 850,
  "description": "Premium Egyptian cotton oversized hoodie with modern streetwear design. Perfect for the urban lifestyle.",
  "images": [
    "https://firebasestorage.googleapis.com/v0/b/.../image1.jpg",
    "https://firebasestorage.googleapis.com/v0/b/.../image2.jpg"
  ],
  "category": "Oversized",
  "variants": {
    "black_L": {
      "stock": 15,
      "price_adjustment": 0
    },
    "black_M": {
      "stock": 10,
      "price_adjustment": 0
    },
    "black_S": {
      "stock": 5,
      "price_adjustment": 0
    },
    "white_L": {
      "stock": 8,
      "price_adjustment": 50
    },
    "white_M": {
      "stock": 12,
      "price_adjustment": 50
    }
  }
}
```

### Variant Key Format
- Format: `{color}_{size}`
- Examples: `black_L`, `white_M`, `red_XL`
- Colors: lowercase (black, white, red, blue, etc.)
- Sizes: uppercase (S, M, L, XL, XXL)

---

## Collection: `users`

Each document represents a user account. Document ID matches Firebase Auth UID.

### Document Structure
```typescript
{
  email: string,
  address_book: Address[],
  cart: CartItem[]
}
```

### Address Type
```typescript
{
  city: string,           // e.g., "Cairo"
  street: string,         // e.g., "123 Main Street"
  building?: string,      // Optional
  apartment?: string      // Optional
}
```

### CartItem Type
```typescript
{
  productId: string,      // Reference to products collection
  qty: number,            // Quantity
  size: string,           // e.g., "L"
  color: string           // e.g., "black"
}
```

### Example Document
```json
{
  "email": "customer@example.com",
  "address_book": [
    {
      "city": "Cairo",
      "street": "123 Tahrir Square",
      "building": "5",
      "apartment": "12"
    }
  ],
  "cart": [
    {
      "productId": "hoodie_123",
      "qty": 2,
      "size": "L",
      "color": "black"
    },
    {
      "productId": "hoodie_456",
      "qty": 1,
      "size": "M",
      "color": "white"
    }
  ]
}
```

---

## Collection: `orders`

Each document represents a customer order.

### Document Structure
```typescript
{
  userId: string,          // Reference to users collection
  items: OrderItem[],
  status: "pending" | "shipped" | "delivered" | "cancelled",
  total: number,          // Total price in EGP
  createdAt: Timestamp,
  shipping_address?: Address
}
```

### OrderItem Type
```typescript
{
  name: string,           // Product name (snapshot at time of order)
  qty: number,            // Quantity
  price: number,          // Price per item in EGP
  size: string,
  color: string
}
```

### Example Document
```json
{
  "userId": "user_abc123",
  "items": [
    {
      "name": "Oversized 'Cairo Night' Hoodie",
      "qty": 2,
      "price": 850,
      "size": "L",
      "color": "black"
    }
  ],
  "status": "pending",
  "total": 1700,
  "createdAt": "2024-01-15T10:30:00Z",
  "shipping_address": {
    "city": "Cairo",
    "street": "123 Tahrir Square",
    "building": "5",
    "apartment": "12"
  }
}
```

---

## Indexes Required

Create these composite indexes in Firestore:

1. **orders collection:**
   - Fields: `userId` (Ascending), `createdAt` (Descending)
   - Used for: Querying user orders by date

2. **products collection:**
   - Fields: `category` (Ascending)
   - Used for: Filtering products by category

---

## Stock Management

### Decrementing Stock
When an order is placed, use Firestore Transactions to decrement stock:

```dart
await firestore.runTransaction((transaction) async {
  final productRef = firestore.collection('products').doc(productId);
  final productDoc = await transaction.get(productRef);
  
  // Check stock
  final variants = productDoc.data()!['variants'];
  final variant = variants['${color}_${size}'];
  final currentStock = variant['stock'] as int;
  
  if (currentStock < quantity) {
    throw Exception('Insufficient stock');
  }
  
  // Decrement using FieldValue.increment
  transaction.update(productRef, {
    'variants.${color}_${size}.stock': FieldValue.increment(-quantity)
  });
});
```

### Why Transactions?
- Prevents race conditions
- Ensures atomic updates
- Two users can't buy the last item simultaneously

---

## Best Practices

1. **Price Storage**: Always store prices as integers (EGP). Avoid floating-point decimals.

2. **Variant Keys**: Use consistent format: `{color}_{size}` in lowercase/uppercase.

3. **Image URLs**: Store full Firebase Storage URLs, not just paths.

4. **Order Items**: Store product name and price snapshot at order time (products may change later).

5. **Timestamps**: Use Firestore Timestamp type, not strings.

6. **Stock Updates**: Always use transactions for stock decrements.

7. **User Data**: Never store sensitive data (passwords, payment info) in Firestore.

---

## Security Rules Example

See `SETUP_GUIDE.md` for complete security rules. Key points:

- Products: Read-only for all, write for admins only
- Users: Users can only access their own document
- Orders: Users can only access their own orders
