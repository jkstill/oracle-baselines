

-- aggregate AAS data by instance
-- we want to find the aggregate activity across all nodes per point in time
-- avg() is used to get an approximate value when there are 2+ snapshots per time period (1 minute)
--
--   average within pdb
--   sum the averages per pdb within a time period
--   sum the counts across instances
-- 
-- there should be code added to exclude con_id if on legacy database
--

/*
-- used for independent testing

set pagesize 100
set linesize 200 trimspool on
set echo off pause off verify off
set feedback on 
ttitle off
btitle off
clear breaks

set term off
spool t1.log
*/

with aas as (
   select
		trunc(begin_time,'MI') begin_time
		, avg(value) value
   from dba_hist_sysmetric_history
   where metric_name = 'Average Active Sessions'
   group by trunc(begin_time,'MI')
		, instance_number
		-- need to sum by con_id
		-- assumes that one day Oracle will start recording per PDB... (not as of 19.3)
		, con_id 
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
   left outer join aas on aas.begin_time = jd.aas_snap_time
	where aas.begin_time is not null -- last row null - dunno why
   group by begin_time
)
select to_char(ad.aas_snap_time,'yyyy-mm-dd hh24:mi:ss')  || ',' || to_char(ad.value,'0999.9990')
from agg_data ad
order by aas_snap_time;

--spool off
--set term on


