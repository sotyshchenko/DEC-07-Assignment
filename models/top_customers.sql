{{ config(materialized='table') }}

with customer_monthly_spending as (
    select
        c.customer_id,
        c.first_name,
        c.last_name,
        month(o.order_date) as month,
        sum(o.amount) as total_spent
    from {{ ref('orders') }} o
    join {{ ref('customers') }} c
        on o.customer_id = c.customer_id
    group by c.customer_id, c.first_name, c.last_name, month
),

ranked_customers as (
    select
        *,
        rank() over (
            partition by month
            order by total_spent desc
        ) as customer_rank
    from customer_monthly_spending
)

select customer_id, first_name, last_name, month, total_spent
from ranked_customers
where customer_rank = 1
order by month
