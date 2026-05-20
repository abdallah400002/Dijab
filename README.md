# Hoodie Startup - Premium Streetwear E-commerce App

A Flutter Web and Mobile e-commerce application for a premium hoodie brand in Egypt, built with Firebase, BLoC state management, and a modern dark mode UI with neon accents.

## Features

### MVP Features
- ✅ Product browsing with responsive grid (2 cols mobile, 4 cols desktop)
- ✅ Product detail pages with variant selection (color, size)
- ✅ Shopping cart with real-time updates
- ✅ User authentication (Firebase Auth)
- ✅ Checkout flow with address management
- ✅ Payment integration (Paymob for Egypt)
- ✅ Order management
- ✅ Image caching and compression
- ✅ SEO optimization for Flutter Web
- ✅ Dark mode UI with glassmorphism effects

## Architecture

The app follows **Clean Architecture** principles:

```
lib/
├── models/          # Data models (Hoodie, User, Order, CartItem)
├── repositories/    # Data layer (Firestore operations)
├── bloc/           # State management (Products, Cart, Auth)
├── services/       # Business logic (Image, Payment)
├── views/          # UI screens
├── widgets/        # Reusable widgets
├── theme/          # App theme and styling
└── utils/          # Utilities (SEO, helpers)
```

## Firestore Schema

### Collection: `products`
```dart
{
  name: String,
  price: int,  // EGP stored as integer
  description: String,
  images: [String],  // Firebase Storage URLs
  category: String,
  variants: {
    "black_L": { stock: 15, price_adjustment: 0 },
    "white_M": { stock: 5, price_adjustment: 50 }
  }
}
```

### Collection: `users`
```dart
{
  email: String,
  address_book: [{ city, street, building?, apartment? }],
  cart: [{ productId, qty, size, color }]
}
```

### Collection: `orders`
```dart
{
  userId: String,
  items: [{ name, qty, price, size, color }],
  status: "pending" | "shipped" | "delivered",
  total: int,
  createdAt: Timestamp,
  shipping_address: { city, street, building?, apartment? }
}
```

## Setup Instructions

### 1. Firebase Setup
1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com)
2. Enable Authentication (Email/Password)
3. Create Firestore database
4. Enable Firebase Storage
5. Add your Firebase config to `lib/firebase_options.dart` (run `flutterfire configure`)

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Configure Payment (Paymob)
Update `lib/services/payment_service.dart` with your Paymob credentials:
- `_paymobApiKey`: Your Paymob API key
- `_paymobIntegrationId`: Your Paymob integration ID

### 4. Run the App
```bash
# For web
flutter run -d chrome

# For mobile
flutter run
```

## Key Technical Decisions

### State Management: BLoC
- **Why BLoC?** Predictable state management, testable, works great with streams
- Perfect for e-commerce where cart, products, and auth states need to be reactive

### Image Optimization
- **flutter_image_compress**: Compresses images before upload (prevents 10MB uploads)
- **cached_network_image**: Caches product images for fast loading
- Images stored in Firebase Storage with organized folder structure

### Stock Management
- Uses Firestore Transactions with `FieldValue.increment(-1)` to prevent race conditions
- Ensures two users can't buy the last item simultaneously

### Price Storage
- Prices stored as **integers** (EGP) in Firestore
- Easier to handle than floating-point decimals
- Simple conversion for international sales later

### Responsive Design
- Uses `responsive_framework` package
- Product grid: 2 columns (mobile) → 4 columns (desktop)
- Breakpoints: Mobile (0-450px), Tablet (451-800px), Desktop (801-1920px), 4K (1921+)

## SEO Optimization for Flutter Web

The app includes SEO utilities in `lib/utils/seo_utils.dart`:
- Meta tags (description, keywords, Open Graph, Twitter Cards)
- Structured data (JSON-LD) for products
- Dynamic page titles
- Social sharing optimization

## Payment Integration

### Paymob (Egypt)
The app includes Paymob payment integration:
1. Initialize payment with order details
2. Get payment key from Paymob API
3. Redirect to payment page (or use Paymob SDK)
4. Verify payment callback

**Note**: For production, move payment logic to Cloud Functions for security.

## Cloud Functions (Recommended)

For production, create Cloud Functions for:
1. **Payment Processing**: Handle Paymob/Stripe securely
2. **Order Notifications**: Send email/SMS on order creation
3. **Stock Alerts**: Notify when stock is low
4. **Analytics**: Track sales, popular products

Example Cloud Function structure:
```javascript
exports.processPayment = functions.https.onCall(async (data, context) => {
  // Verify user authentication
  // Process payment with Paymob
  // Update order status
  // Decrement stock
  // Send confirmation email
});
```

## Testing

```bash
# Run tests
flutter test

# Run with coverage
flutter test --coverage
```

## Building for Production

### Web
```bash
flutter build web --release
```

### Android
```bash
flutter build apk --release
# or
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## Next Steps

1. **Add Firebase configuration** (`firebase_options.dart`)
2. **Set up Cloud Functions** for secure payment processing
3. **Add product images** to Firebase Storage
4. **Configure Paymob credentials**
5. **Add analytics** (Firebase Analytics, Google Analytics)
6. **Implement search functionality**
7. **Add filters** (category, price range, size)
8. **User profile page** with order history
9. **Admin panel** for managing products
10. **Push notifications** for order updates

## License

This project is private and proprietary.
