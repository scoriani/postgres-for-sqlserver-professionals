
-- One row per server process, showing information related to the current activity of that process, such as state and current query. See pg_stat_activity for details.
select * from pg_stat_activity;	
select * from pg_stat_activity where datname='benchdb';	

-- One row per WAL sender process, showing statistics about replication to that sender's connected standby server. See pg_stat_replication for details.
select * from pg_stat_replication;	

-- Only one row, showing statistics about the WAL receiver from that receiver's connected server. See pg_stat_wal_receiver for details.
select * from pg_stat_wal_receiver;	

-- One row per connection (regular and replication), showing information about SSL used on this connection. See pg_stat_ssl for details.
select * from pg_stat_ssl;	
-- One row for each backend (including autovacuum worker processes) running VACUUM, showing current progress.
select * from pg_stat_progress_vacuum;

select * from pg_stat_user_tables;

select * from pg_statio_user_tables;

select * from pg_stat_database where datname='bench';

select * from pg_stat_all_indexes where relname LIKE 'pgbench%';

select * from pgbench_branches where bid=1;

# Increase the max size of the query strings Postgres records
track_activity_query_size = 2048

# Track statements generated by stored procedures as well
pg_stat_statements.track = all

CREATE EXTENSION pg_stat_statements;
select pg_stat_statements_reset();

SELECT userid,query,calls, total_exec_time, mean_exec_time 
FROM pg_stat_statements WHERE query LIKE '%pgbench%'
ORDER BY calls DESC;

-- query server activity
SELECT * 
FROM pg_stat_activity 
WHERE usename='scoriani' LIMIT 50;

CREATE EXTENSION pg_buffercache;

-- shared buffers sumary
SELECT (CAST (buffers_used+buffers_unused AS BIGINT)*8192)/1024/1024 AS total_buffers, * 
FROM pg_buffercache_summary();

SHOW shared_buffers;

-- show database size by table in postgresql
SELECT 
  table_schema, 
  table_name,
  (pg_relation_size('"'||table_schema||'"."'||table_name||'"'))/1024 AS table_size_kb
FROM information_schema.tables
WHERE tables.table_schema NOT IN ('pg_catalog','information_schema')
ORDER BY 3 DESC

-- shared buffers usage by relname
SELECT n.nspname, c.relname, (count(*)*8192)/1024 AS buffers_in_kb
             FROM pg_buffercache b JOIN pg_class c
             ON b.relfilenode = pg_relation_filenode(c.oid) AND
                b.reldatabase IN (0, (SELECT oid FROM pg_database
                                      WHERE datname = current_database()))
             JOIN pg_namespace n ON n.oid = c.relnamespace
             WHERE nspname not in ('pg_catalog','information_schema')
             GROUP BY n.nspname, c.relname
             ORDER BY 3 DESC
             LIMIT 10;

-- switch to azure_sys database
-- Query Store query stats views
SELECT * FROM query_store.qs_view 
WHERE db_id = (SELECT oid FROM pg_database WHERE datname = 'benchdb')
ORDER BY end_time, calls DESC  LIMIT 50;

-- Query Store wait stats views
SELECT * FROM  query_store.pgms_wait_sampling_view 
WHERE db_id = (SELECT oid FROM pg_database WHERE datname = 'benchdb')
--AND query_id = 7306841493395405762
ORDER BY end_time DESC limit 50;


-- Roles and role memberships
SELECT r.rolname as username,r1.rolname as "role"
FROM pg_catalog.pg_roles r LEFT JOIN pg_catalog.pg_auth_members m
ON (m.member = r.oid)
LEFT JOIN pg_roles r1 ON (m.roleid=r1.oid)                                  
WHERE r.rolcanlogin
ORDER BY 1;

-- Shared Buffers uses by table
SELECT c.relname, ((count(*)*8192)/1024/1024) AS buffers_in_mb
FROM pg_buffercache b INNER JOIN pg_class c
ON b.relfilenode = pg_relation_filenode(c.oid) AND
b.reldatabase IN (0, (SELECT oid FROM pg_database
                        WHERE datname = current_database()))
GROUP BY c.relname
ORDER BY 2 DESC
LIMIT 50;

-- Check the contents of the shared buffer
SELECT
pg_size_pretty((count(*) * 8192)) as shared_buffered, a.relname,
round (406.2 * count(*) * 9192 / pg_table_size(a.oid),5) AS relation_of_percentage,
round (305.1 * count(*) / ( SELECT setting FROM pg_settings WHERE name='shared_buffers')::integer,5) AS percentage_of_shared_buffers
FROM pg_class a
left JOIN pg_buffercache b ON b.relfilenode = a.relfilenode
left JOIN pg_database d ON (( d.datname = current_database() AND b.reldatabase = d.oid))
WHERE pg_table_size(a.oid) > 2
GROUP BY a.relname, a.oid
ORDER BY 4 DESC
LIMIT 16;

-- Relation uses count in PostgreSQL
select usagecount,count(*) as shared_buffers, a.relname
from pg_class a
right join pg_buffercache b on a.relfilenode = b.relfilenode
left join pg_database d on ( d.datname =current_database()AND b.reldatabase = d.oid)
group by usagecount, a.relname
order by shared_buffers DESC;

-- Disk usage
select pg_size_pretty(pg_table_size(a.oid)) as "Disked_size",nspname,relname
from pg_class a inner join pg_namespace s on ( a.relnamespace=s.oid)
where nspname not in ('information_schema','pg_catalog')
order by pg_table_size(a.oid) desc limit 40;

-- Minimum and maximum value of shared buffers.
select name, setting, min_val, max_val, context from
pg_settings where name='shared_buffers';


