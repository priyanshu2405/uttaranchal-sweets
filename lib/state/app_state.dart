import 'package:flutter/widgets.dart';

import '../data/catalog.dart';

class CartLine {
  final String key;
  final String name;
  final String subtitle;
  final String image;
  final int unitPrice;
  int qty;

  CartLine({required this.key, required this.name, required this.subtitle, required this.image, required this.unitPrice, this.qty = 1});

  int get total => unitPrice * qty;
}

class PlacedOrder {
  final String id;
  final List<CartLine> lines;
  final int itemsTotal;
  final int delivery;
  final int pointsRedeemed;
  final int discount;
  final String paymentMethod;
  final String slot;
  final bool pickup;

  PlacedOrder({
    required this.id,
    required this.lines,
    required this.itemsTotal,
    required this.delivery,
    required this.pointsRedeemed,
    required this.discount,
    required this.paymentMethod,
    required this.slot,
    required this.pickup,
  });

  int get paid => itemsTotal + delivery - discount;
  int get pointsToEarn => (itemsTotal / 10).floor() - 7; // demo: 65 pts on ₹720
  String get shortPayment => paymentMethod.split(' ').first;
}

class MilkTxn {
  final String label;
  final int amount; // +credit / -debit
  MilkTxn(this.label, this.amount);
}

/// Single source of truth for the prototype. Kept intentionally simple
/// (ChangeNotifier + InheritedNotifier) so the demo has zero third-party deps.
class AppState extends ChangeNotifier {
  // ---------- Profile ----------
  String userName = 'Aarav Sharma';
  String phone = '98765 43210';
  String language = 'English';
  bool notifications = true;
  final Set<String> favourites = {'kaju-katli'};

  String get firstName => userName.split(' ').first;
  String get initials => userName.split(' ').where((w) => w.isNotEmpty).map((w) => w[0]).take(2).join();

  void setName(String v) {
    userName = v;
    notifyListeners();
  }

  void setLanguage(String v) {
    language = v;
    notifyListeners();
  }

  void toggleNotifications(bool v) {
    notifications = v;
    notifyListeners();
  }

  void toggleFavourite(String id) {
    favourites.contains(id) ? favourites.remove(id) : favourites.add(id);
    notifyListeners();
  }

  // ---------- Address ----------
  String pincode = '244713';
  String street = '24, Patel Nagar';
  String city = 'Kashipur, Uttarakhand';

  String get area => street.contains(',') ? street.split(',').last.trim() : street;

  void saveAddress({required String pincode, required String street, required String city}) {
    this.pincode = pincode;
    this.street = street;
    this.city = city;
    notifyListeners();
  }

  // ---------- Bag ----------
  final List<CartLine> cart = [
    CartLine(key: 'kaju-katli|500 g', name: 'Kaju Katli', subtitle: '500 g · Made with cashews', image: Img.sweets, unitPrice: 440),
    CartLine(key: 'bal-mithai|500 g', name: 'Bal Mithai', subtitle: '500 g · Kumaoni favourite', image: Img.milkSweets, unitPrice: 280),
  ];

  int get cartCount => cart.fold(0, (s, l) => s + l.qty);
  int get itemsTotal => cart.fold(0, (s, l) => s + l.total);
  int get deliveryFee => cart.isEmpty || pickup ? 0 : 30;
  int get bagTotal => itemsTotal + deliveryFee;

  void addProduct(Product p, {String? weight, int qty = 1}) {
    final w = weight ?? p.defaultWeight;
    final key = '${p.id}|$w';
    final existing = cart.where((l) => l.key == key);
    if (existing.isNotEmpty) {
      existing.first.qty += qty;
    } else {
      cart.add(CartLine(key: key, name: p.name, subtitle: '$w · ${p.tagline}', image: p.image, unitPrice: p.priceFor(w), qty: qty));
    }
    notifyListeners();
  }

  void addGiftBox({required int items, required String packaging}) {
    cart.add(CartLine(
      key: 'gift-box|${DateTime.now().millisecondsSinceEpoch}',
      name: 'Festive Gift Box',
      subtitle: '$items sweets · $packaging',
      image: Img.sweets,
      unitPrice: 899,
    ));
    notifyListeners();
  }

  void setQty(CartLine line, int qty) {
    if (qty <= 0) {
      cart.remove(line);
    } else {
      line.qty = qty;
    }
    _clampRedeem();
    notifyListeners();
  }

  void restoreLine(CartLine line, int index) {
    cart.insert(index.clamp(0, cart.length), line);
    notifyListeners();
  }

  // ---------- Loyalty ----------
  int points = 1250;
  int pointsToRedeem = 1000;
  bool usePoints = true;

  static int pointsValue(int pts) => pts ~/ 10; // 100 pts = ₹10

  int get redeemablePoints => usePoints ? pointsToRedeem : 0;
  int get discount => pointsValue(redeemablePoints);
  int get payable => (bagTotal - discount).clamp(0, 1 << 30);

  void setRedeem(int pts) {
    pointsToRedeem = pts;
    usePoints = pts > 0;
    _clampRedeem();
    notifyListeners();
  }

  void setUsePoints(bool v) {
    usePoints = v;
    notifyListeners();
  }

  void _clampRedeem() {
    final maxByPoints = points;
    final maxByValue = itemsTotal * 10; // can't discount more than products value
    final cap = maxByPoints < maxByValue ? maxByPoints : maxByValue;
    if (pointsToRedeem > cap) pointsToRedeem = (cap ~/ 50) * 50;
  }

  final List<(String, String, int)> pointsActivity = [
    ('24 Oct', 'Order #UDS1021', 89),
    ('20 Oct', 'Redeemed on order', -500),
    ('18 Oct', 'Referral reward', 200),
    ('15 Oct', 'Order delivered', 120),
  ];

  // ---------- Checkout ----------
  bool pickup = false;
  String deliverySlot = 'Today · 11:30 AM–12:00 PM';
  String paymentMethod = 'UPI · Google Pay / PhonePe / Paytm';
  String upiId = 'aarav@upi';
  PlacedOrder? lastOrder;

  void setPickup(bool v) {
    pickup = v;
    notifyListeners();
  }

  void setSlot(String v) {
    deliverySlot = v;
    notifyListeners();
  }

  void setPayment(String v) {
    paymentMethod = v;
    notifyListeners();
  }

  PlacedOrder placeOrder() {
    final order = PlacedOrder(
      id: 'UDS1048',
      lines: cart.map((l) => CartLine(key: l.key, name: l.name, subtitle: l.subtitle, image: l.image, unitPrice: l.unitPrice, qty: l.qty)).toList(),
      itemsTotal: itemsTotal,
      delivery: deliveryFee,
      pointsRedeemed: redeemablePoints,
      discount: discount,
      paymentMethod: paymentMethod,
      slot: deliverySlot,
      pickup: pickup,
    );
    points -= redeemablePoints;
    if (redeemablePoints > 0) pointsActivity.insert(0, ('Today', 'Redeemed on #${order.id}', -redeemablePoints));
    cart.clear();
    pointsToRedeem = 0;
    usePoints = false;
    lastOrder = order;
    notifyListeners();
    return order;
  }

  /// Fallback order used when a presenter jumps straight to a receipt screen.
  PlacedOrder get demoOrder =>
      lastOrder ??
      PlacedOrder(
        id: 'UDS1048',
        lines: [
          CartLine(key: 'a', name: 'Kaju Katli', subtitle: '500 g', image: Img.sweets, unitPrice: 440),
          CartLine(key: 'b', name: 'Bal Mithai', subtitle: '500 g', image: Img.milkSweets, unitPrice: 280),
        ],
        itemsTotal: 720,
        delivery: 30,
        pointsRedeemed: 1000,
        discount: 100,
        paymentMethod: 'UPI · Google Pay / PhonePe / Paytm',
        slot: 'Today · 11:30 AM–12:00 PM',
        pickup: false,
      );

  // ---------- Milk subscription ----------
  bool milkPlanActive = true;
  int milkLitres = 2;
  String milkFrequency = 'Every day';
  DateTime milkStart = DateTime(2026, 11, 1);
  String milkSlot = Milk.slots.first;
  bool milkReminders = true;
  int milkBalance = 680;
  final Set<int> pausedDays = {11, 12};
  final List<MilkTxn> milkActivity = [
    MilkTxn('7 Nov · 2 L delivered', -136),
    MilkTxn('6 Nov · 2 L delivered', -136),
    MilkTxn('1 Nov · Balance top-up', 1000),
  ];

  int get perDelivery => milkLitres * Milk.pricePerLitre;
  int get nextSevenDays => perDelivery * Milk.deliveriesPerWeek(milkFrequency);

  void configureMilk({int? litres, String? frequency, DateTime? start, String? slot}) {
    if (litres != null) milkLitres = litres;
    if (frequency != null) milkFrequency = frequency;
    if (start != null) milkStart = start;
    if (slot != null) milkSlot = slot;
    notifyListeners();
  }

  void setMilkReminders(bool v) {
    milkReminders = v;
    notifyListeners();
  }

  void activateMilkPlan() {
    milkPlanActive = true;
    notifyListeners();
  }

  void pauseDays(Iterable<int> days) {
    pausedDays
      ..clear()
      ..addAll(days);
    notifyListeners();
  }

  void topUpMilk(int amount) {
    milkBalance += amount;
    milkActivity.insert(0, MilkTxn('Today · Balance top-up', amount));
    notifyListeners();
  }

  // ---------- Staff app ----------
  final List<DeliveryStop> route = buildDemoRoute();
  int bottlesCollected = 20;

  List<DeliveryStop> get pendingStops => route.where((s) => s.status == StopStatus.scheduled).toList();
  int get completedStops => route.where((s) => s.status == StopStatus.delivered).length;
  int get exceptionStops => route.where((s) => s.status == StopStatus.exception).length;
  int get assignedLitres => route.fold(0, (s, r) => s + r.litres);
  int get deliveredLitres => route.where((s) => s.status == StopStatus.delivered).fold(0, (s, r) => s + r.litres);
  int get chargesRecorded => deliveredLitres * Milk.pricePerLitre;
  DeliveryStop? get nextStop => pendingStops.isEmpty ? null : pendingStops.first;

  DeliveryStop stopByNumber(int? n) => route.firstWhere((s) => s.number == n, orElse: () => nextStop ?? route.last);

  void markDelivered(DeliveryStop stop, {int? bottles}) {
    stop.status = StopStatus.delivered;
    bottlesCollected += bottles ?? stop.bottles;
    notifyListeners();
  }

  void markException(DeliveryStop stop) {
    stop.status = StopStatus.exception;
    notifyListeners();
  }

  void recordBottles(int n) {
    bottlesCollected += n;
    notifyListeners();
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  /// Subscribe to changes (rebuilds when state notifies).
  static AppState of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Read without subscribing – use inside callbacks.
  static AppState read(BuildContext context) => context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}

extension AppStateX on BuildContext {
  AppState get app => AppScope.of(this);
  AppState get appRead => AppScope.read(this);
}

String rupees(int v) {
  final neg = v < 0;
  final s = v.abs().toString();
  // Indian digit grouping: 1,23,456
  String out;
  if (s.length <= 3) {
    out = s;
  } else {
    final last3 = s.substring(s.length - 3);
    var rest = s.substring(0, s.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    out = '${parts.join(',')},$last3';
  }
  return '${neg ? '−' : ''}₹$out';
}

String grouped(int v) => rupees(v).replaceFirst('₹', '');
