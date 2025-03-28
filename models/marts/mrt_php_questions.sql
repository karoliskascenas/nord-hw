{{ config(materialized='view') }}

select
    count(*) as php_questions,
    count(case when solver_user_id = {{ var("php_user") }} then 1 else null end) as php_questions_answered_by_user_{{ var("php_user") }},
from `ae_kkascenas.mrt_question_posts`
where contains_substr(title, "PHP") and creation_time is not null
