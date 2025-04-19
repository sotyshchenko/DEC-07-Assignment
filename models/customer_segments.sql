{{ config(
    materialized='table'
) }}

select
  customer_id,
  max(order_date) as last_order,
  case
    when max(order_date) >= current_date - 30 then 'loyal'
    when max(order_date) >= current_date - 90 then 'at risk'
    else 'churned'
  end as segment
from {{ ref('stg_orders') }}
group by customer_id