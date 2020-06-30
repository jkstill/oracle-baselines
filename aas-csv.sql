

with aas as (
   select  trunc(begin_time,'MI') begin_time, avg(value)  value
   from dba_hist_sysmetric_history
   where metric_name = 'Average Active Sessions'
   group by trunc(begin_time,'MI'), instance_number
),
join_dates as (
   -- get 42 days of start times, by the minute, for 10 days
   -- all with the same start time
   -- todays date is 2020-06-29
   select to_date('2020-05-17 17:00','yyyy-mm-dd hh24:mi') + ( level / 1440) aas_snap_time
   from dual
   connect by level <= 42 * 1440
),
agg_data as(
   select begin_time aas_snap_time, sum(value) value
   from join_dates jd
   join aas on aas.begin_time = jd.aas_snap_time
   group by begin_time
)
select to_char(ad.aas_snap_time,'yyyy-mm-dd hh24:mi:ss')  || ',' || to_char(ad.value,'0999.9990')
from agg_data ad
order by aas_snap_time;

