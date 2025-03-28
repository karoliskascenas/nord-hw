with source_data as (
    select
        id,
        title,
        body,
        accepted_answer_id,
        answer_count,
        comment_count,
        community_owned_date as community_owned_time,
        creation_date as creation_time,
        favorite_count,
        last_activity_date as last_activity_time,
        last_edit_date as last_edit_time,
        last_editor_user_id,
        owner_user_id,
        parent_id,
        post_type_id,
        score,
        split(tags, '|') as tags,
        view_count
    from {{ source('bq_public_data', 'posts_questions') }}
)

select *
from source_data
