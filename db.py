import time
from collections import deque
from datetime import datetime, date
from decimal import Decimal
import oracledb
from flask import g, session, has_request_context
from config import Config

# Deque storing the last 50 executed SQL queries for the Live SQL Inspector
sql_log = deque(maxlen=50)


def sanitize_val(val):
    """Make bind values JSON-serializable for the SQL inspector."""
    if isinstance(val, (datetime, date)):
        return val.isoformat()
    if isinstance(val, Decimal):
        return float(val)
    if isinstance(val, oracledb.Var):
        return "<OUT_VAR>"
    return val


def sanitize_params(params):
    """Sanitize parameters dict or list for JSON serialization."""
    if params is None:
        return {}
    if isinstance(params, dict):
        return {k: sanitize_val(v) for k, v in params.items()}
    if isinstance(params, (list, tuple)):
        return [sanitize_val(v) for v in params]
    return sanitize_val(params)


def log_sql(sql_text, params, elapsed_ms):
    """Store executed query details in the memory deque."""
    sql_log.append({
        "time": datetime.now().strftime("%H:%M:%S.%f")[:-3],
        "sql": sql_text.strip(),
        "params": sanitize_params(params),
        "elapsed_ms": round(elapsed_ms, 2)
    })


def get_db():
    """Retrieve or create an Oracle connection per Flask request context."""
    if has_request_context():
        if "db" not in g:
            g.db = oracledb.connect(
                user=Config.DB_USER,
                password=Config.DB_PASSWORD,
                dsn=Config.DB_DSN
            )
        # Update client_info so Oracle userenv context reflects current logged in user
        username = session.get("username", "SYSTEM") if "username" in session else "SYSTEM"
        g.db.clientinfo = username
        return g.db
    else:
        # Fallback for standalone scripts (e.g. seed_users.py)
        conn = oracledb.connect(
            user=Config.DB_USER,
            password=Config.DB_PASSWORD,
            dsn=Config.DB_DSN
        )
        conn.clientinfo = "SYSTEM"
        return conn


def close_db(e=None):
    """Close the Oracle connection at request teardown."""
    if has_request_context():
        db = g.pop("db", None)
        if db is not None:
            db.close()


def query(sql, params=None):
    """Execute a SELECT query and return rows as a list of dicts with lowercase keys."""
    conn = get_db()
    cursor = conn.cursor()
    params_dict = params or {}
    start_time = time.perf_counter()
    try:
        cursor.execute(sql, params_dict)
        elapsed_ms = (time.perf_counter() - start_time) * 1000
        log_sql(sql, params_dict, elapsed_ms)

        if cursor.description is None:
            return []

        cols = [col[0].lower() for col in cursor.description]
        rows = []
        for r in cursor.fetchall():
            row_dict = {}
            for col, val in zip(cols, r):
                if hasattr(val, "read"):  # CLOB / LOB
                    val = val.read()
                elif isinstance(val, (datetime, date)):
                    val = val.isoformat()
                elif isinstance(val, Decimal):
                    val = float(val)
                row_dict[col] = val
            rows.append(row_dict)
        return rows
    except Exception as e:
        elapsed_ms = (time.perf_counter() - start_time) * 1000
        log_sql(f"{sql} [ERROR: {e}]", params_dict, elapsed_ms)
        raise
    finally:
        cursor.close()
        if not has_request_context():
            conn.close()


def execute(sql, params=None, returning_id=False):
    """
    Execute an INSERT, UPDATE, or DELETE statement.
    Commits on success, rolls back on error.
    Supports RETURNING ... INTO :new_id if returning_id=True.
    """
    conn = get_db()
    cursor = conn.cursor()
    params_dict = dict(params) if params else {}
    out_id = None
    if returning_id:
        out_id = cursor.var(oracledb.NUMBER)
        params_dict["new_id"] = out_id

    start_time = time.perf_counter()
    try:
        cursor.execute(sql, params_dict)
        conn.commit()
        elapsed_ms = (time.perf_counter() - start_time) * 1000

        # Replace cursor var with friendly placeholder for logging
        log_params = {k: ("<OUT_ID>" if v is out_id else v) for k, v in params_dict.items()}
        log_sql(sql, log_params, elapsed_ms)

        if returning_id and out_id is not None:
            val = out_id.getvalue()
            return val[0] if isinstance(val, list) and len(val) > 0 else val
        return cursor.rowcount
    except Exception as e:
        conn.rollback()
        elapsed_ms = (time.perf_counter() - start_time) * 1000
        log_params = {k: ("<OUT_ID>" if v is out_id else v) for k, v in params_dict.items()}
        log_sql(f"{sql} [ERROR: {e}]", log_params, elapsed_ms)
        raise
    finally:
        cursor.close()
        if not has_request_context():
            conn.close()


def get_sql_log():
    """Return the recent SQL queries log as a list (newest first)."""
    return list(reversed(sql_log))
