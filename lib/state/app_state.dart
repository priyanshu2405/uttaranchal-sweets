import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/api.dart';
import '../data/catalog.dart';

/// One line in the bag. The bag lives on the phone; prices and stock are re-checked by the server
/// (POST /cart/quote) whenever the bag is opened and again when the order is placed.
class CartLine {
  final int productId;
  final int? optionId;
  String name;
  String label;
  String imageUrl;
  double unitPrice;
  int qty;
  bool perishable;
  int? available;

  CartLine({
    required this.productId,
    this.optionId,
    required this.name,
    required this.label,
    required this.imageUrl,
    required this.unitPrice,
    this.qty = 1,
    this.perishable = false,
    this.available,
  });

  String get key => optionId == null ? '$productId' : '$productId:$optionId';
  double get total => unitPrice * qty;
  String get subtitle => label;

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'option_id': optionId,
        'name': name,
        'label': label,
        'image_url': imageUrl,
        'unit_price': unitPrice,
        'quantity': qty,
        'perishable': perishable,
      };

  Map<String, dynamic> toApi() => {'product_id': productId, if (optionId != null) 'option_id': optionId, 'quantity': qty};

  factory CartLine.fromJson(Map<String, dynamic> j) => CartLine(
        productId: (j['product_id'] as num).toInt(),
        optionId: (j['option_id'] as num?)?.toInt(),
        name: '${j['name'] ?? ''}',
        label: '${j['label'] ?? ''}',
        imageUrl: '${j['image_url'] ?? ''}',
        unitPrice: (j['unit_price'] as num?)?.toDouble() ?? 0,
        qty: (j['quantity'] as num?)?.toInt() ?? 1,
        perishable: j['perishable'] == true,
      );
}

/// Single source of truth for the app. Shop data, account, bag and orders come from the
/// Laravel backend, so the app and the website always show the same products and orders.
class AppState extends ChangeNotifier {
  AppState({ApiClient? api}) : api = api ?? ApiClient() {
    this.api.onUnauthorized = _onUnauthorized;
  }

  final ApiClient api;
  SharedPreferences? _prefs;

  // ---------- Start-up ----------
  bool ready = false;
  bool booting = false;
  String? bootError;
  ShopConfig config = const ShopConfig();

  /// Load saved session/bag, then shop settings and the home catalogue. Safe to call again to retry.
  Future<void> init() async {
    if (booting) return;
    booting = true;
    bootError = null;
    notifyListeners();
    try {
      _prefs ??= await SharedPreferences.getInstance();
      _restore();
      final results = await Future.wait([api.get('/config', auth: ApiAuth.none), api.get('/home')]);
      config = ShopConfig.fromJson(results[0]);
      _applyHome(results[1]);
      if (!config.usablePayments.any((p) => p.key == paymentMethod) && config.usablePayments.isNotEmpty) {
        paymentMethod = config.usablePayments.first.key;
      }
      ready = true;
      if (signedIn) unawaited(refreshMe());
    } on ApiException catch (e) {
      bootError = e.message;
    } catch (e) {
      bootError = 'Something went wrong while opening the shop. Please try again.';
    } finally {
      booting = false;
      notifyListeners();
    }
  }

  void _restore() {
    final p = _prefs!;
    api.userToken = p.getString('user_token');
    api.staffToken = p.getString('staff_token');
    final u = p.getString('user');
    if (u != null && api.userToken != null) user = ApiUser.fromJson(jsonDecode(u) as Map<String, dynamic>);
    staffName = p.getString('staff_name');
    staffRole = p.getString('staff_role') ?? 'admin';
    notifications = p.getBool('notifications') ?? notifications;
    pincode = p.getString('pincode') ?? pincode;
    street = p.getString('street') ?? street;
    city = p.getString('city') ?? city;
    guestName = p.getString('guest_name') ?? '';
    guestPhone = p.getString('guest_phone') ?? '';
    guestEmail = p.getString('guest_email') ?? '';
    favourites
      ..clear()
      ..addAll((p.getStringList('favourites') ?? const []).map(int.tryParse).whereType<int>());
    final c = p.getString('cart');
    cart.clear();
    if (c != null) {
      try {
        cart.addAll((jsonDecode(c) as List).map((e) => CartLine.fromJson(Map<String, dynamic>.from(e as Map))));
      } catch (_) {}
    }
    final k = p.getString('guest_orders');
    guestOrderKeys.clear();
    if (k != null) {
      try {
        guestOrderKeys.addAll(Map<String, String>.from(jsonDecode(k) as Map));
      } catch (_) {}
    }
  }

  void _save() {
    final p = _prefs;
    if (p == null) return;
    p.setString('cart', jsonEncode(cart.map((l) => l.toJson()).toList()));
    p.setStringList('favourites', favourites.map((e) => '$e').toList());
    p.setString('guest_orders', jsonEncode(guestOrderKeys));
    p.setBool('notifications', notifications);
    p.setString('pincode', pincode);
    p.setString('street', street);
    p.setString('city', city);
    p.setString('guest_name', guestName);
    p.setString('guest_phone', guestPhone);
    p.setString('guest_email', guestEmail);
  }

  void _onUnauthorized(ApiAuth auth) {
    if (auth == ApiAuth.user && user != null) {
      _clearUser();
      notifyListeners();
    } else if (auth == ApiAuth.staff) {
      _clearStaff();
      notifyListeners();
    }
  }

  // ---------- Account ----------
  ApiUser? user;
  bool get signedIn => user != null && api.userToken != null;

  // Contact details remembered for guest checkout.
  String guestName = '';
  String guestPhone = '';
  String guestEmail = '';

  bool notifications = true;

  String get userName => user?.name ?? (guestName.isNotEmpty ? guestName : 'Guest');
  String get phone => user?.phone ?? guestPhone;
  String get email => user?.email ?? guestEmail;
  String get firstName => userName.split(' ').first;
  String get initials {
    final s = userName.split(' ').where((w) => w.isNotEmpty).map((w) => w[0].toUpperCase()).take(2).join();
    return s.isEmpty ? '🙂' : s;
  }

  /// Phone shown as "98765 43210".
  String get phoneDisplay => phone.length == 10 ? '${phone.substring(0, 5)} ${phone.substring(5)}' : phone;

  Future<void> _signedIn(Map<String, dynamic> res) async {
    api.userToken = res['token'] as String;
    user = ApiUser.fromJson(Map<String, dynamic>.from(res['user'] as Map));
    await _prefs?.setString('user_token', api.userToken!);
    await _prefs?.setString('user', jsonEncode(user!.toJson()));
    await _syncFavouritesAfterSignIn();
    myOrders = [];
    milkPlan = null;
    milkLoaded = false;
    notifyListeners();
  }

  Future<void> login({required String phone, required String password}) async {
    final res = await api.post('/auth/login', {
      'phone': phone,
      'password': password,
      'device_name': 'Uttaranchal app',
      'wishlist': favourites.toList(),
    }, ApiAuth.none);
    await _signedIn(res);
  }

  Future<void> register({required String name, required String phone, required String email, required String password, bool newsletter = false}) async {
    final res = await api.post('/auth/register', {
      'name': name,
      'phone': phone,
      'email': email,
      'password': password,
      'password_confirmation': password,
      'newsletter': newsletter,
      'device_name': 'Uttaranchal app',
      'wishlist': favourites.toList(),
    }, ApiAuth.none);
    await _signedIn(res);
  }

  Future<String> forgotPassword(String email) async {
    final res = await api.post('/auth/forgot-password', {'email': email}, ApiAuth.none);
    return (res['message'] as String?) ?? 'Check your email for a reset link.';
  }

  Future<void> refreshMe() async {
    try {
      final res = await api.get('/me');
      user = ApiUser.fromJson(Map<String, dynamic>.from(res['user'] as Map));
      await _prefs?.setString('user', jsonEncode(user!.toJson()));
      final ids = (res['wishlist_ids'] as List?)?.map((e) => (e as num).toInt()) ?? const <int>[];
      favourites
        ..clear()
        ..addAll(ids);
      _save();
      notifyListeners();
    } on ApiException catch (_) {
      // Offline or signed out elsewhere — keep what we have; a 401 already signed the user out.
    }
  }

  Future<void> updateProfile({String? name, String? email}) async {
    final res = await api.patch('/me', {if (name != null) 'name': name, if (email != null) 'email': email});
    user = ApiUser.fromJson(Map<String, dynamic>.from(res['user'] as Map));
    await _prefs?.setString('user', jsonEncode(user!.toJson()));
    notifyListeners();
  }

  Future<void> changePassword(String current, String next) async {
    await api.post('/me/password', {'current_password': current, 'password': next, 'password_confirmation': next});
  }

  Future<void> logout() async {
    try {
      if (signedIn) await api.post('/auth/logout');
    } on ApiException catch (_) {}
    _clearUser();
    notifyListeners();
  }

  Future<void> deleteAccount(String password) async {
    await api.delete('/me', {'password': password});
    _clearUser();
    notifyListeners();
  }

  void _clearUser() {
    api.userToken = null;
    user = null;
    myOrders = [];
    milkPlan = null;
    milkLoaded = false;
    _prefs?.remove('user_token');
    _prefs?.remove('user');
  }

  void toggleNotifications(bool v) {
    notifications = v;
    _save();
    notifyListeners();
  }

  // ---------- Address (kept on the phone; the website asks for it at each checkout too) ----------
  String pincode = '';
  String street = '';
  String city = 'Kashipur, Uttarakhand';

  bool get hasAddress => street.trim().isNotEmpty && pincode.length == 6;
  String get area => street.contains(',') ? street.split(',').last.trim() : (street.isEmpty ? 'Add your address' : street);
  String get fullAddress => [street, city].where((s) => s.trim().isNotEmpty).join(', ');

  void saveAddress({required String pincode, required String street, required String city}) {
    this.pincode = pincode;
    this.street = street;
    this.city = city;
    _save();
    notifyListeners();
    unawaited(refreshQuote());
  }

  Future<(bool local, String message)> checkPincode(String pin) async {
    try {
      final res = await api.get('/pincode/$pin', auth: ApiAuth.none);
      return (res['local'] == true, '${res['message'] ?? ''}');
    } on ApiException catch (e) {
      return (false, e.message);
    }
  }

  // ---------- Catalogue ----------
  List<ShopCategory> categories = [];
  List<Product> featured = [];
  final Map<int, Product> _products = {};

  Product? productById(int id) => _products[id];

  void _cache(Iterable<Product> list) {
    for (final p in list) {
      _products[p.id] = p;
    }
  }

  void _applyHome(Map<String, dynamic> res) {
    categories = ((res['categories'] as List?) ?? const []).map((e) => ShopCategory.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    featured = ((res['featured'] as List?) ?? const []).map((e) => Product.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    _cache(featured);
  }

  Future<void> refreshHome() async {
    _applyHome(await api.get('/home'));
    notifyListeners();
  }

  List<Product> _parseProducts(dynamic data) {
    final list = ((data as List?) ?? const []).map((e) => Product.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    _cache(list);
    return list;
  }

  /// Same filters as /shop on the website. [sort]: featured | low | high
  Future<List<Product>> fetchProducts({String? category, String? query, String sort = 'featured'}) async {
    final res = await api.get('/products', query: {'category': category, 'q': query, 'sort': sort});
    return _parseProducts(res['data']);
  }

  Future<(Product, List<Product>)> fetchProduct(Object idOrSlug) async {
    final res = await api.get('/products/$idOrSlug');
    final p = Product.fromJson(Map<String, dynamic>.from(res['data'] as Map));
    _cache([p]);
    return (p, _parseProducts(res['related']));
  }

  Future<List<Product>> search(String q) async {
    final res = await api.get('/search', query: {'q': q});
    return _parseProducts(res['data']);
  }

  Future<List<(String title, String body)>> fetchPage(String page) async {
    final res = await api.get('/pages/$page', auth: ApiAuth.none);
    return ((res['items'] as List?) ?? const []).map((e) => ('${(e as Map)['title']}', '${e['body']}')).toList();
  }

  // ---------- Favourites (shared with the website's wishlist when signed in) ----------
  final Set<int> favourites = {};

  Future<bool> toggleFavourite(Product p) async {
    final saved = !favourites.contains(p.id);
    saved ? favourites.add(p.id) : favourites.remove(p.id);
    _save();
    notifyListeners();
    if (signedIn) {
      try {
        final res = await api.post('/wishlist/${p.id}');
        final ids = (res['ids'] as List?)?.map((e) => (e as num).toInt()) ?? const <int>[];
        favourites
          ..clear()
          ..addAll(ids);
        _save();
        notifyListeners();
      } on ApiException catch (_) {}
    }
    return saved;
  }

  Future<List<Product>> fetchWishlist() async {
    if (!signedIn) {
      final known = favourites.map((id) => _products[id]).whereType<Product>().toList();
      return known;
    }
    final res = await api.get('/wishlist');
    return _parseProducts(res['data']);
  }

  Future<void> _syncFavouritesAfterSignIn() async {
    try {
      final res = await api.post('/wishlist/merge', {'ids': favourites.toList()});
      final ids = (res['ids'] as List?)?.map((e) => (e as num).toInt()) ?? const <int>[];
      favourites
        ..clear()
        ..addAll(ids);
      _save();
    } on ApiException catch (_) {}
  }

  // ---------- Bag ----------
  final List<CartLine> cart = [];
  String cartNote = '';
  CartQuote? quote;
  bool quoting = false;
  String? quoteError;

  int get cartCount => cart.fold(0, (s, l) => s + l.qty);
  double get itemsTotal => quote?.subtotal ?? cart.fold(0.0, (s, l) => s + l.total);
  double get deliveryFee => quote?.deliveryFee ?? 0;
  double get bagTotal => quote?.total ?? itemsTotal;
  double get payable => bagTotal;

  /// How many of this product (all sizes) are in the bag.
  int qtyInBag(int productId) => cart.where((l) => l.productId == productId).fold(0, (s, l) => s + l.qty);

  CartLine? _line(int productId, int? optionId) {
    for (final l in cart) {
      if (l.productId == productId && l.optionId == optionId) return l;
    }
    return null;
  }

  /// Adds to the bag. Returns an error message (e.g. not enough stock) or null on success.
  String? addProduct(Product p, {int? optionId, int qty = 1}) {
    final oid = p.hasOptions ? (p.optionById(optionId) ?? p.defaultOption)!.id : null;
    if (p.soldOutFor(oid)) return 'Sorry, ${p.name} is sold out';
    final existing = _line(p.id, oid);
    final want = (existing?.qty ?? 0) + qty;
    final stock = p.stockFor(oid);
    if (stock != null && want > stock) return 'Only $stock of ${p.name} available';
    if (want > config.maxLineQuantity) return 'You can add up to ${config.maxLineQuantity} of one item';
    if (existing != null) {
      existing.qty = want;
    } else {
      cart.add(CartLine(
        productId: p.id,
        optionId: oid,
        name: p.name,
        label: p.labelFor(oid),
        imageUrl: p.imageUrl,
        unitPrice: p.priceFor(oid),
        qty: qty,
        perishable: p.isPerishable,
        available: stock,
      ));
    }
    _cartChanged();
    return null;
  }

  void setQty(CartLine line, int qty) {
    if (qty <= 0) {
      cart.remove(line);
    } else {
      line.qty = line.available != null && qty > line.available! ? line.available! : qty;
    }
    _cartChanged();
  }

  void restoreLine(CartLine line, int index) {
    cart.insert(index.clamp(0, cart.length), line);
    _cartChanged();
  }

  void clearCart() {
    cart.clear();
    cartNote = '';
    quote = null;
    _cartChanged(requote: false);
  }

  void setNote(String v) {
    cartNote = v;
  }

  Timer? _quoteDebounce;

  void _cartChanged({bool requote = true}) {
    _save();
    notifyListeners();
    if (!requote) return;
    _quoteDebounce?.cancel();
    _quoteDebounce = Timer(const Duration(milliseconds: 400), () => refreshQuote());
  }

  /// Ask the server for current prices, stock, delivery fees and eligibility.
  Future<void> refreshQuote() async {
    if (cart.isEmpty) {
      quote = null;
      notifyListeners();
      return;
    }
    quoting = true;
    notifyListeners();
    try {
      final res = await api.post('/cart/quote', {
        'items': cart.map((l) => l.toApi()).toList(),
        'delivery_method': deliveryMethod,
        if (pincode.length == 6) 'pincode': pincode,
        'payment_method': paymentMethod,
      });
      final q = CartQuote.fromJson(res);
      // Drop lines the shop no longer sells and take the server's current price/stock for the rest.
      final keep = <String>{};
      for (final l in q.lines) {
        final pid = (l['product_id'] as num).toInt();
        final oid = (l['option_id'] as num?)?.toInt();
        final mine = _line(pid, oid) ?? (oid != null ? _line(pid, null) : null);
        if (mine == null) continue;
        final pj = l['product'];
        if (pj is Map) _cache([Product.fromJson(Map<String, dynamic>.from(pj))]);
        final replacement = CartLine(
          productId: pid,
          optionId: oid,
          name: '${l['name']}',
          label: '${l['label']}',
          imageUrl: pj is Map ? '${pj['image_url'] ?? mine.imageUrl}' : mine.imageUrl,
          unitPrice: (l['unit_price'] as num).toDouble(),
          qty: mine.qty,
          perishable: l['is_perishable'] == true,
          available: (l['available'] as num?)?.toInt(),
        );
        final i = cart.indexOf(mine);
        cart[i] = replacement;
        keep.add(replacement.key);
      }
      cart.removeWhere((l) => !keep.contains(l.key));
      quote = q;
      quoteError = null;
      // If the chosen delivery method isn't allowed for this bag any more, pick the first one that is.
      final m = q.method(deliveryMethod);
      if (m != null && !m.available) {
        final ok = q.deliveryMethods.where((d) => d.available);
        if (ok.isNotEmpty) deliveryMethod = ok.first.key;
      }
      _save();
    } on ApiException catch (e) {
      quoteError = e.message;
    } finally {
      quoting = false;
      notifyListeners();
    }
  }

  // ---------- Checkout ----------
  String deliveryMethod = 'local'; // pickup | local | courier
  String? deliverySlot = 'morning';
  String paymentMethod = 'cod'; // upi | card | cod

  bool get pickup => deliveryMethod == 'pickup';

  String get deliveryShortLabel {
    for (final m in config.deliveryMethods) {
      if (m.key == deliveryMethod) return m.shortLabel;
    }
    return deliveryMethod;
  }

  String get paymentLabel {
    for (final p in config.paymentMethods) {
      if (p.key == paymentMethod) return p.label;
    }
    return paymentMethod;
  }

  String? get slotLabel {
    for (final s in config.deliverySlots) {
      if (s.key == deliverySlot) return s.label;
    }
    return null;
  }

  void setDeliveryMethod(String v) {
    deliveryMethod = v;
    if (v == 'courier' && paymentMethod == 'cod') {
      final online = config.usablePayments.where((p) => p.online);
      if (online.isNotEmpty) paymentMethod = online.first.key;
    }
    notifyListeners();
    unawaited(refreshQuote());
  }

  void setPickup(bool v) => setDeliveryMethod(v ? 'pickup' : 'local');

  void setSlot(String? v) {
    deliverySlot = v;
    notifyListeners();
  }

  void setPayment(String v) {
    paymentMethod = v;
    notifyListeners();
  }

  // Contact details for this checkout (pre-filled from the account, editable).
  String? _coName;
  String? _coPhone;
  String? _coEmail;
  String get checkoutName => _coName ?? (signedIn || guestName.isNotEmpty ? userName : '');
  String get checkoutPhone => _coPhone ?? phone;
  String get checkoutEmail => _coEmail ?? email;

  void setCheckoutContact({required String name, required String phone, required String email}) {
    _coName = name;
    _coPhone = phone;
    _coEmail = email;
  }

  void setGuestContact({required String name, required String phone, required String email}) {
    guestName = name;
    guestPhone = phone;
    guestEmail = email;
    _save();
  }

  /// Places the order on the server (same `orders` table and checkout rules as the website).
  Future<ShopOrder> placeOrder({required String name, required String phone, required String email}) async {
    final address = pickup ? (fullAddress.isEmpty ? 'Store pickup' : fullAddress) : fullAddress;
    final res = await api.post('/orders', {
      'items': cart.map((l) => l.toApi()).toList(),
      'customer_name': name,
      'phone': phone,
      'email': email,
      'pincode': pincode,
      'delivery_method': deliveryMethod,
      'address': address,
      'delivery_slot': deliveryMethod == 'courier' ? null : deliverySlot,
      'payment_method': paymentMethod,
      if (cartNote.trim().isNotEmpty) 'note': cartNote.trim(),
      if (quote != null) 'expected_total': quote!.total,
    });
    final order = ShopOrder.fromJson(Map<String, dynamic>.from(res['order'] as Map));
    final key = res['access_key'] as String?;
    if (key != null) guestOrderKeys[order.number] = key;
    if (!signedIn) setGuestContact(name: name, phone: phone, email: email);
    lastOrder = order;
    cart.clear();
    cartNote = '';
    quote = null;
    _save();
    notifyListeners();
    return order;
  }

  // ---------- Online payment (Razorpay) ----------
  Map<String, String> _orderHeaders(String number) => guestOrderKeys.containsKey(number) ? {'X-Order-Key': guestOrderKeys[number]!} : const {};

  Future<Map<String, dynamic>> startPayment(String number) => api.post('/orders/$number/payment/start', null, ApiAuth.user, _orderHeaders(number));

  Future<ShopOrder> verifyPayment(String number, {required String paymentId, required String razorpayOrderId, required String signature}) async {
    final res = await api.post(
      '/orders/$number/payment/verify',
      {'razorpay_payment_id': paymentId, 'razorpay_order_id': razorpayOrderId, 'razorpay_signature': signature},
      ApiAuth.user,
      _orderHeaders(number),
    );
    final o = ShopOrder.fromJson(Map<String, dynamic>.from(res['order'] as Map));
    _remember(o);
    return o;
  }

  // ---------- Orders ----------
  ShopOrder? lastOrder;
  List<ShopOrder> myOrders = [];
  bool loadingOrders = false;
  final Map<String, String> guestOrderKeys = {};

  void _remember(ShopOrder o) {
    if (lastOrder?.number == o.number) lastOrder = o;
    final i = myOrders.indexWhere((x) => x.number == o.number);
    if (i >= 0) myOrders[i] = o;
    notifyListeners();
  }

  /// Signed in: every order on the account (website + app). Guest: orders placed from this phone.
  Future<void> loadMyOrders() async {
    loadingOrders = true;
    notifyListeners();
    try {
      if (signedIn) {
        final res = await api.get('/orders', query: {'per_page': 30});
        myOrders = ((res['data'] as List?) ?? const []).map((e) => ShopOrder.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      } else {
        final list = <ShopOrder>[];
        for (final number in guestOrderKeys.keys.toList().reversed.take(20)) {
          try {
            list.add(await fetchOrder(number));
          } on ApiException catch (_) {}
        }
        myOrders = list;
      }
    } finally {
      loadingOrders = false;
      notifyListeners();
    }
  }

  Future<ShopOrder> fetchOrder(String number) async {
    final res = await api.get('/orders/$number', headers: _orderHeaders(number));
    final o = ShopOrder.fromJson(Map<String, dynamic>.from(res['order'] as Map));
    _remember(o);
    return o;
  }

  Future<ShopOrder> cancelOrder(String number) async {
    final res = await api.post('/orders/$number/cancel', null, ApiAuth.user, _orderHeaders(number));
    final o = ShopOrder.fromJson(Map<String, dynamic>.from(res['order'] as Map));
    _remember(o);
    return o;
  }

  /// A short-lived link to the order's PDF invoice (opened in the phone's browser / PDF viewer).
  Future<String> invoiceLink(String number) async {
    final res = await api.get('/orders/$number/invoice', headers: _orderHeaders(number));
    return '${res['url']}';
  }

  Future<ShopOrder> trackOrder(String number, String contact) async {
    final res = await api.post('/track', {'number': number, 'contact': contact}, ApiAuth.none);
    return ShopOrder.fromJson(Map<String, dynamic>.from(res['order'] as Map));
  }

  /// Put the items of a past order back in the bag (skips anything no longer sold).
  Future<int> reorder(ShopOrder o) async {
    var added = 0;
    for (final i in o.items) {
      if (i.productId == null) continue;
      try {
        final p = _products[i.productId!] ?? (await fetchProduct(i.productId!)).$1;
        if (addProduct(p, optionId: i.optionId, qty: i.quantity) == null) added++;
      } on ApiException catch (_) {}
    }
    return added;
  }

  // ---------- Forms (land in the same admin screens as the website forms) ----------
  Future<String> sendEnquiry(String kind, Map<String, dynamic> body) async {
    final res = await api.post('/enquiries/$kind', body);
    return (res['message'] as String?) ?? 'Thank you — the shop will be in touch.';
  }

  // ---------- Shop staff (same accounts as /admin on the website) ----------
  String? staffName;
  String staffRole = 'admin'; // admin | delivery
  bool get staffSignedIn => api.staffToken != null;
  bool get isDeliveryStaff => staffRole == 'delivery';

  /// The staff app's "home": delivery staff start on their milk round, admins on shop orders.
  String get staffHome => isDeliveryStaff ? '/staff/dashboard' : '/staff/orders';

  Future<void> staffLogin(String email, String password) async {
    final res = await api.post('/staff/login', {'email': email, 'password': password, 'device_name': 'Uttaranchal staff app'}, ApiAuth.none);
    api.staffToken = res['token'] as String;
    staffName = '${(res['staff'] as Map)['name']}';
    staffRole = '${(res['staff'] as Map)['role'] ?? 'admin'}';
    staffDay = null;
    staffRouteId = null;
    await _prefs?.setString('staff_token', api.staffToken!);
    await _prefs?.setString('staff_name', staffName!);
    await _prefs?.setString('staff_role', staffRole);
    notifyListeners();
  }

  Future<void> staffLogout() async {
    try {
      if (staffSignedIn) await api.post('/staff/logout', null, ApiAuth.staff);
    } on ApiException catch (_) {}
    _clearStaff();
    notifyListeners();
  }

  void _clearStaff() {
    api.staffToken = null;
    staffName = null;
    staffRole = 'admin';
    staffDay = null;
    staffRouteId = null;
    _prefs?.remove('staff_token');
    _prefs?.remove('staff_name');
    _prefs?.remove('staff_role');
  }

  Future<StaffDashboard> staffDashboard() async => StaffDashboard.fromJson(await api.get('/staff/dashboard', auth: ApiAuth.staff));

  Future<(List<ShopOrder>, Map<String, int>)> staffOrders({String? status, String? query}) async {
    final res = await api.get('/staff/orders', query: {'status': status, 'q': query, 'per_page': 50}, auth: ApiAuth.staff);
    final orders = ((res['data'] as List?) ?? const []).map((e) => ShopOrder.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    final counts = <String, int>{};
    final c = res['counts'];
    if (c is Map) c.forEach((k, v) => counts['$k'] = (v as num).toInt());
    return (orders, counts);
  }

  Future<ShopOrder> staffOrder(int id) async =>
      ShopOrder.fromJson(Map<String, dynamic>.from((await api.get('/staff/orders/$id', auth: ApiAuth.staff))['order'] as Map));

  Future<ShopOrder> staffAdvance(int id) async =>
      ShopOrder.fromJson(Map<String, dynamic>.from((await api.post('/staff/orders/$id/advance', null, ApiAuth.staff))['order'] as Map));

  Future<ShopOrder> staffUpdateOrder(int id, {String? status, String? paymentStatus}) async {
    final res = await api.patch('/staff/orders/$id', {if (status != null) 'status': status, if (paymentStatus != null) 'payment_status': paymentStatus}, ApiAuth.staff);
    return ShopOrder.fromJson(Map<String, dynamic>.from(res['order'] as Map));
  }

  Future<List<StaffProduct>> staffProducts() async {
    final res = await api.get('/staff/products', auth: ApiAuth.staff);
    return ((res['data'] as List?) ?? const []).map((e) => StaffProduct.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  /// [delta] adjusts tracked stock; [setTo] sets it (use [stopTracking] to make it unlimited).
  Future<void> staffStock(int productId, {int? delta, int? setTo, bool stopTracking = false}) async {
    await api.patch('/staff/products/$productId/stock', {
      if (delta != null) 'delta': delta,
      if (setTo != null || stopTracking) 'stock_qty': stopTracking ? null : setTo,
    }, ApiAuth.staff);
  }

  Future<void> staffOptionStock(int optionId, {int? delta, int? setTo, bool stopTracking = false}) async {
    await api.patch('/staff/options/$optionId/stock', {
      if (delta != null) 'delta': delta,
      if (setTo != null || stopTracking) 'stock_qty': stopTracking ? null : setTo,
    }, ApiAuth.staff);
  }

  // ---------- Milk subscription (Api/MilkController on the server) ----------
  MilkConfig milkConfig = const MilkConfig();
  MilkPlan? milkPlan;
  bool milkLoaded = false;
  bool milkLoading = false;
  String? milkError;

  bool get milkPlanActive => milkPlan?.isActive ?? false;

  /// Loads the shop's milk settings and the customer's plan (needs sign-in).
  Future<void> loadMilk() async {
    if (!signedIn) {
      milkPlan = null;
      milkLoaded = true;
      notifyListeners();
      return;
    }
    milkLoading = true;
    milkError = null;
    notifyListeners();
    try {
      final results = await Future.wait([api.get('/milk/config'), api.get('/milk/subscription')]);
      milkConfig = MilkConfig.fromJson(results[0]);
      final sub = results[1]['subscription'];
      milkPlan = sub is Map ? MilkPlan.fromJson(Map<String, dynamic>.from(sub)) : null;
      milkLoaded = true;
    } on ApiException catch (e) {
      milkError = e.message;
    } finally {
      milkLoading = false;
      notifyListeners();
    }
  }

  void _setPlan(Map<String, dynamic> res) {
    final sub = res['subscription'];
    milkPlan = sub is Map ? MilkPlan.fromJson(Map<String, dynamic>.from(sub)) : null;
    notifyListeners();
  }

  // Plan being built or edited on the phone. Nothing is pre-selected.
  int milkLitres = 0;
  String? milkFrequency; // daily | alternate | custom
  DateTime milkStart = _tomorrow();
  String? milkSlot;
  bool milkReminders = true;
  String milkPaymentMethod = 'upi'; // upi | card | cash
  bool milkEditing = false;
  final Set<int> milkWeekdays = {};
  final Set<DateTime> milkExtraDates = {};
  final Set<DateTime> milkSkippedDates = {};

  static DateTime _tomorrow() {
    final n = DateTime.now().add(const Duration(days: 1));
    return DateTime(n.year, n.month, n.day);
  }

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
  static String _ymd(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Re-reads price and rules from the server (the shop can change the price in the admin panel).
  Future<void> refreshMilkConfig() async {
    try {
      milkConfig = MilkConfig.fromJson(await api.get('/milk/config'));
      notifyListeners();
    } on ApiException catch (_) {}
  }

  /// Start building a new plan, or editing the current one.
  void startMilkDraft({bool edit = false}) {
    if (signedIn) unawaited(refreshMilkConfig());
    final p = milkPlan;
    milkEditing = edit && p != null;
    milkWeekdays.clear();
    milkExtraDates.clear();
    milkSkippedDates.clear();
    if (milkEditing) {
      milkLitres = p!.litres;
      milkFrequency = p.frequency;
      milkStart = p.startDate.isAfter(DateTime.now()) ? _day(p.startDate) : _tomorrow();
      milkSlot = p.slot;
      milkReminders = p.reminders;
      milkWeekdays.addAll(p.weekdays);
    } else {
      milkLitres = 0;
      milkFrequency = null;
      milkStart = _tomorrow();
      milkSlot = null;
      milkReminders = true;
    }
    notifyListeners();
  }

  bool get milkPlanComplete =>
      milkLitres > 0 && milkFrequency != null && milkSlot != null && (milkFrequency != 'custom' || milkWeekdays.isNotEmpty || milkExtraDates.isNotEmpty);

  /// Delivery on [d] under the plan being built (mirrors the server rules).
  bool milkDeliversOn(DateTime d) {
    final day = _day(d);
    if (day.isBefore(milkStart) || milkFrequency == null) return false;
    if (milkSkippedDates.contains(day)) return false;
    if (milkExtraDates.contains(day)) return true;
    return switch (milkFrequency) {
      'alternate' => day.difference(milkStart).inDays.isEven,
      'custom' => milkWeekdays.contains(day.weekday),
      _ => true,
    };
  }

  void toggleMilkDate(DateTime d) {
    final day = _day(d);
    if (day.isBefore(milkStart)) return;
    final inPattern = milkFrequency == 'custom' && milkWeekdays.contains(day.weekday);
    if (milkDeliversOn(day)) {
      inPattern ? milkSkippedDates.add(day) : milkExtraDates.remove(day);
    } else {
      inPattern ? milkSkippedDates.remove(day) : milkExtraDates.add(day);
    }
    notifyListeners();
  }

  void toggleMilkWeekday(int weekday) {
    milkWeekdays.contains(weekday) ? milkWeekdays.remove(weekday) : milkWeekdays.add(weekday);
    milkSkippedDates.removeWhere((d) => d.weekday == weekday);
    milkExtraDates.removeWhere((d) => d.weekday == weekday);
    notifyListeners();
  }

  int get milkDeliveriesFirstMonth {
    var n = 0;
    for (var i = 0; i < milkConfig.firstPaymentDays; i++) {
      if (milkDeliversOn(milkStart.add(Duration(days: i)))) n++;
    }
    return n;
  }

  double get perDelivery => milkLitres * milkConfig.pricePerLitre;
  double get milkFirstPayment => perDelivery * milkDeliveriesFirstMonth;

  String get milkScheduleText => switch (milkFrequency) {
        'custom' => milkWeekdays.isEmpty ? 'Selected dates' : (milkWeekdays.toList()..sort()).map((w) => const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][w - 1]).join(', '),
        null => 'Not chosen',
        _ => milkConfig.frequencyLabel(milkFrequency),
      };

  void configureMilk({int? litres, String? frequency, DateTime? start, String? slot}) {
    if (litres != null) milkLitres = litres;
    if (frequency != null) milkFrequency = frequency;
    if (start != null) {
      milkStart = _day(start);
      milkExtraDates.removeWhere((d) => d.isBefore(milkStart));
      milkSkippedDates.removeWhere((d) => d.isBefore(milkStart));
    }
    if (slot != null) milkSlot = slot;
    notifyListeners();
  }

  void setMilkReminders(bool v) {
    milkReminders = v;
    notifyListeners();
  }

  void setMilkPayment(String v) {
    milkPaymentMethod = v;
    notifyListeners();
  }

  /// Saves the plan on the server (new plan → waits for the first payment).
  Future<MilkPlan> saveMilkDraft() async {
    final body = <String, dynamic>{
      'litres': milkLitres,
      'frequency': milkFrequency,
      'weekdays': milkWeekdays.toList()..sort(),
      'slot': milkSlot,
      'reminders': milkReminders,
      'address': fullAddress,
      'pincode': pincode,
      if (!milkEditing || milkPlan!.awaitingPayment || milkPlan!.startDate.isAfter(DateTime.now())) 'start_date': _ymd(milkStart),
    };
    if (!milkEditing) {
      body['extra_dates'] = milkExtraDates.map(_ymd).toList();
      body['skip_dates'] = milkSkippedDates.map(_ymd).toList();
      if (user != null) {
        body['customer_name'] = user!.name;
        body['phone'] = user!.phone;
      }
    }
    final res = milkEditing ? await api.patch('/milk/subscription', body) : await api.post('/milk/subscription', body);
    _setPlan(res);
    return milkPlan!;
  }

  /// Start a Razorpay payment into the milk balance. Returns the data the checkout needs.
  Future<Map<String, dynamic>> startMilkTopup(double amount, String method) =>
      api.post('/milk/topups', {'amount': double.parse(amount.toStringAsFixed(2)), 'method': method});

  Future<void> verifyMilkTopup(int topupId, {required String paymentId, required String orderId, required String signature}) async {
    _setPlan(await api.post('/milk/topups/$topupId/verify', {'razorpay_payment_id': paymentId, 'razorpay_order_id': orderId, 'razorpay_signature': signature}));
  }

  Future<String> milkStartWithCash() async {
    final res = await api.post('/milk/subscription/cash');
    _setPlan(res);
    return '${res['message'] ?? 'Your milk plan is active.'}';
  }

  /// Skip a day or add milk on a day (respects the shop's evening cut-off).
  Future<void> milkSetDay(DateTime date, bool deliver) async {
    _setPlan(await api.post('/milk/subscription/day', {'date': _ymd(date), 'deliver': deliver}));
  }

  Future<String> milkPause(DateTime from, DateTime resume) async {
    final res = await api.post('/milk/subscription/pause', {'from': _ymd(from), 'resume': _ymd(resume)});
    _setPlan(res);
    return '${res['message'] ?? 'Paused'}';
  }

  Future<String> milkCancel() async {
    final res = await api.post('/milk/subscription/cancel');
    milkPlan = null;
    notifyListeners();
    return '${res['message'] ?? 'Your milk plan has been cancelled.'}';
  }

  // ---------- Staff milk round (Api/Staff/StaffMilkController on the server) ----------
  StaffMilkDay? staffDay;
  int? staffRouteId;
  bool staffDayLoading = false;
  String? staffDayError;

  Future<StaffMilkDay?> loadStaffDay({int? routeId}) async {
    if (routeId != null) staffRouteId = routeId;
    staffDayLoading = true;
    staffDayError = null;
    notifyListeners();
    try {
      final res = await api.get('/staff/milk/day', query: {if (staffRouteId != null) 'route_id': staffRouteId}, auth: ApiAuth.staff);
      staffDay = StaffMilkDay.fromJson(res);
      staffRouteId = staffDay!.route.id;
    } on ApiException catch (e) {
      staffDayError = e.message;
    } finally {
      staffDayLoading = false;
      notifyListeners();
    }
    return staffDay;
  }

  Map<String, dynamic> get _routeParam => {if (staffRouteId != null) 'route_id': staffRouteId};

  void _setDay(Map<String, dynamic> res) {
    staffDay = StaffMilkDay.fromJson(res);
    notifyListeners();
  }

  Future<void> staffStartShift({required int litresLoaded, required int bottlesLoaded}) async {
    _setDay(await api.post('/staff/milk/shift/start', {..._routeParam, 'litres_loaded': litresLoaded, 'bottles_loaded': bottlesLoaded}, ApiAuth.staff));
  }

  Future<void> staffEndShift({required int bottlesReturned, int litresReturned = 0, String? note}) async {
    _setDay(await api.post('/staff/milk/shift/end', {
      ..._routeParam,
      'bottles_returned': bottlesReturned,
      'litres_returned': litresReturned,
      if (note != null && note.isNotEmpty) 'note': note,
    }, ApiAuth.staff));
  }

  /// Report damaged bottles / packets with a camera photo, location and time. The shop approves it in the admin panel.
  Future<String> staffReportDamage({
    required String photoPath,
    required String itemType,
    required int count,
    required String reason,
    String? note,
    double? latitude,
    double? longitude,
    double? accuracy,
    required DateTime capturedAt,
    int? deliveryId,
  }) async {
    final res = await api.upload('/staff/milk/damage', auth: ApiAuth.staff, fileField: 'photo', filePath: photoPath, fields: {
      if (staffRouteId != null) 'route_id': '$staffRouteId',
      'item_type': itemType,
      'count': '$count',
      'reason': reason,
      if (note != null && note.isNotEmpty) 'note': note,
      if (latitude != null) 'latitude': latitude.toStringAsFixed(7),
      if (longitude != null) 'longitude': longitude.toStringAsFixed(7),
      if (accuracy != null) 'accuracy': accuracy.toStringAsFixed(1),
      'captured_at': capturedAt.toUtc().toIso8601String(),
      if (deliveryId != null) 'delivery_id': '$deliveryId',
    });
    await loadStaffDay();
    return '${res['message'] ?? 'Damage reported'}';
  }

  Future<String> staffDeliver(int id, {int bottlesBack = 0, String? note}) async {
    final res = await api.post('/staff/milk/deliveries/$id/deliver', {'bottles_back': bottlesBack, if (note != null && note.isNotEmpty) 'note': note}, ApiAuth.staff);
    await loadStaffDay();
    return '${res['message'] ?? 'Delivered'}';
  }

  Future<String> staffException(int id, {required String reason, String? note}) async {
    final res = await api.post('/staff/milk/deliveries/$id/exception', {'reason': reason, if (note != null && note.isNotEmpty) 'note': note}, ApiAuth.staff);
    await loadStaffDay();
    return '${res['message'] ?? 'Saved'}';
  }

  Future<String> staffUndo(int id) async {
    final res = await api.post('/staff/milk/deliveries/$id/undo', null, ApiAuth.staff);
    await loadStaffDay();
    return '${res['message'] ?? 'Undone'}';
  }

  Future<String> staffCash(int id, double amount) async {
    final res = await api.post('/staff/milk/deliveries/$id/cash', {'amount': amount}, ApiAuth.staff);
    await loadStaffDay();
    return '${res['message'] ?? 'Cash recorded'}';
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

/// Rupees for amounts from the server (₹1,250). Rounds like the website's money() helper.
String money(num v) => rupees(v.round());
