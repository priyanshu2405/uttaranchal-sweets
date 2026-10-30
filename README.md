# Uttaranchal Dairy & Sweets — Flutter demo prototype

A clickable, single-codebase prototype for **Android and iOS**. It covers all **42 designed screens**: the customer app (01–34) and the milk-delivery staff app (35–42).

Everything runs offline on sample data, so no backend, payment gateway or API keys are needed. Bag totals, points redemption, milk balance, pauses and route progress all respond to taps, so the demo feels real.

---

## 1. One-time setup (≈10 minutes)

**You need:**
- **Flutter 3.24 or newer.** Check with `flutter --version`; install from https://docs.flutter.dev/get-started/install.
- **For Android:** Android Studio with the Android SDK, and a phone with USB debugging on or an emulator.
- **For iOS:** a Mac with Xcode 15+, and an iPhone or the iOS Simulator.

Then, from this folder:

```bash
# macOS / Linux
chmod +x setup.sh && ./setup.sh

# Windows (Android only)
setup.bat
```

The script does four things:
1. Generates the native `android/` and `ios/` projects. Your Dart code is left untouched.
2. Fetches packages.
3. Sets the app name to **Uttaranchal**.
4. Creates the brand launcher icon and the yellow splash screen.

Finally, run `flutter doctor` and fix anything marked ✗.

## 2. Run it

```bash
flutter devices          # list connected phones / simulators
flutter run --release    # smooth, demo-quality build
```

Always demo a `--release` build. Debug builds are noticeably slower and show a debug banner on errors.

## 3. Give it to the client

**Android: a shareable APK**

```bash
flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk
```

Send the APK over WhatsApp, email or Drive. The client needs to allow "Install unknown apps" when prompted. It is signed with the debug key, which is fine for a demo but not for the Play Store.

**iOS: on a Mac**
- **Your own iPhone:** connect it, open `ios/Runner.xcworkspace` in Xcode, choose your Team under *Signing & Capabilities*, then `flutter run --release`.
- **Client's iPhone, via TestFlight** (needs a paid Apple Developer account):
  1. Run `flutter build ipa`.
  2. Upload `build/ios/ipa/*.ipa` with the Transporter app.
  3. Invite the client in App Store Connect → TestFlight.

## 4. Presenter tools

- **Screen index:** long-press the उ logo on the Welcome screen, or go to **You → Screen index**. It lists all 42 screens and opens any of them in one tap.
- **Staff app:**
  - Open it with "Delivery partner? Staff sign in" on Welcome, or **You → Switch to delivery staff app**.
  - Leave it with the logout icon on the staff dashboard.
- **Sample codes:** OTP `2468`, mobile `98765 43210`. Both are prefilled.
- **Reset:** restart the app to restore all sample data.

## 5. Suggested 5-minute demo flow

1. **Welcome → Sign in → Verify → Location → Home.**
2. **Home:**
   - Switch the Mithai, Snacks and Gifts chips.
   - Tap **+** on a card and watch the bag badge update.
3. **Product:** open Kaju Katli and change 250 g, 500 g or 1 kg. The price animates. Then tap **Add to bag**.
4. **Bag:**
   - Change quantities, or swipe a line away and tap Undo.
   - Then go **Use points → 1,000 points → address → slot → payment → Preview order**.
5. **Order confirmation → Track my order** (the map animates) **→ Receipt**.
6. **Milk tab:**
   - Go **Start a milk plan → 3 L → Alternate days → Review → Activate**.
   - Open the **calendar** and tap days.
   - **Pause** the 15th–18th and see the calendar update.
   - **Top up ₹2,000** and watch the balance count up.
7. **Rewards:** see the points wallet and activity.
8. **Staff app:** go **Dashboard → Route → Stop 13 → Record delivery → Confirm**. Progress advances to stop 14. Then check **Stock** and the shift **Summary**.

## 6. Project structure

```
lib/
  main.dart               app entry, theme, text-scale clamp
  app/                    theme tokens, route names, router, navigation helpers
  data/catalog.dart       sample products, milk pricing, staff route  ← swap for API later
  state/app_state.dart    single ChangeNotifier (bag, points, milk plan, route)
  widgets/                design-system components (buttons, chips, cards, fields,
                          scaffold + bottom navs, map & milk-bottle illustrations)
  screens/
    onboarding/  01–04    shop/      05–11    checkout/  12–16
    orders/      17–19    milk/      20–28    account/   29–34 (rewards, account, help)
    staff/       35–42    demo/      screen index
assets/
  fonts/   Cormorant Garamond, DM Sans, Noto Serif Devanagari (OFL)
  images/  product & story photography taken from the design files
  icon/    launcher icon + splash logo
```

**Design decisions:**
- **No third-party runtime packages.** It builds first time, with no plugin or CocoaPods issues.
- **Simple state management.** One `AppState` (a ChangeNotifier) is shared through an `InheritedNotifier`. For production, swap in Riverpod or Bloc and repositories without touching screen layouts.
- **Native platform behaviour.** iOS gets the swipe-back gesture and Cupertino switches; Android gets Material transitions.
- **Layouts for real phones.** They adapt to 360–430 pt widths. Text scaling is clamped to 0.9–1.15× so large accessibility fonts can't break the demo.

## 7. Quality checks

```bash
flutter analyze
flutter test        # boots the app and builds every one of the 42 screens
```

## 8. Not in the prototype (planned for production)

- Real sign-in and OTP
- Backend and API
- Payment gateway (UPI)
- Maps and live GPS
- Push notifications
- Full Hindi localisation (the language toggle is wired; the copy is English)
- Analytics and crash reporting
- Play Store and App Store signing
