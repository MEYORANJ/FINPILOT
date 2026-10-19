/**
 * FinPilot Transactions Management
 * Handles pagination, search, category filtering, Add/Edit modals,
 * Delete confirmations, and the Direct DB Record Navigator.
 */

let allAccounts = [];
let currentPage = 1;
const pageSize = 10;
let totalPages = 1;

let navPos = 1;
let navTotal = 0;
let deleteTargetId = null;

// Initialize on DOM load
document.addEventListener("DOMContentLoaded", async () => {
  await loadAccounts();
  await loadTransactions(1);
  await loadNavRecord(1);

  // Bind filter events
  const searchInput = document.getElementById("filter-search");
  let debounceTimeout = null;
  searchInput.addEventListener("input", () => {
    clearTimeout(debounceTimeout);
    debounceTimeout = setTimeout(() => loadTransactions(1), 300);
  });

  document.getElementById("filter-type").addEventListener("change", () => loadTransactions(1));
  document.getElementById("filter-account").addEventListener("change", () => loadTransactions(1));
  document.getElementById("filter-from").addEventListener("change", () => loadTransactions(1));
  document.getElementById("filter-to").addEventListener("change", () => loadTransactions(1));

  document.getElementById("btn-reset-filters").addEventListener("click", () => {
    document.getElementById("filter-search").value = "";
    document.getElementById("filter-type").value = "";
    document.getElementById("filter-account").value = "";
    document.getElementById("filter-from").value = "";
    document.getElementById("filter-to").value = "";
    loadTransactions(1);
  });

  // Pagination buttons
  document.getElementById("btn-page-prev").addEventListener("click", () => {
    if (currentPage > 1) loadTransactions(currentPage - 1);
  });

  document.getElementById("btn-page-next").addEventListener("click", () => {
    if (currentPage < totalPages) loadTransactions(currentPage + 1);
  });

  // Navigator buttons
  document.getElementById("btn-nav-first").addEventListener("click", () => loadNavRecord(1));
  document.getElementById("btn-nav-prev").addEventListener("click", () => loadNavRecord(navPos - 1));
  document.getElementById("btn-nav-next").addEventListener("click", () => loadNavRecord(navPos + 1));
  document.getElementById("btn-nav-last").addEventListener("click", () => loadNavRecord(navTotal));

  // Add transaction button (if role permits)
  const btnAdd = document.getElementById("btn-add-transaction");
  if (btnAdd) {
    btnAdd.addEventListener("click", openAddModal);
  }

  // Modal close buttons
  document.getElementById("btn-close-modal").addEventListener("click", closeTxnModal);
  document.getElementById("btn-cancel-modal").addEventListener("click", closeTxnModal);
  document.getElementById("txn-form").addEventListener("submit", handleFormSubmit);

  // Delete modal buttons
  document.getElementById("btn-close-delete-modal").addEventListener("click", closeDeleteModal);
  document.getElementById("btn-cancel-delete").addEventListener("click", closeDeleteModal);
  document.getElementById("btn-confirm-delete").addEventListener("click", handleConfirmDelete);
});

// Load Chart of Accounts
async function loadAccounts() {
  try {
    const res = await fetch("/api/accounts");
    allAccounts = await res.json();

    const filterSelect = document.getElementById("filter-account");
    filterSelect.innerHTML = '<option value="">All Categories</option>';
    allAccounts.forEach(acct => {
      const opt = document.createElement("option");
      opt.value = acct.account_id;
      opt.textContent = `[${acct.acct_type}] ${acct.name}`;
      filterSelect.appendChild(opt);
    });
  } catch (err) {
    console.error("Error loading accounts:", err);
  }
}

// Load paginated transactions
async function loadTransactions(page = 1) {
  currentPage = page;
  const q = document.getElementById("filter-search").value.trim();
  const type = document.getElementById("filter-type").value;
  const account = document.getElementById("filter-account").value;
  const from = document.getElementById("filter-from").value;
  const to = document.getElementById("filter-to").value;

  const params = new URLSearchParams({
    page: currentPage,
    size: pageSize
  });
  if (q) params.set("q", q);
  if (type) params.set("type", type);
  if (account) params.set("account", account);
  if (from) params.set("from", from);
  if (to) params.set("to", to);

  const tbody = document.getElementById("transactions-tbody");
  tbody.innerHTML = '<tr><td colspan="8" style="text-align:center; padding: 20px; color: var(--slate-600);">Fetching records from Oracle...</td></tr>';

  try {
    const res = await fetch(`/api/transactions?${params.toString()}`);
    const data = await res.json();

    totalPages = data.pages || 1;
    document.getElementById("filter-count-display").textContent = data.total;
    document.getElementById("pagination-info").textContent = `Page ${data.page} of ${totalPages || 1} (${data.total} total records)`;

    document.getElementById("btn-page-prev").disabled = data.page <= 1;
    document.getElementById("btn-page-next").disabled = data.page >= totalPages;

    if (!data.transactions || data.transactions.length === 0) {
      tbody.innerHTML = '<tr><td colspan="8" style="text-align: center; padding: 30px; color: var(--slate-600);">No transactions matching criteria.</td></tr>';
      return;
    }

    const userRole = window.currentUserRole || "VIEWER";
    const canEdit = userRole === "ADMIN" || userRole === "ACCOUNTANT";
    const canDelete = userRole === "ADMIN";

    tbody.innerHTML = data.transactions.map(t => {
      const isIncome = t.txn_type === "INCOME";
      const isPaid = t.payment_status === "PAID";

      let actionsHtml = "";
      if (canEdit || canDelete) {
        actionsHtml = `
          <td style="text-align: right; white-space: nowrap;">
            ${canEdit ? `<button class="btn btn-secondary btn-sm" onclick="editTransaction(${t.txn_id})" title="Edit Transaction">✏️ Edit</button>` : ""}
            ${canDelete ? `<button class="btn btn-danger btn-sm" onclick="promptDelete(${t.txn_id})" style="margin-left: 4px;" title="Delete Record">🗑️</button>` : ""}
          </td>
        `;
      }

      return `
        <tr>
          <td style="font-family: var(--font-mono); font-size: 11.5px; color: var(--slate-600);">#${t.txn_id}</td>
          <td style="font-family: var(--font-mono); font-size: 12px;">${t.txn_date}</td>
          <td style="font-weight: 600;">${escapeHtml(t.account_name)}</td>
          <td style="max-width: 280px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;" title="${escapeHtml(t.description)}">
            ${escapeHtml(t.description)}
          </td>
          <td>
            <span class="badge ${isIncome ? 'badge-income' : 'badge-expense'}">
              ${isIncome ? '↑ INCOME' : '↓ EXPENSE'}
            </span>
          </td>
          <td style="font-weight: 700; ${isIncome ? 'color: #059669;' : 'color: #1e293b;'}">
            ${isIncome ? '+' : '-'}${formatRupee(t.amount)}
          </td>
          <td>
            <span class="badge ${isPaid ? 'badge-paid' : 'badge-pending'}">
              ${isPaid ? 'PAID' : 'PENDING'}
            </span>
          </td>
          ${actionsHtml}
        </tr>
      `;
    }).join("");

  } catch (err) {
    tbody.innerHTML = `<tr><td colspan="8" style="text-align: center; color: #ef4444; padding: 20px;">Error: ${err.message}</td></tr>`;
  }
}

// Load Direct Record Navigator using OFFSET ... FETCH NEXT
async function loadNavRecord(pos) {
  try {
    const res = await fetch(`/api/transactions/nav?pos=${pos}`);
    const data = await res.json();

    navPos = data.pos || 1;
    navTotal = data.total || 0;

    document.getElementById("nav-pos-display").textContent = `Record ${navPos} of ${navTotal}`;

    document.getElementById("btn-nav-first").disabled = navPos <= 1;
    document.getElementById("btn-nav-prev").disabled = navPos <= 1;
    document.getElementById("btn-nav-next").disabled = navPos >= navTotal;
    document.getElementById("btn-nav-last").disabled = navPos >= navTotal;

    const detailCard = document.getElementById("nav-detail-card");
    if (!data.record) {
      detailCard.innerHTML = '<div style="color: #94a3b8;">No records in active startup ledger.</div>';
      return;
    }

    const r = data.record;
    const isIncome = r.txn_type === "INCOME";
    detailCard.innerHTML = `
      <div style="display: flex; justify-content: space-between; align-items: baseline; margin-bottom: 2px;">
        <span style="font-weight: 700; color: #fff;">#${r.txn_id} &bull; ${escapeHtml(r.account_name)}</span>
        <span style="font-weight: 800; font-size: 14px; color: ${isIncome ? '#10b981' : '#f87171'};">
          ${isIncome ? '+' : '-'}${formatRupee(r.amount)}
        </span>
      </div>
      <div style="color: #cbd5e1; font-size: 12px;">${escapeHtml(r.description)}</div>
      <div style="display: flex; gap: 12px; margin-top: 4px; font-size: 11px; color: #94a3b8;">
        <span>📅 ${r.txn_date}</span>
        <span>🏷️ ${r.payment_status}</span>
        <span>👤 Logged by: ${escapeHtml(r.created_by)}</span>
      </div>
    `;
  } catch (err) {
    console.error("Navigator fetch error:", err);
  }
}

// Update modal category options according to active type radio
function handleTypeChange() {
  const selectedType = document.querySelector('input[name="modal_txn_type"]:checked').value;
  const select = document.getElementById("modal-account");
  const currentVal = select.value;

  select.innerHTML = '<option value="">Select category...</option>';
  const matchingAccounts = allAccounts.filter(a => a.acct_type === selectedType);
  matchingAccounts.forEach(acct => {
    const opt = document.createElement("option");
    opt.value = acct.account_id;
    opt.textContent = acct.name;
    if (String(acct.account_id) === String(currentVal)) {
      opt.selected = true;
    }
    select.appendChild(opt);
  });
}

function openAddModal() {
  document.getElementById("modal-title").textContent = "Log New Transaction";
  document.getElementById("modal-txn-id").value = "";
  document.getElementById("txn-form").reset();

  // Default to today's date
  const today = new Date().toISOString().split("T")[0];
  document.getElementById("modal-date").value = today;

  // Default to Expense
  document.querySelector('input[name="modal_txn_type"][value="EXPENSE"]').checked = true;
  handleTypeChange();

  document.getElementById("txn-modal").classList.add("active");
}

async function editTransaction(id) {
  try {
    // Fetch transaction by navigation or filter
    const res = await fetch(`/api/transactions?q=&size=100`);
    const data = await res.json();
    const txn = data.transactions.find(t => t.txn_id === id);

    if (!txn) {
      showToast(`Transaction #${id} details could not be retrieved.`, "error");
      return;
    }

    document.getElementById("modal-title").textContent = `Edit Transaction #${txn.txn_id}`;
    document.getElementById("modal-txn-id").value = txn.txn_id;
    document.getElementById("modal-desc").value = txn.description;
    document.getElementById("modal-amount").value = txn.amount;
    document.getElementById("modal-date").value = txn.txn_date;
    document.getElementById("modal-status").value = txn.payment_status;

    const typeRadio = document.querySelector(`input[name="modal_txn_type"][value="${txn.txn_type}"]`);
    if (typeRadio) typeRadio.checked = true;

    handleTypeChange();
    document.getElementById("modal-account").value = txn.account_id;

    document.getElementById("txn-modal").classList.add("active");
  } catch (err) {
    showToast("Error opening edit modal: " + err.message, "error");
  }
}

function closeTxnModal() {
  document.getElementById("txn-modal").classList.remove("active");
}

async function handleFormSubmit(e) {
  e.preventDefault();
  const txnId = document.getElementById("modal-txn-id").value;
  const isEdit = Boolean(txnId);

  const payload = {
    txn_type: document.querySelector('input[name="modal_txn_type"]:checked').value,
    account_id: document.getElementById("modal-account").value,
    txn_date: document.getElementById("modal-date").value,
    description: document.getElementById("modal-desc").value,
    amount: parseFloat(document.getElementById("modal-amount").value),
    payment_status: document.getElementById("modal-status").value
  };

  const url = isEdit ? `/api/transactions/${txnId}` : "/api/transactions";
  const method = isEdit ? "PUT" : "POST";

  try {
    const res = await fetch(url, {
      method: method,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload)
    });

    const data = await res.json();
    if (!res.ok) {
      throw new Error(data.error || "Transaction submission failed.");
    }

    closeTxnModal();
    showToast(data.message || "Transaction recorded successfully!", "success");
    await loadTransactions(currentPage);
    await loadNavRecord(navPos);
  } catch (err) {
    showToast(err.message, "error");
  }
}

function promptDelete(id) {
  deleteTargetId = id;
  document.getElementById("delete-txn-id-display").textContent = `#${id}`;
  document.getElementById("delete-modal").classList.add("active");
}

function closeDeleteModal() {
  deleteTargetId = null;
  document.getElementById("delete-modal").classList.remove("active");
}

async function handleConfirmDelete() {
  if (!deleteTargetId) return;

  try {
    const res = await fetch(`/api/transactions/${deleteTargetId}`, {
      method: "DELETE"
    });
    const data = await res.json();
    if (!res.ok) {
      throw new Error(data.error || "Deletion failed.");
    }

    closeDeleteModal();
    showToast(data.message || `Transaction #${deleteTargetId} deleted.`, "success");
    await loadTransactions(currentPage);
    await loadNavRecord(1);
  } catch (err) {
    closeDeleteModal();
    showToast(err.message, "error");
  }
}
