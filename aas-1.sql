
set linesize 200 trimspool on
col begin_time format a30

with aas as (
   select snap_id
      , value
      , dbid
      , instance_number
      , rownum my_rownum
   from (
      select distinct snap_id, dbid, instance_number, max(value) over (partition by snap_id order by snap_id) value
      from dba_hist_sysmetric_history
      where metric_name = 'Average Active Sessions'
      order by value desc
   )
),
top10aas as (
   select
		to_char(trunc(sn.begin_interval_time, 'hh'), 'yyyy-mm-dd hh24:mi') begin_time
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
select * from top10aas;

