
-- aggregate AAS data by instance
-- also show each instance
-- we want to find the aggregate activity across all nodes per point in time
-- avg() is used to get an approximate value when there are 2+ snapshots per time period (1 minute)
--
--   average within pdb
--   sum the averages per pdb within a time period
--   sum the counts across instances
--
-- there should be code added to exclude con_id if on legacy database
--
-- Note: adjust WITH clauses as necessary for the number of nodes
--       might be done with listagg(), but probably not as simple as that when coupled with driving shell script


define use_csv='--'
define use_std=''

col a1_value format 9990.099
col a2_value format 9990.099
col a3_value format 9990.099
col tot_value format 9990.099

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
spool t2.log
*/

with aas1 as (
	select
		trunc(begin_time,'MI') begin_time
		, avg(value) value
	from dba_hist_sysmetric_history
	where metric_name = 'Average Active Sessions'
		and instance_number = 1
	group by trunc(begin_time,'MI')
),
aas2 as (
	select
		trunc(begin_time,'MI') begin_time
		, avg(value) value
	from dba_hist_sysmetric_history
	where metric_name = 'Average Active Sessions'
		and instance_number = 2
	group by trunc(begin_time,'MI')
),
aas3 as (
	select
		trunc(begin_time,'MI') begin_time
		, avg(value) value
	from dba_hist_sysmetric_history
	where metric_name = 'Average Active Sessions'
		and instance_number = 3
	group by trunc(begin_time,'MI')
),
get_begin_date as (
	select trunc(min(begin_time),'MI') min_begin_time from dba_hist_sysmetric_history
),
get_end_date as (
	select trunc(max(begin_time),'MI') max_begin_time from dba_hist_sysmetric_history
),
join_dates as (
	-- 40 days of retention
	-- get 42 days of start times, by the minute, for 10 days
	-- overlap in times to ensure matching beginning and end of data
	-- all with the same start time
	-- todays date is 2020-06-29
	--select to_date('2020-05-19 17:00','yyyy-mm-dd hh24:mi') + ( level / 1440) aas_snap_time
	select (select min_begin_time from get_begin_date) + ( level / 1440) aas_snap_time
	from dual
	connect by level <= 42 * 1440
)
select
	-- STD output
	&use_csv to_char(jd.aas_snap_time,'yyyy-mm-dd hh24:mi:ss') begin_time
	&use_csv , a1.value a1_value
	&use_csv , a2.value a2_value
	&use_csv , a3.value a3_value
	&use_csv , a1.value + a2.value + a3.value total_value
	-- CSV output
	&use_std to_char(jd.aas_snap_time,'yyyy-mm-dd hh24:mi:ss')
	&use_std || ',' || to_char(nvl(a1.value,0),'990.099')
	&use_std || ',' || to_char(nvl(a2.value,0),'990.099')
	&use_std || ',' || to_char(nvl(a3.value,0),'990.099')
	&use_std || ',' || to_char(nvl(a1.value + a2.value + a3.value,0),'990.099')
from join_dates jd
	left outer join aas1 a1 on a1.begin_time = jd.aas_snap_time
	left outer join aas2 a2 on a2.begin_time = jd.aas_snap_time
	left outer join aas3 a3 on a3.begin_time = jd.aas_snap_time
--where  a1.value + a2.value + a3.value > 0
where jd.aas_snap_time <= ( select max_begin_time from get_end_date )
order by 1;

--spool off
--set term on

