sql-data-warehouse-project

Light Speed is a PostgreSQL-based analytics engineering project built on top of an Odoo operational database.

The goal of the project is to transform raw Odoo tables into clean, reliable, analytics-ready datasets that can be used by BI tools and dashboards.

## Project Objective

The source database contains a large number of operational Odoo tables inside the `public` schema.

Instead of connecting dashboards directly to raw Odoo tables, this project introduces a structured analytics layer:

```text
Odoo / public
      ↓
analytics_staging
      ↓
analytics_intermediate
      ↓
analytics_marts
      ↓
BI / Dashboards
```

The project is developed domain by domain so that each business area can be understood, modeled, validated, and completed before moving to the next one.

## Database

Database name:

```text
light_speed
```

Main schemas:

```text
public
analytics_staging
analytics_intermediate
analytics_marts
```

### `public`

Contains the original Odoo source tables.

Examples:

```text
sale_order
sale_order_line
res_partner
product_product
product_template
purchase_order
account_move
crm_lead
```

The `public` schema is treated as the source layer and should not be modified for analytics purposes.

## Analytics Architecture

### 1. Staging Layer

Schema:

```text
analytics_staging
```

Purpose:

The staging layer provides a cleaned and standardized representation of source tables.

Typical transformations include:

- Renaming columns to clear business-friendly names
- Selecting only relevant columns
- Standardizing data types
- Cleaning text values where necessary
- Handling null values when a defined business rule exists
- Removing technical duplicates only when they are confirmed to be invalid
- Preserving valid business duplicates
- Keeping the original business meaning of the source data

Example:

```text
public.sale_order
        ↓
analytics_staging.stg_sale_orders
```

Example transformation:

```sql
SELECT
    id             AS order_id,
    partner_id     AS customer_id,
    user_id        AS salesperson_id,
    warehouse_id,
    date_order     AS order_datetime,
    state          AS order_status,
    amount_untaxed AS subtotal_amount,
    amount_tax     AS tax_amount,
    amount_total   AS total_amount
FROM public.sale_order;
```

The staging layer should remain close to the source and should not contain complex business aggregations.

### 2. Intermediate Layer

Schema:

```text
analytics_intermediate
```

Purpose:

The intermediate layer combines staged datasets and applies reusable business logic.

Typical transformations include:

- Joins between staged tables
- Business-rule calculations
- Derived columns
- Status mappings
- Window functions
- Deduplication based on business rules
- Aggregations used by multiple downstream models
- Date spines and other analytical spines

Example:

```text
stg_sale_orders
       +
stg_sale_order_lines
       +
stg_customers
       +
stg_products
       ↓
int_sales_enriched
```

### Spine Concept

A spine is used when reporting requires rows to exist even when no activity occurred.

Example date spine:

```text
2026-01-01
2026-01-02
2026-01-03
...
```

This allows dashboards to display zero-activity periods instead of completely missing dates.

Other possible spines include:

```text
Date × Branch
Month × Customer
Month × Product
Date × Employee
```

### 3. Mart Layer

Schema:

```text
analytics_marts
```

Purpose:

The mart layer contains final analytics-ready tables designed for dashboards, KPIs, and reporting.

Dashboards should preferably consume this layer instead of querying the raw Odoo schema directly.

Possible models:

```text
fact_sales
dim_customer
dim_product
dim_date
dim_salesperson
```

Example star schema:

```text
                 dim_customer
                      |
                      |
dim_product ---- fact_sales ---- dim_date
                      |
                      |
                dim_salesperson
```

The mart layer should be:

- Easy to understand
- Stable
- Business-oriented
- Fast to query
- Tested
- Ready for Power BI, Grafana, or other BI tools

## Modeling Approach

The project follows a domain-first approach.

We do **not** attempt to model every Odoo table at once.

For each business domain:

```text
1. Define the business domain
2. Identify the business questions
3. Define required KPIs
4. Identify relevant Odoo source tables
5. Understand the grain of each table
6. Identify primary keys and foreign keys
7. Understand table cardinality
8. Validate source data quality
9. Build staging models
10. Build intermediate models
11. Build mart models
12. Validate final metrics
13. Connect the mart to dashboards
```

Example domains:

```text
Sales
Purchasing
Inventory
Accounting
CRM
Helpdesk
Projects
HR
```

Only one domain should be developed at a time until its analytics pipeline is stable.

## Current Domain: Sales

Initial source tables being analyzed include:

```text
public.sale_order
public.sale_order_line
public.res_partner
public.product_product
public.product_template
public.product_category
```

Initial understanding:

```text
sale_order
Grain: one row per sales order

sale_order_line
Grain: one row per sales order line
```

Expected relationship:

```text
sale_order.id
      |
      | 1 : N
      |
sale_order_line.order_id
```

This relationship must be validated using actual PostgreSQL PK/FK metadata before building downstream models.

## Grain and Cardinality

Before creating any join, the grain of both tables must be understood.

Example:

```text
sale_order
1 row = 1 order

sale_order_line
1 row = 1 order line
```

A one-to-many join may duplicate order-level measures.

Example:

```text
Order 1001 = 1,000
Order 1001 has 3 lines
```

After joining the order header to its lines:

```text
1001    1,000    Product A
1001    1,000    Product B
1001    1,000    Product C
```

A direct:

```sql
SUM(amount_total)
```

would incorrectly return:

```text
3,000
```

instead of:

```text
1,000
```

Therefore:

> Never create a join before understanding the grain and cardinality of both datasets.

## Data Quality Principles

Before a source table is used in analytics, validate:

- Row count
- Primary key uniqueness
- Null values in important fields
- Foreign-key integrity
- Duplicate records
- Valid status values
- Date ranges
- Unexpected negative or zero values
- Orphan records
- Join multiplication
- Business-rule consistency

Do not use `SELECT DISTINCT` as a general solution for duplicates.

A duplicate-looking row may represent a valid business event.

Technical duplicates should only be removed after their cause and business meaning are understood.

## Naming Convention

Recommended prefixes:

```text
stg_   → staging models
int_   → intermediate models
fact_  → fact tables
dim_   → dimension tables
```

Examples:

```text
analytics_staging.stg_sale_orders
analytics_staging.stg_sale_order_lines

analytics_intermediate.int_sales_enriched
analytics_intermediate.int_daily_sales

analytics_marts.fact_sales
analytics_marts.dim_customer
analytics_marts.dim_product
analytics_marts.dim_date
```

Use lowercase `snake_case` for database objects.

Example:

```text
customer_id
order_date
total_amount
salesperson_id
```

## Suggested Repository Structure

```text
light-speed/
│
├── README.md
├── sql/
│   ├── staging/
│   │   ├── sales/
│   │   ├── purchasing/
│   │   └── inventory/
│   │
│   ├── intermediate/
│   │   ├── sales/
│   │   ├── purchasing/
│   │   └── inventory/
│   │
│   ├── marts/
│   │   ├── sales/
│   │   ├── purchasing/
│   │   └── inventory/
│   │
│   └── tests/
│
├── docs/
│   ├── architecture.md
│   ├── data_dictionary.md
│   └── source_relationships.md
│
└── dashboards/
```

A possible Sales structure:

```text
sql/
├── staging/
│   └── sales/
│       ├── stg_sale_orders.sql
│       ├── stg_sale_order_lines.sql
│       ├── stg_customers.sql
│       └── stg_products.sql
│
├── intermediate/
│   └── sales/
│       ├── int_sales_enriched.sql
│       └── int_daily_sales.sql
│
└── marts/
    └── sales/
        ├── fact_sales.sql
        ├── dim_customer.sql
        ├── dim_product.sql
        └── dim_date.sql
```

## Development Rules

1. Do not modify Odoo source tables in `public`.
2. Do not create dashboard logic directly on raw source tables unless required for investigation.
3. Understand the grain before joining tables.
4. Validate PK/FK relationships instead of assuming them from column names.
5. Keep staging transformations simple.
6. Put reusable joins and business logic in the intermediate layer.
7. Keep marts focused on reporting and business consumption.
8. Validate row counts before and after joins.
9. Document important business rules.
10. Complete one domain before expanding to another.

## Tools

Current development environment:

```text
PostgreSQL
DBeaver
Git / GitHub
```

Target BI tools may include:

```text
Power BI
Grafana
```

## Local Development

Example PostgreSQL connection:

```text
Host: localhost
Port: 5432
Database: light_speed
```

Credentials must never be stored in this repository.

Do not commit:

```text
.env
passwords
database backups
production credentials
private connection strings
```

## Project Status

Current progress:

- [x] PostgreSQL environment prepared
- [x] Odoo database restored
- [x] Analytics schemas created
- [x] Source tables available in `public`
- [x] Initial Sales source discovery started
- [ ] Complete Sales source relationship map
- [ ] Validate Sales PK/FK relationships
- [ ] Create Sales staging models
- [ ] Create Sales intermediate models
- [ ] Create Sales marts
- [ ] Add data-quality tests
- [ ] Build first Sales dashboard
- [ ] Move to the next business domain

## Long-Term Goal

The final goal is to create a governed analytics layer between Odoo and reporting tools:

```text
Operational Odoo Data
          ↓
Clean Analytics Models
          ↓
Reliable Business Metrics
          ↓
Consistent Dashboards
          ↓
Better Decision Making
```

The analytics layer should allow business users to consume consistent KPIs without needing to understand the complexity of the underlying Odoo database.
