
create VIEW gold.dim_customers as 
    select 
    Row_number() over (order by ci.[cst_id])customer_sur_key,
    ci.[cst_id] as customer_id,
    ci.[cst_key] as customer_number,
    ci.[cst_firstname]as first_name,
    ci.[cst_lastname] as last_name,
    cl.cntry as country,
    ca.[bdate]birth_date,
    case 
        when cst_gndr != 'n/a' then cst_gndr 
        else ISNULL(gen,'n/a') 
    end as gender,
    ci.[cst_marital_status] as marital_status,
    ci.[cst_create_date] as create_date
    from [silver].[crm_cust_info] as ci left join [silver].[erp_cust_AZ12] as ca on 
    ci.cst_key =ca.cid left join [silver].[erp_LOC_A101] as cl on
    ci.cst_key =cl.cid 

