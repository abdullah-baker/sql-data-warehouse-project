/*
================================================================================
DDL Script: Create Staging Tables
================================================================================
Script Purpose:
    This script creates the tables in the 'staging' schema.

    It drops existing tables if they already exist and recreates
    them with the defined structure.

    The staging layer stores raw data extracted from CRM and ERP
    source systems before cleaning and transformation.

Warning:
    Running this script will delete all existing data in these tables.

Prerequisites:
    - The staging schema must already exist.
    - Execute this script in the intended Data Warehouse database.
================================================================================
*/

	

IF OBJECT_ID ('staging.crm_cust_info' , 'U') IS NOT NULL 
	DROP TABLE staging.crm_cust_info;
CREATE TABLE staging.crm_cust_info
( 
cst_id int,
cst_key nvarchar(50),
cst_firstname nvarchar(50),
cst_lastname nvarchar(50),
cst_marital_status nvarchar(50),
cst_gndr nvarchar(50),
cst_create_date DATE 
);


IF OBJECT_ID ('staging.crm_prd_info' , 'U') IS NOT NULL 
	DROP TABLE staging.crm_prd_info;
CREATE TABLE staging.crm_prd_info
( 
prd_id int,
prd_key nvarchar(50),
prd_nm nvarchar(50),
prd_cost int,
prd_line nvarchar(50),
prd_start_dt datetime,
prd_end_dt datetime
);


IF OBJECT_ID ('staging.crm_sales_details' , 'U') IS NOT NULL 
	DROP TABLE staging.crm_sales_details;
CREATE TABLE staging.crm_sales_details
(
sls_ord_num nvarchar(50),
sls_prd_key nvarchar(50),
sls_cust_id int,
sls_order_dt int,
sls_ship_dt int,
sls_due_dt int,
sls_sales int,
sls_quantity int,
sls_price int
);


IF OBJECT_ID ('staging.erp_cust_az12' , 'U') IS NOT NULL 
	DROP TABLE staging.erp_cust_az12;
CREATE TABLE staging.erp_cust_az12
(
cid nvarchar(50),
bdate DATE,
gen nvarchar(50)
);


IF OBJECT_ID ('staging.erp_loc_a101' , 'U') IS NOT NULL 
	DROP TABLE staging.erp_loc_a101;
CREATE TABLE staging.erp_loc_a101
(
cid nvarchar(50),
cntry nvarchar(50)
);



IF OBJECT_ID ('staging.erp_px_cat_g1v2' , 'U') IS NOT NULL 
	DROP TABLE staging.erp_px_cat_g1v2;
CREATE TABLE staging.erp_px_cat_g1v2
( 
id nvarchar(50),
cat nvarchar(50),
subct nvarchar(50),
maintenance nvarchar(50)
)

