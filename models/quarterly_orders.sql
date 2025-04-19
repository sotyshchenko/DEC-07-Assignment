{{ config(materialized='table') }}


select {{ get_quarter('order_date') }} AS quarter,
       count(so.order_id) as order_count,
       sum(amount) as orders_value
from {{ ref('stg_orders') }} so
join {{ ref('stg_payments') }} sp on so.order_id = sp.order_id
group by quarter

