/*
   ASH graph from dba_hist_active_sess_history no v$active_session_history
   Credits: ash_gcwait_to_obj.sql Original from OraInternals Riyaj Shamsudeen
   input DBID
   
   
   Usage: ash_gcwait_to_obj_by_dbid.sql DBID StartTimestamp FinishTimestamp InstanceNumber
   
   
   @/dbabin/dbatools/diagscript/khailey/ashmasters-master/ash_gcwait_to_obj_by_dbid.sql 1612081131 '2016-12-08 03:30:00' '2016-12-08 07:00:00' 1
   @/dbabin/dbatools/diagscript/khailey/ashmasters-master/ash_gcwait_to_obj_by_dbid.sql 1612081131 '2016-12-08 03:30:00' '2016-12-08 07:00:00' 2
   

*/

set verify off
set lin 300
set pagesize 500
Def v_secs=10 --  bucket size

set lines 160 pages 100
undef event 
col object_name format A32
col object_type format A20
col event format A30
col owner format A20
col cnt format 999999999
set echo on
undef past_mins
with ash_gc as 
(select * from (
select  dbid,         
        to_char(sample_time,'YYMMDD')                      tday
      , trunc(to_char(sample_time,'SSSSS')/&v_secs)             tmod
      , instance_number inst_id, 
        event, 
        sql_id,
        current_obj#,         
        count(*) cnt 
from dba_hist_active_sess_history where event like '%'||'gc' ||'%'
and sample_time between TIMESTAMP'&&2' and  TIMESTAMP'&&3'
and instance_number=&&4
and dbid=&&1
group by dbid, 
        to_char(sample_time,'YYMMDD')                     
      , trunc(to_char(sample_time,'SSSSS')/&v_secs)            
      , instance_number,sql_id,event, current_obj#
))
select * from (
    select to_date(tday||' '||tmod*&v_secs,'YYMMDD SSSSS') start_time,inst_id,event, sql_id,owner, object_name,object_type, cnt 
        from ash_gc a, DBA_HIST_SEG_STAT_OBJ o
        where (a.current_obj#=o.dataobj# or a.current_obj#=o.obj#) and a.dbid=o.dbid
        and a.current_obj#>=1        and a.current_obj#>=1
    union 
    select to_date(tday||' '||tmod*&v_secs,'YYMMDD SSSSS') start_time,inst_id, event, sql_id,'','','Undo Header/Undo block' , cnt 
        from ash_gc a
        where a.current_obj#=0
    union
    select to_date(tday||' '||tmod*&v_secs,'YYMMDD SSSSS') start_time,inst_id, event, sql_id,'','','Undo Block' , cnt 
        from ash_gc a
        where a.current_obj#=-1
) order by 1,2
/
set echo off
