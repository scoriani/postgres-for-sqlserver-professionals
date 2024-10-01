-- pg_tgrm which allows index search for %TXT% queries and REGEXP querie
-- Dataset from Kaggle: https://www.kaggle.com/datasets/wilmerarltstrmberg/recipe-dataset-over-2m

select * from recipes limit 10;

-- Get Recipe count
select count(*) from recipes;
  count
---------
 2231142


-- postgres=# \dt+
--                                      List of relations
--  Schema |  Name   | Type  |  Owner   | Persistence | Access method |  Size   | Description
-- --------+---------+-------+----------+-------------+---------------+---------+-------------
--  public | recipes | table | postgres | permanent   | heap          | 2220 MB |
-- (1 row)


-- Do an ILIKE search for strawberry
postgres=# explain analyze select title from recipes where title ILIKE '%strawberry%';
                                                           QUERY PLAN
--------------------------------------------------------------------------------------------------------------------------------
 Gather  (cost=1000.00..289024.35 rows=24012 width=24) (actual time=0.580..1279.146 rows=25713 loops=1)
   Workers Planned: 2
   Workers Launched: 2
   ->  Parallel Seq Scan on recipes  (cost=0.00..285623.15 rows=10005 width=24) (actual time=0.199..1261.453 rows=8571 loops=3)
         Filter: (title ~~* '%strawberry%'::text)
         Rows Removed by Filter: 735143
 Planning Time: 0.696 ms
 Execution Time: 1280.795 ms
(8 rows)

-- Do a case-insensitive regex search for recipes that have strawberry or raspberry in the name.
postgres=# explain analyze select title from recipes where title ~* '(strawberry|raspberry)';
                                                           QUERY PLAN
---------------------------------------------------------------------------------------------------------------------------------
 Gather  (cost=1000.00..291157.45 rows=45343 width=24) (actual time=0.204..1638.527 rows=35649 loops=1)
   Workers Planned: 2
   Workers Launched: 2
   ->  Parallel Seq Scan on recipes  (cost=0.00..285623.15 rows=18893 width=24) (actual time=0.155..1632.294 rows=11883 loops=3)
         Filter: (title ~* '(strawberry|raspberry)'::text)
         Rows Removed by Filter: 731831
 Planning Time: 0.412 ms
 Execution Time: 1640.475 ms
(8 rows)


-- Show extensions
demodb=> show azure.extensions;
                           azure.extensions
-----------------------------------------------------------------------
 AZURE_STORAGE,AZURE_AI,PG_TRGM,PG_STAT_STATEMENTS,POSTGRES_FDW,VECTOR
(1 row)

-- Create extension pg_trgm
postgres=# create extension pg_trgm ;
CREATE EXTENSION

DROP INDEX trgm_idx;
-- Now let's add indexes! -- took about 15 seconds
CREATE INDEX trgm_idx ON recipes USING GIN (title gin_trgm_ops);


-- The index is not that big!

postgres=# \di+
                                          List of relations
 Schema |   Name   | Type  |  Owner   |  Table  | Persistence | Access method |  Size  | Description
--------+----------+-------+----------+---------+-------------+---------------+--------+-------------
 public | trgm_idx | index | postgres | recipes | permanent   | gin           | 137 MB |
(1 row)

-- but see how it speeds up BOTH queries:

postgres=# explain analyze select title from recipes where title ILIKE '%strawberry%';
                                                         QUERY PLAN
-----------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on recipes  (cost=270.78..72536.07 rows=23990 width=24) (actual time=15.629..195.838 rows=25713 loops=1)
   Recheck Cond: (title ~~* '%strawberry%'::text)
   Rows Removed by Index Recheck: 19
   Heap Blocks: exact=24012
   ->  Bitmap Index Scan on trgm_idx  (cost=0.00..264.78 rows=23990 width=0) (actual time=11.909..11.910 rows=25732 loops=1)
         Index Cond: (title ~~* '%strawberry%'::text)
 Planning Time: 0.556 ms
 Execution Time: 197.929 ms
(8 rows)


-- Down from 1280.795 ms to 197.929 ms


postgres=# explain analyze select title from recipes where title ~* '(strawberry|raspberry)';
                                                         QUERY PLAN
-----------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on recipes  (cost=463.33..119346.24 rows=45302 width=24) (actual time=39.293..278.925 rows=35649 loops=1)
   Recheck Cond: (title ~* '(strawberry|raspberry)'::text)
   Rows Removed by Index Recheck: 17
   Heap Blocks: exact=32932
   ->  Bitmap Index Scan on trgm_idx  (cost=0.00..452.00 rows=45302 width=0) (actual time=33.697..33.697 rows=35666 loops=1)
         Index Cond: (title ~* '(strawberry|raspberry)'::text)
 Planning Time: 0.588 ms
 Execution Time: 281.674 ms
(8 rows)

-- Down from 1640.475 ms to 281.674 ms.

create database azurerestaurant;

-- But wait, PostgreSQL is also supposed to be good with JSON right? Let's convert our whole table into json per row!
-- It's easy to convert a whole row into json:
 select row_to_json(recipes.*) from recipes limit 1;

-- but we will make sure that the subfields are casted to jsonb also (ingredients and directions):

select json_build_object('title',title, 'ingredients', ingredients::jsonb, 'directions', directions::jsonb, 'link', link, 'source', source, 'ner', ner, 'site', site) from recipes limit 1;

-- So let's create a table based on this:

create table recipes_json(data jsonb);

-- and fill it with data!

postgres=# insert into recipes_json(data)
 SELECT json_build_object('title',title, 'ingredients'
                        , regexp_replace(ingredients, '\\u0000','','g')::jsonb
                        , 'directions', regexp_replace(directions, '\\u0000', '','g')::jsonb
                        , 'link', link
                        , 'source', source
                        , 'ner', ner
                        , 'site', site)
from recipes;

INSERT 0 2231142

-- NOTE: we do the regexp_replace to get rid of some nasty escape sequences from the source dataset

-- But how do I extract the title?

postgres=# select data->'title'  as title from recipes_json limit 1;
       ?column?
-----------------------
 "No-Bake Nut Cookies"select 
(1 row)

-- and we can even query the ingredients itself like an array!

postgres=# select data->'ingredients' as ingredients from recipes_json limit 1;
                                          ?column?
--------------------------------------------------------------------------------------------
 ["2 lbs peeled cantaloupes", "1 lb mini marshmallows", "1 (16 ounce) container Cool Whip"]
(1 row)

postgres=# select (data->'ingredients')[1] from recipes_json limit 1;
         ?column?
--------------------------
 "1 lb mini marshmallows"
(1 row)

-- Easy! Can I search it? Are there recipes with cake as an ingredient?

postgres=# explain analyze select data->'ingredients' from recipes_json where data -> 'ingredients' ? 'cake';
                                                            QUERY PLAN
----------------------------------------------------------------------------------------------------------------------------------
 Gather  (cost=1000.00..307508.71 rows=22425 width=32) (actual time=0.243..1042.001 rows=178 loops=1)
   Workers Planned: 2
   Workers Launched: 2
   ->  Parallel Seq Scan on recipes_json  (cost=0.00..304266.21 rows=9344 width=32) (actual time=3.088..1037.146 rows=59 loops=3)
         Filter: ((data -> 'ingredients'::text) ? 'cake'::text)
         Rows Removed by Filter: 743655
 Planning Time: 0.068 ms
 Execution Time: 1042.123 ms
(8 rows)


-- We can, but it feels slow. Look how many rows were removed by filter!

-- Can we index this somehow?
CREATE INDEX json_idx ON recipes_json USING GIN (data jsonb_path_ops);

postgres=# CREATE INDEX json_idx ON recipes_json USING GIN (data jsonb_path_ops);
CREATE INDEX


-- First JSON is contained in second JSON.

postgres=# explain analyze select data->'ingredients' from recipes_json where data @> '{"ingredients" : ["cake"]}';
                                                      QUERY PLAN
----------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on recipes_json  (cost=31.05..907.85 rows=223 width=32) (actual time=0.057..1.124 rows=178 loops=1)
   Recheck Cond: (data @> '{"ingredients": ["cake"]}'::jsonb)
   Heap Blocks: exact=178
   ->  Bitmap Index Scan on json_idx  (cost=0.00..30.99 rows=223 width=0) (actual time=0.030..0.030 rows=178 loops=1)
         Index Cond: (data @> '{"ingredients": ["cake"]}'::jsonb)
 Planning Time: 0.313 ms
 Execution Time: 1.152 ms
(7 rows)

-- We changed the query to the containment operator to see if there are rows containing cake. This is extremely fast now down form 1042.123 ms to 1.152 ms!

-- The problem however is, that the index itself is now half the size of the data itself. It is that big, because it stores a copy of the values - this is perfect flexibility and we can query any key we want, but we can be smarter about that.

postgres=# \di+
                                            List of relations
 Schema |   Name   | Type  |  Owner   |    Table     | Persistence | Access method |  Size  | Description
--------+----------+-------+----------+--------------+-------------+---------------+--------+-------------
 public | json_idx | index | postgres | recipes_json | permanent   | gin           | 976 MB |
 public | trgm_idx | index | postgres | recipes      | permanent   | gin           | 137 MB |
(2 rows)

-- Instead of indexing every field, let's index just the ingredients.

CREATE INDEX ingredients_json_idx ON recipes_json USING GIN ((data -> 'ingredients'));

postgres=# \di+
                                                  List of relations
 Schema |         Name         | Type  |  Owner   |    Table     | Persistence | Access method |  Size  | Description
--------+----------------------+-------+----------+--------------+-------------+---------------+--------+-------------
 public | ingredients_json_idx | index | postgres | recipes_json | permanent   | gin           | 495 MB |
 public | json_idx             | index | postgres | recipes_json | permanent   | gin           | 976 MB |
 public | trgm_idx             | index | postgres | recipes      | permanent   | gin           | 137 MB |
(3 rows)


-- This is half the size now.

postgres=# explain analyze select data->'ingredients' from recipes_json where data -> 'ingredients' ? 'cake';
                                                             QUERY PLAN
-------------------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on recipes_json  (cost=175.75..68971.97 rows=22311 width=32) (actual time=0.108..1.402 rows=178 loops=1)
   Recheck Cond: ((data -> 'ingredients'::text) ? 'cake'::text)
   Heap Blocks: exact=178
   ->  Bitmap Index Scan on ingredients_json_idx  (cost=0.00..170.17 rows=22311 width=0) (actual time=0.053..0.053 rows=178 loops=1)
         Index Cond: ((data -> 'ingredients'::text) ? 'cake'::text)
 Planning Time: 0.546 ms
 Execution Time: 1.464 ms
(7 rows)

-- and as fast as the previous method.


-- Storing the same data as JSONB vs a regular table doesn't add much overhead itself.

postgres=# \dt+
                                       List of relations
 Schema |     Name     | Type  |  Owner   | Persistence | Access method |  Size   | Description
--------+--------------+-------+----------+-------------+---------------+---------+-------------
 public | recipes      | table | postgres | permanent   | heap          | 2220 MB |
 public | recipes_json | table | postgres | permanent   | heap          | 2343 MB |
(2 rows)

-- Have fun!