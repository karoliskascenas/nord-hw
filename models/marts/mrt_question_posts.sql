{{
    config(
        materialized='incremental',
        incremental_strategy='insert_overwrite',
        partition_by={
          "field": "creation_time",
          "data_type": "timestamp",
          "granularity": "day"
        },
        cluster_by=["id"],
        full_refresh=false,
        require_partition_filter=true
    )
}}

{% set increment_start = 'date_sub(current_date(), interval 1 day)' %}

with question_posts as (
    select
        *
    from {{ ref("stg_posts_questions") }}
    -- where date(creation_time) between "2010-01-01" and "2020-12-01"
    where date(creation_time) between "{{ var('posts_start_date') }}" and "{{ var('posts_end_date') }}"
    {% if is_incremental() %}
        -- and date(creation_time) between "2020-12-01" and "{{ var('posts_end_date') }}"
        and date(creation_time) between {{ increment_start }} and current_date()
    {% endif %}
),

answer_posts as (
    select
        id,
        owner_user_id
    from {{ ref("stg_posts_answers") }}
),

{% set user_prefixes = [
    "last_editor",
    "owner",
    "solver"
] %}

{% set user_cols = [
    "display_name",
    "about_me",
    "creation_time",
    "last_access_time",
    "location",
    "reputation",
    "up_votes",
    "down_votes",
    "views",
    "profile_image_url",
    "website_url"
] %}

user_dims as (
    select
        *
    from {{ ref("stg_users") }}
),

w_accepted_answer_user_id as (
    select
        question_posts.*,
        answer_posts.owner_user_id as solver_user_id
    from question_posts
    left join answer_posts on question_posts.accepted_answer_id = answer_posts.id
),

w_user_dims as (
    select
        w_accepted_answer_user_id.*,
        {% for prefix in user_prefixes %}
            {% for col in user_cols -%}
                {{ prefix }}_user_dims.{{ col }} as {{ prefix }}_{{ col }},
            {% endfor -%}
        {% endfor -%}
    from w_accepted_answer_user_id
    {% for prefix in user_prefixes -%}
    left join user_dims as {{ prefix }}_user_dims on w_accepted_answer_user_id.{{ prefix }}_user_id = {{ prefix }}_user_dims.id
    {% endfor %}
)

select *
from w_user_dims
