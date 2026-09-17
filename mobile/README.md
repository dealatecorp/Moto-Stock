# MotorStock Mobile

Flutter dealership-management app connected to Supabase Auth and Postgres. Android, iOS, and web project scaffolds are included.

## Run the connected app

The local client configuration is stored in `supabase.local.json` and is excluded from source control.

```powershell
cd mobile
flutter pub get
flutter devices
flutter run -d DEVICE_ID --dart-define-from-file=supabase.local.json
```

The configured project is `https://gyhsjxebstehtexhacou.supabase.co`. The live administrator login is `demo` / `demo123`; the app maps that short login to the Supabase Auth email internally.

If the app is started without Supabase Dart defines, it intentionally falls back to the local demo account for UI development:

- `admin@motorstock.demo` / `demo123`
- `staff@motorstock.demo` / `demo123`

## Supabase backend

- `supabase/migrations/20260916000100_initial_mobile_schema.sql`: schema, grants, branch-scoped RLS, and transactional RPCs.
- `supabase/seed.sql`: fictional branches, vehicles, employees, and opening stock movements.
- `supabase/README.md`: database setup and Auth-profile linking instructions.
- `lib/supabase_backend.dart`: Auth, record mapping, CRUD, and RPC calls.
- `lib/app_config.dart`: compile-time URL and publishable-key configuration.

Supabase Auth decides identity. `profiles.role` and `profiles.branch_id` decide access; the mobile UI cannot grant itself admin access. Stock transfers, sales, payments, and cancellation status changes use Postgres functions so related inventory and financial changes commit together.

Only a publishable key is shipped to the app. Never place a Supabase secret/service-role key or the database password in Flutter.

## Implemented app features

- Motorcycle branding, a lavender welcome screen, and matching Android/iOS launcher icons and white native splash screens.
- Admin and branch-scoped staff login and logout.
- Dashboard metrics, branch filter, low-stock alerts, revenue chart, and recent sales.
- Inventory search/filtering, intake/editing, admin removal, and atomic stock transfers.
- Sales ledger, filters, status updates, payment recording, and PDF export.
- Billing with stock reservation, customer details, tax input, payments, finance estimate, and PDF invoice.
- Showroom and non-login employee management.
- A local demo mode for isolated widget tests and offline UI development.

## Source layout

- `lib/domain.dart`: models and invoice/EMI calculations.
- `lib/store.dart`: app state, validation, local fallback, and Supabase orchestration.
- `lib/screens.dart`: login, dashboard, inventory, sales, stores, profile, and EMI.
- `lib/forms.dart`: vehicle, invoice, transfer, payment, and management forms.
- `lib/invoice.dart`: PDF generation and sharing.
- `lib/ui.dart`: shared visual components.
- `test/`: domain and widget checks.

## Verify and build

```powershell
flutter analyze
flutter test
flutter build apk --debug --dart-define-from-file=supabase.local.json
flutter build web --release --no-wasm-dry-run --dart-define-from-file=supabase.local.json
```

Android APK: `build/app/outputs/flutter-apk/app-debug.apk`.

The approved navy/cyan motorcycle artwork is `assets/motorstock-icon.png`. To regenerate native launcher and splash resources after changing it:

```powershell
dart run tool/prepare_brand_assets.dart
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

The packaging script resizes and rounds the approved artwork without redrawing it. Android adaptive icons are inset for launcher masks; Android 12 has a separate centered splash asset. `flutter test test/preview_test.dart` exports the welcome, login, startup splash, and main screen previews to `artifacts/`.

Invoice PDFs remain provisional: the entered tax rate is an operator input and must be verified before accounting or tax use. Refund processing, KYC files, barcode/camera capture, push notifications, and production observability are not implemented yet.
