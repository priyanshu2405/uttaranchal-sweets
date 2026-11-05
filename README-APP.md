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

## Update 2 (changes in this version)

- Language switch removed everywhere (welcome screen and Help).
- Staff entry removed from the customer "You" screen. The welcome screen link now reads "Staff sign in".
  The hidden screen index (long-press the logo) now only works in debug builds.
- "Use my current location" on the address screen (first-time setup, You → Delivery address, and checkout).
  New plugins: geolocator, geocoding. New permissions: location (Android manifest, iOS Info.plist).
- Gifting → Weddings / Corporate now show the website's bulk-order enquiry form, with the occasion filled in.
  It sends to the same Admin → Enquiries list as the website.
- Android back button: from any tab it now goes to Home; on Home, press back twice to exit.
- Tapping + on a product card opens a sheet to pick size (if several) and quantity. Cards show "N in your bag".
- Order tracking: the map is removed.
- Milk plan: nothing is pre-selected. Alternate days shows a calendar to pick the first delivery (every other day
  is highlighted). Select days has Mon–Sun buttons plus a calendar to add/remove single dates. Review shows the
  first-month amount, then "Continue to payment" opens a payment screen; paying activates the plan.
  Milk subscriptions still have no backend, so this payment is a preview (clearly labelled) — no money is taken.

After copying these files: `flutter clean && flutter pub get`, then `cd ios && pod install` on a Mac
(new location plugins), then `flutter analyze` and `flutter run`.

## Update 3 — milk subscriptions & delivery staff (live)

Install the backend zip `upload-backend-milk-staff.zip` on the server first.

Customer app (Milk tab) — now real:
- Build a plan (nothing pre-selected; calendars for alternate / select days), pay the first month by UPI/card
  (Razorpay) or choose cash to the delivery person.
- Live calendar: tap a day to skip it or add milk (closes at 8 PM the evening before). Holiday pause, change plan, cancel.
- Milk balance with full statement and online top-up. Delivery details: time, who delivered, or why not.
- Milk needs an account; guests are asked to sign in.

Staff app:
- Delivery staff (role set in Admin → Staff) sign in and land on their milk round: start round, stops in order,
  call / directions, Delivered (empty bottles) or Not delivered (reason), record cash, undo, finish with a summary.
  Bottom bar: Round · Stops · Summary. They can't open shop orders or stock.
- Admins: Orders · Stock · Milk round (any route, including customers not yet on a route).
- Everything shows live in the website admin under Milk & Delivery.

No new plugins in this update. After copying: `flutter pub get`, `flutter analyze`, `flutter run`.

## Update 4 — damage reports & invoices
- Staff: "Report damage" (round summary, milk & bottles, or at a stop): up to 6 camera-only photos, location and time
  are captured automatically; the shop approves in Admin → Damage Reports. Summary shows status and a stock check.
  End of round also asks for unsold milk brought back.
- Customers: "Download invoice (PDF)" on the receipt and order tracking screens.
- New plugin: image_picker (camera). iOS camera permission text added to Info.plist.
