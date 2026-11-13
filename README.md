# ShopSphere

A **modern online shopping app** built with Flutter for the *Mobile Application Development
with Flutter* course. Products come from the public **DummyJSON** REST API; prices are shown in
**Bangladeshi Taka (৳)**. It has login / sign up, cart, checkout, simulated **bKash / Nagad / Rocket /
card / bank** payment, order tracking, full CRUD, a Hive offline cache, pagination and dark mode.

> Payments are a **simulation** (demo gateway pages). No real money or real bKash/bank API is used.

## API used

**DummyJSON Products** — https://dummyjson.com/products
- `GET /products?limit=20&skip=N` (server-side pagination)
- `POST /products/add`, `PUT /products/{id}`, `DELETE /products/{id}` (simulated by the server)

Product prices from the API are in USD. They are converted to ৳ with a fixed rate (`kUsdToBdt = 120`) **and a local-market factor per category** (`core/money.dart`), so groceries look like Bangladeshi prices (e.g. chicken ≈ ৳168/kg) instead of a plain USD conversion.

Because DummyJSON only *simulates* writes, the app calls these endpoints and also saves
every create / edit / delete locally in Hive, so the changes persist across restarts.

## Features

**Shopping app (new)**
- **Email verification:** on sign-up a 6-digit code is emailed to the user (EmailJS); the account works only after the code is entered (10 min expiry, 5 tries, resend after 30 s). A login alert email is sent on every login
- Login / Sign up (local accounts in Hive, passwords stored as SHA-256 hashes), session is remembered,
  one-tap demo account (`demo@shopsphere.com` / `demo1234`), logout
- Modern home: indigo gradient search header, auto-sliding promo banners, category icons,
  **Flash Sale** with countdown, "Just For You" product grid
- Product page: image gallery, ৳ price with old price and discount badge, quantity, delivery info,
  specifications, **Add to Cart** and **Buy Now**
- **Cart**: quantity +/-, swipe to remove, voucher codes (`WELCOME10` = 10% off up to ৳500, `FREESHIP`),
  delivery fee (৳60 inside Dhaka, ৳120 outside, free over ৳3,000), saved per user
- **Checkout**: delivery address, district, order summary, payment method selection
- **Simulated payment gateway**: bKash, Nagad, Rocket (number -> verification code -> PIN),
  Card (Luhn-checked number, expiry, CVV, 3-D Secure code), Internet Banking (bank -> login -> OTP),
  Cash on Delivery. Demo OTP is `123456`, demo card `4242 4242 4242 4242`
- Order confirmation page, **My Orders** list, order tracking (Placed -> Packed -> Shipped -> Delivered,
  advances every minute for the demo) and cancel order
- Account page: profile edit, wishlist, orders, "Sell a product", dark mode, logout
- Bottom navigation on phones, side navigation rail on tablets

**UI polish (v1.1)**
- Indigo gradient header with soft-shadow search bar, trust strip (fast delivery / COD / easy return)
- Banner cards with decorative shapes, categories card with section headers
- Product cards: discount ribbon, low-stock hint, one-tap *add to cart*, rounded bordered cards
- Filter chips for sort / wishlist / view mode + removable category chip
- Detail page: brand label, discount badge, thumbnail strip linked to the image slider
- Illustrated error and empty states, offline banner with Retry, floating *Sell* button for CRUD add
- Redesigned splash screen

**Assignment features**

- Splash screen with animated logo, auto navigation to Home
- Home list: image, title, brand/category subtitle, short description, price, rating
- **Grid / list view toggle** (choice is saved)
- **Shimmer skeleton loading** (custom widget, no package) for the list and for images
- **Hero animation** from the list image to the detail gallery
- **Swipe to delete with Undo** (list view); delete from the detail screen also has Undo
- Search (debounced 400 ms) across title, brand, category and description
- Category filter chips, sorting (price, rating, name), favorites-only filter
- Detail screen: image gallery, price + discount, stock, rating and extra fields
- CRUD: add, edit and delete products (real API call + local persistence)
- Offline cache: previously fetched pages are shown without internet
- Pagination: infinite scroll plus a "Load more" button
- Pull to refresh
- Error handling: no internet, server failure, empty state, loading state, retry
- Responsive layout (list: 1 column on phones, 2-3 on tablets; grid adapts to width)
- Dark mode (saved), favorites (saved)

## Email setup (real verification emails)

The app sends real emails through [EmailJS](https://www.emailjs.com) (free plan: 200 emails/month,
no own server needed). Until you fill in the keys the app runs in **demo mode** and shows the code on the
verify screen instead of emailing it.

1. Create a free EmailJS account.
2. **Email Services** -> *Add New Service* (e.g. Gmail) -> connect your mailbox -> copy the **Service ID**.
3. **Email Templates** -> *Create New Template*:
   - To Email: `{{to_email}}`
   - Subject: `{{subject}}`
   - Content: `{{message}}`
   
   Save and copy the **Template ID**.
4. **Account -> General** -> copy the **Public Key**.
5. **Account -> Security** -> turn on *Allow EmailJS API for non-browser applications* (required for mobile apps).
6. Paste the three values into `lib/core/email_config.dart`
   (`serviceId`, `templateId`, `publicKey`). Set `sendLoginAlert = false` if you do not want login emails.

Flow: **Sign up -> code emailed (first time) -> enter code -> logged in**. Logging in with an account whose
email was never verified sends a new code. Emails may land in the spam folder the first time.

## Rubric & bonus checklist

| Rubric item | Where it is implemented |
|---|---|
| UI Design (15) | `core/theme.dart`, `presentation/widgets/*`, light + dark theme, tablet layout |
| API Integration (20) | `data/datasource/remote_datasource.dart` (Dio, DummyJSON, JSON -> `ProductModel`) |
| CRUD (20) | `product_form_screen.dart`, `ProductRepositoryImpl` (API call + Hive persistence, undo delete) |
| Local Cache (15) | `data/datasource/local_datasource.dart` (Hive) - app opens offline with last fetched data |
| Pagination (10) | `ProductProvider.loadMore()` - infinite scroll + Load more button |
| State Management (10) | `provider` (`ChangeNotifier` providers in `providers/`) |
| Code Quality (5) | Clean Architecture, `analysis_options.yaml`, unit tests in `test/` |
| Documentation (5) | this README |

| Bonus | Status |
|---|---|
| Dark mode | Done (saved) |
| Favorite items | Done (wishlist, saved) |
| Offline mode | Done (cached pages + offline banner) |
| Infinite scrolling | Done |
| Pull to refresh | Done |
| Sorting | Done (price, rating, name) |
| Filtering | Done (category chips, wishlist only) |
| Debounced search | Done (400 ms) |
| Clean Architecture | Done (domain / data / presentation) |
| Repository pattern | Done |
| Dependency injection | Done (`get_it`) |

## Architecture (Clean Architecture)

```
lib/
├── core/            constants, theme, money (৳ format), validators, di.dart (get_it)
├── domain/          pure Dart, no Flutter / Dio / Hive
│   ├── entities/    Product, PagedProducts, LocalChanges, AppUser, CartItem, Order, PaymentMethod
│   ├── repositories/ abstract ProductRepository, SettingsRepository
│   ├── usecases/    GetProductsPage, AddProduct, DeleteProduct, RestoreProduct, ...
│   └── failures.dart NetworkFailure, ServerFailure, UnknownFailure
├── data/
│   ├── models/      ProductModel, shop_models (JSON for user / cart / order)
│   ├── datasource/  RemoteDataSource (Dio), LocalDataSource + ShopLocalDataSource (Hive)
│   └── repositories/ ProductRepositoryImpl, SettingsRepositoryImpl
├── presentation/
│   ├── screens/     splash, auth/, main shell, home, detail, cart, checkout, payment gateway,
│   │                orders, order detail, account, profile, wishlist, add/edit product form
│   └── widgets/     product cards, price tag, home sections, shimmer skeletons, image, state views
├── providers/       ProductProvider, SettingsProvider, AuthProvider, CartProvider, OrderProvider
├── services/        PaymentService (simulated gateway + validators)
└── main.dart
```

Dependency rule: presentation -> providers -> use cases -> repository interface <- repository
implementation -> data sources. The domain layer depends on nothing.

**Dependency Injection:** `get_it` (`core/di.dart`) registers data sources, repositories, use cases
and providers; `main.dart` only asks the locator (`sl<ProductProvider>()`).

**Repository pattern:** the UI never knows whether data comes from the API or from Hive.

## Packages used

| Package | Purpose |
|---|---|
| dio | HTTP client |
| provider | State management |
| get_it | Dependency injection (service locator) |
| hive, hive_flutter | Local cache / offline storage |
| cached_network_image | Image loading and caching |
| crypto | SHA-256 password hashing |

## Screenshots

Add screenshots in a `screenshots/` folder and link them here:

| Home | Detail | Add/Edit | Dark mode |
|---|---|---|---|
| ![](screenshots/home.png) | ![](screenshots/detail.png) | ![](screenshots/form.png) | ![](screenshots/dark.png) |

## How to run

```bash
# 1. One-time setup: creates android/ios folders and adds the INTERNET permission
bash scripts/setup_android.sh

# 2. Run
flutter run

# 3. Build the APK
flutter build apk --release
# -> build/app/outputs/flutter-apk/app-release.apk
```

Manual alternative: `flutter create . --project-name shopsphere --org com.example`, then add
`<uses-permission android:name="android.permission.INTERNET"/>` above `<application>` in
`android/app/src/main/AndroidManifest.xml`, then `flutter pub get`.

Run tests with `flutter test`.

Requires Flutter 3.22+ (Dart 3).
