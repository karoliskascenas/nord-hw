# Nord security homework assignment 2025-03-28

## The task:

Hey Karoli,

As we discussed over the phone, I’m sending you the technical assignment for the Analytics engineer position. Take your time to review it, and let me know how much time you think you’ll need to complete it. If you have any questions, feel free to reach out.

Analytics engineer assignment:

 

Suppose you are working on a new project which wants to analyze Stackoverflow data. Before doing any serious work, the team wants to take a look at the public dataset and do some initial analysis. Dataset can be found in BigQuery Public Dataset project. You are tasked with providing a table(-s) which would be used by the analysts frequently. This table(-s) should be optimized for query performance, and data should include ranges between 2010 and 2023.

Main use cases would be answering questions such as (although query parameters would vary in real-life situations):

    What are the top ten usernames with the highest accepted answer count between 2012-02-01 and 2012-02-29 and users are from ‘Stockholm, Sweden’? Accepted answer means that a posted question has a specific accepted answer ID. If a user doesn’t have a username, then return its user ID.

    How many posted questions have “PHP” inside a question post title and how many of them have been answered by a user, whose ID is 560648?

    Which comment had the most positive score on a post question that was created between 2013-10-01 and 2013-12-01?

Final table(-s) should be stored inside your own BigQuery dataset, following naming convention: ae_{first_name_letter}{full_last_name}

Final queries will be assessed by the BigQuery Job Information’s Bytes Processed section. This does not include Bytes Processed by the creation of table(-s).

What we expect from you:

    Final table(-s) inside your own BigQuery dataset;

    Queries that you prepared to answer the questions above.

## Env setup
If you do not care to set up your local environment you can skip ahead to [preamble](##apreamble) section.

You'll need the [uv](https://github.com/astral-sh/uv) package manager and Python 3.12.

Sync the project environment and create venv:
```bash
uv sync
```

Activate the virtual env:
```bash
source .venv/bin/activate
```

You can now use dbt cli. I assume you have authenticated via the oauth flow with gcloud cli:
```bash
gcloud auth application-default login
```
and have access to the bq project/dataset.

## Preamble
I've chosen to use dbt to make the models that answer your specific questions and to persist models that would have some value in analyzing things adhoc. This allows me to assign descriptions to tables/columns easily and manage dependencies between models as well as running some basic data tests.

Before we start I'd like to point out a couple if things of importance during the exercise:

1. The stackoverflow question posts end at `2022-09-25 05:56:32.863` even though the assignment asked to include posts through 2023.
2. Results of the top "solvers" from Stockholm differ if you apply some common sense on the filter.
```sql
lower(location) = "stockholm, sweden"
```
instead of
```sql
location = "Stockholm, Sweden"
```
that being said the format of the users' location column is inconsistent so I chose not to try and parse out city/state/country and hope that the user knows exactly what he wants.

3. My solutions try to strike a balance between answering the specific questions the user had and questions other users may have. You definitely can improve the "bytes processed" aspect for the specific questions further, but that would render the models very narrow in the use cases they can cover. At the end of the day modelling this in the real world would involve a lot more time spent understanding the use cases and collaboration with end users - this is just my take based on the information I had.

## Answers
### Tables for adhoc querying
I've chosen to persist data in `homework-data2020.ae_kkascenas.mrt_question_posts` and `homework-data2020.ae_kkascenas.stg_question_comments`. These two models will do the heavy lifting of answering the users' questions. Both of them are partitioned daily. It is probably a bit overkill especially considering bigquery has a 4000 partition modification limit which I've had to hack around by running the dbt models multiple times (see commented out `where` clause blocks). Initially I thought I'd try dbt's `microbatch` incremental strategy to fill the historic data, but since upstream data is not partitioned, in my opinion, this would be too crazy ~40GB (scanned with a single microbatch run) * 5112 (select timestamp_diff(date("2023-12-31"), date("2010-01-01"), day)) = ~200TB of data scanned. Partitioning the data is the main strategy I've used to reduce the bytes scanned when query'ing. I've also set the required partition filter attribute on both tables - this would help prevent running `select * from table;` queries by end users. Both the models in dbt are `incremental` but that's just to hack around the partition limits bigquery has. In the real world these models shouldn't be made incremental as some of the dimensions that are present (or joined) seem to be of SCD type 1 (latest value).

The `homework-data2020.ae_kkascenas.mrt_question_posts` has a grain of one post per row but it has answer posts joined to it so we can slice by user whose answer was marked as the accepted answer dimensions as well. The user dimensions are joined on three keys: `last_editor`, `owner`, `solver`. "solver" is a term I've coined for the user whose answer was accepted for a question post. The table only includes question posts that are joined with answer posts. There are actually 8 types of posts in source tables with prefix `posts_`, but I've chosen to ignore the rest as they did not seem particularly interesting and the questions the user had seemed to revolve around questions/answers. This is a somewhat wide table with a lot of columns and in the real world I would probably refrain from joining the user columns so haphazardly, but having them available in a table without needing to join anything is probably very comfortable for adhoc query'ing/exploring for novice users, may also put less strain on bq when query'ing via BI tools as well. Table is clustered by `id` - it's later used in a join with comments so this should help. In the real world I would probably look at the usage of the table and figure out what the best column(s) to cluster by are.

The `homework-data2020.ae_kkascenas.stg_question_comments` table is more or less the same as the source table. The only difference is that my model is partitioned and only comments that were posted on question posts are retained. I did this partly to reduce the size of the table for the question about the top comment and in part to stay consistent with the "only question posts" theme.



### Top usernames from Stockholm
My solution is stored in this view `homework-data2020.ae_kkascenas.mrt_swedish_top_solvers`. Not much to note here apart from the fact that we enjoy the benefits of having prejoined the "solver" user dimensions previously and partitioned the data very granularly.

### Top PHP posts/answers
Solution is stored in this view `homework-data2020.ae_kkascenas.mrt_php_questions`. Again, we enjoy the benefits of having prejoined the "solver" dimensions. One thing to note is even though the results of the query don't change when trying to query the `lower(title)` instead of `title` to determine which questions were about PHP, perhaps a better way to accomplish this would be to use the array of tags parsed in 
`homework-data2020.ae_kkascenas.stg_posts_questions.tags`?

### Most positive comment
Solution is stored in this view `homework-data2020.ae_kkascenas.mrt_most_positive_comment`. We enjoy the benefits of the granular partitioning of both tables that are read. We also don't have any comments that were posted on things other than question posts. One cheese way to reduce the scanned data would be to return the id of the comment instead of text - this would eliminate the need to scan the text column entirely, but I've chosen not to "cheat" with any interpretation of "Which comment" part of the question :).
