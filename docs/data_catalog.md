# Data Dictionary for Marts Layer

## Overview

The Marts Layer (Gold Layer) represents business-ready data designed to support analytics, reporting, and business intelligence.

It follows a **Star Schema** design consisting of dimension and fact views.

- **Dimension Views:** Provide descriptive information about customers and products.
- **Fact View:** Contains sales transactions, measures, and references to the dimensions.
- **Data Sources:** Cleaned and transformed data from the `intermediate` schema.

The layer contains the following analytical objects:

| Object Name | Type | Purpose |
|---|---|---|
| `marts.dim_customer` | Dimension View | Customer information |
| `marts.dim_products` | Dimension View | Product information |
| `marts.fact_sales` | Fact View | Sales transactions |

---

## 1. marts.dim_customer

**Purpose:** Provides customer information enriched with demographic and geographic data from CRM and ERP systems.

**Grain:** One record per customer in the current model.

**Source Tables:**

- `intermediate.crm_cust_info`
- `intermediate.erp_cust_az12`
- `intermediate.erp_loc_a101`

### Columns

| Column Name | Data Type | Description |
|---|---|---|
| customer_key | BIGINT | Generated row identifier for each customer using `ROW_NUMBER()`. |
| customer_id | INT | Original numeric customer identifier from CRM. |
| customer_number | NVARCHAR(50) | Customer business identifier used for identification and integration. |
| first_name | NVARCHAR(50) | Customer's first name. |
| last_name | NVARCHAR(50) | Customer's last name. |
| country | NVARCHAR(50) | Country of residence obtained from ERP location data. |
| marital_status | NVARCHAR(50) | Standardized marital status, such as Single, Married, or n/a. |
| gender | NVARCHAR(50) | Customer gender, prioritized from CRM with ERP as a fallback. |
| birthdate | DATE | Customer's date of birth obtained from ERP. |
| create_date | DATE | Date the customer record was created in CRM. |

### Business Rules

1. Duplicate customer records are removed upstream using `ROW_NUMBER()`, retaining the most recent record by creation date.
2. Customer names are cleaned using `TRIM()`.
3. Marital status and gender are standardized.
4. CRM gender takes priority over ERP gender when CRM contains a known value.
5. `LEFT JOIN` preserves CRM customers even when matching ERP information is unavailable.

---

## 2. marts.dim_products

**Purpose:** Provides product information enriched with category and subcategory details from ERP.

**Grain:** One record per current product, assuming category identifiers are unique.

**Source Tables:**

- `intermediate.crm_prd_info`
- `intermediate.erp_px_cat_g1v2`

### Columns

| Column Name | Data Type | Description |
|---|---|---|
| product_key | BIGINT | Generated row identifier using `ROW_NUMBER()`. |
| product_id | INT | Original numeric product identifier from CRM. |
| product_number | NVARCHAR(50) | Product business code used for tracking and sales integration. |
| product_name | NVARCHAR(50) | Descriptive name of the product. |
| category_id | NVARCHAR(50) | Product category identifier used to integrate CRM and ERP data. |
| category | NVARCHAR(50) | Main product category, such as Bikes or Components. |
| subcategory | NVARCHAR(50) | Specific product subcategory, such as Mountain Bikes or Road Frames. |
| maintenance | NVARCHAR(50) | Maintenance classification provided by ERP. |
| cost | INT | Product cost after upstream data cleaning. |
| product_line | NVARCHAR(50) | Standardized product line, such as Road, Mountain, or Touring. |
| start_date | DATETIME | Start date of the current product record, based on the shared intermediate table definition. |

### Business Rules

1. Category identifiers are extracted from the original CRM product key.
2. Product costs with missing values are replaced with zero upstream.
3. Product line abbreviations are standardized into descriptive values.
4. CRM products are enriched with ERP category information through `cat_id = id`.
5. Only records with `prd_end_dt IS NULL` are included, representing the current product records under the project's date rules.
6. Products without matching ERP categories remain available because the view uses `LEFT JOIN`.

---

## 3. marts.fact_sales

**Purpose:** Represents sales transactions and provides measurable business metrics such as sales amount, quantity, and price.

**Grain:** One record per sales order line.

**Source Tables and Views:**

- `intermediate.crm_sales_details`
- `marts.dim_products`
- `marts.dim_customer`

**Status:** Proposed output specification based on the sales query and Star Schema design. The final view definition still needs confirmation.

### Columns

| Column Name | Data Type | Description |
|---|---|---|
| order_number | NVARCHAR(50) | Identifier of the sales order. May repeat across multiple order lines. |
| product_key | BIGINT | Logical foreign key referencing the Product Dimension. |
| customer_key | BIGINT | Logical foreign key referencing the Customer Dimension. |
| order_date | DATE | Date when the customer placed the order. |
| shipping_date | DATE | Date when the order was shipped. |
| due_date | DATE | Expected delivery or due date of the order. |
| sales_amount | INT | Total sales amount associated with the order line. |
| quantity | INT | Number of units sold in the order line. |
| price | INT | Unit selling price of the product. |

### Business Rules

1. Sales records originate from the cleaned CRM sales details.
2. Invalid source dates are handled in the Intermediate Layer.
3. Missing or inconsistent sales amounts are processed according to the cleaning rules.
4. Product keys are resolved by matching the sales product code to `dim_products.product_number`.
5. Customer keys are resolved by matching the sales customer ID to `dim_customer.customer_id`.
6. `LEFT JOIN` preserves sales records even when a dimension match is missing.
7. Sales metrics can be aggregated to calculate revenue, quantity sold, and other business KPIs.

---

## 4. Data Relationships

| From | To | Relationship |
|---|---|---|
| `fact_sales.product_key` | `dim_products.product_key` | Many-to-One |
| `fact_sales.customer_key` | `dim_customer.customer_key` | Many-to-One |

### Relationship Explanation

- One customer can generate multiple sales transactions.
- One product can appear in multiple sales transactions.
- Each sales row references a customer and product when matching dimension records exist.

These relationships form the analytical **Star Schema**.

---

## 5. Technical Considerations

### Surrogate Keys

The current dimensions generate `customer_key` and `product_key` using `ROW_NUMBER()`.

These values are calculated dynamically inside the views and are not guaranteed to remain stable when records change. Persistent dimension keys are recommended for production implementations.

### Referential Integrity

The relationships described in this dictionary are logical relationships. Regular SQL Server views do not automatically enforce Primary Key or Foreign Key constraints.

### Historical Data

The Product Dimension currently includes only records without an end date. Historical sales may require additional logic to match products that are no longer current.

### Data Quality

The following controls are recommended:

- Verify unique customer and product keys.
- Check for unmatched sales dimension keys.
- Validate sales amounts and quantities.
- Confirm that joins do not duplicate sales transactions.
- Compare source and target record counts.

---

## 6. Analytical Use Cases

The Marts Layer supports reporting requirements such as:

- Total Sales Revenue
- Total Quantity Sold
- Sales by Customer
- Sales by Country
- Sales by Product
- Sales by Category
- Sales by Product Line
- Sales Trends Over Time

These metrics can be consumed by reporting tools such as Power BI, Metabase, and SQL-based analytical reports.
