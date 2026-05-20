# Setup Guide - Hoodie Startup E-commerce App

## Prerequisites
- Flutter SDK (3.4.0 or higher)
- Firebase account
- Paymob account (for payments in Egypt)

## Step-by-Step Setup

### 1. Firebase Configuration

#### Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click "Add project"
3. Name it "Hoodie Startup" (or your preferred name)
4. Enable Google Analytics (optional)

#### Enable Firebase Services

**Authentication:**
1. Go to Authentication → Sign-in method
2. Enable "Email/Password"
3. Save

**Firestore Database:**
1. Go to Firestore Database
2. Click "Create database"
3. Start in **production mode** (you can change rules later)
4. Choose a location (preferably close to Egypt)

**Firebase Storage:**
1. Go to Storage
2. Click "Get started"
3. Start in **production mode**
4. Use the same location as Firestore

#### Add Firebase to Flutter
1. Install Firebase CLI: `npm install -g firebase-tools`
2. Install FlutterFire CLI: `dart pub global activate flutterfire_cli`
3. Run: `flutterfire configure`
4. Select your Firebase project
5. Select platforms: Web, Android, iOS (as needed)

This will create `lib/firebase_options.dart` automatically.

### 2. Firestore Security Rules

Update your Firestore rules in Firebase Console:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Products - read-only for all, write for admins
    match /products/{productId} {
      allow read: if true;
      allow write: if request.auth != null && 
                     request.auth.token.admin == true;
    }
    
    // Users - users can only read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && 
                           request.auth.uid == userId;
    }
    
    // Orders - users can only read/write their own orders
    match /orders/{orderId} {
      allow read, write: if request.auth != null && 
                           request.auth.uid == resource.data.userId;
      allow create: if request.auth != null;
    }
  }
}
```

### 3. Firebase Storage Rules

Update Storage rules:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /products/{productId}/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null && 
                     request.auth.token.admin == true;
    }
  }
}
```

### 4. Paymob Configuration

1. Sign up at [Paymob](https://www.paymob.com/)
2. Get your API credentials:
   - API Key
   - Integration ID (for card payments)
3. Update `lib/services/payment_service.dart`:
   ```dart
   static const String _paymobApiKey = 'YOUR_API_KEY_HERE';
   static const String _paymobIntegrationId = 'YOUR_INTEGRATION_ID_HERE';
   ```

### 5. Install Dependencies

```bash
flutter pub get
```

### 6. Add Sample Products to Firestore

You can add products manually in Firebase Console or use this script:

**Collection: `products`**

Example document:
```json
{
  "name": "Oversized 'Cairo Night' Hoodie",
  "price": 850,
  "description": "Premium Egyptian cotton oversized hoodie with modern streetwear design.",
  "images": [
    "https://firebasestorage.googleapis.com/.../image1.jpg"
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
    "white_L": {
      "stock": 5,
      "price_adjustment": 50
    },
    "white_M": {
      "stock": 8,
      "price_adjustment": 50
    }
  }
}
```

### 7. Run the App

```bash
# For web development
flutter run -d chrome

# For Android
flutter run

# For iOS (Mac only)
flutter run
```

## Testing the App

### 1. Test Authentication
- Sign up with a test email
- Check Firestore `users` collection for new document

### 2. Test Products
- Products should load on home screen
- Click a product to see details
- Select color and size variants

### 3. Test Cart
- Add items to cart
- Check cart screen
- Update quantities
- Remove items

### 4. Test Checkout
- Fill shipping address
- Place order
- Check `orders` collection in Firestore
- Verify stock decremented in product variants

## Common Issues

### Firebase Not Initialized
**Error:** `FirebaseException: [core/no-app] No Firebase App '[DEFAULT]' has been created`

**Solution:** Make sure `firebase_options.dart` exists and `Firebase.initializeApp()` is called in `main.dart`

### Web Platform Issues
**Error:** `dart:html` not available

**Solution:** The SEO utils use conditional imports. For web, make sure you're running `flutter run -d chrome`, not mobile.

### Payment Errors
**Error:** Paymob API errors

**Solution:** 
- Verify API credentials are correct
- Check Paymob dashboard for API status
- Ensure you're using the correct integration ID

### Image Upload Issues
**Error:** Storage permission denied

**Solution:** Check Firebase Storage security rules allow writes for authenticated users (or admins)

## Next Steps

1. **Add Admin Panel**: Create admin interface for managing products
2. **Cloud Functions**: Move payment processing to Cloud Functions
3. **Email Notifications**: Send order confirmations via SendGrid/Firebase
4. **Analytics**: Add Firebase Analytics for tracking
5. **Search**: Implement product search functionality
6. **Filters**: Add category and price filters
7. **User Profile**: Add profile page with order history

## Production Deployment

### Web
```bash
flutter build web --release
# Deploy to Firebase Hosting
firebase deploy --only hosting
```

### Android
```bash
flutter build appbundle --release
# Upload to Google Play Console
```

### iOS
```bash
flutter build ios --release
# Archive and upload via Xcode
```
