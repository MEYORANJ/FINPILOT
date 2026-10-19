-- ============================================================================
-- FinPilot Database Schema
-- File: sql/01_schema.sql
-- Description: Re-runnable DDL script for Oracle Database 21c XE
-- ============================================================================

SET FEEDBACK ON;
SET SERVEROUTPUT ON;
SET LINESIZE 120;
SET PAGESIZE 50;
SET DEFINE OFF;

PROMPT ============================================================================
PROMPT Dropping existing tables if present...
PROMPT ============================================================================

BEGIN
    FOR cur IN (
        SELECT table_name 
        FROM user_tables 
        WHERE table_name IN ('AUDIT_LOG', 'TRANSACTIONS', 'ACCOUNTS', 'USER_STARTUP_ACCESS', 'USERS', 'STARTUPS')
    ) LOOP
        EXECUTE IMMEDIATE 'DROP TABLE ' || cur.table_name || ' CASCADE CONSTRAINTS PURGE';
        DBMS_OUTPUT.PUT_LINE('Dropped table: ' || cur.table_name);
    END LOOP;
END;
/

PROMPT ============================================================================
PROMPT Creating tables...
PROMPT ============================================================================

-- 1. Startups
CREATE TABLE startups (
    startup_id   NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name         VARCHAR2(100) NOT NULL UNIQUE,
    industry     VARCHAR2(100) NOT NULL,
    opening_cash NUMBER(15, 2) DEFAULT 0 NOT NULL CONSTRAINT chk_startups_opening_cash CHECK (opening_cash >= 0),
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- 2. Users
CREATE TABLE users (
    user_id       NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username      VARCHAR2(50) NOT NULL UNIQUE,
    full_name     VARCHAR2(100) NOT NULL,
    password_hash VARCHAR2(255) NOT NULL,
    role          VARCHAR2(20) NOT NULL CONSTRAINT chk_users_role CHECK (role IN ('ADMIN', 'ACCOUNTANT', 'VIEWER')),
    is_active     NUMBER(1) DEFAULT 1 NOT NULL CONSTRAINT chk_users_active CHECK (is_active IN (0, 1))
);

-- 3. User-Startup Access (Composite PK, ON DELETE CASCADE)
CREATE TABLE user_startup_access (
    user_id    NUMBER NOT NULL,
    startup_id NUMBER NOT NULL,
    CONSTRAINT pk_user_startup_access PRIMARY KEY (user_id, startup_id),
    CONSTRAINT fk_usa_user FOREIGN KEY (user_id) REFERENCES users (user_id) ON DELETE CASCADE,
    CONSTRAINT fk_usa_startup FOREIGN KEY (startup_id) REFERENCES startups (startup_id) ON DELETE CASCADE
);

-- 4. Accounts (Categories)
CREATE TABLE accounts (
    account_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    startup_id NUMBER NOT NULL,
    name       VARCHAR2(100) NOT NULL,
    acct_type  VARCHAR2(10) NOT NULL CONSTRAINT chk_acct_type CHECK (acct_type IN ('INCOME', 'EXPENSE')),
    CONSTRAINT fk_accounts_startup FOREIGN KEY (startup_id) REFERENCES startups (startup_id) ON DELETE CASCADE,
    CONSTRAINT uq_accounts_startup_name UNIQUE (startup_id, name)
);

-- 5. Transactions
CREATE TABLE transactions (
    txn_id         NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    startup_id     NUMBER NOT NULL,
    account_id     NUMBER NOT NULL,
    txn_date       DATE NOT NULL,
    description    VARCHAR2(255) NOT NULL,
    txn_type       VARCHAR2(10) NOT NULL CONSTRAINT chk_txn_type CHECK (txn_type IN ('INCOME', 'EXPENSE')),
    amount         NUMBER(15, 2) NOT NULL CONSTRAINT chk_txn_amount CHECK (amount > 0),
    payment_status VARCHAR2(10) DEFAULT 'PAID' NOT NULL CONSTRAINT chk_txn_status CHECK (payment_status IN ('PAID', 'PENDING')),
    created_by     VARCHAR2(50) DEFAULT 'SYSTEM' NOT NULL,
    created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT fk_txn_startup FOREIGN KEY (startup_id) REFERENCES startups (startup_id) ON DELETE CASCADE,
    CONSTRAINT fk_txn_account FOREIGN KEY (account_id) REFERENCES accounts (account_id) ON DELETE CASCADE
);

-- Required Indexes
CREATE INDEX idx_txn_startup_date ON transactions(startup_id, txn_date);
CREATE INDEX idx_txn_upper_desc ON transactions(UPPER(description));

-- 6. Audit Log
CREATE TABLE audit_log (
    audit_id   NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    startup_id NUMBER,
    table_name VARCHAR2(50) NOT NULL,
    record_id  NUMBER NOT NULL,
    action     VARCHAR2(10) NOT NULL,
    old_value  VARCHAR2(4000),
    new_value  VARCHAR2(4000),
    changed_by VARCHAR2(50),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

PROMPT ============================================================================
PROMPT Creating row-level audit trigger on transactions...
PROMPT ============================================================================

CREATE OR REPLACE TRIGGER trg_transactions_audit
AFTER INSERT OR UPDATE OR DELETE ON transactions
FOR EACH ROW
DECLARE
    v_action     VARCHAR2(10);
    v_user       VARCHAR2(50);
    v_old        VARCHAR2(4000);
    v_new        VARCHAR2(4000);
    v_startup_id NUMBER;
    v_record_id  NUMBER;
BEGIN
    -- Pull logged-in username set by Flask via connection.clientinfo
    v_user := NVL(SYS_CONTEXT('USERENV', 'CLIENT_INFO'), 'SYSTEM');

    IF INSERTING THEN
        v_action     := 'INSERT';
        v_record_id  := :NEW.txn_id;
        v_startup_id := :NEW.startup_id;
        v_old        := NULL;
        v_new        := '{"txn_id":' || :NEW.txn_id ||
                        ',"startup_id":' || :NEW.startup_id ||
                        ',"account_id":' || :NEW.account_id ||
                        ',"txn_date":"' || TO_CHAR(:NEW.txn_date, 'YYYY-MM-DD') || '"' ||
                        ',"description":"' || REPLACE(REPLACE(:NEW.description, '\', '\\'), '"', '\"') || '"' ||
                        ',"txn_type":"' || :NEW.txn_type || '"' ||
                        ',"amount":' || :NEW.amount ||
                        ',"payment_status":"' || :NEW.payment_status || '"}';
    ELSIF UPDATING THEN
        v_action     := 'UPDATE';
        v_record_id  := :NEW.txn_id;
        v_startup_id := :NEW.startup_id;
        v_old        := '{"txn_id":' || :OLD.txn_id ||
                        ',"startup_id":' || :OLD.startup_id ||
                        ',"account_id":' || :OLD.account_id ||
                        ',"txn_date":"' || TO_CHAR(:OLD.txn_date, 'YYYY-MM-DD') || '"' ||
                        ',"description":"' || REPLACE(REPLACE(:OLD.description, '\', '\\'), '"', '\"') || '"' ||
                        ',"txn_type":"' || :OLD.txn_type || '"' ||
                        ',"amount":' || :OLD.amount ||
                        ',"payment_status":"' || :OLD.payment_status || '"}';
        v_new        := '{"txn_id":' || :NEW.txn_id ||
                        ',"startup_id":' || :NEW.startup_id ||
                        ',"account_id":' || :NEW.account_id ||
                        ',"txn_date":"' || TO_CHAR(:NEW.txn_date, 'YYYY-MM-DD') || '"' ||
                        ',"description":"' || REPLACE(REPLACE(:NEW.description, '\', '\\'), '"', '\"') || '"' ||
                        ',"txn_type":"' || :NEW.txn_type || '"' ||
                        ',"amount":' || :NEW.amount ||
                        ',"payment_status":"' || :NEW.payment_status || '"}';
    ELSIF DELETING THEN
        v_action     := 'DELETE';
        v_record_id  := :OLD.txn_id;
        v_startup_id := :OLD.startup_id;
        v_old        := '{"txn_id":' || :OLD.txn_id ||
                        ',"startup_id":' || :OLD.startup_id ||
                        ',"account_id":' || :OLD.account_id ||
                        ',"txn_date":"' || TO_CHAR(:OLD.txn_date, 'YYYY-MM-DD') || '"' ||
                        ',"description":"' || REPLACE(REPLACE(:OLD.description, '\', '\\'), '"', '\"') || '"' ||
                        ',"txn_type":"' || :OLD.txn_type || '"' ||
                        ',"amount":' || :OLD.amount ||
                        ',"payment_status":"' || :OLD.payment_status || '"}';
        v_new        := NULL;
    END IF;

    INSERT INTO audit_log (
        startup_id,
        table_name,
        record_id,
        action,
        old_value,
        new_value,
        changed_by,
        changed_at
    ) VALUES (
        v_startup_id,
        'TRANSACTIONS',
        v_record_id,
        v_action,
        v_old,
        v_new,
        v_user,
        SYSTIMESTAMP
    );
END;
/

PROMPT ============================================================================
PROMPT Listing tables in schema:
PROMPT ============================================================================

SELECT table_name FROM user_tables ORDER BY table_name;
