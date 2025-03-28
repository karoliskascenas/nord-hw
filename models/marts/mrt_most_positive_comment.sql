{{ config(materialized='view') }}

with question_posts as (
    select
        id as post_id
    from {{ ref("mrt_question_posts") }}
    where date(creation_time) between "{{ var('positive_comments_posts_start_date') }}" and "{{ var('positive_comments_posts_end_date') }}"
),

comments as (
    select
        post_id,
        score,
        text
    from {{ ref("stg_question_comments") }}
    -- assuming comments cannot "time travel"
    where date(creation_time) >= "{{ var('positive_comments_posts_start_date') }}"
)

select
    text as most_positive_comment,
    score
from comments
inner join question_posts on comments.post_id = question_posts.post_id
order by score desc
limit 1
