# Preparing pgbench tables with 50 scale factor (50 branches, 500 tellers, 5000000 accounts)
pgbench -i -s 50 -U parallels benchdb

# Running pgbench with 10 clients and 10 threads and 100000 transactions
pgbench -n -P 1 -U parallels -c 10 -j 10 -t 100000 benchdb