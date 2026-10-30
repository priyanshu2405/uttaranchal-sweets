/// Static demo data. Swap this layer for a repository/API client when the
/// prototype graduates to a production build — no UI code needs to change.
class Img {
  Img._();
  static const sweets = 'assets/images/sweets_platter.jpg';
  static const milkSweets = 'assets/images/milk_sweets.jpg';
  static const namkeen = 'assets/images/namkeen.jpg';
  static const devbhoomi = 'assets/images/devbhoomi.jpg';
}

enum Category { sweets, snacks, milkSweets, regional }

extension CategoryX on Category {
  String get label => switch (this) {
        Category.sweets => 'Sweets',
        Category.snacks => 'Snacks',
        Category.milkSweets => 'Milk sweets',
        Category.regional => 'Regional',
      };

  String get heading => switch (this) {
        Category.sweets => 'Our best-loved mithai',
        Category.snacks => 'Crunchy, savoury, shareable',
        Category.milkSweets => 'Made with our own milk',
        Category.regional => 'Flavours of Kumaon',
      };
}

class Product {
  final String id;
  final String name;
  final String tagline; // e.g. "Traditional favourites"
  final int price500g; // price for the default pack
  final String defaultWeight;
  final String image;
  final Set<Category> categories;
  final String description;
  final String ingredients;
  final String allergens;
  final double rating;
  final int reviews;
  final bool bestseller;
  final bool hasWeights;

  const Product({
    required this.id,
    required this.name,
    required this.tagline,
    required this.price500g,
    required this.image,
    required this.categories,
    required this.description,
    required this.ingredients,
    required this.allergens,
    this.defaultWeight = '500 g',
    this.rating = 4.7,
    this.reviews = 80,
    this.bestseller = false,
    this.hasWeights = true,
  });

  String get subtitle => '$defaultWeight · $tagline';

  /// Simple weight-based pricing for the demo.
  int priceFor(String weight) => switch (weight) {
        '250 g' => (price500g / 2).round(),
        '1 kg' => price500g * 2,
        _ => price500g,
      };

  bool matches(String q) {
    final s = q.trim().toLowerCase();
    if (s.isEmpty) return true;
    final hay = '$name $tagline ${categories.map((c) => c.label).join(' ')} mithai sweets'.toLowerCase();
    if (categories.contains(Category.snacks) && !categories.contains(Category.sweets)) {
      return '$name $tagline snacks namkeen savoury'.toLowerCase().contains(s);
    }
    return hay.contains(s);
  }
}

class Catalog {
  Catalog._();

  static const weights = ['250 g', '500 g', '1 kg'];

  static const products = <Product>[
    Product(
      id: 'kaju-katli',
      name: 'Kaju Katli',
      tagline: 'Traditional favourites',
      price500g: 440,
      image: Img.sweets,
      categories: {Category.sweets},
      description: 'Silky cashew mithai, crafted for celebrations big and small.',
      ingredients: 'Cashews, sugar, cardamom',
      allergens: 'Contains tree nuts',
      rating: 4.8,
      reviews: 124,
      bestseller: true,
    ),
    Product(
      id: 'bal-mithai',
      name: 'Bal Mithai',
      tagline: 'Kumaoni special',
      price500g: 280,
      image: Img.milkSweets,
      categories: {Category.sweets, Category.regional},
      description: 'Almora’s beloved chocolate-brown khoya fudge, rolled in sugar pearls.',
      ingredients: 'Khoya, sugar, sugar pearls',
      allergens: 'Contains milk',
      rating: 4.9,
      reviews: 211,
      bestseller: true,
    ),
    Product(
      id: 'milk-cake',
      name: 'Milk Cake',
      tagline: 'Traditional favourites',
      price500g: 320,
      image: Img.milkSweets,
      categories: {Category.sweets, Category.milkSweets},
      description: 'Slow-cooked milk, caramelised into soft, grainy layers.',
      ingredients: 'Milk, sugar, ghee',
      allergens: 'Contains milk',
      rating: 4.7,
      reviews: 98,
    ),
    Product(
      id: 'namkeen-mix',
      name: 'Namkeen Mix',
      tagline: 'Crunchy & savoury',
      price500g: 180,
      defaultWeight: '400 g',
      image: Img.namkeen,
      categories: {Category.snacks},
      description: 'Our house blend of sev, peanuts and spiced crunch for tea time.',
      ingredients: 'Gram flour, peanuts, spices',
      allergens: 'Contains peanuts',
      rating: 4.6,
      reviews: 76,
      hasWeights: false,
    ),
    Product(
      id: 'rasgulla',
      name: 'Rasgulla',
      tagline: 'Soft & spongy',
      price500g: 260,
      image: Img.milkSweets,
      categories: {Category.milkSweets},
      description: 'Pillowy chhena dumplings soaked in light sugar syrup.',
      ingredients: 'Chhena, sugar',
      allergens: 'Contains milk',
      rating: 4.7,
      reviews: 64,
    ),
    Product(
      id: 'singori',
      name: 'Singori',
      tagline: 'Almora classic',
      price500g: 300,
      image: Img.milkSweets,
      categories: {Category.regional, Category.milkSweets},
      description: 'Khoya sweet wrapped in a maalu leaf cone — a true taste of the hills.',
      ingredients: 'Khoya, sugar, maalu leaf',
      allergens: 'Contains milk',
      rating: 4.8,
      reviews: 57,
    ),
    Product(
      id: 'motichoor-laddoo',
      name: 'Motichoor Laddoo',
      tagline: 'Festive favourite',
      price500g: 300,
      image: Img.sweets,
      categories: {Category.sweets},
      description: 'Tiny pearls of boondi, bound with ghee and a hint of saffron.',
      ingredients: 'Gram flour, ghee, sugar, saffron',
      allergens: 'Contains milk',
      rating: 4.7,
      reviews: 132,
    ),
    Product(
      id: 'samosa-mathri',
      name: 'Mathri & Samosa',
      tagline: 'Tea-time box',
      price500g: 160,
      image: Img.namkeen,
      categories: {Category.snacks},
      description: 'Flaky mathri and mini samosas, made fresh every morning.',
      ingredients: 'Wheat flour, potato, spices',
      allergens: 'Contains gluten',
      rating: 4.5,
      reviews: 41,
      hasWeights: false,
    ),
  ];

  static Product byId(String? id) => products.firstWhere((p) => p.id == id, orElse: () => products.first);

  static List<Product> inCategory(Category c) => products.where((p) => p.categories.contains(c)).toList();
}

// ---------------- Milk ----------------
class Milk {
  Milk._();
  static const pricePerLitre = 68;
  static const quantities = ['1 L', '2 L', '3 L', 'Custom'];
  static const frequencies = ['Every day', 'Alternate days', 'Select days'];
  static const slots = ['Morning · 6:00–7:00 AM', 'Morning · 7:00–8:00 AM', 'Evening · 5:00–6:00 PM'];

  static int deliveriesPerWeek(String frequency) => switch (frequency) {
        'Alternate days' => 4,
        'Select days' => 5,
        _ => 7,
      };
}

// ---------------- Staff route ----------------
enum StopStatus { scheduled, delivered, exception }

class DeliveryStop {
  final int number;
  final String name;
  final String address;
  final int litres;
  final String note;
  StopStatus status;

  DeliveryStop(this.number, this.name, this.address, this.litres, this.note, this.status);

  int get charge => litres * Milk.pricePerLitre;
  int get bottles => litres;
}

List<DeliveryStop> buildDemoRoute() {
  const done = [
    'Kavita Pant', 'Suresh Bhatt', 'Meena Arya', 'Deepak Joshi', 'Ritu Tiwari', 'Harish Rawat',
    'Lata Bisht', 'Mohan Negi', 'Sunita Kandpal', 'Gopal Pandey', 'Nisha Mehra', 'Anil Bora',
  ];
  final stops = <DeliveryStop>[
    for (var i = 0; i < done.length; i++)
      DeliveryStop(i + 1, done[i], '${2 + i * 2}, Patel Nagar', 2, 'Leave at the door.', StopStatus.delivered),
  ];
  final pending = <(String, int, int)>[
    ('Aarav Sharma', 24, 2),
    ('Neha Joshi', 28, 1),
    ('Vikram Rawat', 32, 2),
    ('Pooja Bisht', 36, 1),
    ('Rohit Negi', 40, 2),
    ('Anjali Rana', 44, 3),
    ('Kiran Pathak', 48, 2),
    ('Manoj Karki', 52, 2),
    ('Seema Dhami', 56, 1),
    ('Prakash Bisht', 60, 2),
    ('Rekha Adhikari', 64, 3),
    ('Tarun Saini', 68, 3),
  ];
  for (var i = 0; i < pending.length; i++) {
    final p = pending[i];
    stops.add(DeliveryStop(
      13 + i,
      p.$1,
      '${p.$2}, Patel Nagar, Kashipur',
      p.$3,
      i == 0 ? 'Please ring the bell. Hand over at the front door.' : 'Collect empty bottles from the gate.',
      StopStatus.scheduled,
    ));
  }
  return stops;
}
