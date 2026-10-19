import functools
from datetime import datetime
from flask import (
    Flask, render_template, request, redirect, url_for, session,
    jsonify, abort, g
)
from werkzeug.security import check_password_hash
from config import Config
import db

app = Flask(__name__)
app.config.from_object(Config)

# Register database teardown
app.teardown_appcontext(db.close_db)


# -----------------------------------------------------------------------------
# Authentication & Authorization Helpers
# -----------------------------------------------------------------------------

def login_required(view):
    @functools.wraps(view)
    def wrapped_view(**kwargs):
        if "user_id" not in session:
            if request.path.startswith("/api/"):
                return jsonify({"error": "Authentication required"}), 401
            return redirect(url_for("login"))
        return view(**kwargs)
    return wrapped_view


def roles(*allowed_roles):
    """
    Role-based authorization decorator.
    ADMIN: add, edit, delete
    ACCOUNTANT: add, edit
    VIEWER: read-only
    """
    def decorator(view):
        @functools.wraps(view)
        def wrapped_view(**kwargs):
            if "user_id" not in session:
                if request.path.startswith("/api/"):
                    return jsonify({"error": "Authentication required"}), 401
                return redirect(url_for("login"))
            user_role = session.get("role")
            if user_role not in allowed_roles:
                if request.path.startswith("/api/"):
                    return jsonify({
                        "error": f"Forbidden: '{user_role}' role lacks permission. Requires: {', '.join(allowed_roles)}"
                    }), 403
                abort(403)
            return view(**kwargs)
        return wrapped_view
    return decorator


@app.context_processor
def inject_global_context():
    """Inject current user and current startup info into all templates."""
    if "user_id" not in session:
        return {}

    user_id = session.get("user_id")
    # Fetch accessible startups
    startups = db.query(
        """
        SELECT s.startup_id, s.name, s.industry, s.opening_cash
        FROM startups s
        JOIN user_startup_access usa ON s.startup_id = usa.startup_id
        WHERE usa.user_id = :p_user_id
        ORDER BY s.startup_id ASC
        """,
        {"p_user_id": user_id}
    )

    current_startup_id = session.get("startup_id")
    current_startup = None
    if current_startup_id:
        for s in startups:
            if s["startup_id"] == current_startup_id:
                current_startup = s
                break

    # Default to first startup if none selected or not accessible
    if not current_startup and startups:
        current_startup = startups[0]
        session["startup_id"] = current_startup["startup_id"]

    return {
        "current_user": {
            "user_id": session.get("user_id"),
            "username": session.get("username"),
            "full_name": session.get("full_name"),
            "role": session.get("role")
        },
        "current_startup": current_startup,
        "user_startups": startups
    }


# -----------------------------------------------------------------------------
# Web Page Routes
# -----------------------------------------------------------------------------

@app.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        username = request.form.get("username", "").strip()
        password = request.form.get("password", "")

        user_rows = db.query(
            "SELECT user_id, username, full_name, password_hash, role, is_active FROM users WHERE username = :p_username",
            {"p_username": username}
        )

        if not user_rows or not check_password_hash(user_rows[0]["password_hash"], password):
            return render_template("login.html", error="Invalid credentials. Please check username and password.")

        user = user_rows[0]
        if not user["is_active"]:
            return render_template("login.html", error="Account is inactive. Contact system administrator.")

        # Set session details
        session.clear()
        session["user_id"] = user["user_id"]
        session["username"] = user["username"]
        session["full_name"] = user["full_name"]
        session["role"] = user["role"]

        # Fetch accessible startups and set default
        accessible_startups = db.query(
            "SELECT startup_id FROM user_startup_access WHERE user_id = :p_user_id ORDER BY startup_id ASC",
            {"p_user_id": user["user_id"]}
        )
        if accessible_startups:
            session["startup_id"] = accessible_startups[0]["startup_id"]
        else:
            session["startup_id"] = None

        return redirect(url_for("dashboard"))

    return render_template("login.html")


@app.route("/logout")
def logout():
    session.clear()
    return redirect(url_for("login"))


@app.route("/switch/<int:target_startup_id>")
@login_required
def switch_startup(target_startup_id):
    """Switch active startup context if user has access permission."""
    user_id = session.get("user_id")
    access = db.query(
        "SELECT COUNT(*) as cnt FROM user_startup_access WHERE user_id = :p_user_id AND startup_id = :p_startup_id",
        {"p_user_id": user_id, "p_startup_id": target_startup_id}
    )
    if access and access[0]["cnt"] > 0:
        session["startup_id"] = target_startup_id

    # Redirect back to previous page or dashboard
    return redirect(request.referrer or url_for("dashboard"))


@app.route("/")
@app.route("/dashboard")
@login_required
def dashboard():
    return render_template("dashboard.html")


@app.route("/transactions")
@login_required
def transactions():
    return render_template("transactions.html")


@app.route("/audit")
@login_required
def audit():
    return render_template("audit.html")


# -----------------------------------------------------------------------------
# JSON API Routes
# -----------------------------------------------------------------------------

@app.route("/api/accounts")
@login_required
def api_accounts():
    """List chart of accounts/categories for the current startup."""
    startup_id = session.get("startup_id")
    if not startup_id:
        return jsonify([])

    accounts = db.query(
        """
        SELECT account_id, startup_id, name, acct_type
        FROM accounts
        WHERE startup_id = :p_startup_id
        ORDER BY acct_type DESC, name ASC
        """,
        {"p_startup_id": startup_id}
    )
    return jsonify(accounts)


@app.route("/api/transactions")
@login_required
def api_transactions():
    """
    Search and paginated list of transactions for the active startup.
    Filters: q (description search), type, account, from, to, page, size.
    """
    startup_id = session.get("startup_id")
    if not startup_id:
        return jsonify({"transactions": [], "total": 0, "page": 1, "size": 10, "pages": 0})

    q = request.args.get("q", "").strip()
    txn_type = request.args.get("type", "").strip().upper()
    account_id = request.args.get("account", "").strip()
    from_date = request.args.get("from", "").strip()
    to_date = request.args.get("to", "").strip()

    try:
        page = max(1, int(request.args.get("page", 1)))
        size = max(1, min(100, int(request.args.get("size", 10))))
    except ValueError:
        page = 1
        size = 10

    where_clauses = ["t.startup_id = :p_startup_id"]
    params = {"p_startup_id": startup_id}

    if q:
        where_clauses.append("UPPER(t.description) LIKE :p_query")
        params["p_query"] = f"%{q.upper()}%"

    if txn_type in ("INCOME", "EXPENSE"):
        where_clauses.append("t.txn_type = :p_txn_type")
        params["p_txn_type"] = txn_type

    if account_id.isdigit():
        where_clauses.append("t.account_id = :p_account_id")
        params["p_account_id"] = int(account_id)

    if from_date:
        where_clauses.append("t.txn_date >= TO_DATE(:p_from_date, 'YYYY-MM-DD')")
        params["p_from_date"] = from_date

    if to_date:
        where_clauses.append("t.txn_date <= TO_DATE(:p_to_date, 'YYYY-MM-DD')")
        params["p_to_date"] = to_date

    where_sql = " AND ".join(where_clauses)

    # Count total matching rows
    count_sql = f"SELECT COUNT(*) AS total FROM transactions t WHERE {where_sql}"
    total_res = db.query(count_sql, params)
    total = total_res[0]["total"] if total_res else 0

    # Query paginated rows with account names
    offset = (page - 1) * size
    params_paged = dict(params)
    params_paged["p_offset"] = offset
    params_paged["p_limit"] = size

    data_sql = f"""
        SELECT 
            t.txn_id,
            t.startup_id,
            t.account_id,
            a.name AS account_name,
            TO_CHAR(t.txn_date, 'YYYY-MM-DD') AS txn_date,
            t.description,
            t.txn_type,
            t.amount,
            t.payment_status,
            t.created_by,
            TO_CHAR(t.created_at, 'YYYY-MM-DD HH24:MI:SS') AS created_at
        FROM transactions t
        JOIN accounts a ON t.account_id = a.account_id
        WHERE {where_sql}
        ORDER BY t.txn_date DESC, t.txn_id DESC
        OFFSET :p_offset ROWS FETCH NEXT :p_limit ROWS ONLY
    """
    rows = db.query(data_sql, params_paged)
    pages = (total + size - 1) // size if total > 0 else 0

    return jsonify({
        "transactions": rows,
        "total": total,
        "page": page,
        "size": size,
        "pages": pages
    })


@app.route("/api/transactions/nav")
@login_required
def api_transactions_nav():
    """
    Record Navigator endpoint using OFFSET ... FETCH NEXT 1 ROWS ONLY.
    Returns { total, pos, record } for First/Prev/Next/Last navigation.
    """
    startup_id = session.get("startup_id")
    if not startup_id:
        return jsonify({"total": 0, "pos": 0, "record": None})

    # Count total transactions for startup
    total_res = db.query(
        "SELECT COUNT(*) AS total FROM transactions WHERE startup_id = :p_startup_id",
        {"p_startup_id": startup_id}
    )
    total = total_res[0]["total"] if total_res else 0

    if total == 0:
        return jsonify({"total": 0, "pos": 0, "record": None})

    try:
        pos = int(request.args.get("pos", 1))
    except ValueError:
        pos = 1

    # Clamp pos between 1 and total
    pos = max(1, min(total, pos))
    offset = pos - 1

    nav_sql = """
        SELECT 
            t.txn_id,
            t.startup_id,
            t.account_id,
            a.name AS account_name,
            TO_CHAR(t.txn_date, 'YYYY-MM-DD') AS txn_date,
            t.description,
            t.txn_type,
            t.amount,
            t.payment_status,
            t.created_by,
            TO_CHAR(t.created_at, 'YYYY-MM-DD HH24:MI:SS') AS created_at
        FROM transactions t
        JOIN accounts a ON t.account_id = a.account_id
        WHERE t.startup_id = :p_startup_id
        ORDER BY t.txn_date DESC, t.txn_id DESC
        OFFSET :p_offset ROWS FETCH NEXT 1 ROWS ONLY
    """
    record_rows = db.query(nav_sql, {"p_startup_id": startup_id, "p_offset": offset})
    record = record_rows[0] if record_rows else None

    return jsonify({
        "total": total,
        "pos": pos,
        "record": record
    })


def validate_transaction_payload(data, startup_id):
    """
    Validate transaction fields on the server side:
    - description 2-200 chars
    - positive amount
    - valid date
    - category exists, belongs to startup, and its acct_type matches txn_type
    - payment_status in ('PAID', 'PENDING')
    """
    description = (data.get("description") or "").strip()
    if len(description) < 2 or len(description) > 200:
        return "Description must be between 2 and 200 characters."

    try:
        amount = float(data.get("amount", 0))
        if amount <= 0:
            return "Amount must be a positive number greater than 0."
    except (TypeError, ValueError):
        return "Amount must be a valid positive number."

    txn_type = (data.get("txn_type") or "").strip().upper()
    if txn_type not in ("INCOME", "EXPENSE"):
        return "Transaction type must be INCOME or EXPENSE."

    payment_status = (data.get("payment_status") or "PAID").strip().upper()
    if payment_status not in ("PAID", "PENDING"):
        return "Payment status must be PAID or PENDING."

    txn_date_str = (data.get("txn_date") or "").strip()
    try:
        datetime.strptime(txn_date_str, "%Y-%m-%d")
    except ValueError:
        return "Date must be in valid format (YYYY-MM-DD)."

    try:
        account_id = int(data.get("account_id", 0))
    except (TypeError, ValueError):
        return "A valid category must be selected."

    # Validate that account belongs to this startup and type matches
    acct = db.query(
        "SELECT acct_type FROM accounts WHERE account_id = :p_account_id AND startup_id = :p_startup_id",
        {"p_account_id": account_id, "p_startup_id": startup_id}
    )
    if not acct:
        return "Selected category does not exist for the active startup."

    if acct[0]["acct_type"] != txn_type:
        return f"Selected category '{acct[0]['acct_type']}' does not match transaction type '{txn_type}'."

    return None


@app.route("/api/transactions", methods=["POST"])
@roles("ADMIN", "ACCOUNTANT")
def api_add_transaction():
    """Create a new transaction with server-side validation and audit logging."""
    startup_id = session.get("startup_id")
    if not startup_id:
        return jsonify({"error": "No active startup selected."}), 400

    data = request.get_json() or {}
    validation_err = validate_transaction_payload(data, startup_id)
    if validation_err:
        return jsonify({"error": validation_err}), 400

    new_id = db.execute(
        """
        INSERT INTO transactions (
            startup_id, account_id, txn_date, description,
            txn_type, amount, payment_status, created_by
        ) VALUES (
            :p_startup_id, :p_account_id, TO_DATE(:p_txn_date, 'YYYY-MM-DD'), :p_description,
            :p_txn_type, :p_amount, :p_payment_status, :p_created_by
        ) RETURNING txn_id INTO :new_id
        """,
        {
            "p_startup_id": startup_id,
            "p_account_id": int(data["account_id"]),
            "p_txn_date": data["txn_date"].strip(),
            "p_description": data["description"].strip(),
            "p_txn_type": data["txn_type"].strip().upper(),
            "p_amount": float(data["amount"]),
            "p_payment_status": data.get("payment_status", "PAID").strip().upper(),
            "p_created_by": session.get("username", "SYSTEM")
        },
        returning_id=True
    )

    return jsonify({
        "success": True,
        "txn_id": new_id,
        "message": f"Transaction #{new_id} recorded successfully."
    }), 201


@app.route("/api/transactions/<int:txn_id>", methods=["PUT"])
@roles("ADMIN", "ACCOUNTANT")
def api_update_transaction(txn_id):
    """Update an existing transaction with server-side validation and audit logging."""
    startup_id = session.get("startup_id")
    if not startup_id:
        return jsonify({"error": "No active startup selected."}), 400

    # Ensure transaction exists in current startup
    existing = db.query(
        "SELECT txn_id FROM transactions WHERE txn_id = :p_txn_id AND startup_id = :p_startup_id",
        {"p_txn_id": txn_id, "p_startup_id": startup_id}
    )
    if not existing:
        return jsonify({"error": f"Transaction #{txn_id} not found in active startup."}), 404

    data = request.get_json() or {}
    validation_err = validate_transaction_payload(data, startup_id)
    if validation_err:
        return jsonify({"error": validation_err}), 400

    db.execute(
        """
        UPDATE transactions
        SET account_id = :p_account_id,
            txn_date = TO_DATE(:p_txn_date, 'YYYY-MM-DD'),
            description = :p_description,
            txn_type = :p_txn_type,
            amount = :p_amount,
            payment_status = :p_payment_status
        WHERE txn_id = :p_txn_id AND startup_id = :p_startup_id
        """,
        {
            "p_account_id": int(data["account_id"]),
            "p_txn_date": data["txn_date"].strip(),
            "p_description": data["description"].strip(),
            "p_txn_type": data["txn_type"].strip().upper(),
            "p_amount": float(data["amount"]),
            "p_payment_status": data.get("payment_status", "PAID").strip().upper(),
            "p_txn_id": txn_id,
            "p_startup_id": startup_id
        }
    )

    return jsonify({
        "success": True,
        "message": f"Transaction #{txn_id} updated successfully."
    })


@app.route("/api/transactions/<int:txn_id>", methods=["DELETE"])
@roles("ADMIN")
def api_delete_transaction(txn_id):
    """Delete a transaction. Strictly limited to ADMIN role."""
    startup_id = session.get("startup_id")
    if not startup_id:
        return jsonify({"error": "No active startup selected."}), 400

    existing = db.query(
        "SELECT txn_id FROM transactions WHERE txn_id = :p_txn_id AND startup_id = :p_startup_id",
        {"p_txn_id": txn_id, "p_startup_id": startup_id}
    )
    if not existing:
        return jsonify({"error": f"Transaction #{txn_id} not found in active startup."}), 404

    db.execute(
        "DELETE FROM transactions WHERE txn_id = :p_txn_id AND startup_id = :p_startup_id",
        {"p_txn_id": txn_id, "p_startup_id": startup_id}
    )

    return jsonify({
        "success": True,
        "message": f"Transaction #{txn_id} deleted successfully."
    })


@app.route("/api/audit")
@login_required
def api_audit():
    """List recent audit logs for the current startup."""
    startup_id = session.get("startup_id")
    if not startup_id:
        return jsonify([])

    audit_rows = db.query(
        """
        SELECT 
            audit_id,
            startup_id,
            table_name,
            record_id,
            action,
            old_value,
            new_value,
            changed_by,
            TO_CHAR(changed_at, 'YYYY-MM-DD HH24:MI:SS') AS changed_at
        FROM audit_log
        WHERE startup_id = :p_startup_id
        ORDER BY audit_id DESC
        FETCH FIRST 100 ROWS ONLY
        """,
        {"p_startup_id": startup_id}
    )
    return jsonify(audit_rows)


@app.route("/api/sql-log")
@login_required
def api_sql_log():
    """Return the recent executed SQL log for the Live SQL Inspector."""
    return jsonify(db.get_sql_log())


@app.route("/api/dashboard")
@login_required
def api_dashboard():
    """
    Compute startup financial health metrics exclusively via SQL:
    - Cash in bank = opening_cash + PAID income - PAID expense
    - Revenue = total PAID income
    - Expenses = total PAID expense
    - Profit = Revenue - Expenses
    - Receivables = PENDING income
    - Payables = PENDING expense
    - Burn = max(0, -(net PAID cash flow over the last 90 days)/3)
    - Runway months = Cash / Burn (null if burn == 0)
    - Status = Cleared for takeoff (>= 9 mo or no burn), Turbulence ahead (4-9), Low fuel warning (< 4)
    - Monthly revenue vs expenses for the last 6 months
    - Top 6 expense categories
    - 6 most recent transactions
    """
    startup_id = session.get("startup_id")
    if not startup_id:
        return jsonify({"error": "No active startup selected."}), 400

    # 1. Primary financial KPIs
    kpi_query = """
        SELECT 
            s.name AS startup_name,
            s.industry,
            s.opening_cash,
            NVL(SUM(CASE WHEN t.txn_type = 'INCOME' AND t.payment_status = 'PAID' THEN t.amount ELSE 0 END), 0) AS paid_income,
            NVL(SUM(CASE WHEN t.txn_type = 'EXPENSE' AND t.payment_status = 'PAID' THEN t.amount ELSE 0 END), 0) AS paid_expense,
            NVL(SUM(CASE WHEN t.txn_type = 'INCOME' AND t.payment_status = 'PENDING' THEN t.amount ELSE 0 END), 0) AS receivables,
            NVL(SUM(CASE WHEN t.txn_type = 'EXPENSE' AND t.payment_status = 'PENDING' THEN t.amount ELSE 0 END), 0) AS payables,
            NVL(SUM(CASE WHEN t.txn_type = 'INCOME' AND t.payment_status = 'PAID' AND t.txn_date >= TRUNC(SYSDATE) - 90 THEN t.amount ELSE 0 END), 0) AS q_paid_income,
            NVL(SUM(CASE WHEN t.txn_type = 'EXPENSE' AND t.payment_status = 'PAID' AND t.txn_date >= TRUNC(SYSDATE) - 90 THEN t.amount ELSE 0 END), 0) AS q_paid_expense
        FROM startups s
        LEFT JOIN transactions t ON s.startup_id = t.startup_id
        WHERE s.startup_id = :p_startup_id
        GROUP BY s.startup_id, s.name, s.industry, s.opening_cash
    """
    kpis = db.query(kpi_query, {"p_startup_id": startup_id})
    if not kpis:
        return jsonify({"error": "Startup not found."}), 404

    row = kpis[0]
    opening_cash = float(row["opening_cash"])
    paid_income = float(row["paid_income"])
    paid_expense = float(row["paid_expense"])
    receivables = float(row["receivables"])
    payables = float(row["payables"])

    cash_in_bank = opening_cash + paid_income - paid_expense
    revenue = paid_income
    expenses = paid_expense
    profit = revenue - expenses

    # Burn calculation: 90-day net cash flow divided by 3 months
    q_income = float(row["q_paid_income"])
    q_expense = float(row["q_paid_expense"])
    net_90d_cash_flow = q_income - q_expense
    burn = max(0.0, - (net_90d_cash_flow / 3.0))

    if burn > 0:
        runway_months = round(cash_in_bank / burn, 1)
        if runway_months >= 9:
            status = "Cleared for takeoff"
            status_level = "success"
        elif runway_months >= 4:
            status = "Turbulence ahead"
            status_level = "warning"
        else:
            status = "Low fuel warning"
            status_level = "danger"
    else:
        runway_months = None
        status = "Cleared for takeoff"
        status_level = "success"

    # 2. Monthly trend: last 6 calendar months
    trend_query = """
        SELECT 
            TO_CHAR(t.txn_date, 'YYYY-MM') AS month_label,
            NVL(SUM(CASE WHEN t.txn_type = 'INCOME' AND t.payment_status = 'PAID' THEN t.amount ELSE 0 END), 0) AS revenue,
            NVL(SUM(CASE WHEN t.txn_type = 'EXPENSE' AND t.payment_status = 'PAID' THEN t.amount ELSE 0 END), 0) AS expenses
        FROM transactions t
        WHERE t.startup_id = :p_startup_id
          AND t.txn_date >= ADD_MONTHS(TRUNC(SYSDATE, 'MM'), -5)
        GROUP BY TO_CHAR(t.txn_date, 'YYYY-MM')
        ORDER BY month_label ASC
    """
    monthly_trends = db.query(trend_query, {"p_startup_id": startup_id})

    # 3. Top 6 Expense Categories
    top_exp_query = """
        SELECT 
            a.name AS category_name,
            NVL(SUM(t.amount), 0) AS total_amount
        FROM transactions t
        JOIN accounts a ON t.account_id = a.account_id
        WHERE t.startup_id = :p_startup_id
          AND t.txn_type = 'EXPENSE'
          AND t.payment_status = 'PAID'
        GROUP BY a.name
        ORDER BY total_amount DESC
        FETCH FIRST 6 ROWS ONLY
    """
    top_expenses = db.query(top_exp_query, {"p_startup_id": startup_id})

    # 4. Recent 6 Transactions
    recent_query = """
        SELECT 
            t.txn_id,
            t.startup_id,
            t.account_id,
            a.name AS account_name,
            TO_CHAR(t.txn_date, 'YYYY-MM-DD') AS txn_date,
            t.description,
            t.txn_type,
            t.amount,
            t.payment_status
        FROM transactions t
        JOIN accounts a ON t.account_id = a.account_id
        WHERE t.startup_id = :p_startup_id
        ORDER BY t.txn_date DESC, t.txn_id DESC
        FETCH FIRST 6 ROWS ONLY
    """
    recent_txns = db.query(recent_query, {"p_startup_id": startup_id})

    return jsonify({
        "startup": {
            "startup_id": startup_id,
            "name": row["startup_name"],
            "industry": row["industry"],
            "opening_cash": opening_cash
        },
        "kpis": {
            "cash_in_bank": cash_in_bank,
            "revenue": revenue,
            "expenses": expenses,
            "profit": profit,
            "receivables": receivables,
            "payables": payables,
            "burn": round(burn, 2),
            "runway_months": runway_months,
            "status": status,
            "status_level": status_level
        },
        "monthly_trends": monthly_trends,
        "top_expenses": top_expenses,
        "recent_transactions": recent_txns
    })


if __name__ == "__main__":
    app.run(debug=True, port=5000)
