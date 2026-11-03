import 'dart:convert';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uttaranchal_app/data/api.dart';
import 'package:uttaranchal_app/data/models.dart';
import 'package:uttaranchal_app/main.dart';
import 'package:uttaranchal_app/state/app_state.dart';

/// A fake server so tests never touch the real shop.
ApiClient fakeApi() => ApiClient(
      baseUrl: 'https://test.local/api/v1',
      client: MockClient((req) async {
        final path = req.url.path.replaceFirst('/api/v1', '');
        final body = switch (path) {
          '/config' => {
              'shop': {'address': 'Patel Nagar, Kashipur'},
              'delivery_methods': [
                {'key': 'pickup', 'label': 'Store pickup · Patel Nagar', 'fee': 0, 'free_over': null},
                {'key': 'local', 'label': 'Local delivery · Kashipur', 'fee': 40, 'free_over': 500},
              ],
              'delivery_slots': [
                {'key': 'morning', 'label': 'Morning (9 am – 1 pm)'}
              ],
              'payment_methods': [
                {'key': 'cod', 'label': 'Cash on delivery', 'online': false}
              ],
              'razorpay': {'enabled': false},
            },
          '/home' => {
              'categories': [
                {'id': 1, 'slug': 'sweets', 'name': 'Traditional sweet'}
              ],
              'featured': [
                {'id': 2, 'slug': 'kaju', 'name': 'Kaju Katli', 'price': 550, 'price_label': '₹550', 'unit': '500 g', 'options': []}
              ],
            },
          _ => {'message': 'Not found.'},
        };
        return http.Response(jsonEncode(body), path.startsWith('/config') || path.startsWith('/home') ? 200 : 404,
            headers: {'content-type': 'application/json; charset=utf-8'});
      }),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Welcome screen loads the shop and starts sign-in', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(UttaranchalApp(state: AppState(api: fakeApi())));
    await tester.pumpAndSettle();
    expect(find.text('Let’s begin'), findsOneWidget);

    await tester.tap(find.text('Let’s begin'));
    await tester.pumpAndSettle();
    expect(find.text('Namaste.'), findsOneWidget);
  });

  test('Bag respects tracked stock', () {
    final app = AppState(api: fakeApi());
    const p = Product(id: 1, slug: 'x', name: 'Laddoo', price: 240, priceLabel: '₹240', unit: '500 g', stockQty: 2);
    expect(app.addProduct(p, qty: 2), isNull);
    expect(app.addProduct(p), contains('Only 2'));
    expect(app.cartCount, 2);
    expect(app.itemsTotal, 480);
  });
}
