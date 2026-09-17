-- MotorStock Mobile: vehicle image storage and invoice cost snapshots.

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
) values (
  'vehicle-images',
  'vehicle-images',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set
  name = excluded.name,
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists vehicle_images_select_accessible on storage.objects;
create policy vehicle_images_select_accessible
on storage.objects for select to authenticated
using (
  bucket_id = 'vehicle-images'
  and motorstock_private.can_access_branch((storage.foldername(name))[1])
);

drop policy if exists vehicle_images_insert_accessible on storage.objects;
create policy vehicle_images_insert_accessible
on storage.objects for insert to authenticated
with check (
  bucket_id = 'vehicle-images'
  and motorstock_private.can_access_branch((storage.foldername(name))[1])
);

drop policy if exists vehicle_images_update_accessible on storage.objects;
create policy vehicle_images_update_accessible
on storage.objects for update to authenticated
using (
  bucket_id = 'vehicle-images'
  and motorstock_private.can_access_branch((storage.foldername(name))[1])
)
with check (
  bucket_id = 'vehicle-images'
  and motorstock_private.can_access_branch((storage.foldername(name))[1])
);

drop policy if exists vehicle_images_delete_accessible on storage.objects;
create policy vehicle_images_delete_accessible
on storage.objects for delete to authenticated
using (
  bucket_id = 'vehicle-images'
  and (
    motorstock_private.is_admin()
    or motorstock_private.can_access_branch((storage.foldername(name))[1])
  )
);

alter table public.sales
  add column if not exists repair_cost numeric(14, 2) not null default 0,
  add column if not exists vehicle_image_url text not null default '';

alter table public.sales
  drop constraint if exists sales_repair_cost_check;

alter table public.sales
  add constraint sales_repair_cost_check check (repair_cost >= 0);

update public.sales as s
set vehicle_image_url = coalesce(v.image_url, '')
from public.vehicles as v
where v.id = s.vehicle_id
  and s.vehicle_image_url = '';

alter table public.sales
  drop constraint if exists sales_tax_rate_check;

alter table public.sales
  add constraint sales_tax_rate_check check (tax_rate >= 0 and tax_rate <= 100);

drop function if exists public.create_sale(
  text,
  text,
  text,
  text,
  text,
  integer,
  numeric,
  numeric,
  numeric,
  numeric,
  text,
  text,
  boolean,
  numeric,
  integer,
  text
);

-- Atomic invoice creation: validates branch scope, reserves stock, records the
-- initial payment, and writes the stock audit row in one transaction.
create function public.create_sale(
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
  p_sale_id text default null,
  p_repair_cost numeric default 0
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
     or p_repair_cost is null or p_repair_cost < 0
     or p_discount is null or p_discount < 0
     or p_tax_rate is null or p_tax_rate < 0 or p_tax_rate > 100
     or p_initial_payment is null or p_initial_payment < 0
     or p_interest is null or p_interest < 0
     or p_months is null or p_months < 1 then
    raise exception 'Check the invoice amounts.' using errcode = '22023';
  end if;

  v_subtotal := pg_catalog.round(
    v_vehicle.price * p_quantity + p_extras + p_repair_cost,
    2
  );

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
    id, vehicle_id, vehicle_name, vehicle_image_url, branch_id,
    customer_name, phone, address, staff_id, employee_name,
    sold_at, unit_price, quantity, extras, repair_cost, subtotal, discount,
    tax_rate, tax, total, paid, payment_method, status, kind,
    finance, months, emis_paid, installment, interest, created_by
  ) values (
    v_sale_id,
    v_vehicle.id,
    v_vehicle.name,
    v_vehicle.image_url,
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
    p_repair_cost,
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

revoke all on function public.create_sale(
  text,
  text,
  text,
  text,
  text,
  integer,
  numeric,
  numeric,
  numeric,
  numeric,
  text,
  text,
  boolean,
  numeric,
  integer,
  text,
  numeric
) from public, anon;

grant execute on function public.create_sale(
  text,
  text,
  text,
  text,
  text,
  integer,
  numeric,
  numeric,
  numeric,
  numeric,
  text,
  text,
  boolean,
  numeric,
  integer,
  text,
  numeric
) to authenticated, service_role;
