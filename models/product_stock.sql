{{ config(
    materialized='table'
) }}

select
  p.product_id,
  p.book_name,
  s.stock_quantity,
  case
    when s.stock_quantity = 0 then 'out of stock'
    when s.stock_quantity < 10 then 'low stock'
    else 'in stock'
  end as stock_status
from {{ ref('stg_products') }} p
left join {{ ref('stg_stock') }} s on p.product_id = s.product_id
