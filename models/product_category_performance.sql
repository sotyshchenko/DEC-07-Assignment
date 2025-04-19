{{ config(
    materialized='view'
) }}

select
  spr.product_category,
  count(distinct spr.product_id) as product_count,
  sum(sp.amount) as total_revenue,
  avg(sp.amount) as avg_revenue_per_product
from {{ ref('stg_orders') }} so
join {{ ref('stg_products') }} spr on so.product_id = spr.product_id
join {{ ref('stg_payments') }} sp on so.order_id = sp.order_id
group by spr.product_category
