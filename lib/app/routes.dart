/// Named routes, numbered to match the design hand-off (01–42).
class R {
  R._();

  // Onboarding
  static const welcome = '/'; // 01
  static const signIn = '/sign-in'; // 02
  static const verify = '/verify'; // 03
  static const location = '/location'; // 04

  // Shop
  static const home = '/home'; // 05
  static const collection = '/collection'; // 06
  static const product = '/product'; // 07
  static const search = '/search'; // 08
  static const gifting = '/gifting'; // 09
  static const giftBox = '/gift-box'; // 10
  static const bulkEnquiry = '/bulk-enquiry'; // 11

  // Checkout
  static const bag = '/bag'; // 12
  static const redeem = '/redeem'; // 13
  static const checkoutAddress = '/checkout-address'; // 14
  static const payment = '/payment'; // 15
  static const orderConfirmation = '/order-confirmation'; // 16

  // Orders
  static const orderHistory = '/orders'; // 17
  static const tracking = '/tracking'; // 18
  static const receipt = '/receipt'; // 19

  // Milk
  static const milkHub = '/milk'; // 20
  static const milkProduct = '/milk/product'; // 21
  static const milkConfigure = '/milk/configure'; // 22
  static const milkReview = '/milk/review'; // 23
  static const milkActive = '/milk/active'; // 24
  static const milkCalendar = '/milk/calendar'; // 25
  static const milkPause = '/milk/pause'; // 26
  static const milkProof = '/milk/proof'; // 27
  static const milkTopUp = '/milk/top-up'; // 28

  // Rewards
  static const rewards = '/rewards'; // 29
  static const pointsActivity = '/rewards/activity'; // 30

  // Account
  static const account = '/account'; // 31
  static const story = '/story'; // 32
  static const notifications = '/notifications'; // 33
  static const help = '/help'; // 34

  // Staff app
  static const staffSignIn = '/staff'; // 35
  static const staffDashboard = '/staff/dashboard'; // 36
  static const staffRoute = '/staff/route'; // 37
  static const staffStop = '/staff/stop'; // 38
  static const staffConfirm = '/staff/confirm'; // 39
  static const staffException = '/staff/exception'; // 40
  static const staffStock = '/staff/stock'; // 41
  static const staffSummary = '/staff/summary'; // 42

  // Presenter tools
  static const screenIndex = '/demo/screens';

  static const customerTabs = [home, collection, milkHub, rewards, account];
  static const staffTabs = [staffDashboard, staffRoute, staffStock, staffSummary];
}
