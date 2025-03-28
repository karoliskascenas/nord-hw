with source_data as (
    select
        id,
        display_name,
        about_me,
        -- age, has no values
        creation_date as creation_time,
        last_access_date as last_access_time,
        location,
        reputation,
        up_votes,
        down_votes,
        views,
        profile_image_url,
        website_url
    from {{ source('bq_public_data', 'users') }}
)

select *
from source_data
