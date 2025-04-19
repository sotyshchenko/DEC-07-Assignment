{{ config(
    materialized='table'
) }}

select first_name, last_name, so.order_id, order_date, status, amount
from  {{ ref('stg_orders') }} so
join {{ ref('stg_customers') }} sc on so.customer_id = sc.customer_id
join {{ ref('stg_payments') }} sp on so.order_id = sp.order_id
    where payment_method = 'gift_card' and
          amount > 1500