import '../../models/category.dart';
import '../../models/product.dart';

String _img(String label) {
  final safe = Uri.encodeComponent(label);
  return 'https://placehold.co/800x800/png?text=$safe';
}

ProductListItem _toListItem(ProductDetail p) {
  return ProductListItem(
    id: p.id,
    name: p.name,
    slug: p.slug,
    description: p.description,
    price: p.price,
    comparePrice: p.comparePrice,
    stock: p.stock,
    images: p.images,
    category: p.category,
    avgRating: p.avgRating,
    reviewCount: p.reviewCount,
    createdAt: p.createdAt,
  );
}

class DemoCatalog {
  static final List<Category> categories = <Category>[
    Category(id: 'cat-smartphones', name: 'Smartphones', slug: 'smartphones', icon: 'phone', parentId: null),
    Category(id: 'cat-laptops', name: 'PC Portables', slug: 'laptops', icon: 'laptop', parentId: null),
    Category(id: 'cat-audio', name: 'Audio', slug: 'audio', icon: 'headphones', parentId: null),
    Category(id: 'cat-gaming', name: 'Gaming', slug: 'gaming', icon: 'gamepad', parentId: null),
    Category(id: 'cat-accessories', name: 'Accessoires', slug: 'accessoires', icon: 'usb', parentId: null),
  ];

  static final Map<String, Category> _categoryBySlug = {
    for (final c in categories) c.slug: c,
  };

  static Category _cat(String slug) {
    return _categoryBySlug[slug] ?? categories.first;
  }

  static final List<ProductDetail> _details = <ProductDetail>[
    ProductDetail(
      id: 'p-techphone-x12',
      name: 'TechPhone X12',
      slug: 'techphone-x12',
      description: 'Smartphone 5G fluide avec un excellent écran et une batterie longue durée.',
      price: 1299.0,
      comparePrice: 1499.0,
      stock: 18,
      images: [_img('TechPhone X12')],
      specs: {
        'Réseau': '5G',
        'Écran': '6.6" OLED',
        'Stockage': '256 Go',
        'Batterie': '5000 mAh',
        'Garantie': '12 mois',
      },
      category: ProductCategorySummary.fromCategory(_cat('smartphones')),
      avgRating: 4.6,
      reviewCount: 124,
      reviews: const [],
      createdAt: DateTime(2026, 3, 12),
    ),
    ProductDetail(
      id: 'p-techphone-mini',
      name: 'TechPhone Mini 5G',
      slug: 'techphone-mini-5g',
      description: 'Compact et rapide, parfait pour une utilisation à une main.',
      price: 899.0,
      comparePrice: null,
      stock: 32,
      images: [_img('TechPhone Mini 5G')],
      specs: {
        'Réseau': '5G',
        'Écran': '6.1" OLED',
        'Stockage': '128 Go',
        'Batterie': '4200 mAh',
        'Garantie': '12 mois',
      },
      category: ProductCategorySummary.fromCategory(_cat('smartphones')),
      avgRating: 4.4,
      reviewCount: 67,
      reviews: const [],
      createdAt: DateTime(2026, 2, 20),
    ),
    ProductDetail(
      id: 'p-techbook-air-14',
      name: 'TechBook Air 14',
      slug: 'techbook-air-14',
      description: 'PC portable léger pour étude, bureautique et navigation.',
      price: 1799.0,
      comparePrice: 1999.0,
      stock: 9,
      images: [_img('TechBook Air 14')],
      specs: {
        'Écran': '14" IPS',
        'Processeur': '8 cœurs',
        'RAM': '16 Go',
        'Stockage': '512 Go SSD',
        'Garantie': '12 mois',
      },
      category: ProductCategorySummary.fromCategory(_cat('laptops')),
      avgRating: 4.7,
      reviewCount: 58,
      reviews: const [],
      createdAt: DateTime(2026, 4, 2),
    ),
    ProductDetail(
      id: 'p-techbook-pro-16',
      name: 'TechBook Pro 16',
      slug: 'techbook-pro-16',
      description: 'Puissance et écran large pour création, dev et multitâche.',
      price: 2899.0,
      comparePrice: null,
      stock: 6,
      images: [_img('TechBook Pro 16')],
      specs: {
        'Écran': '16" 120Hz',
        'Processeur': '12 cœurs',
        'RAM': '32 Go',
        'Stockage': '1 To SSD',
        'Garantie': '12 mois',
      },
      category: ProductCategorySummary.fromCategory(_cat('laptops')),
      avgRating: 4.8,
      reviewCount: 31,
      reviews: const [],
      createdAt: DateTime(2026, 1, 30),
    ),
    ProductDetail(
      id: 'p-noiseless-buds',
      name: 'NoiseLess Buds',
      slug: 'noiseless-buds',
      description: 'Écouteurs true wireless avec réduction de bruit et bonne autonomie.',
      price: 249.0,
      comparePrice: 299.0,
      stock: 45,
      images: [_img('NoiseLess Buds')],
      specs: {
        'Connexion': 'Bluetooth 5.3',
        'Autonomie': '7h + boîtier',
        'Réduction de bruit': 'Active',
        'Résistance': 'IPX4',
        'Garantie': '12 mois',
      },
      category: ProductCategorySummary.fromCategory(_cat('audio')),
      avgRating: 4.3,
      reviewCount: 210,
      reviews: const [],
      createdAt: DateTime(2026, 3, 5),
    ),
    ProductDetail(
      id: 'p-bassmax-speaker',
      name: 'BassMax Speaker',
      slug: 'bassmax-speaker',
      description: 'Enceinte portable avec des basses puissantes et mode party.',
      price: 329.0,
      comparePrice: null,
      stock: 22,
      images: [_img('BassMax Speaker')],
      specs: {
        'Puissance': '40W',
        'Autonomie': '10h',
        'Connexion': 'Bluetooth / AUX',
        'Résistance': 'IPX6',
        'Garantie': '12 mois',
      },
      category: ProductCategorySummary.fromCategory(_cat('audio')),
      avgRating: 4.5,
      reviewCount: 89,
      reviews: const [],
      createdAt: DateTime(2026, 2, 8),
    ),
    ProductDetail(
      id: 'p-gamepad-elite',
      name: 'GamePad Elite',
      slug: 'gamepad-elite',
      description: 'Manette ergonomique avec gâchettes réactives et faible latence.',
      price: 189.0,
      comparePrice: null,
      stock: 27,
      images: [_img('GamePad Elite')],
      specs: {
        'Connexion': 'USB-C / Bluetooth',
        'Compatibilité': 'PC / Mobile',
        'Batterie': 'Rechargeable',
        'Garantie': '12 mois',
      },
      category: ProductCategorySummary.fromCategory(_cat('gaming')),
      avgRating: 4.2,
      reviewCount: 44,
      reviews: const [],
      createdAt: DateTime(2026, 4, 8),
    ),
    ProductDetail(
      id: 'p-hypermouse-2',
      name: 'HyperMouse 2.0',
      slug: 'hypermouse-2',
      description: 'Souris gaming légère avec capteur précis et RGB discret.',
      price: 119.0,
      comparePrice: 149.0,
      stock: 38,
      images: [_img('HyperMouse 2.0')],
      specs: {
        'DPI': '26000',
        'Poids': '59g',
        'Connexion': 'USB',
        'Garantie': '12 mois',
      },
      category: ProductCategorySummary.fromCategory(_cat('gaming')),
      avgRating: 4.4,
      reviewCount: 73,
      reviews: const [],
      createdAt: DateTime(2026, 3, 28),
    ),
    ProductDetail(
      id: 'p-chargehub-65w',
      name: 'ChargeHub USB-C 65W',
      slug: 'chargehub-usbc-65w',
      description: 'Chargeur compact GaN pour téléphone et PC portable.',
      price: 99.0,
      comparePrice: null,
      stock: 60,
      images: [_img('ChargeHub USB-C 65W')],
      specs: {
        'Puissance': '65W',
        'Ports': '2x USB-C',
        'Technologie': 'GaN',
        'Garantie': '12 mois',
      },
      category: ProductCategorySummary.fromCategory(_cat('accessoires')),
      avgRating: 4.6,
      reviewCount: 55,
      reviews: const [],
      createdAt: DateTime(2026, 1, 18),
    ),
    ProductDetail(
      id: 'p-powerbank-20k',
      name: 'PowerBank 20000mAh',
      slug: 'powerbank-20000mah',
      description: 'Batterie externe pour plusieurs recharges, idéale en voyage.',
      price: 139.0,
      comparePrice: null,
      stock: 41,
      images: [_img('PowerBank 20000mAh')],
      specs: {
        'Capacité': '20000mAh',
        'Entrée': 'USB-C',
        'Sorties': 'USB-C + USB-A',
        'Garantie': '12 mois',
      },
      category: ProductCategorySummary.fromCategory(_cat('accessoires')),
      avgRating: 4.1,
      reviewCount: 98,
      reviews: const [],
      createdAt: DateTime(2026, 2, 26),
    ),
    ProductDetail(
      id: 'p-smartwatch-s9',
      name: 'SmartWatch S9',
      slug: 'smartwatch-s9',
      description: 'Suivi fitness, notifications et autonomie confortable.',
      price: 399.0,
      comparePrice: 449.0,
      stock: 15,
      images: [_img('SmartWatch S9')],
      specs: {
        'Écran': '1.9" AMOLED',
        'Capteurs': 'FC / SpO2',
        'Autonomie': '5 jours',
        'Résistance': 'IP68',
        'Garantie': '12 mois',
      },
      category: ProductCategorySummary.fromCategory(_cat('accessoires')),
      avgRating: 4.0,
      reviewCount: 36,
      reviews: const [],
      createdAt: DateTime(2026, 4, 10),
    ),
    ProductDetail(
      id: 'p-vr-lens-starter',
      name: 'VR Lens Starter',
      slug: 'vr-lens-starter',
      description: 'Casque VR d’entrée de gamme pour découvrir les expériences VR.',
      price: 459.0,
      comparePrice: null,
      stock: 8,
      images: [_img('VR Lens Starter')],
      specs: {
        'Compatibilité': 'Smartphone',
        'Lentilles': 'Anti-reflet',
        'Ajustement': 'Réglable',
        'Garantie': '12 mois',
      },
      category: ProductCategorySummary.fromCategory(_cat('gaming')),
      avgRating: 3.9,
      reviewCount: 22,
      reviews: const [],
      createdAt: DateTime(2026, 1, 6),
    ),
  ];

  static final Map<String, ProductDetail> _bySlug = {
    for (final p in _details) p.slug: p,
  };

  static List<ProductListItem> featured() {
    final items = _details.map(_toListItem).toList(growable: false);
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items.take(10).toList(growable: false);
  }

  static ProductDetail? detail(String slug) {
    return _bySlug[slug];
  }

  static List<ProductListItem> search(String q, {int limit = 20}) {
    final query = q.trim().toLowerCase();
    if (query.isEmpty) return const [];

    final safeLimit = limit < 1 ? 1 : (limit > 50 ? 50 : limit);

    final matches = _details.where((p) {
      return p.name.toLowerCase().contains(query) || p.description.toLowerCase().contains(query);
    }).map(_toListItem);

    final items = matches.toList(growable: false);
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items.take(safeLimit).toList(growable: false);
  }
}
