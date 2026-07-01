
CREATE VIEW gold.fact_sales as 
select 
[sls_ord_num] as order_number,
[product_sur_key] as product_dim_id,
[customer_sur_key] as customer_dim_id,
[sls_sales]as  sales_amount,
[sls_quantity]as quantity,
[sls_price] as price,
[sls_order_dt]as  order_date,
[sls_ship_dt]as  ship_date,
[sls_due_dt]as  due_date

FROM [silver].[crm_sales_details] as sales 
LEFT JOIN [gold].[dim_products] products ON
sales.sls_prd_key = products.product_key  LEFT JOIN gold.dim_customers as customers
on sales.sls_cust_id=customers.customer_id



