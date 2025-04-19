{{ config(
    materialized='view'
) }}

select
  customer_id,
  sum(amount) as total_revenue,
  count(distinct so.order_id) as total_orders,
  round(avg(amount), 2) as avg_order_value,
  min(order_date) as first_order,
  max(order_date) as last_order,
  datediff('day', min(order_date), max(order_date)) as customer_lifespan
from {{ ref('stg_orders') }} so
join {{ ref('stg_payments') }} sp on so.order_id = sp.order_id
group by customer_id