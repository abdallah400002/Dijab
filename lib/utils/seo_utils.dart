import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';

// Conditional import for web
import 'dart:html' as html show document, MetaElement, ScriptElement;

class SEOUtils {
  static void initializeSEO() {
    if (!kIsWeb) return;

    // Set meta tags for SEO
    _setMetaTag('description',
        'Premium streetwear hijabs in Egypt. Shop oversized hoodies with high-quality materials and trendy designs.');
    _setMetaTag('keywords',
        'hijabs, streetwear, egypt, fashion, oversized hijabs, premium clothing');
    _setMetaTag('author', 'Dijab');
    _setMetaTag('viewport', 'width=device-width, initial-scale=1.0');

    // Open Graph tags for social sharing
    _setMetaTag('og:title', 'Dijab - Premium Streetwear');
    _setMetaTag('og:description',
        'Premium streetwear hijabs in Egypt. Shop oversized hijabs with high-quality materials.');
    _setMetaTag('og:type', 'website');
    _setMetaTag('og:image', 'https://yourdomain.com/og-image.jpg');

    // Twitter Card tags
    _setMetaTag('twitter:card', 'summary_large_image');
    _setMetaTag('twitter:title', 'Dijab - Premium Streetwear');
    _setMetaTag('twitter:description',
        'Premium streetwear hoodies in Egypt. Shop oversized hoodies with high-quality materials.');

    // Set page title
    html.document.title = 'Dijabs - Premium Streetwear in Egypt';
  }

  static void _setMetaTag(String name, String content) {
    if (!kIsWeb) return;

    final meta = html.document.querySelector('meta[name="$name"]') ??
        html.document.querySelector('meta[property="$name"]');

    if (meta != null) {
      meta.setAttribute('content', content);
    } else {
      final newMeta = html.MetaElement()
        ..name = name
        ..content = content;
      html.document.head!.append(newMeta);
    }
  }

  static void updatePageTitle(String title) {
    if (!kIsWeb) return;
    html.document.title = '$title - Hoodie Startup';
  }

  static void updateMetaDescription(String description) {
    if (!kIsWeb) return;
    _setMetaTag('description', description);
    _setMetaTag('og:description', description);
    _setMetaTag('twitter:description', description);
  }

  // Add structured data (JSON-LD) for better SEO
  static void addStructuredData(Map<String, dynamic> data) {
    if (!kIsWeb) return;

    final script = html.ScriptElement()
      ..type = 'application/ld+json'
      ..text = jsonEncode(data);
    html.document.head!.append(script);
  }

  // Add product structured data
  static void addProductStructuredData({
    required String name,
    required String description,
    required int price,
    required String currency,
    required String imageUrl,
    required String availability,
  }) {
    if (!kIsWeb) return;

    final structuredData = {
      '@context': 'https://schema.org/',
      '@type': 'Product',
      'name': name,
      'description': description,
      'image': imageUrl,
      'offers': {
        '@type': 'Offer',
        'price': price,
        'priceCurrency': currency,
        'availability': 'https://schema.org/$availability',
      },
    };

    addStructuredData(structuredData);
  }
}
