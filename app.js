const $ = (selector) => document.querySelector(selector);
const modalRoot = $("#modalRoot");
const toast = $("#toast");
const demoMode = new URLSearchParams(window.location.search).get("demo") === "1";
const demoUser = { type: "admin", name: "Demo Admin", role: "Network Admin", username: "demo", id: "DEMO-ADMIN" };

const state = {
  user: null,
  page: "dashboard",
  filter: "month",
  search: "",
  customFrom: "",
  customTo: "",
  branch: "all",
  selectedStore: null,
  selectedEmployeeId: null,
  inventorySearch: "",
  inventoryBranch: "all",
  storeFilter: "month",
  storeCustomFrom: "",
  storeCustomTo: "",
  selectedBikeId: null,
  apiReady: false,
  transactionStatus: "Delivered",
  billingDraft: null,
  lastInvoice: null,
  salesSearch: "",
  salesDateFilter: "month",
  salesCustomFrom: "",
  salesCustomTo: "",
  salesShowroom: "all",
  salesPaymentStatus: "all",
  salesStatus: "all",
  salesVehicle: "all",
  salesEmployee: "all",
  salesPage: 1,
  salesPageSize: 10,
  salesStatusDate: "",
  emiBikeId: "",
  emiDownPayment: null,
  emiInterestRate: 9.5,
  emiTenure: 36,
  bikes: [],
  stores: [],
  employees: [],
  sales: []
};

const api = {
  async request(action, payload = {}) {
    if (demoMode) {
      if (action === "bootstrap") return createDemoData();
      if (action === "login") return { ok: true, user: demoUser };
      throw new Error("Demo preview: saving requires the database.");
    }
    const response = await fetch(`api/api.php?action=${action}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload)
    });
    const text = await response.text();
    let data;
    try {
      data = JSON.parse(text);
    } catch (error) {
      const readable = text.replace(/<[^>]*>/g, " ").replace(/\s+/g, " ").trim();
      throw new Error(readable || "API returned an invalid response.");
    }
    if (!response.ok) throw new Error(data.error || "API request failed");
    if (!data.ok) throw new Error(data.error || "API error");
    return data;
  }
};

const navItems = {
  admin: [
    ["dashboard", "layout-dashboard", "Dashboard"],
    ["inventory", "bike", "Sale In"],
    ["sales", "receipt", "Sale Out"],
    ["emi", "calculator", "EMI Calculator"],
    ["stores", "building-2", "Stores"],
    ["billing", "credit-card", "Billing"],
    ["profile", "user", "Profile"]
  ],
  staff: [
    ["dashboard", "layout-dashboard", "Dashboard"],
    ["inventory", "bike", "Sale In"],
    ["sales", "receipt", "Sale Out"],
    ["emi", "calculator", "EMI Calculator"],
    ["billing", "credit-card", "Billing"],
    ["profile", "user", "Profile"]
  ]
};

const priceUnits = ["rupees", "hundreds", "thousands", "lakhs"];
const colors = ["Black", "White", "Red", "Blue", "Green", "Yellow", "Orange", "Silver", "Grey", "Brown", "Purple", "Gold", "Matte Black", "Pearl White", "Cosmic Silver"];
const indianStates = ["Andhra Pradesh", "Arunachal Pradesh", "Assam", "Bihar", "Chhattisgarh", "Goa", "Gujarat", "Haryana", "Himachal Pradesh", "Jharkhand", "Karnataka", "Kerala", "Madhya Pradesh", "Maharashtra", "Manipur", "Meghalaya", "Mizoram", "Nagaland", "Odisha", "Punjab", "Rajasthan", "Sikkim", "Tamil Nadu", "Telangana", "Tripura", "Uttar Pradesh", "Uttarakhand", "West Bengal", "Delhi", "Jammu and Kashmir", "Ladakh", "Puducherry"];

function formatMoney(value, unit = "lakhs") {
  const amount = Number(value || 0);
  if (unit === "rupees") return `Rs ${amount.toLocaleString("en-IN", { maximumFractionDigits: 0 })}`;
  const suffix = { hundreds: "hundreds", thousands: "thousands", lakhs: "L" }[unit] || unit;
  return `Rs ${amount.toLocaleString("en-IN", { minimumFractionDigits: 2, maximumFractionDigits: 2 })} ${suffix}`;
}

function formatInventoryRupees(value, unit = "lakhs") {
  const rupees = Math.round(fromLakhs(toLakhs(value || 0, unit), "rupees"));
  return `Rs ${rupees}`;
}

function formatInvoiceMoney(valueLakh = 0) {
  const rupees = Math.round(Number(valueLakh || 0) * 100000);
  return `Rs ${rupees.toLocaleString("en-IN", { maximumFractionDigits: 0 })}`;
}

function cleanPaymentMode(value = "") {
  return String(value || "").replace(/\bw(?:ire)\b/gi, "Bank Transfer");
}

function toLakhs(value, unit = "lakhs") {
  const amount = Number(value || 0);
  if (unit === "rupees") return amount / 100000;
  if (unit === "hundreds") return amount / 1000;
  if (unit === "thousands") return amount / 100;
  return amount;
}

function fromLakhs(value, unit = "lakhs") {
  const amount = Number(value || 0);
  if (unit === "rupees") return amount * 100000;
  if (unit === "hundreds") return amount * 1000;
  if (unit === "thousands") return amount * 100;
  return amount;
}

function rupeesToLakhs(value) {
  return Math.max(Number(value || 0), 0) / 100000;
}

function addMonthsToDate(value, months = 1) {
  if (!value) return "";
  const date = new Date(`${value}T00:00:00`);
  if (Number.isNaN(date.getTime())) return "";
  date.setMonth(date.getMonth() + months);
  return date.toISOString().slice(0, 10);
}

function calculateEmiRupees(loanAmount, tenure, annualRate) {
  const principal = Number(loanAmount || 0);
  const months = Number(tenure || 0);
  const rate = Number(annualRate || 0) / 1200;
  if (principal <= 0 || months <= 0) return 0;
  if (rate <= 0) return Math.round(principal / months);
  const factor = Math.pow(1 + rate, months);
  return Math.round((principal * rate * factor) / (factor - 1));
}

function emiStatusForDate(value, paid = false) {
  if (paid) return "Paid";
  if (!value) return "Upcoming";
  const today = new Date();
  const due = new Date(`${value}T00:00:00`);
  today.setHours(0, 0, 0, 0);
  if (Number.isNaN(due.getTime())) return "Upcoming";
  if (due.getTime() === today.getTime()) return "Due Today";
  return due < today ? "Overdue" : "Upcoming";
}

function bookingIsYes(data = {}) {
  return String(data.booking || data.transaction_type || "").toLowerCase() === "yes" ||
    String(data.transaction_type || "").toLowerCase() === "booking";
}

async function loadDatabaseData() {
  try {
    const data = await api.request("bootstrap");
    state.apiReady = true;
    state.bikes = data.bikes.map((bike) => ({
      id: bike.id,
      name: bike.name,
      brand: bike.brand || bikeBrand(bike.name),
      category: bike.category,
      showroom: bike.showroom,
      stock: Number(bike.stock),
      sold: Number(bike.sold || 0),
      price: Number(bike.price),
      purchaseCost: Number(bike.purchase_cost || 0),
      gst: Number(bike.gst_percent || 0),
      repairCharges: Number(bike.repair_charges || 0),
      margin: Number(bike.margin_percent || 0),
      priceUnit: bike.price_unit || "lakhs",
      costUnit: bike.cost_unit || "lakhs",
      status: bike.status,
      vin: bike.chassis_vin || "",
      engine: bike.engine_serial || "",
      plate: bike.plate || "",
      color: bike.color_scheme || "",
      odometer: Number(bike.odometer || 0),
      fuel: bike.fuel_model || "",
      year: bike.model_year || "",
      registrationState: bike.registration_state || "",
      mediaName: bike.media_name || "",
      mediaType: bike.media_type || "",
      mediaData: bike.media_data || "",
      serviceDate: bike.last_service_date || "",
      createdBy: bike.created_by || "",
      createdAt: bike.created_at || "",
      owner: bike.owner || "Motorstock Network",
      insurance: bike.insurance || "Active",
      lowThreshold: Number(bike.low_threshold || 2)
    }));
    state.stores = data.stores.map((store) => ({
      id: store.id,
      name: store.name,
      location: store.location || "",
      tier: store.tier,
      units: Number(store.units),
      revenue: Number(store.revenue),
      rating: Number(store.rating)
    }));
    state.employees = data.employees.map((emp) => ({
      id: emp.emp_id,
      name: emp.name,
      username: emp.username,
      password: emp.password,
      shift: emp.shift,
      role: emp.role,
      branch: emp.branch,
      active: Number(emp.active) === 1,
      frozen: Number(emp.frozen || 0) === 1,
      closed: Number(emp.closed || 0),
      revenue: Number(emp.revenue || 0)
    }));
    state.sales = data.sales.map((sale) => ({
      saleDbId: sale.sale_db_id,
      invoiceId: sale.invoice_id,
      id: sale.transaction_id,
      invoiceNumber: sale.invoice_number || sale.transaction_id,
      transactionType: sale.transaction_type || "",
      booking: sale.booking || "No",
      customer: sale.customer,
      phone: sale.phone || "",
      email: sale.email || "",
      address: sale.address || "",
      city: sale.city || "",
      stateName: sale.state_name || "",
      pincode: sale.pincode || "",
      idType: sale.id_type || "",
      idReference: sale.id_reference || "",
      idProofFileName: sale.id_proof_file_name || "",
      customerGstin: sale.customer_gstin || "",
      customerPan: sale.customer_pan || "",
      billToAddress: sale.bill_to_address || "",
      deliveryAddress: sale.delivery_address || "",
      bikeId: sale.bike_id || "",
      bike: sale.bike,
      category: sale.category || "",
      color: sale.color || "",
      vin: sale.vin || "",
      engine: sale.engine || "",
      year: sale.model_year || "",
      fuel: sale.fuel_type || "",
      odometer: sale.odometer || "",
      showroomPriceLakh: Number(sale.showroom_price_lakh || sale.amount || 0),
      quantity: Number(sale.quantity || 1),
      accessoriesLakh: Number(sale.accessories_lakh || 0),
      insuranceLakh: Number(sale.insurance_lakh || 0),
      registrationLakh: Number(sale.registration_lakh || 0),
      handlingLakh: Number(sale.handling_lakh || 0),
      logisticsLakh: Number(sale.logistics_lakh || 0),
      extendedWarrantyLakh: Number(sale.extended_warranty_lakh || 0),
      otherChargesLakh: Number(sale.other_charges_lakh || 0),
      subtotalLakh: Number(sale.subtotal_lakh || 0),
      discountType: sale.discount_type || "None",
      discountValue: Number(sale.discount_value || 0),
      taxableLakh: Number(sale.taxable_lakh || 0),
      gstAmountLakh: Number(sale.gst_amount_lakh || 0),
      cgstPercent: Number(sale.cgst_percent || 0),
      cgstLakh: Number(sale.cgst_lakh || 0),
      sgstPercent: Number(sale.sgst_percent || 0),
      sgstLakh: Number(sale.sgst_lakh || 0),
      roundOffLakh: Number(sale.round_off_lakh || 0),
      grandTotalLakh: Number(sale.grand_total_lakh || sale.amount || 0),
      amountPaidLakh: Number(sale.amount_paid_lakh || 0),
      balanceLakh: Number(sale.balance_lakh || 0),
      bookingNumber: sale.booking_number || "",
      bookingAmountLakh: Number(sale.booking_amount_lakh || 0),
      bookingDate: sale.booking_date || "",
      bookingStatus: sale.booking_status || "",
      expectedDeliveryDate: sale.expected_delivery_date || "",
      financeRequired: sale.finance_required || "No",
      financeProvider: sale.finance_provider || "",
      financeStatus: sale.finance_status || "",
      deliveryStatus: sale.delivery_status || "",
      actualDeliveryDate: sale.actual_delivery_date || "",
      deliveryLocation: sale.delivery_location || "",
      bikeMediaData: sale.bike_media_data || "",
      bikeMediaType: sale.bike_media_type || "",
      bikeMediaName: sale.bike_media_name || "",
      amount: Number(sale.amount),
      gst: Number(sale.gst_percent || 0),
      discount: Number(sale.discount_lakh || 0),
      status: sale.status,
      payment: sale.payment,
      mode: cleanPaymentMode(sale.mode),
      paymentReference: sale.payment_reference || "",
      paymentDate: sale.payment_date || "",
      paymentHistory: Array.isArray(sale.payment_history) ? sale.payment_history : [],
      branch: sale.branch,
      employee: sale.employee,
      employeeId: sale.employee_emp_id || "",
      loanAmountLakh: Number(sale.loan_amount_lakh || 0),
      downPaymentLakh: Number(sale.down_payment_lakh || 0),
      loanAccountNumber: sale.loan_account_number || "",
      loanApplicationNumber: sale.loan_application_number || "",
      emiAmountLakh: Number(sale.emi_amount_lakh || 0),
      emiStartDate: sale.emi_start_date || "",
      emiDueDate: sale.emi_due_date || "",
      emiDueDay: Number(sale.emi_due_day || 0),
      emiFrequency: sale.emi_frequency || "Monthly",
      numberOfEmis: Number(sale.number_of_emis || 0),
      loanTenureMonths: Number(sale.loan_tenure_months || sale.number_of_emis || 0),
      interestRatePercent: Number(sale.interest_rate_percent || 0),
      emisPaid: Number(sale.emis_paid || 0),
      remainingEmis: Number(sale.remaining_emis || 0),
      emiStatus: sale.emi_status || "",
      nextEmiDueDate: sale.next_emi_due_date || "",
      statusHistory: Array.isArray(sale.status_history) ? sale.status_history : [],
      date: sale.sale_date
    }));
    if (state.user) renderPage();
    return true;
  } catch (error) {
    state.apiReady = false;
    state.databaseError = error.message || "Database connection failed.";
    return false;
  }
}

async function ensureDatabaseReady() {
  if (state.apiReady) return true;
  const connected = await loadDatabaseData();
  if (!connected) showToast(state.databaseError || "Database is not connected.");
  return connected;
}

function normalizeUser(user) {
  return {
    type: user.type,
    name: user.name,
    branch: user.branch || "All Showrooms",
    role: user.role || "Network Admin",
    id: user.emp_id || user.id || "ADM-001",
    username: user.username
  };
}

loadDatabaseData();

setTimeout(() => {
  $("#splash").classList.remove("is-active");
  $("#splash").classList.add("hidden");
  $("#app").classList.remove("hidden");
  $("#loginView").classList.remove("hidden");
  if (demoMode) login(normalizeUser(demoUser));
  refreshIcons();
}, 2300);

$("#adminFill").addEventListener("click", () => {
  $("#email").value = "admin@gmail.com";
  $("#password").value = "admin";
});

$("#demoEntry").addEventListener("click", () => {
  window.location.search = "?demo=1";
});

$("#loginForm").addEventListener("submit", async (event) => {
  event.preventDefault();
  const email = $("#email").value.trim();
  const password = $("#password").value.trim();
  const connected = await ensureDatabaseReady();
  if (!connected) {
    showToast("Database connection is required before login.");
    return;
  }
  try {
    const result = await api.request("login", { username: email, password });
    login(normalizeUser(result.user));
    await loadDatabaseData();
  } catch (error) {
    showToast(error.message || "Database login failed.");
  }
});

$("#logoutBtn").addEventListener("click", () => {
  if (state.user?.type === "staff") {
    const emp = state.employees.find((item) => item.username === state.user.username);
    if (emp) emp.active = false;
  }
  state.user = null;
  $("#workspace").classList.add("hidden");
  $("#loginView").classList.remove("hidden");
  document.body.classList.remove("has-sticky");
  showToast("Logged out successfully.");
});

$("#brandHome").addEventListener("click", () => setPage("dashboard"));

function login(user) {
  state.user = user;
  state.branch = user.type === "staff" ? user.branch : "all";
  state.page = "dashboard";
  $("#loginView").classList.add("hidden");
  $("#workspace").classList.remove("hidden");
  $("#roleLabel").textContent = user.type === "admin" ? "Admin Console" : user.branch;
  if (demoMode) $("#roleLabel").textContent = "Demo · Sample data";
  $("#avatar").textContent = user.name[0];
  renderNav();
  renderPage();
  showToast(`Welcome, ${user.name}.`);
}

function isWithinShift(shift) {
  const hour = new Date().getHours();
  return shift === "A" ? hour >= 10 && hour < 15 : hour >= 16 && hour < 21;
}

function renderNav() {
  $("#nav").innerHTML = navItems[state.user.type].map(([id, icon, label]) => `
    <button class="nav-btn ${state.page === id ? "active" : ""}" data-page="${id}">
      <i data-lucide="${icon}"></i><span>${label}</span>
    </button>
  `).join("");
  document.querySelectorAll(".nav-btn").forEach((btn) => btn.addEventListener("click", () => setPage(btn.dataset.page)));
  refreshIcons();
}

function setPage(page) {
  state.page = page;
  renderNav();
  renderPage();
}

function renderPage() {
  const pageTitles = { inventory: "Sale In", sales: "Sale Out" };
  const title = pageTitles[state.page] || state.page[0].toUpperCase() + state.page.slice(1);
  $("#pageTitle").textContent = title;
  $("#welcomeEyebrow").textContent = state.user.type === "admin" ? "Welcome back, Network Admin" : `${state.user.name} - ${state.user.branch}`;
  document.body.classList.toggle("has-sticky", state.page === "transaction");
  document.body.classList.toggle("dashboard-active", state.page === "dashboard");
  const pages = { dashboard: renderDashboard, inventory: renderInventory, sales: renderSales, emi: renderEmiCalculator, stores: renderStores, billing: renderBilling, profile: renderProfile, transaction: renderTransaction };
  $("#pageContent").innerHTML = pages[state.page]();
  bindPageEvents();
  refreshIcons();
}

function visibleBikes() {
  return state.branch === "all" ? state.bikes : state.bikes.filter((bike) => bike.showroom === state.branch);
}

function visibleSales() {
  return state.branch === "all" ? state.sales : state.sales.filter((sale) => sale.branch === state.branch);
}

function saleDate(sale) {
  const date = sale.date ? new Date(`${sale.date}T00:00:00`) : new Date();
  return Number.isNaN(date.getTime()) ? new Date() : date;
}

function isSaleInFilter(sale) {
  const now = new Date();
  const date = saleDate(sale);
  if (state.filter === "today") return date.toDateString() === now.toDateString();
  if (state.filter === "yesterday") {
    const yesterday = new Date(now);
    yesterday.setDate(now.getDate() - 1);
    return date.toDateString() === yesterday.toDateString();
  }
  if (state.filter === "week") {
    const weekAgo = new Date(now);
    weekAgo.setDate(now.getDate() - 7);
    return date >= weekAgo && date <= now;
  }
  if (state.filter === "month" || state.filter === "1 month") return date.getMonth() === now.getMonth() && date.getFullYear() === now.getFullYear();
  if (state.filter === "year") return date.getFullYear() === now.getFullYear();
  if (state.filter === "custom") {
    const from = state.customFrom ? new Date(`${state.customFrom}T00:00:00`) : null;
    const to = state.customTo ? new Date(`${state.customTo}T23:59:59`) : null;
    return (!from || date >= from) && (!to || date <= to);
  }
  return true;
}

function filteredSales() {
  return visibleSales().filter(isSaleInFilter);
}

function filteredDashboardData() {
  const query = state.search.trim().toLowerCase();
  const bikes = visibleBikes();
  const sales = filteredSales();
  const stores = state.branch === "all" ? state.stores : state.stores.filter((store) => store.name === state.branch);
  if (!query) return { bikes, sales, stores };
  const matches = (values) => values.some((value) => String(value || "").toLowerCase().includes(query));
  return {
    bikes: bikes.filter((bike) => matches([bike.name, bike.category, bike.showroom, bike.status])),
    sales: sales.filter((sale) => matches([sale.id, sale.customer, sale.bike, sale.branch, sale.employee, sale.mode, sale.status])),
    stores: stores.filter((store) => matches([store.name, store.tier]))
  };
}

function storeStats(sales = filteredSales()) {
  const totalUnits = sales.length;
  return state.stores.map((store) => {
    const rows = sales.filter((sale) => sale.branch === store.name);
    const units = rows.length;
    const revenue = rows.reduce((sum, sale) => sum + Number(sale.amount || 0), 0);
    const rating = totalUnits ? Math.round((units / totalUnits) * 100) : 0;
    return { ...store, units, revenue, rating };
  });
}

function bikeBrand(name = "") {
  return String(name || "Bike").trim().split(/\s+/)[0] || "Bike";
}

function purchaseCostForSale(sale) {
  const match = state.bikes.find((bike) => String(bike.id) === String(sale.bikeId)) ||
    state.bikes.find((bike) => bike.name === sale.bike && bike.showroom === sale.branch) ||
    state.bikes.find((bike) => bike.name === sale.bike);
  return toLakhs(match?.purchaseCost || 0, match?.costUnit || "lakhs");
}

function profitForSale(sale) {
  return Number(sale.grandTotalLakh || sale.amount || 0) - purchaseCostForSale(sale);
}

function profitForSales(sales = []) {
  return sales.reduce((sum, sale) => sum + profitForSale(sale), 0);
}

function renderDashboard() {
  const { bikes, sales, stores } = filteredDashboardData();
  const stats = storeStats(sales).filter((store) => state.branch === "all" || store.name === state.branch);
  const stock = bikes.reduce((sum, bike) => sum + Number(bike.stock || 0), 0);
  const sold = sales.length;
  const revenue = sales.reduce((sum, sale) => sum + sale.amount, 0);
  const profit = profitForSales(sales);
  const activeStores = stores.length;
  const periodLabel = state.filter === "today" ? "Sold today" : `Sold in ${state.filter}`;
  return `
    <div class="grid dashboard-page">
      <div class="searchbar"><i data-lucide="search"></i><input id="dashboardSearch" value="${state.search}" placeholder="Search bikes, transactions, or stores..."></div>
      <div class="filters">${filterButtons(state.user.type === "admin" ? ["today","week","month","year","custom"] : ["today","yesterday","week","1 month","custom"])}</div>
      ${dashboardSearchResults({ bikes, sales, stores })}
      <div class="grid dashboard-grid">
        ${metric("gauge", stock, state.user.type === "staff" ? "Bikes in branch inventory" : "Total bikes")}
        ${metric("badge-check", sold, state.user.type === "staff" ? "Bikes sold by employee" : periodLabel)}
        ${metric("indian-rupee", formatMoney(revenue), "Total revenue")}
        ${metric("building-2", activeStores, state.user.type === "staff" ? "Assigned showroom" : "Active stores")}
        ${metric("trending-up", formatMoney(profit), "Profit")}
      </div>
      ${emiReminderPanel(sales)}
      <div class="grid two-col">
        ${lowStockPanel(bikes)}
        ${branchRevenuePanel(stats)}
      </div>
      <div class="grid two-col">
        <section class="card">
          <div class="section-title"><h3>${state.user.type === "staff" ? "Employee Revenue" : "Monthly Revenue"}</h3></div>
          <h2>${formatMoney(revenue)}</h2>
          ${chart(monthlyRevenueSeries(sales))}
        </section>
        <section class="card">
          <div class="section-title"><h3>${state.user.type === "staff" ? "Recent Showroom Transactions" : "Store Performance"}</h3><button class="link-btn" data-page-link="${state.user.type === "staff" ? "sales" : "stores"}">View</button></div>
          <div class="stack">${state.user.type === "staff" ? transactionRows(sales) : storeRows(stats)}</div>
        </section>
      </div>
      <section class="card">
        <div class="section-title"><h3>Recent Transactions</h3><button class="link-btn" data-page-link="sales">View Stream</button></div>
        <div class="stack">${transactionRows(sales)}</div>
      </section>
    </div>`;
}

function lowStockPanel(bikes) {
  const lowStock = bikes
    .filter((bike) => Number(bike.stock || 0) <= Number(bike.lowThreshold || 2))
    .sort((a, b) => Number(a.stock || 0) - Number(b.stock || 0));
  const rows = lowStock.map((bike) => `<button class="low-stock-row" data-bike-detail="${escapeHtml(bike.id)}">
    <span class="avatar-letter"><i data-lucide="alert-triangle"></i></span>
    <span class="low-stock-copy">
      <b>${escapeHtml(bike.name)}</b>
      <small class="muted">${escapeHtml(bikeBrand(bike.name))} - ${escapeHtml(bike.showroom)}</small>
    </span>
    <span class="stock-left"><b>${Number(bike.stock || 0)}</b><small>left</small></span>
  </button>`).join("") || `<p class="muted">No low stock items for this filter.</p>`;
  return `<section class="card">
    <div class="section-title"><h3>Low Stock Items</h3><span class="badge warning">${lowStock.length} Low</span></div>
    <div class="stack">${rows}</div>
  </section>`;
}

function branchRevenuePanel(stores) {
  const maxRevenue = Math.max(...stores.map((store) => Number(store.revenue || 0)), 1);
  const rows = stores.map((store) => `<div class="branch-revenue-row">
    <b>${escapeHtml(store.name)}</b>
    <span class="branch-revenue-track"><span style="width:${Math.max(6, (Number(store.revenue || 0) / maxRevenue) * 100).toFixed(1)}%"></span></span>
    <span>${formatInvoiceMoney(store.revenue)}</span>
  </div>`).join("") || `<p class="muted">No branch revenue for this filter.</p>`;
  return `<section class="card branch-revenue-card">
    <div class="section-title"><h3>Revenue by branch</h3></div>
    <div class="branch-revenue-list">${rows}</div>
  </section>`;
}

function emiReminderPanel(sales) {
  const reminders = sales.filter((sale) => Number(sale.remainingEmis || 0) > 0 && Number(sale.emiAmountLakh || 0) > 0 && /emi/i.test(`${sale.payment || ""} ${sale.financeStatus || ""} ${sale.status || ""}`));
  if (!reminders.length) return "";
  return `<section class="card">
    <div class="section-title"><h3>EMI Reminders</h3><span class="badge warning">${reminders.length} Due</span></div>
    <div class="stack">${reminders.map((sale) => `<div class="transaction-row">
      <div><b>${escapeHtml(sale.customer)}</b><small>${escapeHtml(sale.bike)} - Due ${shortDate(sale.nextEmiDueDate)}</small></div>
      <span>${formatInvoiceMoney(sale.emiAmountLakh)}</span>
      <span class="badge ${statusClass(sale.emiStatus)}">${escapeHtml(sale.emiStatus || emiStatusForDate(sale.nextEmiDueDate))}</span>
      <button class="mini-btn" data-emi-paid="${escapeHtml(sale.id)}">Mark Paid</button>
    </div>`).join("")}</div>
  </section>`;
}

function dashboardSearchResults(data) {
  if (!state.search.trim()) return "";
  const bikeRows = data.bikes.map((bike) => `<button class="compact-result" data-bike-result="${bike.id}"><b>${bike.name}</b><small>${bike.category} - ${bike.showroom}</small></button>`).join("") || `<p class="muted">No bikes found.</p>`;
  const saleRows = data.sales.map((sale) => `<button class="compact-result" data-transaction="${sale.id}"><b>${sale.id}</b><small>${sale.customer} - ${sale.bike}</small></button>`).join("") || `<p class="muted">No transactions found.</p>`;
  const storeRowsHtml = data.stores.map((store) => `<button class="compact-result" data-store="${store.name}"><b>${store.name}</b><small>${store.tier}</small></button>`).join("") || `<p class="muted">No stores found.</p>`;
  return `<section class="card">
    <div class="section-title"><h3>Search Results</h3><span class="badge info">${state.search}</span></div>
    <div class="grid three-col">
      <div class="stack"><h4>Bikes</h4>${bikeRows}</div>
      <div class="stack"><h4>Transactions</h4>${saleRows}</div>
      <div class="stack"><h4>Stores</h4>${storeRowsHtml}</div>
    </div>
  </section>`;
}

function metric(icon, value, label, badge = "") {
  return `<section class="card metric"><div class="metric-icon"><i data-lucide="${icon}"></i></div><div><strong>${value}</strong><small>${label}</small></div>${badge ? `<span class="badge success">${badge}</span>` : ""}</section>`;
}

function filterButtons(items) {
  return items.map((item) => `<button class="chip ${state.filter === item ? "active" : ""}" data-filter="${item}">${item}</button>`).join("") +
    `<input class="date-pair" data-custom-date="from" type="date" value="${state.customFrom}" ${state.filter === "custom" ? "" : "hidden"}><input class="date-pair" data-custom-date="to" type="date" value="${state.customTo}" ${state.filter === "custom" ? "" : "hidden"}>`;
}

function monthlyRevenueSeries(sales) {
  const buckets = [0, 0, 0, 0];
  sales.forEach((sale, index) => {
    const date = sale.date ? new Date(sale.date) : null;
    const bucket = date && !Number.isNaN(date.getTime()) ? Math.min(3, Math.floor((date.getDate() - 1) / 7)) : index % buckets.length;
    buckets[bucket] += Number(sale.amount || 0);
  });
  return buckets;
}

function salesCountSeries(sales) {
  const buckets = [0, 0, 0, 0, 0, 0];
  sales.forEach((sale, index) => {
    const date = sale.date ? new Date(sale.date) : null;
    const bucket = date && !Number.isNaN(date.getTime()) ? Math.min(5, Math.floor(date.getDate() / 5)) : index % buckets.length;
    buckets[bucket] += 1;
  });
  return buckets;
}

function bikeDate(bike) {
  const date = bike.createdAt ? new Date(String(bike.createdAt).replace(" ", "T")) : new Date();
  return Number.isNaN(date.getTime()) ? new Date() : date;
}

function isInStoreFilter(date) {
  const now = new Date();
  if (state.storeFilter === "today") return date.toDateString() === now.toDateString();
  if (state.storeFilter === "week") {
    const weekAgo = new Date(now);
    weekAgo.setDate(now.getDate() - 7);
    return date >= weekAgo && date <= now;
  }
  if (state.storeFilter === "month") return date.getMonth() === now.getMonth() && date.getFullYear() === now.getFullYear();
  if (state.storeFilter === "6 months") {
    const sixMonthsAgo = new Date(now);
    sixMonthsAgo.setMonth(now.getMonth() - 6);
    return date >= sixMonthsAgo && date <= now;
  }
  if (state.storeFilter === "custom") {
    const from = state.storeCustomFrom ? new Date(`${state.storeCustomFrom}T00:00:00`) : null;
    const to = state.storeCustomTo ? new Date(`${state.storeCustomTo}T23:59:59`) : null;
    return (!from || date >= from) && (!to || date <= to);
  }
  return true;
}

function chart(series) {
  const max = Math.max(...series, 1);
  const width = 460;
  const height = 220;
  const points = series.map((value, index) => {
    const x = 22 + index * ((width - 44) / (series.length - 1));
    const y = height - 42 - (value / max) * 142;
    return { x, y };
  });
  const path = smoothPath(points);
  const baseline = height - 42;
  const area = `${path} L ${points[points.length - 1].x.toFixed(1)} ${baseline} L ${points[0].x.toFixed(1)} ${baseline} Z`;
  return `<div class="chart revenue-chart"><svg viewBox="0 0 460 220" preserveAspectRatio="none">
    <defs>
      <linearGradient id="revenueFill" x1="0" x2="0" y1="0" y2="1">
        <stop offset="0%" stop-color="#1d4ed8" stop-opacity=".28"/>
        <stop offset="100%" stop-color="#38bdf8" stop-opacity="0"/>
      </linearGradient>
    </defs>
    ${points.map((point) => `<rect x="${(point.x - 12).toFixed(1)}" y="${point.y.toFixed(1)}" width="24" height="${Math.max(baseline - point.y, 4).toFixed(1)}" rx="8" fill="#dbeafe"/>`).join("")}
    <path d="${area}" fill="url(#revenueFill)"/>
    <path d="${path}" fill="none" stroke="#0f2f68" stroke-width="7" stroke-linecap="round" stroke-linejoin="round"/>
    ${points.map((point) => `<circle cx="${point.x.toFixed(1)}" cy="${point.y.toFixed(1)}" r="6" fill="#2563eb" stroke="#ffffff" stroke-width="3"/>`).join("")}
    <line x1="22" y1="68" x2="438" y2="68" class="chart-grid-line"/>
    <line x1="22" y1="132" x2="438" y2="132" class="chart-grid-line"/>
    ${points.map((point, index) => `<text x="${point.x.toFixed(1)}" y="210" text-anchor="middle">Wk ${index + 1}</text>`).join("")}
  </svg></div>`;
}

function smoothPath(points) {
  if (!points.length) return "";
  return points.reduce((path, point, index) => {
    if (index === 0) return `M ${point.x.toFixed(1)} ${point.y.toFixed(1)}`;
    const prev = points[index - 1];
    const midX = (prev.x + point.x) / 2;
    return `${path} C ${midX.toFixed(1)} ${prev.y.toFixed(1)}, ${midX.toFixed(1)} ${point.y.toFixed(1)}, ${point.x.toFixed(1)} ${point.y.toFixed(1)}`;
  }, "");
}

function storeRows(stores) {
  if (!stores.length) return `<p class="muted">No stores match the current search or filter.</p>`;
  return stores.map((store) => `<button class="store-card" data-store="${store.name}">
    <span class="avatar-letter">${store.name[0]}</span>
    <span><b>${store.name}</b><small class="muted">${store.units} units sold - ${formatMoney(store.revenue)}</small></span>
    <span class="badge ${store.tier === "Platinum" ? "success" : "warning"}">${store.tier}</span>
    <span><b>${store.rating}%</b></span>
  </button>`).join("");
}

function transactionRows(sales) {
  if (!sales.length) return `<p class="muted">No transactions match the current search or filter.</p>`;
  return sales.map((sale) => `<button class="transaction-row" data-transaction="${sale.id}">
    <span class="avatar-letter"><i data-lucide="bike"></i></span>
    <span class="transaction-copy">
      <b>${escapeHtml(sale.bike)}</b>
      <small class="muted">${escapeHtml(sale.customer)} - ${escapeHtml(sale.mode)}</small>
    </span>
    <b class="danger-text">${formatMoney(sale.amount)}</b>
    <span class="badge ${statusClass(sale.status)}">${escapeHtml(sale.status)}</span>
  </button>`).join("");
}

function stockLevel(bike) {
  const stock = Number(bike.stock || 0);
  const low = Number(bike.lowThreshold || 2);
  if (stock <= low) return ["danger", "Low Stock"];
  if (stock <= low * 2) return ["warning", "Medium Stock"];
  return ["success", "Available"];
}

function vehicleImageCell(bike) {
  if (bike.mediaData && /^image\//i.test(bike.mediaType || "")) return `<img class="vehicle-thumb-img" src="${bike.mediaData}" alt="${bike.name}">`;
  if (bike.mediaName) return `<span class="vehicle-thumb"><i data-lucide="${/^video\//i.test(bike.mediaType || "") ? "video" : "image"}"></i></span>`;
  return `<span class="vehicle-thumb"><i data-lucide="bike"></i></span>`;
}

function renderInventory() {
  const query = state.inventorySearch.trim().toLowerCase();
  const matchesInventorySearch = (bike) => {
    if (!query) return true;
    return [bike.name, bike.brand, bike.category, bike.showroom, bike.status, bike.color, bike.year, bike.plate, bike.vin]
      .some((value) => String(value || "").toLowerCase().includes(query));
  };
  const branchOptions = state.stores.map((store) => store.name).filter(Boolean);
  const adminBranchFiltered = state.inventoryBranch === "all" ? state.bikes : state.bikes.filter((bike) => bike.showroom === state.inventoryBranch);
  const adminBikes = adminBranchFiltered.filter(matchesInventorySearch);
  const branchBikes = state.bikes.filter((bike) => bike.showroom === state.branch);
  const staffOwnBikes = (query ? branchBikes : visibleBikes()).filter(matchesInventorySearch);
  const staffOtherBikes = state.bikes.filter((bike) => bike.showroom !== state.branch).filter(matchesInventorySearch);
  const adminTools = state.user.type === "admin" ? `<label class="inline-filter">Branches<select data-inventory-branch><option value="all" ${state.inventoryBranch === "all" ? "selected" : ""}>All Branches</option>${branchOptions.map((branch) => `<option value="${escapeHtml(branch)}" ${state.inventoryBranch === branch ? "selected" : ""}>${escapeHtml(branch)}</option>`).join("")}</select></label>` : "";
  return `<div class="grid">
    <div class="section-title"><h3>${state.branch === "all" ? "Network Sale In" : state.branch + " Sale In"}</h3><button class="primary-btn" data-open="vehicle"><i data-lucide="plus"></i> Add Unit</button></div>
    <div class="inventory-tools">
      <div class="searchbar"><i data-lucide="search"></i><input id="inventorySearch" value="${escapeHtml(state.inventorySearch)}" placeholder="Search inventory by bike, brand, showroom..."></div>
      ${adminTools}
    </div>
    ${state.user.type === "admin" ? inventoryTable("Sale In Bike List", adminBikes, true) : `
      ${inventoryTable("Bikes In Your Showroom", staffOwnBikes, true)}
      ${inventoryTable("Sale In Bike List Of Other Branches", staffOtherBikes, false)}
    `}
  </div>`;
}

function inventoryTable(title, bikes, canEdit) {
  return `<section class="card inventory-table-card">
    <div class="section-title"><h3>${title}</h3><span class="badge info">${bikes.length} Items</span></div>
    <div class="employee-table inventory-table"><table>
      <thead><tr><th>Photo</th><th>Model Name</th><th>Brand</th><th>Category</th><th>Showroom</th><th>Selling Price</th><th>Dealer Cost</th><th>Repair Charges</th><th>Profit</th><th>Stock</th><th>Status</th><th>Action</th></tr></thead>
      <tbody>${bikes.map((bike) => inventoryRow(bike, canEdit)).join("") || `<tr><td colspan="12" class="muted">No sale in items match this search.</td></tr>`}</tbody>
    </table></div>
  </section>`;
}

function inventoryRow(bike, canEdit) {
  const [tone, label] = stockLevel(bike);
  const profit = toLakhs(bike.price, bike.priceUnit) - toLakhs(bike.purchaseCost, bike.costUnit);
  const action = canEdit ? `<button class="mini-btn" data-edit-bike="${bike.id}">Edit</button><button class="mini-btn danger-mini" data-delete-bike="${bike.id}">Delete</button>` : `<span class="badge info">View only</span>`;
  return `<tr data-bike-detail="${bike.id}">
    <td>${vehicleImageCell(bike)}</td>
    <td><b>${escapeHtml(bike.name)}</b></td>
    <td>${escapeHtml(bike.brand || bikeBrand(bike.name))}</td>
    <td>${escapeHtml(bike.category)}</td>
    <td>${escapeHtml(bike.showroom)}</td>
    <td>${formatInventoryRupees(bike.price, bike.priceUnit)}</td>
    <td>${formatInventoryRupees(bike.purchaseCost, bike.costUnit)}</td>
    <td>${formatInventoryRupees(bike.repairCharges || 0, "rupees")}</td>
    <td><b class="${profit >= 0 ? "success-text" : "danger-text"}">${formatInvoiceMoney(profit)}</b></td>
    <td>${escapeHtml(bike.stock)}</td>
    <td><span class="badge ${tone}">${label}</span></td>
    <td><span class="row-actions">${action}</span></td>
  </tr>`;
}

function vehicleDetails(bike) {
  const [tone, label] = stockLevel(bike);
  const profit = toLakhs(bike.price, bike.priceUnit) - toLakhs(bike.purchaseCost, bike.costUnit);
  return `<section class="card">
    <div class="section-title"><h3>${bike.name}</h3><span class="badge ${tone}">${label}</span></div>
    <div class="vehicle-detail-photo">${vehicleImageCell(bike)}</div>
    <div class="data-grid">
      <div><small>Model Name</small><b>${escapeHtml(bike.name)}</b></div><div><small>Brand</small><b>${escapeHtml(bike.brand || bikeBrand(bike.name))}</b></div>
      <div><small>Colour</small><b>${escapeHtml(bike.color || "Not entered")}</b></div><div><small>Chasis No</small><b>${escapeHtml(bike.vin || "Not entered")}</b></div>
      <div><small>Engine CC</small><b>${escapeHtml(bike.engine || "Not entered")}</b></div><div><small>Odometer</small><b>${Number(bike.odometer || 0)} km</b></div>
      <div><small>Fuel Type</small><b>${escapeHtml(bike.fuel || "Petrol")}</b></div><div><small>Dealer Cost</small><b>${formatInventoryRupees(bike.purchaseCost, bike.costUnit)}</b></div>
      <div><small>Selling Price</small><b>${formatInventoryRupees(bike.price, bike.priceUnit)}</b></div><div><small>Repair Charges</small><b>${formatInventoryRupees(bike.repairCharges || 0, "rupees")}</b></div>
      <div><small>Profit</small><b class="${profit >= 0 ? "success-text" : "danger-text"}">${formatInvoiceMoney(profit)}</b></div>
      <div><small>Unit Size</small><b>${escapeHtml(bike.stock)}</b></div><div><small>Low Stock</small><b>${bike.lowThreshold || 2} units</b></div>
      <div><small>Model Year</small><b>${escapeHtml(bike.year || "Not entered")}</b></div><div><small>Plate No</small><b>${escapeHtml(bike.plate || "Not entered")}</b></div>
      <div><small>Registration State</small><b>${escapeHtml(bike.registrationState || "Not entered")}</b></div><div><small>Vehicle Category</small><b>${escapeHtml(bike.category || "Not entered")}</b></div>
      <div><small>Showroom</small><b>${escapeHtml(bike.showroom)}</b></div><div><small>Status</small><b>${escapeHtml(label)}</b></div>
    </div>
  </section>`;
}

const saleStatusOptions = ["Pending", "Booking Confirmed", "Payment Completed", "Balance Pending", "Documents Pending", "Documents Submitted", "Payment Processed", "Down Payment", "Partially Paid", "Paid", "Pending Finance", "Finance Pending", "Finance Approved", "Loan Disbursed", "EMI Active", "Vehicle Allocated", "Processing", "PDI Scheduled", "PDI Completed", "Registration In Process", "Registration Completed", "Delivery Scheduled", "Delivered", "Cancelled"];
const saleTimelineSteps = ["Booking Confirmed", "Payment Processed", "Finance Approved", "PDI Completed", "Registration Completed", "Delivery Scheduled", "Delivered"];
const paymentStatusOptions = ["Pending", "Down Payment", "Partially Paid", "Fully Paid", "Finance Pending", "Finance Approved", "Loan Disbursed", "EMI Active"];
const financeStatusOptions = ["Not Applied", "Documents Pending", "Documents Submitted", "Under Verification", "Finance Pending", "Finance Approved", "Loan Disbursed"];
const emiStatusOptions = ["Upcoming", "Due Today", "Paid", "Overdue"];
const mixedPaymentModes = ["Cash", "UPI", "Debit Card", "Credit Card", "NEFT", "RTGS", "IMPS", "Bank Transfer", "Cheque"];
const paymentStatusOptionsBilling = ["Pending", "Down Payment", "Partially Paid", "Fully Paid", "Finance Pending", "Finance Approved", "Loan Disbursed", "EMI Active"];

function salesData() {
  return state.apiReady ? visibleSales() : [];
}

function saleMatchesDate(sale) {
  const now = new Date();
  const date = saleDate(sale);
  if (state.salesDateFilter === "today") return date.toDateString() === now.toDateString();
  if (state.salesDateFilter === "yesterday") {
    const yesterday = new Date(now);
    yesterday.setDate(now.getDate() - 1);
    return date.toDateString() === yesterday.toDateString();
  }
  if (state.salesDateFilter === "week") {
    const weekAgo = new Date(now);
    weekAgo.setDate(now.getDate() - 7);
    return date >= weekAgo && date <= now;
  }
  if (state.salesDateFilter === "month") return date.getMonth() === now.getMonth() && date.getFullYear() === now.getFullYear();
  if (state.salesDateFilter === "year") return date.getFullYear() === now.getFullYear();
  if (state.salesDateFilter === "custom") {
    const from = state.salesCustomFrom ? new Date(`${state.salesCustomFrom}T00:00:00`) : null;
    const to = state.salesCustomTo ? new Date(`${state.salesCustomTo}T23:59:59`) : null;
    return (!from || date >= from) && (!to || date <= to);
  }
  return true;
}

function filteredSalesPageRows() {
  const query = state.salesSearch.trim().toLowerCase();
  const matches = (values) => values.some((value) => String(value || "").toLowerCase().includes(query));
  return salesData().filter((sale) => {
    const showroomOk = state.salesShowroom === "all" || sale.branch === state.salesShowroom;
    const paymentOk = state.salesPaymentStatus === "all" || sale.payment === state.salesPaymentStatus;
    const statusOk = state.salesStatus === "all" || sale.status === state.salesStatus;
    const vehicleOk = state.salesVehicle === "all" || sale.bike === state.salesVehicle;
    const employeeOk = state.salesEmployee === "all" || sale.employee === state.salesEmployee;
    const searchOk = !query || matches([sale.customer, sale.phone, sale.bike, sale.invoiceNumber, sale.id, sale.vin, sale.employee, sale.branch, sale.mode]);
    return showroomOk && paymentOk && statusOk && vehicleOk && employeeOk && searchOk && saleMatchesDate(sale);
  });
}

function saleSelectOptions(values, selected, allLabel) {
  return [`<option value="all">${allLabel}</option>`, ...values.map((value) => `<option value="${escapeHtml(value)}" ${value === selected ? "selected" : ""}>${escapeHtml(value)}</option>`)].join("");
}

function shortDate(value) {
  const raw = value ? String(value).replace(" ", "T") : "";
  const date = raw ? new Date(raw.includes("T") ? raw : `${raw}T00:00:00`) : null;
  return date && !Number.isNaN(date.getTime()) ? date.toLocaleDateString("en-IN", { day: "2-digit", month: "short", year: "numeric" }) : "Not available";
}

function dateTimeParts(value) {
  const raw = value ? String(value).replace(" ", "T") : "";
  const date = raw ? new Date(raw) : null;
  if (!date || Number.isNaN(date.getTime())) return { date: "Not available", time: "" };
  return {
    date: date.toLocaleDateString("en-IN", { day: "2-digit", month: "short", year: "numeric" }),
    time: date.toLocaleTimeString("en-IN", { hour: "2-digit", minute: "2-digit" })
  };
}

function saleVehicleImage(sale) {
  if (sale.bikeMediaData && /^image\//i.test(sale.bikeMediaType || "")) return `<img class="vehicle-thumb-img" src="${sale.bikeMediaData}" alt="${escapeHtml(sale.bike)}">`;
  return `<span class="vehicle-thumb"><i data-lucide="bike"></i></span>`;
}

function saleInvoiceData(sale) {
  return {
    invoice_number: sale.invoiceNumber,
    transaction_type: sale.transactionType || (sale.booking === "Yes" ? "Booking" : "Vehicle Sale"),
    booking_number: sale.bookingNumber,
    customer: sale.customer,
    phone: sale.phone,
    email: sale.email,
    address: sale.address,
    city: sale.city,
    state_name: sale.stateName,
    pincode: sale.pincode,
    customer_gstin: sale.customerGstin,
    customer_pan: sale.customerPan,
    bill_to_address: sale.billToAddress,
    delivery_address: sale.deliveryAddress,
    bike: sale.bike,
    category: sale.category,
    showroom: sale.branch,
    color: sale.color,
    vin: sale.vin,
    engine: sale.engine,
    year: sale.year,
    fuel: sale.fuel,
    odometer: sale.odometer,
    amount: sale.showroomPriceLakh || sale.amount,
    amount_unit: "lakhs",
    quantity: sale.quantity || 1,
    id_type: sale.idType,
    id_reference: sale.idReference,
    id_proof_file_name: sale.idProofFileName,
    accessories: sale.accessoriesLakh,
    insurance_amount: sale.insuranceLakh,
    registration: sale.registrationLakh,
    handling: sale.handlingLakh,
    logistics: sale.logisticsLakh,
    extended_warranty: sale.extendedWarrantyLakh,
    other_charges: sale.otherChargesLakh,
    discount_type: sale.discountType,
    discount: sale.discount,
    discount_lakh: sale.discount,
    taxable_lakh: sale.taxableLakh,
    gst: sale.gst,
    gst_amount_lakh: sale.gstAmountLakh,
    cgst_percent: sale.cgstPercent,
    cgst_lakh: sale.cgstLakh,
    sgst_percent: sale.sgstPercent,
    sgst_lakh: sale.sgstLakh,
    round_off_lakh: sale.roundOffLakh,
    grand_total_lakh: sale.grandTotalLakh || sale.amount,
    amount_paid_lakh: sale.amountPaidLakh,
    balance_lakh: sale.balanceLakh,
    booking_amount_lakh: sale.bookingAmountLakh,
    payment_mode: sale.mode,
    payment_status: sale.payment,
    payment_reference: sale.paymentReference,
    finance_required: sale.financeRequired,
    finance_provider: sale.financeProvider,
    finance_status: sale.financeStatus,
    delivery_status: sale.status,
    employee: sale.employee,
    invoice_date: sale.date
  };
}

function renderSales() {
  const allSales = salesData();
  const rows = filteredSalesPageRows();
  const totalPages = Math.max(Math.ceil(rows.length / Number(state.salesPageSize || 10)), 1);
  state.salesPage = Math.min(Math.max(Number(state.salesPage || 1), 1), totalPages);
  const start = (state.salesPage - 1) * Number(state.salesPageSize || 10);
  const pageRows = rows.slice(start, start + Number(state.salesPageSize || 10));
  const totalRevenue = rows.reduce((sum, sale) => sum + Number(sale.grandTotalLakh || sale.amount || 0), 0);
  const delivered = rows.filter((sale) => /delivered/i.test(sale.status)).length;
  const notDelivered = rows.length - delivered;
  const showrooms = [...new Set(state.stores.map((store) => store.name).filter(Boolean))];
  const vehicles = [...new Set(allSales.map((sale) => sale.bike).filter(Boolean))];
  const employees = [...new Set(state.employees.map((emp) => emp.name).filter(Boolean))];
  const payments = [...new Set(allSales.map((sale) => sale.payment).filter(Boolean))];
  const statuses = [...new Set([...saleStatusOptions, ...allSales.map((sale) => sale.status).filter(Boolean)])];
  const empty = !pageRows.length ? `<section class="card sales-empty"><h3>NO SALES TRANSACTIONS</h3><p class="muted">Sales transactions will appear here after a vehicle is billed.</p></section>` : "";
  return `<div class="grid sales-page">
    <section class="card sales-filters">
      <div class="sales-filter-top">
        <div><h3>SALES</h3><small class="muted">Filter invoices and live sales totals</small></div>
        <div class="sales-search-export">
          <div class="searchbar sales-search"><i data-lucide="search"></i><input data-sales-filter="salesSearch" value="${escapeHtml(state.salesSearch)}" placeholder="Search sales..."></div>
          <button class="soft-btn" data-sales-export><i data-lucide="download"></i> Export</button>
        </div>
      </div>
      <div class="filters sales-filter-controls">
        <select data-sales-filter="salesDateFilter">
          ${["today", "yesterday", "week", "month", "year", "custom"].map((item) => `<option value="${item}" ${state.salesDateFilter === item ? "selected" : ""}>${item === "week" ? "This Week" : item === "month" ? "This Month" : item === "year" ? "This Year" : item[0].toUpperCase() + item.slice(1)}</option>`).join("")}
        </select>
        <input class="date-pair" data-sales-filter="salesCustomFrom" type="date" value="${state.salesCustomFrom}" ${state.salesDateFilter === "custom" ? "" : "hidden"}>
        <input class="date-pair" data-sales-filter="salesCustomTo" type="date" value="${state.salesCustomTo}" ${state.salesDateFilter === "custom" ? "" : "hidden"}>
        <select data-sales-filter="salesShowroom">${saleSelectOptions(showrooms, state.salesShowroom, "All Showrooms")}</select>
        <select data-sales-filter="salesEmployee">${saleSelectOptions(employees, state.salesEmployee, "All Employees")}</select>
        <select data-sales-filter="salesPaymentStatus">${saleSelectOptions(payments, state.salesPaymentStatus, "All Payment Status")}</select>
        <select data-sales-filter="salesStatus">${saleSelectOptions(statuses, state.salesStatus, "All Sale Status")}</select>
        <select data-sales-filter="salesVehicle">${saleSelectOptions(vehicles, state.salesVehicle, "All Vehicles")}</select>
        <select data-sales-filter="salesPageSize">${[10, 25, 50, 100].map((size) => `<option value="${size}" ${Number(state.salesPageSize) === size ? "selected" : ""}>${size} rows</option>`).join("")}</select>
      </div>
    </section>
    <div class="grid dashboard-grid sales-summary-grid">
      ${metric("badge-check", rows.length, "Total bikes sold")}
      ${metric("indian-rupee", formatInvoiceMoney(totalRevenue), "Total revenue")}
      ${metric("truck", delivered, "Delivered")}
      ${metric("circle-slash", notDelivered, "Not delivered")}
    </div>
    ${empty || `<section class="card sales-table-card">
      <div class="employee-table sales-table"><table>
        <thead><tr><th>Invoice No</th><th>Customer Phone</th><th>Vehicle</th><th>Showroom</th><th>Payment Mode</th><th>Employee</th><th>Date</th><th>Invoice</th><th>Actions</th><th>Amount</th><th>Profit</th></tr></thead>
        <tbody>${pageRows.map((sale, index) => `<tr data-sale-row="${escapeHtml(sale.id)}">
          <td><b>${escapeHtml(sale.invoiceNumber || sale.id)}</b></td>
          <td>${escapeHtml(sale.phone || "Not available")}</td>
          <td>${escapeHtml(sale.bike)}</td>
          <td>${escapeHtml(sale.branch)}</td>
          <td>${escapeHtml(sale.mode || "Not available")}</td>
          <td>${escapeHtml(sale.employee || "Not available")}</td>
          <td>${shortDate(sale.date)}</td>
          <td><button class="mini-btn" data-sale-invoice="${escapeHtml(sale.id)}">Invoice</button></td>
          <td><button class="mini-btn" data-sale-view="${escapeHtml(sale.id)}">View</button></td>
          <td><b>${formatInvoiceMoney(sale.grandTotalLakh || sale.amount)}</b></td>
          <td><b class="${profitForSale(sale) >= 0 ? "success-text" : "danger-text"}">${formatInvoiceMoney(profitForSale(sale))}</b></td>
        </tr>`).join("")}</tbody>
      </table></div>
      <div class="sales-mobile-list">${pageRows.map((sale) => `<article class="sales-mobile-card">
        <div><b>${escapeHtml(sale.customer)}</b><small class="muted">${escapeHtml(sale.bike)}</small></div>
        <b>${formatInvoiceMoney(sale.grandTotalLakh || sale.amount)}</b>
        <span class="badge info">Profit ${formatInvoiceMoney(profitForSale(sale))}</span>
        <small>${escapeHtml(sale.mode || "Payment")} - ${shortDate(sale.date)}</small>
        <div class="row-actions"><button class="mini-btn" data-sale-view="${escapeHtml(sale.id)}">View</button><button class="mini-btn" data-sale-invoice="${escapeHtml(sale.id)}">Invoice</button></div>
      </article>`).join("")}</div>
      <div class="sales-pagination"><button class="mini-btn" data-sales-page="${state.salesPage - 1}" ${state.salesPage <= 1 ? "disabled" : ""}>Previous</button><span>Page ${state.salesPage} of ${totalPages}</span><button class="mini-btn" data-sales-page="${state.salesPage + 1}" ${state.salesPage >= totalPages ? "disabled" : ""}>Next</button></div>
    </section>`}
  </div>`;
}

function saleById(id) {
  return salesData().find((sale) => String(sale.id) === String(id) || String(sale.invoiceNumber) === String(id));
}

function saleWorkflowStatuses(sale) {
  const financeRequired = String(sale.financeRequired || "").toLowerCase() === "yes" || /finance/i.test(sale.mode || "") || Boolean(sale.financeProvider);
  if (financeRequired) return ["Booking Confirmed", "Documents Pending", "Documents Submitted", "Finance Pending", "Finance Approved", "Loan Disbursed", "Delivery Scheduled", "Delivered", "EMI Active"];
  if (/partial|down/i.test(sale.payment || "") || Number(sale.balanceLakh || 0) > 0) return ["Booking Confirmed", "Partially Paid", "Balance Pending", "Delivery Scheduled", "Delivered"];
  return ["Booking Confirmed", "Payment Completed", "Delivery Scheduled", "Delivered"];
}

function saleWorkflowIndex(sale, statuses) {
  const status = String(sale.status || "");
  const payment = String(sale.payment || "");
  const finance = String(sale.financeStatus || "");
  const direct = statuses.findIndex((item) => item.toLowerCase() === status.toLowerCase() || item.toLowerCase() === finance.toLowerCase());
  if (direct >= 0) return direct;
  if (statuses.includes("EMI Active") && /emi/i.test(payment + finance + status)) return statuses.indexOf("EMI Active");
  if (statuses.includes("Loan Disbursed") && /loan disbursed/i.test(payment + finance + status)) return statuses.indexOf("Loan Disbursed");
  if (statuses.includes("Finance Approved") && /finance approved/i.test(payment + finance + status)) return statuses.indexOf("Finance Approved");
  if (statuses.includes("Balance Pending") && Number(sale.balanceLakh || 0) > 0 && /partial|down/i.test(payment)) return statuses.indexOf("Balance Pending");
  if (statuses.includes("Partially Paid") && /partial|down/i.test(payment)) return statuses.indexOf("Partially Paid");
  if (statuses.includes("Payment Completed") && /fully|paid/i.test(payment) && !/partial|down/i.test(payment)) return statuses.indexOf("Payment Completed");
  if (statuses.includes("Delivered") && /delivered/i.test(status)) return statuses.indexOf("Delivered");
  if (statuses.includes("Delivery Scheduled") && /delivery scheduled|ready for delivery/i.test(status)) return statuses.indexOf("Delivery Scheduled");
  return 0;
}

function saleTrackingState(sale) {
  const status = String(sale.status || "").toLowerCase();
  const mode = String(sale.mode || "").toLowerCase();
  const statuses = saleWorkflowStatuses(sale);
  const financeRequired = String(sale.financeRequired || "").toLowerCase() === "yes" || /finance/.test(mode) || Boolean(sale.financeProvider);
  const isCancelled = /cancel/.test(status);
  const progressIndex = saleWorkflowIndex(sale, statuses);
  const complete = statuses.map((_, index) => !isCancelled && index <= progressIndex);
  let current = complete.findIndex((item) => !item);
  if (isCancelled) current = 0;
  if (current < 0) current = complete.length - 1;
  return { complete, current, financeRequired, isCancelled, statuses };
}

function paymentStageLabel(sale) {
  const payment = String(sale.payment || "").toLowerCase();
  if (/paid/.test(payment) && !/partial|down/.test(payment)) return "Full Payment";
  if (/partial/.test(payment)) return "Partially Paid";
  if (/down/.test(payment)) return "Down Payment";
  if (Number(sale.bookingAmountLakh || 0) > 0 && !Number(sale.amountPaidLakh || 0)) return "Booking Amount";
  return sale.payment || "Payment";
}

function trackingMeta(value, completedBy) {
  const when = dateTimeParts(value);
  if (when.date === "Not available") return [];
  return [when.date !== "Not available" ? when.date : "", when.time, completedBy ? `By: ${completedBy}` : ""].filter(Boolean);
}

function trackingLine(label, value) {
  return `<small>${label}</small><b>${escapeHtml(value || "Not available")}</b>`;
}

function trackingHistoryHtml(sale) {
  const history = sale.statusHistory || [];
  if (!history.length) return `<p class="muted">No status history has been recorded yet.</p>`;
  return `<div class="status-history">${history.map((item) => {
    const when = dateTimeParts(item.changed_at);
    return `<div><b>${escapeHtml(item.status || "Status Updated")}</b><small class="muted">${when.date}${when.time ? ` - ${when.time}` : ""}</small><small class="muted">By: ${escapeHtml(item.changed_by || "System")}</small>${item.notes ? `<small class="muted">${escapeHtml(item.notes)}</small>` : ""}</div>`;
  }).join("")}</div>`;
}

function statusHistoryDate(sale, pattern) {
  return statusHistoryEntry(sale, pattern)?.changed_at || "";
}

function statusHistoryBy(sale, pattern) {
  return statusHistoryEntry(sale, pattern)?.changed_by || "";
}

function statusHistoryEntry(sale, pattern) {
  const history = sale.statusHistory || [];
  return [...history].reverse().find((item) => pattern.test(String(item.status || "")));
}

function workflowStageCards(sale, tracking, employee) {
  const stageDates = saleStageDates(sale);
  const dateByStatus = {
    "Booking Confirmed": sale.bookingDate || stageDates.booking || sale.date,
    "Payment Completed": sale.paymentDate || stageDates.payment,
    "Partially Paid": sale.paymentDate || stageDates.payment,
    "Balance Pending": sale.paymentDate || stageDates.payment,
    "Documents Pending": sale.bookingDate || sale.date,
    "Documents Submitted": statusHistoryDate(sale, /documents submitted/i),
    "Finance Pending": statusHistoryDate(sale, /finance pending/i) || sale.bookingDate || sale.date,
    "Finance Approved": statusHistoryDate(sale, /finance approved/i),
    "Loan Disbursed": statusHistoryDate(sale, /loan disbursed/i),
    "Delivery Scheduled": stageDates.deliveryScheduled,
    "Delivered": stageDates.delivered,
    "EMI Active": sale.nextEmiDueDate || statusHistoryDate(sale, /emi active|emi started/i)
  };
  return tracking.statuses.map((status) => {
    const lines = [
      trackingLine("Customer", sale.customer),
      trackingLine("Vehicle", sale.bike),
      trackingLine("Amount", /emi/i.test(status) ? formatInvoiceMoney(sale.emiAmountLakh || 0) : formatInvoiceMoney(sale.grandTotalLakh || sale.amount || 0)),
      trackingLine("Balance", formatInvoiceMoney(sale.balanceLakh || 0))
    ];
    if (/booking/i.test(status)) lines.push(trackingLine("Booking Amount", formatInvoiceMoney(sale.bookingAmountLakh || 0)), trackingLine("Booking ID", sale.bookingNumber || sale.invoiceNumber || sale.id));
    if (/finance|documents|loan/i.test(status)) lines.push(trackingLine("Finance Provider", sale.financeProvider), trackingLine("Loan Amount", formatInvoiceMoney(sale.loanAmountLakh || 0)), trackingLine("Application Number", sale.loanApplicationNumber));
    if (/emi/i.test(status)) lines.push(trackingLine("EMI Amount", formatInvoiceMoney(sale.emiAmountLakh || 0)), trackingLine("Next Due Date", shortDate(sale.nextEmiDueDate)), trackingLine("Remaining EMIs", sale.remainingEmis || "0"));
    return {
      title: status.toUpperCase(),
      status,
      lines,
      meta: trackingMeta(dateByStatus[status], statusHistoryBy(sale, new RegExp(status.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"), "i")) || employee)
    };
  });
}

function saleStageDates(sale) {
  const paymentStatus = String(sale.payment || "").toLowerCase();
  const paymentHistoryDate = sale.paymentHistory?.find((item) => Number(item.amount_lakh || 0) > 0 && item.payment_date)?.payment_date || "";
  const paymentStatusDate = statusHistoryDate(sale, /payment processed|partially paid|paid$/i);
  const financeStatusDate = statusHistoryDate(sale, /finance approved|loan disbursed/i);
  const paymentDate = paymentStatusDate || paymentHistoryDate || (!/^pending$/.test(paymentStatus) && Number(sale.amountPaidLakh || 0) > 0 ? sale.paymentDate : "");
  return {
    booking: sale.bookingDate || statusHistoryDate(sale, /booking confirmed/i) || sale.date || "",
    payment: paymentDate || "",
    finance: financeStatusDate || "",
    vehicle: statusHistoryDate(sale, /vehicle allocated|processing|pdi scheduled|pdi completed|registration|delivery scheduled|delivered/i),
    pdi: statusHistoryDate(sale, /pdi completed/i),
    registration: statusHistoryDate(sale, /registration completed/i),
    deliveryScheduled: sale.expectedDeliveryDate || statusHistoryDate(sale, /delivery scheduled/i),
    delivered: sale.actualDeliveryDate || statusHistoryDate(sale, /^delivered$/i)
  };
}

function stageActionHtml(sale, tracking, index, status) {
  if (!["admin", "staff"].includes(state.user?.type) || tracking.isCancelled) return "";
  const today = new Date().toISOString().slice(0, 10);
  const buttonText = status === "Delivery Scheduled" ? "Schedule" : "Complete";
  const acceptsAmount = /payment|paid|balance|down|emi|loan/i.test(status);
  const suggestedAmount = /emi/i.test(status) && Number(sale.emiAmountLakh || 0) > 0
    ? Math.min(Number(sale.emiAmountLakh || 0), Number(sale.balanceLakh || sale.emiAmountLakh || 0))
    : Number(sale.balanceLakh || 0);
  const isCurrent = index === tracking.current;
  const currentBalance = Number(sale.balanceLakh || 0);
  return `${!isCurrent ? `<button class="mini-btn stage-edit-btn" data-stage-edit="${index}"><i data-lucide="edit-3"></i> Edit</button>` : ""}
  <div class="tracking-stage-action ${isCurrent ? "" : "hidden"}" data-stage-action="${index}">
    <input type="date" data-stage-date="${index}" value="${today}">
    ${acceptsAmount ? `<label class="stage-amount-field"><input type="number" step=".01" min="0" max="${Math.round(suggestedAmount * 100000)}" data-stage-amount="${index}" data-stage-current-balance="${currentBalance}" placeholder="Amount paid (Rs)"><small data-stage-balance-preview="${index}">New balance: ${formatInvoiceMoney(currentBalance)}</small></label>` : ""}
    <input data-stage-notes="${index}" placeholder="Stage note (optional)">
    <button class="primary-btn" data-stage-complete="${escapeHtml(sale.id)}" data-stage-index="${index}" data-stage-status="${escapeHtml(status)}">${buttonText}</button>
  </div>`;
}

function saleTimelineHtml(sale) {
  const tracking = saleTrackingState(sale);
  const employee = sale.employee || sale.salesExecutive || "Not available";
  const paymentLabel = paymentStageLabel(sale);
  const bookingPattern = /booking/i;
  const paymentPattern = /payment|down|paid/i;
  const financePattern = /finance/i;
  const pdiPattern = /pdi/i;
  const registrationPattern = /registration/i;
  const deliveryScheduledPattern = /delivery scheduled/i;
  const deliveredPattern = /^delivered$/i;
  const stageDates = saleStageDates(sale);
  const bookingWhen = stageDates.booking;
  const paymentWhen = stageDates.payment;
  const financeWhen = stageDates.finance;
  const pdiWhen = stageDates.pdi;
  const registrationWhen = stageDates.registration;
  const deliveryScheduledWhen = stageDates.deliveryScheduled;
  const deliveredWhen = stageDates.delivered;
  const legacyStages = [
    {
      title: "BOOKING CONFIRMED",
      status: "Booking Confirmed",
      lines: [
        trackingLine("Booking Date", shortDate(bookingWhen)),
        trackingLine("Booking Amount", formatInvoiceMoney(sale.bookingAmountLakh || 0)),
        trackingLine("Booking ID", sale.bookingNumber || sale.invoiceNumber || sale.id),
        trackingLine("Booked By", employee),
        trackingLine("Showroom", sale.branch)
      ],
      meta: trackingMeta(bookingWhen, statusHistoryBy(sale, bookingPattern) || employee)
    },
    {
      title: "PAYMENT PROCESSED",
      status: "Payment Processed",
      lines: [
        trackingLine("Payment Type", paymentLabel),
        trackingLine("Amount Received", formatInvoiceMoney(Number(sale.amountPaidLakh || 0) + Number(sale.bookingAmountLakh || 0))),
        trackingLine("Payment Date", shortDate(paymentWhen)),
        trackingLine("Payment Mode", sale.mode),
        trackingLine("Receipt Number", sale.paymentReference || "Not Available")
      ],
      meta: trackingMeta(paymentWhen, statusHistoryBy(sale, paymentPattern) || employee)
    },
    tracking.financeRequired ? {
      title: /approved/i.test(sale.financeStatus || sale.status || "") ? "FINANCE APPROVED" : "FINANCE APPLICATION",
      status: "Finance Approved",
      lines: [
        trackingLine("Finance Provider", sale.financeProvider),
        trackingLine("Loan Amount", formatInvoiceMoney(sale.loanAmountLakh || Math.max(Number(sale.balanceLakh || 0), 0))),
        trackingLine("EMI", "Not available"),
        trackingLine("Tenure", "Not available"),
        trackingLine("Application Number", sale.loanApplicationNumber || "Not available"),
        trackingLine("Finance Status", sale.financeStatus || sale.status)
      ],
      meta: trackingMeta(financeWhen, statusHistoryBy(sale, financePattern) || employee)
    } : {
      title: "FINANCE NOT REQUIRED",
      status: "Payment Processed",
      lines: [trackingLine("Finance", "Not Required")],
      meta: trackingMeta(paymentWhen, employee)
    },
    {
      title: "VEHICLE ALLOCATED",
      status: "Vehicle Allocated",
      lines: [
        trackingLine("Vehicle", sale.bike),
        trackingLine("VIN / Chassis", sale.vin),
        trackingLine("Engine", sale.engine),
        trackingLine("Color", sale.color),
        trackingLine("Showroom", sale.branch)
      ],
      meta: trackingMeta(stageDates.vehicle, statusHistoryBy(sale, /vehicle allocated|processing|pdi scheduled|pdi completed|registration|delivery scheduled|delivered/i) || employee)
    },
    {
      title: tracking.complete?.[4] ? "PDI COMPLETED" : "PDI / PRE-DELIVERY INSPECTION",
      status: "PDI Completed",
      lines: [
        trackingLine("PDI Status", tracking.complete[4] ? "Passed" : (/pdi scheduled/i.test(sale.status || "") ? "Scheduled" : "Pending")),
        trackingLine("Inspected By", "Not available"),
        trackingLine("Inspection Result", tracking.complete[4] ? "Inspection Passed" : "Pending"),
        trackingLine("PDI Date", tracking.complete[4] ? shortDate(pdiWhen) : "Not available")
      ],
      meta: tracking.complete[4] ? trackingMeta(pdiWhen, statusHistoryBy(sale, pdiPattern)) : []
    },
    {
      title: tracking.complete[5] ? "REGISTRATION COMPLETED" : "REGISTRATION PENDING",
      status: "Registration Completed",
      lines: [
        trackingLine("Registration Status", tracking.complete[5] ? "Completed" : (/registration in process/i.test(sale.status || "") ? "In Process" : "Pending")),
        trackingLine("RTO", sale.deliveryLocation || sale.city || "Not available"),
        trackingLine("Registration Number", "Not available"),
        trackingLine("Registration Date", tracking.complete[5] ? shortDate(registrationWhen) : "Not available")
      ],
      meta: tracking.complete[5] ? trackingMeta(registrationWhen, statusHistoryBy(sale, registrationPattern)) : []
    },
    {
      title: "DELIVERY SCHEDULED",
      status: "Delivery Scheduled",
      lines: [
        trackingLine("Scheduled Delivery Date", shortDate(deliveryScheduledWhen)),
        trackingLine("Delivery Time", "Not available"),
        trackingLine("Showroom", sale.branch),
        trackingLine("Delivery Executive", "Not available")
      ],
      meta: tracking.complete[6] ? trackingMeta(deliveryScheduledWhen, statusHistoryBy(sale, deliveryScheduledPattern) || employee) : []
    },
    {
      title: "DELIVERED",
      status: "Delivered",
      lines: [
        trackingLine("Delivery Date", shortDate(deliveredWhen)),
        trackingLine("Delivery Time", "Not available"),
        trackingLine("Delivered To", sale.customer || "Customer"),
        trackingLine("Odometer", sale.odometer ? `${sale.odometer} km` : "Not available"),
        trackingLine("Key Handover", tracking.complete[7] ? "Completed" : "Pending"),
        trackingLine("Delivery Challan", tracking.complete[7] ? "Available" : "Pending")
      ],
      meta: tracking.complete[7] ? trackingMeta(deliveredWhen, statusHistoryBy(sale, deliveredPattern) || employee) : []
    }
  ];
  const stages = workflowStageCards(sale, tracking, employee);
  const progressed = tracking.complete.filter(Boolean).length;
  const percent = Math.round((Math.min(progressed, stages.length) / stages.length) * 100);
  const paymentSummary = [
    ["Total Vehicle Price", formatInvoiceMoney(sale.grandTotalLakh || sale.amount)],
    ["Booking Amount", formatInvoiceMoney(sale.bookingAmountLakh || 0)],
    ["Down Payment", formatInvoiceMoney(sale.amountPaidLakh || 0)],
    ["Finance Amount", tracking.financeRequired ? formatInvoiceMoney(sale.loanAmountLakh || Math.max(Number(sale.balanceLakh || 0), 0)) : "Not Applicable"],
    ["Amount Paid", formatInvoiceMoney(Number(sale.amountPaidLakh || 0) + Number(sale.bookingAmountLakh || 0))],
    ["Balance", formatInvoiceMoney(sale.balanceLakh || 0)],
    ["Payment Status", sale.payment || "Not available"],
    ["EMI", tracking.financeRequired ? formatInvoiceMoney(sale.emiAmountLakh || 0) : "Not Applicable"],
    ["Next EMI Due", tracking.financeRequired ? shortDate(sale.nextEmiDueDate) : "Not Applicable"],
    ["Remaining EMIs", tracking.financeRequired ? String(sale.remainingEmis || 0) : "Not Applicable"]
  ];
  return `<div class="sales-tracking">
    <div class="tracking-topline">
      <div><small class="muted">CURRENT STATUS</small><span class="badge ${statusClass(sale.status)}">${escapeHtml(sale.status || "Pending")}</span></div>
      <div><small class="muted">TRANSACTION TRACKING</small><b>${Math.min(progressed, stages.length)}/${stages.length} Completed</b></div>
    </div>
    <div class="tracking-progress"><span style="width:${percent}%"></span></div>
    <div class="tracking-progress-labels">${tracking.statuses.map((label, index) => `<span class="${tracking.complete[index] ? "done" : index === tracking.current ? "current" : ""}">${label.replace("Booking Confirmed", "Booked")}</span>`).join("")}</div>
    <div class="grid two-col sales-tracking-snapshot">
      <div class="tracking-mini-card"><h4>CUSTOMER DETAILS</h4>${trackingLine("Name", sale.customer)}${trackingLine("Phone", sale.phone)}${trackingLine("Email", sale.email)}${trackingLine("Address", [sale.address, sale.city, sale.stateName, sale.pincode].filter(Boolean).join(", "))}</div>
      <div class="tracking-mini-card"><h4>SOLD BY</h4>${trackingLine("Employee", employee)}${trackingLine("Employee ID", sale.employeeId)}${trackingLine("Designation", "Not available")}${trackingLine("Showroom", sale.branch)}</div>
      <div class="tracking-mini-card tracking-vehicle-mini"><h4>VEHICLE DETAILS</h4><div class="sales-vehicle-card">${saleVehicleImage(sale)}<div><b>${escapeHtml(sale.bike || "Not available")}</b><small class="muted">${escapeHtml(sale.category || "Vehicle")}</small></div></div>${trackingLine("Color", sale.color)}${trackingLine("VIN / Chassis", sale.vin)}${trackingLine("Engine Serial", sale.engine)}${trackingLine("Model Year", sale.year)}${trackingLine("Fuel Type", sale.fuel)}${trackingLine("Showroom", sale.branch)}</div>
      <div class="tracking-mini-card"><h4>PAYMENT SUMMARY</h4>${paymentSummary.map(([label, value]) => trackingLine(label, value)).join("")}</div>
    </div>
    <div class="timeline sales-timeline">${stages.map((step, index) => {
      const cls = tracking.isCancelled ? (index === 0 ? "cancelled" : "") : tracking.complete[index] ? "done" : index === tracking.current ? "current" : "pending";
      const icon = tracking.isCancelled && index === 0 ? "x" : tracking.complete[index] ? "check" : index === tracking.current ? "circle-dot" : "clock";
      const statusText = tracking.isCancelled && index === 0 ? "Cancelled" : tracking.complete[index] ? "Completed" : index === tracking.current ? "Current" : "Pending";
      return `<div class="timeline-item ${cls}"><span class="timeline-dot"><i data-lucide="${icon}"></i></span><div class="timeline-body"><div class="tracking-stage-head"><h4>${step.title}</h4><span class="badge ${statusClass(statusText)}">${statusText}</span></div><div class="tracking-stage-lines">${step.lines.join("")}</div>${step.meta.length ? `<div class="tracking-meta">${step.meta.map((item) => `<small>${escapeHtml(item)}</small>`).join("")}</div>` : ""}${stageActionHtml(sale, tracking, index, step.status)}</div></div>`;
    }).join("")}</div>
    <div class="tracking-history"><div class="section-title"><h3>STATUS HISTORY</h3></div>${trackingHistoryHtml(sale)}</div>
  </div>`;
}

function saleDocumentsHtml(sale) {
  const docs = [
    ["Tax Invoice", Boolean(sale.invoiceNumber), "data-sale-invoice"],
    ["Payment Receipt", Number(sale.amountPaidLakh || sale.bookingAmountLakh || 0) > 0, ""],
    ["Insurance", Number(sale.insuranceLakh || 0) > 0, ""],
    ["RTO / RC Document", Number(sale.registrationLakh || 0) > 0, ""],
    ["Delivery Challan", /delivered/i.test(sale.status || ""), ""],
    ["PDI Report", /pdi|registration|delivery|delivered/i.test(sale.status || ""), ""]
  ];
  return docs.map(([name, exists, action]) => `<div class="document-row">
    <span><b>${name}</b><small class="muted">${exists ? "Available" : "Not Available"}</small></span>
    ${exists && action ? `<button class="mini-btn" ${action}="${escapeHtml(sale.id)}"><i data-lucide="download"></i></button>` : `<span class="muted">Not Available</span>`}
  </div>`).join("");
}

function openSaleDetails(id) {
  const sale = saleById(id);
  if (!sale) return showToast("Transaction was not found.");
  const canUpdate = ["admin", "staff"].includes(state.user.type);
  const tracking = saleTrackingState(sale);
  const nextStageLabel = tracking.statuses[tracking.current] || "Complete";
  modalRoot.innerHTML = `<div class="modal-backdrop"><section class="modal-panel sales-detail-modal">
    <div class="modal-head"><h3>${escapeHtml(sale.invoiceNumber || sale.id)}</h3><button class="close-btn" data-close>&times;</button></div>
    <div class="grid two-col sales-detail-grid">
      <section class="card"><div class="section-title"><h3>CUSTOMER</h3></div><div class="data-grid">
        <div><small>Customer Name</small><b>${escapeHtml(sale.customer || "Not available")}</b></div>
        <div><small>Phone</small><b>${escapeHtml(sale.phone || "Not available")}</b></div>
        <div><small>Email</small><b>${escapeHtml(sale.email || "Not available")}</b></div>
        <div><small>GSTIN</small><b>${escapeHtml(sale.customerGstin || "Not available")}</b></div>
        <div><small>Address</small><b>${escapeHtml([sale.address, sale.city, sale.stateName, sale.pincode].filter(Boolean).join(", ") || "Not available")}</b></div>
      </div></section>
      <section class="card"><div class="section-title"><h3>VEHICLE</h3></div><div class="sales-vehicle-card">
        ${saleVehicleImage(sale)}
        <div><b>${escapeHtml(sale.bike || "Not available")}</b><small class="muted">${escapeHtml(sale.category || "Vehicle")}</small></div>
      </div><div class="data-grid">
        <div><small>VIN / Chassis</small><b>${escapeHtml(sale.vin || "Not available")}</b></div>
        <div><small>Engine Number</small><b>${escapeHtml(sale.engine || "Not available")}</b></div>
        <div><small>Color</small><b>${escapeHtml(sale.color || "Not available")}</b></div>
        <div><small>Model Year</small><b>${escapeHtml(sale.year || "Not available")}</b></div>
        <div><small>Fuel Type</small><b>${escapeHtml(sale.fuel || "Not available")}</b></div>
        <div><small>Odometer</small><b>${escapeHtml(sale.odometer || "Not available")}</b></div>
        <div><small>Showroom</small><b>${escapeHtml(sale.branch || "Not available")}</b></div>
        <div><small>Price</small><b>${formatInvoiceMoney(sale.showroomPriceLakh || sale.amount)}</b></div>
      </div></section>
    </div>
    <div class="grid two-col sales-detail-grid">
      <section class="card"><div class="section-title"><h3>PAYMENT DETAILS</h3></div><div class="summary-lines">
        <span><small>Vehicle Price</small><b>${formatInvoiceMoney(sale.showroomPriceLakh || sale.amount)}</b></span>
        <span><small>Discount</small><b>${formatInvoiceMoney(sale.discount)}</b></span>
        <span><small>GST</small><b>${formatInvoiceMoney(sale.gstAmountLakh)}</b></span>
        <span><small>Other Charges</small><b>${formatInvoiceMoney(Number(sale.accessoriesLakh || 0) + Number(sale.insuranceLakh || 0) + Number(sale.registrationLakh || 0) + Number(sale.handlingLakh || 0) + Number(sale.logisticsLakh || 0) + Number(sale.extendedWarrantyLakh || 0) + Number(sale.otherChargesLakh || 0))}</b></span>
        <span class="summary-total"><small>Total Amount</small><b>${formatInvoiceMoney(sale.grandTotalLakh || sale.amount)}</b></span>
        <span><small>Amount Paid</small><b>${formatInvoiceMoney(sale.amountPaidLakh)}</b></span>
        <span><small>Booking Amount</small><b>${formatInvoiceMoney(sale.bookingAmountLakh)}</b></span>
        <span><small>Balance</small><b>${formatInvoiceMoney(sale.balanceLakh)}</b></span>
        <span><small>Payment Mode</small><b>${escapeHtml(sale.mode || "Not available")}</b></span>
        <span><small>Payment Status</small><b>${escapeHtml(sale.payment || "Not available")}</b></span>
      </div></section>
      <section class="card"><div class="section-title"><h3>TRANSACTION DETAILS</h3></div><div class="data-grid">
        <div><small>Invoice Number</small><b>${escapeHtml(sale.invoiceNumber || sale.id)}</b></div>
        <div><small>Transaction ID</small><b>${escapeHtml(sale.id)}</b></div>
        <div><small>Sale Date</small><b>${shortDate(sale.date)}</b></div>
        <div><small>Showroom</small><b>${escapeHtml(sale.branch || "Not available")}</b></div>
        <div><small>Sold By</small><b>${escapeHtml(sale.employee || "Not available")}</b></div>
        <div><small>Employee ID</small><b>${escapeHtml(sale.employeeId || "Not available")}</b></div>
        <div><small>Sale Status</small><b><span class="badge ${statusClass(sale.status)}">${escapeHtml(sale.status)}</span></b></div>
      </div>${canUpdate && !tracking.complete.every(Boolean) ? `<p class="stage-edit-hint">Next editable stage: <b>${escapeHtml(nextStageLabel)}</b></p>` : ""}</section>
    </div>
    <section class="card"><div class="section-title"><h3>TRANSACTION TRACKING</h3></div>${saleTimelineHtml(sale)}</section>
    <section class="card"><div class="section-title"><h3>DOCUMENTS</h3></div><div class="stack">${saleDocumentsHtml(sale)}</div></section>
    <div class="actions-row invoice-modal-actions"><button class="primary-btn" data-sale-invoice="${escapeHtml(sale.id)}"><i data-lucide="file-text"></i> View Invoice</button><button class="soft-btn" data-sale-pdf="${escapeHtml(sale.id)}"><i data-lucide="download"></i> Download PDF</button><button class="soft-btn" data-sale-print="${escapeHtml(sale.id)}"><i data-lucide="printer"></i> Print</button></div>
  </section></div>`;
  bindSalesModalEvents();
  refreshIcons();
}

function openSaleInvoice(id) {
  const sale = saleById(id);
  if (!sale) return showToast("Invoice was not found.");
  const invoice = saleInvoiceData(sale);
  modalRoot.innerHTML = `<div class="modal-backdrop"><section class="modal-panel invoice-preview-modal"><div class="modal-head"><h3>Invoice Preview</h3><button class="close-btn" data-close>&times;</button></div>${invoiceHtml(invoice)}<div class="actions-row invoice-modal-actions"><button class="primary-btn" data-sale-pdf="${escapeHtml(sale.id)}"><i data-lucide="download"></i> Download PDF</button><button class="soft-btn" data-sale-print="${escapeHtml(sale.id)}"><i data-lucide="printer"></i> Print</button><button class="danger-btn" data-close>Close</button></div></section></div>`;
  bindSalesModalEvents();
  refreshIcons();
}

async function updateSaleStatus(id, status = "", stageIndex = "") {
  const select = modalRoot.querySelector("[data-sale-status-select]");
  const dateInput = stageIndex ? modalRoot.querySelector(`[data-stage-date="${stageIndex}"]`) : modalRoot.querySelector("[data-sale-status-date]");
  const amountInput = stageIndex ? modalRoot.querySelector(`[data-stage-amount="${stageIndex}"]`) : null;
  const notesInput = stageIndex ? modalRoot.querySelector(`[data-stage-notes="${stageIndex}"]`) : modalRoot.querySelector("[data-sale-status-notes]");
  const nextStatus = status || select?.value || "";
  if (!nextStatus) return;
  if (!dateInput?.value) return showToast("Please select the completion date.");
  if (amountInput && Number(amountInput.value || 0) < 0) return showToast("Enter a valid payment amount.");
  try {
    await api.request("update_sale_status", {
      transaction_id: id,
      status: nextStatus,
      stage_date: dateInput.value,
      stage_amount: amountInput?.value || "",
      notes: notesInput?.value || `${nextStatus} completed from Sales tracking`,
      username: state.user.username || "",
      user_id: state.user.id || ""
    });
    await loadDatabaseData();
    openSaleDetails(id);
    showToast("Transaction stage updated successfully.");
  } catch (error) {
    showToast(error.message || "Status update failed.");
  }
}

async function markEmiPaid(id) {
  try {
    await api.request("mark_emi_paid", {
      transaction_id: id,
      username: state.user.username || "",
      user_id: state.user.id || ""
    });
    await loadDatabaseData();
    renderPage();
    showToast("EMI payment updated successfully.");
  } catch (error) {
    showToast(error.message || "EMI update failed.");
  }
}

function bindSalesModalEvents() {
  modalRoot.querySelectorAll("[data-close]").forEach((btn) => btn.addEventListener("click", closeModal));
  modalRoot.querySelectorAll("[data-sale-invoice]").forEach((btn) => btn.addEventListener("click", () => openSaleInvoice(btn.dataset.saleInvoice)));
  modalRoot.querySelectorAll("[data-sale-pdf]").forEach((btn) => btn.addEventListener("click", () => {
    const sale = saleById(btn.dataset.salePdf);
    if (sale) downloadInvoice(saleInvoiceData(sale));
  }));
  modalRoot.querySelectorAll("[data-sale-print]").forEach((btn) => btn.addEventListener("click", () => {
    const sale = saleById(btn.dataset.salePrint);
    if (sale) printInvoice(saleInvoiceData(sale));
  }));
  modalRoot.querySelectorAll("[data-sale-status-save]").forEach((btn) => btn.addEventListener("click", () => updateSaleStatus(btn.dataset.saleStatusSave)));
  modalRoot.querySelectorAll("[data-stage-edit]").forEach((btn) => btn.addEventListener("click", () => {
    modalRoot.querySelector(`[data-stage-action="${btn.dataset.stageEdit}"]`)?.classList.remove("hidden");
    btn.classList.add("hidden");
  }));
  modalRoot.querySelectorAll("[data-stage-amount]").forEach((input) => input.addEventListener("input", () => {
    const balance = Number(input.dataset.stageCurrentBalance || 0);
    const paid = rupeesToLakhs(input.value || 0);
    const preview = modalRoot.querySelector(`[data-stage-balance-preview="${input.dataset.stageAmount}"]`);
    if (preview) preview.textContent = `New balance: ${formatInvoiceMoney(Math.max(balance - paid, 0))}`;
  }));
  modalRoot.querySelectorAll("[data-stage-complete]").forEach((btn) => btn.addEventListener("click", () => updateSaleStatus(btn.dataset.stageComplete, btn.dataset.stageStatus, btn.dataset.stageIndex)));
}

function exportSalesCsv() {
  const rows = filteredSalesPageRows();
  if (!rows.length) return showToast("No sales to export.");
  const header = ["Invoice No", "Customer Phone", "Vehicle", "Showroom", "Payment Mode", "Employee", "Date", "Amount", "Profit"];
  const csv = [header, ...rows.map((sale) => [sale.invoiceNumber, sale.phone, sale.bike, sale.branch, sale.mode, sale.employee, sale.date, Math.round(Number(sale.grandTotalLakh || sale.amount || 0) * 100000), Math.round(profitForSale(sale) * 100000)])].map((row) => row.map((cell) => `"${String(cell ?? "").replace(/"/g, '""')}"`).join(",")).join("\n");
  const link = document.createElement("a");
  link.href = URL.createObjectURL(new Blob([csv], { type: "text/csv" }));
  link.download = `motostock-sales-${new Date().toISOString().slice(0, 10)}.csv`;
  link.click();
  URL.revokeObjectURL(link.href);
}

function renderEmiCalculator() {
  const bikes = visibleBikes().length ? visibleBikes() : state.bikes;
  const selected = bikes.find((bike) => String(bike.id) === String(state.emiBikeId)) || bikes[0];
  if (selected && String(state.emiBikeId) !== String(selected.id)) state.emiBikeId = String(selected.id);
  const price = selected ? Math.round(fromLakhs(toLakhs(selected.price, selected.priceUnit), "rupees")) : 0;
  if (state.emiDownPayment === null || state.emiDownPayment > price) state.emiDownPayment = Math.round(price * 0.15);
  const downPayment = Math.min(Number(state.emiDownPayment || 0), price);
  const loanAmount = Math.max(price - downPayment, 0);
  const emi = calculateEmiRupees(loanAmount, state.emiTenure, state.emiInterestRate);
  const totalPayable = emi * Number(state.emiTenure || 0);
  const interest = Math.max(totalPayable - loanAmount, 0);
  const maxDown = Math.max(price, 100000);
  return `<div class="emi-page">
    <section class="card emi-details-card">
      <div class="section-title"><div><h3>Loan Details</h3><small class="muted">Select a bike and tune finance inputs</small></div><span class="badge info">${selected ? escapeHtml(selected.showroom) : "Inventory"}</span></div>
      <label>Bike Model
        <select data-emi-input="emiBikeId">${bikes.map((bike) => `<option value="${escapeHtml(bike.id)}" ${String(state.emiBikeId) === String(bike.id) ? "selected" : ""}>${escapeHtml(bike.name)} - ${escapeHtml(bike.showroom)}</option>`).join("")}</select>
      </label>
      <label>On-road Price
        <input type="text" value="${formatInvoiceMoney(price / 100000)}" readonly>
      </label>
      ${emiSlider("Down Payment", "emiDownPayment", downPayment, 0, maxDown, 5000, formatInvoiceMoney(downPayment / 100000))}
      ${emiSlider("Interest Rate", "emiInterestRate", state.emiInterestRate, 0, 24, 0.1, `${Number(state.emiInterestRate).toFixed(1)}%`)}
      ${emiSlider("Tenure", "emiTenure", state.emiTenure, 6, 84, 1, `${state.emiTenure} months`)}
    </section>
    <aside class="emi-side">
      <section class="card emi-result-card">
        <small>Monthly EMI</small>
        <strong>${formatInvoiceMoney(emi / 100000)}</strong>
        <span>${escapeHtml(selected?.name || "Select a bike")}</span>
      </section>
      <section class="card emi-breakdown-card">
        <div class="section-title"><h3>Breakdown</h3></div>
        <div class="data-grid">
          <div><small>Loan Amount</small><b>${formatInvoiceMoney(loanAmount / 100000)}</b></div>
          <div><small>Total Interest</small><b>${formatInvoiceMoney(interest / 100000)}</b></div>
          <div><small>Total Amount Payable</small><b>${formatInvoiceMoney(totalPayable / 100000)}</b></div>
          <div><small>Down Payment</small><b>${formatInvoiceMoney(downPayment / 100000)}</b></div>
        </div>
      </section>
    </aside>
  </div>`;
}

function emiSlider(label, key, value, min, max, step, display) {
  return `<label class="emi-slider">${label}<span>${display}</span>
    <input data-emi-input="${key}" type="range" min="${min}" max="${max}" step="${step}" value="${value}">
  </label>`;
}

function renderStores() {
  if (!state.selectedStore) {
    return `<div class="grid">
      <div class="section-title"><h3>Stores</h3><button class="primary-btn" data-open="store"><i data-lucide="plus"></i> Add Showroom</button></div>
      <section class="store-quick-grid">${state.stores.map((store) => `<button class="store-quick-card" data-store="${store.name}"><i data-lucide="building-2"></i><b>${store.name}</b></button>`).join("")}</section>
    </div>`;
  }
  const selected = state.selectedStore;
  const employees = state.employees.filter((emp) => emp.branch === selected);
  const store = storeStats(visibleSales()).find((item) => item.name === selected) || state.stores.find((item) => item.name === selected);
  const storeBikes = state.bikes.filter((bike) => bike.showroom === selected);
  const storeSales = visibleSales().filter((sale) => sale.branch === selected);
  const selectedEmployee = state.selectedEmployeeId ? employees.find((emp) => emp.id === state.selectedEmployeeId) : null;
  const filteredStoreSales = storeSales.filter((sale) => isInStoreFilter(saleDate(sale)));
  const filteredStoreBikes = storeBikes.filter((bike) => isInStoreFilter(bikeDate(bike)));
  const available = storeBikes.reduce((sum, bike) => sum + Number(bike.stock || 0), 0);
  const sold = filteredStoreSales.length;
  const revenue = filteredStoreSales.reduce((sum, sale) => sum + Number(sale.amount || 0), 0);
  return `<div class="grid">
    <div class="section-title"><button class="soft-btn" data-back-stores><i data-lucide="arrow-left"></i> Back</button><button class="primary-btn" data-open="employee"><i data-lucide="user-plus"></i> Add Employee</button></div>
    <section class="card">
      <div class="section-title"><div><h3>${selected}</h3><small class="muted">${store?.location || "Showroom location"}</small></div><span class="badge ${state.apiReady ? "success" : "warning"}">${state.apiReady ? "Database Data" : "Database Unavailable"}</span></div>
      <div class="filters">${storeFilterButtons()}</div>
      <div class="employee-table"><table>
        <thead><tr><th>Employee Name</th><th>Username</th><th>Password</th><th>Shift</th><th>Status</th><th>Role</th><th>Actions</th></tr></thead>
        <tbody>${employees.map((emp) => `<tr class="${emp.active ? "active-employee" : ""}" data-employee-row="${emp.id}">
          <td><b>${emp.name}</b></td>
          <td>${emp.username}</td>
          <td><span class="password-cell"><input id="pw-${escapeHtml(emp.id)}" type="password" value="${escapeHtml(emp.password)}" readonly><button class="icon-btn" type="button" data-toggle-password="pw-${escapeHtml(emp.id)}" aria-label="Show password"><i data-lucide="eye"></i></button></span></td>
          <td>Shift ${emp.shift}</td>
          <td><span class="badge ${emp.frozen ? "danger" : emp.active ? "success" : "info"}">${emp.frozen ? "Frozen" : emp.active ? "Active" : "Inactive"}</span></td>
          <td>${emp.role}</td>
          <td><span class="row-actions"><button class="mini-btn" data-edit-employee="${emp.id}">Edit</button><button class="mini-btn ${emp.frozen ? "" : "danger-mini"}" data-toggle-freeze-employee="${emp.id}">${emp.frozen ? "Resume" : "Freeze"}</button><button class="mini-btn danger-mini" data-delete-employee="${emp.id}">Delete</button></span></td>
        </tr>`).join("")}</tbody>
      </table></div>
    </section>
    ${selectedEmployee ? employeePerformance(selectedEmployee, filteredStoreSales, filteredStoreBikes) : ""}
    <section class="card">
      <div class="section-title"><h3>${selected} Performance Report</h3><span class="badge info">${state.storeFilter}</span></div>
      <div class="grid dashboard-grid">
        ${metric("bike", available, "Total bikes available")}
        ${metric("badge-check", sold, "Total bikes sold")}
        ${metric("indian-rupee", formatMoney(revenue), "Total revenue generated")}
        ${metric("upload-cloud", filteredStoreBikes.length, "Inventory uploaded in filter")}
      </div>
    </section>
  </div>`;
}

function storeFilterButtons() {
  return ["today", "week", "month", "6 months", "custom"].map((item) => `<button class="chip ${state.storeFilter === item ? "active" : ""}" data-store-filter="${item}">${item}</button>`).join("") +
    `<input class="date-pair" data-store-custom-date="from" type="date" value="${state.storeCustomFrom}" ${state.storeFilter === "custom" ? "" : "hidden"}><input class="date-pair" data-store-custom-date="to" type="date" value="${state.storeCustomTo}" ${state.storeFilter === "custom" ? "" : "hidden"}>`;
}

function employeePerformance(employee, storeSales, storeBikes) {
  const sales = storeSales.filter((sale) => sale.employee === employee.name);
  const uploads = storeBikes.filter((bike) => bike.createdBy === employee.name);
  const revenue = sales.reduce((sum, sale) => sum + Number(sale.amount || 0), 0);
  const saleList = sales.map((sale) => `<tr><td>${sale.bike}</td><td>${sale.customer}</td><td>${formatMoney(sale.amount)}</td><td><span class="badge ${statusClass(sale.status)}">${sale.status}</span></td><td>${sale.payment}</td></tr>`).join("") || `<tr><td colspan="5" class="muted">No bikes sold for this filter.</td></tr>`;
  return `<section class="card">
    <div class="section-title"><h3>${employee.name} Performance</h3><span class="badge info">${state.storeFilter}</span></div>
    <div class="grid dashboard-grid">
      ${metric("badge-check", sales.length, "Bikes sold by employee")}
      ${metric("indian-rupee", formatMoney(revenue), "Revenue closed")}
      ${metric("upload-cloud", uploads.length, "Bikes uploaded to inventory")}
      ${metric("list-checks", sales.filter((sale) => /delivered/i.test(sale.status)).length, "Delivered bikes")}
    </div>
    <div class="employee-table"><table>
      <thead><tr><th>Bike sold</th><th>Customer</th><th>Amount</th><th>Status</th><th>Payment</th></tr></thead>
      <tbody>${saleList}</tbody>
    </table></div>
  </section>`;
}

function escapeHtml(value) {
  return String(value ?? "").replace(/[&<>"']/g, (char) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[char]));
}

function selectedBillingBike() {
  const name = state.billingDraft?.bike;
  const color = state.billingDraft?.color;
  const id = state.billingDraft?.bike_id;
  const showroom = state.billingDraft?.showroom;
  const bikes = state.bikes;
  return bikes.find((bike) => String(bike.id) === String(id) && (!name || bike.name === name)) ||
    bikes.find((bike) => bike.name === name && (!showroom || bike.showroom === showroom) && (!color || (bike.color || "Not specified") === color)) ||
    bikes.find((bike) => bike.name === name && (!showroom || bike.showroom === showroom)) ||
    bikes.find((bike) => bike.name === name);
}

function billingShowroom() {
  return state.billingDraft?.showroom || (state.user?.type === "staff" ? state.user.branch : "");
}

function billingBranchBikes() {
  const showroom = billingShowroom();
  return showroom ? state.bikes.filter((bike) => bike.showroom === showroom) : visibleBikes();
}

function billingCatalogBikes() {
  return state.bikes;
}

function billingBikeOptions() {
  const showroom = billingShowroom() || state.user?.branch || "";
  const own = state.bikes.filter((bike) => !showroom || bike.showroom === showroom);
  const other = state.bikes.filter((bike) => showroom && bike.showroom !== showroom);
  return [...own, ...other];
}

function billingBikeOptionLabel(bike, activeShowroom = billingShowroom()) {
  const stock = Number(bike.stock || 0);
  const showroom = bike.showroom || "Unassigned showroom";
  const branchText = activeShowroom && showroom !== activeShowroom ? "booking only" : `${stock} in stock`;
  return `${bike.name} - ${showroom} (${branchText})`;
}

function billingStockForBike(bike = {}, showroom = billingShowroom()) {
  if (!bike?.name || !showroom) return Number(bike?.stock || 0);
  return state.bikes
    .filter((item) => item.name === bike.name && item.showroom === showroom && (!bike.color || (item.color || "Not specified") === (bike.color || "Not specified")))
    .reduce((sum, item) => sum + Number(item.stock || 0), 0);
}

function billingSelectedBikeId() {
  return state.billingDraft?.bike_id || selectedBillingBike()?.id || "";
}

function branchBikeByName(name) {
  const normalized = String(name || "").trim().toLowerCase();
  if (!normalized) return null;
  return billingBranchBikes().find((bike) => bike.name.toLowerCase() === normalized) || null;
}

function billingStockFor(vehicleName, color) {
  return billingColors(vehicleName).find((item) => item.color === color)?.stock || 0;
}

function bookingValueForBike(bike = {}, color = "") {
  if (!bike.name) return "No";
  return Number(billingStockFor(bike.name, color || bike.color || "Not specified")) > 0 ? "No" : "Yes";
}

function nextInvoiceNumber() {
  if (state.lastInvoice?.invoice_number) return state.lastInvoice.invoice_number;
  if (!state.billingInvoiceNumber) state.billingInvoiceNumber = `INV-${new Date().getFullYear()}-${Math.floor(100000 + Math.random() * 899999)}`;
  return state.billingInvoiceNumber;
}

function nextBookingNumber() {
  if (state.lastInvoice?.booking_number) return state.lastInvoice.booking_number;
  if (!state.billingBookingNumber) state.billingBookingNumber = `BKG-${new Date().getFullYear()}-${Math.floor(100000 + Math.random() * 899999)}`;
  return state.billingBookingNumber;
}

function billingDefaults(bike = {}) {
  const now = new Date();
  const booking = bookingValueForBike(bike);
  return {
    customer_type: "Individual",
    customer: "",
    phone: "",
    email: "",
    address: "",
    city: "",
    state_name: bike.registrationState || "",
    pincode: "",
    id_type: "",
    id_reference: "",
    id_proof_file_name: "",
    id_proof_file_data: "",
    customer_gstin: "",
    customer_pan: "",
    relation_name: "",
    bill_to_address: "",
    delivery_address: "",
    bike_id: bike.id || "",
    bike: bike.name || "",
    category: bike.category || "",
    showroom: bike.showroom || "",
    color: bike.color || "",
    vin: bike.vin || "",
    engine: bike.engine || "",
    year: bike.year || "",
    fuel: bike.fuel || "",
    odometer: bike.odometer || "",
    amount_unit: bike.priceUnit || "lakhs",
    amount: Number(bike.price || 0).toFixed(2),
    quantity: "1",
    accessories: "0",
    insurance_amount: "0",
    registration: "0",
    handling: "0",
    logistics: "0",
    extended_warranty: "0",
    other_charges: "0",
    discount_type: "None",
    discount_percent: "0",
    discount: "0",
    gst: Number(bike.gst || 28),
    booking,
    transaction_type: booking === "Yes" ? "Booking" : "Vehicle Sale",
    payment_status: "Pending",
    payment_mode: "UPI",
    amount_paid: "0",
    payment_reference: "",
    payment_date: now.toISOString().slice(0, 10),
    balance_amount: "0",
    booking_number: booking === "Yes" ? nextBookingNumber() : "",
    booking_amount: "0",
    booking_date: now.toISOString().slice(0, 10),
    delivery_date: "",
    booking_status: "Booking Confirmed",
    finance_required: "No",
    finance_provider: "",
    loan_account_number: "",
    loan_amount: "0",
    down_payment: "0",
    loan_tenure_months: "12",
    interest_rate: "0",
    loan_application_number: "",
    finance_status: "Not Applied",
    emi_amount: "0",
    emi_start_date: "",
    emi_due_date: "",
    emi_due_day: "",
    emi_frequency: "Monthly",
    number_of_emis: "0",
    total_emis: "0",
    emis_paid: "0",
    remaining_emis: "0",
    emi_status: "Upcoming",
    next_emi_due_date: "",
    delivery_status: "Pending",
    actual_delivery_date: "",
    delivery_location: bike.showroom || "",
    sales_executive: state.user?.role || "",
    ...(state.billingDraft || {})
  };
}

function billingColors(vehicleName) {
  const showroom = billingShowroom();
  const matches = state.bikes.filter((bike) => bike.name === vehicleName && (!showroom || bike.showroom === showroom));
  const grouped = new Map();
  matches.forEach((bike) => {
    const color = bike.color || "Not specified";
    grouped.set(color, (grouped.get(color) || 0) + Number(bike.stock || 0));
  });
  const stocked = [...grouped.entries()]
    .map(([color, stock]) => ({ color, stock }))
    .sort((a, b) => Number(b.stock > 0) - Number(a.stock > 0) || a.color.localeCompare(b.color));
  const existing = new Set(stocked.map((item) => item.color));
  const unavailable = colors.filter((color) => !existing.has(color)).map((color) => ({ color, stock: 0 }));
  return [...stocked, ...unavailable];
}

function billingSection(title, fields) {
  return `<div class="form-section"><h4>${title}</h4>${fields.map(([name, label, value, options]) => billingField(name, label, value, options || {})).join("")}</div>`;
}

function billingField(name, label, value = "", options = {}) {
  const attrs = [
    options.required ? "required" : "",
    options.readonly ? "readonly" : "",
    options.list ? `list="${options.list}"` : "",
    options.className ? `class="${options.className}"` : "",
    options.step ? `step="${options.step}"` : "",
    options.type ? `type="${options.type}"` : "",
    options.min !== undefined ? `min="${options.min}"` : "",
    options.accept ? `accept="${options.accept}"` : ""
  ].filter(Boolean).join(" ");
  if (options.textarea) return `<label>${label}<textarea name="${name}" ${attrs}>${escapeHtml(value)}</textarea></label>`;
  if (options.select) {
    return `<label>${label}<select name="${name}" ${attrs}>${options.select.map((item) => {
      const optionValue = typeof item === "object" ? item.value : item;
      const optionLabel = typeof item === "object" ? item.label : item;
      return `<option value="${escapeHtml(optionValue)}" ${String(optionValue) === String(value) ? "selected" : ""}>${escapeHtml(optionLabel || "Select")}</option>`;
    }).join("")}</select></label>`;
  }
  const valueAttr = options.type === "file" ? "" : `value="${escapeHtml(value)}"`;
  return `<label>${label}<input name="${name}" ${valueAttr} ${attrs}></label>`;
}

function billingPaymentStatusFor(totals, data = {}) {
  const financeRequired = data.finance_required === "Yes";
  const financeStatus = data.finance_status || "Not Applied";
  if (financeRequired) {
    if (financeStatus === "EMI Active") return "EMI Active";
    if (["Loan Disbursed", "Completed"].includes(financeStatus)) return "Loan Disbursed";
    if (financeStatus === "Finance Approved") return "Finance Approved";
    return "Finance Pending";
  }
  if (data.booking === "No" && data.payment_status === "Fully Paid") return "Fully Paid";
  const paid = Number(totals.booking_amount_lakh || 0) + Number(totals.amount_paid_lakh || 0);
  if (paid <= 0) return "Pending";
  if (paid >= Number(totals.grand_total_lakh || 0) - 0.00001) return "Fully Paid";
  return Number(totals.booking_amount_lakh || 0) > 0 && Number(totals.amount_paid_lakh || 0) <= 0 ? "Down Payment" : "Partially Paid";
}

function billingVisibilityClass(visible) {
  return visible ? "is-visible" : "is-hidden";
}

function mixedPaymentsHtml(draft) {
  return `<div class="form-section mixed-payment-fields ${draft.payment_mode === "Mixed Payment" ? "is-visible" : "is-hidden"}">
    <h4>Mixed Payment Methods</h4>
    ${mixedPaymentModes.map((mode) => {
      const key = `mixed_${mode.toLowerCase().replace(/\s+/g, "_")}`;
      return billingField(key, `${mode} (Rs)`, draft[key] || "0", { type: "number", step: ".01", min: "0" });
    }).join("")}
  </div>`;
}

function financeEmiHtml(draft) {
  return `<div class="form-section finance-emi-fields ${draft.finance_required === "Yes" ? "is-visible" : "is-hidden"}">
    <h4>EMI Details</h4>
    ${billingField("down_payment", "Down Payment (Rs)", draft.down_payment, { type: "number", step: ".01", min: "0" })}
    ${billingField("loan_tenure_months", "Loan Tenure", draft.loan_tenure_months || "12", { select: ["12", "24", "36", "48"] })}
    ${billingField("interest_rate", "Interest Rate (%)", draft.interest_rate, { type: "number", step: ".01", min: "0" })}
    ${billingField("emi_amount", "EMI Amount (Rs)", draft.emi_amount, { type: "number", step: ".01", min: "0" })}
    ${billingField("emi_start_date", "EMI Start Date", draft.emi_start_date, { type: "date" })}
    ${billingField("emi_due_day", "EMI Due Day", draft.emi_due_day, { type: "number", step: "1", min: "1" })}
    ${billingField("total_emis", "Total EMIs", draft.total_emis || draft.number_of_emis, { type: "number", step: "1", min: "0" })}
    ${billingField("emis_paid", "EMIs Paid", draft.emis_paid, { type: "number", step: "1", min: "0" })}
    ${billingField("remaining_emis", "Remaining EMIs", draft.remaining_emis, { type: "number", step: "1", min: "0", readonly: true })}
    ${billingField("next_emi_due_date", "Next EMI Due Date", draft.next_emi_due_date, { type: "date" })}
    ${billingField("emi_status", "EMI Status", draft.emi_status || "Upcoming", { select: emiStatusOptions })}
  </div>`;
}

function renderBilling() {
  const bikes = billingBranchBikes();
  const selectedBike = selectedBillingBike() || bikes[0] || {};
  const draft = billingDefaults(selectedBike);
  const bikeOptions = billingBikeOptions();
  const colorsForBike = billingColors(draft.bike);
  const colorOptions = colorsForBike.length ? colorsForBike : colors.map((color) => ({ color, stock: 0 }));
  if (draft.color && !colorOptions.some((item) => (item.color || "Not specified") === draft.color)) {
    colorOptions.unshift({ color: draft.color, stock: billingStockForBike({ ...selectedBike, color: draft.color }) });
  }
  const showroomOptions = [...new Set(state.stores.map((store) => store.name).filter(Boolean))];
  const roleOptions = [...new Set([state.user.role, ...state.employees.map((emp) => emp.role)].filter(Boolean))];
  const now = new Date();
  const currentShowroom = draft.showroom || (state.user.type === "staff" ? state.user.branch : showroomOptions[0] || "");
  const branchStock = billingStockForBike({ ...selectedBike, color: draft.color || selectedBike.color || "Not specified" }, currentShowroom);
  const outsideBranch = selectedBike?.showroom && currentShowroom && selectedBike.showroom !== currentShowroom;
  const requestedQty = Math.max(Number(draft.quantity || 1), 1);
  const stockBlocked = requestedQty > Number(branchStock || 0);
  const billMode = outsideBranch || stockBlocked || draft.booking === "Yes" ? "Booking" : "Vehicle Sale";
  const effectiveDraft = { ...draft, booking: billMode === "Booking" ? "Yes" : "No", transaction_type: billMode };
  const totals = calculateBillingTotals(effectiveDraft);
  return `<div class="billing-page">
    <div class="billing-hero">
      <div>
        <span class="billing-kicker">Billing Desk</span>
        <h2>Professional Bike Invoice</h2>
        <p>Invoice, customer, vehicle, proof, and totals in one clean workflow.</p>
      </div>
      <div class="billing-hero-total"><small>Grand Total</small><b>${formatInvoiceMoney(totals.grand_total_lakh)}</b></div>
    </div>
    <div class="billing-layout">
    <section class="card billing-form-card">
      <div class="section-title"><div><h3>New Bike Billing</h3><small class="muted">Invoice number is generated automatically.</small></div><span class="badge info">${state.apiReady ? "Inventory linked" : "Database required"}</span></div>
      <div class="billing-meta">
        <span><small>Invoice No</small><b>${escapeHtml(nextInvoiceNumber())}</b></span>
        <span><small>Invoice Date</small><b>${now.toLocaleDateString("en-IN")}</b></span>
        <span><small>Current Time</small><b>${now.toLocaleTimeString("en-IN", { hour: "2-digit", minute: "2-digit" })}</b></span>
        <span><small>Employee</small><b>${escapeHtml(state.user.name)}</b></span>
        <span><small>Showroom</small><b>${escapeHtml(currentShowroom)}</b></span>
      </div>
      <form id="billingForm" class="billing-form">
        <input type="hidden" name="invoice_number" value="${escapeHtml(nextInvoiceNumber())}">
        <input type="hidden" name="bike_id" value="${selectedBike.id || ""}">
        <input type="hidden" name="bike" value="${escapeHtml(draft.bike)}">
        <input type="hidden" name="amount" value="${escapeHtml(draft.amount)}">
        <input type="hidden" name="amount_unit" value="${escapeHtml(draft.amount_unit)}">
        <input type="hidden" name="quantity" value="${escapeHtml(draft.quantity || "1")}">
        <input type="hidden" name="payment_status" value="${escapeHtml(billingPaymentStatusFor(totals, effectiveDraft))}">
        <input type="hidden" name="booking_number" value="${escapeHtml(effectiveDraft.booking === "Yes" ? (draft.booking_number || nextBookingNumber()) : "")}">
        <input type="hidden" name="booking_amount" value="0">
        <input type="hidden" name="booking_date" value="${escapeHtml(effectiveDraft.booking === "Yes" ? (draft.booking_date || now.toISOString().slice(0, 10)) : "")}">
        <input type="hidden" name="booking_status" value="${escapeHtml(draft.booking_status || "Booking Confirmed")}">
        <input type="hidden" name="finance_required" value="No">
        <input type="hidden" name="finance_status" value="Not Applied">
        <input type="hidden" name="delivery_status" value="${escapeHtml(draft.delivery_status || "Pending")}">
        <input type="hidden" name="delivery_location" value="${escapeHtml(draft.delivery_location || currentShowroom)}">
        ${billingSection("Showroom & Vehicle", [
          ["showroom", "Branch", currentShowroom, state.user.type === "admin" ? { required: true, select: showroomOptions } : { readonly: true }],
          ["bike_id_select", `Bike Model - ${currentShowroom}`, selectedBike.id || "", { required: true, select: bikeOptions.map((bike) => ({ value: bike.id, label: billingBikeOptionLabel(bike, currentShowroom) })) }],
          ["available_stock", "Available Stock In Branch", branchStock, { readonly: true }],
          ["transaction_type", "Sale Type", billMode, { required: true, readonly: true }],
          ["booking", "Booking", billMode === "Booking" ? "Yes" : "No", { required: true, readonly: true }],
          ["sales_executive", "Employee Role", draft.sales_executive || state.user.role, { select: roleOptions }],
          ["category", "Category", draft.category, { readonly: true }],
          ["color", "Color *", draft.color, { required: true, select: colorOptions.map((item) => ({ value: item.color || "Not specified", label: `${item.color || "Not specified"}${Number(item.stock || 0) > 0 ? ` - Available (${Number(item.stock || 0)})` : ""}` })) }],
          ["vin", "VIN / Chassis", draft.vin, { readonly: true }],
          ["year", "Model Year", draft.year, { readonly: true }]
        ])}
        ${outsideBranch ? `<div class="billing-alert"><i data-lucide="calendar-clock"></i><span>Selected model belongs to ${escapeHtml(selectedBike.showroom)}. This bill will be saved as a booking for ${escapeHtml(currentShowroom)}.</span></div>` : ""}
        ${!outsideBranch && stockBlocked ? `<div class="billing-alert"><i data-lucide="package-search"></i><span>Requested quantity is higher than available branch stock. This bill will be saved as a booking.</span></div>` : ""}
        ${billingSection("Customer Details", [
          ["customer", "Customer Name *", draft.customer, { required: true }],
          ["phone", "Customer Phone Number *", draft.phone, { required: true }],
          ["address", "Customer Address", draft.address, { textarea: true }]
        ])}
        ${billingSection("RC / KYC Proof", [
          ["id_type", "ID Proof Type", draft.id_type, { select: ["", "Aadhaar", "PAN", "Driving License", "Passport", "Voter ID", "Other"] }],
          ["id_reference", "ID Proof Number", draft.id_reference],
          ["id_proof_upload", "ID Proof Upload", "", { type: "file", accept: "image/*,.pdf" }]
        ])}
        ${billingSection("Payment Details", [
          ["payment_mode", "Payment Mode *", draft.payment_mode === "Mixed Payment" ? "UPI" : draft.payment_mode, { required: true, select: ["Cash", "UPI", "Debit Card", "Credit Card", "NEFT", "RTGS", "IMPS", "Bank Transfer", "Finance", "Cheque"] }],
          ["amount_paid", "Amount Paid (Rs)", totals.amount_paid_lakh ? Math.round(totals.amount_paid_lakh * 100000) : draft.amount_paid, { type: "number", step: ".01", min: "0", readonly: effectiveDraft.booking === "Yes" }],
          ["balance_amount", "Balance Amount", Math.round(totals.balance_lakh * 100000), { type: "number", step: ".01", readonly: true }],
          ["payment_date", "Payment Date", draft.payment_date, { type: "date" }]
        ])}
        <div class="billing-actions">
          <button class="soft-btn" type="button" data-invoice-download><i data-lucide="download"></i> Generate Invoice</button>
          <button class="soft-btn" type="button" data-print><i data-lucide="printer"></i> Print Invoice</button>
          <button class="primary-btn" type="submit"><i data-lucide="save"></i> Save Bill</button>
        </div>
      </form>
    </section>
    <aside class="card billing-summary">
      <div class="section-title"><h3>Billing Summary</h3><span class="badge ${Number(branchStock || 0) > 0 ? "success" : "warning"}">${Number(branchStock || 0)} in branch stock</span></div>
      <div class="summary-bike"><b>${escapeHtml(draft.bike || "Select vehicle")}</b><small>${escapeHtml(draft.category || "Vehicle category")} - ${escapeHtml(draft.showroom || "Showroom")}</small></div>
      <div id="billingTotals">${billingTotalsHtml(totals)}</div>
      <div class="data-grid billing-mini-grid">
        <div><small>Employee</small><b>${escapeHtml(state.user.name)}</b></div>
      </div>
    </aside>
  </div></div>`;
}

function renderProfile() {
  const user = state.user;
  return `<section class="profile-hero">
    <div class="profile-heading">
      <span><span class="avatar-letter">S</span> SHOWROOM OPERATIONS</span>
      <button class="logout-btn" id="profileLogout"><i data-lucide="log-out"></i></button>
    </div>
    <div class="profile-card">
      <div class="profile-avatar">${user.name[0]}</div>
      <h2>${user.name}</h2>
      <p>${user.branch} • ${user.role}</p>
      <span class="employee-id-pill"><i data-lucide="id-card"></i>${user.id}</span>
    </div>
  </section>`;
}

function renderTransaction() {
  const sale = state.sales[0];
  const actions = `<div class="actions-row desktop-actions">
    <button class="soft-btn" data-open="edit"><i data-lucide="edit-3"></i> Edit</button>
    <button class="soft-btn" data-open="invoice"><i data-lucide="receipt"></i> Invoice</button>
    <button class="soft-btn" data-open="share"><i data-lucide="share-2"></i> Share</button>
    <button class="danger-btn" data-open="status"><i data-lucide="list-checks"></i> Status</button>
  </div>`;
  return `<div class="grid">
    <section class="card">
      <div class="section-title"><div><h3>Sold to: ${sale.customer}</h3><small class="muted">Transaction ID: ${sale.id}</small></div><span class="badge success">${state.transactionStatus}</span></div>
      ${actions}
    </section>
    <div class="grid erp-layout">
      <div class="grid">
        ${customerCard()}
        ${vehicleSpecCard()}
        ${vehicleHighlight()}
      </div>
      <div class="grid">
        ${statusCard()}
        ${paymentCard()}
      </div>
      <div class="grid">
        ${documentVault()}
        ${remarksSection()}
      </div>
    </div>
    ${auditTimeline()}
    <div class="sticky-actions">
      <button class="soft-btn" data-open="edit"><i data-lucide="edit-3"></i>Edit</button>
      <button class="soft-btn" data-open="invoice"><i data-lucide="receipt"></i>Invoice</button>
      <button class="soft-btn" data-open="share"><i data-lucide="share-2"></i>Share</button>
      <button class="danger-btn" data-open="status"><i data-lucide="list-checks"></i>Status</button>
    </div>
  </div>`;
}

function statusCard() {
  const steps = ["Booking Confirmed","Payment Processed","Finance Approved","PDI Completed","Registration Completed","Delivery Scheduled","Delivered"];
  const current = steps.indexOf(state.transactionStatus);
  return `<section class="card"><div class="section-title"><h3>Transaction Status</h3><span class="badge success">Completed</span></div>
    <div class="timeline">${steps.map((step, index) => `<div class="timeline-item ${index < current ? "done" : index === current ? "current" : ""}">
      <span class="timeline-dot"><i data-lucide="${index <= current ? "check" : "clock"}"></i></span>
      <div class="timeline-body"><h4>${step}</h4><small class="muted">${statusSubtitle(step)}</small></div>
    </div>`).join("")}</div>
  </section>`;
}

function statusSubtitle(step) {
  return {
    "Booking Confirmed": "Initial booking received",
    "Payment Processed": "Booking amount / down-payment cleared",
    "Finance Approved": "Documentation verified",
    "PDI Completed": "Pre-delivery inspection passed",
    "Registration Completed": "RTO / registration processed",
    "Delivery Scheduled": "Vehicle ready for delivery",
    "Delivered": "Gate pass & key handover"
  }[step] || "Updated by showroom team";
}

function paymentCard() {
  return `<section class="card"><div class="section-title"><h3>Full Payment Breakdown</h3><span class="badge success">100% Paid</span></div>
    <div class="amount-box"><span><small>Total Transaction Value</small><strong>₹48.50L</strong></span><i data-lucide="wallet"></i></div>
    <div class="data-grid" style="margin-top:12px;">
      <div><small>Amount Received</small><b>₹48.50L</b></div><div><small>Payment Mode</small><b>NEFT / RTGS / Bank Transfer</b></div>
      <div><small>GST Breakdown</small><b>₹10.81L</b></div><div><small>Extra Components</small><b>₹1.21L Included</b></div>
      <div><small>Invoice Number</small><b>INV-2026-9842</b></div><div><small>Receipt Status</small><b>Cleared & Reconciled</b></div>
    </div></section>`;
}

function customerCard() {
  return `<section class="card"><div class="section-title"><h3>Customer & Key Logistics</h3><span class="badge success">KYC Verified</span></div>
    <div class="store-card"><span class="avatar-letter danger">V</span><span><b>Vikram Rathore</b><small class="muted">AADHAAR-8492-XXXX</small></span></div>
    <div class="data-grid" style="margin-top:12px;">
      <div><small>Primary Mobile</small><b>+91 98492 83920</b></div><div><small>Email Address</small><b>vikramrathore@gmail.com</b></div>
      <div><small>Registered Address</small><b>Flat 402, Sea View Towers, Beach Road, Visakhapatnam, AP - 530003</b></div><div><small>Delivery POC</small><b>Self / Account Holder</b></div>
    </div></section>`;
}

function vehicleSpecCard() {
  return `<section class="card"><div class="section-title"><h3>Assigned Vehicle Specifications</h3></div>
    <div class="data-grid">
      <div><small>Vehicle</small><b>Ducati Panigale V4 R</b></div><div><small>VIN</small><b>WB10M1000R2026</b></div>
      <div><small>Engine Serial</small><b>M-999CC-0941B</b></div><div><small>License Plate</small><b>AP-31-M-1000</b></div>
      <div><small>Odometer</small><b>0 km (Brand New)</b></div><div><small>Showroom</small><b>Vizag Showroom (HQ)</b></div>
      <div><small>Sales Executive</small><b>Rajesh K. (Senior Lead)</b></div>
    </div></section>`;
}

function vehicleHighlight() {
  return `<section class="card"><div class="vehicle-photo"><div><h2>Ducati Panigale V4 R</h2><p>₹48.50L <span class="badge success">${state.transactionStatus}</span></p></div></div></section>`;
}

function documentVault() {
  const docs = [["Tax Invoice", "Customer Copy", "2.4 MB", "Verified"], ["Comprehensive Insurance Policy", "", "4.1 MB", "Active"], ["RTO / RC Transfer Receipt", "", "1.8 MB", "Submitted"], ["Delivery Challan", "", "1.2 MB", "Completed"], ["PDI Report", "", "3.2 MB", "Passed"]];
  return `<section class="card"><div class="section-title"><h3>Transaction Vault & Documents</h3></div><div class="stack">
    ${docs.map((doc) => `<button class="document-row" data-download="${doc[0]}"><span class="avatar-letter danger"><i data-lucide="file-text"></i></span><span><b>${doc[0]}</b><small class="muted">${doc[1]} ${doc[2]}</small></span><span class="badge success">${doc[3]}</span><i data-lucide="download"></i></button>`).join("")}
  </div></section>`;
}

function auditTimeline() {
  const items = [["Booking Initiated","12 May, 10:00 AM","System Auto-Log","Token Received"],["Finance Application Submitted","12 May, 02:15 PM","Rajesh (Finance Exec.)","HDFC Bank"],["Loan Approved","13 May, 11:30 AM","Finance Team","Approved"],["PDI Completed","14 May, 04:00 PM","Anand (Service Head)","PDI Passed"],["Delivered Successfully","Today, 02:30 PM","Showroom Delivery Manager","Key Handover"]];
  return `<section class="card"><div class="section-title"><h3>Transaction Audit Timeline</h3></div><div class="timeline">
    ${items.map((item, index) => `<div class="timeline-item ${index === items.length - 1 ? "done" : ""}"><span class="timeline-dot"><i data-lucide="check"></i></span><div class="timeline-body"><h4>${item[0]}</h4><small class="muted">${item[1]} - Logged by ${item[2]}</small><br><span class="badge info">${item[3]}</span></div></div>`).join("")}
  </div></section>`;
}

function remarksSection() {
  return `<details class="card"><summary><b>ADMIN & REMARKS LOG</b></summary>
    <p><b>Delivery Remark</b></p>
    <p class="muted">Vehicle delivered after successful PDI and document verification. Customer received both keys and delivery kit.</p>
    <p class="muted">Finance remarks, customer remarks and sales executive notes are available for authorized staff.</p>
  </details>`;
}

function bindPageEvents() {
  document.querySelectorAll("[data-page-link]").forEach((el) => el.addEventListener("click", () => setPage(el.dataset.pageLink)));
  const dashboardSearch = $("#dashboardSearch");
  if (dashboardSearch) dashboardSearch.addEventListener("input", (event) => {
    const cursor = event.target.selectionStart;
    state.search = event.target.value;
    renderPage();
    const nextSearch = $("#dashboardSearch");
    if (nextSearch) {
      nextSearch.focus();
      nextSearch.setSelectionRange(cursor, cursor);
    }
  });
  document.querySelectorAll("[data-filter]").forEach((el) => el.addEventListener("click", () => { state.filter = el.dataset.filter; renderPage(); }));
  document.querySelectorAll("[data-store-filter]").forEach((el) => el.addEventListener("click", () => { state.storeFilter = el.dataset.storeFilter; renderPage(); }));
  document.querySelectorAll("[data-custom-date]").forEach((el) => el.addEventListener("change", () => {
    if (el.dataset.customDate === "from") state.customFrom = el.value;
    if (el.dataset.customDate === "to") state.customTo = el.value;
    renderPage();
  }));
  document.querySelectorAll("[data-store-custom-date]").forEach((el) => el.addEventListener("change", () => {
    if (el.dataset.storeCustomDate === "from") state.storeCustomFrom = el.value;
    if (el.dataset.storeCustomDate === "to") state.storeCustomTo = el.value;
    renderPage();
  }));
  const inventorySearch = $("#inventorySearch");
  if (inventorySearch) {
    inventorySearch.addEventListener("input", (event) => {
      const cursor = event.target.selectionStart;
      state.inventorySearch = event.target.value;
      renderPage();
      const next = $("#inventorySearch");
      if (next) {
        next.focus();
        next.setSelectionRange(cursor, cursor);
      }
    });
  }
  const inventoryBranch = document.querySelector("[data-inventory-branch]");
  if (inventoryBranch) {
    inventoryBranch.addEventListener("change", (event) => {
      state.inventoryBranch = event.target.value;
      renderPage();
    });
  }
  document.querySelectorAll("[data-store]").forEach((el) => el.addEventListener("click", () => { state.selectedStore = el.dataset.store; state.selectedEmployeeId = null; if (state.page !== "stores") state.page = "stores"; renderPage(); }));
  document.querySelectorAll("[data-back-stores]").forEach((el) => el.addEventListener("click", () => { state.selectedStore = null; state.selectedEmployeeId = null; renderPage(); }));
  document.querySelectorAll("[data-employee-row]").forEach((el) => el.addEventListener("click", () => { state.selectedEmployeeId = el.dataset.employeeRow; renderPage(); }));
  document.querySelectorAll("[data-employee]").forEach((el) => el.addEventListener("click", () => openEmployeeLeads(el.dataset.employee)));
  document.querySelectorAll("[data-edit-employee]").forEach((el) => el.addEventListener("click", (event) => { event.stopPropagation(); openModal("employee", el.dataset.editEmployee); }));
  document.querySelectorAll("[data-toggle-freeze-employee]").forEach((el) => el.addEventListener("click", (event) => { event.stopPropagation(); toggleEmployeeFreeze(el.dataset.toggleFreezeEmployee); }));
  document.querySelectorAll("[data-delete-employee]").forEach((el) => el.addEventListener("click", (event) => { event.stopPropagation(); deleteEmployee(el.dataset.deleteEmployee); }));
  document.querySelectorAll("[data-toggle-password]").forEach((el) => el.addEventListener("click", (event) => {
    event.stopPropagation();
    const input = document.getElementById(el.dataset.togglePassword);
    if (!input) return;
    const visible = input.type === "text";
    input.type = visible ? "password" : "text";
    el.innerHTML = `<i data-lucide="${visible ? "eye" : "eye-off"}"></i>`;
    el.setAttribute("aria-label", visible ? "Show password" : "Hide password");
    refreshIcons();
  }));
  document.querySelectorAll("[data-bike-detail]").forEach((el) => el.addEventListener("click", () => {
    const bike = state.bikes.find((item) => String(item.id) === String(el.dataset.bikeDetail));
    if (bike) openInfo("Inventory Details", vehicleDetails(bike));
  }));
  document.querySelectorAll("[data-bike-result]").forEach((el) => el.addEventListener("click", () => {
    state.selectedBikeId = el.dataset.bikeResult;
    state.page = "inventory";
    renderNav();
    renderPage();
  }));
  document.querySelectorAll("[data-edit-bike]").forEach((el) => el.addEventListener("click", (event) => {
    event.stopPropagation();
    openModal("vehicle", el.dataset.editBike);
  }));
  document.querySelectorAll("[data-delete-bike]").forEach((el) => el.addEventListener("click", (event) => {
    event.stopPropagation();
    deleteBike(el.dataset.deleteBike);
  }));
  document.querySelectorAll("[data-transaction]").forEach((el) => el.addEventListener("click", () => openSaleDetails(el.dataset.transaction)));
  document.querySelectorAll("[data-sales-filter]").forEach((el) => el.addEventListener(el.tagName === "INPUT" ? "input" : "change", (event) => {
    const key = event.target.dataset.salesFilter;
    const cursor = event.target.selectionStart;
    state[event.target.dataset.salesFilter] = event.target.value;
    state.salesPage = 1;
    renderPage();
    if (key === "salesSearch") {
      const next = document.querySelector('[data-sales-filter="salesSearch"]');
      if (next) {
        next.focus();
        next.setSelectionRange(cursor, cursor);
      }
    }
  }));
  document.querySelectorAll("[data-sale-row]").forEach((el) => el.addEventListener("click", () => openSaleDetails(el.dataset.saleRow)));
  document.querySelectorAll("[data-sale-view]").forEach((el) => el.addEventListener("click", (event) => {
    event.stopPropagation();
    openSaleDetails(el.dataset.saleView);
  }));
  document.querySelectorAll("[data-sale-invoice]").forEach((el) => el.addEventListener("click", (event) => {
    event.stopPropagation();
    openSaleInvoice(el.dataset.saleInvoice);
  }));
  document.querySelectorAll("[data-sales-page]").forEach((el) => el.addEventListener("click", () => {
    const next = Number(el.dataset.salesPage || 1);
    if (next >= 1) {
      state.salesPage = next;
      renderPage();
    }
  }));
  const salesExport = document.querySelector("[data-sales-export]");
  if (salesExport) salesExport.addEventListener("click", exportSalesCsv);
  document.querySelectorAll("[data-emi-input]").forEach((el) => el.addEventListener("input", (event) => {
    const key = event.target.dataset.emiInput;
    state[key] = key === "emiBikeId" ? event.target.value : Number(event.target.value || 0);
    if (key === "emiBikeId") {
      const bike = state.bikes.find((item) => String(item.id) === String(event.target.value));
      const price = bike ? Math.round(fromLakhs(toLakhs(bike.price, bike.priceUnit), "rupees")) : 0;
      state.emiDownPayment = Math.round(price * 0.15);
    }
    renderPage();
  }));
  document.querySelectorAll("[data-open]").forEach((el) => el.addEventListener("click", () => openModal(el.dataset.open)));
  document.querySelectorAll("[data-download]").forEach((el) => el.addEventListener("click", () => showToast(`${el.dataset.download} downloaded successfully.`)));
  const billing = $("#billingForm");
  if (billing) {
    billing.addEventListener("input", handleBillingInput);
    billing.addEventListener("change", handleBillingChange);
    billing.addEventListener("submit", saveInvoice);
    $("[data-invoice-preview]")?.addEventListener("click", openBillingInvoicePreview);
    $("[data-invoice-download]")?.addEventListener("click", () => downloadInvoice());
    $("[data-print]")?.addEventListener("click", () => printInvoice());
    updateBillTotal();
  }
  const profileLogout = $("#profileLogout");
  if (profileLogout) profileLogout.addEventListener("click", () => $("#logoutBtn").click());
}

function openModal(type, id = null) {
  const content = {
    vehicle: vehicleForm(id),
    employee: employeeForm(id),
    store: storeForm(),
    edit: simpleEditForm(),
    invoice: invoiceModal(),
    share: shareModal(),
    status: statusModal()
  }[type];
  modalRoot.innerHTML = `<div class="modal-backdrop"><section class="modal-panel"><div class="modal-head"><h3>${modalTitle(type)}</h3><button class="close-btn" data-close>&times;</button></div>${content}</section></div>`;
  $("[data-close]").addEventListener("click", closeModal);
  $(".modal-backdrop").addEventListener("click", (event) => { if (event.target.classList.contains("modal-backdrop")) closeModal(); });
  const form = modalRoot.querySelector("form");
  if (form) form.addEventListener("submit", handleModalSubmit);
  if (type === "vehicle") bindVehicleFormCalculations(form);
  refreshIcons();
}

function modalTitle(type) {
  return { vehicle: "Publish Vehicle To Inventory", employee: "Add Employee", store: "Add Showroom", edit: "Edit Transaction", invoice: "Invoice Preview", share: "Share Transaction", status: "Update Status" }[type];
}

function closeModal() { modalRoot.innerHTML = ""; }

function vehicleForm(id = null) {
  const bike = id ? state.bikes.find((item) => String(item.id) === String(id)) : null;
  const value = (key, fallback = "") => bike?.[key] ?? fallback;
  const modelOptions = [...new Set(state.bikes.map((item) => item.name).filter(Boolean))];
  const years = Array.from({ length: 51 }, (_, index) => String(new Date().getFullYear() + 1 - index));
  return `<form data-form="vehicle" data-bike-id="${id || ""}" class="form-grid inventory-form">
    <input type="hidden" name="price_unit" value="rupees">
    <input type="hidden" name="cost_unit" value="rupees">
    <input type="hidden" name="margin" value="0">
    <input type="hidden" name="percent" value="0">
    <input type="hidden" name="tax" value="${value("gst", 0)}">
    <input type="hidden" name="owner" value="Motorstock Network">
    <input type="hidden" name="insurance" value="Active">
    <datalist id="modelSuggestions">${modelOptions.map((name) => `<option value="${escapeHtml(name)}"></option>`).join("")}</datalist>
    ${formSection("Bike Details", [
      ["media","Bike photo", "", { type: "file", accept: "image/*" }],
      ["model_name","Model name", value("name", ""), { list: "modelSuggestions", className: "js-model", suggestions: modelOptions }],
      ["brand","Brand", value("brand", bike ? bikeBrand(bike.name) : "")],
      ["year","Model year", value("year", new Date().getFullYear()), { select: years }],
      ["plate","Plate no", value("plate", "")]
    ])}
    ${formSection("Technical Specifications", [
      ["color","Color", value("color", "Black"), { select: colors }],
      ["vin","Chasis number", value("vin", "")],
      ["engine","Engine CC", value("engine", ""), { type: "number", min: "0", step: "1" }],
      ["odo","Odometer in kilometers", value("odometer", 0), { type: "number", min: "0", step: "1" }],
      ["state","Registration state", value("registrationState", "Andhra Pradesh"), { select: indianStates }]
    ])}
    ${formSection("Inventory", [
      ["fuel","Fuel type", value("fuel", "Petrol"), { select: ["Petrol","Electrical","CNG","Hybrid"] }],
      ["showroom","Branch", value("showroom", state.branch === "all" ? (state.stores[0]?.name || "") : state.branch), { select: state.stores.map((store) => store.name) }],
      ["cost","Dealer cost in rupees", fromLakhs(toLakhs(value("purchaseCost", 0), value("costUnit", "lakhs")), "rupees").toFixed(0), { type: "number", min: "0", step: "1", className: "js-cost" }],
      ["price","Selling price in rupees", fromLakhs(toLakhs(value("price", 0), value("priceUnit", "lakhs")), "rupees").toFixed(0), { type: "number", min: "0", step: "1", className: "js-price" }],
      ["repair_charges","Repair charges in rupees", Number(value("repairCharges", 0)).toFixed(0), { type: "number", min: "0", step: "1" }],
      ["total","Units in stock", value("stock", 1), { type: "number", min: "0", step: "1" }],
      ["low","Low stock threshold", value("lowThreshold", 2), { type: "number", min: "0", step: "1" }]
    ])}
    ${formSection("Administration", [
      ["category","Vehicle category", value("category", "Superbike"), { select: ["Superbike","Sport","Track Only","Naked","Adventure","Scooter","Commuter","Cruiser"] }],
      ["display","Display status", value("status", "In Stock"), { select: ["In Stock","Booked","Low Stock","Showroom Demo"] }],
      ["service","Last service inspection", value("serviceDate", new Date().toISOString().slice(0, 10)), { type: "date" }]
    ])}
    <button class="primary-btn" type="submit"><i data-lucide="save"></i> Save</button>
  </form>`;
}

function formSection(title, fields) {
  return `<fieldset class="form-section"><h4>${title}</h4>${fields.map(([name, label, value, options = {}]) => {
    if (options.select) return `<label>${label}<select name="${name}">${options.select.map((item) => `<option ${String(item) === String(value) ? "selected" : ""}>${item}</option>`).join("")}</select></label>`;
    const attrs = [
      `name="${name}"`,
      `type="${options.type || "text"}"`,
      options.type === "file" ? "" : `value="${value ?? ""}"`,
      options.step ? `step="${options.step}"` : "",
      options.min ? `min="${options.min}"` : "",
      options.max ? `max="${options.max}"` : "",
      options.list ? `list="${options.list}"` : "",
      options.accept ? `accept="${options.accept}"` : "",
      options.className ? `class="${options.className}"` : ""
    ].filter(Boolean).join(" ");
    const suggestions = options.suggestions?.length ? `<div class="field-suggestions">${options.suggestions.slice(0, 6).map((item) => `<button type="button" data-fill-brand="${item}">${item}</button>`).join("")}</div>` : "";
    return `<label>${label}<input ${attrs}>${suggestions}</label>`;
  }).join("")}</fieldset>`;
}

function bindVehicleFormCalculations(form) {
  if (!form) return;
  const price = form.querySelector(".js-price");
  const cost = form.querySelector(".js-cost");
  const brand = form.querySelector(".js-model");
  const suggestions = form.querySelector(".field-suggestions");
  const syncVehicleDetails = () => {
    if (!brand?.value.trim()) return;
    const normalized = brand.value.trim().toLowerCase();
    const showroom = form.elements.showroom?.value || "";
    const bike = state.bikes.find((item) => item.name.toLowerCase() === normalized && (!showroom || item.showroom === showroom)) ||
      state.bikes.find((item) => item.name.toLowerCase() === normalized);
    if (!bike) return;
    const set = (name, value) => {
      if (form.elements[name]) form.elements[name].value = value ?? "";
    };
    set("category", bike.category);
    set("showroom", bike.showroom);
    set("vin", bike.vin);
    set("engine", bike.engine);
    set("plate", bike.plate);
    set("color", bike.color);
    set("odo", bike.odometer);
    set("fuel", bike.fuel);
    set("year", bike.year);
    set("state", bike.registrationState);
    set("price", fromLakhs(toLakhs(bike.price, bike.priceUnit), "rupees").toFixed(0));
    set("cost", fromLakhs(toLakhs(bike.purchaseCost, bike.costUnit), "rupees").toFixed(0));
    set("repair_charges", Number(bike.repairCharges || 0).toFixed(0));
    set("tax", bike.gst);
    set("units", bike.stock);
    set("total", bike.stock);
    set("display", bike.status);
    set("service", bike.serviceDate);
    set("owner", bike.owner);
    set("insurance", bike.insurance);
    set("low", bike.lowThreshold);
    syncMargin();
  };
  const syncMargin = () => {
    const costValue = Number(cost?.value || 0);
    const priceValue = Number(price?.value || 0);
    form.elements.margin.value = costValue > 0 ? (((priceValue - costValue) / costValue) * 100).toFixed(2) : "0";
  };
  cost?.addEventListener("input", syncMargin);
  price?.addEventListener("input", syncMargin);
  if (brand && suggestions) {
    const syncSuggestions = () => suggestions.classList.toggle("hidden", Boolean(brand.value.trim()));
    brand.addEventListener("focus", syncSuggestions);
    brand.addEventListener("input", () => {
      syncSuggestions();
      syncVehicleDetails();
    });
    brand.addEventListener("change", syncVehicleDetails);
    form.querySelectorAll("[data-fill-brand]").forEach((button) => button.addEventListener("click", () => {
      brand.value = button.dataset.fillBrand;
      suggestions.classList.add("hidden");
      syncVehicleDetails();
      brand.focus();
    }));
    syncSuggestions();
  }
}

function employeeForm(id = null) {
  const emp = state.employees.find((item) => item.id === id) || { id: "EMP-VZG-103", name: "Meera Shah", username: "meera_a", password: "staff123", shift: "A", role: "Inventory Lead", branch: state.selectedStore || "Vizag Showroom" };
  const roles = ["Sales Executive", "Senior Lead", "Finance Executive", "Inventory Lead", "Billing Executive", "Delivery Manager", "Branch Manager"];
  return `<form data-form="employee" data-employee-id="${id || ""}" class="form-grid">
    <label>Emp ID<input name="id" value="${emp.id}"></label><label>Name of Employee<input name="name" value="${emp.name}"></label>
    <label>Username<input name="username" value="${emp.username}"></label><label>Password<input name="password" value="${emp.password}"></label>
    <label>Shift<select name="shift"><option ${emp.shift === "A" ? "selected" : ""}>A</option><option ${emp.shift === "B" ? "selected" : ""}>B</option></select></label>
    <label>Designation / Role<select name="role">${roles.map((role) => `<option ${role === emp.role ? "selected" : ""}>${role}</option>`).join("")}</select></label>
    <label>Branch Assigned<select name="branch">${state.stores.map((store) => `<option ${store.name === emp.branch ? "selected" : ""}>${store.name}</option>`).join("")}</select></label>
    <button class="primary-btn" type="submit"><i data-lucide="save"></i> Save</button>
  </form>`;
}

function storeForm() {
  return `<form data-form="store" class="form-grid">
    <label>Showroom Name<input name="name" placeholder="Vizag Showroom" required></label>
    <label>Location<input name="location" placeholder="Visakhapatnam" required></label>
    <button class="primary-btn" type="submit"><i data-lucide="save"></i> Save Showroom</button>
  </form>`;
}

function simpleEditForm() {
  return `<form data-form="edit" class="form-grid">
    <label>Customer details<input value="Vikram Rathore"></label><label>Vehicle details<input value="Ducati Panigale V4 R"></label>
    <label>Payment information<input value="₹48.50L - 100% Paid"></label><label>Delivery information<input value="Delivered"></label>
    <label>Sales executive<input value="Rajesh K."></label><button class="primary-btn" type="submit">Save Changes</button>
  </form>`;
}

function invoiceModal() {
  return `<div class="stack"><div class="amount-box"><span><small>Invoice INV-2026-9842</small><strong>₹48.50L</strong></span><i data-lucide="receipt"></i></div><button class="soft-btn" data-download="Invoice">View invoice</button><button class="primary-btn" data-download="Invoice">Download invoice</button><button class="danger-btn" onclick="window.print()">Print invoice</button></div>`;
}

function shareModal() {
  return `<div class="grid three-col"><button class="soft-btn" data-share="WhatsApp"><i data-lucide="message-circle"></i> WhatsApp</button><button class="soft-btn" data-share="Email"><i data-lucide="mail"></i> Email</button><button class="soft-btn" data-share="Copy link"><i data-lucide="copy"></i> Copy link</button></div>`;
}

function statusModal() {
  const statuses = ["Booking Confirmed","Payment Processed","Finance Approved","PDI Completed","Registration Completed","Delivery Scheduled","Delivered","Cancelled"];
  return `<div class="grid two-col">${statuses.map((status) => `<button class="chip" data-set-status="${status}">${status}</button>`).join("")}</div>`;
}

async function fileToDataUrl(file) {
  if (!file) return "";
  if (file.type.startsWith("image/")) return imageToSafeDataUrl(file);
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(String(reader.result || ""));
    reader.onerror = () => reject(reader.error || new Error("Unable to read media file."));
    reader.readAsDataURL(file);
  });
}

async function imageToSafeDataUrl(file) {
  const rawUrl = await new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(String(reader.result || ""));
    reader.onerror = () => reject(reader.error || new Error("Unable to read image file."));
    reader.readAsDataURL(file);
  });
  const image = await new Promise((resolve, reject) => {
    const img = new Image();
    img.onload = () => resolve(img);
    img.onerror = () => reject(new Error("Unable to process selected image."));
    img.src = rawUrl;
  });
  const canvas = document.createElement("canvas");
  const maxSide = 1000;
  const scale = Math.min(1, maxSide / Math.max(image.naturalWidth || image.width, image.naturalHeight || image.height));
  canvas.width = Math.max(1, Math.round((image.naturalWidth || image.width) * scale));
  canvas.height = Math.max(1, Math.round((image.naturalHeight || image.height) * scale));
  canvas.getContext("2d").drawImage(image, 0, 0, canvas.width, canvas.height);
  for (const quality of [0.78, 0.68, 0.58, 0.48]) {
    const compressed = canvas.toDataURL("image/jpeg", quality);
    if (compressed.length < 850000) return compressed;
  }
  throw new Error("Selected image is too large. Please choose a smaller image.");
}

async function handleModalSubmit(event) {
  event.preventDefault();
  const form = event.currentTarget;
  const data = Object.fromEntries(new FormData(form).entries());
  if (form.dataset.form === "vehicle") {
    const media = form.querySelector('input[name="media"]')?.files?.[0];
    data.media_name = media?.name || "";
    data.media_type = media?.type?.startsWith("image/") ? "image/jpeg" : (media?.type || "");
    data.media_data = media ? await fileToDataUrl(media) : "";
    data.id = form.dataset.bikeId || "";
    data.created_by = state.user?.username || state.user?.name || "";
    data.username = state.user?.username || "";
    data.user_id = state.user?.id || "";
    data.price_unit = "rupees";
    data.cost_unit = "rupees";
    data.brand = data.brand || bikeBrand(data.model_name);
    const existingBike = state.bikes.find((item) => String(item.id) === String(data.id));
    const bike = {
      id: data.id || Date.now(),
      name: data.model_name,
      brand: data.brand,
      category: data.category,
      showroom: data.showroom,
      stock: Number(data.total || data.units || 1),
      sold: Number(existingBike?.sold || 0),
      price: Number(data.price || 0),
      purchaseCost: Number(data.cost || 0),
      gst: Number(data.tax || 0),
      repairCharges: Number(data.repair_charges || 0),
      margin: Number(data.margin || 0),
      priceUnit: data.price_unit,
      costUnit: data.cost_unit,
      status: data.display || "Available",
      vin: data.vin,
      engine: data.engine,
      plate: data.plate,
      color: data.color,
      odometer: Number(data.odo || 0),
      fuel: data.fuel,
      year: data.year,
      registrationState: data.state,
      mediaName: data.media_name,
      mediaType: data.media_type,
      mediaData: data.media_data,
      serviceDate: data.service,
      createdBy: state.user?.name || "",
      createdAt: new Date().toISOString(),
      owner: data.owner,
      insurance: data.insurance,
      lowThreshold: Number(data.low || 2)
    };
    if (existingBike && !data.media_data) {
      data.media_name = existingBike.mediaName || "";
      data.media_type = existingBike.mediaType || "";
      data.media_data = existingBike.mediaData || "";
      bike.mediaName = existingBike.mediaName || "";
      bike.mediaType = existingBike.mediaType || "";
      bike.mediaData = existingBike.mediaData || "";
    }
    const saved = await saveVehicleToDatabase(data);
    if (!saved) return;
    if (!state.apiReady) {
      const index = state.bikes.findIndex((item) => String(item.id) === String(data.id));
      if (index >= 0) state.bikes[index] = { ...state.bikes[index], ...bike };
      else state.bikes.push(bike);
    }
    showToast("Vehicle published to inventory.");
  }
  if (form.dataset.form === "employee") {
    const existingId = form.dataset.employeeId;
    const employee = { ...data, active: false, closed: 0, revenue: 0 };
    const saved = await saveEmployeeToDatabase(employee, Boolean(existingId));
    if (!saved) return;
    showToast("Employee saved successfully.");
  }
  if (form.dataset.form === "store") {
    const store = { name: data.name, location: data.location, tier: "Silver", units: 0, revenue: 0, rating: 70 };
    const saved = await saveStoreToDatabase(store);
    if (!saved) return;
    showToast("Showroom saved successfully.");
  }
  if (form.dataset.form === "edit") showToast("Transaction details updated.");
  closeModal();
  renderPage();
}

async function saveStoreToDatabase(store) {
  const connected = await ensureDatabaseReady();
  if (!connected) {
    showToast("Database is not connected. Showroom was not saved.");
    return false;
  }
  try {
    await api.request("save_store", store);
    await loadDatabaseData();
    return true;
  } catch (error) {
    showToast(error.message || "Database showroom save failed. Showroom was not saved.");
    return false;
  }
}

async function saveVehicleToDatabase(data) {
  const connected = await ensureDatabaseReady();
  if (!connected) {
    showToast("Database is not connected. Inventory was not updated.");
    return false;
  }
  try {
    await api.request("save_vehicle", data);
    await loadDatabaseData();
    return true;
  } catch (error) {
    showToast(error.message || "Database vehicle save failed. Inventory was not updated.");
    return false;
  }
}

async function saveEmployeeToDatabase(employee, isEdit) {
  const connected = await ensureDatabaseReady();
  if (!connected) {
    showToast("Database is not connected. Employee was not saved.");
    return false;
  }
  try {
    await api.request("save_employee", { ...employee, is_edit: isEdit ? 1 : 0 });
    await loadDatabaseData();
    return true;
  } catch (error) {
    showToast(error.message || "Database employee save failed. Employee was not saved.");
    return false;
  }
}

async function deleteEmployee(id) {
  const employee = state.employees.find((item) => item.id === id);
  if (!employee) return;
  const connected = await ensureDatabaseReady();
  if (!connected) {
    showToast("Database is not connected. Employee was not deleted.");
    return;
  }
  try {
    await api.request("delete_employee", { id });
    await loadDatabaseData();
    renderPage();
    showToast(`${employee.name} deleted.`);
  } catch (error) {
    showToast(error.message || "Database employee delete failed. Employee was not changed.");
  }
}

async function toggleEmployeeFreeze(id) {
  const employee = state.employees.find((item) => item.id === id);
  if (!employee) return;
  const connected = await ensureDatabaseReady();
  if (!connected) {
    showToast("Database is not connected. Employee status was not changed.");
    return;
  }
  try {
    await api.request("toggle_employee_freeze", { id, frozen: employee.frozen ? 0 : 1 });
    await loadDatabaseData();
    renderPage();
    showToast(`${employee.name} ${employee.frozen ? "resumed" : "frozen"}.`);
  } catch (error) {
    showToast(error.message || "Employee status update failed.");
  }
}

async function deleteBike(id) {
  const bike = state.bikes.find((item) => String(item.id) === String(id));
  if (!bike) return;
  if (!state.apiReady) {
    showToast("Database is not connected. Inventory was not deleted.");
    return;
  }
  try {
    await api.request("delete_vehicle", { id, username: state.user?.username || "", user_id: state.user?.id || "" });
    await loadDatabaseData();
    if (String(state.selectedBikeId) === String(id)) state.selectedBikeId = null;
    renderPage();
    showToast(`${bike.name} deleted.`);
  } catch (error) {
    showToast("Database vehicle delete failed. Inventory was not changed.");
  }
}

document.addEventListener("click", (event) => {
  const emiPaidBtn = event.target.closest("[data-emi-paid]");
  if (emiPaidBtn) {
    markEmiPaid(emiPaidBtn.dataset.emiPaid);
    return;
  }
  const statusBtn = event.target.closest("[data-set-status]");
  if (statusBtn) {
    state.transactionStatus = statusBtn.dataset.setStatus;
    state.sales[0].status = state.transactionStatus;
    closeModal();
    renderPage();
    showToast("Transaction status updated successfully.");
  }
  const shareBtn = event.target.closest("[data-share]");
  if (shareBtn) showToast(`${shareBtn.dataset.share} share option ready.`);
  const downloadBtn = event.target.closest("[data-download]");
  if (downloadBtn) showToast(`${downloadBtn.dataset.download} downloaded successfully.`);
});

function openEmployeeLeads(id) {
  const emp = state.employees.find((item) => item.id === id);
  const closed = state.sales.filter((sale) => sale.employee === emp.name);
  openInfo("Employee Closed Leads", `<div class="stack"><p><b>${emp.name}</b> closed ${emp.closed} leads worth ₹${emp.revenue}L.</p>${transactionRows(closed.length ? closed : state.sales.slice(0, 1))}</div>`);
}

function openInfo(title, html) {
  modalRoot.innerHTML = `<div class="modal-backdrop"><section class="modal-panel"><div class="modal-head"><h3>${title}</h3><button class="close-btn" data-close>&times;</button></div>${html}</section></div>`;
  $("[data-close]").addEventListener("click", closeModal);
  refreshIcons();
}

async function saveInvoice(event) {
  event.preventDefault();
  const data = billingFormData(event.currentTarget);
  const proofFile = event.currentTarget.querySelector('input[name="id_proof_upload"]')?.files?.[0];
  if (proofFile) {
    data.id_proof_file_name = proofFile.name;
    data.id_proof_file_data = await fileToDataUrl(proofFile);
  }
  const selectedBike = state.bikes.find((bike) => String(bike.id) === String(data.bike_id));
  const inBranchBike = branchBikeByName(data.bike);
  const selectedOutsideBranch = Boolean(selectedBike?.showroom && data.showroom && selectedBike.showroom !== data.showroom);
  if ((!inBranchBike || selectedOutsideBranch) && data.transaction_type !== "Booking") return showToast("This vehicle is not in your showroom. Create a booking instead.");
  const missing = requiredBillingErrors(data);
  markBillingErrors(missing);
  if (missing.length) return showToast(`Missing required fields: ${missing.map((item) => item.label).join(", ")}.`);
  const bike = selectedBillingBike();
  if (!bike) return showToast("Select a vehicle from inventory before billing.");
  const exactColorStock = billingStockForBike({ name: data.bike, color: data.color }, data.showroom);
  if (data.transaction_type === "Vehicle Sale" && Number(data.quantity || 1) > Number(exactColorStock || 0)) return showToast("Requested quantity is not available in stock. Create a booking instead.");
  const connected = await ensureDatabaseReady();
  if (!connected) {
    return showToast("Database is not connected. Bill was not saved.");
  }
  try {
    const result = await api.request("save_invoice", { ...data, user_id: state.user.id, username: state.user.username, employee: state.user.name });
    state.lastInvoice = result.invoice;
    state.billingDraft = null;
    state.billingInvoiceNumber = null;
    state.billingBookingNumber = null;
    await loadDatabaseData();
    showBillingSuccess(result.invoice, true);
  } catch (error) {
    showToast(error.message || "Bill save failed.");
  }
}

function billingFormData(form = $("#billingForm")) {
  const data = Object.fromEntries(new FormData(form).entries());
  delete data.id_proof_upload;
  const selected = state.bikes.find((bike) => String(bike.id) === String(data.bike_id_select || data.bike_id));
  if (selected) {
    data.bike_id = selected.id;
    data.bike = selected.name;
  }
  const selectedShowroom = data.showroom || (state.user?.type === "staff" ? state.user.branch : "");
  const branchStock = billingStockForBike({ ...selected, color: data.color }, selectedShowroom);
  if (selected && selectedShowroom && (selected.showroom !== selectedShowroom || Number(data.quantity || 1) > Number(branchStock || 0))) {
    data.booking = "Yes";
    data.transaction_type = "Booking";
  }
  if (bookingIsYes(data)) {
    data.amount_paid = "0";
    data.booking_number = data.booking_number || nextBookingNumber();
  } else {
    data.booking_amount = "0";
    data.booking_number = "";
  }
  const totals = calculateBillingTotals(data);
  if (totals.booking === "No" && data.payment_status === "Fully Paid" && data.finance_required !== "Yes") {
    data.amount_paid = String(Math.round(Number(totals.grand_total_lakh || 0) * 100000));
  }
  const fullPaid = totals.booking === "No" && billingPaymentStatusFor(totals, data) === "Fully Paid" && data.finance_required !== "Yes";
  const today = new Date().toISOString().slice(0, 10);
  const paymentDate = data.payment_date || (fullPaid || Number(totals.amount_paid_lakh || 0) > 0 ? today : "");
  const bookingDate = data.booking_date || (totals.booking === "Yes" ? today : "");
  if (data.finance_required === "Yes") {
    if (!data.finance_status || data.finance_status === "Not Applied") data.finance_status = "Documents Pending";
    const totalEmis = Math.max(Number(data.total_emis || data.loan_tenure_months || data.number_of_emis || 0), 0);
    const paidEmis = Math.max(Number(data.emis_paid || 0), 0);
    if (!Number(data.emi_amount || 0)) {
      data.emi_amount = String(calculateEmiRupees(data.loan_amount, totalEmis, data.interest_rate));
    }
    data.total_emis = String(totalEmis);
    data.number_of_emis = String(totalEmis);
    data.remaining_emis = String(Math.max(totalEmis - paidEmis, 0));
    data.next_emi_due_date = data.next_emi_due_date || addMonthsToDate(data.emi_start_date, paidEmis) || data.emi_start_date || "";
    data.emi_due_date = data.next_emi_due_date;
    data.emi_due_day = data.emi_due_day || (data.next_emi_due_date ? String(new Date(`${data.next_emi_due_date}T00:00:00`).getDate()) : "");
    data.emi_status = emiStatusForDate(data.next_emi_due_date, Number(data.remaining_emis || 0) === 0 && totalEmis > 0);
  }
  return { ...data, payment_date: paymentDate, booking_date: bookingDate, ...totals, branch: data.showroom || state.user.branch };
}

function requiredBillingErrors(data) {
  const errors = [];
  const add = (name, label) => errors.push({ name, label });
  if (!data.customer?.trim()) add("customer", "Customer Name");
  if (!/^[0-9+\-\s()]{10,18}$/.test(data.phone || "")) add("phone", "Valid Phone Number");
  if (!data.bike?.trim()) add("bike", "Vehicle");
  if (!data.color?.trim()) add("color", "Color");
  if (!data.transaction_type?.trim()) add("transaction_type", "Transaction Type");
  if (!["Yes", "No"].includes(data.booking)) add("booking", "Booking");
  if (!data.payment_status?.trim()) add("payment_status", "Payment Status");
  if (!data.payment_mode?.trim()) add("payment_mode", "Payment Mode");
  if (Number(data.amount || 0) <= 0) add("amount", "Showroom Price");
  if (Number(data.gst || 0) < 0 || Number(data.gst || 0) > 50) add("gst", "Valid GST %");
  if (Number(data.amount_paid || 0) < 0) add("amount_paid", "Valid Amount Paid");
  if (Number(data.booking_amount || 0) < 0) add("booking_amount", "Valid Booking Amount");
  const deducted = bookingIsYes(data) ? rupeesToLakhs(data.booking_amount || 0) : rupeesToLakhs(data.amount_paid || 0);
  if (deducted > Number(data.grand_total_lakh || 0)) add(bookingIsYes(data) ? "booking_amount" : "amount_paid", "Payment within Total");
  if (data.finance_required === "Yes" && !data.finance_provider?.trim()) add("finance_provider", "Finance Provider");
  return errors;
}

function markBillingErrors(errors) {
  const form = $("#billingForm");
  if (!form) return;
  form.querySelectorAll(".field-error").forEach((field) => field.classList.remove("field-error"));
  errors.forEach((error) => form.elements[error.name]?.classList.add("field-error"));
}

function updateBillTotal(changedName = "") {
  const form = $("#billingForm");
  if (!form || !$("#billingTotals")) return;
  const data = Object.fromEntries(new FormData(form).entries());
  const selected = state.bikes.find((bike) => String(bike.id) === String(data.bike_id_select || data.bike_id));
  const selectedShowroom = data.showroom || (state.user?.type === "staff" ? state.user.branch : "");
  const branchStock = billingStockForBike({ ...selected, color: data.color }, selectedShowroom);
  const forceBooking = Boolean(selected && selectedShowroom && (selected.showroom !== selectedShowroom || Number(data.quantity || 1) > Number(branchStock || 0)));
  const effectiveData = forceBooking ? { ...data, booking: "Yes", transaction_type: "Booking" } : data;
  const totals = calculateBillingTotals(effectiveData);
  const derivedStatus = billingPaymentStatusFor(totals, effectiveData);
  const today = new Date().toISOString().slice(0, 10);
  $("#billingTotals").innerHTML = billingTotalsHtml(totals);
  if (form.elements.line_total) form.elements.line_total.value = Math.round(toLakhs(data.amount || 0, data.amount_unit || "lakhs") * Math.max(Number(data.quantity || 1), 1) * 100000);
  if (form.elements.available_stock) form.elements.available_stock.value = branchStock;
  if (forceBooking) {
    if (form.elements.booking) form.elements.booking.value = "Yes";
    if (form.elements.transaction_type) form.elements.transaction_type.value = "Booking";
  }
  if (form.elements.payment_status && changedName !== "payment_status") form.elements.payment_status.value = derivedStatus;
  if (form.elements.balance_amount) form.elements.balance_amount.value = Math.round(totals.balance_lakh * 100000);
  if (form.elements.amount_paid) {
    form.elements.amount_paid.readOnly = effectiveData.booking === "Yes";
    if (effectiveData.booking === "Yes") form.elements.amount_paid.value = 0;
    if (effectiveData.booking === "No" && data.payment_status === "Fully Paid" && data.finance_required !== "Yes") {
      form.elements.amount_paid.value = Math.round(totals.grand_total_lakh * 100000);
    }
  }
  if (form.elements.payment_date && !form.elements.payment_date.value && (Number(totals.amount_paid_lakh || 0) > 0 || derivedStatus === "Fully Paid")) {
    form.elements.payment_date.value = today;
    state.billingDraft = { ...(state.billingDraft || {}), payment_date: today };
  }
  if (form.elements.booking_date && effectiveData.booking === "Yes" && !form.elements.booking_date.value) {
    form.elements.booking_date.value = today;
    state.billingDraft = { ...(state.billingDraft || {}), booking_date: today };
  }
  if (form.elements.next_emi_due_date && data.finance_required === "Yes" && !form.elements.next_emi_due_date.value && form.elements.emi_start_date?.value) {
    form.elements.next_emi_due_date.value = form.elements.emi_start_date.value;
    state.billingDraft = { ...(state.billingDraft || {}), next_emi_due_date: form.elements.emi_start_date.value };
  }
  if (data.finance_required === "Yes") {
    const tenure = Number(data.loan_tenure_months || data.total_emis || 0);
    const paidEmis = Math.max(Number(data.emis_paid || 0), 0);
    const totalEmis = Math.max(Number(data.total_emis || tenure || 0), 0);
    const remaining = Math.max(totalEmis - paidEmis, 0);
    const calculatedEmi = calculateEmiRupees(data.loan_amount, totalEmis || tenure, data.interest_rate);
    if (form.elements.emi_amount && (!Number(form.elements.emi_amount.value || 0) || ["loan_amount", "loan_tenure_months", "interest_rate"].includes(changedName))) {
      form.elements.emi_amount.value = calculatedEmi || 0;
    }
    if (form.elements.total_emis) form.elements.total_emis.value = String(totalEmis || tenure);
    if (form.elements.number_of_emis) form.elements.number_of_emis.value = String(totalEmis || tenure);
    if (form.elements.remaining_emis) form.elements.remaining_emis.value = String(remaining);
    if (form.elements.emi_due_day && !form.elements.emi_due_day.value && form.elements.emi_start_date?.value) form.elements.emi_due_day.value = String(new Date(`${form.elements.emi_start_date.value}T00:00:00`).getDate());
    if (form.elements.next_emi_due_date && !form.elements.next_emi_due_date.value && form.elements.emi_start_date?.value) form.elements.next_emi_due_date.value = addMonthsToDate(form.elements.emi_start_date.value, paidEmis);
    if (form.elements.emi_status) form.elements.emi_status.value = emiStatusForDate(form.elements.next_emi_due_date?.value, remaining === 0 && totalEmis > 0);
  }
  if (form.elements.booking_number && effectiveData.booking === "Yes" && !form.elements.booking_number.value) {
    form.elements.booking_number.value = nextBookingNumber();
    state.billingDraft = { ...(state.billingDraft || {}), booking_number: form.elements.booking_number.value };
  }
  if (form.elements.booking_amount) {
    form.elements.booking_amount.readOnly = effectiveData.booking !== "Yes";
    if (effectiveData.booking !== "Yes") form.elements.booking_amount.value = 0;
  }
  if (form.elements.total_paid) form.elements.total_paid.value = Math.round((Number(totals.amount_paid_lakh || 0) + Number(totals.booking_amount_lakh || 0) + Number(totals.down_payment_lakh || 0)) * 100000);
  document.querySelector(".booking-fields")?.classList.toggle("is-hidden", effectiveData.booking !== "Yes");
  document.querySelector(".booking-fields")?.classList.toggle("is-visible", effectiveData.booking === "Yes");
  document.querySelector(".mixed-payment-fields")?.classList.toggle("is-hidden", data.payment_mode !== "Mixed Payment");
  document.querySelector(".mixed-payment-fields")?.classList.toggle("is-visible", data.payment_mode === "Mixed Payment");
  document.querySelector(".finance-emi-fields")?.classList.toggle("is-hidden", data.finance_required !== "Yes");
  document.querySelector(".finance-emi-fields")?.classList.toggle("is-visible", data.finance_required === "Yes");
  form.querySelectorAll(".js-finance-field").forEach((field) => {
    field.closest("label").classList.toggle("is-hidden", data.finance_required !== "Yes");
  });
  const tax = document.querySelector(".billing-tax-snapshot");
  if (tax) tax.innerHTML = `
    <span><small>Total Amount</small><b>${formatInvoiceMoney(totals.grand_total_lakh)}</b></span>`;
}

function handleBillingInput(event) {
  if (!event.target.name) return;
  state.lastInvoice = null;
  if (event.target.name === "id_proof_upload") {
    const file = event.target.files?.[0];
    state.billingDraft = { ...(state.billingDraft || {}), id_proof_file_name: file?.name || "", id_proof_file_data: "" };
    if ($("#billingForm")?.elements.id_proof_file_name) $("#billingForm").elements.id_proof_file_name.value = file?.name || "";
    return;
  }
  if (event.target.name === "bike_id_select") return syncBillingBikeById(event.target.value);
  if (event.target.name === "bike") {
    const normalized = String(event.target.value || "").trim().toLowerCase();
    const exact = billingCatalogBikes().find((bike) => bike.name.toLowerCase() === normalized);
    if (exact) return syncBillingBike(event.target.value);
    state.billingDraft = { ...(state.billingDraft || {}), bike: event.target.value, bike_id: "", category: "", color: "", vin: "", engine: "", year: "", fuel: "", odometer: "" };
    return updateBillTotal();
  }
  state.billingDraft = { ...(state.billingDraft || {}), [event.target.name]: event.target.value };
  updateBillTotal(event.target.name);
}

function handleBillingChange(event) {
  state.lastInvoice = null;
  if (event.target.name === "booking") {
    const transactionType = event.target.value === "Yes" ? "Booking" : "Vehicle Sale";
    state.billingDraft = { ...(state.billingDraft || {}), booking: event.target.value, transaction_type: transactionType };
    return renderPage();
  }
  if (event.target.name === "transaction_type") {
    state.billingDraft = { ...(state.billingDraft || {}), transaction_type: event.target.value, booking: event.target.value === "Booking" ? "Yes" : "No" };
    return renderPage();
  }
  if (event.target.name === "showroom") return syncBillingShowroom(event.target.value);
  if (event.target.name === "bike_id_select") return syncBillingBikeById(event.target.value);
  if (event.target.name === "bike") return syncBillingBike(event.target.value);
  if (event.target.name === "color") return syncBillingColor(event.target.value);
  handleBillingInput(event);
}

function syncBillingBikeById(id) {
  const bike = state.bikes.find((item) => String(item.id) === String(id));
  if (!bike) return;
  const preferredShowroom = billingShowroom() || state.user.branch;
  const branchBike = !preferredShowroom || bike.showroom === preferredShowroom ? bike : null;
  const mustBook = Boolean(preferredShowroom && bike.showroom !== preferredShowroom);
  const current = state.billingDraft || {};
  const booking = mustBook || Number(bike.stock || 0) <= 0 ? "Yes" : (current.booking || "No");
  state.billingDraft = {
    ...billingDefaults(bike),
    ...current,
    bike_id: bike.id,
    bike: bike.name,
    showroom: branchBike ? bike.showroom : preferredShowroom,
    category: bike.category || "",
    color: bike.color || "Not specified",
    vin: branchBike ? (bike.vin || "") : "",
    engine: branchBike ? (bike.engine || "") : "",
    odometer: branchBike ? (bike.odometer || "") : "",
    year: branchBike ? (bike.year || "") : "",
    fuel: branchBike ? (bike.fuel || "") : "",
    amount_unit: bike.priceUnit || "lakhs",
    amount: Number(bike.price || 0).toFixed(2),
    gst: Number(bike.gst || 28),
    booking,
    transaction_type: booking === "Yes" ? "Booking" : "Vehicle Sale",
    booking_number: booking === "Yes" ? (current.booking_number || nextBookingNumber()) : "",
    booking_date: booking === "Yes" ? (current.booking_date || new Date().toISOString().slice(0, 10)) : current.booking_date || "",
    delivery_location: preferredShowroom || bike.showroom || ""
  };
  renderPage();
}

function syncBillingBike(name) {
  const preferredShowroom = billingShowroom();
  const normalized = String(name || "").trim().toLowerCase();
  const branchBike = state.bikes.find((item) => item.name.toLowerCase() === normalized && (!preferredShowroom || item.showroom === preferredShowroom));
  const bike = branchBike || state.bikes.find((item) => item.name.toLowerCase() === normalized);
  if (!bike) {
    state.billingDraft = { ...(state.billingDraft || {}), bike: name };
    return updateBillTotal();
  }
  const current = state.billingDraft || {};
  const mustBook = !branchBike;
  const keep = {
    customer: current.customer || "",
    phone: current.phone || "",
    email: current.email || "",
    address: current.address || "",
    city: current.city || "",
    state_name: current.state_name || bike.registrationState || "",
    pincode: current.pincode || "",
    id_type: current.id_type || "",
    id_reference: current.id_reference || "",
    transaction_type: mustBook ? "Booking" : (current.transaction_type || (bookingValueForBike(bike) === "Yes" ? "Booking" : "Vehicle Sale")),
    booking: mustBook ? "Yes" : (Number(billingStockFor(bike.name, bike.color || "Not specified")) > 0 ? (current.booking || "No") : "Yes"),
    payment_status: current.payment_status || "Pending",
    payment_mode: current.payment_mode || "UPI",
    amount_paid: current.amount_paid || "0",
    balance_amount: current.balance_amount || "0",
    booking_amount: current.booking_amount || "0",
    booking_number: current.booking_number || (mustBook || current.booking === "Yes" ? nextBookingNumber() : ""),
    booking_date: current.booking_date || new Date().toISOString().slice(0, 10),
    delivery_date: current.delivery_date || "",
    booking_status: current.booking_status || "Booking Confirmed",
    finance_required: current.finance_required || "No",
    finance_provider: current.finance_provider || "",
    loan_account_number: current.loan_account_number || "",
    loan_amount: current.loan_amount || "0",
    down_payment: current.down_payment || "0",
    loan_tenure_months: current.loan_tenure_months || "12",
    interest_rate: current.interest_rate || "0",
    loan_application_number: current.loan_application_number || "",
    finance_status: current.finance_status || "Not Applied",
    emi_amount: current.emi_amount || "0",
    emi_start_date: current.emi_start_date || "",
    emi_due_date: current.emi_due_date || "",
    emi_due_day: current.emi_due_day || "",
    emi_frequency: current.emi_frequency || "Monthly",
    number_of_emis: current.number_of_emis || "0",
    total_emis: current.total_emis || current.number_of_emis || "0",
    emis_paid: current.emis_paid || "0",
    remaining_emis: current.remaining_emis || "0",
    emi_status: current.emi_status || "Upcoming",
    next_emi_due_date: current.next_emi_due_date || "",
    delivery_status: current.delivery_status || "Pending",
    actual_delivery_date: current.actual_delivery_date || "",
    delivery_location: current.delivery_location || preferredShowroom || bike.showroom || "",
    sales_executive: current.sales_executive || state.user.role
  };
  keep.transaction_type = keep.booking === "Yes" ? "Booking" : "Vehicle Sale";
  state.billingDraft = {
    ...billingDefaults(bike),
    ...keep,
    bike: bike.name,
    bike_id: bike.id,
    showroom: branchBike ? (bike.showroom || "") : preferredShowroom,
    color: bike.color || "Not specified",
    category: bike.category || "",
    vin: branchBike ? (bike.vin || "") : "",
    engine: branchBike ? (bike.engine || "") : "",
    year: branchBike ? (bike.year || "") : "",
    fuel: branchBike ? (bike.fuel || "") : "",
    odometer: branchBike ? (bike.odometer || "") : "",
    amount_unit: bike.priceUnit || "lakhs",
    amount: Number(bike.price || 0).toFixed(2),
    gst: Number(bike.gst || 28)
  };
  renderPage();
}

function syncBillingShowroom(showroom) {
  const current = state.billingDraft || {};
  const matchingBike = state.bikes.find((item) => item.name === current.bike && item.showroom === showroom);
  const bike = matchingBike || state.bikes.find((item) => item.showroom === showroom) || {};
  state.billingDraft = {
    ...current,
    ...billingDefaults(bike),
    showroom,
    bike: matchingBike ? current.bike : (bike.name || ""),
    bike_id: bike.id || "",
    color: bike.color || "",
    category: bike.category || "",
    vin: bike.vin || "",
    engine: bike.engine || "",
    year: bike.year || "",
    fuel: bike.fuel || "",
    odometer: bike.odometer || "",
    amount_unit: bike.priceUnit || "lakhs",
    amount: Number(bike.price || 0).toFixed(2),
    gst: Number(bike.gst || 28)
  };
  renderPage();
}

function syncBillingColor(color) {
  const bikeName = $("#billingForm")?.elements.bike.value;
  const showroom = $("#billingForm")?.elements.showroom.value;
  const branchBike = state.bikes.find((item) => item.name === bikeName && item.showroom === showroom && (item.color || "Not specified") === color) ||
    state.bikes.find((item) => item.name === bikeName && item.showroom === showroom);
  const bike = branchBike || state.bikes.find((item) => item.name === bikeName);
  if (bike) {
    const booking = branchBike && Number(billingStockFor(bike.name, color)) > 0 ? (state.billingDraft?.booking || "No") : "Yes";
    state.billingDraft = {
      ...(state.billingDraft || {}),
      booking,
      transaction_type: booking === "Yes" ? "Booking" : "Vehicle Sale",
      bike_id: bike.id,
      showroom: branchBike ? (bike.showroom || showroom) : showroom,
      color,
      category: bike.category || "",
      vin: branchBike ? (bike.vin || "") : "",
      engine: branchBike ? (bike.engine || "") : "",
      odometer: branchBike ? (bike.odometer || "") : "",
      year: branchBike ? (bike.year || "") : "",
      fuel: branchBike ? (bike.fuel || "") : "",
      amount_unit: bike.priceUnit || "lakhs",
      amount: Number(bike.price || 0).toFixed(2)
    };
  }
  renderPage();
}

function calculateBillingTotals(data) {
  const booking = bookingIsYes(data) ? "Yes" : "No";
  const amount = toLakhs(data.amount || 0, data.amount_unit || "lakhs");
  const quantity = Math.max(Number(data.quantity || 1), 1);
  const additions = ["accessories", "insurance_amount", "registration", "handling", "logistics", "extended_warranty", "other_charges"].reduce((sum, key) => sum + Number(data[key] || 0), 0);
  const subtotal = Math.max((amount * quantity) + additions, 0);
  const percentDiscount = data.discount_type === "Percentage" ? subtotal * Math.max(Number(data.discount_percent || 0), 0) / 100 : 0;
  const fixedDiscount = data.discount_type === "None" ? 0 : Math.max(Number(data.discount ?? data.discount_lakh ?? 0), 0);
  const discount = Math.min(data.discount_type === "Percentage" ? percentDiscount : fixedDiscount, subtotal);
  const taxable = Math.max(subtotal - discount, 0);
  const gstAmount = taxable * Number(data.gst || 0) / 100;
  const cgst = gstAmount / 2;
  const sgst = gstAmount / 2;
  const grand = taxable + gstAmount;
  const financeRequired = data.finance_required === "Yes";
  const financeStatus = data.finance_status || "Not Applied";
  const fullSale = booking === "No" && data.payment_status === "Fully Paid" && !financeRequired;
  const paid = booking === "Yes" ? 0 : (fullSale ? grand : (data.amount_paid !== undefined ? rupeesToLakhs(data.amount_paid) : Math.max(Number(data.amount_paid_lakh ?? 0), 0)));
  const bookingPaid = booking === "Yes" ? (data.booking_amount !== undefined ? rupeesToLakhs(data.booking_amount) : Math.max(Number(data.booking_amount_lakh ?? 0), 0)) : 0;
  const loanAmount = financeRequired ? rupeesToLakhs(data.loan_amount || 0) : 0;
  const downPayment = financeRequired ? rupeesToLakhs(data.down_payment || 0) : 0;
  const financeCoverage = ["Loan Disbursed", "EMI Started", "Completed"].includes(financeStatus) ? loanAmount : 0;
  const paidTotal = paid + bookingPaid + downPayment + financeCoverage;
  return { subtotal_lakh: subtotal, discount_lakh: discount, taxable_lakh: taxable, gst_amount_lakh: gstAmount, cgst_percent: Number(data.gst || 0) / 2, sgst_percent: Number(data.gst || 0) / 2, cgst_lakh: cgst, sgst_lakh: sgst, round_off_lakh: 0, grand_total_lakh: grand, amount_paid_lakh: paid, booking_amount_lakh: bookingPaid, down_payment_lakh: downPayment, loan_amount_lakh: loanAmount, finance_coverage_lakh: financeCoverage, balance_lakh: Math.max(grand - paidTotal, 0), booking, transaction_type: booking === "Yes" ? "Booking" : "Vehicle Sale", quantity };
}

function calculateTotal(data) {
  return calculateBillingTotals(data).grand_total_lakh;
}

function billingTotalsHtml(totals) {
  return `<div class="summary-lines">
    <span><small>Quantity</small><b>${Number(totals.quantity || 1)}</b></span>
    <span><small>Amount Paid</small><b>${formatInvoiceMoney(totals.amount_paid_lakh)}</b></span>
  </div>`;
}

function buildLocalInvoice(data, bike) {
  const invoiceNumber = `INV-${new Date().getFullYear()}-${Math.floor(100000 + Math.random() * 899999)}`;
  const bookingNumber = data.transaction_type === "Booking" ? `BKG-${new Date().getFullYear()}-${Math.floor(100000 + Math.random() * 899999)}` : "";
  const showroom = data.showroom || bike.showroom || state.user.branch;
  const sale = { id: invoiceNumber, customer: data.customer, bike: data.bike, amount: data.grand_total_lakh, status: data.transaction_type === "Booking" ? "Booking/Awaiting Stock" : "Delivered", payment: data.payment_status, mode: data.payment_mode, branch: showroom, employee: state.user.name, date: new Date().toISOString().slice(0, 10) };
  return { invoice_number: invoiceNumber, booking_number: bookingNumber, sale, ...data, showroom, employee: state.user.name, invoice_date: sale.date, invoice_time: new Date().toLocaleTimeString("en-IN") };
}

function showBillingSuccess(invoice, persisted) {
  modalRoot.innerHTML = `<div class="modal-backdrop"><section class="modal-panel billing-success-modal">
    <div class="modal-head"><h3>Bill Created Successfully</h3><button class="close-btn" data-close>&times;</button></div>
    <div class="amount-box"><span><small>Invoice No</small><strong>${escapeHtml(invoice.invoice_number || invoice.id)}</strong></span><i data-lucide="badge-check"></i></div>
    <div class="data-grid">
      <div><small>Customer</small><b>${escapeHtml(invoice.customer || "")}</b></div>
      <div><small>Vehicle</small><b>${escapeHtml(invoice.bike || "")}</b></div>
      <div><small>Total</small><b>${formatInvoiceMoney(invoice.grand_total_lakh || invoice.amount || 0)}</b></div>
      <div><small>Booking Amount</small><b>${formatInvoiceMoney(invoice.booking_amount_lakh || invoice.booking_amount || 0)}</b></div>
      <div><small>Amount Paid</small><b>${formatInvoiceMoney(invoice.amount_paid_lakh || invoice.amount_paid || 0)}</b></div>
      <div><small>Balance</small><b>${formatInvoiceMoney(invoice.balance_lakh || 0)}</b></div>
      <div><small>Status</small><b>${persisted ? "Saved to database" : "Preview only"}</b></div>
    </div>
    <div class="actions-row invoice-modal-actions">
      <button class="primary-btn" data-success-invoice><i data-lucide="file-text"></i> View Invoice</button>
      <button class="soft-btn" data-success-pdf><i data-lucide="download"></i> Download PDF</button>
      <button class="soft-btn" data-success-print><i data-lucide="printer"></i> Print</button>
      <button class="danger-btn" data-success-sales><i data-lucide="receipt"></i> Go To Sales</button>
    </div>
  </section></div>`;
  $("[data-close]").addEventListener("click", closeModal);
  $("[data-success-invoice]").addEventListener("click", openBillingInvoicePreview);
  $("[data-success-pdf]").addEventListener("click", () => downloadInvoice(invoice));
  $("[data-success-print]").addEventListener("click", () => printInvoice(invoice));
  $("[data-success-sales]").addEventListener("click", () => { closeModal(); setPage("sales"); });
  refreshIcons();
  showToast(`Bill ${invoice.invoice_number || ""} saved successfully.`);
}

function invoiceDataForPreview() {
  const form = $("#billingForm");
  if (!form) return state.lastInvoice;
  return state.lastInvoice || buildLocalInvoice(billingFormData(form), selectedBillingBike() || {});
}

function openBillingInvoicePreview() {
  const invoice = invoiceDataForPreview();
  if (!invoice) return showToast("Add billing details before previewing invoice.");
  modalRoot.innerHTML = `<div class="modal-backdrop"><section class="modal-panel invoice-preview-modal"><div class="modal-head"><h3>Invoice Preview</h3><button class="close-btn" data-close>&times;</button></div>${invoiceHtml(invoice)}<div class="actions-row invoice-modal-actions"><button class="primary-btn" data-download-pdf><i data-lucide="download"></i> Download PDF</button><button class="soft-btn" data-print-invoice><i data-lucide="printer"></i> Print</button><button class="danger-btn" data-close>Close</button></div></section></div>`;
  document.querySelectorAll("[data-close]").forEach((btn) => btn.addEventListener("click", closeModal));
  $("[data-download-pdf]").addEventListener("click", () => downloadInvoice(invoice));
  $("[data-print-invoice]").addEventListener("click", () => printInvoice(invoice));
  refreshIcons();
}

function invoiceRows(invoice) {
  const quantity = Math.max(Number(invoice.quantity || 1), 1);
  const rows = [
    { label: invoice.bike || "Vehicle", amount: toLakhs(invoice.amount || 0, invoice.amount_unit || "lakhs"), quantity, taxable: true, hsn: invoice.hsn || "" },
    { label: "Accessories", amount: Number(invoice.accessories || 0), taxable: true },
    { label: "Insurance", amount: Number(invoice.insurance_amount || 0), taxable: false },
    { label: "Registration/RTO", amount: Number(invoice.registration || 0), taxable: false },
    { label: "Handling Charges", amount: Number(invoice.handling || 0), taxable: true },
    { label: "Logistics Charges", amount: Number(invoice.logistics || 0), taxable: true },
    { label: "Extended Warranty", amount: Number(invoice.extended_warranty || 0), taxable: true },
    { label: "Other Charges", amount: Number(invoice.other_charges || 0), taxable: true }
  ].filter((row, index) => index === 0 || Number(row.amount || 0) > 0);
  const totals = calculateBillingTotals(invoice);
  return { rows, totals };
}

function amountInWordsFromLakhs(value) {
  const rupees = Math.round(Number(value || 0) * 100000);
  if (!rupees) return "RUPEES ZERO ONLY.";
  const ones = ["", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten", "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen", "Seventeen", "Eighteen", "Nineteen"];
  const tens = ["", "", "Twenty", "Thirty", "Forty", "Fifty", "Sixty", "Seventy", "Eighty", "Ninety"];
  const belowHundred = (num) => num < 20 ? ones[num] : [tens[Math.floor(num / 10)], ones[num % 10]].filter(Boolean).join(" ");
  const belowThousand = (num) => [num >= 100 ? `${ones[Math.floor(num / 100)]} Hundred` : "", num % 100 ? belowHundred(num % 100) : ""].filter(Boolean).join(" ");
  const parts = [
    [10000000, "Crore"],
    [100000, "Lakh"],
    [1000, "Thousand"],
    [1, ""]
  ];
  let remaining = rupees;
  const words = [];
  parts.forEach(([value, label]) => {
    const count = Math.floor(remaining / value);
    if (count) {
      words.push(`${belowThousand(count)} ${label}`.trim());
      remaining %= value;
    }
  });
  return `RUPEES ${words.join(" ").toUpperCase()} ONLY.`;
}

function invoiceHtml(invoice) {
  const { rows, totals } = invoiceRows(invoice);
  const fullAddress = [invoice.address, invoice.city, invoice.state_name, invoice.pincode].filter(Boolean).join(", ");
  const billTo = invoice.bill_to_address || fullAddress;
  const deliveryTo = invoice.delivery_address || billTo;
  const printed = new Date().toLocaleString("en-IN");
  const itemRows = rows.map((row, index) => `<tr>
    <td>${index + 1}</td>
    <td><b>${escapeHtml(row.label)}</b>${row.hsn ? `<small>HSN: ${escapeHtml(row.hsn)}</small>` : ""}</td>
    <td>${formatInvoiceMoney(row.amount)}</td>
    <td>${index === 0 ? Math.max(Number(row.quantity || invoice.quantity || 1), 1) : 1}</td>
    <td>${formatInvoiceMoney(index === 0 ? totals.grand_total_lakh : row.amount)}</td>
  </tr>`).join("");
  return `<article class="invoice-sheet" id="invoiceSheet">
    <header class="invoice-head">
      <img src="assets/logobike.png" alt="Motorstock logo">
      <div><h2>MOTORSTOCK</h2><p><b>${escapeHtml(invoice.showroom || invoice.branch || "Showroom")}</b><br>${escapeHtml(invoice.showroom_address || invoice.branch || "")}<br>${escapeHtml(invoice.showroom_email || "")}</p></div>
      <span><small>ORIGINAL FOR RECIPIENT</small><b>TAX INVOICE (VEHICLE)</b></span>
    </header>
    <div class="invoice-meta-strip"><b>Invoice No: ${escapeHtml(invoice.invoice_number || invoice.id || "Draft")}</b><span>Date: ${escapeHtml(invoice.invoice_date || new Date().toISOString().slice(0, 10))}</span><span>Time: ${escapeHtml(invoice.invoice_time || "")}</span><span>Reverse Charge: No</span></div>
    <div class="invoice-grid">
      <section><h4>Customer Information</h4><p><b>${escapeHtml(invoice.customer)}</b><br>${escapeHtml(invoice.customer_type || "Individual")} ${invoice.relation_name ? `<br>${escapeHtml(invoice.relation_name)}` : ""}<br>Phone: ${escapeHtml(invoice.phone)}${invoice.email ? `<br>Email: ${escapeHtml(invoice.email)}` : ""}${invoice.id_type ? `<br>ID: ${escapeHtml(invoice.id_type)} ${escapeHtml(invoice.id_reference || "")}` : ""}${invoice.id_proof_file_name ? `<br>Proof File: ${escapeHtml(invoice.id_proof_file_name)}` : ""}${invoice.customer_gstin ? `<br>GSTIN: ${escapeHtml(invoice.customer_gstin)}` : ""}${invoice.customer_pan ? `<br>PAN: ${escapeHtml(invoice.customer_pan)}` : ""}</p></section>
      <section><h4>Bill To / Delivery Address</h4><p><b>Bill To:</b><br>${escapeHtml(billTo || "Not entered")}<br><b>Delivery:</b><br>${escapeHtml(deliveryTo || "Not entered")}</p></section>
      <section><h4>Vehicle Information</h4><p><b>${escapeHtml(invoice.bike)}</b><br>${escapeHtml(invoice.category || "")} ${invoice.color ? `- ${escapeHtml(invoice.color)}` : ""}${invoice.vin ? `<br>VIN/Chassis: ${escapeHtml(invoice.vin)}` : ""}${invoice.engine ? `<br>Engine: ${escapeHtml(invoice.engine)}` : ""}${invoice.year ? `<br>Model Year: ${escapeHtml(invoice.year)}` : ""}${invoice.fuel ? `<br>Fuel: ${escapeHtml(invoice.fuel)}` : ""}${invoice.odometer ? `<br>Odometer: ${escapeHtml(invoice.odometer)}` : ""}</p></section>
      <section><h4>Payment / Booking / Finance</h4><p>Transaction: ${escapeHtml(invoice.transaction_type || "")}<br>Status: ${escapeHtml(invoice.payment_status || "")}<br>Mode: ${escapeHtml(invoice.payment_mode || "")}${invoice.payment_reference ? `<br>Ref: ${escapeHtml(invoice.payment_reference)}` : ""}${invoice.booking_number ? `<br>Booking No: ${escapeHtml(invoice.booking_number)}` : ""}${invoice.finance_required === "Yes" ? `<br>Finance: ${escapeHtml(invoice.finance_provider || "")} / ${escapeHtml(invoice.finance_status || "")}` : ""}<br>Delivery: ${escapeHtml(invoice.delivery_status || "Pending")}</p></section>
    </div>
    <table class="invoice-table"><thead><tr><th>S.No</th><th>Model / HSN / SAC</th><th>Price</th><th>Qty</th><th>Amount</th></tr></thead><tbody>${itemRows}</tbody></table>
    <div class="invoice-total-block">
      <p class="invoice-grand"><span>TOTAL AMOUNT</span><b>${formatInvoiceMoney(totals.grand_total_lakh)}</b></p>
      <p><span>Amount Paid</span><b>${formatInvoiceMoney(totals.amount_paid_lakh)}</b></p>
    </div>
    <p class="amount-words"><b>Amount in Words:</b> ${amountInWordsFromLakhs(totals.grand_total_lakh)}</p>
    <p class="invoice-terms"><b>Terms & Conditions:</b> Vehicle is sold subject to applicable MotoStock showroom terms. Registration and insurance follow applicable rules. Warranty is subject to manufacturer terms. Delivery is subject to completion of payment and documentation requirements. Customer should retain this invoice.</p>
    <footer class="invoice-signatures"><span>Customer Signature / Authorized Agent</span><span>For ${escapeHtml(invoice.showroom || "MOTORSTOCK")}<br>Authorized Signatory</span></footer>
    <div class="invoice-footer"><span>Printed On: ${escapeHtml(printed)}</span><span>Page 1 of 1</span></div>
  </article>`;
}

function downloadInvoice(invoice = invoiceDataForPreview()) {
  if (!invoice) return showToast("No invoice available to download.");
  const blob = new Blob([createInvoicePdf(invoice)], { type: "application/pdf" });
  const link = document.createElement("a");
  link.href = URL.createObjectURL(blob);
  link.download = `MotoStock_${invoice.invoice_number || "invoice"}.pdf`;
  link.click();
  URL.revokeObjectURL(link.href);
  showToast("Invoice downloaded successfully.");
}

function printInvoice(invoice = invoiceDataForPreview()) {
  if (!invoice) return showToast("No invoice available to print.");
  const printWindow = window.open("", "_blank", "width=900,height=1100");
  printWindow.document.write(`<!doctype html><html><head><title>${escapeHtml(invoice.invoice_number || "Invoice")}</title><link rel="stylesheet" href="styles.css"></head><body class="invoice-print-body">${invoiceHtml(invoice)}<script>window.onload=()=>window.print();<\/script></body></html>`);
  printWindow.document.close();
  showToast("Invoice print dialog opened.");
}

function createInvoicePdf(invoice) {
  const totals = calculateBillingTotals(invoice);
  const lines = [
    "MOTORSTOCK",
    "TAX INVOICE (VEHICLE) - ORIGINAL FOR RECIPIENT",
    `Invoice No: ${invoice.invoice_number || invoice.id || "Draft"}`,
    `Date: ${invoice.invoice_date || new Date().toISOString().slice(0, 10)}`,
    `Customer: ${invoice.customer || ""}`,
    `Phone: ${invoice.phone || ""}`,
    `Bill To: ${invoice.bill_to_address || invoice.address || ""}`,
    `Delivery Address: ${invoice.delivery_address || invoice.address || ""}`,
    `Showroom: ${invoice.showroom || invoice.branch || ""}`,
    `Employee: ${invoice.employee || state.user.name}`,
    `Vehicle: ${invoice.bike || ""}`,
    `Quantity: ${invoice.quantity || 1}`,
    `Color: ${invoice.color || ""}`,
    `ID Proof: ${[invoice.id_type, invoice.id_reference].filter(Boolean).join(" ")}`,
    `VIN: ${invoice.vin || "Not entered"}`,
    `Engine: ${invoice.engine || "Not entered"}`,
    `Model Year: ${invoice.year || "Not entered"}`,
    `Payment Mode: ${invoice.payment_mode || ""}`,
    `Payment Status: ${invoice.payment_status || ""}`,
    `Total Amount: ${formatInvoiceMoney(totals.grand_total_lakh)}`,
    `Amount Paid: ${formatInvoiceMoney(totals.amount_paid_lakh)}`,
    `Amount in Words: ${amountInWordsFromLakhs(totals.grand_total_lakh)}`,
    "Terms: Subject to MotoStock showroom terms, statutory registration rules, finance approval, and payment realization.",
    "",
    "Customer Signature: ____________________",
    "Authorized Signatory: __________________",
    `Printed On: ${new Date().toLocaleString("en-IN")}    Page 1 of 1`
  ];
  const content = lines.map((line, index) => `BT /F1 11 Tf 56 ${780 - index * 24} Td (${pdfEscape(line)}) Tj ET`).join("\n");
  const objects = [
    "<< /Type /Catalog /Pages 2 0 R >>",
    "<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
    "<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>",
    "<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>",
    `<< /Length ${content.length} >>\nstream\n${content}\nendstream`
  ];
  let pdf = "%PDF-1.4\n";
  const offsets = [0];
  objects.forEach((object, index) => {
    offsets.push(pdf.length);
    pdf += `${index + 1} 0 obj\n${object}\nendobj\n`;
  });
  const xref = pdf.length;
  pdf += `xref\n0 ${objects.length + 1}\n0000000000 65535 f \n${offsets.slice(1).map((offset) => String(offset).padStart(10, "0") + " 00000 n ").join("\n")}\n`;
  pdf += `trailer << /Size ${objects.length + 1} /Root 1 0 R >>\nstartxref\n${xref}\n%%EOF`;
  return pdf;
}

function pdfEscape(value) {
  return String(value).replace(/[\\()]/g, "\\$&").replace(/[^\x20-\x7E]/g, "");
}

function statusClass(status) {
  if (/delivered|completed|paid/i.test(status)) return "success";
  if (/pending|finance/i.test(status)) return "warning";
  if (/cancelled|low/i.test(status)) return "danger";
  return "info";
}

function showToast(message) {
  toast.textContent = message;
  toast.classList.add("show");
  clearTimeout(showToast.timer);
  showToast.timer = setTimeout(() => toast.classList.remove("show"), 2400);
}

function refreshIcons() {
  if (window.lucide) window.lucide.createIcons();
}

