-- Fictional MotorStock Mobile demo data.
-- No auth users, passwords, API keys, or public.profiles are created here.

insert into public.branches (id, name, location)
values
  ('b1', 'Vizag Showroom', 'Visakhapatnam, Andhra Pradesh'),
  ('b2', 'Hyderabad Center', 'Hyderabad, Telangana'),
  ('b3', 'Vijayawada Hub', 'Vijayawada, Andhra Pradesh'),
  ('b4', 'Guntur Outlet', 'Guntur, Andhra Pradesh')
on conflict (id) do update
set name = excluded.name,
    location = excluded.location;

insert into public.vehicles (
  id, name, brand, category, branch_id, vin, color,
  stock, price, cost, model_year, image_url
)
values
  (
    'v1', 'BMW S 1000 RR', 'BMW', 'Supersport', 'b2', 'DEMO-BMW-001',
    'Light White / M', 5, 2485000, 2250000, 2026, ''
  ),
  (
    'v2', 'Ducati Panigale V4 S', 'Ducati', 'Superbike', 'b1', 'DEMO-DUC-002',
    'Ducati Red', 1, 3150000, 2850000, 2026, ''
  ),
  (
    'v3', 'Kawasaki Ninja H2', 'Kawasaki', 'Superbike', 'b3', 'DEMO-KAW-003',
    'Mirror Black', 0, 3540000, 3200000, 2025, ''
  ),
  (
    'v4', 'Triumph Street Triple RS', 'Triumph', 'Roadster', 'b4', 'DEMO-TRI-004',
    'Silver Ice', 3, 1340000, 1185000, 2026, ''
  ),
  (
    'v5', 'RE Continental GT 650', 'Royal Enfield', 'Cruiser', 'b1', 'DEMO-RE-005',
    'British Racing Green', 2, 415000, 355000, 2026, 'assets/bike.png'
  ),
  (
    'v6', 'Honda Activa 6G', 'Honda', 'Commuter', 'b3', 'DEMO-HON-006',
    'Pearl White', 12, 95000, 79000, 2026, ''
  )
on conflict (id) do update
set name = excluded.name,
    brand = excluded.brand,
    category = excluded.category,
    branch_id = excluded.branch_id,
    vin = excluded.vin,
    color = excluded.color,
    stock = excluded.stock,
    price = excluded.price,
    cost = excluded.cost,
    model_year = excluded.model_year,
    image_url = excluded.image_url;

insert into public.staff (id, name, branch_id, role, shift, frozen)
values
  ('EMP-001', 'Ravi Kumar', 'b1', 'Sales Executive', 'A', false),
  ('EMP-002', 'Suresh Babu', 'b2', 'Sales Executive', 'B', false),
  ('EMP-003', 'P. Rajesh', 'b3', 'Sales Executive', 'A', false),
  ('EMP-004', 'M. Srikanth', 'b4', 'Sales Executive', 'B', false)
on conflict (id) do update
set name = excluded.name,
    branch_id = excluded.branch_id,
    role = excluded.role,
    shift = excluded.shift,
    frozen = excluded.frozen;

insert into public.stock_movements (
  id, vehicle_id, movement_type, from_branch_id, to_branch_id,
  quantity, note
)
select
  'MOV-SEED-' || v.id,
  v.id,
  'opening',
  null,
  v.branch_id,
  v.stock,
  'Opening balance from fictional mobile demo seed'
from public.vehicles v
where v.id in ('v1', 'v2', 'v4', 'v5', 'v6')
  and v.stock > 0
on conflict (id) do nothing;

