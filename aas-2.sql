
set linesize 200 trimspool on
col begin_time format a30

with aas as (
   select snap_id, value, dbid, instance_number, rownum my_rownum
   from (
      select snap_id
         , round(db_time / elapsed_time,1)  value
         , dbid
         , instance_number
      from (
         select distinct h.snap_id
            , h.instance_number
            , h.dbid
            , count(*) over (partition by h.snap_id, h.instance_number) * 10 db_time
            , (extract( day from (s.end_interval_time - s.begin_interval_time) )*24*60*60)+
               (extract( hour from (s.end_interval_time - s.begin_interval_time) )*60*60)+
               (extract( minute from (s.end_interval_time - s.begin_interval_time) )*60)+
               (extract( second from (s.end_interval_time - s.begin_interval_time)))
            elapsed_time
         from dba_hist_active_sess_history h
         join dba_hist_snapshot s on s.snap_id = h.snap_id
            and s.instance_number = h.instance_number
         where (
            wait_class is null  -- on CPU
            or wait_class != 'Idle' -- ignore idle events
         )
      )
      order by 2 desc
   )
),
top10aas as (
   select
      to_char(trunc(sn.begin_interval_time,'hh'), 'yyyy-mm-dd hh24:mi') begin_time
      , aas.instance_number
      , aas.snap_id begin_snap_id
      , aas.value
      , aas.dbid
   from aas
   join dba_hist_snapshot sn on sn.snap_id = aas.snap_id
      and sn.instance_number = aas.instance_number
   where my_rownum <= 10
   order by value desc
)
select * from top10aas
/
