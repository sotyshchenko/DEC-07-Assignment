with source as (

    select * from {{ ref('raw_products') }}

),

renamed as (

    select
        id as product_id,
        title as book_name,
        author,
        category as product_category,
        price as product_price

    from source

)

select * from renamed
