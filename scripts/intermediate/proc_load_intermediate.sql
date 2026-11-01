/*
===========================================================================
Stored Procedure: Load Silver Layer (staging -> intermediate)
===========================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process to
    populate the 'intermediate' schema tables from the 'staging' schema.
  Actions Performed:
    - Truncates Silver tables.
    - Inserts transformed and cleansed data from Bronze into Silver tables.

Parameters:
    None.
    This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC intermediate.intermediate;
===========================================================================
*/








EXECUTE intermediate.load_intermediate

CREATE OR ALTER PROCEDURE intermediate.load_intermediate AS
BEGIN
	DECLARE @start_time DATETIME,
			@end_time DATETIME,
			@batch_start_time DATETIME,
			@batch_end_time DATETIME;

			
	BEGIN TRY
		SET @batch_start_time = GETDATE();
		
		PRINT '============================================================';
		PRINT 'Loading intermediate Layer';
		PRINT '============================================================';
	 	
		PRINT '------------------------------------------------------------';
		PRINT 'Loading CRM Tables';
		PRINT '------------------------------------------------------------';
	
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: intermediate.crm_cust_info';
		TRUNCATE TABLE intermediate.crm_cust_info;		
		PRINT '>> Inserting Data Into Table: intermediate.crm_cust_info';
		INSERT INTO DataWarehouse.intermediate.crm_cust_info
	(
		cst_id,
	    cst_key,
	    cst_firstname,
	    cst_lastname,
	    cst_marital_status,
	    cst_gndr,
	    cst_create_date
	    )
	
	SELECT 
	    cst_id,
	    cst_key,
	    TRIM(cst_firstname) cst_firstname,
	    TRIM(cst_lastname) cst_lastname,
	       CASE 
		     WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
		     WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
		     ELSE 'n/a' 
	    END cst_marital_status,
	    
	    CASE 
		     WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
		     WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
		     ELSE 'n/a' 
	    END cst_gndr,
	    cst_create_date
	
		FROM (
		SELECT *,
		ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
		FROM DataWarehouse.staging.crm_cust_info   
		WHERE cst_id IS NOT NULL
		)T WHERE flag_last =1 
		
		
		
	
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '------------------------------------------------------------';
		
		
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: intermediate.crm_prd_info';
		TRUNCATE TABLE intermediate.crm_prd_info;
		PRINT '>> Inserting Data Into Table: intermediate.crm_prd_info';
		INSERT INTO DataWarehouse.intermediate.crm_prd_info
	(
	    prd_id,
	    cat_id,
	    prd_key,
	    prd_nm,
	    prd_cost,
	    prd_line,
	    prd_start_dt,
	    prd_end_dt
	)
		SELECT
	    prd_id,
	    REPLACE(SUBSTRING(prd_key,1, 5), '-', '_')as cat_id,
	    SUBSTRING(prd_key,7 , LEN(prd_key))as prd_key,
	    prd_nm,
	    ISNULL (prd_cost,0) AS prd_cost,
	    CASE UPPER(TRIM(prd_line))  
	    	WHEN 'M' THEN 'Mountain'
	   		WHEN 'R' THEN 'Road'
	    	WHEN 'S' THEN 'Other Sales'
	        WHEN 'T' THEN 'Touring'
	       	else 'n/a'
	    END AS prd_line,
	    CAST(prd_start_dt AS DATE) AS prd_start_dt,
	    CAST(LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)-1 AS DATE) AS prd_end_dt
		FROM
	    DataWarehouse.staging.crm_prd_info
	
	    SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '------------------------------------------------------------';   
	
	    
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: intermediate.crm_sales_details';
		TRUNCATE TABLE intermediate.crm_sales_details;
		PRINT '>> Inserting Data Into Table: intermediate.crm_sales_details';
	
	
	    INSERT INTO DataWarehouse.intermediate.crm_sales_details( 
	    sls_ord_num,
	    sls_prd_key,
	    sls_cust_id,
	    sls_order_dt,
	    sls_ship_dt,
	    sls_due_dt,
	    sls_sales,
	    sls_quantity,
	    sls_price
	    )
	    SELECT
	    sls_ord_num,
	    sls_prd_key,
	    sls_cust_id,
	    CASE WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL 
	    	ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
	    END AS sls_order_dt,
	    CASE WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL 
	    	ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
	    END AS sls_ship_dt,
	    CASE WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL 
	    	ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
	    END AS sls_due_dt,
	    
	    CASE WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
			    THEN sls_quantity * ABS(sls_price)
			   	ELSE sls_sales
	 	END AS sls_sales,
	 	 sls_quantity ,
	    CASE WHEN sls_price IS NULL OR sls_price <= 0 
	    	THEN sls_sales / NULLIF(sls_quantity,0)
	    ELSE sls_price
	    END  AS sls_price
	    FROM
	    DataWarehouse.staging.crm_sales_details
	 
	    SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '------------------------------------------------------------';
		
		
		PRINT '------------------------------------------------------------';
		PRINT 'Loading ERP Tables';
		PRINT '------------------------------------------------------------';
		
	 
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: intermediate.erp_cust_az12';
		TRUNCATE TABLE intermediate.erp_cust_az12;
		PRINT '>> Inserting Data Into Table: intermediate.erp_cust_az12';
		
		 INSERT INTO DataWarehouse.intermediate.erp_cust_az12
		 (
		 cid,
		 bdate,
		 gen
		 )
		SELECT
	    CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
	         ELSE cid
	    END AS cid,
	
	    CASE WHEN bdate > GETDATE() THEN NULL
	         ELSE bdate
	    END AS bdate,
	
	    CASE WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
	         WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
	         ELSE 'n/a'
	    END AS gen
		FROM DataWarehouse.staging.erp_cust_az12
	
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '------------------------------------------------------------';
		
		
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: intermediate.erp_loc_a101';
		TRUNCATE TABLE intermediate.erp_loc_a101;
		PRINT '>> Inserting Data Into Table: intermediate.erp_loc_a101';

	
	INSERT INTO DataWarehouse.intermediate.erp_loc_a101
	 (
	 cid,
	 cntry
	 )
	 SELECT 
		REPLACE(cid,'-','') AS cid,
	 	CASE WHEN TRIM(cntry) = 'DE' THEN 'Germany'
	 		 WHEN TRIM(cntry) IN ('USA' ,'US') THEN 'United States'
	 		 WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
	 		 ELSE TRIM(cntry)
	 	END AS cntry
	FROM DataWarehouse.staging.erp_loc_a101
	
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '------------------------------------------------------------';
				
	
	
	SET @start_time = GETDATE();
		PRINT '>> Truncating Table: intermediate.erp_px_cat_g1v2';
		TRUNCATE TABLE intermediate.erp_px_cat_g1v2;
		PRINT '>> Inserting Data Into Table: intermediate.erp_px_cat_g1v2';
	
	INSERT INTO DataWarehouse.intermediate.erp_px_cat_g1v2
	(
	    id,
	    cat,
	    subct,
	    maintenance
	)
	SELECT
	    id,
	    cat,
	    subct,
	    maintenance
	FROM
	    DataWarehouse.staging.erp_px_cat_g1v2;
 
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '------------------------------------------------------------';
				
		
		SET @batch_end_time = GETDATE();
		PRINT '==========================================='
		PRINT 'Loading intermediate is Completed';
		PRINT '    - Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
		PRINT '==========================================='
	
	END TRY
	BEGIN CATCH
		PRINT '==========================================='
		PRINT 'ERROR OCCURED DURING LOADING intermediate'
		PRINT 'ERROR MESSAGE: ' + ERROR_MESSAGE();
		PRINT 'ERROR NUMBER: ' + CAST(ERROR_NUMBER() AS NVARCHAR(20));
		PRINT 'ERROR STATE: ' + CAST(ERROR_STATE() AS NVARCHAR(20));	
		PRINT '==========================================='
	END CATCH
END


