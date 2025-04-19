{{ config(
    materialized='table'
) }}

select
  spr.product_id,
  spr.book_name,
  count(distinct so.customer_id) as unique_buyers,
  count(*) as total_purchases,
  count(*) - count(distinct so.customer_id) as repeat_purchases
from {{ ref('stg_orders') }} so
join {{ ref('stg_products') }} spr on so.product_id = spr.product_id
join {{ ref('stg_payments') }} sp on so.order_id = sp.order_id
group by spr.product_id, spr.book_name
