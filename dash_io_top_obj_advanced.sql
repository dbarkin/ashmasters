set lin 300
/*


Notice the 3rd row final  column, it's UNDO. 1/2 of the query data is coming from UNDO
Seeing sequential read waits on a full table scan that shoul normally
be scattered read waits is a good flag that it might be undo coming from
an uncommited transaction.

This query can help identify that

AAS SQL_ID        PCT OBJ          SUB_OBJ OTYPE      EVENT      F# TABLESPAC CONTENTS
---- ----------------- ----------- ------- ---------- ---------- -- --------- ---------
.00 f9u2k84v884y7  33 CUSTOMERS    SYS_P27 TABLE PART  sequentia  1 SYSTEM    PERMANENT     
                   33 ORDER_PK             INDEX       sequentia  4 USERS     PERMANENT
                   33                                  sequentia  2 UNDOTBS1  UNDO
.01 0tvtamt770hqz 100 TOTO1                TABLE       scattered  7 NO_ASSM   PERMANENT 
.06 75621g9y3xmvd   3 CUSTOMERS    SYS_P36 TABLE PART  sequentia  4 USERS     PERMANENT
                    3 CUSTOMERS    SYS_P25 TABLE PART  sequentia  4 USERS     PERMANENT
                    3 CUSTOMERS    SYS_P22 TABLE PART  sequentia  4 USERS     PERMANENT
                    3 CUSTOMERS    SYS_P29 TABLE PART  sequentia  4 USERS     PERMANENT
                    3 CUSTOMERS    SYS_P21 TABLE PART  sequentia  4 USERS     PERMANENT

 Version When        Who            What?
 ------- ----------- -------------- ----------------------------------------------------------------------------------------------
 1.0     Jan 19 2013 K. Hailey      First version
 1.0.1   Feb 26 2013 M. Krijgsman   Bug fix: removed tcnt from order by ;)
 1.0.2   Dec 28 2016 D. Barkin   Bug fix: removed tcnt from order by ;)

*/


col tcnt for 9999
col sql_id for a14
col cnt for 999
col obj for a20
col sub_obj for a10
col otype for a15
col event for a30
col file# for 9999
col tsname for a15

col f_minutes new_value v_minutes
select &minutes f_minutes from dual;

select
       to_date(io.tday||' '||io.tmod*&v_secs,'YYMMDD SSSSS') start_time,
       sum(cnt) over ( partition by io.sql_id order by sql_id ) tcnt,
       cnt,
       io.sql_id,       
       io.CURRENT_OBJ#,
       o.object_name obj,
       o.subobject_name sub_obj,
       o.object_type otype,
       substr(io.event,1,50) event,
       df.tsname
from 
(
  select
         to_char(sample_time,'YYMMDD')                        tday
       , trunc(to_char(sample_time,'SSSSS')/&v_secs)          tmod
       , dbid
       , sql_id
	   , event
       , count(*) cnt
       , count(*) / (&v_minutes*60) aas
       , CURRENT_OBJ#
       , current_file# 
       , ash.p1
   from 
   --v$active_session_history ash
        dba_hist_active_sess_history ash
   where
    ( event like 'db file s%' or event like 'direct%' or
      event like 'gc %'       or event like 'enq:%')  and 
   dbid=1612081131
   group by
         to_char(sample_time,'YYMMDD')                   
       , trunc(to_char(sample_time,'SSSSS')/&v_secs)   
       ,dbid, 
       CURRENT_OBJ#,
       current_file#, 
       event,
       ash.p1,
       sql_id
)   io
  , DBA_HIST_SEG_STAT_OBJ o
  , DBA_HIST_DATAFILE df
where
   o.obj# (+)= io.CURRENT_OBJ# and o.dbid (+)=io.dbid
   and
   df.dbid=io.dbid and df.file#=io.current_file#   
Order by to_date(io.tday||' '||io.tmod*&v_secs,'YYMMDD SSSSS'), sql_id, cnt
/

clear breaks


