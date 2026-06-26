create table if not exists app_users (
  id text primary key,
  full_name text not null,
  email text not null unique,
  dni text not null unique,
  password_hash text not null,
  role text not null check (role in ('customer', 'salesOfficer'))
);

create table if not exists savings_accounts (
  id text primary key,
  customer_id text not null references app_users(id),
  name text not null,
  currency text not null default 'S/',
  balance numeric(12, 2) not null default 0,
  account_number text not null unique,
  last_statement_period text not null
);

create table if not exists bank_movements (
  id text primary key,
  customer_id text not null references app_users(id),
  description text not null,
  movement_date date not null,
  amount numeric(12, 2) not null,
  movement_type text not null check (
    movement_type in ('deposit', 'withdrawal', 'payment', 'transfer')
  )
);

create table if not exists credit_loans (
  id text primary key,
  customer_id text not null references app_users(id),
  product_name text not null,
  principal numeric(12, 2) not null,
  outstanding_balance numeric(12, 2) not null,
  next_payment_date date not null
);

create table if not exists payment_schedule_items (
  id text primary key,
  loan_id text not null references credit_loans(id),
  installment integer not null,
  due_date date not null,
  amount numeric(12, 2) not null,
  paid boolean not null default false
);

create table if not exists payment_services (
  id text primary key,
  name text not null,
  category text not null,
  amount numeric(12, 2) not null
);

create table if not exists customer_visits (
  id text primary key,
  officer_id text not null references app_users(id),
  customer_name text not null,
  address text not null,
  visit_time text not null,
  reason text not null,
  score integer not null,
  risk_level text not null,
  active_products text[] not null default '{}',
  payment_behavior text not null
);

create table if not exists credit_applications (
  id text primary key,
  customer_name text not null,
  dni text not null,
  phone text not null,
  amount numeric(12, 2) not null,
  business_activity text not null,
  status text not null check (
    status in ('sent', 'underReview', 'approved', 'disbursed')
  ),
  bureau_provider text not null,
  bureau_result text not null,
  bureau_checked_at timestamp not null,
  transmitted boolean not null default false,
  offline_captured boolean not null default true,
  created_at timestamp not null default now()
);

create table if not exists document_captures (
  id text primary key,
  application_id text not null references credit_applications(id),
  document_type text not null,
  file_name text not null,
  captured boolean not null default false
);

insert into app_users (id, full_name, email, dni, password_hash, role)
values
  ('customer-001', 'Valeria Torres', 'demo@interbank.pe', '74859612', 'demo-dev-only', 'customer'),
  ('officer-001', 'Diego Salazar', 'oficial@interbank.pe', '70112233', 'demo-dev-only', 'salesOfficer')
on conflict (id) do nothing;
