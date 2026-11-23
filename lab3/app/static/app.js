// ЛР3. Клієнт: звертається до REST API через fetch.

async function api(url, options) {
  const res = await fetch(url, options);
  const data = await res.json();
  // помилку з сервера (THROW у процедурі) показуємо користувачу
  if (!res.ok) throw new Error(data.detail);
  return data;
}

// таблиця з масиву об'єктів; columns - пари [поле, заголовок]
function fillTable(table, rows, columns, onClick) {
  table.innerHTML = "<tr>" + columns.map(c => `<th>${c[1]}</th>`).join("") + "</tr>";
  for (const row of rows) {
    const tr = table.insertRow();
    for (const [field] of columns) tr.insertCell().textContent = row[field];
    if (onClick) tr.onclick = () => onClick(row);
  }
}

async function loadMedicines() {
  const rows = await api("/api/medicines");
  fillTable(document.getElementById("medicines"), rows,
    [["name", "Назва"], ["producer", "Виробник"], ["base_price", "Ціна"]],
    row => showMedicine(row.medicine_id));
}

async function showMedicine(id, message) {
  const d = await api(`/api/medicines/${id}`);
  const box = document.getElementById("detail");
  box.innerHTML = `
    <h2>${d.medicine.name}</h2>
    <p>Виробник: ${d.medicine.producer}.
       Базова ціна: ${d.medicine.base_price} грн.
       ${d.medicine.prescription_only ? "За рецептом." : ""}</p>
    <h3>Наявність в аптеках</h3><table id="stock"></table>
    <h3>Продаж</h3>
    <div class="row">
      <select id="sale-pharmacy"></select>
      <select id="sale-employee"></select>
      <input id="sale-qty" type="number" value="1" min="1">
      <button id="sale-btn">Продати</button>
    </div>
    <p id="sale-msg" class="${message?.error ? "error" : "ok"}">${message?.text ?? ""}</p>
    <h3>Продажі (${d.sales.length})</h3>
    <div class="scroll"><table id="sales"></table></div>`;

  fillTable(document.getElementById("stock"), d.stock,
    [["pharmacy", "Аптека"], ["price", "Ціна"], ["quantity", "Залишок"]]);
  fillTable(document.getElementById("sales"), d.sales,
    [["order_id", "Чек"], ["order_date", "Дата"], ["pharmacy", "Аптека"],
     ["employee", "Працівник"], ["quantity", "К-сть"], ["unit_price", "Ціна"]]);

  const pharmacySelect = document.getElementById("sale-pharmacy");
  pharmacySelect.innerHTML = d.stock
    .map(s => `<option value="${s.pharmacy_id}">${s.pharmacy}</option>`).join("");
  pharmacySelect.onchange = loadEmployees;
  await loadEmployees();

  document.getElementById("sale-btn").onclick = async () => {
    const body = {
      pharmacy_id: +pharmacySelect.value,
      employee_id: +document.getElementById("sale-employee").value,
      medicine_id: id,
      quantity: +document.getElementById("sale-qty").value,
    };
    try {
      const r = await api("/api/sales", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body),
      });
      await showMedicine(id, { text: `Створено чек №${r.order_id}` });
    } catch (e) {
      const msg = document.getElementById("sale-msg");
      msg.className = "error";
      msg.textContent = "Помилка: " + e.message;
    }
  };
}

async function loadEmployees() {
  const pharmacyId = document.getElementById("sale-pharmacy").value;
  const select = document.getElementById("sale-employee");
  if (!pharmacyId) { select.innerHTML = ""; return; }
  const rows = await api(`/api/pharmacies/${pharmacyId}/employees`);
  select.innerHTML = rows
    .map(e => `<option value="${e.employee_id}">${e.full_name}</option>`).join("");
}

async function loadPharmacies() {
  const rows = await api("/api/pharmacies");
  document.getElementById("assortment-pharmacy").innerHTML = rows
    .map(p => `<option value="${p.pharmacy_id}">${p.name}</option>`).join("");
}

document.getElementById("assortment-btn").onclick = async () => {
  const id = document.getElementById("assortment-pharmacy").value;
  const rows = await api(`/api/pharmacies/${id}/assortment`);
  fillTable(document.getElementById("assortment"), rows,
    [["name", "Препарат"], ["producer", "Виробник"], ["price", "Ціна"],
     ["quantity", "Залишок"], ["stock_value", "Вартість залишку"]]);
};

document.getElementById("price-btn").onclick = async () => {
  const price = document.getElementById("price").value;
  const r = await api(`/api/functions/cheaper-than?price=${price}`);
  document.getElementById("price-result").textContent = `${r.count} позицій`;
};

document.getElementById("region-btn").onclick = async () => {
  const region = encodeURIComponent(document.getElementById("region").value);
  const r = await api(`/api/functions/employees-by-region?region=${region}`);
  document.getElementById("region-result").textContent = `${r.count} працівників`;
};

loadMedicines();
loadPharmacies();
