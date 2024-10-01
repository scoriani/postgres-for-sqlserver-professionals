pg_dump -h scorianipg16.postgres.database.azure.com  -Fc nyc > nyc.dump

ls -la

# restore on a different database
create database nyc2;
create extension hypopg;
set pgaudit.log = none;
create extension postgis;

pg_restore -h scorianipg16.postgres.database.azure.com -d nyc2 nyc.dump