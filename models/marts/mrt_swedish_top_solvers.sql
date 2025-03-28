{{ config(materialized='view') }}

select
    coalesce(solver_display_name, cast(solver_user_id as string)) as solver,
    count(*) as accepted_answer_count
from {{ ref("mrt_question_posts") }}
where date(creation_time) between "{{ var('swedish_solves_start_date') }}" and "{{ var('swedish_solves_end_date') }}"
and solver_user_id is not null
and solver_location = "Stockholm, Sweden"
group by 1
order by 2 desc
limit {{ var("n_swedish_top_solvers") }}
