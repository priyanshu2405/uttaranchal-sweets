// Data shapes returned by the Laravel API (see app/Support/ApiPresenter.php on the server).

double _d(dynamic v) => v == null ? 0 : (v is num ? v.toDouble() : double.tryParse('$v') ?? 0);
int? _i(dynamic v) => v == null ? null : (v is num ? v.toInt() : int.tryParse('$v'));
String? _s(dynamic v) => v == null ? null : '$v';
DateTime? _date(dynamic v) => v == null ? null : DateTime.tryParse('$v')?.toLocal();
List<Map<String, dynamic>> _list(dynamic v) => v is List ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : const [];

class ShopCategory {
  final int id;
  final String slug;
  final String name;
  const ShopCategory({required this.id, required this.slug, required this.name});

  factory ShopCategory.fromJson(Map<String, dynamic> j) => ShopCategory(id: _i(j['id']) ?? 0, slug: _s(j['slug']) ?? '', name: _s(j['name']) ?? '');
}

class ProductOption {
  final int id;
  final String label;
  final double price;
  final int? stockQty;
  final bool soldOut;
  const ProductOption({required this.id, required this.label, required this.price, this.stockQty, this.soldOut = false});

  factory ProductOption.fromJson(Map<String, dynamic> j) => ProductOption(
        id: _i(j['id']) ?? 0,
        label: _s(j['label']) ?? '',
        price: _d(j['price']),
        stockQty: _i(j['stock_qty']),
        soldOut: j['sold_out'] == true,
      );
}

class Product {
  final int id;
  final String slug;
  final String name;
  final String? nameHi;
  final ShopCategory? category;
  final double price;
  final String priceLabel;
  final String unit;
  final String? tagline;
  final String description;
  final String imageUrl;
  final bool isPerishable;
  final bool soldOut;
  final int? stockQty;
  final List<ProductOption> options;
  final int? defaultOptionId;
  final String? webUrl;

  const Product({
    required this.id,
    required this.slug,
    required this.name,
    this.nameHi,
    this.category,
    required this.price,
    required this.priceLabel,
    required this.unit,
    this.tagline,
    this.description = '',
    this.imageUrl = '',
    this.isPerishable = false,
    this.soldOut = false,
    this.stockQty,
    this.options = const [],
    this.defaultOptionId,
    this.webUrl,
  });

  factory Product.fromJson(Map<String, dynamic> j) => Product(
        id: _i(j['id']) ?? 0,
        slug: _s(j['slug']) ?? '',
        name: _s(j['name']) ?? '',
        nameHi: _s(j['name_hi']),
        category: j['category'] is Map ? ShopCategory.fromJson(Map<String, dynamic>.from(j['category'] as Map)) : null,
        price: _d(j['price']),
        priceLabel: _s(j['price_label']) ?? '',
        unit: _s(j['unit']) ?? '',
        tagline: _s(j['tagline']),
        description: _s(j['description']) ?? '',
        imageUrl: _s(j['image_url']) ?? '',
        isPerishable: j['is_perishable'] == true,
        soldOut: j['sold_out'] == true,
        stockQty: _i(j['stock_qty']),
        options: _list(j['options']).map(ProductOption.fromJson).toList(),
        defaultOptionId: _i(j['default_option_id']),
        webUrl: _s(j['web_url']),
      );

  bool get hasOptions => options.isNotEmpty;

  ProductOption? optionById(int? id) {
    if (id == null) return null;
    for (final o in options) {
      if (o.id == id) return o;
    }
    return null;
  }

  ProductOption? get defaultOption => optionById(defaultOptionId) ?? (options.isEmpty ? null : options.first);

  double priceFor(int? optionId) => hasOptions ? (optionById(optionId) ?? defaultOption)!.price : price;

  String labelFor(int? optionId) => hasOptions ? (optionById(optionId) ?? defaultOption)!.label : unit;

  /// Units still available for this size, or null when the shop doesn't track stock.
  int? stockFor(int? optionId) => hasOptions ? (optionById(optionId) ?? defaultOption)!.stockQty : stockQty;

  bool soldOutFor(int? optionId) => hasOptions ? (optionById(optionId) ?? defaultOption)!.soldOut : soldOut;

  String get sizeText => hasOptions ? (options.length > 1 ? '${options.length} sizes' : options.first.label) : unit;

  String get subtitle => [sizeText, if (tagline != null && tagline!.isNotEmpty) tagline!].join(' · ');

  bool matches(String q) {
    final s = q.trim().toLowerCase();
    if (s.isEmpty) return true;
    return '$name ${nameHi ?? ''} ${tagline ?? ''} ${category?.name ?? ''}'.toLowerCase().contains(s);
  }
}

class ApiUser {
  final int id;
  final String name;
  final String phone;
  final String? email;
  const ApiUser({required this.id, required this.name, required this.phone, this.email});

  factory ApiUser.fromJson(Map<String, dynamic> j) => ApiUser(id: _i(j['id']) ?? 0, name: _s(j['name']) ?? '', phone: _s(j['phone']) ?? '', email: _s(j['email']));

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'phone': phone, 'email': email};
}

class OrderStep {
  final String key;
  final String label;
  final String state; // done | current | pending | cancelled
  const OrderStep(this.key, this.label, this.state);
}

class OrderItem {
  final int? productId;
  final int? optionId;
  final String name;
  final String unit;
  final double price;
  final int quantity;
  final String quantityText;
  final double lineTotal;
  final String? imageUrl;

  const OrderItem({
    this.productId,
    this.optionId,
    required this.name,
    required this.unit,
    required this.price,
    required this.quantity,
    required this.quantityText,
    required this.lineTotal,
    this.imageUrl,
  });

  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
        productId: _i(j['product_id']),
        optionId: _i(j['option_id']),
        name: _s(j['name']) ?? '',
        unit: _s(j['unit']) ?? '',
        price: _d(j['price']),
        quantity: _i(j['quantity']) ?? 1,
        quantityText: _s(j['quantity_text']) ?? '',
        lineTotal: _d(j['line_total']),
        imageUrl: _s(j['image_url']),
      );
}

/// An order from the shared `orders` table — placed on the website or in the app.
class ShopOrder {
  final int id;
  final String number;
  final String status;
  final String statusLabel;
  final String? nextStatus;
  final String deliveryMethod;
  final String deliveryLabel;
  final String? deliverySlotLabel;
  final String paymentMethod;
  final String paymentLabel;
  final String paymentStatus;
  final bool needsPayment;
  final bool canCancel;
  final String customerName;
  final String phone;
  final String? email;
  final String pincode;
  final String address;
  final String? note;
  final double subtotal;
  final double deliveryFee;
  final double taxAmount;
  final double total;
  final int itemsCount;
  final List<OrderStep> timeline;
  final List<OrderItem> items;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ShopOrder({
    required this.id,
    required this.number,
    required this.status,
    required this.statusLabel,
    this.nextStatus,
    required this.deliveryMethod,
    required this.deliveryLabel,
    this.deliverySlotLabel,
    required this.paymentMethod,
    required this.paymentLabel,
    required this.paymentStatus,
    required this.needsPayment,
    required this.canCancel,
    required this.customerName,
    required this.phone,
    this.email,
    required this.pincode,
    required this.address,
    this.note,
    required this.subtotal,
    required this.deliveryFee,
    required this.taxAmount,
    required this.total,
    required this.itemsCount,
    required this.timeline,
    required this.items,
    this.createdAt,
    this.updatedAt,
  });

  factory ShopOrder.fromJson(Map<String, dynamic> j) {
    final items = _list(j['items']).map(OrderItem.fromJson).toList();
    return ShopOrder(
      id: _i(j['id']) ?? 0,
      number: _s(j['number']) ?? '',
      status: _s(j['status']) ?? 'received',
      statusLabel: _s(j['status_label']) ?? '',
      nextStatus: _s(j['next_status']),
      deliveryMethod: _s(j['delivery_method']) ?? 'pickup',
      deliveryLabel: _s(j['delivery_label']) ?? '',
      deliverySlotLabel: _s(j['delivery_slot_label']),
      paymentMethod: _s(j['payment_method']) ?? 'cod',
      paymentLabel: _s(j['payment_label']) ?? '',
      paymentStatus: _s(j['payment_status']) ?? 'pending',
      needsPayment: j['needs_payment'] == true,
      canCancel: j['can_cancel'] == true,
      customerName: _s(j['customer_name']) ?? '',
      phone: _s(j['phone']) ?? '',
      email: _s(j['email']),
      pincode: _s(j['pincode']) ?? '',
      address: _s(j['address']) ?? '',
      note: _s(j['note']),
      subtotal: _d(j['subtotal']),
      deliveryFee: _d(j['delivery_fee']),
      taxAmount: _d(j['tax_amount']),
      total: _d(j['total']),
      itemsCount: _i(j['items_count']) ?? items.length,
      timeline: _list(j['timeline']).map((t) => OrderStep(_s(t['key']) ?? '', _s(t['label']) ?? '', _s(t['state']) ?? 'pending')).toList(),
      items: items,
      createdAt: _date(j['created_at']),
      updatedAt: _date(j['updated_at']),
    );
  }

  bool get isActive => const ['received', 'preparing', 'dispatched'].contains(status);
  bool get isCancelled => status == 'cancelled';
  bool get isDelivered => status == 'delivered';
  bool get isPickup => deliveryMethod == 'pickup';
  bool get isPaid => paymentStatus == 'paid';
  String? get firstImage => items.map((i) => i.imageUrl).firstWhere((u) => u != null && u.isNotEmpty, orElse: () => null);
}

class DeliveryMethodOption {
  final String key;
  final String label;
  final double fee;
  final double? freeOver;
  final bool available;
  final String? reason;
  const DeliveryMethodOption({required this.key, required this.label, required this.fee, this.freeOver, this.available = true, this.reason});

  factory DeliveryMethodOption.fromJson(Map<String, dynamic> j) => DeliveryMethodOption(
        key: _s(j['key']) ?? '',
        label: _s(j['label']) ?? '',
        fee: _d(j['fee']),
        freeOver: j['free_over'] == null ? null : _d(j['free_over']),
        available: j['available'] != false,
        reason: _s(j['reason']),
      );

  /// "Store pickup" from "Store pickup · Patel Nagar, Kashipur".
  String get shortLabel => label.split(' · ').first;
  String get detail => label.contains(' · ') ? label.split(' · ').last : '';
}

class KeyLabel {
  final String key;
  final String label;
  final bool online;
  const KeyLabel(this.key, this.label, {this.online = false});
}

class GiftPackaging {
  final String key;
  final String label;
  final double price;
  final int? productId;
  const GiftPackaging(this.key, this.label, this.price, this.productId);
}

/// Shop settings from GET /config (fees, slots, payment methods, contact details).
class ShopConfig {
  final Map<String, dynamic> shop;
  final List<DeliveryMethodOption> deliveryMethods;
  final List<KeyLabel> deliverySlots;
  final List<KeyLabel> paymentMethods;
  final bool razorpayEnabled;
  final String? razorpayKeyId;
  final List<GiftPackaging> giftPackaging;
  final int giftMaxItems;
  final int maxLineQuantity;
  final int unpaidCancelHours;
  final List<String> contactTopics;
  final List<String> bulkOccasions;
  final List<String> exportTypes;

  const ShopConfig({
    this.shop = const {},
    this.deliveryMethods = const [],
    this.deliverySlots = const [],
    this.paymentMethods = const [],
    this.razorpayEnabled = false,
    this.razorpayKeyId,
    this.giftPackaging = const [],
    this.giftMaxItems = 4,
    this.maxLineQuantity = 99,
    this.unpaidCancelHours = 6,
    this.contactTopics = const ['Product enquiry', 'Delivery & pickup', 'Existing order support', 'Bulk / event gifting'],
    this.bulkOccasions = const ['Wedding', 'Festival', 'Corporate gifting', 'Bhandara / community event', 'Other celebration'],
    this.exportTypes = const ['Wholesale / distribution', 'Indian grocery retail', 'Festival gifting', 'Private label enquiry'],
  });

  factory ShopConfig.fromJson(Map<String, dynamic> j) {
    final rp = j['razorpay'] is Map ? Map<String, dynamic>.from(j['razorpay'] as Map) : <String, dynamic>{};
    final eo = j['enquiry_options'] is Map ? Map<String, dynamic>.from(j['enquiry_options'] as Map) : <String, dynamic>{};
    List<String> strs(dynamic v, List<String> fallback) => v is List ? v.map((e) => '$e').toList() : fallback;
    const d = ShopConfig();
    return ShopConfig(
      shop: j['shop'] is Map ? Map<String, dynamic>.from(j['shop'] as Map) : const {},
      deliveryMethods: _list(j['delivery_methods']).map(DeliveryMethodOption.fromJson).toList(),
      deliverySlots: _list(j['delivery_slots']).map((e) => KeyLabel(_s(e['key']) ?? '', _s(e['label']) ?? '')).toList(),
      paymentMethods: _list(j['payment_methods']).map((e) => KeyLabel(_s(e['key']) ?? '', _s(e['label']) ?? '', online: e['online'] == true)).toList(),
      razorpayEnabled: rp['enabled'] == true,
      razorpayKeyId: _s(rp['key_id']),
      giftPackaging: _list(j['gift_packaging']).map((e) => GiftPackaging(_s(e['key']) ?? '', _s(e['label']) ?? '', _d(e['price']), _i(e['product_id']))).toList(),
      giftMaxItems: _i(j['gift_max_items']) ?? 4,
      maxLineQuantity: _i(j['max_line_quantity']) ?? 99,
      unpaidCancelHours: _i(j['unpaid_cancel_hours']) ?? 6,
      contactTopics: strs(eo['contact_topics'], d.contactTopics),
      bulkOccasions: strs(eo['bulk_occasions'], d.bulkOccasions),
      exportTypes: strs(eo['export_types'], d.exportTypes),
    );
  }

  /// Payment methods the customer can actually use right now (online ones only when Razorpay is set up).
  List<KeyLabel> get usablePayments => paymentMethods.where((p) => !p.online || razorpayEnabled).toList();

  String get shopAddress => (shop['address'] as String?) ?? 'Patel Nagar, Kashipur, Uttarakhand';
  String? get shopPhone => shop['phone'] as String?;
  String? get shopHours => shop['hours'] as String?;
  String? get mapsUrl => shop['maps_url'] as String?;
}

/// Server's view of the cart (POST /cart/quote).
class CartQuote {
  final double subtotal;
  final double tax;
  final double deliveryFee;
  final double total;
  final bool hasPerishable;
  final double freeThreshold;
  final double freeRemaining;
  final bool freeReached;
  final List<DeliveryMethodOption> deliveryMethods;
  final List<String> problems;
  final String? choiceError;
  final List<Map<String, dynamic>> lines;
  final List<Product> suggestions;

  const CartQuote({
    required this.subtotal,
    required this.tax,
    required this.deliveryFee,
    required this.total,
    required this.hasPerishable,
    required this.freeThreshold,
    required this.freeRemaining,
    required this.freeReached,
    required this.deliveryMethods,
    required this.problems,
    this.choiceError,
    required this.lines,
    required this.suggestions,
  });

  factory CartQuote.fromJson(Map<String, dynamic> j) {
    final fd = j['free_delivery'] is Map ? Map<String, dynamic>.from(j['free_delivery'] as Map) : <String, dynamic>{};
    return CartQuote(
      subtotal: _d(j['subtotal']),
      tax: _d(j['tax']),
      deliveryFee: _d(j['delivery_fee']),
      total: _d(j['total']),
      hasPerishable: j['has_perishable'] == true,
      freeThreshold: _d(fd['threshold']),
      freeRemaining: _d(fd['remaining']),
      freeReached: fd['reached'] == true,
      deliveryMethods: _list(j['delivery_methods']).map(DeliveryMethodOption.fromJson).toList(),
      problems: _list(j['problems']).map((p) => _s(p['message']) ?? '').where((m) => m.isNotEmpty).toList(),
      choiceError: _s(j['choice_error']),
      lines: _list(j['lines']),
      suggestions: _list(j['suggestions']).map(Product.fromJson).toList(),
    );
  }

  DeliveryMethodOption? method(String key) {
    for (final m in deliveryMethods) {
      if (m.key == key) return m;
    }
    return null;
  }
}

class StaffDashboard {
  final double todayRevenue;
  final int ordersToday;
  final int newOrders;
  final int pending;
  final int outNow;
  final int newEnquiries;
  final List<(int, String, int)> lowStock;
  final List<ShopOrder> latest;

  const StaffDashboard({
    required this.todayRevenue,
    required this.ordersToday,
    required this.newOrders,
    required this.pending,
    required this.outNow,
    required this.newEnquiries,
    required this.lowStock,
    required this.latest,
  });

  factory StaffDashboard.fromJson(Map<String, dynamic> j) => StaffDashboard(
        todayRevenue: _d(j['today_revenue']),
        ordersToday: _i(j['orders_today']) ?? 0,
        newOrders: _i(j['new_orders']) ?? 0,
        pending: _i(j['pending']) ?? 0,
        outNow: _i(j['out_now']) ?? 0,
        newEnquiries: _i(j['new_enquiries']) ?? 0,
        lowStock: _list(j['low_stock']).map((p) => (_i(p['id']) ?? 0, _s(p['name']) ?? '', _i(p['stock_qty']) ?? 0)).toList(),
        latest: _list(j['latest']).map(ShopOrder.fromJson).toList(),
      );
}

/// A product row on the staff stock screen.
class StaffProduct {
  final Product product;
  final bool isActive;
  final int? stockQty;
  const StaffProduct(this.product, this.isActive, this.stockQty);

  factory StaffProduct.fromJson(Map<String, dynamic> j) => StaffProduct(Product.fromJson(j), j['is_active'] != false, _i(j['raw_stock_qty']));
}

// ───────────────────────── Milk subscriptions (server: app/Http/Controllers/Api/MilkController.php) ─────────────────────────

class MilkConfig {
  final String productName;
  final double pricePerLitre;
  final int maxLitres;
  final List<KeyLabel> slots;
  final List<KeyLabel> frequencies;
  final int cutoffHour;
  final int firstPaymentDays;
  final double minTopup;
  final bool allowCash;
  final bool onlinePayments;

  const MilkConfig({
    this.productName = 'Full Cream Milk',
    this.pricePerLitre = 68,
    this.maxLitres = 10,
    this.slots = const [],
    this.frequencies = const [KeyLabel('daily', 'Every day'), KeyLabel('alternate', 'Alternate days'), KeyLabel('custom', 'Select days')],
    this.cutoffHour = 20,
    this.firstPaymentDays = 30,
    this.minTopup = 100,
    this.allowCash = true,
    this.onlinePayments = false,
  });

  factory MilkConfig.fromJson(Map<String, dynamic> j) => MilkConfig(
        productName: _s(j['product_name']) ?? 'Full Cream Milk',
        pricePerLitre: _d(j['price_per_litre']),
        maxLitres: _i(j['max_litres']) ?? 10,
        slots: _list(j['slots']).map((e) => KeyLabel(_s(e['key']) ?? '', _s(e['label']) ?? '')).toList(),
        frequencies: _list(j['frequencies']).map((e) => KeyLabel(_s(e['key']) ?? '', _s(e['label']) ?? '')).toList(),
        cutoffHour: _i(j['cutoff_hour']) ?? 20,
        firstPaymentDays: _i(j['first_payment_days']) ?? 30,
        minTopup: _d(j['min_topup']),
        allowCash: j['allow_cash'] != false,
        onlinePayments: j['online_payments'] == true,
      );

  String slotLabel(String? key) {
    for (final s in slots) {
      if (s.key == key) return s.label;
    }
    return key ?? '';
  }

  String frequencyLabel(String? key) {
    for (final f in frequencies) {
      if (f.key == key) return f.label;
    }
    return key ?? '';
  }

  String get cutoffText => '${cutoffHour % 12 == 0 ? 12 : cutoffHour % 12} ${cutoffHour < 12 ? 'AM' : 'PM'}';
}

class MilkDay {
  final DateTime date;
  final String state; // delivered | not_delivered | scheduled | skipped | none
  final bool inPattern;
  final bool canChange;
  final int? deliveryId;
  const MilkDay(this.date, this.state, this.inPattern, this.canChange, this.deliveryId);
}

class MilkDeliveryInfo {
  final int id;
  final DateTime date;
  final int litres;
  final double amount;
  final String status; // scheduled | delivered | exception
  final String statusLabel;
  final String? exceptionReason;
  final String? note;
  final DateTime? deliveredAt;
  final String? deliveredBy;
  final int bottlesBack;

  const MilkDeliveryInfo({
    required this.id,
    required this.date,
    required this.litres,
    required this.amount,
    required this.status,
    required this.statusLabel,
    this.exceptionReason,
    this.note,
    this.deliveredAt,
    this.deliveredBy,
    this.bottlesBack = 0,
  });

  factory MilkDeliveryInfo.fromJson(Map<String, dynamic> j) => MilkDeliveryInfo(
        id: _i(j['id']) ?? 0,
        date: DateTime.tryParse('${j['date']}') ?? DateTime.now(),
        litres: _i(j['litres']) ?? 0,
        amount: _d(j['amount']),
        status: _s(j['status']) ?? 'scheduled',
        statusLabel: _s(j['status_label']) ?? '',
        exceptionReason: _s(j['exception_reason']),
        note: _s(j['note']),
        deliveredAt: _date(j['delivered_at']),
        deliveredBy: _s(j['delivered_by']),
        bottlesBack: _i(j['bottles_back']) ?? 0,
      );
}

class MilkTransaction {
  final String type;
  final double amount;
  final double? balanceAfter;
  final String description;
  final DateTime? createdAt;
  const MilkTransaction(this.type, this.amount, this.balanceAfter, this.description, this.createdAt);
}

/// The customer's milk plan as stored on the server.
class MilkPlan {
  final int id;
  final String number;
  final String status; // pending_payment | active | paused | cancelled
  final String statusLabel;
  final String productName;
  final int litres;
  final double perDelivery;
  final String frequency;
  final String frequencyLabel;
  final List<int> weekdays;
  final DateTime startDate;
  final String slot;
  final String slotLabel;
  final String address;
  final String pincode;
  final bool reminders;
  final double balance;
  final bool lowBalance;
  final double firstPayment;
  final int deliveriesFirstPeriod;
  final DateTime? nextDelivery;
  final MilkDeliveryInfo? today;
  final List<MilkDay> calendar;
  final List<MilkDeliveryInfo> recentDeliveries;
  final List<MilkTransaction> transactions;

  const MilkPlan({
    required this.id,
    required this.number,
    required this.status,
    required this.statusLabel,
    required this.productName,
    required this.litres,
    required this.perDelivery,
    required this.frequency,
    required this.frequencyLabel,
    required this.weekdays,
    required this.startDate,
    required this.slot,
    required this.slotLabel,
    required this.address,
    required this.pincode,
    required this.reminders,
    required this.balance,
    required this.lowBalance,
    required this.firstPayment,
    required this.deliveriesFirstPeriod,
    this.nextDelivery,
    this.today,
    required this.calendar,
    required this.recentDeliveries,
    required this.transactions,
  });

  factory MilkPlan.fromJson(Map<String, dynamic> j) => MilkPlan(
        id: _i(j['id']) ?? 0,
        number: _s(j['number']) ?? '',
        status: _s(j['status']) ?? 'pending_payment',
        statusLabel: _s(j['status_label']) ?? '',
        productName: _s(j['product_name']) ?? 'Full Cream Milk',
        litres: _i(j['litres']) ?? 1,
        perDelivery: _d(j['per_delivery']),
        frequency: _s(j['frequency']) ?? 'daily',
        frequencyLabel: _s(j['frequency_label']) ?? '',
        weekdays: (j['weekdays'] as List? ?? const []).map((e) => _i(e) ?? 0).where((e) => e > 0).toList(),
        startDate: DateTime.tryParse('${j['start_date']}') ?? DateTime.now(),
        slot: _s(j['slot']) ?? '',
        slotLabel: _s(j['slot_label']) ?? '',
        address: _s(j['address']) ?? '',
        pincode: _s(j['pincode']) ?? '',
        reminders: j['reminders'] != false,
        balance: _d(j['balance']),
        lowBalance: j['low_balance'] == true,
        firstPayment: _d(j['first_payment']),
        deliveriesFirstPeriod: _i(j['deliveries_first_period']) ?? 0,
        nextDelivery: j['next_delivery'] == null ? null : DateTime.tryParse('${j['next_delivery']}'),
        today: j['today'] is Map ? MilkDeliveryInfo.fromJson(Map<String, dynamic>.from(j['today'] as Map)) : null,
        calendar: _list(j['calendar'])
            .map((c) => MilkDay(DateTime.tryParse('${c['date']}') ?? DateTime.now(), _s(c['state']) ?? 'none', c['in_pattern'] == true, c['can_change'] == true, _i(c['delivery_id'])))
            .toList(),
        recentDeliveries: _list(j['recent_deliveries']).map(MilkDeliveryInfo.fromJson).toList(),
        transactions: _list(j['transactions'])
            .map((t) => MilkTransaction(_s(t['type']) ?? '', _d(t['amount']), t['balance_after'] == null ? null : _d(t['balance_after']), _s(t['description']) ?? '', _date(t['created_at'])))
            .toList(),
      );

  bool get isActive => status == 'active';
  bool get awaitingPayment => status == 'pending_payment';

  MilkDay? dayFor(DateTime d) {
    for (final c in calendar) {
      if (c.date.year == d.year && c.date.month == d.month && c.date.day == d.day) return c;
    }
    return null;
  }
}

// ───────────────────────── Staff milk round (server: Api/Staff/StaffMilkController.php) ─────────────────────────

class MilkStop {
  final int id;
  final int position;
  final String status; // scheduled | delivered | exception
  final String statusLabel;
  final int litres;
  final double amount;
  final int bottlesOut;
  final int bottlesBack;
  final String? exceptionReason;
  final String? note;
  final DateTime? deliveredAt;
  final String subscriptionNumber;
  final String customerName;
  final String phone;
  final String address;
  final String pincode;
  final String slotLabel;
  final String? customerNote;
  final double balance;
  final bool lowBalance;

  const MilkStop({
    required this.id,
    required this.position,
    required this.status,
    required this.statusLabel,
    required this.litres,
    required this.amount,
    required this.bottlesOut,
    required this.bottlesBack,
    this.exceptionReason,
    this.note,
    this.deliveredAt,
    required this.subscriptionNumber,
    required this.customerName,
    required this.phone,
    required this.address,
    required this.pincode,
    required this.slotLabel,
    this.customerNote,
    required this.balance,
    required this.lowBalance,
  });

  factory MilkStop.fromJson(Map<String, dynamic> j) => MilkStop(
        id: _i(j['id']) ?? 0,
        position: _i(j['position']) ?? 0,
        status: _s(j['status']) ?? 'scheduled',
        statusLabel: _s(j['status_label']) ?? '',
        litres: _i(j['litres']) ?? 0,
        amount: _d(j['amount']),
        bottlesOut: _i(j['bottles_out']) ?? 0,
        bottlesBack: _i(j['bottles_back']) ?? 0,
        exceptionReason: _s(j['exception_reason']),
        note: _s(j['note']),
        deliveredAt: _date(j['delivered_at']),
        subscriptionNumber: _s(j['subscription_number']) ?? '',
        customerName: _s(j['customer_name']) ?? '',
        phone: _s(j['phone']) ?? '',
        address: _s(j['address']) ?? '',
        pincode: _s(j['pincode']) ?? '',
        slotLabel: _s(j['slot_label']) ?? '',
        customerNote: _s(j['customer_note']),
        balance: _d(j['balance']),
        lowBalance: j['low_balance'] == true,
      );

  bool get isPending => status == 'scheduled';
  bool get isDelivered => status == 'delivered';
  bool get isException => status == 'exception';
}

class StaffRouteInfo {
  final int id; // 0 = customers not on a route yet
  final String name;
  final String? area;
  final String? staffName;
  const StaffRouteInfo(this.id, this.name, this.area, this.staffName);

  factory StaffRouteInfo.fromJson(Map<String, dynamic> j) => StaffRouteInfo(_i(j['id']) ?? 0, _s(j['name']) ?? '', _s(j['area']), _s(j['staff_name']));
}

class StaffMilkDay {
  final DateTime date;
  final StaffRouteInfo route;
  final List<StaffRouteInfo> routes;
  final DateTime? shiftStarted;
  final DateTime? shiftEnded;
  final int litresLoaded;
  final int bottlesLoaded;
  final int bottlesReturned;
  final List<MilkStop> stops;
  final Map<String, dynamic> summary;
  final List<KeyLabel> exceptionReasons;

  const StaffMilkDay({
    required this.date,
    required this.route,
    required this.routes,
    this.shiftStarted,
    this.shiftEnded,
    this.litresLoaded = 0,
    this.bottlesLoaded = 0,
    this.bottlesReturned = 0,
    required this.stops,
    required this.summary,
    required this.exceptionReasons,
  });

  factory StaffMilkDay.fromJson(Map<String, dynamic> j) {
    final shift = j['shift'] is Map ? Map<String, dynamic>.from(j['shift'] as Map) : const <String, dynamic>{};
    return StaffMilkDay(
      date: DateTime.tryParse('${j['date']}') ?? DateTime.now(),
      route: StaffRouteInfo.fromJson(Map<String, dynamic>.from(j['route'] as Map)),
      routes: _list(j['routes']).map(StaffRouteInfo.fromJson).toList(),
      shiftStarted: _date(shift['started_at']),
      shiftEnded: _date(shift['ended_at']),
      litresLoaded: _i(shift['litres_loaded']) ?? 0,
      bottlesLoaded: _i(shift['bottles_loaded']) ?? 0,
      bottlesReturned: _i(shift['bottles_returned']) ?? 0,
      stops: _list(j['stops']).map(MilkStop.fromJson).toList(),
      summary: j['summary'] is Map ? Map<String, dynamic>.from(j['summary'] as Map) : const {},
      exceptionReasons: _list(j['exception_reasons']).map((e) => KeyLabel(_s(e['key']) ?? '', _s(e['label']) ?? '')).toList(),
    );
  }

  int sum(String key) => _i(summary[key]) ?? 0;
  double amountOf(String key) => _d(summary[key]);
  List<MilkStop> get pending => stops.where((s) => s.isPending).toList();
  MilkStop? get next => pending.isEmpty ? null : pending.first;

  MilkStop? stopById(int? id) {
    for (final s in stops) {
      if (s.id == id) return s;
    }
    return null;
  }

  List<(String, int)> get exceptionCounts =>
      _list(summary['exception_reasons']).map((e) => (_s(e['reason']) ?? '', _i(e['count']) ?? 0)).toList();
}
