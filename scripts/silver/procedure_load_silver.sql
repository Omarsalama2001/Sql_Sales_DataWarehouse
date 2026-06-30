create OR ALTER procedure silver.load_silver as
BEGIN
    declare @start_time DateTime ,@end_time DateTime ,@batch_start_time DateTime  ,@batch_end_time DateTime;
    BEGIN TRY
        set @batch_start_time=GetDate();
        print '========================================================='
        print 'Loading Silver Layer'
        print '========================================================='

        print '----------------------------------------------------------'
        print 'Loding CRM (SOURCE) Tables'
        print '----------------------------------------------------------'
        -- Loading silver.crm_cust_info TABLE
        set @start_time=GetDate();
        PRINT '<<TRUNCATING silver.crm_cust_info TABLE';
        TRUNCATE TABLE silver.crm_cust_info ;
        PRINT '<<loading silver.crm_cust_info TABLE';
        with last_cust_info as (
            select * , Row_Number() over (partition by cst_id order by cst_create_date) as rnk
            from bronze.crm_cust_info
        ) 

        INSERT INTO silver.crm_cust_info(cst_id,cst_key,cst_firstname,cst_lastname,cst_marital_status,cst_gndr,cst_create_date)
        select
        [cst_id],
        [cst_key],
        TRIM([cst_firstname]) as cst_firstname,
        Trim([cst_lastname]) as cst_lastname,
        case when TRIM([cst_marital_status])='M' then 'Married' -- standization for the martial_status as (Married , Single, n/a)
            when TRIM([cst_marital_status]) ='S' then 'Single' 
            else 'n/a'
        end  as cst_marital_status,
        case when UPPER(TRIM([cst_gndr]))='M' then 'Male' -- standization for the gender as (Male , Female, n/a)
            when UPPER(TRIm([cst_gndr])) ='F' then 'Female'
            else 'n/a'
        end as cst_gndr,
        [cst_create_date]
        from last_cust_info
        where rnk =1 and cst_id is not null
        set @end_time=GetDate();
        print '>> Loading Duration :'+ CAST(DATEDIFF(second, @start_time ,@end_time)AS NVARCHAR)
        print '------------------------------------------------------'

        -- Loading silver.crm_prd_info TABLE
        set @start_time=GetDate();

        PRINT '<<TRUNCATING silver.crm_prd_info TABLE';
        TRUNCATE TABLE silver.crm_prd_info ;
        PRINT '<<loading silver.crm_prd_info TABLE';

        INSERT INTO [silver].[crm_prd_info] ([prd_id],[prd_key],[cat_id],[prd_nm],[prd_cost],[prd_line],[prd_start_dt],[prd_end_dt])
        select 
        prd_id ,
        SUBSTRING (prd_key,7,LEN(prd_key))AS prd_key, -- derived column from the <prd_key> for <CRM> Product table joining
        REPLACE (SUBSTRING (prd_key,1,5),'-','_' )AS cat_id, -- derived column from the <prd_key> for <ERP> category table joining
        prd_nm,
        ISNULL(prd_cost,0) as prd_cost ,
        case Upper(Trim(prd_line))
        when 'R' then 'Road' 
        when 'M' then 'Mountain'
        when 'T' then 'Touring'
        when 'S' then 'Other Sales '
        else 'n/a'
        end  as prd_line,
        prd_start_dt,
        DATEADD(day,-1,LEAD([prd_start_dt]) over(partition by [prd_key] order by [prd_start_dt] asc)) as prd_end_dt -- handling invalid "prd_end_date" 
        from [bronze].[crm_prd_info]
                set @end_time=GetDate();
        print '>> Loading Duration :'+ CAST(DATEDIFF(second, @start_time ,@end_time)AS NVARCHAR)
        print '------------------------------------------------------'

        -- Loading silver.crm_sales_details TABLE
        set @start_time=GetDate();

        PRINT '<<TRUNCATING silver.crm_sales_details TABLE';
        TRUNCATE TABLE silver.crm_sales_details ;
        PRINT '<<loading silver.crm_sales_details TABLE';
        INSERT INTO silver.crm_sales_details ( 
                sls_ord_num ,
                sls_prd_key,
                sls_cust_id ,
                sls_order_dt ,
                sls_ship_dt ,
                sls_due_dt ,
                sls_sales ,
                sls_quantity,
                sls_price 
                )
        select 
            [sls_ord_num], -- duplication regrading to the <grain> of the table which is (per item not the whole order)
            [sls_prd_key],
            [sls_cust_id],
            case
                when [sls_order_dt] > 20500101 or [sls_order_dt]<19000101 or  len([sls_order_dt]) !=8 then null 
                Else cast(cast([sls_order_dt]as NVARCHAR(8))as Date) -- validating dates
                end as sls_order_dt,
                    case
                when [sls_ship_dt] > 20500101 or [sls_ship_dt]<19000101 or  len([sls_ship_dt]) !=8 then null
                Else cast(cast([sls_ship_dt]as NVARCHAR(8))as Date)
                end as sls_ship_dt,
                case
                when [sls_due_dt] > 20500101 or [sls_due_dt]<19000101 or  len([sls_due_dt]) !=8 then null
                Else cast(cast([sls_due_dt]as NVARCHAR(8))as Date)
                end as [sls_due_dt]
            ,
            case  -- handling invalid values between the sls_sales and the sales _price 
            when sls_sales is null or sls_sales <=0 or sls_sales !=  [sls_quantity] * ABS([sls_price]) then [sls_quantity] * ABS([sls_price])
            else sls_sales
            end as sls_sales,
            [sls_quantity]
            ,
            case
            when [sls_price] is null or [sls_price] =0 then  sls_sales/NULLIF(sls_quantity,0)
            else ABS([sls_price])
            end as sls_price
        from [bronze].[crm_sales_details]

        set @end_time=GetDate();
        print '>> Loading Duration :'+ CAST(DATEDIFF(second, @start_time ,@end_time)AS NVARCHAR)
        print '------------------------------------------------------'

        -- Loading ERP Transformed data into Silver Layer
        print '----------------------------------------------------------'
        print 'Loding CRM (SOURCE) Tables'
        print '----------------------------------------------------------'

        -- Loading silver.erp_cust_AZ12 TABLE
        set @start_time=GetDate();
        PRINT '<<TRUNCATING silver.erp_cust_AZ12 TABLE';
        TRUNCATE TABLE silver.erp_cust_AZ12 ;
        PRINT '<<loading silver.erp_cust_AZ12 TABLE';

        INSERT INTO [silver].[erp_cust_AZ12] (cid,bdate,gen)
        select 
        SUBSTRING(cid,CHARINDEX('AW',cid),len(cid))as cid, -- standraization for the c_id for right join with <CRM> cust_info table
        case 
            when [bdate] is null or bdate > GETDATE() then null -- validating the bdate
            else [bdate]
        end ,
        case 
            when TRIM([gen]) is null or [gen] ='' then 'n/a' --standraization for the <gen> column as (Male, Female, n/a)
            when UPPER(TRIM([gen])) ='F' then 'Female'
            when UPPER(TRIM([gen])) ='M' then 'Male'
            else  TRIM([gen])
        end as gen
        from [bronze].[erp_cust_AZ12]

        set @end_time=GetDate();
        print '>> Loading Duration :'+ CAST(DATEDIFF(second, @start_time ,@end_time)AS NVARCHAR)
        print '------------------------------------------------------'

        -- Loading silver.erp_LOC_A101 TABLE
        set @start_time=GetDate();
        PRINT '<<TRUNCATING silver.erp_LOC_A101 TABLE';
        TRUNCATE TABLE silver.erp_LOC_A101 ;
        PRINT '<<loading silver.erp_LOC_A101 TABLE';

        INSERT INTO [silver].[erp_LOC_A101](cid,cntry)
        select 
        REPLACE(cid, '-' ,'') as  cid,-- standraization for the cid for the right join with <CRM> cust_info table
        case 
            when TRIM(cntry) ='DE' then 'Germany' -- standraization for the country names LIKE (Germany, United States, n/a)
            when TRIM(cntry) IN('USA' ,'US') then 'United States'
            when TRIM(cntry) ='' or TRIM(cntry) is null then 'n/a'
            else TRIM(cntry) 
        end as cntry
        from [bronze].[erp_LOC_A101]

        set @end_time=GetDate();
        print '>> Loading Duration :'+ CAST(DATEDIFF(second, @start_time ,@end_time)AS NVARCHAR)
        print '------------------------------------------------------'
        
        -- Loading silver.erp_px_cat_g1v2 TABLE
        set @start_time=GetDate();
        PRINT '<<TRUNCATING silver.erp_px_cat_g1v2 TABLE';

        TRUNCATE TABLE silver.erp_px_cat_g1v2 ;
        PRINT '<<loading silver.erp_px_cat_g1v2 TABLE';

        INSERT INTO [silver].[erp_px_cat_g1v2] (id ,cat ,subcat,maintenance)
        select 
        [id],
        [cat],
        [subcat],
        [maintenance]
        from [bronze].[erp_px_cat_g1v2]
        set @end_time=GetDate();

        print '>> Loading Duration :'+ CAST(DATEDIFF(second, @start_time ,@end_time)AS NVARCHAR)
        print '------------------------------------------------------'
            set @batch_end_time=GETDATE()
            print '=========================================================='
            print 'Loading Silver Layer Completed successfuly'
            print '=========================================================='
            print '>> Batch Loading Duration : '+ CAST(DATEDIFF(second, @batch_start_time ,@batch_end_time)AS NVARCHAR) + ' seconds'
    END TRY
    BEGIN CATCH
        print 'error happend'
        print ERROR_MESSAGE()
    END CATCH

END
GO
EXEC silver.load_silver

