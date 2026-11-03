import 'package:flutter/material.dart';

import '../screens/account/account_screens.dart';
import '../screens/checkout/checkout_screens.dart';
import '../screens/demo/screen_index.dart';
import '../screens/milk/milk_screens.dart';
import '../screens/onboarding/onboarding_screens.dart';
import '../screens/orders/order_screens.dart';
import '../screens/shop/shop_screens.dart';
import '../screens/staff/shop_staff_screens.dart';
import '../screens/staff/staff_screens.dart';
import 'nav.dart';
import 'routes.dart';

class AppRouter {
  AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final args = settings.arguments;
    final str = args is String ? args : null;
    final intArg = args is int ? args : null;

    final Widget page = switch (settings.name) {
      R.welcome => const WelcomeScreen(),
      R.signIn => const SignInScreen(),
      R.verify => const VerifyScreen(),
      R.location => const LocationScreen(),
      R.home => const HomeScreen(),
      R.collection => const CollectionScreen(),
      R.product => ProductScreen(product: args is TabSwitch ? null : args),
      R.search => const SearchScreen(),
      R.gifting => const GiftingScreen(),
      R.giftBox => const GiftBoxScreen(),
      R.bulkEnquiry => BulkEnquiryScreen(initialType: str),
      R.bag => const BagScreen(),
      R.redeem => const RedeemScreen(),
      R.checkoutAddress => const CheckoutAddressScreen(),
      R.payment => const PaymentScreen(),
      R.orderConfirmation => const OrderConfirmationScreen(),
      R.orderHistory => const OrderHistoryScreen(),
      R.tracking => TrackingScreen(number: str),
      R.receipt => ReceiptScreen(number: str),
      R.milkHub => const MilkHubScreen(),
      R.milkProduct => const MilkProductScreen(),
      R.milkConfigure => const MilkConfigureScreen(),
      R.milkReview => const MilkReviewScreen(),
      R.milkActive => const MilkActiveScreen(),
      R.milkCalendar => const MilkCalendarScreen(),
      R.milkPause => const MilkPauseScreen(),
      R.milkProof => const MilkProofScreen(),
      R.milkTopUp => const MilkTopUpScreen(),
      R.rewards => const RewardsScreen(),
      R.pointsActivity => const PointsActivityScreen(),
      R.account => const AccountScreen(),
      R.story => const StoryScreen(),
      R.notifications => const NotificationsScreen(),
      R.help => HelpScreen(reference: str),
      R.favourites => const FavouritesScreen(),
      R.info => InfoPageScreen(page: str ?? 'faq'),
      R.staffSignIn => const StaffSignInScreen(),
      R.staffDashboard => const StaffDashboardScreen(),
      R.staffRoute => const StaffRouteScreen(),
      R.staffStop => StaffStopScreen(stopNumber: intArg),
      R.staffConfirm => StaffConfirmScreen(stopNumber: intArg),
      R.staffException => StaffExceptionScreen(stopNumber: intArg),
      R.staffStock => const StaffStockScreen(),
      R.staffSummary => const StaffSummaryScreen(),
      R.staffOrders => const StaffOrdersScreen(),
      R.staffOrder => StaffOrderScreen(orderId: intArg),
      R.staffProducts => const StaffProductsScreen(),
      R.screenIndex => const ScreenIndexScreen(),
      _ => const WelcomeScreen(),
    };

    // Bottom-nav tab switches cross-fade; everything else uses the native
    // platform transition (Cupertino swipe-back on iOS, zoom on Android).
    if (args is TabSwitch) {
      return PageRouteBuilder<dynamic>(
        settings: settings,
        transitionDuration: const Duration(milliseconds: 220),
        reverseTransitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut), child: child),
      );
    }
    return MaterialPageRoute<dynamic>(settings: settings, builder: (_) => page);
  }
}
