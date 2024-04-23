# OS processes
ps -aux | grep postgres

# system usage
top
htop

# postgres specific system monitoring
sudo apt-get install pgtop

pg_top -h localhost -p 5432 -d severalnines -U postgres
pg_top -r -h 192.168.1.20 -p 5432 -d severalnines -U postgres

# IO monitoring
sudo apt-get install sysstat
sudo apt-get install iotop

iostat -x -d 2 vda

sudo iotop -oP



