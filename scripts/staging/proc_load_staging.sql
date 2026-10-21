/*
================================================================================
Stored Procedure: Load Staging Layer (Source -> Staging)
================================================================================
Script Purpose:
    This stored procedure loads data into the 'staging' schema from external CSV files.
    It performs the following actions:
    - Truncates the staging tables before loading data.
    - Uses the `BULK INSERT` command to load data from CSV files to staging tables.

Parameters:
    None.
    This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXECUTE  staging.load_staging;
================================================================================
*/


CREATE OR ALTER PROCEDURE staging.load_staging AS
BEGIN
	DECLARE @start_time DATETIME,
			@end_time DATETIME,
			@batch_start_time DATETIME,
			@batch_end_time DATETIME;

			
	BEGIN TRY
		SET @batch_start_time = GETDATE();
		
		PRINT '============================================================';
		PRINT 'Loading Staging Layer';
		PRINT '============================================================';
	 	
		PRINT '------------------------------------------------------------';
		PRINT 'Loading CRM Tables';
		PRINT '------------------------------------------------------------';
	
		
		SET @start_time = GETDATE();
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
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '------------------------------------------------------------';
		
		
		SET @start_time = GETDATE();
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
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '------------------------------------------------------------';
		
		
		SET @start_time = GETDATE();
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
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '------------------------------------------------------------';
		
		
		PRINT '------------------------------------------------------------';
		PRINT 'Loading ERP Tables';
		PRINT '------------------------------------------------------------';
		
		
		SET @start_time = GETDATE();
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
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '------------------------------------------------------------';
		
		
		SET @start_time = GETDATE();
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
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '------------------------------------------------------------';
		
		
		SET @start_time = GETDATE();
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
		
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '------------------------------------------------------------';
				
		
		SET @batch_end_time = GETDATE();
		PRINT '==========================================='
		PRINT 'Loading Staging is Completed';
		PRINT '    - Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
		PRINT '==========================================='
	
	END TRY
	BEGIN CATCH
		PRINT '==========================================='
		PRINT 'ERROR OCCURED DURING LOADING STAGING'
		PRINT 'ERROR MESSAGE: ' + ERROR_MESSAGE();
		PRINT 'ERROR NUMBER: ' + CAST(ERROR_NUMBER() AS NVARCHAR(20));
		PRINT 'ERROR STATE: ' + CAST(ERROR_STATE() AS NVARCHAR(20));	
		PRINT '==========================================='
	END CATCH
END
