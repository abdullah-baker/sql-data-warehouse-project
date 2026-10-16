create SCHEMA marts
create SCHEMA staging
create SCHEMA intermediate




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




====================================



EXECUTE  staging.load_staging;


CREATE OR ALTER PROCEDURE staging.load_staging AS
BEGIN
	
	PRINT '============================================================';
	PRINT 'Loading Staging Layer';
	PRINT '============================================================';

	PRINT '------------------------------------------------------------';
	PRINT 'Loading CRM Tables';
	PRINT '------------------------------------------------------------';

	PRINT '>> Truncating Table: staging.crm_cust_info';
	TRUNCATE TABLE staging.crm_cust_info;
	
	PRINT '>> Inserting Data Into Table: staging.crm_cust_info';
	BULK INSERT staging.crm_cust_info 
		FROM 'C:\Users\abdul\OneDrive\Desktop\dwh_project\source_crm\cust_info.csv'
	WITH (
		FIRSTROW = 2,
		FIELDTERMINATOR = ',',
		TABLOCK
		);
	
	PRINT '>> Truncating Table: staging.crm_prd_info';
	TRUNCATE TABLE staging.crm_prd_info;
	PRINT '>> Inserting Data Into Table: staging.crm_prd_info';
	BULK INSERT staging.crm_prd_info
		FROM 'C:\Users\abdul\OneDrive\Desktop\dwh_project\source_crm\prd_info.csv'
	WITH (
		FIRSTROW = 2,
		FIELDTERMINATOR = ',',
		TABLOCK
		);
	
	PRINT '>> Truncating Table: staging.crm_sales_details';
	TRUNCATE TABLE staging.crm_sales_details;
	PRINT '>> Inserting Data Into Table: staging.crm_sales_details';
	BULK INSERT staging.crm_sales_details
		FROM 'C:\Users\abdul\OneDrive\Desktop\dwh_project\source_crm\sales_details.csv'
	WITH (
		FIRSTROW = 2,
		FIELDTERMINATOR = ',',
		TABLOCK
		);
	
	PRINT '------------------------------------------------------------';
	PRINT 'Loading ERP Tables';
	PRINT '------------------------------------------------------------';
	
	
	PRINT '>> Truncating Table: staging.erp_cust_az12';
	TRUNCATE TABLE staging.erp_cust_az12;
	PRINT '>> Inserting Data Into Table: staging.erp_cust_az12';
	BULK INSERT staging.erp_cust_az12
		FROM 'C:\Users\abdul\OneDrive\Desktop\dwh_project\source_erp\CUST_AZ12.csv'
	WITH (
		FIRSTROW = 2,
		FIELDTERMINATOR = ',',
		TABLOCK
		);
	
	PRINT '>> Truncating Table: staging.erp_loc_a101';
	TRUNCATE TABLE staging.erp_loc_a101;
	PRINT '>> Inserting Data Into Table: staging.erp_loc_a101';
	BULK INSERT staging.erp_loc_a101
		FROM 'C:\Users\abdul\OneDrive\Desktop\dwh_project\source_erp\LOC_A101.csv'
	WITH (
		FIRSTROW = 2,
		FIELDTERMINATOR = ',',
		TABLOCK
		);
	
	PRINT '>> Truncating Table: staging.erp_px_cat_g1v2';
	TRUNCATE TABLE staging.erp_px_cat_g1v2;
	PRINT '>> Inserting Data Into Table: staging.erp_px_cat_g1v2';
	BULK INSERT staging.erp_px_cat_g1v2
		FROM 'C:\Users\abdul\OneDrive\Desktop\dwh_project\source_erp\PX_CAT_G1V2.csv'
	WITH (
		FIRSTROW = 2,
		FIELDTERMINATOR = ',',
		TABLOCK
		);
END
















