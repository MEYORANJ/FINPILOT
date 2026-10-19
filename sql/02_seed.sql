-- ============================================================================
-- FinPilot Seed Data Script
-- File: sql/02_seed.sql
-- Description: Seeds initial startups, accounts, and realistic 6-month transactions
-- ============================================================================

SET FEEDBACK ON;
SET SERVEROUTPUT ON;
SET LINESIZE 120;
SET PAGESIZE 50;
SET DEFINE OFF;

PROMPT ============================================================================
PROMPT Disabling audit trigger during seeding...
PROMPT ============================================================================

ALTER TRIGGER trg_transactions_audit DISABLE;

PROMPT ============================================================================
PROMPT Seeding Startups...
PROMPT ============================================================================

INSERT INTO startups (name, industry, opening_cash)
VALUES ('Nimbus Labs', 'SaaS', 1500000.00);

INSERT INTO startups (name, industry, opening_cash)
VALUES ('GreenCart', 'E-commerce', 800000.00);

PROMPT ============================================================================
PROMPT Seeding Accounts (12 categories per startup: 4 Income, 8 Expense)...
PROMPT ============================================================================

-- Nimbus Labs Accounts
INSERT INTO accounts (startup_id, name, acct_type)
VALUES ((SELECT startup_id FROM startups WHERE name = 'Nimbus Labs'), 'Enterprise Subscriptions', 'INCOME');
INSERT INTO accounts (startup_id, name, acct_type)
VALUES ((SELECT startup_id FROM startups WHERE name = 'Nimbus Labs'), 'SaaS Pro Tier', 'INCOME');
INSERT INTO accounts (startup_id, name, acct_type)
VALUES ((SELECT startup_id FROM startups WHERE name = 'Nimbus Labs'), 'API Usage Overage', 'INCOME');
INSERT INTO accounts (startup_id, name, acct_type)
VALUES ((SELECT startup_id FROM startups WHERE name = 'Nimbus Labs'), 'Implementation & Consulting', 'INCOME');

INSERT INTO accounts (startup_id, name, acct_type)
VALUES ((SELECT startup_id FROM startups WHERE name = 'Nimbus Labs'), 'Cloud Infrastructure', 'EXPENSE');
INSERT INTO accounts (startup_id, name, acct_type)
VALUES ((SELECT startup_id FROM startups WHERE name = 'Nimbus Labs'), 'Engineering Salaries', 'EXPENSE');
INSERT INTO accounts (startup_id, name, acct_type)
VALUES ((SELECT startup_id FROM startups WHERE name = 'Nimbus Labs'), 'Office Rent & Utilities', 'EXPENSE');
INSERT INTO accounts (startup_id, name, acct_type)
VALUES ((SELECT startup_id FROM startups WHERE name = 'Nimbus Labs'), 'Software Licenses & Tools', 'EXPENSE');
INSERT INTO accounts (startup_id, name, acct_type)
VALUES ((SELECT startup_id FROM startups WHERE name = 'Nimbus Labs'), 'Marketing & Lead Gen', 'EXPENSE');
INSERT INTO accounts (startup_id, name, acct_type)
VALUES ((SELECT startup_id FROM startups WHERE name = 'Nimbus Labs'), 'Legal & Professional', 'EXPENSE');
INSERT INTO accounts (startup_id, name, acct_type)
VALUES ((SELECT startup_id FROM startups WHERE name = 'Nimbus Labs'), 'Customer Support Ops', 'EXPENSE');
INSERT INTO accounts (startup_id, name, acct_type)
VALUES ((SELECT startup_id FROM startups WHERE name = 'Nimbus Labs'), 'Analytics & Data Platform', 'EXPENSE');

-- GreenCart Accounts
INSERT INTO accounts (startup_id, name, acct_type)
VALUES ((SELECT startup_id FROM startups WHERE name = 'GreenCart'), 'Direct Marketplace Sales', 'INCOME');
INSERT INTO accounts (startup_id, name, acct_type)
VALUES ((SELECT startup_id FROM startups WHERE name = 'GreenCart'), 'Seller Commission Fees', 'INCOME');
INSERT INTO accounts (startup_id, name, acct_type)
VALUES ((SELECT startup_id FROM startups WHERE name = 'GreenCart'), 'Premium Delivery Subscriptions', 'INCOME');
INSERT INTO accounts (startup_id, name, acct_type)
VALUES ((SELECT startup_id FROM startups WHERE name = 'GreenCart'), 'Featured Brand Promotions', 'INCOME');

INSERT INTO accounts (startup_id, name, acct_type)
VALUES ((SELECT startup_id FROM startups WHERE name = 'GreenCart'), 'Warehousing & Fulfillment', 'EXPENSE');
INSERT INTO accounts (startup_id, name, acct_type)
VALUES ((SELECT startup_id FROM startups WHERE name = 'GreenCart'), 'Delivery & Logistics', 'EXPENSE');
INSERT INTO accounts (startup_id, name, acct_type)
VALUES ((SELECT startup_id FROM startups WHERE name = 'GreenCart'), 'Supplier Inventory Purchase', 'EXPENSE');
INSERT INTO accounts (startup_id, name, acct_type)
VALUES ((SELECT startup_id FROM startups WHERE name = 'GreenCart'), 'Staff & Operations Salaries', 'EXPENSE');
INSERT INTO accounts (startup_id, name, acct_type)
VALUES ((SELECT startup_id FROM startups WHERE name = 'GreenCart'), 'Payment Gateway Fees', 'EXPENSE');
INSERT INTO accounts (startup_id, name, acct_type)
VALUES ((SELECT startup_id FROM startups WHERE name = 'GreenCart'), 'Digital Ad Campaigns', 'EXPENSE');
INSERT INTO accounts (startup_id, name, acct_type)
VALUES ((SELECT startup_id FROM startups WHERE name = 'GreenCart'), 'Tech Infrastructure & CDN', 'EXPENSE');
INSERT INTO accounts (startup_id, name, acct_type)
VALUES ((SELECT startup_id FROM startups WHERE name = 'GreenCart'), 'Regulatory & Legal Advisory', 'EXPENSE');

PROMPT ============================================================================
PROMPT Seeding Transactions for Nimbus Labs (45 transactions)...
PROMPT ============================================================================

-- Month -5 (~150-170 days ago)
INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'Nimbus Labs'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'Nimbus Labs') AND name = 'Enterprise Subscriptions'), TRUNC(SYSDATE) - 168, 'Acme Corp Q1 Enterprise Cloud Plan', 'INCOME', 185000.00, 'PAID', 'SYSTEM');

INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'Nimbus Labs'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'Nimbus Labs') AND name = 'SaaS Pro Tier'), TRUNC(SYSDATE) - 165, 'Stripe Billing - Recurring Pro Subscriptions', 'INCOME', 92000.00, 'PAID', 'SYSTEM');

INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'Nimbus Labs'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'Nimbus Labs') AND name = 'Cloud Infrastructure'), TRUNC(SYSDATE) - 162, 'AWS Production Cluster & S3 Storage', 'EXPENSE', 38000.00, 'PAID', 'SYSTEM');

INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'Nimbus Labs'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'Nimbus Labs') AND name = 'Engineering Salaries'), TRUNC(SYSDATE) - 158, 'Core Tech Engineering Payroll - Month 1', 'EXPENSE', 145000.00, 'PAID', 'SYSTEM');

INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'Nimbus Labs'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'Nimbus Labs') AND name = 'Office Rent & Utilities'), TRUNC(SYSDATE) - 155, 'TechPark Innovation Hub - Monthly Office Rent', 'EXPENSE', 42000.00, 'PAID', 'SYSTEM');

INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'Nimbus Labs'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'Nimbus Labs') AND name = 'Software Licenses & Tools'), TRUNC(SYSDATE) - 153, 'GitHub Enterprise & Slack Workspace', 'EXPENSE', 15000.00, 'PAID', 'SYSTEM');

INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'Nimbus Labs'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'Nimbus Labs') AND name = 'Marketing & Lead Gen'), TRUNC(SYSDATE) - 150, 'Google Search Ads & LinkedIn Sponsor', 'EXPENSE', 28000.00, 'PAID', 'SYSTEM');

-- Month -4 (~120-145 days ago)
INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'Nimbus Labs'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'Nimbus Labs') AND name = 'Enterprise Subscriptions'), TRUNC(SYSDATE) - 138, 'Global Logistics Enterprise License', 'INCOME', 195000.00, 'PAID', 'SYSTEM');

INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'Nimbus Labs'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'Nimbus Labs') AND name = 'SaaS Pro Tier'), TRUNC(SYSDATE) - 135, 'Stripe Billing - Pro Recurring Accounts', 'INCOME', 98000.00, 'PAID', 'SYSTEM');

INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'Nimbus Labs'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'Nimbus Labs') AND name = 'API Usage Overage'), TRUNC(SYSDATE) - 132, 'Developer Portal API Metered Invoices', 'INCOME', 14000.00, 'PAID', 'SYSTEM');

INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'Nimbus Labs'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'Nimbus Labs') AND name = 'Cloud Infrastructure'), TRUNC(SYSDATE) - 130, 'AWS Production RDS & Elastic Kubernetes', 'EXPENSE', 41000.00, 'PAID', 'SYSTEM');

INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'Nimbus Labs'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'Nimbus Labs') AND name = 'Engineering Salaries'), TRUNC(SYSDATE) - 128, 'Core Tech Engineering Payroll - Month 2', 'EXPENSE', 145000.00, 'PAID', 'SYSTEM');

INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'Nimbus Labs'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'Nimbus Labs') AND name = 'Office Rent & Utilities'), TRUNC(SYSDATE) - 125, 'TechPark Innovation Hub - Monthly Office Rent', 'EXPENSE', 42000.00, 'PAID', 'SYSTEM');

INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'Nimbus Labs'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'Nimbus Labs') AND name = 'Software Licenses & Tools'), TRUNC(SYSDATE) - 123, 'Figma & Atlassian Jira Suite', 'EXPENSE', 16500.00, 'PAID', 'SYSTEM');

INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'Nimbus Labs'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'Nimbus Labs') AND name = 'Customer Support Ops'), TRUNC(SYSDATE) - 120, 'Zendesk Suite & Intercom Live Chat', 'EXPENSE', 18000.00, 'PAID', 'SYSTEM');

-- Month -3 (~90-115 days ago)
INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'Nimbus Labs'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'Nimbus Labs') AND name = 'Enterprise Subscriptions'), TRUNC(SYSDATE) - 108, 'FinCore Banking Suite Enterprise Contract', 'INCOME', 210000.00, 'PAID', 'SYSTEM');

INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'Nimbus Labs'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'Nimbus Labs') AND name = 'SaaS Pro Tier'), TRUNC(SYSDATE) - 105, 'Stripe Billing - Pro Recurring Accounts', 'INCOME', 105000.00, 'PAID', 'SYSTEM');

INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'Nimbus Labs'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'Nimbus Labs') AND name = 'Implementation & Consulting'), TRUNC(SYSDATE) - 102, 'Onboarding & Migration Services for FinCore', 'INCOME', 55000.00, 'PAID', 'SYSTEM');

INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'Nimbus Labs'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'Nimbus Labs') AND name = 'Cloud Infrastructure'), TRUNC(SYSDATE) - 98, 'AWS Multi-region Cloud Deployments', 'EXPENSE', 44000.00, 'PAID', 'SYSTEM');

INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'Nimbus Labs'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'Nimbus Labs') AND name = 'Engineering Salaries'), TRUNC(SYSDATE) - 95, 'Core Tech Engineering Payroll - Month 3', 'EXPENSE', 150000.00, 'PAID', 'SYSTEM');

INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'Nimbus Labs'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'Nimbus Labs') AND name = 'Office Rent & Utilities'), TRUNC(SYSDATE) - 92, 'TechPark Innovation Hub - Monthly Office Rent', 'EXPENSE', 42000.00, 'PAID', 'SYSTEM');

INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'Nimbus Labs'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'Nimbus Labs') AND name = 'Marketing & Lead Gen'), TRUNC(SYSDATE) - 90, 'TechCrunch Feature & Developer Outreach', 'EXPENSE', 32000.00, 'PAID', 'SYSTEM');

-- Month -2 (~60-85 days ago)
INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'Nimbus Labs'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'Nimbus Labs') AND name = 'Enterprise Subscriptions'), TRUNC(SYSDATE) - 78, 'HyperScale Retail Enterprise Platform', 'INCOME', 225000.00, 'PAID', 'SYSTEM');

INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'Nimbus Labs'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'Nimbus Labs') AND name = 'SaaS Pro Tier'), TRUNC(SYSDATE) - 75, 'Stripe Billing - Pro Recurring Accounts', 'INCOME', 112000.00, 'PAID', 'SYSTEM');

INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'Nimbus Labs'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'Nimbus Labs') AND name = 'API Usage Overage'), TRUNC(SYSDATE) - 72, 'Metered API Consumption Billing', 'INCOME', 19000.00, 'PAID', 'SYSTEM');

INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'Nimbus Labs'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'Nimbus Labs') AND name = 'Cloud Infrastructure'), TRUNC(SYSDATE) - 68, 'AWS EKS & CloudFront CDN Infrastructure', 'EXPENSE', 47000.00, 'PAID', 'SYSTEM');

INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'Nimbus Labs'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'Nimbus Labs') AND name = 'Engineering Salaries'), TRUNC(SYSDATE) - 65, 'Core Tech Engineering Payroll - Month 4', 'EXPENSE', 150000.00, 'PAID', 'SYSTEM');

INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'Nimbus Labs'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'Nimbus Labs') AND name = 'Office Rent & Utilities'), TRUNC(SYSDATE) - 63, 'TechPark Innovation Hub Coworking Lease', 'EXPENSE', 42000.00, 'PAID', 'SYSTEM');

INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'Nimbus Labs'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'Nimbus Labs') AND name = 'Software Licenses & Tools'), TRUNC(SYSDATE) - 61, 'Postman & Sentry Error Monitoring', 'EXPENSE', 18000.00, 'PAID', 'SYSTEM');

INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'Nimbus Labs'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'Nimbus Labs') AND name = 'Customer Support Ops'), TRUNC(SYSDATE) - 60, 'Support Engineers Contractors - Tier 1', 'EXPENSE', 20000.00, 'PAID', 'SYSTEM');

INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'Nimbus Labs'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'Nimbus Labs') AND name = 'Marketing & Lead Gen'), TRUNC(SYSDATE) - 58, 'Growth Marketing Campaign & Webinars', 'EXPENSE', 35000.00, 'PAID', 'SYSTEM');

-- Month -1 (~30-55 days ago)
INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'Nimbus Labs'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'Nimbus Labs') AND name = 'Enterprise Subscriptions'), TRUNC(SYSDATE) - 48, 'Matrix Health SaaS Enterprise Renewal', 'INCOME', 240000.00, 'PAID', 'SYSTEM');

INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'Nimbus Labs'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'Nimbus Labs') AND name = 'SaaS Pro Tier'), TRUNC(SYSDATE) - 45, 'Stripe Billing - Pro Recurring Accounts', 'INCOME', 118000.00, 'PAID', 'SYSTEM');

INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'Nimbus Labs'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'Nimbus Labs') AND name = 'Implementation & Consulting'), TRUNC(SYSDATE) - 42, 'Matrix Health Custom API Integration', 'INCOME', 60000.00, 'PAID', 'SYSTEM');

INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'Nimbus Labs'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'Nimbus Labs') AND name = 'Cloud Infrastructure'), TRUNC(SYSDATE) - 40, 'AWS Enterprise Hosting & Direct Connect', 'EXPENSE', 49000.00, 'PAID', 'SYSTEM');

INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'Nimbus Labs'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'Nimbus Labs') AND name = 'Engineering Salaries'), TRUNC(SYSDATE) - 38, 'Core Tech Engineering Payroll - Month 5', 'EXPENSE', 155000.00, 'PAID', 'SYSTEM');

INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'Nimbus Labs'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'Nimbus Labs') AND name = 'Office Rent & Utilities'), TRUNC(SYSDATE) - 35, 'TechPark Innovation Hub Coworking Lease', 'EXPENSE', 42000.00, 'PAID', 'SYSTEM');

INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'Nimbus Labs'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'Nimbus Labs') AND name = 'Software Licenses & Tools'), TRUNC(SYSDATE) - 33, 'Notion Team & JetBrains Licenses', 'EXPENSE', 19000.00, 'PAID', 'SYSTEM');

INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'Nimbus Labs'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'Nimbus Labs') AND name = 'Marketing & Lead Gen'), TRUNC(SYSDATE) - 30, 'Outbound SDR Tooling & Paid Inbound', 'EXPENSE', 38000.00, 'PAID', 'SYSTEM');

-- Planted Demo Case: Anomalously large expense (95,000 annual analytics licence)
INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'Nimbus Labs'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'Nimbus Labs') AND name = 'Analytics & Data Platform'), TRUNC(SYSDATE) - 45, 'Mixpanel & Datadog Enterprise Annual Analytics Licence', 'EXPENSE', 95000.00, 'PAID', 'SYSTEM');

-- Current Month (~0-25 days ago)
INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'Nimbus Labs'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'Nimbus Labs') AND name = 'Enterprise Subscriptions'), TRUNC(SYSDATE) - 15, 'Quantum Leap Tech Q2 SaaS Plan', 'INCOME', 260000.00, 'PAID', 'SYSTEM');

INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'Nimbus Labs'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'Nimbus Labs') AND name = 'SaaS Pro Tier'), TRUNC(SYSDATE) - 12, 'Stripe Billing - Pro Recurring Accounts', 'INCOME', 125000.00, 'PAID', 'SYSTEM');

INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'Nimbus Labs'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'Nimbus Labs') AND name = 'Cloud Infrastructure'), TRUNC(SYSDATE) - 8, 'AWS Cloud Services & CDN Infrastructure', 'EXPENSE', 52000.00, 'PAID', 'SYSTEM');

-- Planted Demo Case: Unpaid customer invoice (PENDING income)
INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'Nimbus Labs'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'Nimbus Labs') AND name = 'Enterprise Subscriptions'), TRUNC(SYSDATE) - 10, 'Acme Corp Enterprise SaaS Annual - Invoice #INV-2026-088', 'INCOME', 120000.00, 'PENDING', 'SYSTEM');

-- Planted Demo Case: Unpaid legal retainer (PENDING expense)
INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'Nimbus Labs'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'Nimbus Labs') AND name = 'Legal & Professional'), TRUNC(SYSDATE) - 5, 'Apex Legal Partners - Q4 Corporate Retainer', 'EXPENSE', 35000.00, 'PENDING', 'SYSTEM');

PROMPT ============================================================================
PROMPT Seeding Transactions for GreenCart (33 transactions)...
PROMPT ============================================================================

-- Month -5 (~150-165 days ago)
INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'GreenCart'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'GreenCart') AND name = 'Direct Marketplace Sales'), TRUNC(SYSDATE) - 165, 'Consumer Direct Orders Settlement Batch #1', 'INCOME', 140000.00, 'PAID', 'SYSTEM');

INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'GreenCart'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'GreenCart') AND name = 'Seller Commission Fees'), TRUNC(SYSDATE) - 160, 'Vendor Platform 10% Take-rate Commissions', 'INCOME', 42000.00, 'PAID', 'SYSTEM');

INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'GreenCart'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'GreenCart') AND name = 'Warehousing & Fulfillment'), TRUNC(SYSDATE) - 158, 'Central Cold Storage & Warehouse Rent', 'EXPENSE', 38000.00, 'PAID', 'SYSTEM');

INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'GreenCart'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'GreenCart') AND name = 'Delivery & Logistics'), TRUNC(SYSDATE) - 155, 'Last-mile Fleet Electric Delivery Run', 'EXPENSE', 45000.00, 'PAID', 'SYSTEM');

INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'GreenCart'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'GreenCart') AND name = 'Staff & Operations Salaries'), TRUNC(SYSDATE) - 150, 'Warehouse Ops & Courier Team Salaries', 'EXPENSE', 85000.00, 'PAID', 'SYSTEM');

-- Month -4 (~120-135 days ago)
INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'GreenCart'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'GreenCart') AND name = 'Direct Marketplace Sales'), TRUNC(SYSDATE) - 135, 'Consumer Direct Orders Settlement Batch #2', 'INCOME', 155000.00, 'PAID', 'SYSTEM');

INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'GreenCart'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'GreenCart') AND name = 'Seller Commission Fees'), TRUNC(SYSDATE) - 130, 'Merchant Commission Remittances', 'INCOME', 48000.00, 'PAID', 'SYSTEM');

INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'GreenCart'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'GreenCart') AND name = 'Premium Delivery Subscriptions'), TRUNC(SYSDATE) - 128, 'GreenCart Prime Monthly Member Subscriptions', 'INCOME', 16000.00, 'PAID', 'SYSTEM');

INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'GreenCart'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'GreenCart') AND name = 'Warehousing & Fulfillment'), TRUNC(SYSDATE) - 125, 'Sorting Hub Lease & Packaging Materials', 'EXPENSE', 40000.00, 'PAID', 'SYSTEM');

INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'GreenCart'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'GreenCart') AND name = 'Delivery & Logistics'), TRUNC(SYSDATE) - 122, 'City-wide Delivery Fleet Dispatch Fuel & EV Rent', 'EXPENSE', 49000.00, 'PAID', 'SYSTEM');

INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'GreenCart'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'GreenCart') AND name = 'Staff & Operations Salaries'), TRUNC(SYSDATE) - 120, 'Warehouse Ops & Fulfillment Payroll', 'EXPENSE', 85000.00, 'PAID', 'SYSTEM');

-- Month -3 (~90-105 days ago)
INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'GreenCart'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'GreenCart') AND name = 'Direct Marketplace Sales'), TRUNC(SYSDATE) - 105, 'Consumer Direct Orders Settlement Batch #3', 'INCOME', 168000.00, 'PAID', 'SYSTEM');

INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'GreenCart'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'GreenCart') AND name = 'Seller Commission Fees'), TRUNC(SYSDATE) - 100, 'Merchant Commission Payout Remittances', 'INCOME', 52000.00, 'PAID', 'SYSTEM');

INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'GreenCart'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'GreenCart') AND name = 'Supplier Inventory Purchase'), TRUNC(SYSDATE) - 98, 'Organic Produce Bulk Farm Purchase', 'EXPENSE', 72000.00, 'PAID', 'SYSTEM');

INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'GreenCart'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'GreenCart') AND name = 'Delivery & Logistics'), TRUNC(SYSDATE) - 95, 'Third-party Logistics Surge Van Fleet', 'EXPENSE', 53000.00, 'PAID', 'SYSTEM');

INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'GreenCart'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'GreenCart') AND name = 'Staff & Operations Salaries'), TRUNC(SYSDATE) - 92, 'Warehouse Ops & Team Payroll', 'EXPENSE', 90000.00, 'PAID', 'SYSTEM');

INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'GreenCart'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'GreenCart') AND name = 'Payment Gateway Fees'), TRUNC(SYSDATE) - 90, 'Razorpay & UPI Transaction Processing Charges', 'EXPENSE', 8500.00, 'PAID', 'SYSTEM');

-- Month -2 (~60-75 days ago)
INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'GreenCart'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'GreenCart') AND name = 'Direct Marketplace Sales'), TRUNC(SYSDATE) - 75, 'Consumer Direct Orders Settlement Batch #4', 'INCOME', 180000.00, 'PAID', 'SYSTEM');

INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'GreenCart'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'GreenCart') AND name = 'Seller Commission Fees'), TRUNC(SYSDATE) - 72, 'Merchant Platform Commission Payouts', 'INCOME', 56000.00, 'PAID', 'SYSTEM');

INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'GreenCart'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'GreenCart') AND name = 'Featured Brand Promotions'), TRUNC(SYSDATE) - 70, 'Featured Brand Home Screen Placement Sponsorship', 'INCOME', 22000.00, 'PAID', 'SYSTEM');

INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'GreenCart'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'GreenCart') AND name = 'Warehousing & Fulfillment'), TRUNC(SYSDATE) - 67, 'Automated Sorting & Sustainable Packaging', 'EXPENSE', 44000.00, 'PAID', 'SYSTEM');

INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'GreenCart'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'GreenCart') AND name = 'Delivery & Logistics'), TRUNC(SYSDATE) - 64, 'Urban Express Logistics Deliveries', 'EXPENSE', 58000.00, 'PAID', 'SYSTEM');

INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'GreenCart'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'GreenCart') AND name = 'Staff & Operations Salaries'), TRUNC(SYSDATE) - 60, 'Fulfillment Staff & QA Salaries', 'EXPENSE', 90000.00, 'PAID', 'SYSTEM');

-- Month -1 (~30-45 days ago)
INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'GreenCart'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'GreenCart') AND name = 'Direct Marketplace Sales'), TRUNC(SYSDATE) - 45, 'Consumer Direct Orders Settlement Batch #5', 'INCOME', 195000.00, 'PAID', 'SYSTEM');

INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'GreenCart'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'GreenCart') AND name = 'Seller Commission Fees'), TRUNC(SYSDATE) - 40, 'Merchant Platform Commission Payouts', 'INCOME', 61000.00, 'PAID', 'SYSTEM');

INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'GreenCart'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'GreenCart') AND name = 'Premium Delivery Subscriptions'), TRUNC(SYSDATE) - 38, 'GreenCart Prime Monthly Member Subscriptions', 'INCOME', 19000.00, 'PAID', 'SYSTEM');

INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'GreenCart'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'GreenCart') AND name = 'Digital Ad Campaigns'), TRUNC(SYSDATE) - 35, 'Meta & Instagram Ads App Install Campaign', 'EXPENSE', 34000.00, 'PAID', 'SYSTEM');

INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'GreenCart'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'GreenCart') AND name = 'Tech Infrastructure & CDN'), TRUNC(SYSDATE) - 32, 'Cloud Hosting, Redis & Fastly CDN', 'EXPENSE', 16000.00, 'PAID', 'SYSTEM');

INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'GreenCart'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'GreenCart') AND name = 'Staff & Operations Salaries'), TRUNC(SYSDATE) - 30, 'Operations & Tech Support Salaries', 'EXPENSE', 95000.00, 'PAID', 'SYSTEM');

-- Current Month (~0-20 days ago)
INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'GreenCart'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'GreenCart') AND name = 'Direct Marketplace Sales'), TRUNC(SYSDATE) - 15, 'Consumer Direct Orders Settlement Batch #6', 'INCOME', 210000.00, 'PAID', 'SYSTEM');

INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'GreenCart'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'GreenCart') AND name = 'Delivery & Logistics'), TRUNC(SYSDATE) - 10, 'Last-mile Fleet Electric Vehicle Deliveries', 'EXPENSE', 62000.00, 'PAID', 'SYSTEM');

-- Planted Demo Case: Unpaid customer invoice (PENDING income)
INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'GreenCart'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'GreenCart') AND name = 'Direct Marketplace Sales'), TRUNC(SYSDATE) - 12, 'Wholesale Merchant B2B Settlement - Order #GC-9821', 'INCOME', 65000.00, 'PENDING', 'SYSTEM');

-- Planted Demo Case: Unpaid legal retainer (PENDING expense)
INSERT INTO transactions (startup_id, account_id, txn_date, description, txn_type, amount, payment_status, created_by)
VALUES ((SELECT startup_id FROM startups WHERE name = 'GreenCart'), (SELECT account_id FROM accounts WHERE startup_id = (SELECT startup_id FROM startups WHERE name = 'GreenCart') AND name = 'Regulatory & Legal Advisory'), TRUNC(SYSDATE) - 7, 'LexJuris Consulting - Regulatory Compliance Retainer', 'EXPENSE', 18000.00, 'PENDING', 'SYSTEM');

PROMPT ============================================================================
PROMPT Re-enabling audit trigger...
PROMPT ============================================================================

ALTER TRIGGER trg_transactions_audit ENABLE;

COMMIT;

PROMPT ============================================================================
PROMPT Seeding complete. Summary of transactions per startup:
PROMPT ============================================================================

SELECT s.name AS startup_name, COUNT(t.txn_id) AS transaction_count
FROM startups s
LEFT JOIN transactions t ON s.startup_id = t.startup_id
GROUP BY s.name
ORDER BY s.name;
