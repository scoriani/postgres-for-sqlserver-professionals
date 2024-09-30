mkdir source  
  
cd source  
git clone https://github.com/postgres/postgres.git  
git branch --list --remotes  
git checkout REL_16_STABLE

sudo apt-get update  
sudo apt-get install --yes build-essential libreadline-dev zlib1g-dev flex bison libxml2-dev libxslt-dev libssl-dev libxml2-utils xsltproc ccache pkg-config gdb

cd postgres  
./configure --prefix="$HOME/pgsql/16/" CFLAGS="-O0 -DTRACE_SORT" --enable-debug --enable-cassert --enable-depend  
make -j 4

make install
mkdir -p ~/pgsql/16/data

vi ~/.profile

PATH="$HOME/pgsql/16/bin:$PATH"
source ~/.profile

initdb -D ~/pgsql/16/data

pg_ctl -D ~/pgsql/16/data -l logfile start

createdb test

psql test

vi ~/.psqlsrc

\set PROMPT1 '%M:%[%033[1;31m%]%p%[%033[0m%] %n@%/%R%#%x'
\pset null '[null]'
\set COMP_KEYWORD_CASE upper
\timing
\set HISTSIZE 2000
\x auto
\set VERBOSITY verbose
\set QUIET 0
\echo 'Welcome to Tijuana! \n'
\echo 'Type :version to see the PostgreSQL version. \n'
\echo 'Type :extensions to see the available extensions. \n'
\echo 'Type \\q to exit. \n'
\set version 'SELECT version();'
\set extensions 'select * from pg_available_extensions;'

code-insiders .


launch.json

{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Debug running Postgres",
            "type": "cppdbg",
            "request": "attach",
            "program": "/home/ialonso/pgsql/16/bin/postgres",
            "processId": "${command:pickProcess}",
            "MIMode": "gdb",
            "miDebuggerPath": "/usr/bin/gdb"
        }
    ]
}


cd ~/source
git clone https://github.com/pgaudit/pgaudit.git
cd pgaudit
git branch --list --remotes
git checkout REL_16_STABLE
make install USE_PGXS=1 PG_CONFIG=$HOME/pgsql/16/bin/pg_config
vi ~/pgsql/16/data/postgresql.conf

pg_ctl restart -D $HOME/pgsql/16/data

CREATE EXTENSION pgaudit;SET pgaudit.log = 'role';

postgres/src/backend/utils/misc/guc.c!AlterSystemSetConfigFile

ALTER SYSTEM SET wal_level = replica;