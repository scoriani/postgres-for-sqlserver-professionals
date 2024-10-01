# OS processes
ps -aux | grep postgres

# system usage
top
htop

# Great tool for real-time monitoring of disk I/O
sudo apt-get install iotop

sudo iotop -oP

# IO monitoring
sudo apt-get install sysstat
iostat -x -d 2 vda

# Shared memory utilization across Postgres processes
ps -u postgres o pid= | \
sed 's# *\(.*\)#/proc/\1/smaps#' | \
xargs sudo grep ^Pss: | \
awk '{A+=$2} END{print A" Kb"}'

# postgres specific system monitoring
sudo apt-get install pgtop

pg_top -d benchdb -U postgres
pg_top -r -h 192.168.1.20 -p 5432 -d mydb -U postgres

