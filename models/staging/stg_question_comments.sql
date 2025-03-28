{{
    config(
        materialized='incremental',
        incremental_strategy='insert_overwrite',
        partition_by={
          "field": "creation_time",
          "data_type": "timestamp",
          "granularity": "day"
        },
        cluster_by=['post_id'],
        full_refresh=false,
        require_partition_filter=true
    )
}}

{% set increment_start = 'date_sub(current_date(), interval 1 day)' %}

with source_data as (
    select
        id,
        text,
        creation_date as creation_time,
        post_id,
        user_id,
        user_display_name,
        score
    from {{ source('bq_public_data', 'comments') }}
    -- where date(creation_date) <= "2018-01-01"
    {% if is_incremental() %}
        -- where date(creation_date) > "2018-01-01"
        where date(creation_date) between {{ increment_start }} and current_date()
    {% endif %}
),

question_post_ids as (
    select id from {{ ref("stg_posts_questions") }}
)

select
    source_data.*
from source_data
inner join question_post_ids on source_data.post_id = question_post_ids.id
