# Uttaranchal Flutter app — connected to the website

This folder holds only the files that changed. Copy it over your `uttaranchal_app` project
(keeping the folder structure), then:

```bash
cd uttaranchal_app
flutter clean
flutter pub get
flutter analyze            # should report no errors
cd ios && pod install && cd ..   # macOS only, first time after adding Razorpay
flutter run
```

Your project also contains an empty folder literally named `lib/{app,data,state,widgets,screens` —
a leftover from a shell command. It's harmless; you can delete it.

## Which server it talks to

`lib/config.dart` — default `https://uttaranchal.vads.ca/api/v1`. Install the Laravel add-on first
(see the other zip). For testing against a copy:
`flutter run --dart-define=API_BASE=https://staging.example.com/api/v1`
Android emulator → your computer's `php artisan serve`: `--dart-define=API_BASE=http://10.0.2.2:8000/api/v1`
(plain http needs `android:usesCleartextTraffic="true"` on Android — for local testing only).

## What's live now

Customer app
- Sign in / create account with mobile + password — the same accounts as the website. Guests can still shop.
- Home, collection, search and product pages show your real products, sizes, prices, stock and photos
  (photos come from the website; the bundled pictures are used as fall-backs).
- Bag is checked against live prices/stock; delivery methods, fees, free-delivery progress and
  "fresh items can't go by courier" come from the server, exactly as on the website.
- Checkout places a real order. UPI/card open Razorpay's native checkout; the server verifies payment.
  Cash on delivery / pay at pickup works too. Unpaid online orders can be paid later from the order screen.
- Orders list (website + app orders on the account), live tracking (refreshes every 30 s), cancel
  (when the website allows it), receipt, reorder, and "track an order" by number + phone.
- Favourites shared with the website wishlist; gift box (add to bag or ask for a custom quote);
  bulk & export enquiries; help messages; FAQ & policies; profile edit, change password, delete account.

Staff app (Welcome → "Shop staff? Staff sign in", same email/password as /admin)
- Shop orders: today's sales, new orders, search, tabs by status, one-tap "Start preparing → Out for
  delivery / Ready for pickup → Delivered" (customer is emailed), buzz on new orders, auto-refresh.
- Order detail: mark paid, cancel (stock is returned).
- Stock: +/- or set stock per product and per size.

Marked "coming soon" (no backend yet — screens kept, showing sample data or a note)
- Milk subscriptions (customer) and the milk delivery route (staff "Milk route" tab).
- Loyalty points / rewards (hidden from checkout so totals always match what's charged).
- OTP sign-in (needs an SMS provider; password sign-in is used instead).

## Before publishing

- Android release signing still uses debug keys (`android/app/build.gradle.kts`) — set up your upload key.
- Change `applicationId` / bundle id if you want something other than `com.uttaranchal.dairy.uttaranchal_app`.
- Use Razorpay **live** keys in the server `.env` (the app reads the key from the server).
- App Store / Play listing: account deletion is in You → Delete my account.
