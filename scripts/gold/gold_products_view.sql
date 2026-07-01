CREATE VIEW gold.dim_products as 
select
Row_number() over(order by cp.prd_id) as product_sur_key,
cp.[prd_id] as product_id,
cp.[prd_key] as product_key,
[prd_nm] name,
[cat_id] category_id,
epc.cat as category,
epc.subcat as subcategory,
[prd_cost] cost,
[prd_line] product_line,
epc.maintenance as maintenance,
[prd_start_dt]as start_date,
[prd_end_dt] as end_date

from [silver].[crm_prd_info] as cp LEFT JOIN [silver].[erp_px_cat_g1v2] as epc on 
cp.cat_id =epc.id
where cp.prd_end_dt is null

