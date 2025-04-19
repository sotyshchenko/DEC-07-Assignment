{{ config(
    materialized = 'incremental',
    unique_key = 'date'
) }}

select
  cast(order_date as date) as date,
  count(distinct order_id) as daily_orders
from {{ ref('stg_orders') }}
{% if is_incremental() %}
where date > (select max(date) from {{ this }})
{% endif %}
group by date

