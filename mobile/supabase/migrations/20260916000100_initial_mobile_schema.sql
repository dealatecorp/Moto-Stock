-- MotorStock Mobile: initial Supabase schema.
-- This migration is intentionally scoped to the Flutter mobile app.

create schema if not exists motorstock_private;
revoke all on schema motorstock_private from public;
grant usage on schema motorstock_private to authenticated, service_role;

create table public.branches (
  id text primary key check (btrim(id) <> ''),
  name text not null check (btrim(name) <> ''),
  location text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index branches_name_ci_key on public.branches (lower(name));

comment on table public.branches is
  'Dealership locations used by MotorStock Mobile.';

create table public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null check (btrim(display_name) <> ''),
  role text not null check (role in ('admin', 'staff')),
  branch_id text references public.branches(id) on update cascade on delete restrict,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint staff_profile_requires_branch check (role = 'admin' or branch_id is not null)
);

comment on table public.profiles is
  'Auth-linked app identities. Staff rows in public.staff are employee records and do not grant login access.';
comment on column public.profiles.user_id is
  'Must match auth.users.id. Create the Auth user first, then insert this profile from a trusted admin context.';

create table public.vehicles (
  id text primary key check (btrim(id) <> ''),
  name text not null check (btrim(name) <> ''),
  brand text not null check (btrim(brand) <> ''),
  category text not null check (btrim(category) <> ''),
  branch_id text not null references public.branches(id) on update cascade on delete restrict,
  vin text not null check (btrim(vin) <> ''),
  color text not null default '',
  stock integer not null default 0 check (stock >= 0),
  price numeric(14, 2) not null check (price > 0),
  cost numeric(14, 2) not null default 0 check (cost >= 0),
  model_year smallint not null check (model_year between 1900 and 2200),
  image_url text not null default '',
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index vehicles_vin_ci_key on public.vehicles (lower(vin));
create index vehicles_branch_id_idx on public.vehicles (branch_id);

create table public.staff (
  id text primary key check (btrim(id) <> ''),
  name text not null check (btrim(name) <> ''),
  branch_id text not null references public.branches(id) on update cascade on delete restrict,
  role text not null default 'Sales Executive' check (btrim(role) <> ''),
  shift text not null default 'A' check (btrim(shift) <> ''),
  frozen boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index staff_branch_id_idx on public.staff (branch_id);

comment on table public.staff is
  'Non-login employee directory. A row here never creates an auth.users identity.';

create table public.sales (
  id text primary key check (btrim(id) <> ''),
  vehicle_id text not null references public.vehicles(id) on update cascade on delete restrict,
  vehicle_name text not null check (btrim(vehicle_name) <> ''),
  branch_id text not null references public.branches(id) on update cascade on delete restrict,
  customer_name text not null check (btrim(customer_name) <> ''),
  phone text not null check (phone ~ '^[0-9]{10}$'),
  address text not null default '',
  staff_id text references public.staff(id) on update cascade on delete set null,
  employee_name text not null check (btrim(employee_name) <> ''),
  sold_at timestamptz not null default now(),
  unit_price numeric(14, 2) not null check (unit_price > 0),
  quantity integer not null default 1 check (quantity > 0),
  extras numeric(14, 2) not null default 0 check (extras >= 0),
  subtotal numeric(14, 2) not null check (subtotal >= 0),
  discount numeric(14, 2) not null default 0 check (discount >= 0 and discount <= subtotal),
  tax_rate numeric(7, 4) not null default 0 check (tax_rate >= 0),
  tax numeric(14, 2) not null default 0 check (tax >= 0),
  total numeric(14, 2) not null check (total >= 0),
  paid numeric(14, 2) not null default 0 check (paid >= 0 and paid <= total),
  balance numeric(14, 2) generated always as (greatest(total - paid, 0::numeric)) stored,
  payment_status text generated always as (
    case
      when greatest(total - paid, 0::numeric) = 0 then 'Paid'
      when paid > 0 then 'Partial'
      else 'Pending'
    end
  ) stored,
  payment_method text not null default 'UPI' check (btrim(payment_method) <> ''),
  status text not null check (
    status in (
      'Booking confirmed',
      'Balance pending',
      'Payment completed',
      'Ready for delivery',
      'Delivered',
      'Cancelled'
    )
  ),
  kind text not null default 'Vehicle sale' check (kind in ('Vehicle sale', 'Booking')),
  finance boolean not null default false,
  months integer not null default 36 check (months > 0),
  emis_paid integer not null default 0 check (emis_paid >= 0 and emis_paid <= months),
  installment numeric(14, 2) not null default 0 check (installment >= 0),
  interest numeric(7, 4) not null default 9.5 check (interest >= 0),
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index sales_branch_sold_at_idx on public.sales (branch_id, sold_at desc);
create index sales_vehicle_id_idx on public.sales (vehicle_id);
create index sales_staff_id_idx on public.sales (staff_id);

create table public.sale_payments (
  id text primary key check (btrim(id) <> ''),
  sale_id text not null references public.sales(id) on update cascade on delete restrict,
  amount numeric(14, 2) not null check (amount > 0),
  method text not null check (btrim(method) <> ''),
  payment_kind text not null default 'collection' check (payment_kind in ('initial', 'collection')),
  note text not null default '',
  received_at timestamptz not null default now(),
  received_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

create index sale_payments_sale_id_idx on public.sale_payments (sale_id, received_at);

create table public.stock_movements (
  id text primary key check (btrim(id) <> ''),
  vehicle_id text not null references public.vehicles(id) on update cascade on delete restrict,
  counterpart_vehicle_id text references public.vehicles(id) on update cascade on delete restrict,
  sale_id text references public.sales(id) on update cascade on delete restrict,
  movement_type text not null check (
    movement_type in ('opening', 'intake', 'adjustment', 'sale', 'transfer', 'cancellation')
  ),
  from_branch_id text references public.branches(id) on update cascade on delete restrict,
  to_branch_id text references public.branches(id) on update cascade on delete restrict,
  quantity integer not null check (quantity > 0),
  note text not null default '',
  performed_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  constraint stock_movement_has_location check (
    from_branch_id is not null or to_branch_id is not null
  )
);

create index stock_movements_vehicle_id_idx on public.stock_movements (vehicle_id, created_at desc);
create index stock_movements_sale_id_idx on public.stock_movements (sale_id);
create index stock_movements_from_branch_idx on public.stock_movements (from_branch_id);
create index stock_movements_to_branch_idx on public.stock_movements (to_branch_id);

-- Helper functions deliberately bypass profile RLS, while deriving identity only
-- from auth.uid(). They expose no data other than the caller's own access scope.
create or replace function motorstock_private.active_user()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.profiles p
    where p.user_id = auth.uid()
      and p.active
  );
$$;

create or replace function motorstock_private.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.profiles p
    where p.user_id = auth.uid()
      and p.active
      and p.role = 'admin'
  );
$$;

create or replace function motorstock_private.can_access_branch(p_branch_id text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.profiles p
    where p.user_id = auth.uid()
      and p.active
      and (p.role = 'admin' or p.branch_id = p_branch_id)
  );
$$;

create or replace function motorstock_private.touch_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := pg_catalog.now();
  return new;
end;
$$;

revoke all on function motorstock_private.active_user() from public;
revoke all on function motorstock_private.is_admin() from public;
revoke all on function motorstock_private.can_access_branch(text) from public;
revoke all on function motorstock_private.touch_updated_at() from public;
grant execute on function motorstock_private.active_user() to authenticated, service_role;
grant execute on function motorstock_private.is_admin() to authenticated, service_role;
grant execute on function motorstock_private.can_access_branch(text) to authenticated, service_role;

create trigger branches_touch_updated_at
before update on public.branches
for each row execute function motorstock_private.touch_updated_at();

create trigger profiles_touch_updated_at
before update on public.profiles
for each row execute function motorstock_private.touch_updated_at();

create trigger vehicles_touch_updated_at
before update on public.vehicles
for each row execute function motorstock_private.touch_updated_at();

create trigger staff_touch_updated_at
before update on public.staff
for each row execute function motorstock_private.touch_updated_at();

create trigger sales_touch_updated_at
before update on public.sales
for each row execute function motorstock_private.touch_updated_at();

alter table public.branches enable row level security;
alter table public.profiles enable row level security;
alter table public.vehicles enable row level security;
alter table public.staff enable row level security;
alter table public.sales enable row level security;
alter table public.sale_payments enable row level security;
alter table public.stock_movements enable row level security;

create policy branches_select_accessible
on public.branches for select to authenticated
using (motorstock_private.can_access_branch(id));

create policy branches_insert_admin
on public.branches for insert to authenticated
with check (motorstock_private.is_admin());

create policy branches_update_admin
on public.branches for update to authenticated
using (motorstock_private.is_admin())
with check (motorstock_private.is_admin());

create policy branches_delete_admin
on public.branches for delete to authenticated
using (motorstock_private.is_admin());

create policy profiles_select_self_or_admin
on public.profiles for select to authenticated
using (user_id = auth.uid() or motorstock_private.is_admin());

create policy profiles_insert_admin
on public.profiles for insert to authenticated
with check (motorstock_private.is_admin());

create policy profiles_update_admin
on public.profiles for update to authenticated
using (motorstock_private.is_admin())
with check (motorstock_private.is_admin());

create policy profiles_delete_admin
on public.profiles for delete to authenticated
using (motorstock_private.is_admin());

create policy vehicles_select_accessible
on public.vehicles for select to authenticated
using (motorstock_private.can_access_branch(branch_id));

create policy vehicles_insert_accessible
on public.vehicles for insert to authenticated
with check (motorstock_private.can_access_branch(branch_id));

create policy vehicles_update_accessible
on public.vehicles for update to authenticated
using (motorstock_private.can_access_branch(branch_id))
with check (motorstock_private.can_access_branch(branch_id));

create policy vehicles_delete_admin
on public.vehicles for delete to authenticated
using (motorstock_private.is_admin());

create policy staff_select_accessible
on public.staff for select to authenticated
using (motorstock_private.can_access_branch(branch_id));

create policy staff_insert_admin
on public.staff for insert to authenticated
with check (motorstock_private.is_admin());

create policy staff_update_admin
on public.staff for update to authenticated
using (motorstock_private.is_admin())
with check (motorstock_private.is_admin());

create policy staff_delete_admin
on public.staff for delete to authenticated
using (motorstock_private.is_admin());

create policy sales_select_accessible
on public.sales for select to authenticated
using (motorstock_private.can_access_branch(branch_id));

create policy sale_payments_select_accessible
on public.sale_payments for select to authenticated
using (
  exists (
    select 1
    from public.sales s
    where s.id = sale_payments.sale_id
      and motorstock_private.can_access_branch(s.branch_id)
  )
);

create policy stock_movements_select_accessible
on public.stock_movements for select to authenticated
using (
  motorstock_private.can_access_branch(from_branch_id)
  or motorstock_private.can_access_branch(to_branch_id)
);

revoke all privileges on public.branches from public, anon, authenticated;
revoke all privileges on public.profiles from public, anon, authenticated;
revoke all privileges on public.vehicles from public, anon, authenticated;
revoke all privileges on public.staff from public, anon, authenticated;
revoke all privileges on public.sales from public, anon, authenticated;
revoke all privileges on public.sale_payments from public, anon, authenticated;
revoke all privileges on public.stock_movements from public, anon, authenticated;

grant select, insert, update, delete on public.branches to authenticated;
grant select, insert, update, delete on public.profiles to authenticated;
grant select, insert, update, delete on public.vehicles to authenticated;
grant select, insert, update, delete on public.staff to authenticated;
grant select on public.sales to authenticated;
grant select on public.sale_payments to authenticated;
grant select on public.stock_movements to authenticated;

grant all privileges on public.branches to service_role;
grant all privileges on public.profiles to service_role;
grant all privileges on public.vehicles to service_role;
grant all privileges on public.staff to service_role;
grant all privileges on public.sales to service_role;
grant all privileges on public.sale_payments to service_role;
grant all privileges on public.stock_movements to service_role;

-- Admin-only stock transfer. A partial transfer creates another stock lot,
-- mirroring the current Flutter demo's behavior.
create or replace function public.transfer_vehicle(
  p_vehicle_id text,
  p_destination_branch_id text,
  p_quantity integer,
  p_destination_vehicle_id text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_source public.vehicles%rowtype;
  v_destination public.vehicles%rowtype;
  v_movement public.stock_movements%rowtype;
  v_destination_id text;
  v_origin_branch_id text;
begin
  if v_actor is null or not motorstock_private.is_admin() then
    raise exception 'Admin access is required.' using errcode = '42501';
  end if;

  if p_quantity is null or p_quantity < 1 then
    raise exception 'Transfer quantity must be at least one.' using errcode = '22023';
  end if;

  if not exists (select 1 from public.branches b where b.id = p_destination_branch_id) then
    raise exception 'Destination branch not found.' using errcode = 'P0002';
  end if;

  select * into v_source
  from public.vehicles v
  where v.id = p_vehicle_id
  for update;

  if not found then
    raise exception 'Vehicle not found.' using errcode = 'P0002';
  end if;

  v_origin_branch_id := v_source.branch_id;

  if v_source.branch_id = p_destination_branch_id then
    raise exception 'Choose another branch.' using errcode = '22023';
  end if;

  if p_quantity > v_source.stock then
    raise exception 'Transfer quantity exceeds available stock.' using errcode = '22023';
  end if;

  if p_quantity = v_source.stock then
    update public.vehicles
    set branch_id = p_destination_branch_id
    where id = v_source.id
    returning * into v_destination;

    v_source := v_destination;
  else
    update public.vehicles
    set stock = stock - p_quantity
    where id = v_source.id
    returning * into v_source;

    v_destination_id := coalesce(
      nullif(btrim(p_destination_vehicle_id), ''),
      'v-' || replace(pg_catalog.gen_random_uuid()::text, '-', '')
    );

    insert into public.vehicles (
      id, name, brand, category, branch_id, vin, color, stock,
      price, cost, model_year, image_url, created_by
    ) values (
      v_destination_id,
      v_source.name,
      v_source.brand,
      v_source.category,
      p_destination_branch_id,
      v_source.vin || '-T' || left(replace(pg_catalog.gen_random_uuid()::text, '-', ''), 10),
      v_source.color,
      p_quantity,
      v_source.price,
      v_source.cost,
      v_source.model_year,
      v_source.image_url,
      v_actor
    )
    returning * into v_destination;
  end if;

  insert into public.stock_movements (
    id, vehicle_id, counterpart_vehicle_id, movement_type,
    from_branch_id, to_branch_id, quantity, note, performed_by
  ) values (
    'MOV-' || replace(pg_catalog.gen_random_uuid()::text, '-', ''),
    p_vehicle_id,
    v_destination.id,
    'transfer',
    v_origin_branch_id,
    p_destination_branch_id,
    p_quantity,
    'Mobile stock transfer',
    v_actor
  )
  returning * into v_movement;

  return pg_catalog.jsonb_build_object(
    'source_vehicle', pg_catalog.to_jsonb(v_source),
    'destination_vehicle', pg_catalog.to_jsonb(v_destination),
    'movement', pg_catalog.to_jsonb(v_movement)
  );
end;
$$;

-- Atomic invoice creation: validates branch scope, reserves stock, records the
-- initial payment, and writes the stock audit row in one transaction.
create or replace function public.create_sale(
  p_vehicle_id text,
  p_customer_name text,
  p_phone text,
  p_address text,
  p_staff_id text,
  p_quantity integer default 1,
  p_extras numeric default 0,
  p_discount numeric default 0,
  p_tax_rate numeric default 0,
  p_initial_payment numeric default 0,
  p_payment_method text default 'UPI',
  p_kind text default 'Vehicle sale',
  p_finance boolean default false,
  p_interest numeric default 9.5,
  p_months integer default 36,
  p_sale_id text default null
)
returns public.sales
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_vehicle public.vehicles%rowtype;
  v_staff public.staff%rowtype;
  v_sale public.sales%rowtype;
  v_employee_name text;
  v_sale_staff_id text;
  v_sale_id text;
  v_subtotal numeric(14, 2);
  v_taxable numeric(14, 2);
  v_tax numeric(14, 2);
  v_total numeric(14, 2);
  v_balance numeric(14, 2);
  v_installment numeric(14, 2) := 0;
  v_monthly_rate numeric;
begin
  if v_actor is null or not motorstock_private.active_user() then
    raise exception 'An active MotorStock profile is required.' using errcode = '42501';
  end if;

  select * into v_vehicle
  from public.vehicles v
  where v.id = p_vehicle_id
  for update;

  if not found then
    raise exception 'Vehicle not found.' using errcode = 'P0002';
  end if;

  if not motorstock_private.can_access_branch(v_vehicle.branch_id) then
    raise exception 'This showroom is not accessible.' using errcode = '42501';
  end if;

  if p_staff_id is null then
    select p.display_name into v_employee_name
    from public.profiles p
    where p.user_id = v_actor
      and p.active;

    v_sale_staff_id := null;
  else
    select * into v_staff
    from public.staff s
    where s.id = p_staff_id;

    if not found or v_staff.branch_id <> v_vehicle.branch_id or v_staff.frozen then
      raise exception 'Choose an active employee from this showroom.' using errcode = '22023';
    end if;

    v_employee_name := v_staff.name;
    v_sale_staff_id := v_staff.id;
  end if;

  if p_quantity is null or p_quantity < 1 or p_quantity > v_vehicle.stock then
    raise exception 'Not enough stock for this invoice.' using errcode = '22023';
  end if;

  if nullif(btrim(p_customer_name), '') is null or p_phone !~ '^[0-9]{10}$' then
    raise exception 'Enter a customer name and 10-digit phone number.' using errcode = '22023';
  end if;

  if p_kind not in ('Vehicle sale', 'Booking') then
    raise exception 'Invalid sale kind.' using errcode = '22023';
  end if;

  if nullif(btrim(p_payment_method), '') is null
     or p_extras is null or p_extras < 0
     or p_discount is null or p_discount < 0
     or p_tax_rate is null or p_tax_rate < 0
     or p_initial_payment is null or p_initial_payment < 0
     or p_interest is null or p_interest < 0
     or p_months is null or p_months < 1 then
    raise exception 'Check the invoice amounts.' using errcode = '22023';
  end if;

  v_subtotal := pg_catalog.round(v_vehicle.price * p_quantity + p_extras, 2);

  if p_discount > v_subtotal then
    raise exception 'Discount cannot exceed subtotal.' using errcode = '22023';
  end if;

  v_taxable := greatest(v_subtotal - p_discount, 0::numeric);
  v_tax := pg_catalog.round(v_taxable * p_tax_rate / 100, 2);
  v_total := pg_catalog.round(v_taxable + v_tax, 2);

  if p_initial_payment > v_total then
    raise exception 'Initial payment cannot exceed the invoice total.' using errcode = '22023';
  end if;

  v_balance := pg_catalog.round(v_total - p_initial_payment, 2);

  if p_finance and v_balance > 0 then
    if p_interest = 0 then
      v_installment := pg_catalog.round(v_balance / p_months, 2);
    else
      v_monthly_rate := p_interest / 1200;
      v_installment := pg_catalog.round(
        v_balance * v_monthly_rate * pg_catalog.power(1 + v_monthly_rate, p_months)
        / (pg_catalog.power(1 + v_monthly_rate, p_months) - 1),
        2
      );
    end if;
  end if;

  v_sale_id := coalesce(
    nullif(btrim(p_sale_id), ''),
    'MS-' || pg_catalog.to_char(pg_catalog.clock_timestamp(), 'YYYY') || '-'
      || replace(pg_catalog.gen_random_uuid()::text, '-', '')
  );

  insert into public.sales (
    id, vehicle_id, vehicle_name, branch_id,
    customer_name, phone, address, staff_id, employee_name,
    sold_at, unit_price, quantity, extras, subtotal, discount,
    tax_rate, tax, total, paid, payment_method, status, kind,
    finance, months, emis_paid, installment, interest, created_by
  ) values (
    v_sale_id,
    v_vehicle.id,
    v_vehicle.name,
    v_vehicle.branch_id,
    btrim(p_customer_name),
    p_phone,
    coalesce(p_address, ''),
    v_sale_staff_id,
    v_employee_name,
    pg_catalog.now(),
    v_vehicle.price,
    p_quantity,
    p_extras,
    v_subtotal,
    p_discount,
    p_tax_rate,
    v_tax,
    v_total,
    p_initial_payment,
    btrim(p_payment_method),
    case
      when p_kind = 'Booking' then 'Booking confirmed'
      when v_balance = 0 then 'Payment completed'
      else 'Balance pending'
    end,
    p_kind,
    p_finance,
    p_months,
    0,
    v_installment,
    p_interest,
    v_actor
  )
  returning * into v_sale;

  update public.vehicles
  set stock = stock - p_quantity
  where id = v_vehicle.id;

  if p_initial_payment > 0 then
    insert into public.sale_payments (
      id, sale_id, amount, method, payment_kind, note, received_by
    ) values (
      'PAY-' || replace(pg_catalog.gen_random_uuid()::text, '-', ''),
      v_sale.id,
      p_initial_payment,
      btrim(p_payment_method),
      'initial',
      'Initial payment recorded with invoice',
      v_actor
    );
  end if;

  insert into public.stock_movements (
    id, vehicle_id, sale_id, movement_type,
    from_branch_id, to_branch_id, quantity, note, performed_by
  ) values (
    'MOV-' || replace(pg_catalog.gen_random_uuid()::text, '-', ''),
    v_vehicle.id,
    v_sale.id,
    'sale',
    v_vehicle.branch_id,
    null,
    p_quantity,
    case when p_kind = 'Booking' then 'Stock reserved for booking' else 'Stock issued for sale' end,
    v_actor
  );

  return v_sale;
end;
$$;

create or replace function public.record_payment(
  p_sale_id text,
  p_amount numeric,
  p_method text default null,
  p_note text default null,
  p_payment_id text default null
)
returns public.sales
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_sale public.sales%rowtype;
  v_payment_id text;
  v_method text;
  v_existing public.sale_payments%rowtype;
begin
  if v_actor is null or not motorstock_private.active_user() then
    raise exception 'An active MotorStock profile is required.' using errcode = '42501';
  end if;

  select * into v_sale
  from public.sales s
  where s.id = p_sale_id
  for update;

  if not found then
    raise exception 'Sale not found.' using errcode = 'P0002';
  end if;

  if not motorstock_private.can_access_branch(v_sale.branch_id) then
    raise exception 'This showroom is not accessible.' using errcode = '42501';
  end if;

  v_method := coalesce(nullif(btrim(p_method), ''), v_sale.payment_method);
  v_payment_id := coalesce(
    nullif(btrim(p_payment_id), ''),
    'PAY-' || replace(pg_catalog.gen_random_uuid()::text, '-', '')
  );

  -- A caller-supplied ID makes retries idempotent. It must describe the same
  -- payment if it already exists.
  select * into v_existing
  from public.sale_payments sp
  where sp.id = v_payment_id;

  if found then
    if v_existing.sale_id = p_sale_id
       and v_existing.amount = p_amount
       and v_existing.method = v_method then
      return v_sale;
    end if;
    raise exception 'Payment ID is already in use.' using errcode = '23505';
  end if;

  if v_sale.status = 'Cancelled' or p_amount is null or p_amount <= 0 or p_amount > v_sale.balance then
    raise exception 'Enter a payment within the outstanding balance.' using errcode = '22023';
  end if;

  insert into public.sale_payments (
    id, sale_id, amount, method, payment_kind, note, received_by
  ) values (
    v_payment_id,
    v_sale.id,
    p_amount,
    v_method,
    'collection',
    coalesce(p_note, ''),
    v_actor
  );

  update public.sales
  set paid = paid + p_amount,
      payment_method = v_method,
      status = case
        when paid + p_amount >= total and status <> 'Delivered' then 'Payment completed'
        else status
      end
  where id = v_sale.id
  returning * into v_sale;

  return v_sale;
end;
$$;

create or replace function public.update_sale_status(
  p_sale_id text,
  p_status text
)
returns public.sales
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_sale public.sales%rowtype;
  v_vehicle public.vehicles%rowtype;
  v_restock_vehicle public.vehicles%rowtype;
begin
  if v_actor is null or not motorstock_private.active_user() then
    raise exception 'An active MotorStock profile is required.' using errcode = '42501';
  end if;

  if p_status not in (
    'Booking confirmed',
    'Balance pending',
    'Payment completed',
    'Ready for delivery',
    'Delivered',
    'Cancelled'
  ) then
    raise exception 'Invalid status.' using errcode = '22023';
  end if;

  select * into v_sale
  from public.sales s
  where s.id = p_sale_id
  for update;

  if not found then
    raise exception 'Sale not found.' using errcode = 'P0002';
  end if;

  if not motorstock_private.can_access_branch(v_sale.branch_id) then
    raise exception 'This showroom is not accessible.' using errcode = '42501';
  end if;

  if v_sale.status = 'Cancelled' then
    raise exception 'Cancelled invoices cannot be reopened.' using errcode = '22023';
  end if;

  if p_status = 'Payment completed' and v_sale.balance > 0 then
    raise exception 'Record the remaining payment first.' using errcode = '22023';
  end if;

  if p_status = 'Delivered' and v_sale.balance > 0 and not v_sale.finance then
    raise exception 'Collect the balance before delivery.' using errcode = '22023';
  end if;

  if p_status = 'Cancelled' then
    if v_sale.paid > 0 or v_sale.status = 'Delivered' then
      raise exception 'Paid or delivered invoices require a refund workflow.' using errcode = '22023';
    end if;

    select * into v_vehicle
    from public.vehicles v
    where v.id = v_sale.vehicle_id
    for update;

    if not found then
      raise exception 'Vehicle not found for stock restoration.' using errcode = 'P0002';
    end if;

    if v_vehicle.branch_id = v_sale.branch_id then
      update public.vehicles
      set stock = stock + v_sale.quantity
      where id = v_vehicle.id
      returning * into v_restock_vehicle;
    else
      insert into public.vehicles (
        id, name, brand, category, branch_id, vin, color, stock,
        price, cost, model_year, image_url, created_by
      ) values (
        'v-' || replace(pg_catalog.gen_random_uuid()::text, '-', ''),
        v_vehicle.name,
        v_vehicle.brand,
        v_vehicle.category,
        v_sale.branch_id,
        v_vehicle.vin || '-C' || left(replace(pg_catalog.gen_random_uuid()::text, '-', ''), 10),
        v_vehicle.color,
        v_sale.quantity,
        v_vehicle.price,
        v_vehicle.cost,
        v_vehicle.model_year,
        v_vehicle.image_url,
        v_actor
      )
      returning * into v_restock_vehicle;
    end if;

    insert into public.stock_movements (
      id, vehicle_id, counterpart_vehicle_id, sale_id, movement_type,
      from_branch_id, to_branch_id, quantity, note, performed_by
    ) values (
      'MOV-' || replace(pg_catalog.gen_random_uuid()::text, '-', ''),
      v_restock_vehicle.id,
      v_sale.vehicle_id,
      v_sale.id,
      'cancellation',
      null,
      v_sale.branch_id,
      v_sale.quantity,
      'Stock restored after unpaid cancellation',
      v_actor
    );
  end if;

  update public.sales
  set status = p_status
  where id = v_sale.id
  returning * into v_sale;

  return v_sale;
end;
$$;

revoke all on function public.transfer_vehicle(text, text, integer, text) from public, anon;
revoke all on function public.create_sale(text, text, text, text, text, integer, numeric, numeric, numeric, numeric, text, text, boolean, numeric, integer, text) from public, anon;
revoke all on function public.record_payment(text, numeric, text, text, text) from public, anon;
revoke all on function public.update_sale_status(text, text) from public, anon;

grant execute on function public.transfer_vehicle(text, text, integer, text) to authenticated, service_role;
grant execute on function public.create_sale(text, text, text, text, text, integer, numeric, numeric, numeric, numeric, text, text, boolean, numeric, integer, text) to authenticated, service_role;
grant execute on function public.record_payment(text, numeric, text, text, text) to authenticated, service_role;
grant execute on function public.update_sale_status(text, text) to authenticated, service_role;
