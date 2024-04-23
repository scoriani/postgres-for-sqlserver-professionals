# show hammerdb for SQL Server

# spin up a new hammerdb container and run the tprocc test
docker run --network=bridge -it --name hammerdb hammerdbpg bash

# run hammerdb tprocc test
./scripts/python/postgres/tprocc/pg_tprocc_py.sh