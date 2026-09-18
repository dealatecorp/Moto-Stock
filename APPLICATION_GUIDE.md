# MotorStock Application Guide

## 1. Application overview

MotorStock is a motorcycle dealership management application. Its main product is the Flutter mobile app in `mobile/`, designed for Android, iOS, and web. It gives a dealership a single workspace for inventory intake, stock monitoring, inter-branch transfers, customer billing, payment tracking, sales history, showroom management, employee statistics, and PDF invoices.

The repository also contains an older browser application at the project root (`index.html`, `app.js`, `styles.css`, `server.js`, and `api/`). That web application uses the PHP/MySQL setup described in `DATABASE_SETUP.md`. The Flutter app is independent of that backend: it uses either on-device demo data or Supabase. Changes made in the Flutter demo do not update the PHP/MySQL database.

The mobile app version is currently `1.2.0+6` and the Android package is `com.motorstock.motorstock_mobile`.

## 2. Main users and permissions

MotorStock supports two application roles.

### Administrator

An administrator has a network-wide view and can:

- View all branches or filter the workspace to one branch.
- Add, edit, and delete eligible inventory records.
- Transfer stock between showrooms.
- Add showrooms.
- Add, edit, freeze, unfreeze, and remove employees.
- View all sales and employee performance.
- Create invoices, record payments, and update transaction status.

A vehicle cannot be deleted after it has sales records. Its stock should be set to zero instead, preserving the sales history.

### Showroom staff

A staff user is restricted to the assigned showroom. Staff can work with inventory, invoices, payments, sales, and reports for that branch. Network-level actions such as stock transfers, vehicle deletion, showroom creation, and employee administration require administrator access.

In Supabase mode, these restrictions are also enforced in the database with authentication, profiles, row-level security, and transactional database functions. The interface alone is not the security boundary.

## 3. Data modes

### Offline demo mode

If the app is built without Supabase values, it starts in demo mode. It includes fictional branches, vehicles, employees, and sales. Changes are stored on the device with `SharedPreferences` and remain available after the app is closed and reopened.

Demo accounts:

| Role | Login | Password |
|---|---|---|
| Administrator | `admin@motorstock.demo` | `demo123` |
| Showroom staff | `staff@motorstock.demo` | `demo123` |

The account screen includes **Reset demo data**, which replaces locally edited records with the original sample data.

### Supabase cloud mode

When both `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` are supplied at build time, the app uses Supabase Auth, Postgres, Storage, row-level security, and RPC functions. A partially supplied configuration shows a configuration error instead of silently falling back to demo mode.

Cloud mode provides:

- Authenticated sessions and session restoration.
- Administrator or branch-scoped access from the user profile.
- Shared branches, vehicles, sales, staff, payments, and stock movements.
- Vehicle image storage.
- Atomic stock transfer, invoice creation, payment, and status operations.
- Manual refresh from the account screen.

Only a publishable/anonymous key belongs in the app. A service-role key must never be packaged into the mobile client.

## 4. Application startup and navigation

At startup, the app validates configuration, initializes local storage, optionally initializes Supabase, restores any cloud session, and loads the appropriate data. While this is happening it shows a branded splash screen. If initialization fails, the splash screen displays a retry action.

After sign-in, the main shell contains five bottom navigation destinations:

1. **Home** — dealership overview and shortcuts.
2. **Sales In** — inventory intake and stock management.
3. **Bill** — invoice creation and stock reservation. This is the central primary destination.
4. **Sales Out** — completed and ongoing sales ledger.
5. **Stores** — showroom and employee information.

The top bar also provides appearance, low-stock notification, and account/settings shortcuts. Demo or live context is available on login and the account screen; billing also marks demo invoices.

### Interaction and motion

The main screens use short headings, compact records, and dropdown filters. Secondary actions live in overflow menus, while optional detail sections expand on demand. Shared menu and disclosure components are in `mobile/lib/ui.dart`.

The mobile interface offers Light, System, and Dark appearance options. The chosen mode is stored on the device. Light mode is the default and uses translucent white surfaces, soft blur, pale cyan atmosphere, navy type, and restrained shadows. Dark mode retains the same glass hierarchy with quiet slate-blue accents and no neon treatment:

- The remapped bottom bar uses **Home**, **Sales In**, **Bill**, **Sales Out**, and **Stores**, with billing in the center. Tab icons respond to selection and page content fades and lifts into place. Visited tabs retain their filters, scroll position, and unsaved billing inputs during the session.
- Buttons and actionable sale cards give brief press feedback. Detail pages use Cupertino-style slide transitions; scrolling has gentle edge resistance.
- Dashboard periods use a compact dropdown. Metric changes count smoothly to their new values, revenue tracks animate, and tapping a weekly chart bar shows its invoice count and total.
- Administrators choose a showroom from a compact dropdown. The selection updates inventory and reports across the workspace.
- Billing sections appear in sequence; optional charges and the price breakdown expand on demand. Finance controls expand when enabled, and invoice totals, balances, and EMI estimates animate as the draft changes.
- System reduced-motion settings show content immediately and disable decorative transitions and automatic bike animation. Screen readers announce final financial values.

Shared effects live in `mobile/lib/motion.dart`; theme, frosted-surface, tactile-choice, and atmospheric-background components live in `mobile/lib/ui.dart`. The supplied reference informed the depth, translucent layers, compact controls, and tactile active states. The app uses its own Flutter components and MotorStock palette.

## 5. Screens and features

### Welcome and login

The welcome screen introduces the MotorStock brand and opens the login form. The login form includes username/login ID, password visibility control, sign-in progress, and validation messages.

Onboarding includes a native motorcycle assembly animation (`mobile/lib/bike_assembly.dart`). The wheels, tank, saddle, engine, and other illustrated components separate and return to their assembled positions. A short cycle settles into the completed motorcycle, with pause and replay controls. The supplied `landing animationn.mp4` remains in the project root as a visual reference; it is not bundled or played by the app. The **Get started** button remains available throughout the animation.

The login page uses a soft cyan and navy background glow with a short entrance animation. Its brand text, heading, labels, role selector, button text, and supporting copy use the word-by-word Text Generate Effect. Form inputs remain usable during the reveal.

In demo mode, the role dropdown switches between administrator and showroom staff accounts. The information icon beside **Offline demo** explains local storage and sample credentials. In cloud mode, Supabase authenticates the supplied account and loads its active MotorStock profile. An inactive, missing, or unauthorized profile cannot open the workspace.

### Dashboard

The dashboard gives a high-level operational view for the selected branch scope. Administrators can choose **All branches** or an individual showroom; staff always see their assigned showroom.

Dashboard features include:

- A compact **Overview** heading and **New invoice** action.
- An overflow menu for the EMI calculator.
- Today, week, and month period dropdown.
- Invoiced revenue.
- Total available motorcycles.
- Units sold.
- Pending customer balance.
- Expandable low-stock and out-of-stock alerts; tap an alert to update stock.
- Expandable revenue distribution by showroom.
- Four-week revenue velocity chart.
- Recent dealership sales with links to sale details.

Cancelled sales are excluded from revenue calculations.

### Sales In / Inventory

The inventory screen is the dealership's stock intake and catalogue workspace. It shows the matching bike-record count and provides:

- Search by motorcycle model, brand, or VIN/stock ID.
- Showroom dropdown.
- Category dropdown: Supersport, Superbike, Cruiser, Roadster, and Commuter.
- Stock dropdown: in stock, low stock, and out of stock.
- Compact rows with a photo, name, showroom, selling price, and remaining quantity.
- Tap a bike for its full details, including cost, year, color, and VIN.
- One overflow menu per bike for details, editing, and administrator-only transfer and deletion. Deletion still requires confirmation.

Stock status is calculated automatically:

- **Out of stock** — quantity is 0.
- **Low stock** — quantity is 1 or 2.
- **In stock** — quantity is greater than 2.

#### Vehicle intake and editing

The vehicle form captures name, brand, category, showroom, VIN/stock identifier, color, model year, stock, purchase cost, selling price, and an optional photo. A photo can be selected from the camera or gallery and may be JPG, PNG, or WebP. Demo images are limited to 1 MB; cloud images are limited to 5 MB.

The app validates required values, positive prices, nonnegative stock and cost, and unique VIN/stock identifiers. Demo photos are stored as local encoded data; cloud photos are uploaded to Supabase Storage.

#### Vehicle details

The vehicle detail screen shows the photo, classification, stock state, showroom, VIN, year, color, prices, available stock, and gross unit margin. From here a user can edit the vehicle or start a new invoice with that motorcycle preselected. Invoice creation is disabled for an out-of-stock vehicle.

#### Stock transfer

Administrators can transfer an available quantity to another showroom. A full transfer moves the stock record. A partial transfer reduces the source quantity and creates a separate destination stock lot with a unique transferred stock identifier. Cloud transfers are performed atomically by the backend.

### Sales Out / Sales ledger

The sales ledger shows transaction totals and customer balances for the current branch scope. It supports:

- Search by customer, motorcycle, phone number, or invoice ID.
- Payment dropdown: Paid, Partial, and Pending.
- Date dropdown: all dates, today, and this month.
- Sort dropdown: newest, oldest, or highest amount.
- Sales volume and outstanding balance metrics.
- PDF export of the currently filtered ledger from the overflow menu.

Each compact sale row shows the customer, motorcycle, total, date, and payment state. Cancelled sales show **Cancelled**. Tap a row for the invoice ID, paid amount, balance, branch, and full transaction details.

#### Sale details

The sale detail screen preserves the vehicle photo and financial values captured when the invoice was made. It displays:

- Customer name, phone, address, and the saved customer photo when provided.
- Motorcycle, quantity, showroom, executive, and sale date.
- Vehicle amount, extras, repair cost, subtotal, discount, GST, total, amount paid, balance, and payment method.
- Estimated EMI when finance was selected.
- Invoice and payment status.

Available actions include:

- Preview and print the invoice PDF.
- Share the invoice PDF.
- Record a payment up to the outstanding balance.
- Change status to Booking confirmed, Balance pending, Payment completed, Ready for delivery, Delivered, or Cancelled.

The transaction rules protect data consistency:

- Payment completed requires a zero balance.
- A non-financed sale cannot be delivered while a balance remains.
- A paid or delivered sale cannot be cancelled because it requires a separate refund workflow.
- Cancelling an unpaid, undelivered sale restores its reserved stock.
- A cancelled invoice cannot be reopened.
- Completing the final payment automatically changes a non-delivered transaction to Payment completed.

### Billing

The billing screen creates a vehicle sale or booking. It only lists motorcycles with available stock and validates the requested whole quantity against current inventory.

The invoice form captures:

- Sale type: Vehicle sale or Booking.
- Motorcycle and quantity.
- Customer name, 10-digit phone number, registration address, and an optional photo from the camera or gallery.
- Payment method: UPI, Cash, Bank transfer, Card, or Cheque.
- Registration, insurance, and other extras.
- Repair cost.
- Discount.
- GST rate.
- Initial amount received.
- Optional finance estimate, annual interest rate, and tenure.

Vehicle, customer, payment method, and amount received stay visible. Expand **Charges & tax** for extras, repair cost, discount, and GST; expand **Price breakdown** for individual totals. Collapsing these sections preserves entered values and validation. Invalid hidden charges reopen automatically when generating an invoice.

The financial calculation is:

```text
Subtotal        = vehicle price × quantity + extras + repair cost
Taxable amount  = max(0, subtotal - discount)
GST             = taxable amount × GST rate / 100
Invoice total   = taxable amount + GST
Balance payable = max(0, invoice total - amount received)
```

When finance is enabled, the app calculates an illustrative reducing-balance monthly EMI for the remaining balance. Supported terms are 12, 24, 36, 48, 60, and 72 months.

Creating an invoice reserves stock immediately, adds the transaction to the sales ledger, records any initial payment, and opens the generated PDF. The customer photo is saved with the invoice snapshot and appears in its sale details. Bookings reserve stock in the same way as vehicle sales. In cloud mode these related changes commit as one database transaction, while customer photos remain in private branch-scoped storage.

The entered GST rate is an operator input. The app labels invoices as provisional and requires the tax and statutory details to be checked before accounting use.

### Invoice preview and PDF sharing

The PDF invoice contains the MotorStock identity, invoice ID, date, showroom, vehicle image when available, customer details and optional customer photo, motorcycle line item, financial breakdown, balance, payment method, status, executive, and optional EMI estimate.

The preview supports printing and sharing. The sales ledger can also be exported as a landscape PDF containing invoice, customer, motorcycle, total, paid amount, balance, and status columns.

### Stores

The Stores screen lists showrooms accessible to the current user. Each showroom card shows:

- Name and location.
- Employee count.
- Available motorcycle count.

Administrators can add a showroom with a unique name from the overflow menu. Selecting a showroom opens its employee directory and an expandable **Showroom summary** with revenue excluding cancelled transactions and stock.

### Store details and team management

The store detail screen lists employees, roles, shifts, and active/frozen states. Selecting an employee opens their statistics.

Administrators can:

- Add an employee.
- Edit employee information and showroom assignment.
- Freeze or unfreeze the employee directory record.
- Remove an employee.

The employee directory is separate from Supabase Auth. Adding an employee record does not automatically create a login account.

### Employee statistics

The employee statistics screen reports all-time performance for invoices assigned to that employee and branch. Cancelled invoices are excluded. Metrics include:

- Invoice count.
- Vehicles sold.
- Invoiced revenue.
- Payments collected.
- Outstanding balance.
- Average invoice value.
- Up to 20 recent assigned sales.

### Inventory alerts

The inventory alerts screen lists motorcycles with two or fewer units available in the active branch scope. Selecting an alert opens the vehicle editor so stock can be updated. The top-bar badge shows the current number of alerts.

### EMI calculator

The standalone EMI calculator accepts vehicle price, down payment, annual interest rate, and loan term. It displays:

- Estimated monthly EMI.
- Loan principal.
- Total interest.
- Total loan repayment.

The result is illustrative and excludes lender fees and lender-specific rules.

### Account and settings

This screen shows the current user, role, initials, and branch context. Its tactile appearance control selects **Light**, **System**, or **Dark**. It also links to the EMI calculator, inventory alerts, and administrator-only Stores & team page.

Cloud users can refresh data from Supabase. Demo users can restore the original sample records. All users can sign out.

## 6. Core data model

| Model | Purpose | Important fields |
|---|---|---|
| `Vehicle` | Inventory stock lot | Model, brand, category, branch, VIN/stock ID, color, quantity, costs, year, image |
| `Branch` | Dealership showroom | ID, name, location |
| `Staff` | Employee directory entry | Name, branch, role, shift, frozen state |
| `BillDraft` | Live invoice calculation | Vehicle, customer, optional customer photo, quantity, extras, repair, discount, GST, payment, finance |
| `Sale` | Stored invoice and transaction snapshot | Customer and photo, vehicle, branch, executive, financial amounts, payment, status, finance |
| `MotorProfile` | Authenticated cloud identity | Auth user ID, email, name, role, assigned branch |

Sales keep a snapshot of the motorcycle name, photo, unit price, and financial breakdown. Later inventory edits therefore do not rewrite historical invoice values.

## 7. Architecture and source layout

The Flutter app uses a simple layered structure:

```text
UI screens and forms
        ↓
MotorStore state, validation, and orchestration
        ↓
SharedPreferences (demo) or SupabaseMotorRepository (cloud)
        ↓
On-device JSON or Supabase Auth/Postgres/Storage/RPC
```

Important files:

| Path | Responsibility |
|---|---|
| `mobile/lib/main.dart` | Startup, configuration validation, backend initialization, session routing |
| `mobile/lib/app_config.dart` | Compile-time Supabase values |
| `mobile/lib/domain.dart` | Vehicle, branch, staff, billing, sale, money, date, and EMI models/calculations |
| `mobile/lib/store.dart` | State, permissions, validation, persistence, stock, billing, payment, and status workflows |
| `mobile/lib/supabase_backend.dart` | Supabase authentication, queries, RPC calls, mapping, and image storage |
| `mobile/lib/screens.dart` | Login, dashboard, inventory, sales, stores, employee statistics, alerts, and EMI screens |
| `mobile/lib/forms.dart` | Vehicle, transfer, payment, showroom, employee, and billing forms |
| `mobile/lib/invoice.dart` | Invoice PDF generation, preview, sharing, and ledger export |
| `mobile/lib/ui.dart` | Theme and reusable interface components |
| `mobile/lib/branding.dart` | Welcome, splash, and MotorStock branding widgets |
| `mobile/supabase/migrations/` | Postgres schema, security policies, and transactional functions |
| `mobile/supabase/seed.sql` | Optional fictional cloud records |
| `mobile/test/` | Domain, billing, persistence, startup, image, and screen tests |

`MotorStore` is a `ChangeNotifier`. Screens listen to it and rebuild after inventory, sales, branch, employee, payment, or session changes. Local mutations are rolled back if persistence fails. Cloud mutations refresh the shared snapshot after successful backend operations.

## 8. Validation and safeguards

The application includes the following protections:

- Unique vehicle VIN/stock IDs.
- Positive selling price and nonnegative stock/cost values.
- Available-stock checks before invoice creation or transfer.
- Ten-digit customer phone validation.
- Discount cannot exceed subtotal.
- GST must be between 0 and 100 percent.
- Payment cannot exceed invoice total or remaining balance.
- Branch access validation on operations.
- Administrator checks for network-level actions.
- Confirmation prompts for invoice generation, status changes, resets, deletion, and other significant actions.
- Rollback of local state when a save or remote operation fails.
- Idempotent payment IDs for safer cloud retries.
- Atomic cloud functions for stock transfers, invoice creation, payments, and cancellations.
- Customer photos use a private Supabase bucket with branch-scoped policies and short-lived signed display URLs; offline demo photos remain on the device.
- Restricted invoice image downloads to local assets, embedded data, or HTTPS Supabase Storage URLs.

## 9. Running and building the mobile app

From the `mobile/` directory:

```powershell
flutter pub get
flutter analyze
flutter test
flutter run -d DEVICE_ID
```

The commands above run offline demo mode. To use Supabase, create `mobile/supabase.local.json` from `mobile/supabase.example.json`, then run:

```powershell
flutter run -d DEVICE_ID --dart-define-from-file=supabase.local.json
```

Build an Android release APK with:

```powershell
flutter build apk --release --dart-define-from-file=supabase.local.json
```

For an offline release build, omit the `--dart-define-from-file` option. The APK is generated at:

```text
mobile/build/app/outputs/flutter-apk/app-release.apk
```

## 10. Current limitations

The current version does not include:

- A refund workflow for paid or delivered cancellations.
- KYC or customer document storage.
- Barcode or VIN scanning.
- Push notifications.
- Production observability and crash reporting.
- Automatic tax-rate selection or statutory invoice certification.
- Automatic creation of Supabase Auth users from employee directory records.
- Synchronization between the Flutter demo and the legacy PHP/MySQL application.

Invoice and EMI outputs are operational estimates. Dealership staff must verify taxes, statutory fields, lender terms, and accounting treatment before relying on them in production.
