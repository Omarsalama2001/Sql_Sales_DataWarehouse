
CREATE OR ALTER PROCEDURE bronze.load_bronze AS

BEGIN
    DECLARE @start_time DateTime ,@end_time DateTime ,@start_batch_time DateTime,@end_batch_time DateTime
    BEGIN TRY
        set @start_batch_time =GetDate()

        print '========================================================================';
        print 'Loading Bronze Layer';
        print '========================================================================';
        
        -- bulk insert the data for crm(source)

        print '--------------------------------------------------------------------';
        print 'Loading CRM Tables';
        print '--------------------------------------------------------------------';
        set @start_time =GetDate()

        print '<< Truncating table : bronze.crm_cust_info'
        TRUNCATE TABLE bronze.crm_cust_info
        
        print '<< Inseting data into table : bronze.crm_cust_info'
        BULK INSERT bronze.crm_cust_info
        from 'D:\data_warehouse_project\datasets\source_crm\cust_info.csv'
        WITH(
            FIRSTROW =2,
            FIELDTERMINATOR= ','
        )
        set @end_time =GetDate()
        print '>>Load Duration :' +cast (DateDiff(second,@start_time,@end_time)as NVARCHAR) +' seconds'
        

        set @start_time =GetDate()
        print '<< Truncating table : bronze.crm_prd_info'
        TRUNCATE TABLE bronze.crm_prd_info

        print '<< Inseting data into table : bronze.crm_prd_info'
        BULK INSERT bronze.crm_prd_info
        from 'D:\data_warehouse_project\datasets\source_crm\prd_info.csv'
        WITH(
            FIRSTROW =2,
            FIELDTERMINATOR= ','
        )
        set @end_time =GetDate()
        print '>>Load Duration :' +cast (DateDiff(second,@start_time,@end_time)as NVARCHAR) +' seconds'




        
        set @start_time =GetDate()

        print '<< Truncating table : bronze.crm_sales_details'

        TRUNCATE TABLE bronze.crm_sales_details
        print '<< Inseting data into table : crm_sales_details'

        BULK INSERT bronze.crm_sales_details
        from 'D:\data_warehouse_project\datasets\source_crm\sales_details.csv'
        WITH(
            FIRSTROW =2,
            FIELDTERMINATOR= ','
        )
        set @end_time =GetDate()
        print '>>Load Duration :' +cast (DateDiff(second,@start_time,@end_time)as NVARCHAR) +' seconds'
    

        -- bulk insert the data for erp(source)
        
        print '--------------------------------------------------------------------';
        print 'Loading ERP Tables';
        print '--------------------------------------------------------------------';

        set @start_time =GetDate()        
        print '<< Truncating table : bronze.erp_cust_AZ12'
   
        TRUNCATE TABLE bronze.erp_cust_AZ12
        print '<< Inseting data into table : bronze.erp_cust_AZ12'

        BULK INSERT bronze.erp_cust_AZ12
        from 'D:\data_warehouse_project\datasets\source_erp\CUST_AZ12.csv'
        WITH(
            FIRSTROW =2,
            FIELDTERMINATOR= ','
        )
        set @end_time =GetDate()
        print '>>Load Duration :' +cast (DateDiff(second,@start_time,@end_time)as NVARCHAR) +' seconds'    



        print '<< Truncating table : bronze.erp_loc_A101'

        set @start_time =GetDate()
        TRUNCATE TABLE bronze.erp_loc_A101
        print '<< Inseting data into table :bronze.erp_loc_A101'
        BULK INSERT bronze.erp_loc_A101
        from 'D:\data_warehouse_project\datasets\source_erp\loc_A101.csv'
        WITH(
            FIRSTROW =2,
            FIELDTERMINATOR= ','
        )
        set @end_time =GetDate()
        print '>>Load Duration :' +cast (DateDiff(second,@start_time,@end_time)as NVARCHAR) +' seconds'   
    


        set @start_time =GetDate()
        print '<< Truncating table : bronze.erp_px_cat_g1v2'

        TRUNCATE TABLE bronze.erp_px_cat_g1v2
        print '<< Inseting data into table :bronze.erp_px_cat_g1v2'

        BULK INSERT bronze.erp_px_cat_g1v2
        from 'D:\data_warehouse_project\datasets\source_erp\px_cat_g1v2.csv'
        WITH(
            FIRSTROW =2,
            FIELDTERMINATOR= ','
        )
        set @end_time =GetDate()

        print '>>Load Duration :' +cast (DateDiff(second,@start_time,@end_time)as NVARCHAR) +' seconds'   
        set @end_batch_time =GetDate()
        print'========================================================================='
        print ' Loading Completed successfully into the bronze layer'
        print'========================================================================='

        print 'Batch Time (Bronze layer) :'+cast(DateDiff(second,@start_batch_time,@end_batch_time)as NVARCHAR)+ ' seconds'
        print'-------------------------------------------------------------------------------------------------'
    END TRY

    BEGIN CATCH
        PRINT 'ERROR HAPPEND'

    END CATCH
END; 
