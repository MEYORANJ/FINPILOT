/**
 * FinPilot Core Flight Control JS
 * Handles Indian Rupee formatting, toasts, and Live SQL Inspector drawer.
 */

// Format numbers in Indian Rupee format (en-IN grouping e.g. ₹5,00,000)
function formatRupee(amount) {
  if (amount === null || amount === undefined || isNaN(amount)) {
    return "₹0";
  }
  return new Intl.NumberFormat("en-IN", {
    style: "currency",
    currency: "INR",
    maximumFractionDigits: 0
  }).format(amount);
}

// Global Toast System
function showToast(message, type = "success") {
  let container = document.getElementById("toast-container");
  if (!container) {
    container = document.createElement("div");
    container.id = "toast-container";
    container.className = "toast-container";
    document.body.appendChild(container);
  }

  const toast = document.createElement("div");
  toast.className = `toast toast-${type}`;
  toast.innerHTML = `
    <span>${type === "error" ? "⚠️" : "✈️"}</span>
    <div>${message}</div>
  `;

  container.appendChild(toast);

  setTimeout(() => {
    toast.style.opacity = "0";
    toast.style.transform = "translateX(100%)";
    toast.style.transition = "all 0.3s ease";
    setTimeout(() => toast.remove(), 300);
  }, 4000);
}

// Live SQL Inspector
function toggleSqlDrawer() {
  const drawer = document.getElementById("sql-inspector-drawer");
  if (!drawer) return;
  drawer.classList.toggle("open");
  if (drawer.classList.contains("open")) {
    refreshSqlLog();
  }
}

async function refreshSqlLog() {
  const container = document.getElementById("sql-log-entries");
  if (!container) return;

  container.innerHTML = '<div style="color: #94a3b8; padding: 20px 0; text-align: center;">Fetching database execution logs...</div>';

  try {
    const res = await fetch("/api/sql-log");
    const logs = await res.json();

    const countBadge = document.getElementById("sql-query-count");
    if (countBadge) {
      countBadge.textContent = logs.length;
    }

    if (!logs || logs.length === 0) {
      container.innerHTML = '<div style="color: #94a3b8; padding: 20px 0; text-align: center;">No queries captured yet.</div>';
      return;
    }

    container.innerHTML = logs.map(entry => {
      const paramsJson = Object.keys(entry.params || {}).length > 0 
        ? JSON.stringify(entry.params, null, 2) 
        : "None (No bind parameters)";

      return `
        <div class="sql-log-entry">
          <div class="sql-log-header">
            <span>⏱️ ${entry.time}</span>
            <span class="sql-duration-tag">${entry.elapsed_ms} ms</span>
          </div>
          <div class="sql-text-block">${escapeHtml(entry.sql)}</div>
          <div class="sql-params-block">
            <strong>Binds:</strong> ${escapeHtml(paramsJson)}
          </div>
        </div>
      `;
    }).join("");
  } catch (err) {
    container.innerHTML = `<div style="color: #ef4444; padding: 20px 0;">Error fetching SQL logs: ${err.message}</div>`;
  }
}

function escapeHtml(str) {
  if (!str) return "";
  return str
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

document.addEventListener("DOMContentLoaded", () => {
  // Bind SQL drawer trigger
  const btnInspector = document.getElementById("btn-open-sql-inspector");
  if (btnInspector) {
    btnInspector.addEventListener("click", toggleSqlDrawer);
  }

  const btnCloseInspector = document.getElementById("btn-close-sql-inspector");
  if (btnCloseInspector) {
    btnCloseInspector.addEventListener("click", toggleSqlDrawer);
  }

  const btnRefreshSql = document.getElementById("btn-refresh-sql");
  if (btnRefreshSql) {
    btnRefreshSql.addEventListener("click", refreshSqlLog);
  }
});
