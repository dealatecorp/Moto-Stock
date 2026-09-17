// Fictional preview data, generated fresh each time. No database access.
function createDemoData() {
  const today = new Date();
  const date = `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, "0")}-${String(today.getDate()).padStart(2, "0")}`;
  const stores = [
    { id: 1, name: "Vizag", location: "Visakhapatnam", tier: "Gold", rating: 92 },
    { id: 2, name: "Vijayawada", location: "Vijayawada", tier: "Silver", rating: 85 }
  ];
  const employees = stores.map((store, i) => ({ emp_id: `DEMO-00${i + 1}`, name: ["Demo Ravi", "Demo Priya"][i], username: `demo_staff_${i}`, role: "Sales Executive", shift: "A", active: 1, frozen: 0, branch: store.name }));
  const bikes = [
    { name: "Royal Enfield Classic 350", brand: "Royal Enfield", category: "Cruiser", price: 2.15, stock: 8 },
    { name: "Yamaha MT-15", brand: "Yamaha", category: "Sports", price: 1.75, stock: 5 },
    { name: "Honda Activa 6G", brand: "Honda", category: "Scooter", price: 0.85, stock: 12 },
    { name: "Bajaj Pulsar NS200", brand: "Bajaj", category: "Sports", price: 1.60, stock: 2 }
  ].map((bike, i) => ({ ...bike, id: i + 1, showroom: stores[i % 2].name, sold: 3, purchase_cost: bike.price * 0.8, status: bike.stock <= 2 ? "Low Stock" : "In Stock", color_scheme: "Black", fuel_model: "Petrol", model_year: String(today.getFullYear()), created_at: date, price_unit: "lakhs", cost_unit: "lakhs" }));
  const sales = Array.from({ length: 12 }, (_, i) => {
    const bike = bikes[i % bikes.length];
    const emp = employees[i % employees.length];
    return { sale_db_id: i + 1, transaction_id: `DEMO-${1001 + i}`, customer: `Sample Customer ${i + 1}`, bike_id: bike.id, bike: bike.name, category: bike.category, amount: bike.price, amount_paid_lakh: bike.price, status: "Delivered", delivery_status: "Delivered", payment: "Paid", mode: "Cash", branch: bike.showroom, employee: emp.name, employee_emp_id: emp.emp_id, sale_date: date, quantity: 1 };
  });
  for (const store of stores) {
    const rows = sales.filter(sale => sale.branch === store.name);
    store.units = rows.length;
    store.revenue = rows.reduce((sum, sale) => sum + sale.amount, 0);
  }
  for (const emp of employees) {
    const rows = sales.filter(sale => sale.employee_emp_id === emp.emp_id);
    emp.closed = rows.length;
    emp.revenue = rows.reduce((sum, sale) => sum + sale.amount, 0);
  }
  return { ok: true, stores, employees, bikes, sales };
}
