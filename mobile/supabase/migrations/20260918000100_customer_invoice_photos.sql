-- Optional customer photos attached to sale records and invoice PDFs.
-- These images are private because they contain customer data.

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
) values (
  'customer-images',
  'customer-images',
  false,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set
  name = excluded.name,
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists customer_images_select_accessible on storage.objects;
create policy customer_images_select_accessible
on storage.objects for select to authenticated
using (
  bucket_id = 'customer-images'
  and motorstock_private.can_access_branch((storage.foldername(name))[1])
);

drop policy if exists customer_images_insert_accessible on storage.objects;
create policy customer_images_insert_accessible
on storage.objects for insert to authenticated
with check (
  bucket_id = 'customer-images'
  and motorstock_private.can_access_branch((storage.foldername(name))[1])
);

drop policy if exists customer_images_delete_accessible on storage.objects;
create policy customer_images_delete_accessible
on storage.objects for delete to authenticated
using (
  bucket_id = 'customer-images'
  and motorstock_private.can_access_branch((storage.foldername(name))[1])
);

alter table public.sales
  add column if not exists customer_image_path text not null default '';

alter table public.sales
  drop constraint if exists sales_customer_image_path_length_check;

alter table public.sales
  add constraint sales_customer_image_path_length_check
  check (length(customer_image_path) <= 512);

create or replace function public.create_sale_with_customer_image(
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
  p_repair_cost numeric default 0,
  p_customer_image_path text default ''
)
returns public.sales
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_sale public.sales%rowtype;
  v_customer_image_path text := coalesce(p_customer_image_path, '');
begin
  if length(v_customer_image_path) > 512 then
    raise exception 'Customer image path is too long.' using errcode = '22023';
  end if;

  if v_customer_image_path <> '' and v_customer_image_path !~
      '^[A-Za-z0-9_-]+/customers/[A-Za-z0-9_-]+/[0-9]+[.](jpg|jpeg|png|webp)$' then
    raise exception 'Customer image path is invalid.' using errcode = '22023';
  end if;

  select * into v_sale
  from public.create_sale(
    p_vehicle_id => p_vehicle_id,
    p_customer_name => p_customer_name,
    p_phone => p_phone,
    p_address => p_address,
    p_staff_id => p_staff_id,
    p_quantity => p_quantity,
    p_extras => p_extras,
    p_discount => p_discount,
    p_tax_rate => p_tax_rate,
    p_initial_payment => p_initial_payment,
    p_payment_method => p_payment_method,
    p_kind => p_kind,
    p_finance => p_finance,
    p_interest => p_interest,
    p_months => p_months,
    p_sale_id => p_sale_id,
    p_repair_cost => p_repair_cost
  );

  update public.sales
  set customer_image_path = v_customer_image_path
  where id = v_sale.id
  returning * into v_sale;

  return v_sale;
end;
$$;

revoke all on function public.create_sale_with_customer_image(
  text, text, text, text, text, integer, numeric, numeric, numeric, numeric,
  text, text, boolean, numeric, integer, text, numeric, text
) from public, anon;

grant execute on function public.create_sale_with_customer_image(
  text, text, text, text, text, integer, numeric, numeric, numeric, numeric,
  text, text, boolean, numeric, integer, text, numeric, text
) to authenticated, service_role;
