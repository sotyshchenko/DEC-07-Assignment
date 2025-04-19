{{ config(
    materialized='incremental',
    unique_key=['customer_id', 'order_month']
) }}

with order_payments as (
    select
        o.customer_id,
        date_trunc('month', o.order_date) as order_month,
        p.amount
    from {{ ref('stg_orders') }} o
    join {{ ref('stg_payments') }} p on o.order_id = p.order_id
    {% if is_incremental() %}
      where o.order_date > (select max(order_month) from {{ this }})
    {% endif %}
),

monthly_revenue as (
    select
        customer_id,
        order_month,
        sum(amount) as total_revenue
    from order_payments
    group by customer_id, order_month
),

ranked as (
    select
        customer_id,
        order_month,
        total_revenue,
        row_number() over (
            partition by order_month
            order by total_revenue desc
        ) as revenue_rank
    from monthly_revenue
)

select * from ranked
