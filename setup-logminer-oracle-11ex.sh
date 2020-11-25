#!/bin/sh

# Set archive log mode and enable GG replication
ORACLE_SID=XE
export ORACLE_SID
sqlplus /nolog <<- EOF
	CONNECT sys/adminPassword1 AS SYSDBA
	alter system set db_recovery_file_dest_size = 10G;
	alter system set db_recovery_file_dest = '/u01/app/oracle/oradata/recovery_area' scope=spfile;
	shutdown immediate
	startup mount
	alter database archivelog;
	alter database open;
        -- Should show "Database log mode: Archive Mode"
	archive log list
	exit;
EOF

# Enable Log Miner
sqlplus sys/adminPassword1@//localhost:1521/XE as sysdba <<- EOF
  ALTER DATABASE ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS;
  ALTER PROFILE DEFAULT LIMIT FAILED_LOGIN_ATTEMPTS UNLIMITED;
  exit;
EOF

# Create Log Miner Tablespace and User
sqlplus sys/adminPassword1@//localhost:1521/XE as sysdba <<- EOF
  CREATE TABLESPACE LOGMINER_TBS DATAFILE '/u01/app/oracle/oradata/XE/logminer_tbs.dbf' SIZE 25M REUSE AUTOEXTEND ON MAXSIZE UNLIMITED;
  exit;
EOF

sqlplus sys/adminPassword1@//localhost:1521/XE as sysdba <<- EOF
    create role c##dbzuser_privs;
    grant FLASHBACK ANY TABLE TO c##dbzuser_privs;
    grant create session, create table, execute_catalog_role, select_catalog_role, select any table, select any transaction, select any dictionary, lock any table to c##dbzuser_privs;
    grant select on V\_$DATABASE to c##dbzuser_privs;
    grant select on SYSTEM.LOGMNR_COL$ to c##dbzuser_privs;
    grant select on SYSTEM.LOGMNR_OBJ$ to c##dbzuser_privs;
    grant select on SYSTEM.LOGMNR_USER$ to c##dbzuser_privs;
    grant select on SYSTEM.LOGMNR_UID$ to c##dbzuser_privs;
    grant execute on SYS.DBMS_LOGMNR to c##dbzuser_privs;
    grant execute on SYS.DBMS_LOGMNR_D to c##dbzuser_privs;
    grant execute on SYS.DBMS_LOGMNR_LOGREP_DICT to c##dbzuser_privs;
    grant execute on SYS.DBMS_LOGMNR_SESSION to c##dbzuser_privs;
    create user c##dbzuser identified by dbz default tablespace LOGMINER_TBS;
    grant c##dbzuser_privs to c##dbzuser;
    alter user c##dbzuser quota unlimited on LOGMINER_TBS;
    exit;
EOF