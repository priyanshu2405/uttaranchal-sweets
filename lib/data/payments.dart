import 'dart:async';

import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../state/app_state.dart';
import 'api.dart';
import 'models.dart';

class PaymentResult {
  final bool paid;
  final bool cancelled;
  final String message;
  final ShopOrder? order;
  const PaymentResult({required this.paid, this.cancelled = false, required this.message, this.order});
}

/// Opens Razorpay's native checkout for an order that was already placed (UPI / card),
/// then has the server verify the signature before marking it paid.
/// If the app is closed mid-payment, the website's Razorpay webhook still marks the order paid.
Future<PaymentResult> payOnline(AppState app, ShopOrder order) async {
  final Map<String, dynamic> start;
  try {
    start = await app.startPayment(order.number);
  } on ApiException catch (e) {
    return PaymentResult(paid: false, message: e.message);
  }

  final razorpay = Razorpay();
  final done = Completer<PaymentResult>();
  void finish(PaymentResult r) {
    if (!done.isCompleted) done.complete(r);
  }

  razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse r) async {
    try {
      final o = await app.verifyPayment(order.number, paymentId: r.paymentId ?? '', razorpayOrderId: r.orderId ?? '', signature: r.signature ?? '');
      finish(PaymentResult(paid: o.isPaid, message: 'Payment received — thank you!', order: o));
    } on ApiException catch (e) {
      finish(PaymentResult(paid: false, message: e.message));
    }
  });
  razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse r) {
    final cancelled = r.code == Razorpay.PAYMENT_CANCELLED;
    finish(PaymentResult(
      paid: false,
      cancelled: cancelled,
      message: cancelled ? 'Payment cancelled. Your order is saved — you can pay from the order screen.' : (r.message?.isNotEmpty == true ? r.message! : 'The payment didn’t go through. Please try again.'),
    ));
  });
  razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse r) {
    finish(PaymentResult(paid: false, message: 'Finish paying in ${r.walletName ?? 'your wallet'}. We’ll update your order once the payment is confirmed.'));
  });

  final prefill = Map<String, dynamic>.from((start['prefill'] as Map?) ?? const {});
  if (start['method'] == 'upi' || start['method'] == 'card') prefill['method'] = start['method'];

  try {
    razorpay.open({
      'key': start['key_id'],
      'amount': start['amount'],
      'currency': start['currency'] ?? 'INR',
      'name': 'Uttaranchal Dairy & Sweets',
      'description': start['description'] ?? 'Order ${order.number}',
      'order_id': start['razorpay_order_id'],
      'prefill': prefill,
      'theme': {'color': '#A81656'},
      'retry': {'enabled': true, 'max_count': 2},
    });
    return await done.future;
  } catch (e) {
    return const PaymentResult(paid: false, message: 'Couldn’t open the payment screen. Your order is saved — please try again from the order screen.');
  } finally {
    razorpay.clear();
  }
}
