-- dbarkin  20161229 This scripts list top objects with blocks from dba_hist_active_sess_history
col name format a25; 
col p1 format a10; 
col p2 format a10; 
col p3 format a10; 
SELECT NAME, PARAMETER1 P1, PARAMETER2 P2, PARAMETER3 P3  FROM V$EVENT_NAME  WHERE NAME = 'gc imc multi block quiesce'; 

select sample_time,event,time_waited,p1text,p1,p2text,p2,p3text,p3,CURRENT_OBJ#,CURRENT_FILE#,CURRENT_BLOCK#,CURRENT_ROW#,
       o.object_name obj,
       o.subobject_name sub_obj,
       o.object_type otype,
       df.tsname 
from dba_hist_active_sess_history io
  , DBA_HIST_SEG_STAT_OBJ o
  , DBA_HIST_DATAFILE df
where
   o.obj# (+)= io.CURRENT_OBJ# and o.dbid (+)=io.dbid
   and   df.dbid (+)=io.dbid and df.file# (+)=io.current_file#   
   and   event in ( 'gc block recovery request'
,'gc buffer busy acquire'
,'gc buffer busy release'
,'gc claim'
,'gc cr disk request'
,'gc cr multi block request'
,'gc cr request'
,'gc current multi block request'
,'gc current request'
,'gc domain validation'
,'gc imc multi block quiesce'
,'gc imc multi block request'
,'gc recovery quiesce'
,'gc remaster'
) and io.dbid=1611110930
   order by o.object_name, o.subobject_name,sample_time,CURRENT_FILE#,CURRENT_BLOCK#;


select * from dba_hist_active_sess_history io where  current_block#=548743

col object format a60
col i format 99
select * from (
select o.owner||'.'||o.object_name||decode(o.subobject_name,NULL,'','.')||
  o.subobject_name||' ['||o.object_type||']' object,
  instance_number i, stat
from (
  select obj#||'.'||dataobj# obj#, instance_number, sum(
GC_BUFFER_BUSY_DELTA
) stat
  from dba_hist_seg_stat
  where (dbid=1611110930)  
  group by rollup(obj#||'.'||dataobj#, instance_number)
  having obj#||'.'||dataobj# is not null
) s, dba_hist_seg_stat_obj o
where o.dataobj#||'.'||o.obj#=s.obj#
order by max(stat) over (partition by s.obj#) desc,
  o.owner||o.object_name||o.subobject_name, nvl(instance_number,0)
) where rownum<=40;