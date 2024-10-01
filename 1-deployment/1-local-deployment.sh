
######### install postgres locally (on Ubuntu) #########

# Create the file repository configuration:
sudo sh -c 'echo "deb https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'

# Import the repository signing key:
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

# Update the package lists:
sudo apt-get update

# Install the latest version of PostgreSQL.
# If you want a specific version, use 'postgresql-12' or similar instead of 'postgresql':
sudo apt-get -y install postgresql-16

# switch to postgres user
sudo su postgres

# connect to your postgres instance
psql 

# secure access!

# set up a password for the postgres user :)
\password postgres
# or
ALTER USER postgres WITH PASSWORD '<password>';

# create a new user using the createuser utility in /usr/lib/postgresql/16/bin/
createuser parallels

psql -c "ALTER USER parallels WITH SUPERUSER;"

# edit /etc/postgresql/16/main/pg_hba.conf to allow password authentication
# Database administrative login by Unix domain socket
local   all             postgres                                md5

# restart the service
sudo service postgresql restart

# edit /etc/postgresql/16/main/postgresql.conf to allow external connections

#------------------------------------------------------------------------------
# CONNECTIONS AND AUTHENTICATION
#------------------------------------------------------------------------------

# - Connection Settings -

listen_addresses = '*'                  # what IP address(es) to listen on;
                                        # comma-separated list of addresses;
                                        # defaults to 'localhost'; use '*' for all
                                        # (change requires restart)
port = 5432                             # (change requires restart)
