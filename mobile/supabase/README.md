# MotorStock Mobile Supabase setup

This folder belongs only to the Flutter app under `mobile/`. It does not change or reuse the existing PHP/MySQL backend.

## Apply locally

With the Supabase CLI installed and a local project initialized at `mobile/`:

```powershell
cd mobile
supabase db reset
```

The reset applies `supabase/migrations/20260916000100_initial_mobile_schema.sql` and then `supabase/seed.sql`. For a hosted project, link the CLI to that project and use `supabase db push`; run `seed.sql` separately only when fictional demo records are wanted.

## Create a login profile

The seed deliberately creates no Auth users, passwords, or profiles. Create the user in Supabase Authentication first. Then link its Auth UUID from a trusted SQL Editor or server/service-role process:

```sql
-- Admin may see every branch. branch_id may be null.
insert into public.profiles (user_id, display_name, role, branch_id)
values ('AUTH-USER-UUID'::uuid, 'Network Admin', 'admin', null);

-- Staff login is restricted to one branch.
insert into public.profiles (user_id, display_name, role, branch_id)
values ('ANOTHER-AUTH-USER-UUID'::uuid, 'Ravi Kumar', 'staff', 'b1');
```

`public.staff` is a separate employee directory used on invoices. Creating a staff row never creates a login. Do not place the Supabase service-role key in Flutter; the mobile app uses only the project URL and anon/publishable key, then signs in through Supabase Auth.

The first admin profile must be inserted from SQL Editor or a service-role process because RLS cannot authorize an admin before one exists. Later profile management may be performed by an authenticated active admin.

## Mobile data contract

All application IDs are `text`, matching the current Dart models. Rupee values use `numeric(14,2)` and should be decoded as `num`/`double` by Flutter.

The branch-facing Dart values come from joins:

- `vehicles.branch_id -> branches.id`; show `branches.name` as `Vehicle.branch`.
- `sales.branch_id -> branches.id`; show `branches.name` as `Sale.branch`.
- `staff.branch_id -> branches.id`; show `branches.name` as `Staff.branch`.
- `vehicles.model_year` maps to `Vehicle.year`, and `vehicles.image_url` maps to `Vehicle.image`.

Use the four RPCs for operations that must remain atomic:

- `transfer_vehicle(p_vehicle_id, p_destination_branch_id, p_quantity, p_destination_vehicle_id?)` returns JSON with `source_vehicle`, `destination_vehicle`, and `movement`. Admin only.
- `create_sale(...)` locks inventory, creates the invoice, reserves stock, records an optional initial payment, and returns the sale row. Pass `p_staff_id: null` to use the authenticated profile's display name on the invoice, or pass an employee ID to validate and snapshot that active branch employee.
- `record_payment(p_sale_id, p_amount, p_method?, p_note?, p_payment_id?)` returns the updated sale. Supplying a stable `p_payment_id` makes a network retry idempotent.
- `update_sale_status(p_sale_id, p_status)` validates payment/cancellation rules, restores stock for an unpaid cancellation, and returns the updated sale.

RLS gives active admins access to all branches and active staff identities access only to their assigned branch. Sale, payment, and stock-movement writes are intentionally available only through the RPCs. Branch and employee changes require admin access. Vehicle intake/edit is allowed within the caller's accessible branch; vehicle deletion is admin-only.
