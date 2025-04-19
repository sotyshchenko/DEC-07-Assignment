with source as (

    select * from {{ source('raw', 'raw_stock') }}

),

renamed as (

    select
        product_id,
        number_available_in_stock as stock_quantity

    from source

)

select * from renamed
