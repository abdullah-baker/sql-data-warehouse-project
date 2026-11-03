CREATE VIEW marts.dim_customers As 
SELECT
ROW_NUMBER() OVER (ORDER BY cst_id) as customer_key,
    ci.cst_id Customer_id,
    ci.cst_key as Customer_number,
    ci.cst_firstname as first_name,
    ci.cst_lastname as last_name,
    la.cntry as country,
    ci.cst_marital_status as marital_status,
    CASE WHEN ci. cst_gndr != 'n/a' THEN ci. cst_gndr 
    	 ELSE COALESCE (ca. gen, 'n/a')
    END AS gender , 
    ca.bdate as birthdate,
    ci.cst_create_date as create_date
FROM
    DataWarehouse.intermediate.crm_cust_info ci
LEFT JOIN intermediate.erp_cust_az12 ca
ON   	ci.cst_key = ca.cid 
LEFT JOIN intermediate.erp_loc_a101 la 
ON 		Ci.cst_key = la.cid


CREATE VIEW marts.dim_products AS
SELECT
	  ROW_NUMBER() OVER (ORDER BY  pn.prd_start_dt, pn.prd_key) AS product_key,
	  pn.prd_id AS product_id,
	  pn.prd_key AS product_number,
	  pn.prd_nm AS product_name,
	  pn.cat_id AS category_id,
	  pc.cat AS category,
	  pc.subct AS subcategory,
	  pc.maintenance,
	  pn.prd_cost AS cost,
	  pn.prd_line AS product_line,
	  pn.prd_start_dt AS start_date
FROM DataWarehouse.intermediate.crm_prd_info pn
LEFT JOIN intermediate.erp_px_cat_g1v2 pc
ON pn.cat_id = pc.id
WHERE prd_end_dt IS NULL


CREATE VIEW marts.fact_sales AS

SELECT
    sd.sls_ord_num AS order_number,
    pr.product_key,
    cu.customer_key,
    sd.sls_order_dt AS order_date,
    sd.sls_ship_dt AS shipping_date,
    sd.sls_due_dt AS due_date,
    sd.sls_sales AS sales_amount,
    sd.sls_quantity AS sls_quantity,
    sd.sls_price As price
FROM
    DataWarehouse.intermediate.crm_sales_details sd
LEFT JOIN marts.dim_products pr
ON sd.sls_prd_key = pr.product_number 
LEFT JOIN marts.dim_customers cu
ON sd.sls_cust_id = cu.Customer_id


SELECT * 
FROM marts.fact_sales f
LEFT JOIN marts.dim_customers c
ON c.customer_key = f.customer_key 
 
