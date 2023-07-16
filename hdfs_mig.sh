#!/bin/bash
# profile_distcp 입력 필요

WORKDIR=`readlink -f $0 | xargs  dirname`
source ${WORKDIR}/profile_distcp

DBNAME=$1
TIMESTAMP=$(date +%m%d)
SQLFILE=${WORKDIR}/msck_sql/${DBNAME}_msck_tables_${TIMESTAMP}.sql


# distcp command 
# queue option : -Dmapred.job.queue.name=root.users.{queuename}
function distcp_DB(){
    HADDOP_USER_NAME=hdfs hadoop distcp  \
    -prbugcxt -bandwidth 100 -m 20 -update -delete -direct -strategy dynamic \
    hdfs://${hdfssource}/user/hive/warehouse/${DBNAME}.db \
    hdfs://${hdfsdestination}/user/hive/warehouse/${DBNAME}.db
    result=$?
    [ $result -eq 0 ] && echo -n "result:SUCESS " || echo -n "result:ERROR "
}


function msck_drop_partition(){
    # make SQLFILE for msck repair table
    mysql -u ${mysqluser} -p ${mysqlpasswd} metastore -N -e \
    "select concat('msck repair table ', DBS.name, '.', TBLS.tbl_name,' drop partitions;') \
    FROM TBLS INNER JOIN DBS ON TBLS.DB_ID=DBS.DB_ID WHERE DBS.name='${DBNAME}'" \
    > ${SQLFILE}

    # beeline execute
    # ldapaccount
    beeline -n ${hiveuser} -p ${hivepasswd} -f ${SQLFILE}
}


distcp_DB
msck_drop_partition