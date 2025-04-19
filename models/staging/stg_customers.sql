with source as (

    select * from {{ ref('raw_customers') }}

),

renamed as (

    select
        user_id as customer_id,
        first_name,
        last_name,
        email,
        registration_date

    from source

)

select * from renamed
