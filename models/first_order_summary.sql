{{ config(
    materialized='table'
) }}

with first_order as (
  select *,
    row_number() over (partition by customer_id order by order_date) as row_number
  from {{ ref('stg_orders') }}
)
select *
from first_order
where row_number = 1