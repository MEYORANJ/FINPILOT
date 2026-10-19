# FinPilot ✈️ — Startup Financial Flight Control

A full-stack startup financial management web application built for a university **Database Systems** assignment, powered by **Oracle Database 21c Express Edition** and **Python Flask**.

---

## 🛫 Key Features & Architecture

### 1. Authentic Oracle Database 21c XE Layer
- **Relational Schema**: 6 core tables utilizing `GENERATED ALWAYS AS IDENTITY` primary keys, foreign keys with `ON DELETE CASCADE`, composite access keys, and domain `CHECK` / `UNIQUE` constraints.
- **Indexes**: Composite index on `(startup_id, txn_date)` and function-based index on `UPPER(description)`.
- **Row-Level PL/SQL Audit Trigger**: `trg_transactions_audit` captures every `INSERT`, `UPDATE`, and `DELETE` on the ledger along with before-and-after snapshots, retrieving the active operator identity via `SYS_CONTEXT('USERENV', 'CLIENT_INFO')`.

### 2. Python Flask Backend (`python-oracledb`)
- **Thin Driver Connectivity**: Direct TCP connection without requiring Oracle Instant Client installations.
- **Strict Parameterization**: Enforces bind variables across all queries to prevent SQL injection.
- **Role-Based Access Control (RBAC)**:
  - `ADMIN`: Full access (Add, Edit, and Delete transactions).
  - `ACCOUNTANT`: Operational access (Add and Edit transactions).
  - `VIEWER`: Read-only access (Server rejects modifications with `403 Forbidden`).
- **Telemetry Computation**: SQL-computed cash balances, 90-day burn rate, runway months, and aeronautical status (`Cleared for takeoff`, `Turbulence ahead`, `Low fuel warning`).
- **Live SQL Inspector**: Maintains a memory trace (`deque`) of the last 50 executed queries, bind parameters, and execution timings in milliseconds.

### 3. Aeronautical Cockpit Frontend
- **Design System**: Dark navy sidebar (`#0B132B`) with amber accents (`#F59E0B`), crisp metric cards, and plain-English explanatory subtitles.
- **Indian Rupee Standard**: All financial values formatted using standard Indian numbering (`en-IN`, e.g. `₹15,00,000`).
- **Flight Deck**: Coloured status strip, 6 primary KPI cards, SVG semicircle runway gauge, Chart.js 6-month trajectory, and top expense category bars.
- **Flight Ledger**: Search filter, category filters, server-paginated table, and **Direct Record Navigator** using Oracle `OFFSET ... FETCH NEXT 1 ROWS ONLY`.
- **Black Box**: Visual inspection table of all trigger-recorded audit transitions.

---

## 🛠️ Project Structure

```text
finpilot/
├── .env.example                 # Environment configuration template
├── .gitignore                   # Excludes .env, venv/, and build artifacts
├── requirements.txt             # Python dependencies (flask, oracledb, python-dotenv)
├── config.py                    # Environment variable loader
├── db.py                        # Per-request Oracle connection & SQL logger
├── app.py                       # Application endpoints, RBAC, and JSON APIs
├── seed_users.py                # User credentials & startup access seeder
├── sql/
│   ├── 01_schema.sql            # Re-runnable DDL, tables, constraints, trigger
│   └── 02_seed.sql              # Disables trigger, seeds startups, accounts, 78 transactions
├── templates/
│   ├── base.html                # Navigation shell, startup switcher, SQL drawer
│   ├── login.html               # Two-panel login page with quick-fill credentials
│   ├── dashboard.html           # Flight Deck telemetry & analytics
│   ├── transactions.html        # Ledger table, modals, Record Navigator
│   └── audit.html               # Black Box flight recorder table
└── static/
    ├── css/
    │   └── app.css              # Custom cockpit styles (No Bootstrap/Tailwind)
    └── js/
        ├── app.js               # INR currency format, toasts, SQL Inspector
        └── transactions.js      # Ledger controls, modals, Record Navigator
```

---

## 🚀 Quick Start Guide

### 1. Prerequisites
- Windows OS with PowerShell
- Python 3.11+
- Oracle Database 21c Express Edition (XE) with `finpilot_user` created

### 2. Setup Environment
```powershell
# Clone the repository
git clone https://github.com/YOUR_USERNAME/finpilot.git
cd finpilot

# Create and activate virtual environment
python -m venv venv
.\venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
```

### 3. Configure Database Credentials
Create a `.env` file in the project root (copied from `.env.example`):
```ini
DB_USER=finpilot_user
DB_PASSWORD=YOUR_ORACLE_PASSWORD
DB_DSN=localhost:1521/XEPDB1
SECRET_KEY=your_secret_key_here
```

### 4. Initialize Database Schema & Seed Data
Execute the SQL scripts from the project root using SQL*Plus:
```powershell
sqlplus finpilot_user/"YOUR_PASSWORD"@//localhost:1521/XEPDB1
```
Inside SQL*Plus:
```sql
@sql/01_schema.sql
@sql/02_seed.sql
EXIT;
```

### 5. Seed Users & Permissions
```powershell
python seed_users.py
```

### 6. Launch FinPilot
```powershell
python app.py
```
Open your browser and navigate to: **`http://localhost:5000`**

---

## 👥 Demo Accounts

| Username | Password | Role | Capabilities |
|---|---|:---:|---|
| **`admin`** | `admin123` | `ADMIN` | Full flight deck control: Add, Edit, Delete transactions |
| **`accountant`** | `acc123` | `ACCOUNTANT` | Ledger controller: Add and Edit transactions |
| **`viewer`** | `view123` | `VIEWER` | Audit observer: Read-only access (403 on mutations) |
