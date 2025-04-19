{{ config(
    materialized='view'
) }}

select
  spr.product_id,
  spr.book_name,
  sum(sp.amount) as total_revenue,
  count(so.order_id) as total_orders,
  row_number() over (order by sum(sp.amount) desc) as product_rank
from {{ ref('stg_orders') }} so
join {{ ref('stg_products') }} spr on spr.product_id = so.product_id
join {{ ref('stg_payments') }} sp on so.order_id = sp.order_id
group by spr.product_id, spr.book_name
